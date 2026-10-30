import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/agreement.dart';
import '../../models/app_usage.dart';
import '../../models/child.dart';
import '../../models/context_note.dart';
import '../../models/visibility.dart';
import '../../services/ai_analyzer_service.dart';
import '../../state/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';
import '../../utils/formatters.dart';
import '../../widgets/agreement_card.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/context_chip.dart';
import '../../widgets/usage_widgets.dart';
import '../agreement_sheet.dart';
import '../context_note_sheet.dart';
import 'sharing_note.dart';

part 'overview/context_strip.dart';
part 'overview/today_card.dart';
part 'overview/week_card.dart';
part 'overview/ai_teaser_card.dart';

/// Overview tab displaying the child's daily summary, week trend, active agreement, and AI teaser.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.child,
    required this.report,
    required this.gutter,
    required this.onOpenApps,
    required this.onOpenInsights,
    required this.onOpenApp,
  });

  final Child child;
  final AiReport report;
  final double gutter;
  final VoidCallback onOpenApps;
  final VoidCallback onOpenInsights;
  final ValueChanged<UsageApp> onOpenApp;

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

  Future<void> _askForTime(BuildContext context) async {
    final agreement = await showAgreementRequestSheet(context, child: child);
    if (agreement == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.requestSentToParent)),
    );
  }

  Future<void> _reviewRequest(BuildContext context, Agreement? pending) async {
    if (pending == null) return;
    final status = await showAgreementReviewSheet(
      context,
      child: child,
      agreement: pending,
    );
    if (status == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == AgreementStatus.active
              ? context.strings.planNowActive(child.name)
              : context.strings.replySavedHistory,
        ),
      ),
    );
  }

  Future<void> _adjustVisibility(BuildContext context) async {
    final saved = await showVisibilitySheet(context, child: child);
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.sharingLevelUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final topApps = child.appsByUsage.take(3).toList();
    final topSessions = child.longestSessions.take(3).toList();
    final today = AppClock.now();
    final pending = state.pendingRequestFor(child.id);
    final declined = state.latestDeclinedFor(child.id);
    final level = state.isChild
        ? VisibilityLevel.full
        : state.visibilityFor(child.id);
    final showDetail = level != VisibilityLevel.trends;
    final showFullDetail = level == VisibilityLevel.full;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 42),
      children: [
        if (state.isChild) ...[
          FamilyPlanCard(
            child: child,
            agreement: state.activeAgreementFor(child.id),
            pending: pending,
            declined: declined,
            visibility: state.visibilityFor(child.id),
            isChild: true,
            onAsk: () => _askForTime(context),
          ),
          const SizedBox(height: 14),
        ],
        _TodayCard(child: child, visibility: level),
        if (showDetail) ...[
          const SizedBox(height: 12),
          _ContextStrip(child: child),
        ],
        if (!state.isChild) ...[
          const SizedBox(height: 12),
          FamilyPlanCard(
            child: child,
            agreement: state.activeAgreementFor(child.id),
            pending: pending,
            declined: declined,
            visibility: state.visibilityFor(child.id),
            isChild: false,
            onAdjust: () => _adjustVisibility(context),
            onReview: pending == null
                ? null
                : () => _reviewRequest(context, pending),
          ),
        ],
        if (!state.isChild && level != VisibilityLevel.full) ...[
          const SizedBox(height: 10),
          SharingNote(child: child, level: level),
        ],
        const SizedBox(height: 14),
        _WeekCard(child: child),
        const SizedBox(height: 22),
        _AiTeaserCard(
          child: child,
          headline: report.headline,
          onTap: onOpenInsights,
        ),
        if (showFullDetail) ...[
          const SizedBox(height: 26),
          SectionHeader(
            title: context.strings.longestStretches,
            subtitle: context.strings.mostAbsorbedMoments,
            actionLabel: context.strings.seeAll,
            onAction: onOpenInsights,
          ),
          const SizedBox(height: 11),
          for (var index = 0; index < topSessions.length; index++) ...[
            if (index > 0) const SizedBox(height: 9),
            SessionCard(
              session: topSessions[index],
              maxMinutes: child.maxSessionMinutes,
              showTime: true,
              note: state.noteForSession(child.id, topSessions[index].id),
              onAddNote: () => _addSessionNote(context, topSessions[index]),
            ),
          ],
        ],
        if (showDetail) ...[
          const SizedBox(height: 26),
          SectionHeader(
            title: context.strings.appUsage,
            subtitle: context.strings.whereWeekWent,
            actionLabel: context.strings.allApps,
            onAction: onOpenApps,
          ),
          const SizedBox(height: 11),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            radius: 22,
            boxShadow: AppShadows.soft,
            child: Column(
              children: [
                for (var index = 0; index < topApps.length; index++) ...[
                  if (index > 0) const Divider(),
                  AppUsageRow(
                    app: topApps[index],
                    maxMinutes: child.topApp?.weekMinutes ?? 0,
                    onTap: level == VisibilityLevel.full
                        ? () => onOpenApp(topApps[index])
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              context.strings.sessionAppDetailPrivate,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtle,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Center(
          child: Text(
            context.strings.todayDateSimulated(
              formatDateShort(today, strings: context.strings),
            ),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtle,
            ),
          ),
        ),
      ],
    );
  }
}
