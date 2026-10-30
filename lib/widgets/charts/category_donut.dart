part of '../charts.dart';

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

/// A donut with rounded arc caps and a total in the middle.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.slices,
    required this.total,
    this.size = 132,
    this.strokeWidth = 16,
  });

  final List<DonutSlice> slices;
  final int total;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Semantics(
      container: true,
      label: _semanticSummary(strings),
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return CustomPaint(
                    size: Size.square(size),
                    painter: _DonutPainter(
                      slices: slices,
                      total: total,
                      strokeWidth: strokeWidth,
                      progress: progress,
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(strokeWidth + 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMinutes(total, strings: strings),
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.thisWeekLower,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticSummary(AppStrings strings) {
    if (total <= 0 || slices.isEmpty) {
      return strings.categoryChartNoData;
    }
    final parts = <String>[
      for (final slice in slices)
        if (slice.value > 0)
          strings.categoryShare(
            slice.label,
            (slice.value / total * 100).round(),
          ),
    ];
    return strings.categorySummary(
      formatMinutes(total, strings: strings),
      parts.join(', '),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.strokeWidth,
    required this.progress,
  });

  final List<DonutSlice> slices;
  final int total;
  final double strokeWidth;
  final double progress;

  /// Space left between neighbouring arcs, in radians.
  static const _gap = 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    _paintTrack(canvas, center, radius);

    if (total <= 0) return;
    _paintSlices(canvas, Rect.fromCircle(center: center, radius: radius));
  }

  /// The empty ring drawn behind the data.
  void _paintTrack(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.parchment,
    );
  }

  void _paintSlices(Canvas canvas, Rect rect) {
    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * math.pi * 2;
      if (sweep <= _gap) continue;

      canvas.drawArc(
        rect,
        start + _gap / 2,
        (sweep - _gap) * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = slice.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return !_sameSlices(oldDelegate.slices, slices) ||
        oldDelegate.total != total ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }

  /// [DonutSlice] has no equality, so compare the fields that change the paint.
  static bool _sameSlices(List<DonutSlice> a, List<DonutSlice> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.label != right.label ||
          left.value != right.value ||
          left.color != right.color) {
        return false;
      }
    }
    return true;
  }
}
