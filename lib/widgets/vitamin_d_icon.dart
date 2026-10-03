import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vitamin D icon: a spiked sun badge with a round cut-out holding a bold
/// solid "D". Drawn on a 24×24 grid; the ring between sun and D is
/// transparent, so it shows the background on any theme.
class VitaminDSunIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const VitaminDSunIcon({Key? key, this.size = 24, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _VitaminDSunIconPainter(c)),
    );
  }
}

class _VitaminDSunIconPainter extends CustomPainter {
  final Color color;
  const _VitaminDSunIconPainter(this.color);

  static const int _spikes = 16;
  static const double _tipR = 12.0;
  static const double _valleyR = 9.3;
  static const double _holeR = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(s);
    const c = Offset(12, 12);

    // Spiked sun body; a round-joined stroke softens the spike tips.
    final sun = Path();
    for (int i = 0; i < _spikes * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / _spikes;
      final r = i.isEven ? _tipR - 0.5 : _valleyR;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        sun.moveTo(p.dx, p.dy);
      } else {
        sun.lineTo(p.dx, p.dy);
      }
    }
    sun.close();
    canvas.drawPath(sun, Paint()..color = color);
    canvas.drawPath(
        sun,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeJoin = StrokeJoin.round);

    // Round hole
    canvas.drawCircle(c, _holeR, Paint()..blendMode = BlendMode.clear);

    // Bold solid "D", drawn as a shape (no font needed)
    final d = Path()
      ..moveTo(9.0, 7.3)
      ..lineTo(11.1, 7.3)
      ..arcToPoint(const Offset(11.1, 16.7),
          radius: const Radius.circular(4.7), clockwise: true)
      ..lineTo(9.0, 16.7)
      ..close();
    canvas.drawPath(
        d,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VitaminDSunIconPainter old) => old.color != color;
}
