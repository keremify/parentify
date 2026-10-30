import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../models/context_note.dart';
import '../../models/usage_driver.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'day_shift.dart';

class AttentionCard extends StatelessWidget {
  const AttentionCard({
    super.key,
    required this.child,
    required this.onTap,
    this.driver,
    this.note,
  });

  final Child child;
  final VoidCallback onTap;
  final UsageDriver? driver;
  final ContextNote? note;

  @override
  Widget build(BuildContext context) {
    final ratio = child.dayOverDay.ratio;
    final shift = dayShiftFor(child);
    final flagged = shift == DayShift.flagged;
    final tint = dayShiftTint(shift);

    final title = switch (shift) {
      DayShift.flagged => context.strings.attentionAbove(
        child.name,
        formatSignedPercent(ratio, strings: context.strings),
      ),
      DayShift.quieter => context.strings.attentionQuieter(child.name),
      DayShift.steady => context.strings.attentionSteady(child.name),
    };

    final detail = driver != null
        ? context.strings.attentionDriver(driver!.label, driver!.detail)
        : switch (shift) {
            DayShift.flagged =>
              child.topApp == null
                  ? context.strings.attentionAppUsageLeading
                  : context.strings.attentionAppLeading(child.topApp!.name),
            DayShift.quieter => context.strings.attentionDown(
              formatSignedPercent(ratio.abs(), strings: context.strings),
            ),
            DayShift.steady => context.strings.attentionSame,
          };

    return SoftCard(
      padding: const EdgeInsets.all(15),
      radius: 20,
      color: flagged ? AppColors.lemonSoft : AppColors.mintSoft,
      border: Border.all(color: tint.withValues(alpha: 0.22)),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                icon: flagged ? Icons.route_rounded : Icons.spa_rounded,
                color: tint,
                size: 40,
                background: AppColors.paper.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: tint),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.paper.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 12,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note!.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 9.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
