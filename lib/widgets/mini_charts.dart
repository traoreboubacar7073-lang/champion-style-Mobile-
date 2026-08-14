import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'shared_widgets.dart';

/// Petit graphique en courbe (ex : chiffre d'affaires par mois) — dessiné
/// directement en Flutter, sans dépendance externe à un paquet de graphes.
class LineChartPoint {
  final String label;
  final double value;
  const LineChartPoint(this.label, this.value);
}

class MiniLineChart extends StatelessWidget {
  final List<LineChartPoint> points;
  final Color color;
  final double height;
  const MiniLineChart({super.key, required this.points, required this.color, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LineChartPainter(points: points, color: color)),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartPoint> points;
  final Color color;
  _LineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxVal = points.map((p) => p.value).fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;

    double yFor(double value) => size.height - (value / safeMax) * (size.height - 16) - 8;
    double xFor(int i) => points.length > 1 ? i * stepX : size.width / 2;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = xFor(i);
      final y = yFor(points[i].value);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(xFor(points.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    final dotHalo = Paint()..color = color.withOpacity(0.25);
    for (int i = 0; i < points.length; i++) {
      final offset = Offset(xFor(i), yFor(points[i].value));
      canvas.drawCircle(offset, 6, dotHalo);
      canvas.drawCircle(offset, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

/// Petit anneau de répartition (ex : commandes par statut) — un segment
/// coloré par catégorie, avec un total affiché au centre.
class DonutSegment {
  final String label;
  final double value;
  final Color color;
  const DonutSegment(this.label, this.value, this.color);
}

class MiniDonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final String centerLabel;
  final String centerSubLabel;
  const MiniDonutChart({super.key, required this.segments, this.size = 130, required this.centerLabel, required this.centerSubLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(segments: segments)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel, style: TextStyle(fontSize: size * 0.19, fontWeight: FontWeight.w700, color: context.textPrimary)),
              Text(centerSubLabel, style: TextStyle(fontSize: size * 0.085, color: context.textFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, seg) => s + seg.value);
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);

    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
