import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

/// Small icon + label chip that toggles on tap.
/// Filled with the primary color when on, faded when off.
class TapToggleChip extends StatelessWidget {
  final bool value;
  final IconData onIcon;
  final IconData offIcon;
  final String label;
  final VoidCallback onTap;

  const TapToggleChip({
    Key? key,
    required this.value,
    required this.onIcon,
    required this.offIcon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final offColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      toggled: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: value
                  ? primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: value
                    ? primaryColor.withValues(alpha: 0.6)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value ? onIcon : offIcon,
                  size: 18,
                  color: value ? primaryColor : offColor,
                ),
                const SizedBox(width: 4),
                // Long translations wrap onto a second line instead of overflowing.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                      color: value ? primaryColor : offColor,
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
}

/// "Caffeine" toggle: a coffee cup chip that keeps the screen on while enabled
/// (saved in Prefs.screenAlwaysOn).
class ScreenAwakeToggle extends StatefulWidget {
  const ScreenAwakeToggle({Key? key}) : super(key: key);

  @override
  State<ScreenAwakeToggle> createState() => _ScreenAwakeToggleState();
}

class _ScreenAwakeToggleState extends State<ScreenAwakeToggle>
    with WidgetsBindingObserver {
  bool _wakeOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wakeOn = Prefs.screenAlwaysOn;
    _applyWakelock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS can drop the wakelock while backgrounded, so re-assert it.
    if (state == AppLifecycleState.resumed) _applyWakelock();
  }

  void _applyWakelock() {
    if (!_wakeOn) return;
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  void _setWake(bool value) {
    setState(() {
      _wakeOn = value;
      Prefs.screenAlwaysOn = value;
    });
    try {
      WakelockPlus.toggle(enable: value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.screen_always_on,
      child: TapToggleChip(
        value: _wakeOn,
        onIcon: Icons.coffee,
        offIcon: Icons.coffee_outlined,
        label: AppLocalizations.of(context)!.screenAwakeLabel,
        onTap: () => _setWake(!_wakeOn),
      ),
    );
  }
}
