part of '../charts.dart';

/// A simple seven-day bar chart. The last bar represents today and gets the
/// strongest treatment.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.minutes,
    required this.dates,
    required this.color,
    this.height = 128,
    this.barRadius = 6,
  });

  final List<int> minutes;
  final List<DateTime> dates;
  final Color color;
  final double height;
  final double barRadius;

  @override
  Widget build(BuildContext context) {
    final maxValue = minutes.fold(0, math.max);
    final lastIndex = minutes.length - 1;

    return Semantics(
      container: true,
      label: _semanticSummary(context.strings),
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < minutes.length; index++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _Bar(
                              fraction: maxValue == 0
                                  ? 0
                                  : minutes[index] / maxValue,
                              maxHeight: constraints.maxHeight,
                              active: index == lastIndex,
                              color: color,
                              radius: barRadius,
                              animationDelay: index * 35,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                for (var index = 0; index < dates.length; index++)
                  Expanded(
                    child: _WeekdayLabel(
                      label: weekdayLetter(
                        dates[index],
                        strings: context.strings,
                      ),
                      active: index == lastIndex,
                      color: color,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Spoken version of the bars, since colour and height are the only visual
  /// encoding. Kept short enough to be useful in a screen reader.
  String _semanticSummary(AppStrings strings) {
    if (minutes.isEmpty) return strings.weeklyChartNoData;
    final parts = <String>[];
    for (var index = 0; index < minutes.length; index++) {
      final label = index < dates.length
          ? weekdayShort(dates[index], strings: strings)
          : strings.dayNumber(index + 1);
      parts.add(
        strings.weeklyChartPart(
          label,
          formatMinutes(minutes[index], strings: strings),
          isToday: index == minutes.length - 1,
        ),
      );
    }
    return strings.weeklyChartSummary(parts.join(', '));
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.maxHeight,
    required this.active,
    required this.color,
    required this.radius,
    required this.animationDelay,
  });

  final double fraction;
  final double maxHeight;
  final bool active;
  final Color color;
  final double radius;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 620 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          height: math.max(5, maxHeight * value),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, Color.lerp(color, Colors.white, 0.34)!],
                  )
                : null,
            color: active ? null : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius),
              bottom: const Radius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

/// One weekday initial under the bar, with a dot marking today.
class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({
    required this.label,
    required this.active,
    required this.color,
  });

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.2,
            color: active ? AppColors.ink : AppColors.subtle,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
          ),
        ),
      ],
    );
  }
}
