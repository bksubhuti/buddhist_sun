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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.resumed ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden) &&
        mounted) {
      context.read<MeditationTimerProvider>().syncWithCurrentTime();
      setState(() {});
    }
  }

  Future<void> _handleStopAttempt(BuildContext context) async {
    final timerProvider = context.read<MeditationTimerProvider>();
    await timerProvider.stopSession(
      completed: timerProvider.isOvertime ||
          timerProvider.status == MeditationTimerStatus.completed,
    );
    timerProvider.resetToIdle();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final timerProvider = context.watch<MeditationTimerProvider>();
    final t = AppLocalizations.of(context)!;

    // If completed, automatically return directly to meditation setup screen
    if (timerProvider.status == MeditationTimerStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          timerProvider.resetToIdle();
          Navigator.of(context).pop();
        }
      });
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    // 3. Active Running / Paused Timer View
    final isPaused = timerProvider.status == MeditationTimerStatus.paused;
    final isOvertime = timerProvider.isOvertime;

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
                      tooltip: isOvertime ? t.finishSession : t.endSession,
                      onPressed: () => _handleStopAttempt(context),
                    ),
                    Row(
                      children: [
                        Icon(
                          isOvertime
                              ? Icons.alarm_on_rounded
                              : (isPaused
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline),
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOvertime
                              ? t.timerOvertime.toUpperCase()
                              : (isPaused
                                  ? t.meditationPaused
                                  : t.meditationActive),
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
                          builder: (context, _) {
                            final currentIsOvertime = timerProvider.isOvertime;
                            final currentSubtitle = currentIsOvertime
                                ? t.timerOvertime
                                : (timerProvider.mode ==
                                        MeditationTimerMode.unlimited
                                    ? t.timerElapsed
                                    : t.timerRemaining);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: isPaused ? 1.0 : _pulseAnimation.value,
                                  child: MeditationTimerDisplay(
                                    timeText:
                                        timerProvider.formattedDisplayTime,
                                    subtitle: currentSubtitle,
                                    progress: timerProvider.progress,
                                    isPaused: isPaused,
                                    size: 300,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  currentIsOvertime
                                      ? 'Target: ${timerProvider.formattedTargetDuration}  •  Total: ${timerProvider.formattedElapsedTime}'
                                      : (isPaused
                                          ? t.tapScreenToResume
                                          : t.tapScreenToPause),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: currentIsOvertime
                                        ? primary
                                        : theme.colorScheme.onSurface
                                            .withAlpha(120),
                                    fontWeight: currentIsOvertime
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom End / Finish Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: isOvertime
                    ? FilledButton.icon(
                        onPressed: () => _handleStopAttempt(context),
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: Text(
                          t.finishSession,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      )
                    : TextButton.icon(
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
