import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:buddhist_sun/src/services/vitamin_d_calc.dart';

/// Swatch colours for Fitzpatrick skin types I–VI.
const List<Color> vitDSkinColors = [
  Color(0xFFF9E4D6),
  Color(0xFFF0CDB4),
  Color(0xFFDDAA84),
  Color(0xFFB98159),
  Color(0xFF8A5533),
  Color(0xFF4E2E1E),
];

const Color _robeColor = Color(0xFFC8691E);
const Color _robeShade = Color(0xFF9E4F12);
const Color _angsaColor = Color(0xFF9C5A1C);
const Color _shirtColor = Color(0xFF2E7D8C);
const Color _shirtShade = Color(0xFF1F5A66);
const Color _trouserColor = Color(0xFF5D6470);
const Color _pinkShirt = Color(0xFFE57A9E);
const Color _pinkShade = Color(0xFFB9527A);
const Color _pinkTrouser = Color(0xFFC75B85);
const Color _hairColor = Color(0xFF3B2A20);

/// A standing figure dressed for [coverage]: a monk in robes, or a lay
/// person in everyday clothes. Skin uses [skinColor] to match the chosen tone.
class CoveragePainter extends CustomPainter {
  final VitDCoverage coverage;
  final Color skinColor;

  const CoveragePainter({required this.coverage, required this.skinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Keep proportions: work in a centred box with aspect 0.75.
    final bw = math.min(w, h * 0.75);
    final ox = (w - bw) / 2;
    Offset p(double x, double y) => Offset(ox + x * bw, y * h);

    final skin = Paint()..color = skinColor;
    final outline = Paint()
      ..color = Colors.black.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final robe = Paint()..color = _robeColor;
    final fold = Paint()
      ..color = _robeShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // ── Skin layer (whole body) ──────────────────────────────────────
    // Legs
    for (final x in [0.39, 0.53]) {
      final r = RRect.fromRectAndRadius(
          Rect.fromPoints(p(x, 0.56), p(x + 0.08, 0.92)), Radius.circular(bw * 0.03));
      canvas.drawRRect(r, skin);
    }
    // Feet
    for (final x in [0.42, 0.58]) {
      canvas.drawOval(
          Rect.fromCenter(center: p(x, 0.935), width: bw * 0.13, height: h * 0.035),
          skin);
    }
    // Arms
    for (final x in [0.19, 0.71]) {
      final r = RRect.fromRectAndRadius(
          Rect.fromPoints(p(x, 0.31), p(x + 0.10, 0.60)), Radius.circular(bw * 0.05));
      canvas.drawRRect(r, skin);
    }
    // Hands
    for (final x in [0.24, 0.76]) {
      canvas.drawCircle(p(x, 0.615), bw * 0.055, skin);
    }
    // Torso
    final torso = Path()
      ..moveTo(p(0.27, 0.30).dx, p(0.27, 0.30).dy)
      ..lineTo(p(0.73, 0.30).dx, p(0.73, 0.30).dy)
      ..lineTo(p(0.67, 0.58).dx, p(0.67, 0.58).dy)
      ..lineTo(p(0.33, 0.58).dx, p(0.33, 0.58).dy)
      ..close();
    canvas.drawPath(torso, skin);
    // Shoulders (rounded)
    canvas.drawCircle(p(0.27, 0.335), bw * 0.07, skin);
    canvas.drawCircle(p(0.73, 0.335), bw * 0.07, skin);
    // Neck
    canvas.drawRect(Rect.fromPoints(p(0.45, 0.22), p(0.55, 0.31)), skin);
    // Shaved head
    final headC = p(0.5, 0.15);
    final headR = h * 0.085;
    canvas.drawCircle(headC, headR, skin);
    canvas.drawCircle(headC, headR, outline);
    if (coverage.isLay) {
      canvas.drawArc(Rect.fromCircle(center: headC, radius: headR * 1.04),
          math.pi * 1.02, math.pi * 0.96, true, Paint()..color = _hairColor);
    }
    // Ears
    canvas.drawCircle(headC.translate(-headR, h * 0.01), headR * 0.22, skin);
    canvas.drawCircle(headC.translate(headR, h * 0.01), headR * 0.22, skin);
    // Simple calm face
    final face = Paint()
      ..color = Colors.black.withAlpha(110)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headC.translate(-headR * 0.45, -headR * 0.02),
        headC.translate(-headR * 0.2, -headR * 0.02), face);
    canvas.drawLine(headC.translate(headR * 0.2, -headR * 0.02),
        headC.translate(headR * 0.45, -headR * 0.02), face);
    canvas.drawArc(
        Rect.fromCenter(
            center: headC.translate(0, headR * 0.35),
            width: headR * 0.5,
            height: headR * 0.25),
        0.2,
        math.pi - 0.4,
        false,
        face);

    // ── Robe layer ───────────────────────────────────────────────────
    Path poly(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      return path..close();
    }

    switch (coverage.maleEquivalent) {
      case VitDCoverage.fullRobe:
        // Upper robe over both shoulders and arms to the wrists.
        canvas.drawPath(
            poly([
              p(0.42, 0.25),
              p(0.58, 0.25),
              p(0.80, 0.29),
              p(0.84, 0.60),
              p(0.70, 0.60),
              p(0.68, 0.66),
              p(0.32, 0.66),
              p(0.30, 0.60),
              p(0.16, 0.60),
              p(0.20, 0.29),
            ]),
            robe);
        canvas.drawLine(p(0.30, 0.34), p(0.30, 0.58), fold);
        canvas.drawLine(p(0.70, 0.34), p(0.70, 0.58), fold);
        canvas.drawLine(p(0.44, 0.27), p(0.50, 0.40), fold);
        canvas.drawLine(p(0.56, 0.27), p(0.50, 0.40), fold);
        _lowerRobe(canvas, p, robe, fold, 0.90);
        break;
      case VitDCoverage.oneShoulder:
        // Right shoulder and arm (viewer's left) left bare.
        canvas.drawPath(
            poly([
              p(0.56, 0.25),
              p(0.80, 0.29),
              p(0.84, 0.60),
              p(0.70, 0.60),
              p(0.68, 0.66),
              p(0.32, 0.66),
              p(0.31, 0.44),
            ]),
            robe);
        canvas.drawLine(p(0.70, 0.34), p(0.70, 0.58), fold);
        canvas.drawLine(p(0.54, 0.30), p(0.38, 0.47), fold);
        canvas.drawLine(p(0.60, 0.36), p(0.46, 0.55), fold);
        _lowerRobe(canvas, p, robe, fold, 0.90);
        break;
      case VitDCoverage.angsa:
        // Aṅsa: shoulder cloth over the left shoulder (viewer's right) and
        // upper arm to mid-bicep, diagonal across the chest; right arm,
        // left forearm and right chest bare.
        _lowerRobe(canvas, p, robe, fold, 0.84);
        canvas.drawPath(
            poly([
              p(0.50, 0.26),
              p(0.66, 0.27),
              p(0.78, 0.28),
              p(0.83, 0.33),
              p(0.83, 0.45),
              p(0.70, 0.45),
              p(0.68, 0.60),
              p(0.34, 0.60),
              p(0.35, 0.52),
            ]),
            Paint()..color = _angsaColor);
        canvas.drawLine(p(0.52, 0.30), p(0.38, 0.52), fold);
        canvas.drawLine(p(0.62, 0.32), p(0.50, 0.56), fold);
        break;
      case VitDCoverage.upperBare:
        // Only the lower robe, to mid-shin.
        _lowerRobe(canvas, p, robe, fold, 0.84);
        break;
      case VitDCoverage.bathingCloth:
        // Bathing cloth from waist to knee.
        final cloth = Paint()..color = _robeColor.withAlpha(230);
        canvas.drawPath(
            poly([p(0.33, 0.55), p(0.67, 0.55), p(0.69, 0.74), p(0.31, 0.74)]),
            cloth);
        canvas.drawLine(p(0.33, 0.57), p(0.67, 0.57), fold);
        canvas.drawLine(p(0.45, 0.60), p(0.43, 0.72), fold);
        canvas.drawLine(p(0.56, 0.60), p(0.58, 0.72), fold);
        break;
      case VitDCoverage.layFaceHands:
        _shirt(canvas, p, 0.60);
        _trousers(canvas, p, 0.90);
        break;
      case VitDCoverage.layShortSleeves:
        _shirt(canvas, p, 0.42);
        _trousers(canvas, p, 0.90);
        break;
      case VitDCoverage.layShorts:
        _shirt(canvas, p, 0.42);
        _trousers(canvas, p, 0.71);
        break;
      case VitDCoverage.laySwimwear:
        _trousers(canvas, p, 0.65);
        if (coverage.isFemale) {
          // Plain rectangular swim top across the chest.
          canvas.drawRect(Rect.fromPoints(p(0.30, 0.34), p(0.70, 0.44)),
              Paint()..color = _pinkTrouser);
        }
        break;
      default:
        break;
    }
  }

  /// Shirt over the torso with sleeves ending at [sleeveEnd] (0.60 = wrist).
  void _shirt(
      Canvas canvas, Offset Function(double, double) p, double sleeveEnd) {
    final female = coverage.isFemale;
    final shirt = Paint()..color = female ? _pinkShirt : _shirtColor;
    final seam = Paint()
      ..color = female ? _pinkShade : _shirtShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(p(0.42, 0.26).dx, p(0.42, 0.26).dy)
      ..lineTo(p(0.58, 0.26).dx, p(0.58, 0.26).dy)
      ..lineTo(p(0.78, 0.29).dx, p(0.78, 0.29).dy)
      ..lineTo(p(0.82, sleeveEnd).dx, p(0.82, sleeveEnd).dy)
      ..lineTo(p(0.70, sleeveEnd).dx, p(0.70, sleeveEnd).dy)
      ..lineTo(p(0.68, 0.40).dx, p(0.68, 0.40).dy)
      ..lineTo(p(0.67, 0.58).dx, p(0.67, 0.58).dy)
      ..lineTo(p(0.33, 0.58).dx, p(0.33, 0.58).dy)
      ..lineTo(p(0.32, 0.40).dx, p(0.32, 0.40).dy)
      ..lineTo(p(0.30, sleeveEnd).dx, p(0.30, sleeveEnd).dy)
      ..lineTo(p(0.18, sleeveEnd).dx, p(0.18, sleeveEnd).dy)
      ..lineTo(p(0.22, 0.29).dx, p(0.22, 0.29).dy)
      ..close();
    canvas.drawPath(path, shirt);
    // Collar
    canvas.drawArc(Rect.fromPoints(p(0.44, 0.23), p(0.56, 0.31)), 0, math.pi,
        false, seam);
  }

  /// Trousers or shorts from the waist down to [hem] (0.90 = ankle).
  void _trousers(Canvas canvas, Offset Function(double, double) p, double hem) {
    final cloth = Paint()
      ..color = coverage.isFemale ? _pinkTrouser : _trouserColor;
    canvas.drawRect(Rect.fromPoints(p(0.34, 0.555), p(0.66, 0.62)), cloth);
    canvas.drawRect(Rect.fromPoints(p(0.375, 0.60), p(0.49, hem)), cloth);
    canvas.drawRect(Rect.fromPoints(p(0.51, 0.60), p(0.625, hem)), cloth);
  }

  void _lowerRobe(Canvas canvas, Offset Function(double, double) p, Paint robe,
      Paint fold, double hem) {
    final path = Path()
      ..moveTo(p(0.32, 0.55).dx, p(0.32, 0.55).dy)
      ..lineTo(p(0.68, 0.55).dx, p(0.68, 0.55).dy)
      ..lineTo(p(0.71, hem).dx, p(0.71, hem).dy)
      ..lineTo(p(0.29, hem).dx, p(0.29, hem).dy)
      ..close();
    canvas.drawPath(path, robe);
    canvas.drawLine(p(0.32, 0.575), p(0.68, 0.575), fold);
    canvas.drawLine(p(0.45, 0.60), p(0.42, hem - 0.02), fold);
    canvas.drawLine(p(0.56, 0.60), p(0.59, hem - 0.02), fold);
  }

  @override
  bool shouldRepaint(CoveragePainter old) =>
      old.coverage != coverage || old.skinColor != skinColor;
}

/// Compact side view: the sun on its arc at [elevation], a 45° guide line,
/// and a monk casting a shadow. At 45° the shadow equals the body height.
class SunAnglePainter extends CustomPainter {
  final double elevation;
  final Color primary;
  final Color onSurface;
  final Color skinColor;
  final bool lay;
  final bool female;

  const SunAnglePainter({
    required this.elevation,
    required this.primary,
    required this.onSurface,
    required this.skinColor,
    this.lay = false,
    this.female = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.88;
    final feet = Offset(w * 0.40, groundY);
    final bodyH = h * 0.34;
    final head = Offset(feet.dx, groundY - bodyH);
    // Sun arc is centred on the head so the ray through the head lands
    // exactly on the shadow tip (and 45° means shadow = height).
    final radius = math.min(head.dy - 20, w - feet.dx - 20);

    final good = elevation >= vitDOptimalElevation;
    final sunColor = elevation <= 0
        ? onSurface.withAlpha(90)
        : (good ? const Color(0xFFFFB300) : const Color(0xFFFF7043));

    // Ground
    canvas.drawLine(
        Offset(0, groundY),
        Offset(w, groundY),
        Paint()
          ..color = onSurface.withAlpha(90)
          ..strokeWidth = 1.5);

    // Elevation arc (0°–90°), dotted
    final arcPaint = Paint()..color = onSurface.withAlpha(70);
    for (int d = 0; d <= 90; d += 6) {
      final a = d * math.pi / 180;
      canvas.drawCircle(
          head + Offset(radius * math.cos(a), -radius * math.sin(a)), 0.9, arcPaint);
    }

    // 45° guide (dashed) through the head, ground to arc
    final guide = Paint()
      ..color = primary.withAlpha(150)
      ..strokeWidth = 1.2;
    const a45 = math.pi / 4;
    final dir45 = Offset(math.cos(a45), -math.sin(a45));
    final guideStart = head - dir45 * (bodyH / math.sin(a45));
    final guideLen = bodyH / math.sin(a45) + radius;
    for (double t = 0; t < guideLen; t += 8) {
      canvas.drawLine(guideStart + dir45 * t,
          guideStart + dir45 * math.min(t + 4, guideLen), guide);
    }
    _label(canvas, '45°', head + dir45 * (radius * 0.4) + const Offset(-14, -8),
        primary, 10);

    // Shadow, ray and sun
    if (elevation > 1) {
      final e = elevation * math.pi / 180;
      final shadowLen = bodyH / math.tan(e);
      final tip = Offset(math.max(feet.dx - shadowLen, 0), groundY);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(tip.dx, groundY - 2.5, feet.dx, groundY + 2.5),
              const Radius.circular(3)),
          Paint()..color = onSurface.withAlpha(120));
      final dir = Offset(math.cos(e), -math.sin(e));
      final sun = head + dir * radius;
      final ray = Paint()
        ..color = sunColor.withAlpha(160)
        ..strokeWidth = 1.2;
      canvas.drawLine(sun, head, ray);
      final rayEnd = head - dir * (bodyH / math.sin(e));
      for (double f = 0; f < 1; f += 0.12) {
        canvas.drawLine(Offset.lerp(head, rayEnd, f)!,
            Offset.lerp(head, rayEnd, math.min(f + 0.06, 1))!, ray);
      }
      // Angle wedge at the head, from horizontal
      canvas.drawArc(Rect.fromCircle(center: head, radius: 18), 0, -e, true,
          Paint()..color = sunColor.withAlpha(70));
      // Sun with rays
      final rayPaint = Paint()
        ..color = sunColor
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final ra = i * math.pi / 4;
        final d = Offset(math.cos(ra), math.sin(ra));
        canvas.drawLine(sun + d * 12, sun + d * 16, rayPaint);
      }
      canvas.drawCircle(sun, 9, Paint()..color = sunColor);
      _label(canvas, '${elevation.toStringAsFixed(0)}°',
          sun + Offset(elevation > 60 ? 26 : 0, elevation > 60 ? 0 : -24),
          onSurface, 11);
    }

    // Figure silhouette (side view): robe + shaved head, or lay clothes
    final robe = Paint()
      ..color = lay ? (female ? _pinkShirt : _shirtColor) : _robeColor;
    final headR = bodyH * 0.12;
    final body = Path()
      ..moveTo(feet.dx - bodyH * 0.15, groundY)
      ..lineTo(feet.dx + bodyH * 0.15, groundY)
      ..lineTo(feet.dx + bodyH * 0.13, groundY - bodyH * 0.70)
      ..quadraticBezierTo(feet.dx, groundY - bodyH * 0.80,
          feet.dx - bodyH * 0.13, groundY - bodyH * 0.70)
      ..close();
    canvas.drawPath(body, robe);
    canvas.drawCircle(head + Offset(0, headR), headR, Paint()..color = skinColor);
    if (lay) {
      canvas.drawArc(Rect.fromCircle(center: head + Offset(0, headR), radius: headR),
          math.pi, math.pi, true, Paint()..color = _hairColor);
    }
  }

  void _label(Canvas canvas, String text, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(SunAnglePainter old) =>
      old.elevation != elevation ||
      old.primary != primary ||
      old.onSurface != onSurface ||
      old.skinColor != skinColor ||
      old.lay != lay ||
      old.female != female;
}
