import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';
import 'package:buddhist_sun/src/provider/meditation_timer_provider.dart';
import 'package:buddhist_sun/widgets/meditation_timer_display.dart';

class ActiveMeditationPage extends StatefulWidget {
  const ActiveMeditationPage({Key? key}) : super(key: key);

  @override
  State<ActiveMeditationPage> createState() => _ActiveMeditationPageState();
}

class _ActiveMeditationPageState extends State<ActiveMeditationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hide status bar / immersive feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _handleStopAttempt(BuildContext context) async {
    final timerProvider = context.read<MeditationTimerProvider>();
    final t = AppLocalizations.of(context)!;

    if (timerProvider.status == MeditationTimerStatus.completed) {
      timerProvider.resetToIdle();
      Navigator.of(context).pop();
      return;
    }

    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.endSession),
        content: Text(
          t.endSessionConfirm(timerProvider.formattedElapsedTime),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.endSession),
          ),
        ],
      ),
    );

    if (shouldStop == true && mounted) {
      await timerProvider.stopSession(completed: false);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final timerProvider = context.watch<MeditationTimerProvider>();
    final t = AppLocalizations.of(context)!;

    // 1. Completed View
    if (timerProvider.status == MeditationTimerStatus.completed) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 80,
                    color: primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.sessionCompleted,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.meditatedFor(timerProvider.formattedElapsedTime),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: () {
                      timerProvider.resetToIdle();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(t.timerDone, style: const TextStyle(fontSize: 16)),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Active Running / Paused Timer View
    final isPaused = timerProvider.status == MeditationTimerStatus.paused;
    final subtitle = timerProvider.mode == MeditationTimerMode.unlimited
        ? t.timerElapsed
        : t.timerRemaining;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleStopAttempt(context);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with End/Exit button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      tooltip: t.endSession,
                      onPressed: () => _handleStopAttempt(context),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPaused
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPaused ? t.meditationPaused : t.meditationActive,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48), // balance spacing
                  ],
                ),
              ),

              // Main Circular Display (Tap anywhere to pause/resume)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isPaused) {
                      timerProvider.resumeSession();
                    } else {
                      timerProvider.pauseSession();
                    }
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: isPaused ? 1.0 : _pulseAnimation.value,
                            child: child,
                          ),
                          child: MeditationTimerDisplay(
                            timeText: timerProvider.formattedDisplayTime,
                            subtitle: subtitle,
                            progress: timerProvider.progress,
                            isPaused: isPaused,
                            size: 300,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          isPaused
                              ? t.tapScreenToResume
                              : t.tapScreenToPause,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(120),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom End Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: TextButton.icon(
                  onPressed: () => _handleStopAttempt(context),
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    color: theme.colorScheme.error,
                    size: 22,
                  ),
                  label: Text(
                    t.endSession,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
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
}
