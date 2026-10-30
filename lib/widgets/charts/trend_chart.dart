part of '../charts.dart';

/// A fourteen-day trend line with a marked boundary between last week and the
/// current week.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.dates,
    required this.color,
    this.height = 140,
  });

  final List<int> values;
  final List<DateTime> dates;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Semantics(
      container: true,
      label: _semanticSummary(strings),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return SizedBox(
                  height: height,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      values: values,
                      color: color,
                      progress: progress,
                      splitIndex: values.length > 7 ? values.length - 7 : -1,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  dates.isEmpty
                      ? ''
                      : formatDateShort(dates.first, strings: strings),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtle,
                  ),
                ),
                const Spacer(),
                Text(
                  strings.last7DaysLower,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtle,
                  ),
                ),
                const Spacer(),
                Text(
                  strings.today,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

  String _semanticSummary(AppStrings strings) {
    if (values.isEmpty) return strings.fourteenDayNoData;
    final split = values.length > 7 ? values.length - 7 : values.length;
    final earlier = values.sublist(0, split);
    final recent = values.sublist(split);

    String average(List<int> days) {
      if (days.isEmpty) return strings.screenTimeNoData;
      final total = days.fold<int>(0, (sum, minutes) => sum + minutes);
      return formatMinutes((total / days.length).round(), strings: strings);
    }

    if (earlier.isEmpty) {
      return strings.trendSummarySingle(
        recent.length,
        average(recent),
        formatMinutes(values.last, strings: strings),
      );
    }
    return strings.trendSummary(
      average(earlier),
      recent.length,
      average(recent),
      formatMinutes(values.last, strings: strings),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.splitIndex,
  });

  final List<int> values;
  final Color color;
  final double progress;
  final int splitIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final points = _pointsFor(size);
    _paintSplitMarker(canvas, size, points);
    _paintGuides(canvas, size);

    final line = _smoothPath(points);
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    _paintSeries(canvas, size, line: line, area: area);
    _paintLastPoint(canvas, points.last);
  }

  /// Maps every value onto the canvas, reserving vertical room for the end dot.
  List<Offset> _pointsFor(Size size) {
    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final paddedRange = math.max(1.0, maxValue - minValue) * 1.35;
    final low = minValue - paddedRange * 0.12;

    return [
      for (var index = 0; index < values.length; index++)
        Offset(
          size.width * index / (values.length - 1),
          size.height -
              10 -
              ((values[index] - low) / paddedRange) * (size.height - 20),
        ),
    ];
  }

  /// A faint tint plus a dashed rule marks where the current week begins.
  void _paintSplitMarker(Canvas canvas, Size size, List<Offset> points) {
    if (splitIndex <= 0 || splitIndex >= values.length) return;

    final splitX = points[splitIndex].dx;
    canvas.drawRect(
      Rect.fromLTRB(splitX, 0, size.width, size.height),
      Paint()..color = color.withValues(alpha: 0.045),
    );

    const dashHeight = 4.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = AppColors.lineStrong
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += dashHeight + dashSpace) {
      canvas.drawLine(
        Offset(splitX, y),
        Offset(splitX, math.min(y + dashHeight, size.height)),
        paint,
      );
    }
  }

  /// Two dotted horizontal guides give the line a sense of scale.
  void _paintGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.9)
      ..strokeWidth = 1;
    for (final fraction in const [0.28, 0.72]) {
      final y = size.height * fraction;
      for (var x = 0.0; x < size.width; x += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, size.width), y),
          paint,
        );
      }
    }
  }

  /// Draws the filled area and the stroke, revealed left to right by [progress].
  void _paintSeries(
    Canvas canvas,
    Size size, {
    required Path line,
    required Path area,
  }) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  /// The end dot only appears once the reveal animation reaches the last point.
  void _paintLastPoint(Canvas canvas, Offset last) {
    if (progress <= 0.97) return;
    canvas.drawCircle(last, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 3.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) {
    return !listEquals(oldDelegate.values, values) ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.splitIndex != splitIndex;
  }
}
