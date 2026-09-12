import 'dart:math';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:buddhist_sun/src/services/moon_calc.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buddhist_sun/src/models/moon_phase/moon_phase.dart';
import 'package:buddhist_sun/src/services/astronomy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:buddhist_sun/widgets/poya_bottom_sheet.dart';
import 'package:buddhist_sun/views/sun_shadow_view.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({Key? key}) : super(key: key);

  @override
  _MoonPageState createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime selectedDate = DateTime.now();
  double moonPhasePercentage = 0.0;
  String _moonPhaseDescription = "";
  PoyaDay? _todayPoya;
  bool _isTodayUposatha = false;
  bool _isTomorrowUposatha = false;

  CalendarTradition get _tradition {
    switch (Prefs.selectedUposatha) {
      case UposathaCountry.Thailand:
        return CalendarTradition.thai;
      case UposathaCountry.Myanmar:
        return CalendarTradition.myanmar;
      case UposathaCountry.Sinhala:
        return CalendarTradition.sriLanka;
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  void _calculateMoonPhase() {
    useMeeus();
    final moonCalc = MoonCalc();
    final MoonPhase m = MoonPhase();
    double result = m.getPhaseAngle(selectedDate);
    result = makePercentageFromPhase(result);

    final phaseData = moonCalc.calculateMoonPhase(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    setState(() {
      moonPhasePercentage = result;
      _moonPhaseDescription = phaseData['description'] as String? ?? '';
    });
  }

  double makePercentageFromPhase(double phaseAngle) {
    if (phaseAngle < 0) {
      phaseAngle += 2 * pi;
    }
    return 100 - (1 - phaseAngle / (2 * pi)) * 100;
  }

  void useMeeus() {
    TZDateTime datetimeUTC = TZDateTime.now(UTC);
    TZDateTime datetimeSL =
        datetimeUTC.add(const Duration(hours: 5, minutes: 30));
    double latitude = 7.4854;
    double longitude = 80.3622;
    double jd = datetimeToJD(datetimeSL);
    double lunarPhase = calculateLunarPhaseWithLatLong(jd, latitude, longitude);
    double illumination = calculateLunarIllumination(lunarPhase);
    debugPrint("Lunar Phase: $lunarPhase°, Illumination: $illumination%");
  }

  void _calculateNextUposatha() {
    final poyaList = BuddhavassaData.getPoyaList(_tradition,
        includeEighthDays: Prefs.showEighthDayUposatha);
    final String currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    _todayPoya = null;
    _isTodayUposatha = false;
    for (var poya in poyaList) {
      if (poya.date == currentDateStr &&
          (poya.moonPhase == "FullMoon" ||
              poya.moonPhase == "NewMoon" ||
              (Prefs.showEighthDayUposatha &&
                  (poya.moonPhase == "Waxing8th" ||
                      poya.moonPhase == "Waning8th")))) {
        _todayPoya = poya;
        _isTodayUposatha = true;
        break;
      }
    }

    // Check if tomorrow is Uposatha (Shaving Eve)
    final tomorrow = selectedDate.add(const Duration(days: 1));
    final String tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
    _isTomorrowUposatha = poyaList.any((poya) =>
        poya.date == tomorrowStr &&
        (poya.moonPhase == "FullMoon" ||
            poya.moonPhase == "NewMoon" ||
            (Prefs.showEighthDayUposatha &&
                (poya.moonPhase == "Waxing8th" ||
                    poya.moonPhase == "Waning8th"))));
  }

  List<Map<String, dynamic>> _getUpcomingUposathas() {
    final poyaList = BuddhavassaData.getPoyaList(_tradition,
        includeEighthDays: Prefs.showEighthDayUposatha);
    final String currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final List<Map<String, dynamic>> upcoming = [];

    for (var poya in poyaList) {
      if (poya.date.compareTo(currentDateStr) >= 0) {
        final poyaDate = DateTime.parse(poya.date);
        final diffDays = DateTime(poyaDate.year, poyaDate.month, poyaDate.day)
            .difference(DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day))
            .inDays;

        upcoming.add({
          'poya': poya,
          'date': poyaDate,
          'diffDays': diffDays,
        });

        if (upcoming.length >= 3) break;
      }
    }
    return upcoming;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _calculateMoonPhase();
      _calculateNextUposatha();
    }
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  void _jumpToNextUposatha() {
    final poyaList = BuddhavassaData.getPoyaList(_tradition,
        includeEighthDays: Prefs.showEighthDayUposatha);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    for (var poya in poyaList) {
      if (poya.date.compareTo(currentDateStr) > 0) {
        setState(() {
          selectedDate = DateTime.parse(poya.date);
        });
        _calculateMoonPhase();
        _calculateNextUposatha();
        return;
      }
    }
  }

  void _jumpToPrevUposatha() {
    final poyaList = BuddhavassaData.getPoyaList(_tradition,
        includeEighthDays: Prefs.showEighthDayUposatha);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    for (var i = poyaList.length - 1; i >= 0; i--) {
      if (poyaList[i].date.compareTo(currentDateStr) < 0) {
        setState(() {
          selectedDate = DateTime.parse(poyaList[i].date);
        });
        _calculateMoonPhase();
        _calculateNextUposatha();
        return;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMoonPhaseName(String phase, AppLocalizations loc) {
    return phase
        .replaceAll('FullMoon', loc.beFullMoon)
        .replaceAll('NewMoon', loc.beNewMoon)
        .replaceAll('Waxing8th', loc.beWaxing8th)
        .replaceAll('Waning8th', loc.beWaning8th);
  }

  String _getEnhancedPhaseTitle(String moonPhaseDesc, String mmPhase) {
    if (mmPhase.toLowerCase().contains('full') ||
        moonPhaseDesc == 'Full Moon') {
      return 'Full Moon • Puṇṇamī';
    } else if (mmPhase.toLowerCase().contains('new') ||
        moonPhaseDesc == 'New Moon') {
      return 'New Moon • Amāvāsī';
    } else if (moonPhaseDesc.contains('Waxing') ||
        mmPhase.toLowerCase().contains('waxing')) {
      return '$moonPhaseDesc • Sukka Pakkha';
    } else if (moonPhaseDesc.contains('Waning') ||
        mmPhase.toLowerCase().contains('waning')) {
      return '$moonPhaseDesc • Kaḷa Pakkha';
    }
    return moonPhaseDesc.isNotEmpty ? moonPhaseDesc : mmPhase;
  }

  IconData _getMoonPhaseIcon(String phase) {
    switch (phase) {
      case 'FullMoon':
        return Icons.brightness_1_rounded;
      case 'NewMoon':
        return Icons.brightness_3_rounded;
      case 'Waxing8th':
        return Icons.brightness_2_outlined;
      case 'Waning8th':
        return Icons.nightlight_outlined;
      default:
        return Icons.brightness_3_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isToday = _isSameDay(selectedDate, DateTime.now());

    final mmCalendar = MmCalendar(
      config: const MmCalendarConfig(
        calendarType: CalendarType.english,
        language: Language.english,
      ),
    );
    final mmDate = mmCalendar.fromDateTime(selectedDate);
    final String mmPhase = mmDate.getMoonPhase();
    final String fortnightDay = mmDate.getFortnightDay();
    final String enhancedPhaseTitle =
        _getEnhancedPhaseTitle(_moonPhaseDescription, mmPhase);

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Container(
          color: Prefs.getChosenColor(context),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ══════════════════════════════════════════════════════════
                // 1. INTERACTIVE TOP DATE BAR
                // ══════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        iconSize: 18,
                        tooltip: AppLocalizations.of(context)!.prev,
                        onPressed: _goToPreviousDay,
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _selectDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    DateFormat('EEEE, MMM d, yyyy')
                                        .format(selectedDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        iconSize: 18,
                        tooltip: AppLocalizations.of(context)!.next,
                        onPressed: _goToNextDay,
                      ),
                    ],
                  ),
                ),

                // Quick "Return to Today" button if browsing away from today
                if (!isToday) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: _goToToday,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text(
                        "Return to Today",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ══════════════════════════════════════════════════════════
                // 2. FAST UPOSATHA JUMP BUTTONS & POYA SHEET ACTION
                // ══════════════════════════════════════════════════════════
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _jumpToPrevUposatha,
                        icon: const Icon(Icons.fast_rewind_rounded, size: 16),
                        label: const Text(
                          "Prev Uposatha",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.event_note_rounded),
                      tooltip: "View Uposatha Calendar List",
                      onPressed: () async {
                        await PoyaBottomSheet.show(
                          context,
                          selectedDate,
                          _tradition,
                          AppLocalizations.of(context)!,
                        );
                        _calculateNextUposatha();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _jumpToNextUposatha,
                        icon: const Icon(Icons.fast_forward_rounded, size: 16),
                        label: const Text(
                          "Next Uposatha",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ══════════════════════════════════════════════════════════
                // 3. INLINE BUDDHIST TRADITION SWITCHER
                // ══════════════════════════════════════════════════════════
                SegmentedButton<UposathaCountry>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: UposathaCountry.Sinhala,
                      label:
                          Text('Sri Lanka', style: TextStyle(fontSize: 12.5)),
                    ),
                    ButtonSegment(
                      value: UposathaCountry.Thailand,
                      label: Text('Thailand', style: TextStyle(fontSize: 12.5)),
                    ),
                    ButtonSegment(
                      value: UposathaCountry.Myanmar,
                      label: Text('Myanmar', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                  selected: {Prefs.selectedUposatha},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      Prefs.selectedUposatha = newSelection.first;
                      Prefs.instance
                          .setInt('selectedUposatha', newSelection.first.index);
                    });
                    _calculateNextUposatha();
                  },
                ),

                const SizedBox(height: 14),

                // ══════════════════════════════════════════════════════════
                // 4. ATMOSPHERIC HERO MOON CARD
                // ══════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(22.0),
                    border: Border.all(
                      color: _isTodayUposatha
                          ? Colors.amber.withAlpha(150)
                          : theme.colorScheme.outlineVariant.withAlpha(60),
                      width: _isTodayUposatha ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Banner for Today is Uposatha or Shaving Eve
                      if (_isTodayUposatha) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withAlpha(120),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "${AppLocalizations.of(context)!.today_is} ${_formatMoonPhaseName(_todayPoya!.moonPhase, AppLocalizations.of(context)!)} Uposatha" +
                                      (_todayPoya!.special.isNotEmpty
                                          ? " • ${_todayPoya!.special}"
                                          : ""),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_isTomorrowUposatha) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_cut_rounded,
                                  color: primaryColor, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                "Uposatha Eve (Shaving Day) • Tomorrow is Uposatha",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Central Moon Visualization (scaled down 20%)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: MoonWidget(
                          size: 108,
                          resolution: 200,
                          backgroundImageAsset: 'assets/moon_free2.png',
                          moonColor: const Color.fromARGB(97, 63, 57, 57),
                          date: selectedDate,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Phase Title
                      Text(
                        enhancedPhaseTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 2),

                      // Myanmar & Buddhist Era subtitle
                      Text(
                        "$fortnightDay • BE ${mmDate.getBuddhistEra()}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              theme.textTheme.bodyMedium?.color?.withAlpha(180),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Illumination badge pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primaryColor.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          "🌔 ${moonPhasePercentage.toStringAsFixed(1)}% Illuminated",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ══════════════════════════════════════════════════════════
                // 5. 3D MOON SKY COMPASS & REAL-TIME DOME CARD
                // ══════════════════════════════════════════════════════════
                _buildMoon3DSkyCard(context, theme),

                const SizedBox(height: 14),

                // ══════════════════════════════════════════════════════════
                // 6. UPCOMING UPOSATHAS SCHEDULE CARD
                // ══════════════════════════════════════════════════════════
                _buildUpcomingUposathasCard(context, theme),

                const SizedBox(height: 14),

                // ══════════════════════════════════════════════════════════
                // 6. UPOSATHA NOTIFICATION SETTING
                // ══════════════════════════════════════════════════════════
                _buildUposathaSwitch(context, theme),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingUposathasCard(BuildContext context, ThemeData theme) {
    final upcomingList = _getUpcomingUposathas();

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Upcoming Uposathas",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await PoyaBottomSheet.show(
                    context,
                    selectedDate,
                    _tradition,
                    AppLocalizations.of(context)!,
                  );
                  _calculateNextUposatha();
                  setState(() {});
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "Full List ›",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          if (upcomingList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                AppLocalizations.of(context)!.noData,
                style:
                    const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...upcomingList.map((item) {
              final PoyaDay poya = item['poya'] as PoyaDay;
              final DateTime date = item['date'] as DateTime;
              final int diffDays = item['diffDays'] as int;
              final bool isSelected = _isSameDay(date, selectedDate);

              String diffText;
              if (diffDays == 0) {
                diffText = "Today";
              } else if (diffDays == 1) {
                diffText = "Tomorrow";
              } else {
                diffText = "In $diffDays days";
              }

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                  _calculateMoonPhase();
                  _calculateNextUposatha();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(28)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary.withAlpha(100),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getMoonPhaseIcon(poya.moonPhase),
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color?.withAlpha(180),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(date),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              "${_formatMoonPhaseName(poya.moonPhase, AppLocalizations.of(context)!)}" +
                                  (poya.pakkhaType.isNotEmpty
                                      ? " • ${poya.pakkhaType}"
                                      : "") +
                                  (poya.special.isNotEmpty
                                      ? " • ${poya.special}"
                                      : ""),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(170),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: diffDays == 0
                              ? Colors.amber.withAlpha(40)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          diffText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: diffDays == 0
                                ? Colors.amber
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildUposathaSwitch(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Prefs.uposathaNotificationsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                size: 20,
                color: Prefs.uposathaNotificationsEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withAlpha(140),
              ),
              const SizedBox(width: 10),
              Text(
                "Uposatha Reminders",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: Prefs.uposathaNotificationsEnabled,
              onChanged: (bool value) async {
                setState(() {
                  Prefs.uposathaNotificationsEnabled = value;
                });
                if (value) {
                  await requestPermissions();
                  await scheduleUpcomingUposathaNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Uposatha reminders scheduled"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  await cancelAllUposathaNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🔕 Uposatha reminders turned off"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoon3DSkyCard(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final mPos = getMoonPositionAt(now);
    final isAbove = mPos.elevation > 0;
    final vis = getMoonVisibility(now);

    final String statusString;
    final Color statusColor;
    if (!isAbove) {
      statusString =
          "Under Horizon • Altitude: ${mPos.elevation.toStringAsFixed(1)}°";
      statusColor =
          theme.textTheme.bodySmall?.color?.withAlpha(160) ?? Colors.grey;
    } else if (!vis.isVisibleToNakedEye) {
      statusString =
          "In Sky (Alt: +${mPos.elevation.toStringAsFixed(1)}°) • ${vis.shortBadge}";
      statusColor = isDark ? Colors.amberAccent : Colors.amber.shade800;
    } else {
      statusString =
          "${vis.statusText} • Alt: +${mPos.elevation.toStringAsFixed(1)}°";
      statusColor = isDark ? Colors.cyanAccent : Colors.indigo;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SunShadowPage(
                  initialMode: CelestialBodyMode.moon,
                ),
              ),
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                // Live ticking mini 3D Moon Sky dome
                MiniSunShadowWidget(
                  size: 76.0,
                  mode: CelestialBodyMode.moon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "3D Moon Sky Compass",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusString,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight:
                              isAbove ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isAbove
                            ? "Tap to open interactive 3D Dome & Scrubber"
                            : (!vis.isVisibleToNakedEye
                                ? "Washed out by daylight glare • Tap 3D Dome"
                                : "Tap to open interactive 3D Dome & Scrubber"),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              theme.textTheme.bodySmall?.color?.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.outline.withAlpha(150),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
