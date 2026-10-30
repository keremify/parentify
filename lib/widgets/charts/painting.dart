part of '../charts.dart';

/// Builds a smooth path through a set of points using midpoint cubics.
Path _smoothPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final midX = (previous.dx + current.dx) / 2;
    path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
  }
  return path;
}
