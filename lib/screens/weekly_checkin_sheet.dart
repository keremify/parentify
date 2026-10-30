import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/check_in_record.dart';
import '../models/child.dart';
import '../services/ai_analyzer_service.dart';
import '../services/change_explainer.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import '../utils/dates.dart';
import '../widgets/child_avatar.dart';
import '../widgets/common.dart';

/// The weekly ritual. Three cards turn the report into one conversation and
/// remember the topic for next week's analysis.
Future<void> showWeeklyCheckInSheet(
  BuildContext context, {
  required Child child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => _WeeklyCheckInSheet(child: child),
  );
}

class _WeeklyCheckInSheet extends StatefulWidget {
  const _WeeklyCheckInSheet({required this.child});

  final Child child;

  @override
  State<_WeeklyCheckInSheet> createState() => _WeeklyCheckInSheetState();
}

class _WeeklyCheckInSheetState extends State<_WeeklyCheckInSheet> {
  int _selected = 1;
  bool _saved = false;
  bool _alreadyDone = false;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    final thisWeek = _weekStart(AppClock.now());
    _alreadyDone = state.checkInHistory.any(
      (record) =>
          record.childId == widget.child.id &&
          _weekStart(record.weekStart) == thisWeek,
    );
  }

  void _save() {
    final state = AppScope.read(context);
    final options = _options(state);
    final option = options[_selected];
    state.completeCheckIn(
      CheckInRecord(
        childId: widget.child.id,
        weekStart: _weekStart(AppClock.now()),
        topic: option.topic,
        question: option.question,
        completedAt: AppClock.now(),
      ),
    );
    setState(() {
      _saved = true;
      _alreadyDone = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.checkInSaved(option.topic))),
    );
  }

  List<_CheckInOption> _options(AppState state) {
    final strings = context.strings;
    final last = _lastCheckInFor(state, widget.child.id);
    final drivers = ChangeExplainer.explainDay(
      widget.child,
      limit: 1,
      strings: strings,
    );
    final driver = drivers.isEmpty ? null : drivers.first;
    final report = AiAnalyzerService.buildLocalReport(
      widget.child,
      lastCheckIn: last,
      strings: strings,
    );
    final trySuggestion = report.suggestions.first;
    final topApp = widget.child.topApp;
    final topAppName = topApp?.name ?? strings.theirApps;
    final topAppCategory = topApp == null
        ? strings.screenTimeFallback
        : strings.categoryLabel(topApp.category).toLowerCase();

    return [
      _CheckInOption(
        label: strings.noticedBadge,
        icon: Icons.visibility_outlined,
        color: AppColors.sky,
        title: driver == null
            ? strings.steadyWeek(widget.child.name)
            : strings.biggestChange(driver.label),
        detail: driver == null
            ? strings.rhythmHeld
            : strings.driverToday(driver.detail),
        topic: strings.weekRhythmTopic,
        question: strings.weekRhythmQuestion,
      ),
      _CheckInOption(
        label: strings.askBadge,
        icon: Icons.forum_outlined,
        color: AppColors.violet,
        title: strings.topAppWorthQuestion(topAppName),
        detail: last == null
            ? strings.questionOpensMore(widget.child.name)
            : strings.lastWeekTalked(last.topic),
        topic: topAppCategory,
        question: strings.topAppWorthQuestionThisWeek(topAppName),
      ),
      _CheckInOption(
        label: strings.tryBadge,
        icon: Icons.eco_outlined,
        color: AppColors.mint,
        title: trySuggestion.title,
        detail: trySuggestion.detail,
        topic: strings.windDownTopic,
        question: strings.windDownQuestion,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final state = AppScope.of(context);
    final options = _options(state);
    final streak = state.checkInStreak;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBubble(
                icon: Icons.event_available_outlined,
                color: AppColors.mint,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.weeklyCheckInTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.checkInSubtitle(widget.child.name),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
                size: 34,
                background: AppColors.cream,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChildAvatar(child: widget.child, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.child.name,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_outlined,
                        size: 13,
                        color: AppColors.mint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.streakWeeks(streak),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_alreadyDone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.mint.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.mint,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      strings.checkInDone,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            strings.pickOneFocus,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.subtle,
            ),
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < options.length; index++) ...[
            if (index > 0) const SizedBox(height: 9),
            _CheckInCard(
              option: options[index],
              selected: _selected == index,
              onTap: () => setState(() => _selected = index),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.memory_rounded,
                  size: 14,
                  color: AppColors.violet,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _saved
                        ? strings.savedFocus(options[_selected].topic)
                        : strings.savingFocusReminder,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 9.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_saved)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(strings.done),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.favorite_outline_rounded, size: 18),
              label: Text(strings.talkedAboutThis),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
        ],
      ),
    );
  }

  static DateTime _weekStart(DateTime date) => startOfWeek(date);

  static CheckInRecord? _lastCheckInFor(AppState state, String childId) {
    for (final record in state.checkInHistory) {
      if (record.childId == childId) return record;
    }
    return null;
  }
}

class _CheckInOption {
  const _CheckInOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.topic,
    required this.question,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String topic;
  final String question;
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CheckInOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected
                  ? option.color.withValues(alpha: 0.07)
                  : AppColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? option.color.withValues(alpha: 0.45)
                    : AppColors.line,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(
                  icon: option.icon,
                  color: option.color,
                  size: 36,
                  radius: 12,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: option.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.detail,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected ? option.color : AppColors.subtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
