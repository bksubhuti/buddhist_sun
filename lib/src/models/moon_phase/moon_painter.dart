//
// MoonPhase.java:
// Calculate the phase of the moon.
//    Copyright 2014 by Audrius Meskauskas
// You may use or distribute this code under the terms of the GPLv3
//https://github.com/andviane/moon.git

import 'dart:math';
import 'package:flutter/material.dart';
import 'moon_phase.dart';

class MoonPainter extends CustomPainter {
  MoonWidget moonWidget;
  final Paint paintDark = Paint();
  final Paint paintLight = Paint();
  final MoonPhase moon = MoonPhase();

  MoonPainter({required this.moonWidget});

  @override
  void paint(Canvas canvas, Size size) {
    // Use the size parameter to get the center of the canvas
    double xcenter = size.width / 2;
    double ycenter = size.height / 2;
    double radius = min(size.width, size.height) /
        2; // Use the size to determine the radius

    double phaseAngle = moon.getPhaseAngle(moonWidget.date);

    // Update the color settings
    paintLight.color = moonWidget.moonColor;
    paintDark.color = moonWidget.earthshineColor;

    // Draw the full moon as a light circle
    canvas.drawCircle(Offset(xcenter, ycenter), radius, paintLight);

    // Calculate the terminator position
    double positionAngle = pi - phaseAngle;
    if (positionAngle < 0.0) {
      positionAngle += 2.0 * pi;
    }

    // Calculate the shadow
    double cosTerm = cos(positionAngle);
    double rsquared = radius * radius;
    double whichQuarter = ((positionAngle * 2.0 / pi) + 4) % 4;

    // Draw the shadow on the moon
    for (int j = -radius.toInt(); j <= radius.toInt(); ++j) {
      double rrf = sqrt(rsquared - j * j);
      double rr = rrf;
      double xx = rrf * cosTerm;
      double x1 = xcenter - (whichQuarter < 2 ? rr : xx);
      double w = rr + xx;

      canvas.drawRect(
          Rect.fromLTRB(x1, ycenter + j, x1 + w, ycenter + j + 1), paintDark);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
