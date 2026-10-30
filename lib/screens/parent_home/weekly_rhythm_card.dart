import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class WeeklyRhythmCard extends StatelessWidget {
  const WeeklyRhythmCard({
    super.key,
    required this.children,
    required this.familyAverage,
    required this.familyWeekRatio,
  });

  final List<Child> children;
  final int familyAverage;
  final double familyWeekRatio;

  @override
  Widget build(BuildContext context) {
    final maxAverage = children.fold<int>(
      1,
      (max, child) => math.max(max, child.weeklyAverage),
    );

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      radius: 24,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.insights_rounded,
                color: AppColors.violet,
                size: 36,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.weekSoFar,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.dailyAveragePerChild,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            RhythmRow(child: children[index], maxAverage: maxAverage),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.strings.familyAveragePerDay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMinutes(familyAverage, strings: context.strings),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 7),
              TrendChip(change: familyWeekRatio),
            ],
          ),
        ],
      ),
    );
  }
}

class RhythmRow extends StatelessWidget {
  const RhythmRow({super.key, required this.child, required this.maxAverage});

  final Child child;
  final int maxAverage;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAverage == 0
        ? 0.0
        : (child.weeklyAverage / maxAverage).clamp(0.0, 1.0);

    return Row(
      children: [
        SmallAvatar(initials: child.initials, color: child.accent, size: 28),
        const SizedBox(width: 9),
        SizedBox(
          width: 52,
          child: Text(
            child.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: child.accent.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(child.accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          child: Text(
            formatMinutes(child.weeklyAverage, strings: context.strings),
            textAlign: TextAlign.end,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
