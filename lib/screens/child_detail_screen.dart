import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_usage.dart';
import '../models/child.dart';
import '../models/visibility.dart';
import '../services/ai_analyzer_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand.dart';
import '../widgets/child_avatar.dart';
import '../widgets/common.dart';
import 'child_detail/child_detail.dart';
import 'settings_sheet.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({
    super.key,
    required this.child,
    this.initialTab = 0,
    this.childMode = false,
  });

  final Child child;
  final int initialTab;
  final bool childMode;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  static const _tabIcons = [
    Icons.space_dashboard_rounded,
    Icons.grid_view_rounded,
    Icons.auto_awesome_rounded,
  ];

  late int _tab = widget.initialTab.clamp(0, 2).toInt();
  late AiReport _report;
  bool _reportInitialized = false;
  AppStrings? _reportStrings;
  bool _includeAppDetail = true;
  bool _analyzing = false;
  DateTime? _appliedCheckInAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = context.strings;
    final state = AppScope.of(context);
    final checkIn = state.lastCheckIn;
    final childCheckIn = checkIn != null && checkIn.childId == widget.child.id
        ? checkIn
        : null;

    final stringsChanged = !identical(_reportStrings, strings);
    final checkInChanged =
        childCheckIn != null && _appliedCheckInAt != childCheckIn.completedAt;
    final includeAppDetail = _detailAllowed(state);

    if (!_reportInitialized ||
        stringsChanged ||
        checkInChanged ||
        includeAppDetail != _includeAppDetail) {
      _report = AiAnalyzerService.buildLocalReport(
        widget.child,
        lastCheckIn: childCheckIn,
        strings: strings,
        includeAppDetail: includeAppDetail,
      );
      _reportInitialized = true;
      _reportStrings = strings;
      _appliedCheckInAt = childCheckIn?.completedAt;
      _includeAppDetail = includeAppDetail;
    }
  }

  /// App-level detail stays available to the child's own view and to parents
  /// who have not chosen the `trends` sharing level.
  bool _detailAllowed(AppState state) =>
      state.isChild ||
      state.visibilityFor(widget.child.id) != VisibilityLevel.trends;

  Future<void> _refreshAnalysis() async {
    if (_analyzing) return;
    final state = AppScope.read(context);
    setState(() => _analyzing = true);

    try {
      final outcome = await state.ai.analyze(
        widget.child,
        notes: state.notesFor(widget.child.id),
        agreement: state.activeAgreementFor(widget.child.id),
        lastCheckIn: state.lastCheckIn,
        strings: context.strings,
        includeAppDetail: _detailAllowed(state),
      );
      if (!mounted) return;

      setState(() => _report = outcome.report);
      if (outcome.notice != null) {
        _showAnalysisMessage(context.strings.analysisNotice(outcome.notice!));
      } else if (outcome.usedModel) {
        _showAnalysisMessage(context.strings.analysisRefreshedGemini);
      } else {
        _showAnalysisMessage(context.strings.analysisRefreshedDemo);
      }
    } catch (_) {
      if (!mounted) return;
      _showAnalysisMessage(context.strings.analysisRefreshFailed);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _showAnalysisMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAppDetails(UsageApp app) {
    showAppDetailSheet(context, child: widget.child, app: app);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final gutter = AppTheme.gutter(context);
    final canGoBack = !widget.childMode && Navigator.of(context).canPop();

    final Widget tabView;
    switch (_tab) {
      case 0:
        tabView = OverviewTab(
          key: const ValueKey('overview'),
          child: child,
          report: _report,
          gutter: gutter,
          onOpenApps: () => setState(() => _tab = 1),
          onOpenInsights: () => setState(() => _tab = 2),
          onOpenApp: _showAppDetails,
        );
      case 1:
        tabView = AppsTab(
          key: const ValueKey('apps'),
          child: child,
          gutter: gutter,
          onOpenApp: _showAppDetails,
        );
      default:
        tabView = InsightsTab(
          key: const ValueKey('insights'),
          child: child,
          report: _report,
          gutter: gutter,
          analyzing: _analyzing,
          onRefresh: _refreshAnalysis,
          onOpenSettings: () =>
              showParentifySettings(context, childMode: widget.childMode),
          childMode: widget.childMode,
        );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
              child: Row(
                children: [
                  if (canGoBack)
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                      size: 40,
                      background: AppColors.paper,
                      tooltip: context.strings.backToFamily,
                    )
                  else
                    const BrandMark(size: 36),
                  const SizedBox(width: 10),
                  ChildAvatar(
                    child: child,
                    size: 40,
                    heroTag: 'child-avatar-${child.id}',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.childMode
                              ? context.strings.childGreeting(child.name)
                              : child.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.ink,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                context.strings.deviceSyncLine(
                                  child.deviceName,
                                  formatSyncedAt(
                                    child.lastSyncedAt,
                                    strings: context.strings,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: Icons.tune_rounded,
                    onPressed: () => showParentifySettings(
                      context,
                      childMode: widget.childMode,
                    ),
                    size: 40,
                    background: AppColors.paper,
                    tooltip: context.strings.settings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: TabSwitcher(
                index: _tab,
                labels: [
                  context.strings.overviewTab,
                  context.strings.appsTab,
                  context.strings.insightsTab,
                ],
                icons: _tabIcons,
                onChanged: (index) => setState(() => _tab = index),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: tabView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
