import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/buddhavassa_data.dart';
import '../src/services/solar_calc.dart';
import '../src/models/prefs.dart';

class PoyaBottomSheet {
  static String _translateSeason(
      String rawSeason, AppLocalizations localizations) {
    switch (rawSeason) {
      case 'Hemanta':
        return localizations.beSeason_Hemanta;
      case 'Gimhana':
        return localizations.beSeason_Gimhana;
      case 'Vassana':
        return localizations.beSeason_Vassana;
      case 'ReHemanta':
        return localizations.beSeason_ReHemanta;
      default:
        return rawSeason;
    }
  }

  static void _showSolarTimesDialog(
      BuildContext context, DateTime date, AppLocalizations loc) {
    final times = getSolarTimesForDate(date);
    final dateStr = DateFormat('EEE, MMM dd, yyyy').format(date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            dateStr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _solarRow('${loc.solar_noon}:', times.solarNoon),
                const Divider(height: 12),
                _solarRow('${loc.astronomical_twilight}:', times.astronomicalTwilight),
                _solarRow('${loc.nautical_twilight}:', times.nauticalTwilight),
                _solarRow('${loc.pa_auk_angle}:', times.paAukAngle),
                _solarRow('${loc.custom_dawn} (${Prefs.customDawnAngle}°):', times.customDawn),
                _solarRow('${loc.na_uyana_angle}:', times.naUyanaAngle),
                _solarRow('${loc.civil_twilight}:', times.civilTwilight),
                _solarRow('${loc.sunrise}:', times.sunrise),
                _solarRow('${loc.pa_auk}:', times.paAukSR),
                _solarRow('${loc.na_uyana}:', times.naUyanaSR),
                const Divider(height: 12),
                _solarRow('Sunset:', times.sunset),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.ok),
            ),
          ],
        );
      },
    );
  }

  static Widget _solarRow(String label, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(time,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  static void show(BuildContext context, DateTime selectedDate,
      CalendarTradition tradition, AppLocalizations localizations) {
    final int selectedYear = selectedDate.year;
    final poyaList = BuddhavassaData.getPoyaList(tradition);
    final poyasForSelectedYear = poyaList
        .where((poyaDay) => poyaDay.date.startsWith(selectedYear.toString()))
        .toList();

    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Find the index to highlight:
    // - exact match if selected date is a poya, otherwise the next upcoming poya.
    int highlightIndex = poyasForSelectedYear
        .indexWhere((poyaDay) => poyaDay.date == selectedDateString);
    final bool isSelectedPoya = highlightIndex >= 0;
    if (!isSelectedPoya) {
      highlightIndex = poyasForSelectedYear.indexWhere(
          (poyaDay) => poyaDay.date.compareTo(selectedDateString) > 0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            final GlobalKey highlightKey = GlobalKey();

            if (highlightIndex >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  final highlightContext = highlightKey.currentContext;
                  if (highlightContext != null) {
                    Scrollable.ensureVisible(
                      highlightContext,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              });
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$selectedYear ${localizations.bePoyaTitle}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: poyasForSelectedYear.isEmpty
                      ? const Center(child: Text("No Data"))
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: () {
                              final List<Widget> listItems = [];

                              for (int i = 0;
                                  i < poyasForSelectedYear.length;
                                  i++) {
                                final poyaDay = poyasForSelectedYear[i];
                                final poyaDate = DateTime.parse(poyaDay.date);

                                final bool isHighlight = (i == highlightIndex);
                                Color? normalCardColor;
                                if (isHighlight) {
                                  normalCardColor = isSelectedPoya
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer;
                                }

                                // Safely handle properties (in case they parse as 'NaN' or null from CSV)
                                final String moonPhaseStr =
                                    poyaDay.moonPhase.toString().trim();
                                final bool hasMoonPhase =
                                    moonPhaseStr.isNotEmpty &&
                                        moonPhaseStr != 'NaN' &&
                                        moonPhaseStr != 'null';

                                final String specialStr =
                                    poyaDay.special.toString().trim();
                                final bool hasSpecial = specialStr.isNotEmpty &&
                                    specialStr != 'NaN' &&
                                    specialStr != 'null';

                                final String pakkhaStr =
                                    poyaDay.pakkhaType.toString().trim();

                                // 1. Render normal moon phase (Full/New Moon with 14 or 15 days count)
                                if (hasMoonPhase) {
                                  final localizedMoonPhaseName = moonPhaseStr
                                      .replaceAll(
                                          "FullMoon", localizations.beFullMoon)
                                      .replaceAll(
                                          "NewMoon", localizations.beNewMoon);

                                  listItems.add(
                                    Card(
                                      key: isHighlight ? highlightKey : null,
                                      color: normalCardColor,
                                      child: ListTile(
                                        dense: true,
                                        leading: Text(
                                          DateFormat('MMM dd').format(poyaDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isHighlight
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer
                                                : null,
                                          ),
                                        ),
                                        title: Text(
                                          '$localizedMoonPhaseName $pakkhaStr'
                                              .trim(),
                                          style: TextStyle(
                                            fontWeight: isHighlight
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _translateSeason(
                                                  poyaDay.season, localizations),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => _showSolarTimesDialog(
                                                  context, poyaDate, localizations),
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // 2. Render special entries (Vassa entry or pushed Pavāraṇā entry)
                                if (hasSpecial) {
                                  listItems.add(
                                    Card(
                                      // Only attach highlightKey here if this special item is the ONLY one for the day (e.g., Vassa)
                                      key: (isHighlight && !hasMoonPhase)
                                          ? highlightKey
                                          : null,
                                      color: normalCardColor,
                                      child: ListTile(
                                        dense: true,
                                        leading: Text(
                                          DateFormat('MMM dd').format(poyaDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isHighlight
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer
                                                : null,
                                          ),
                                        ),
                                        title: Text(
                                          '$specialStr',
                                          style: const TextStyle(
                                            fontWeight: FontWeight
                                                .bold, // Distinguish special day with bold text
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _translateSeason(
                                                  poyaDay.season, localizations),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => _showSolarTimesDialog(
                                                  context, poyaDate, localizations),
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                              return listItems;
                            }(),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
