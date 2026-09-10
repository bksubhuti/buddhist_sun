import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:buddhist_sun/utils/death_contemplation_calculator.dart';
import 'package:buddhist_sun/views/meditation_timer_page.dart';

class DeathContemplationPage extends StatefulWidget {
  const DeathContemplationPage({Key? key}) : super(key: key);

  @override
  State<DeathContemplationPage> createState() => _DeathContemplationPageState();
}

class _DeathContemplationPageState extends State<DeathContemplationPage> {
  Timer? _timer;
  late DateTime _currentTime;
  bool _showGasTank = Prefs.deathContemplationShowGasTank;
  bool _gaugeShowRemaining = Prefs.deathContemplationGaugeShowRemaining;

  @override
  void initState() {
    super.initState();
    Prefs.lastScreen = 'death_contemplation';
    _currentTime = DateTime.now();
    // Live ticking countdown update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final currentBirthDate = Prefs.deathContemplationBirthDate;
    final currentLifeExp = Prefs.deathContemplationLifeExpectancy;

    DateTime selectedDate = currentBirthDate ?? DateTime(1990, 1, 1);
    int selectedAge = currentLifeExp;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
            final l = AppLocalizations.of(context)!;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.deathContemplation,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Birthday picker
                    ColoredText(
                      '${l.birthday}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(1900, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    // Life expectancy age
                    ColoredText(
                      '${l.lifeExpectancy}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (selectedAge > 1) {
                              setDialogState(() {
                                selectedAge--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$selectedAge yrs',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (selectedAge < 130) {
                              setDialogState(() {
                                selectedAge++;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Prefs.deathContemplationBirthDate = selectedDate;
                    Prefs.deathContemplationLifeExpectancy = selectedAge;
                    settingsProvider.updateDeathContemplationSettings();
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: Text(l.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.spa,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l.deathContemplation)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Maraṇānussati (Mindfulness of Death)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Buddha repeatedly recommended the frequent contemplation of death as a potent spiritual tool to cut through complacency (pamāda) and arouse urgency (saṃvega).\n\n'
                '“Mindfulness of death, monks, when developed and cultivated, is of great fruit and benefit; it culminates in the Deathless (Nibbāna).”\n— Aṅguttara Nikāya 6.19\n\n'
                'By observing the relentless passage of years, months, days, and seconds, we remember that time is precious and unrepeatable. Let this reflection inspire diligence in virtue, mindfulness, and wisdom.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Watch settings provider for changes
    context.watch<SettingsProvider>();

    final birthDate = Prefs.deathContemplationBirthDate;
    final lifeExpYears = Prefs.deathContemplationLifeExpectancy;

    final result = DeathContemplationCalculator.calculate(
      birthDate: birthDate,
      lifeExpectancyYears: lifeExpYears,
      currentTime: _currentTime,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.deathContemplation),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Maraṇassati',
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: l.editDeathSettings,
            onPressed: () => _openEditDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!result.isConfigured)
                _buildUnconfiguredCard(context, l)
              else ...[
                // 1. Header Card (Maraṇassati Subtitle & Target Information)
                _buildHeaderCard(context, l, result),
                const SizedBox(height: 14),

                // 2. Countdown Grid (Years, Months, Days, Hours, Minutes, Seconds)
                if (!result.isElapsed)
                  _buildCountdownCards(context, l, result)
                else
                  _buildElapsedCard(context, l, result),
                const SizedBox(height: 14),

                // 3. Life Progress / Summary Bar
                _buildProgressCard(context, l, result),
                const SizedBox(height: 14),

                // 4. Buddhist Contemplation & Verses Card
                _buildContemplationReflectionCard(context, l),
                const SizedBox(height: 16),

                // 5. Action Buttons (Meditation Timer shortcut & Edit)
                _buildActionButtons(context, l),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnconfiguredCard(BuildContext context, AppLocalizations l) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l.deathContemplation,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Maraṇassati — Mindfulness of Death',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l.deathContemplationPrompt,
              style: const TextStyle(fontSize: 15, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month),
              label: Text(
                l.editDeathSettings,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _openEditDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    final targetDateStr = result.targetDate != null
        ? DateFormat('MMMM d, yyyy').format(result.targetDate!)
        : '';
    final birthDateStr = result.birthDate != null
        ? DateFormat('yyyy-MM-dd').format(result.birthDate!)
        : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Text(
              'Target: $targetDateStr (Age ${result.lifeExpectancyYears})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Born: $birthDateStr',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCards(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    final theme = Theme.of(context);
    final primaryColor =
        (!Prefs.darkThemeOn) ? theme.colorScheme.primary : Colors.white;
    final unitColor = theme.colorScheme.onSurfaceVariant;
    final dividerColor = theme.colorScheme.outlineVariant;

    final hoursStr = result.hours.toString().padLeft(2, '0');
    final minutesStr = result.minutes.toString().padLeft(2, '0');
    final secondsStr = result.seconds.toString().padLeft(2, '0');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Years | Months | Days (e.g. 23y | 4m | 13d)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  _buildUnitValue(
                    value: '${result.years}',
                    unit: 'y',
                    valueColor: primaryColor,
                    unitColor: unitColor,
                  ),
                  _buildVerticalBar(dividerColor),
                  _buildUnitValue(
                    value: '${result.months}',
                    unit: 'm',
                    valueColor: primaryColor,
                    unitColor: unitColor,
                  ),
                  _buildVerticalBar(dividerColor),
                  _buildUnitValue(
                    value: '${result.days}',
                    unit: 'd',
                    valueColor: primaryColor,
                    unitColor: unitColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Row 2: Hours : Minutes : Seconds (e.g. 09 : 16 : 12s)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    hoursStr,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: unitColor,
                      ),
                    ),
                  ),
                  Text(
                    minutesStr,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: unitColor,
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: secondsStr,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: primaryColor,
                        letterSpacing: 1.0,
                      ),
                      children: [
                        TextSpan(
                          text: 's',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: unitColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitValue({
    required String value,
    required String unit,
    required Color valueColor,
    required Color unitColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: valueColor,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: unitColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBar(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '|',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w200,
          color: color,
        ),
      ),
    );
  }

  Widget _buildElapsedCard(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              l.lifeExceeded,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    if (_showGasTank) {
      return _buildGasTankCard(context, l, result);
    } else {
      return _buildBarProgressCard(context, l, result);
    }
  }

  Widget _buildGasTankCard(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    final fuelRemaining = (1.0 - result.progressFraction).clamp(0.0, 1.0);
    final lifeElapsed = result.progressFraction.clamp(0.0, 1.0);
    final displayedFraction = _gaugeShowRemaining ? fuelRemaining : lifeElapsed;
    final percentStr = (displayedFraction * 100).toStringAsFixed(1);
    final NumberFormat numFormat = NumberFormat('#,###');
    final theme = Theme.of(context);
    final isDark = Prefs.darkThemeOn;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _gaugeShowRemaining
                          ? Icons.local_gas_station
                          : Icons.child_care,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    ColoredText(
                      _gaugeShowRemaining
                          ? 'Life Fuel (Remaining)'
                          : 'Life Elapsed (Lived)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _gaugeShowRemaining = !_gaugeShowRemaining;
                      Prefs.deathContemplationGaugeShowRemaining =
                          _gaugeShowRemaining;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _gaugeShowRemaining
                              ? '$percentStr% Full'
                              : '$percentStr% Lived',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              width: 250,
              child: CustomPaint(
                painter: GasTankGaugePainter(
                  fraction: displayedFraction,
                  isRemainingMode: _gaugeShowRemaining,
                  primaryColor: (!isDark)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  trackColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.9),
                  tickColor: theme.colorScheme.outline,
                  needleColor: Colors.amber.shade700,
                  textColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numFormat.format(result.totalDaysLived),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Days Lived',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numFormat.format(result.totalDaysRemaining),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Days Left',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For Maraṇa reflection only.\nWe never know when, where, or how.\nYou might live longer, or you might live less.\nMay you live beyond the estimation, and make the best use of life.',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                height: 1.3,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarProgressCard(
      BuildContext context, AppLocalizations l, DeathCountdownResult result) {
    final percentLived = (result.progressFraction * 100).toStringAsFixed(1);
    final percentRemaining =
        ((1.0 - result.progressFraction) * 100).toStringAsFixed(1);
    final NumberFormat numFormat = NumberFormat('#,###');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ColoredText(
                    '${l.lifeElapsed}: $percentLived%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l.lifeRemaining}: $percentRemaining%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.progressFraction,
                minHeight: 12,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numFormat.format(result.totalDaysLived),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Days Lived',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numFormat.format(result.totalDaysRemaining),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Days Left',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For Maraṇa reflection only.\nWe never know when, how, or where.\nYou may live longer, or you may live less.\nMay you live beyond the estimation, and make the best use of life.',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                height: 1.3,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContemplationReflectionCard(
      BuildContext context, AppLocalizations l) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dhamma Reflection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            _buildVerseItem(
              pali: '“Jīvitaṃ aniyataṃ, maraṇaṃ niyataṃ.”',
              english: '“Life is unpredictable, death is certain.”',
            ),
            const SizedBox(height: 10),
            _buildVerseItem(
              pali: '“Appamādena sampādetha.”',
              english: '“Strive on with diligence.” — Mahāparinibbāna Sutta',
            ),
            const SizedBox(height: 10),
            _buildVerseItem(
              pali: '“Vayadhammā saṅkhārā.”',
              english: '“All conditioned things are subject to decay.”',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseItem({required String pali, required String english}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pali,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          english,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.self_improvement),
            label: Text(
              l.meditationTimer,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MeditationTimerPage(),
                ),
              );
              Prefs.lastScreen = 'death_contemplation';
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _showGasTank ? Icons.view_headline : Icons.local_gas_station,
              size: 20,
            ),
            label: Text(
              _showGasTank ? 'Bar View' : 'Gas Tank',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              setState(() {
                _showGasTank = !_showGasTank;
                Prefs.deathContemplationShowGasTank = _showGasTank;
              });
            },
          ),
        ),
      ],
    );
  }
}

class GasTankGaugePainter extends CustomPainter {
  final double fraction; // 0.0 to 1.0
  final bool isRemainingMode;
  final Color primaryColor;
  final Color trackColor;
  final Color tickColor;
  final Color needleColor;
  final Color textColor;

  GasTankGaugePainter({
    required this.fraction,
    required this.isRemainingMode,
    required this.primaryColor,
    required this.trackColor,
    required this.tickColor,
    required this.needleColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.width * 0.36;

    const startAngle = math.pi * 0.85; // ~153° (bottom-left)
    const sweepAngle = math.pi * 1.30; // ~234° (sweeps up to ~27° bottom-right)

    // 1. Background Arc Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);

    // 2. Active Arc
    final activeAngle = sweepAngle * fraction.clamp(0.01, 1.0);
    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, activeAngle, false, fillPaint);

    // 3. Ticks
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final majorTicks = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final tick in majorTicks) {
      final angle = startAngle + sweepAngle * tick;
      final outer = center +
          Offset(
              math.cos(angle) * (radius + 8), math.sin(angle) * (radius + 8));
      final inner = center +
          Offset(
              math.cos(angle) * (radius - 8), math.sin(angle) * (radius - 8));
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Minor ticks
    final minorTickPaint = Paint()
      ..color = tickColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    final minorTicks = [0.125, 0.375, 0.625, 0.875];
    for (final tick in minorTicks) {
      final angle = startAngle + sweepAngle * tick;
      final outer = center +
          Offset(
              math.cos(angle) * (radius + 5), math.sin(angle) * (radius + 5));
      final inner = center +
          Offset(
              math.cos(angle) * (radius - 5), math.sin(angle) * (radius - 5));
      canvas.drawLine(inner, outer, minorTickPaint);
    }

    // 4. Egg & Skull Icons (30% larger at 26pt)
    final leftEmoji = isRemainingMode ? '💀' : '🥚';
    final rightEmoji = isRemainingMode ? '🥚' : '💀';
    _drawLabel(canvas, leftEmoji, center, radius + 23, startAngle);
    _drawLabel(
        canvas, rightEmoji, center, radius + 23, startAngle + sweepAngle);

    // 5. Needle
    final needleAngle = startAngle + sweepAngle * fraction;
    final needleLen = radius - 8;
    final needleTip = center +
        Offset(math.cos(needleAngle) * needleLen,
            math.sin(needleAngle) * needleLen);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Pivot Circle
    final pivotPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, 5.5, pivotPaint);

    final pivotInner = Paint()..color = textColor;
    canvas.drawCircle(center, 2.0, pivotInner);
  }

  void _drawLabel(
      Canvas canvas, String emoji, Offset center, double radius, double angle) {
    final pos =
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(
          fontSize: 26,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GasTankGaugePainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.isRemainingMode != isRemainingMode ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
