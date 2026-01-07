import 'dart:math' as math;

import 'package:flutter/material.dart';

Offset cubicBezierPoint(
  double t,
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
) {
  // Using Horner's method for better performance
  final u = 1 - t;
  final t2 = t * t;
  final u2 = u * u;
  final t3 = t2 * t;
  final u3 = u2 * u;

  // Optimized calculation
  final x = u3 * p0.dx + 3 * u2 * t * p1.dx + 3 * u * t2 * p2.dx + t3 * p3.dx;
  final y = u3 * p0.dy + 3 * u2 * t * p1.dy + 3 * u * t2 * p2.dy + t3 * p3.dy;

  return Offset(x, y);
}

bool isPointNearCubicBezier(
  Offset point,
  Offset start,
  Offset end,
  double threshold,
) {
  // Cache all coordinates
  final ctrl1X = start.dx + 200;
  final ctrl1Y = start.dy;
  final ctrl2X = end.dx - 200;
  final ctrl2Y = end.dy;
  final px = point.dx;
  final py = point.dy;
  final thresholdSq = threshold * threshold;

  // Ultra-fast AABB check
  final minX =
      math.min(math.min(start.dx, end.dx), math.min(ctrl1X, ctrl2X)) -
      threshold;
  if (px < minX) return false;
  final maxX =
      math.max(math.max(start.dx, end.dx), math.max(ctrl1X, ctrl2X)) +
      threshold;
  if (px > maxX) return false;
  final minY =
      math.min(math.min(start.dy, end.dy), math.min(ctrl1Y, ctrl1Y)) -
      threshold;
  if (py < minY) return false;
  final maxY =
      math.max(math.max(start.dy, end.dy), math.max(ctrl1Y, ctrl2Y)) +
      threshold;
  if (py > maxY) return false;

  // Test endpoints
  double dx = start.dx - px;
  double dy = start.dy - py;
  if (dx * dx + dy * dy < thresholdSq) return true;

  dx = end.dx - px;
  dy = end.dy - py;
  if (dx * dx + dy * dy < thresholdSq) return true;

  // Flatness test - if curve is nearly flat, test as line segment
  final flatness = math.max(
    ((ctrl1X - start.dx) - (end.dx - ctrl1X)).abs() +
        ((ctrl1Y - start.dy) - (end.dy - ctrl1Y)).abs(),
    ((ctrl2X - start.dx) - (end.dx - ctrl2X)).abs() +
        ((ctrl2Y - start.dy) - (end.dy - ctrl2Y)).abs(),
  );

  if (flatness < 1.0) {
    // Treat as line segment
    final lineLength =
        (end.dx - start.dx) * (end.dx - start.dx) +
        (end.dy - start.dy) * (end.dy - start.dy);
    if (lineLength < 0.01) return false;

    final t = math.max(
      0.0,
      math.min(
        1.0,
        ((px - start.dx) * (end.dx - start.dx) +
                (py - start.dy) * (end.dy - start.dy)) /
            lineLength,
      ),
    );
    final closestX = start.dx + t * (end.dx - start.dx);
    final closestY = start.dy + t * (end.dy - start.dy);
    dx = closestX - px;
    dy = closestY - py;
    return dx * dx + dy * dy < thresholdSq;
  }

  // Adaptive sampling based on curve length
  // Approximate curve length using control polygon
  final polyLength =
      math.sqrt(
        (ctrl1X - start.dx) * (ctrl1X - start.dx) +
            (ctrl1Y - start.dy) * (ctrl1Y - start.dy),
      ) +
      math.sqrt(
        (ctrl2X - ctrl1X) * (ctrl2X - ctrl1X) +
            (ctrl2Y - ctrl1Y) * (ctrl2Y - ctrl1Y),
      ) +
      math.sqrt(
        (end.dx - ctrl2X) * (end.dx - ctrl2X) +
            (end.dy - ctrl2Y) * (end.dy - ctrl2Y),
      );

  // Ensure at least 1 sample per threshold distance for full coverage
  final samples = math.max(
    16,
    math.min(64, (polyLength / threshold).ceil()),
  );
  final step = 1.0 / samples;

  // Track previous point to check line segments between samples
  double prevX = start.dx;
  double prevY = start.dy;

  for (var i = 1; i <= samples; i++) {
    final t = i * step;
    final u = 1 - t;
    final u2 = u * u;
    final t2 = t * t;
    final u3 = u2 * u;
    final t3 = t2 * t;
    final term1 = 3 * u2 * t;
    final term2 = 3 * u * t2;

    final cx = u3 * start.dx + term1 * ctrl1X + term2 * ctrl2X + t3 * end.dx;
    final cy = u3 * start.dy + term1 * ctrl1Y + term2 * ctrl2Y + t3 * end.dy;

    // Test current point
    dx = cx - px;
    dy = cy - py;
    if (dx * dx + dy * dy < thresholdSq) return true;

    // Test line segment from previous to current point
    final segLenSq = (cx - prevX) * (cx - prevX) + (cy - prevY) * (cy - prevY);
    if (segLenSq > 0.01) {
      final segT = math.max(
        0.0,
        math.min(
          1.0,
          ((px - prevX) * (cx - prevX) + (py - prevY) * (cy - prevY)) /
              segLenSq,
        ),
      );
      final closestX = prevX + segT * (cx - prevX);
      final closestY = prevY + segT * (cy - prevY);
      dx = closestX - px;
      dy = closestY - py;
      if (dx * dx + dy * dy < thresholdSq) return true;
    }

    prevX = cx;
    prevY = cy;
  }

  return false;
}
