import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';
import '../../utils/dates.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class FamilyCard extends StatelessWidget {
  const FamilyCard({
    super.key,
    required this.children,
    required this.familyToday,
    required this.familyYesterday,
    required this.dayRatio,
    required this.week,
    required this.weekTotal,
  });

  final List<Child> children;
  final int familyToday;
  final int familyYesterday;
  final double dayRatio;
  final List<int> week;
  final int weekTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.inkCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -64,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -100,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.violet.withValues(alpha: 0.38),
                    AppColors.violet.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.mintBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        context.strings.familyTodayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.devices_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.strings.deviceCount(children.length),
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatMinutes(familyToday, strings: context.strings),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: TrendChip(change: dayRatio, onDark: true),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  context.strings.versusYesterday(
                    formatMinutes(familyYesterday, strings: context.strings),
                  ),
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      context.strings.last7Days,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMinutes(weekTotal, strings: context.strings),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                FamilyBars(values: week, today: AppClock.now()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyBars extends StatelessWidget {
  const FamilyBars({super.key, required this.values, required this.today});

  final List<int> values;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold(0, math.max);
    final minValue = values.isEmpty ? 0 : values.reduce(math.min);
    final span = maxValue - minValue;
    // Family daily totals sit in a narrow band, so a straight 0..max scale
    // flattens into identical bars. Anchor the scale to the week's own range
    // (with a 42% floor) to keep subtle day-to-day movement readable.
    final levels = [
      for (final value in values)
        maxValue == 0
            ? 0.0
            : span == 0
            ? 1.0
            : 0.42 + 0.58 * ((value - minValue) / span),
    ];
    final start = addDays(dateOnly(today), 1 - values.length);

    return SizedBox(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: levels[index]),
                          duration: Duration(milliseconds: 600 + index * 40),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            final isToday = index == values.length - 1;
                            return Container(
                              height: math.max(4, 34 * value),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.mintBright
                                    : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      weekdayLetter(
                        addDays(start, index),
                        strings: context.strings,
                      ),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(
                          alpha: index == values.length - 1 ? 0.9 : 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
