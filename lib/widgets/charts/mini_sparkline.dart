part of '../charts.dart';

/// A small, smooth trend line for compact cards.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 34,
    this.strokeWidth = 2.2,
    this.showDot = true,
  });

  final List<int> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _semanticSummary(context.strings),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              color: color,
              strokeWidth: strokeWidth,
              showDot: showDot,
            ),
          ),
        ),
      ),
    );
  }

  String _semanticSummary(AppStrings strings) {
    if (values.isEmpty) return strings.recentTrendNoData;
    final lowest = values.reduce(math.min);
    final highest = values.reduce(math.max);
    return strings.recentTrendSummary(
      formatMinutes(lowest, strings: strings),
      formatMinutes(highest, strings: strings),
      formatMinutes(values.last, strings: strings),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.showDot,
  });

  final List<int> values;
  final Color color;
  final double strokeWidth;
  final bool showDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0) return;

    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final range = math.max(1.0, maxValue - minValue);
    const verticalPadding = 4.0;
    final chartHeight = size.height - verticalPadding * 2;

    final points = <Offset>[
      for (var index = 0; index < values.length; index++)
        Offset(
          size.width * index / (values.length - 1),
          size.height -
              verticalPadding -
              ((values[index] - minValue) / range) * chartHeight,
        ),
    ];

    final line = _smoothPath(points);
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showDot) {
      final last = points.last;
      canvas.drawCircle(last, strokeWidth + 2.2, Paint()..color = Colors.white);
      canvas.drawCircle(last, strokeWidth + 0.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return !listEquals(oldDelegate.values, values) ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showDot != showDot;
  }
}
