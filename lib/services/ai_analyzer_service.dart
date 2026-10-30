import 'dart:async';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../models/agreement.dart';
import '../models/app_usage.dart';
import '../models/check_in_record.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../models/usage_driver.dart';
import '../models/user_role.dart';
import '../utils/clock.dart';
import '../utils/formatters.dart';
import 'change_explainer.dart';
import 'gemini_analyzer.dart';

enum InsightTone { positive, attention, neutral }

class AiObservation {
  const AiObservation({
    required this.title,
    required this.detail,
    required this.tone,
    required this.tag,
  });

  final String title;
  final String detail;
  final InsightTone tone;
  final String tag;
}

class AiSuggestion {
  const AiSuggestion({required this.title, required this.detail});

  final String title;
  final String detail;
}

class AiReport {
  const AiReport({
    required this.headline,
    required this.summary,
    required this.observations,
    required this.suggestions,
    required this.createdAt,
    required this.fromModel,
    this.drivers = const [],
    this.conversationStarters = const [],
  });

  final String headline;
  final String summary;
  final List<AiObservation> observations;
  final List<AiSuggestion> suggestions;
  final DateTime createdAt;

  /// False in the demo: analysis is produced locally with transparent rules.
  final bool fromModel;

  /// Ranked reasons the day moved, when available.
  final List<UsageDriver> drivers;

  /// Gentle, local question prompts built from the same drivers.
  final List<String> conversationStarters;
}

enum AiAnalysisSource { local, gemini }

/// The result of a refresh, including enough context for honest UI copy.
class AiAnalysisOutcome {
  const AiAnalysisOutcome({
    required this.report,
    required this.source,
    this.notice,
  });

  final AiReport report;
  final AiAnalysisSource source;

  /// A friendly explanation when a model call failed and the local report was
  /// used instead. Null on a clean local or model result.
  final String? notice;

  bool get usedModel => source == AiAnalysisSource.gemini;
}

/// The AI seam.
///
/// With no key, analysis comes from [buildLocalReport]: transparent on-device
/// rules over the same inputs. With a Gemini key passed at build time or entered
/// in Settings, [analyze] sends the brief to Gemini and falls back to the local
/// report on any timeout, network or parsing failure.
///
/// A mobile binary cannot keep a key secret. This is deliberately a demo path;
/// production should route the request through a small backend proxy.
class AiAnalyzerService {
  AiAnalyzerService({
    String? apiKey,
    GeminiAnalyzer Function(String apiKey)? clientBuilder,
    this.localLatency = const Duration(milliseconds: 450),
  }) : _apiKey = _normalize(apiKey ?? AppEnv.geminiApiKey),
       _clientBuilder = clientBuilder ?? _defaultClient;

  static GeminiAnalyzer _defaultClient(String apiKey) =>
      GeminiAnalyzer(config: GeminiConfig.fromEnvironment(apiKey));

  final GeminiAnalyzer Function(String apiKey) _clientBuilder;
  final Duration localLatency;

  String? _apiKey;

  String? get apiKey => _apiKey;

  /// A key is considered usable only when it passes the cheap shape checks.
  bool get hasApiKey => _apiKey != null && apiKeyProblem == null;

  /// Null when the key is absent or plausible; otherwise copy for the UI.
  String? get apiKeyProblem => validateApiKey(_apiKey);

  /// Returns a user-safe validation message, or null when the value is valid.
  /// An empty value means "remove the key" and is valid.
  static String? validateApiKey(
    String? key, {
    AppStrings strings = AppStrings.english,
  }) {
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (RegExp(r'\s').hasMatch(trimmed)) {
      return strings.apiKeyHasSpaces;
    }
    if (trimmed.length < 20) {
      return strings.apiKeyTooShort;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{20,128}$').hasMatch(trimmed)) {
      return strings.apiKeyLooksInvalid;
    }
    return null;
  }

  static String? _normalize(String? key) {
    final trimmed = key?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  void setApiKey(String? key) {
    _apiKey = _normalize(key);
  }

  /// Runs the configured analysis path.
  ///
  /// The local report is always built first. It is both the no-key result and
  /// the fallback when Gemini fails, so the UI never ends a refresh with an
  /// empty or partial card.
  Future<AiAnalysisOutcome> analyze(
    Child child, {
    List<ContextNote> notes = const [],
    Agreement? agreement,
    CheckInRecord? lastCheckIn,
    AppStrings strings = AppStrings.english,
    bool includeAppDetail = true,
  }) async {
    final local = buildLocalReport(
      child,
      lastCheckIn: lastCheckIn,
      strings: strings,
      includeAppDetail: includeAppDetail,
    );
    final key = _apiKey;

    // At the trends level the parent has agreed not to receive app or session
    // detail, so the model path is skipped entirely rather than trusting it to
    // stay aggregate-only.
    if (key == null || !includeAppDetail) {
      if (localLatency > Duration.zero) {
        await Future<void>.delayed(localLatency);
      }
      return AiAnalysisOutcome(report: local, source: AiAnalysisSource.local);
    }

    final problem = validateApiKey(_apiKey, strings: strings);
    if (problem != null) {
      return AiAnalysisOutcome(
        report: local,
        source: AiAnalysisSource.local,
        notice: problem,
      );
    }

    final client = _clientBuilder(key);
    try {
      final analysis = await client
          .analyze(
            brief: buildPrompt(
              child,
              notes: notes,
              agreement: agreement,
              lastCheckIn: lastCheckIn,
            ),
            strings: strings,
          )
          .timeout(client.timeout + const Duration(seconds: 2));

      return AiAnalysisOutcome(
        report: AiReport(
          headline: analysis.headline,
          summary: analysis.summary,
          observations: [
            for (final observation in analysis.observations)
              AiObservation(
                title: observation.title,
                detail: observation.detail,
                tone: _toneFor(observation.tone),
                tag: observation.tag,
              ),
          ],
          suggestions: [
            for (final suggestion in analysis.suggestions)
              AiSuggestion(title: suggestion.title, detail: suggestion.detail),
          ],
          createdAt: AppClock.now(),
          fromModel: true,
          drivers: ChangeExplainer.explainDay(child, strings: strings),
          conversationStarters: analysis.conversationStarters.isEmpty
              ? local.conversationStarters
              : analysis.conversationStarters,
        ),
        source: AiAnalysisSource.gemini,
      );
    } on GeminiException catch (error) {
      return AiAnalysisOutcome(
        report: local,
        source: AiAnalysisSource.local,
        notice: error.message,
      );
    } on TimeoutException {
      return AiAnalysisOutcome(
        report: local,
        source: AiAnalysisSource.local,
        notice: strings.geminiTookTooLong,
      );
    } catch (_) {
      return AiAnalysisOutcome(
        report: local,
        source: AiAnalysisSource.local,
        notice: strings.aiRequestFailed,
      );
    }
  }

  static InsightTone _toneFor(String tone) => switch (tone) {
    'positive' => InsightTone.positive,
    'attention' => InsightTone.attention,
    _ => InsightTone.neutral,
  };

  /// A compact, privacy-conscious brief that can be sent to a model.
  ///
  /// Names and app labels are pseudonymous enough for a parent-owned account,
  /// but avoid sending raw device identifiers. The system prompt in
  /// `assets/prompts/gemini_system_prompt.txt` supplies the role and output
  /// contract; this is the family data the model reasons over.
  static String buildPrompt(
    Child child, {
    List<ContextNote> notes = const [],
    Agreement? agreement,
    CheckInRecord? lastCheckIn,
    bool includeAppDetail = true,
  }) {
    final totals =
        '''
Private family brief for ${child.name} (age ${child.age}), covering today and
the last two weeks. Follow the system instructions exactly and return only the
JSON object they describe.

Today: ${formatMinutes(child.todayMinutes)}
Yesterday: ${formatMinutes(child.yesterdayMinutes)}
Daily minutes (oldest to newest): ${child.days.map((day) => day.minutes).join(', ')}
Weekly total: ${formatMinutes(child.weekMinutes)}
''';

    if (!includeAppDetail) {
      return '''
$totals
The parent has chosen a trends-only sharing level. Use only weekly trends and
daily totals. Do not name or infer apps, categories, sessions, peak hours or
context notes.
''';
    }

    final categories = child.weeklyCategories
        .map(
          (entry) =>
              '${AppStrings.english.categoryLabel(entry.key)}: '
              '${formatMinutes(entry.value)}',
        )
        .join(', ');
    final sessions = child.longestSessions
        .take(3)
        .map(
          (session) =>
              '${session.label} at ${formatTime(session.start)} for ${formatMinutes(session.minutes)}',
        )
        .join('; ');
    final drivers = ChangeExplainer.explainDay(child, limit: 3);
    final driverLines = drivers.isEmpty
        ? 'No single driver stands out.'
        : drivers
              .map(
                (driver) =>
                    '${driver.label}: ${driver.detail} (${driver.evidence})',
              )
              .join('; ');
    final noteLines = notes.isEmpty
        ? 'No context notes yet.'
        : notes
              .take(4)
              .map(
                (note) =>
                    '${note.author == UserRole.parent ? 'Parent' : 'Child'} note '
                    '(${note.tag.name}): ${_clip(note.text)}',
              )
              .join('; ');
    final agreementLine = agreement == null
        ? 'No active family agreement.'
        : 'Agreement: ${_clip(agreement.title)} — ${_clip(agreement.detail)}';
    final checkInLine = lastCheckIn == null || lastCheckIn.childId != child.id
        ? 'No family check-in recorded yet for ${child.name}.'
        : 'Last check-in topic: ${_clip(lastCheckIn.topic)} — '
              '${_clip(lastCheckIn.question)}';

    return '''
$totals
Weekly categories: $categories
Peak window: ${formatHourRange(child.peakWindowStart, child.peakWindowStart + 3)}
Late-night minutes: ${child.lateNightMinutes}
Longest sessions: $sessions
What moved today: $driverLines
<family_data>
Context notes: $noteLines
$agreementLine
$checkInLine
</family_data>
''';
  }

  /// Trims family-written text before it enters a prompt.
  static String _clip(String text, [int limit = 200]) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final clipped = cleaned.length <= limit
        ? cleaned
        : '${cleaned.substring(0, limit)}…';
    return clipped.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }

  /// A transparent rule-based stand-in for the model. It uses the same inputs
  /// the future prompt will use, so the UI can be built and tested end-to-end.
  static AiReport buildLocalReport(
    Child child, {
    DateTime? now,
    CheckInRecord? lastCheckIn,
    AppStrings strings = AppStrings.english,
    bool includeAppDetail = true,
  }) {
    final day = child.dayOverDay;
    final week = child.weekOverWeek;
    final topApp = child.topApp;
    final topCategory = child.weeklyCategories.isEmpty
        ? AppCategory.utilities
        : child.weeklyCategories.first.key;
    final weekRatio = week.ratio;

    final String headline;
    if (weekRatio.abs() < 0.04) {
      headline = strings.headlineSteadyWeek(child.name);
    } else if (weekRatio > 0) {
      headline = strings.headlineAboveWeek(
        child.name,
        (weekRatio * 100).round(),
      );
    } else {
      headline = strings.headlineBelowWeek(
        child.name,
        (weekRatio.abs() * 100).round(),
      );
    }

    final summary = buildSummary(
      child,
      includeAppDetail: includeAppDetail,
      strings: strings,
    );

    final dayObservation = AiObservation(
      title: strings.observationTodayVsYesterday,
      detail: day.isFlat
          ? strings.observationDayFlat
          : strings.observationDayDetail(
              formatMinutes(child.todayMinutes, strings: strings),
              formatDifference(day.difference, strings: strings),
              formatMinutes(child.yesterdayMinutes, strings: strings),
            ),
      tone: day.ratio > 0.1
          ? InsightTone.attention
          : day.ratio < -0.1
          ? InsightTone.positive
          : InsightTone.neutral,
      tag: strings.tagToday,
    );

    final peakObservation = AiObservation(
      title: strings.observationBusiestWindow,
      detail: strings.observationPeak(
        formatHourRange(
          child.peakWindowStart,
          child.peakWindowStart + 3,
          strings: strings,
        ),
        strings.categoryLabel(topCategory),
      ),
      tone: InsightTone.neutral,
      tag: strings.tagPattern,
    );

    final appObservation = topApp == null
        ? AiObservation(
            title: strings.observationNoAppTitle,
            detail: strings.observationNoAppDetail,
            tone: InsightTone.neutral,
            tag: strings.tagApps,
          )
        : AiObservation(
            title: strings.observationWeeklyLeader(topApp.name),
            detail: strings.observationWeeklyLeaderDetail(
              formatMinutes(topApp.weekMinutes, strings: strings),
              child.weekAppMinutes == 0
                  ? 0
                  : (topApp.weekMinutes / child.weekAppMinutes * 100).round(),
              formatMinutes(topApp.dailyAverage, strings: strings),
            ),
            tone: InsightTone.neutral,
            tag: strings.tagApps,
          );

    final observations = <AiObservation>[dayObservation];
    if (includeAppDetail) {
      observations.addAll([peakObservation, appObservation]);
    }

    final lateWindow = child.hourlyToday.length >= 24
        ? child.hourlyToday[22] + child.hourlyToday[23]
        : child.lateNightMinutes;
    final containsLateSession = child.sessions.any(
      (session) => session.end.hour >= 22 || session.end.hour < 4,
    );
    if (includeAppDetail) {
      if (lateWindow > 12 || containsLateSession) {
        observations.add(
          AiObservation(
            title: strings.observationLateTitle,
            detail: strings.observationLateDetail(
              formatMinutes(child.lateNightMinutes, strings: strings),
            ),
            tone: InsightTone.attention,
            tag: strings.tagBedtime,
          ),
        );
      } else {
        observations.add(
          AiObservation(
            title: strings.observationEveningTitle,
            detail: strings.observationEveningDetail(
              formatMinutes(child.lateNightMinutes, strings: strings),
            ),
            tone: InsightTone.positive,
            tag: strings.tagBedtime,
          ),
        );
      }
    }

    if (lastCheckIn != null && lastCheckIn.childId == child.id) {
      observations.add(
        AiObservation(
          title: strings.observationFollowingUp,
          detail: strings.observationFollowUpDetail(
            lastCheckIn.topic,
            lastCheckIn.question,
          ),
          tone: InsightTone.positive,
          tag: strings.tagRitual,
        ),
      );
    }

    final suggestions = includeAppDetail
        ? _suggestionsFor(child, topCategory, strings)
        : _aggregateSuggestions(child, strings);
    final drivers = includeAppDetail
        ? ChangeExplainer.explainDay(child, strings: strings)
        : const <UsageDriver>[];
    return AiReport(
      headline: headline,
      summary: summary,
      observations: observations,
      suggestions: suggestions,
      createdAt: now ?? AppClock.now(),
      fromModel: false,
      drivers: drivers,
      conversationStarters: _startersFor(child, drivers, strings),
    );
  }

  /// The short summary paragraph used by the AI card.
  ///
  /// At the `trends` sharing level the parent sees weekly shape only, so
  /// [includeAppDetail] can be turned off to keep app names and category
  /// leaders out of the copy. Nothing is removed from the data itself.
  static String buildSummary(
    Child child, {
    bool includeAppDetail = true,
    AppStrings strings = AppStrings.english,
  }) {
    final day = child.dayOverDay;
    final week = child.weekOverWeek;
    final weekRatio = week.ratio;
    final weekDirection = weekRatio.abs() < 0.04
        ? strings.weekAboutSame
        : weekRatio.isNegative
        ? strings.weekBelow
        : strings.weekAbove;
    final dayPhrase = day.isFlat
        ? strings.dayAboutSame
        : strings.dayCompared(formatSignedPercent(day.ratio, strings: strings));

    final base = strings.summaryBase(
      formatMinutes(child.todayMinutes, strings: strings),
      dayPhrase,
      child.name,
      formatMinutes(child.weeklyAverage, strings: strings),
      weekDirection,
    );

    if (!includeAppDetail || child.weeklyCategories.isEmpty) {
      return '$base ${strings.summaryRhythmSignal}';
    }

    final topApp = child.topApp;
    if (topApp == null) {
      return '$base ${strings.summaryRhythmSignal}';
    }
    final topCategory = strings.categoryLabel(child.weeklyCategories.first.key);
    return strings.summaryCategory(
      base,
      topCategory,
      topApp.name,
      formatMinutes(topApp.weekMinutes, strings: strings),
    );
  }

  static List<String> _startersFor(
    Child child,
    List<UsageDriver> drivers,
    AppStrings strings,
  ) {
    final delta = child.dayOverDay.difference;
    final first = drivers.isEmpty
        ? strings.starterDifferent
        : strings.starterLongerShorter(delta >= 0);
    final second = child.lateNightMinutes > 0
        ? strings.starterLastHour
        : strings.starterEvening;
    final third = child.weekOverWeek.isFlat
        ? strings.starterSteady
        : strings.starterBalanced;
    return [first, second, third];
  }

  /// Suggestions that stay at the weekly-trends level and never name an app,
  /// category or session. Used when the parent chose the `trends` level.
  static List<AiSuggestion> _aggregateSuggestions(
    Child child,
    AppStrings strings,
  ) {
    final name = child.name;
    return [
      AiSuggestion(
        title: strings.suggestionChargerTitle,
        detail: strings.suggestionChargerDetail(name),
      ),
      AiSuggestion(
        title: strings.suggestionCheckInTitle,
        detail: strings.suggestionCheckInDetail,
      ),
      AiSuggestion(
        title: strings.suggestionSharedRuleTitle,
        detail: strings.suggestionSharedRuleDetail(name),
      ),
    ];
  }

  static List<AiSuggestion> _suggestionsFor(
    Child child,
    AppCategory category,
    AppStrings strings,
  ) {
    final name = child.name;
    switch (category) {
      case AppCategory.gaming:
        return [
          AiSuggestion(
            title: strings.suggestionWindDownTitle,
            detail: strings.suggestionWindDownDetail,
          ),
          AiSuggestion(
            title: strings.suggestionChargerTitle,
            detail: strings.suggestionChargerDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionPlayTogetherTitle,
            detail: strings.suggestionPlayTogetherDetail,
          ),
        ];
      case AppCategory.social:
      case AppCategory.video:
        return [
          AiSuggestion(
            title: strings.suggestionTeamRuleTitle,
            detail: strings.suggestionTeamRuleDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionFeedTitle,
            detail: strings.suggestionFeedDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionOfflineTitle,
            detail: strings.suggestionOfflineDetail,
          ),
        ];
      case AppCategory.education:
        return [
          AiSuggestion(
            title: strings.suggestionStreakTitle,
            detail: strings.suggestionStreakDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionQuietHourTitle,
            detail: strings.suggestionQuietHourDetail,
          ),
          AiSuggestion(
            title: strings.suggestionMovementTitle,
            detail: strings.suggestionMovementDetail,
          ),
        ];
      case AppCategory.creativity:
        return [
          AiSuggestion(
            title: strings.suggestionDisplayTitle,
            detail: strings.suggestionDisplayDetail,
          ),
          AiSuggestion(
            title: strings.suggestionCornerTitle,
            detail: strings.suggestionCornerDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionShowTellTitle,
            detail: strings.suggestionShowTellDetail,
          ),
        ];
      case AppCategory.messaging:
        return [
          AiSuggestion(
            title: strings.suggestionResponseTitle,
            detail: strings.suggestionResponseDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionGroupChatsTitle,
            detail: strings.suggestionGroupChatsDetail,
          ),
          AiSuggestion(
            title: strings.suggestionNotificationsTitle,
            detail: strings.suggestionNotificationsDetail,
          ),
        ];
      case AppCategory.utilities:
        return [
          AiSuggestion(
            title: strings.suggestionNameMattersTitle,
            detail: strings.suggestionNameMattersDetail(name),
          ),
          AiSuggestion(
            title: strings.suggestionHomeScreenTitle,
            detail: strings.suggestionHomeScreenDetail,
          ),
          AiSuggestion(
            title: strings.suggestionCheckInTitle,
            detail: strings.suggestionCheckInDetail,
          ),
        ];
    }
  }
}
