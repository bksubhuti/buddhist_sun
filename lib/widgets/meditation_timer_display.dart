import 'dart:math';
import 'package:flutter/material.dart';

class MeditationTimerDisplay extends StatelessWidget {
  final String timeText;
  final String? subtitle;
  final double progress; // 0.0 to 1.0
  final bool isPaused;
  final double size;

  const MeditationTimerDisplay({
    Key? key,
    required this.timeText,
    this.subtitle,
    this.progress = 0.0,
    this.isPaused = false,
    this.size = 280,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final ringBgColor =
        isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow and Circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withAlpha(80)
                  : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            ),
          ),

          // Custom Painted Animated Ring
          CustomPaint(
            size: Size(size, size),
            painter: _TimerRingPainter(
              progress: progress,
              ringColor: primary,
              backgroundColor: ringBgColor,
              strokeWidth: 8.0,
            ),
          ),

          // Time and Status Texts
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Text(
                    subtitle!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                AnimatedOpacity(
                  opacity: isPaused ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 3.0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (isPaused) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withAlpha(100)),
                    ),
                    child: Text(
                      'PAUSED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    if (progress > 0.0) {
      final activePaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -pi / 2; // Top of circle
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
