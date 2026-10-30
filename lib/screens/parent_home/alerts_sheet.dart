import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/child_avatar.dart';
import '../../widgets/common.dart';
import 'day_shift.dart';

class AlertsSheet extends StatelessWidget {
  const AlertsSheet({
    super.key,
    required this.state,
    required this.onOpenChild,
  });

  final AppState state;
  final ValueChanged<Child> onOpenChild;

  @override
  Widget build(BuildContext context) {
    final sorted = [...state.children]
      ..sort((a, b) => b.dayOverDay.ratio.compareTo(a.dayOverDay.ratio));

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
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                context.strings.alerts,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              DemoPill(label: context.strings.demo),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.strings.alertsSubtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          for (final child in sorted) ...[
            AlertRow(
              child: child,
              onTap: () {
                Navigator.of(context).pop();
                onOpenChild(child);
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.strings.alertsDone,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertRow extends StatelessWidget {
  const AlertRow({super.key, required this.child, required this.onTap});

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = child.dayOverDay.ratio;
    final shift = dayShiftFor(child);
    final tint = dayShiftTint(shift);
    final title = switch (shift) {
      DayShift.flagged => context.strings.alertAbove(
        child.name,
        formatSignedPercent(ratio, strings: context.strings),
      ),
      DayShift.quieter => context.strings.alertWindingDown(child.name),
      DayShift.steady => context.strings.alertEvenKeel(child.name),
    };
    final detail = switch (shift) {
      DayShift.flagged => context.strings.alertDetailAbove(
        formatMinutes(child.todayMinutes, strings: context.strings),
        child.topApp?.name ?? context.strings.theirApps,
      ),
      DayShift.quieter => context.strings.alertDetailQuieter(
        formatMinutes(child.todayMinutes, strings: context.strings),
        formatMinutes(
          child.dayOverDay.difference.abs(),
          strings: context.strings,
        ),
      ),
      DayShift.steady => context.strings.alertDetailSteady(
        formatMinutes(child.todayMinutes, strings: context.strings),
      ),
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            ChildAvatar(child: child, size: 38, showDeviceBadge: false),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: tint),
          ],
        ),
      ),
    );
  }
}
