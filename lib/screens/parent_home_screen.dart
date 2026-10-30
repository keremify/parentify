import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/agreement.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../models/usage_driver.dart';
import '../services/change_explainer.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import '../widgets/agreement_card.dart';
import '../widgets/common.dart';
import 'agreement_sheet.dart';
import 'child_detail_screen.dart';
import 'parent_home/alerts_sheet.dart';
import 'parent_home/attention_card.dart';
import 'parent_home/check_in_card.dart';
import 'parent_home/child_carousel.dart';
import 'parent_home/family_balance_card.dart';
import 'parent_home/family_card.dart';
import 'parent_home/home_header.dart';
import 'parent_home/weekly_rhythm_card.dart';
import 'settings_sheet.dart';
import 'weekly_checkin_sheet.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  void _openChild(BuildContext context, Child child, {int initialTab = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildDetailScreen(child: child, initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final gutter = AppTheme.gutter(context);
    final now = AppClock.now();
    final attention = state.childNeedingAttention;
    final (attentionDriver, attentionNote) = _resolveAttentionDriverAndNote(
      attention,
      state,
      context.strings,
    );

    final familyWeek = state.familyWeekByDay;
    final familyWeekTotal = state.familyWeekTotal;
    final familyYesterday = state.familyYesterdayMinutes;
    final familyToday = state.familyTodayMinutes;
    final familyDayRatio = state.familyDayRatio;
    final familyWeekRatio = state.familyWeekRatio;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: HomeHeader(
                  state: state,
                  now: now,
                  hasPending: state.pendingRequests.isNotEmpty,
                  onOpenSettings: () => showParentifySettings(context),
                  onOpenAlerts: () => _showAlerts(context, state),
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: FamilyCard(
                  children: state.children,
                  familyToday: familyToday,
                  familyYesterday: familyYesterday,
                  dayRatio: familyDayRatio,
                  week: familyWeek,
                  weekTotal: familyWeekTotal,
                ),
              ),
              const SizedBox(height: 30),
              if (state.pendingRequests.isNotEmpty) ...[
                SectionHeader(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  title: context.strings.waitingForYou,
                  subtitle: context.strings.waitingForYouSubtitle,
                  actionLabel: context.strings.requestCount(
                    state.pendingRequests.length,
                  ),
                ),
                const SizedBox(height: 11),
                for (final request in state.pendingRequests)
                  _pendingRequestCard(context, state, request, gutter),
                const SizedBox(height: 17),
              ],
              SectionHeader(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                title: context.strings.chooseChild,
                subtitle: context.strings.chooseChildSubtitle,
                actionLabel: context.strings.profileCount(
                  state.children.length,
                ),
              ),
              const SizedBox(height: 12),
              ChildCarousel(
                children: state.children,
                gutter: gutter,
                onTap: (child) => _openChild(context, child),
              ),
              if (attention != null) ...[
                const SizedBox(height: 28),
                SectionHeader(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  title: context.strings.worthALook,
                  subtitle: context.strings.worthALookSubtitle,
                ),
                const SizedBox(height: 11),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: AttentionCard(
                    child: attention,
                    driver: attentionDriver,
                    note: attentionNote,
                    onTap: () => _openChild(context, attention, initialTab: 2),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: WeeklyRhythmCard(
                  children: state.children,
                  familyAverage: state.familyWeeklyAverage,
                  familyWeekRatio: familyWeekRatio,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: CheckInCard(
                  state: state,
                  onTap: () => _openCheckIn(context, state),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: FamilyBalanceCard(
                  state: state,
                  onToggle: () =>
                      state.setIncludeParentUsage(!state.includeParentUsage),
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: AppColors.subtle,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          context.strings.localDemoNoDataLeaves,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtle.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (UsageDriver?, ContextNote?) _resolveAttentionDriverAndNote(
    Child? attention,
    AppState state,
    AppStrings strings,
  ) {
    if (attention == null) return (null, null);

    final attentionDrivers = ChangeExplainer.explainDay(
      attention,
      limit: 4,
      strings: strings,
    );
    final attentionRising = attention.dayOverDay.difference >= 0;
    final attentionNotes = state.notesFor(attention.id);

    ContextNote? noteForDriver(UsageDriver driver) {
      for (final note in attentionNotes) {
        if (note.scope != NoteScope.app) continue;
        final matchesApp = attention.apps.any(
          (app) => app.id == note.targetId && app.name == driver.label,
        );
        if (matchesApp) return note;
      }
      return null;
    }

    final preferredDrivers = attentionDrivers
        .where(
          (driver) =>
              driver.isAttribution && driver.isHigher == attentionRising,
        )
        .toList();
    final driversWithNotes = preferredDrivers
        .where((driver) => noteForDriver(driver) != null)
        .toList();
    final attentionDriver = driversWithNotes.isNotEmpty
        ? driversWithNotes.first
        : preferredDrivers.isNotEmpty
        ? preferredDrivers.first
        : attentionDrivers.isEmpty
        ? null
        : attentionDrivers.first;
    final dayNotes = attentionNotes
        .where((note) => note.scope == NoteScope.day)
        .toList();
    final fallbackNote = dayNotes.isNotEmpty
        ? dayNotes.first
        : (attentionNotes.isEmpty ? null : attentionNotes.first);
    final attentionNote = attentionDriver == null
        ? fallbackNote
        : noteForDriver(attentionDriver) ?? fallbackNote;

    return (attentionDriver, attentionNote);
  }

  Widget _pendingRequestCard(
    BuildContext context,
    AppState state,
    Agreement request,
    double gutter,
  ) {
    final child = state.childById(request.childId);
    if (child == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 9),
      child: PendingRequestCard(
        child: child,
        agreement: request,
        onReview: () => _reviewRequest(context, child, request),
      ),
    );
  }

  Future<void> _reviewRequest(
    BuildContext context,
    Child child,
    Agreement agreement,
  ) async {
    final status = await showAgreementReviewSheet(
      context,
      child: child,
      agreement: agreement,
    );
    if (status == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == AgreementStatus.active
              ? context.strings.agreementActivated(child.name)
              : context.strings.requestReplied,
        ),
      ),
    );
  }

  Future<void> _openCheckIn(BuildContext context, AppState state) async {
    final last = state.lastCheckIn;
    final child = last == null
        ? (state.children.isEmpty ? null : state.children.first)
        : state.childById(last.childId);
    if (child == null) return;
    await showWeeklyCheckInSheet(context, child: child);
  }

  void _showAlerts(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (sheetContext) => AlertsSheet(
        state: state,
        onOpenChild: (child) => _openChild(context, child, initialTab: 2),
      ),
    );
  }
}
