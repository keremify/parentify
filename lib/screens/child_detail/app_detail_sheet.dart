import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_usage.dart';
import '../../models/child.dart';
import '../../models/context_note.dart';
import '../../state/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/context_chip.dart';
import '../context_note_sheet.dart';

/// Displays the detailed breakdown sheet for an application.
Future<void> showAppDetailSheet(
  BuildContext context, {
  required Child child,
  required UsageApp app,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (_) => AppDetailSheet(child: child, app: app),
  );
}

/// App detail sheet showing weekly trend, stats, and contextual notes.
class AppDetailSheet extends StatelessWidget {
  const AppDetailSheet({super.key, required this.child, required this.app});

  final Child child;
  final UsageApp app;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final notes = state.notesForApp(child.id, app.id);
    final share = child.weekAppMinutes == 0
        ? 0.0
        : app.weekMinutes / child.weekAppMinutes;
    final strings = context.strings;

    void addNote() {
      showContextNoteSheet(
        context,
        childId: child.id,
        scope: NoteScope.app,
        targetId: app.id,
        title: strings.contextForApp(app.name),
        subtitle: strings.sharedWithFamily(child.name),
      );
    }

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
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Icon(app.icon, color: app.color, size: 28),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.categoryDevice(
                        strings.categoryLabel(app.category),
                        child.deviceName,
                      ),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
                size: 36,
                background: AppColors.cream,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                context.strings.appContext,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.subtle,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: addNote,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: Text(context.strings.addNote),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (notes.isEmpty)
            Text(
              context.strings.noAppNote,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            )
          else
            for (var index = 0; index < notes.length; index++) ...[
              if (index > 0) const SizedBox(height: 6),
              ContextNoteChip(note: notes[index]),
            ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SheetStat(
                    label: strings.today,
                    value: formatMinutes(app.todayMinutes, strings: strings),
                  ),
                ),
                _SheetDivider(),
                Expanded(
                  child: _SheetStat(
                    label: strings.dailyAverage,
                    value: formatMinutes(app.dailyAverage, strings: strings),
                  ),
                ),
                _SheetDivider(),
                Expanded(
                  child: _SheetStat(
                    label: strings.opensToday,
                    value: '${app.launchesToday}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                strings.last7Days,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.subtle,
                ),
              ),
              const Spacer(),
              Text(
                formatMinutes(app.weekMinutes, strings: strings),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          WeeklyBarChart(
            minutes: app.last7Days,
            dates: child.last7Days.map((day) => day.date).toList(),
            color: app.color,
            height: 100,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                strings.shareOfAppTime,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Text(
                strings.percent((share * 100).round()),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: app.color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(app.color),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 11,
                color: AppColors.subtle,
              ),
              const SizedBox(width: 5),
              Text(
                context.strings.simulatedUsage,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtle.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SheetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.line);
  }
}
