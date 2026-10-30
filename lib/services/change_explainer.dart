import '../l10n/app_strings.dart';
import '../models/app_usage.dart';
import '../models/child.dart';
import '../models/usage_driver.dart';
import '../utils/dates.dart';
import '../utils/formatters.dart';

/// The three questions the AI card can answer without a model call.
enum InsightQuestion { whyChange, bedtime, week }

/// Turns existing activity into an explanation of *why* the number moved.
///
/// App drivers are exact attribution rows: their signed minutes add up to the
/// day-over-day delta. Late-night, unlock and weekday rows are context signals
/// and are not counted twice.
abstract final class ChangeExplainer {
  static List<UsageDriver> attribution(
    Child child, {
    AppStrings strings = AppStrings.english,
  }) {
    final positive = child.apps.fold<int>(
      0,
      (total, app) =>
          total + (app.todayMinutes - app.yesterdayMinutes).clamp(0, 1 << 30),
    );

    final drivers = <UsageDriver>[];
    for (final app in child.apps) {
      final delta = app.todayMinutes - app.yesterdayMinutes;
      if (delta == 0) continue;
      drivers.add(
        UsageDriver(
          label: app.name,
          detail: delta > 0
              ? '${formatMinutes(delta, strings: strings)} '
                    '${strings.driverMoreThanYesterday}'
              : '${formatMinutes(-delta, strings: strings)} '
                    '${strings.driverLessThanYesterday}',
          minutes: delta,
          share: delta > 0 && positive > 0 ? delta / positive : 0,
          evidence: strings.driverEvidence(
            formatMinutes(app.todayMinutes, strings: strings),
            formatMinutes(app.yesterdayMinutes, strings: strings),
          ),
          kind: DriverKind.app,
          tone: delta > 0 ? DriverTone.attention : DriverTone.positive,
        ),
      );
    }
    drivers.sort((a, b) => b.minutes.abs().compareTo(a.minutes.abs()));
    return drivers;
  }

  /// A ranked, human list for the "Why it changed" card.
  static List<UsageDriver> explainDay(
    Child child, {
    int limit = 4,
    AppStrings strings = AppStrings.english,
  }) {
    if (child.days.isEmpty) return const [];

    final drivers = attribution(child, strings: strings).take(3).toList();
    final today = child.today;
    if (today == null) return const [];

    final lateDelta = _lateNightMinutes(child, 0) - _lateNightMinutes(child, 1);
    if (lateDelta.abs() >= 5) {
      drivers.add(
        UsageDriver(
          label: strings.driverLateNight,
          detail: lateDelta > 0
              ? '${formatMinutes(lateDelta, strings: strings)} '
                    '${strings.driverMoreAfter10}'
              : '${formatMinutes(-lateDelta, strings: strings)} '
                    '${strings.driverLessAfter10}',
          minutes: lateDelta,
          evidence: strings.driverEvidence(
            formatMinutes(_lateNightMinutes(child, 0), strings: strings),
            formatMinutes(_lateNightMinutes(child, 1), strings: strings),
          ),
          kind: DriverKind.lateNight,
          tone: lateDelta > 0 ? DriverTone.attention : DriverTone.positive,
        ),
      );
    }

    final unlocksDelta = today.unlocks - (child.yesterday?.unlocks ?? 0);
    if (unlocksDelta.abs() >= 5) {
      drivers.add(
        UsageDriver(
          label: strings.driverUnlocks,
          detail: unlocksDelta > 0
              ? strings.driverMoreOpens(unlocksDelta)
              : strings.driverFewerOpens(unlocksDelta.abs()),
          minutes: unlocksDelta,
          evidence: strings.driverUnlockEvidence(
            '${today.unlocks}',
            '${child.yesterday?.unlocks ?? 0}',
          ),
          kind: DriverKind.unlocks,
          tone: unlocksDelta > 0 ? DriverTone.attention : DriverTone.positive,
        ),
      );
    }

    if (child.days.length >= 14) {
      final baselineDelta = child.todayMinutes - child.days[6].minutes;
      if (baselineDelta.abs() >= 15) {
        drivers.add(
          UsageDriver(
            label: strings.driverSameWeekday,
            detail: strings.driverSameWeekdayDetail(
              formatDifference(baselineDelta, strings: strings),
              weekdayShort(today.date, strings: strings),
            ),
            minutes: baselineDelta,
            evidence: strings.driverLastWeekEvidence(
              formatMinutes(child.todayMinutes, strings: strings),
              formatMinutes(child.days[6].minutes, strings: strings),
            ),
            kind: DriverKind.baseline,
            tone: baselineDelta > 0
                ? DriverTone.attention
                : DriverTone.positive,
          ),
        );
      }
    }

    final newApp = _newApp(child);
    if (newApp != null) {
      drivers.add(
        UsageDriver(
          label: strings.driverAppShowedUp(newApp.name),
          detail: strings.driverFirstMeaningfulTime,
          minutes: newApp.todayMinutes,
          evidence: strings.driverEvidence(
            formatMinutes(newApp.todayMinutes, strings: strings),
            formatMinutes(newApp.yesterdayMinutes, strings: strings),
          ),
          kind: DriverKind.newApp,
          tone: DriverTone.attention,
        ),
      );
    }

    drivers.sort((a, b) => b.minutes.abs().compareTo(a.minutes.abs()));
    return drivers.take(limit).toList();
  }

  /// The part of the day's delta that is not represented by the shown app rows.
  static int remainderMinutes(Child child, List<UsageDriver> shown) {
    final delta = child.dayOverDay.difference;
    final attributed = shown
        .where((driver) => driver.isAttribution)
        .fold<int>(0, (total, driver) => total + driver.minutes);
    return delta - attributed;
  }

  static String answerFor(
    Child child,
    InsightQuestion question, {
    AppStrings strings = AppStrings.english,
  }) {
    return switch (question) {
      InsightQuestion.whyChange => _whyAnswer(child, strings),
      InsightQuestion.bedtime => _bedtimeAnswer(child, strings),
      InsightQuestion.week => _weekAnswer(child, strings),
    };
  }

  static String _whyAnswer(Child child, AppStrings strings) {
    final drivers = explainDay(child, limit: 3, strings: strings);
    final delta = child.dayOverDay.difference;
    if (delta == 0 || drivers.isEmpty) {
      return strings.whyAnswerLevel(
        formatMinutes(child.todayMinutes, strings: strings),
      );
    }

    final top = drivers.first;
    final context = drivers
        .skip(1)
        .take(2)
        .map((driver) => driver.label.toLowerCase())
        .toList();
    final extra = context.isEmpty ? '' : strings.whyAnswerExtra(context);
    return strings.whyAnswerChanged(
      formatMinutes(delta.abs(), strings: strings),
      delta > 0,
      top.label,
      top.evidence.toLowerCase(),
      extra,
    );
  }

  static String _bedtimeAnswer(Child child, AppStrings strings) {
    final todayLate = _lateNightMinutes(child, 0);
    final yesterdayLate = _lateNightMinutes(child, 1);
    final delta = todayLate - yesterdayLate;
    final opening = todayLate == 0
        ? strings.bedtimeNothingLate
        : strings.bedtimeLandedLate(formatMinutes(todayLate, strings: strings));
    final comparison = delta == 0
        ? strings.bedtimeLevel
        : delta > 0
        ? strings.bedtimeMore(formatMinutes(delta, strings: strings))
        : strings.bedtimeLess(formatMinutes(-delta, strings: strings));
    return '$opening$comparison${strings.bedtimeClosing(child.name)}';
  }

  static String _weekAnswer(Child child, AppStrings strings) {
    final week = child.weekOverWeek;
    final topCategory = child.weeklyCategories.isEmpty
        ? null
        : strings.categoryLabel(child.weeklyCategories.first.key);
    final categoryPhrase = topCategory == null
        ? ''
        : strings.weekCategoryPhrase(topCategory);
    final topApp = child.topApp;
    final appPhrase = topApp == null
        ? strings.weekNoTopApp
        : strings.weekLedBy(
            topApp.name,
            formatMinutes(topApp.weekMinutes, strings: strings),
          );
    return strings.weekAnswer(
      formatMinutes(child.weekMinutes, strings: strings),
      formatDifference(week.difference, strings: strings).toLowerCase(),
      formatSignedPercent(week.ratio, strings: strings),
      categoryPhrase,
      appPhrase,
    );
  }

  static int _lateNightMinutes(Child child, int daysAgo) {
    final today = child.today;
    if (today == null) return 0;
    final target = addDays(dateOnly(today.date), -daysAgo);
    var total = 0;
    for (final session in child.sessions) {
      final start = dateOnly(session.start);
      if (start != target) continue;
      final late =
          session.start.hour >= 22 ||
          session.start.hour < 4 ||
          session.end.hour >= 22 ||
          session.end.hour < 4;
      if (late) total += session.minutes;
    }
    return total;
  }

  static UsageApp? _newApp(Child child) {
    for (final app in child.apps) {
      if (app.last7Days.length < 7) continue;
      final firstActive = app.last7Days.indexWhere((minutes) => minutes > 0);
      if (firstActive >= 5 && app.todayMinutes > 0) return app;
    }
    return null;
  }
}
