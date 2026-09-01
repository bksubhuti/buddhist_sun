import 'dart:math' as math;
import 'package:flutter/material.dart';

class DharmachakraIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DharmachakraIcon({
    Key? key,
    this.size = 20,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.primary;

    return CustomPaint(
      size: Size(size, size),
      painter: _DharmachakraPainter(color: iconColor),
    );
  }
}

class _DharmachakraPainter extends CustomPainter {
  final Color color;

  _DharmachakraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    final rimRadius = maxRadius * 0.78;
    final rimStroke = maxRadius * 0.11;
    final spokeStroke = maxRadius * 0.10;
    final hubRadius = maxRadius * 0.24;
    final knobRadius = maxRadius * 0.12;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimStroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = spokeStroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Outer circular rim
    canvas.drawCircle(center, rimRadius, strokePaint);

    // 2. Center hub (ring + solid center bindu)
    canvas.drawCircle(center, hubRadius, strokePaint);
    canvas.drawCircle(center, hubRadius * 0.5, fillPaint);

    // 3. Exactly 8 spokes and 8 outer points (starting at 12 o'clock = -pi/2)
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 4);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      // 8 Spokes (from hub to rim)
      final start = Offset(
        center.dx + (hubRadius + rimStroke * 0.3) * cosA,
        center.dy + (hubRadius + rimStroke * 0.3) * sinA,
      );
      final end = Offset(
        center.dx + (rimRadius - rimStroke * 0.3) * cosA,
        center.dy + (rimRadius - rimStroke * 0.3) * sinA,
      );
      canvas.drawLine(start, end, spokePaint);

      // 8 Outer Knobs / Points on the rim
      final knobCenter = Offset(
        center.dx + (rimRadius + rimStroke * 0.5) * cosA,
        center.dy + (rimRadius + rimStroke * 0.5) * sinA,
      );
      canvas.drawCircle(knobCenter, knobRadius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DharmachakraPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
