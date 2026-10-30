part of '../charts.dart';

/// Twenty-four small bars that reveal the shape of the day.
class HourlyActivityStrip extends StatelessWidget {
  const HourlyActivityStrip({
    super.key,
    required this.hourly,
    required this.color,
    this.height = 62,
  });

  final List<int> hourly;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = hourly.fold(0, math.max);
    final peak = hourly.isEmpty ? 0 : hourly.indexOf(maxValue);
    final strings = context.strings;

    return Semantics(
      container: true,
      label: _semanticSummary(strings),
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
                      for (var hour = 0; hour < hourly.length; hour++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.3,
                            ),
                            child: _HourlyBar(
                              fraction: maxValue == 0
                                  ? 0
                                  : hourly[hour] / maxValue,
                              maxHeight: constraints.maxHeight,
                              isPeak: hour == peak,
                              delayMs: hour * 18,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HourLabel(strings.hour12a),
                _HourLabel(strings.hour6a),
                _HourLabel(strings.hour12p),
                _HourLabel(strings.hour6p),
                _HourLabel(strings.hour12a),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _semanticSummary(AppStrings strings) {
    if (hourly.isEmpty) return strings.hourlyChartNoData;
    final peak = hourly.indexOf(hourly.fold(0, math.max));
    final total = hourly.fold<int>(0, (sum, minutes) => sum + minutes);
    return strings.hourlySummary(
      formatMinutes(total, strings: strings),
      formatHourLabel(peak, strings: strings),
      formatMinutes(hourly[peak], strings: strings),
    );
  }
}

class _HourLabel extends StatelessWidget {
  const _HourLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: AppColors.subtle,
      ),
    );
  }
}

/// A single hour's bar, scaled against the busiest hour of the day.
class _HourlyBar extends StatelessWidget {
  const _HourlyBar({
    required this.fraction,
    required this.maxHeight,
    required this.isPeak,
    required this.delayMs,
    required this.color,
  });

  final double fraction;
  final double maxHeight;
  final bool isPeak;
  final int delayMs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: Duration(milliseconds: 500 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          height: math.max(4, maxHeight * value * (isPeak ? 1 : 0.88)),
          decoration: BoxDecoration(
            color: isPeak
                ? color
                : color.withValues(alpha: 0.18 + value * 0.34),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}
