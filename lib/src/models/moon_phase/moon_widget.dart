import 'package:flutter/material.dart';
import 'moon_painter.dart';

class MoonWidget extends StatelessWidget {
  final DateTime date;
  final double size;
  final double resolution;
  final Color moonColor;
  final Color earthshineColor;
  final String backgroundImageAsset; // Add a property for the background image

  const MoonWidget({
    Key? key,
    required this.date,
    this.size = 300, // This can be adjusted to change the size of the moon
    this.resolution = 96,
    this.moonColor = Colors.amber,
    this.earthshineColor = Colors.black87,
    required this.backgroundImageAsset, // Add required to ensure an image is provided
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.2,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            backgroundImageAsset,
            width: size * 1.2,
            height: size * 1.2,
            fit: BoxFit.cover,
          ),
          CustomPaint(
            size: Size(size, size), // The CustomPainter uses this size
            painter: MoonPainter(moonWidget: this),
          ),
        ],
      ),
    );
  }
}
