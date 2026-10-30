import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../models/context_note.dart';
import '../../models/visibility.dart';
import '../../services/ai_analyzer_service.dart';
import '../../services/change_explainer.dart';
import '../../state/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/usage_widgets.dart';
import '../context_note_sheet.dart';
import 'explainer.dart';
import 'patterns.dart';
import 'sharing_note.dart';

/// Insights tab displaying AI analysis, change drivers, rhythm signals, and actionable ideas.
class InsightsTab extends StatelessWidget {
  const InsightsTab({
    super.key,
    required this.child,
    required this.report,
    required this.gutter,
    required this.analyzing,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.childMode,
  });

  final Child child;
  final AiReport report;
  final double gutter;
  final bool analyzing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final bool childMode;

  void _addSessionNote(BuildContext context, UsageSession session) {
    showContextNoteSheet(
      context,
      childId: child.id,
      scope: NoteScope.session,
      targetId: session.id,
      title: context.strings.whatWasThisStretch,
      subtitle: context.strings.sessionSubtitle(
        relativeDay(session.start, strings: context.strings),
        formatMinutes(session.minutes, strings: context.strings),
        session.label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hasKey = state.ai.hasApiKey;
    final level = state.isChild
        ? VisibilityLevel.full
        : state.visibilityFor(child.id);
    final showDetail = level != VisibilityLevel.trends;
    final showFullDetail = level == VisibilityLevel.full;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 42),
      children: [
        if (!state.isChild && level != VisibilityLevel.full) ...[
          SharingNote(child: child, level: level),
          const SizedBox(height: 14),
        ],
        if (showDetail) ...[
          _AskChips(child: child),
          const SizedBox(height: 12),
        ],
        _AiAnalysisCard(
          child: child,
          report: report,
          analyzing: analyzing,
          hasKey: hasKey,
          onRefresh: onRefresh,
          onOpenSettings: onOpenSettings,
        ),
        const SizedBox(height: 26),
        SectionHeader(
          title: context.strings.whatChanged,
          subtitle: context.strings.whatChangedSubtitle,
        ),
        const SizedBox(height: 11),
        if (showDetail) ...[
          WhyChangedCard(child: child),
          const SizedBox(height: 12),
        ],
        ChangeCard(child: child),
        if (showFullDetail) ...[
          const SizedBox(height: 26),
          SectionHeader(
            title: context.strings.whatAnalysisNoticed,
            subtitle: context.strings.smallSignals,
          ),
          const SizedBox(height: 11),
          ObservationsCard(observations: report.observations),
          const SizedBox(height: 26),
          SectionHeader(
            title: context.strings.whenDeviceBusiest,
            subtitle: context.strings.todayHourByHour,
          ),
          const SizedBox(height: 11),
          PeakCard(child: child),
          const SizedBox(height: 26),
          SectionHeader(
            title: context.strings.longestStretches,
            subtitle: context.strings.continuousSessions,
            actionLabel: context.strings.sessionCount(child.sessions.length),
          ),
          const SizedBox(height: 11),
          for (
            var index = 0;
            index < child.longestSessions.length;
            index++
          ) ...[
            if (index > 0) const SizedBox(height: 9),
            SessionCard(
              session: child.longestSessions[index],
              maxMinutes: child.maxSessionMinutes,
              showTime: true,
              note: state.noteForSession(
                child.id,
                child.longestSessions[index].id,
              ),
              onAddNote: () =>
                  _addSessionNote(context, child.longestSessions[index]),
            ),
          ],
        ],
        const SizedBox(height: 26),
        SectionHeader(
          title: childMode
              ? context.strings.ideasForFamily
              : context.strings.ideasToTry,
          subtitle: context.strings.gentleNotRigid,
        ),
        const SizedBox(height: 11),
        for (var index = 0; index < report.suggestions.length; index++) ...[
          if (index > 0) const SizedBox(height: 9),
          SuggestionCard(
            index: index + 1,
            suggestion: report.suggestions[index],
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.strings.aboutThisAnalysis,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  DemoPill(
                    label: hasKey
                        ? context.strings.geminiBadge
                        : context.strings.demo,
                    icon: null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hasKey
                    ? context.strings.aboutAnalysisWithKey
                    : context.strings.aboutAnalysisDemo,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onOpenSettings,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(
                    hasKey
                        ? context.strings.manageAiKey
                        : context.strings.connectGeminiOptional,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({
    required this.child,
    required this.report,
    required this.analyzing,
    required this.hasKey,
    required this.onRefresh,
    required this.onOpenSettings,
  });

  final Child child;
  final AiReport report;
  final bool analyzing;
  final bool hasKey;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.violetCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lemon.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.strings.aiCheckIn,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.strings.dayOverDayWeekOverWeek,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    DemoPill(
                      onDark: true,
                      label: hasKey
                          ? context.strings.geminiBadge
                          : context.strings.demo,
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: analyzing
                      ? const _AnalyzingState(key: ValueKey('analyzing'))
                      : _ReportState(
                          key: ValueKey(
                            report.createdAt.millisecondsSinceEpoch,
                          ),
                          report: report,
                        ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        hasKey
                            ? context.strings.geminiSendsOnRefresh
                            : context.strings.demoRunsOnDevice,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      enabled: !analyzing,
                      label: context.strings.refreshAnalysis,
                      onTap: onRefresh,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onRefresh,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: analyzing
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.strings.refresh,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: analyzing
                                      ? Colors.white38
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Semantics(
                  button: true,
                  label: hasKey
                      ? context.strings.manageAiKey
                      : context.strings.connectGemini,
                  onTap: onOpenSettings,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onOpenSettings,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.key_rounded,
                            size: 12,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasKey
                                ? context.strings.manageAiKey
                                : context.strings.connectGeminiOptional,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 11,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportState extends StatelessWidget {
  const _ReportState({super.key, required this.report});

  final AiReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.headline,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 21,
            height: 1.24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          report.summary,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11.5,
            height: 1.6,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 11, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              context.strings.updated(
                formatSyncedAt(report.createdAt, strings: context.strings),
              ),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  const _AnalyzingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.strings.reading14Days,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final factor in [0.82, 0.95, 0.62]) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: factor,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

/// Three local questions above the AI card. Each answer is deterministic and
/// built from the same data as the rest of the screen.
class _AskChips extends StatefulWidget {
  const _AskChips({required this.child});

  final Child child;

  @override
  State<_AskChips> createState() => _AskChipsState();
}

class _AskChipsState extends State<_AskChips> {
  InsightQuestion? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 14,
              color: AppColors.muted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.strings.askAboutToday,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.subtle,
                ),
              ),
            ),
            Text(
              context.strings.localAnswers,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.subtle.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final question in InsightQuestion.values)
              Semantics(
                button: true,
                selected: _selected == question,
                label: _insightQuestionLabel(context.strings, question),
                onTap: () => setState(
                  () => _selected = _selected == question ? null : question,
                ),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => setState(
                    () => _selected = _selected == question ? null : question,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 17,
                    ),
                    decoration: BoxDecoration(
                      color: _selected == question
                          ? AppColors.violetSoft
                          : AppColors.paper,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _selected == question
                            ? AppColors.violet.withValues(alpha: 0.45)
                            : AppColors.line,
                      ),
                    ),
                    child: Text(
                      _insightQuestionLabel(context.strings, question),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _selected == question
                            ? AppColors.violet
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _selected == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.violetSoft.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.violet.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppColors.violet,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _insightQuestionLabel(
                                context.strings,
                                _selected!,
                              ),
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: AppColors.violet,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              context.strings.onDevice,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.subtle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ChangeExplainer.answerFor(
                            widget.child,
                            _selected!,
                            strings: context.strings,
                          ),
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

String _insightQuestionLabel(AppStrings strings, InsightQuestion question) =>
    switch (question) {
      InsightQuestion.whyChange => strings.whyItChanged,
      InsightQuestion.bedtime => strings.bedtime,
      InsightQuestion.week => strings.thisWeek,
    };
