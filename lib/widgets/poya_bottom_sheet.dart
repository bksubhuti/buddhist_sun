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
                _solarRow('${loc.astronomical_twilight}:',
                    times.astronomicalTwilight),
                _solarRow('${loc.nautical_twilight}:', times.nauticalTwilight),
                _solarRow('${loc.pa_auk_angle}:', times.paAukAngle),
                _solarRow('${loc.custom_dawn} (${Prefs.customDawnAngle}°):',
                    times.customDawn),
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

  static Widget _seasonStatColumn(
      BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, DateTime selectedDate,
      CalendarTradition tradition, AppLocalizations localizations) async {
    final int selectedYear = selectedDate.year;
    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool show8th = Prefs.showEighthDayUposatha;
            final poyaList = BuddhavassaData.getPoyaList(tradition,
                includeEighthDays: show8th);
            final poyasForSelectedYear = poyaList
                .where((poyaDay) =>
                    poyaDay.date.startsWith(selectedYear.toString()))
                .toList();

            // Find the index to highlight:
            // - exact match if selected date is a poya/8th day, otherwise the next upcoming poya.
            int highlightIndex = poyasForSelectedYear
                .indexWhere((poyaDay) => poyaDay.date == selectedDateString);
            final bool isSelectedPoya = highlightIndex >= 0;
            if (!isSelectedPoya) {
              highlightIndex = poyasForSelectedYear.indexWhere(
                  (poyaDay) => poyaDay.date.compareTo(selectedDateString) > 0);
            }

            // Compute pakkha season progress for the highlighted entry based on major Pakkhas
            String? seasonName;
            int pakkhaToday = 0;
            int pakkhaPast = 0;
            int pakkhaRemaining = 0;
            int pakkhaTotal = 0;

            if (highlightIndex >= 0) {
              final highlightedPoya = poyasForSelectedYear[highlightIndex];
              final currentSeason = highlightedPoya.season;
              seasonName = currentSeason;

              // Find the contiguous block of the same season around the highlighted entry.
              int seasonStart = highlightIndex;
              while (seasonStart > 0 &&
                  poyasForSelectedYear[seasonStart - 1].season ==
                      currentSeason) {
                seasonStart--;
              }
              int seasonEnd = highlightIndex;
              while (seasonEnd < poyasForSelectedYear.length - 1 &&
                  poyasForSelectedYear[seasonEnd + 1].season == currentSeason) {
                seasonEnd++;
              }

              // Count canonical major pakkhas (Full/New Moon) for the season stats
              int pakkhaPosition = 0;
              for (int j = seasonStart; j <= seasonEnd; j++) {
                final mp = poyasForSelectedYear[j].moonPhase.toString().trim();
                final isMajorPakkha = (mp == "FullMoon" || mp == "NewMoon");
                if (isMajorPakkha) {
                  pakkhaTotal++;
                  if (j < highlightIndex) {
                    pakkhaPast++;
                  } else if (j == highlightIndex) {
                    pakkhaPosition = pakkhaTotal;
                  }
                }
              }

              final highlightMp = highlightedPoya.moonPhase.toString().trim();
              if (highlightMp == "FullMoon" || highlightMp == "NewMoon") {
                pakkhaToday = pakkhaPosition;
                pakkhaRemaining = pakkhaTotal - pakkhaToday;
              } else {
                pakkhaToday = pakkhaPast;
                pakkhaRemaining = pakkhaTotal - pakkhaPast;
              }
            }

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$selectedYear ${localizations.bePoyaTitle}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    localizations.beTithi_8,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.85,
                                    child: Switch(
                                      value: show8th,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) {
                                        Prefs.showEighthDayUposatha = val;
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Season pakkha progress header
                    if (highlightIndex >= 0 &&
                        seasonName != null &&
                        pakkhaTotal > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _seasonStatColumn(context,
                                  localizations.beSeason_Today, '$pakkhaToday'),
                              _seasonStatColumn(context,
                                  localizations.beSeason_Past, '$pakkhaPast'),
                              _seasonStatColumn(
                                  context,
                                  localizations.beSeason_Remaining,
                                  '$pakkhaRemaining'),
                              _seasonStatColumn(
                                  context,
                                  _translateSeason(seasonName, localizations),
                                  '$pakkhaTotal'),
                            ],
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: poyasForSelectedYear.isEmpty
                          ? Center(child: Text(localizations.noData))
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
                                    final poyaDate =
                                        DateTime.parse(poyaDay.date);

                                    final bool isHighlight =
                                        (i == highlightIndex);
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

                                    // Safely handle properties
                                    final String moonPhaseStr =
                                        poyaDay.moonPhase.toString().trim();
                                    final bool hasMoonPhase =
                                        moonPhaseStr.isNotEmpty &&
                                            moonPhaseStr != 'NaN' &&
                                            moonPhaseStr != 'null';

                                    final String specialStr =
                                        poyaDay.special.toString().trim();
                                    final bool hasSpecial =
                                        specialStr.isNotEmpty &&
                                            specialStr != 'NaN' &&
                                            specialStr != 'null';

                                    final String pakkhaStr =
                                        poyaDay.pakkhaType.toString().trim();

                                    // 1. Render normal moon phase (Full/New Moon, or 8th Days)
                                    if (hasMoonPhase) {
                                      final isEighthDay =
                                          moonPhaseStr == "Waxing8th" ||
                                              moonPhaseStr == "Waning8th";
                                      final localizedMoonPhaseName =
                                          moonPhaseStr
                                              .replaceAll("FullMoon",
                                                  localizations.beFullMoon)
                                              .replaceAll("NewMoon",
                                                  localizations.beNewMoon)
                                              .replaceAll("Waxing8th",
                                                  localizations.beWaxing8th)
                                              .replaceAll("Waning8th",
                                                  localizations.beWaning8th);

                                      final titleText = isEighthDay
                                          ? localizedMoonPhaseName
                                          : '$localizedMoonPhaseName $pakkhaStr'
                                              .trim();

                                      listItems.add(
                                        Card(
                                          key:
                                              isHighlight ? highlightKey : null,
                                          color: normalCardColor,
                                          child: ListTile(
                                            dense: true,
                                            onTap: () => _showSolarTimesDialog(
                                                context,
                                                poyaDate,
                                                localizations),
                                            leading: Text(
                                              DateFormat('MMM dd')
                                                  .format(poyaDate),
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
                                              titleText,
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
                                                      poyaDay.season,
                                                      localizations),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: const CircleBorder(),
                                                    padding: EdgeInsets.zero,
                                                    minimumSize:
                                                        const Size(36, 36),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    elevation: 2,
                                                  ),
                                                  onPressed: () =>
                                                      _showSolarTimesDialog(
                                                          context,
                                                          poyaDate,
                                                          localizations),
                                                  child: const Icon(
                                                    Icons.info_outline,
                                                    size: 20,
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
                                          key: (isHighlight && !hasMoonPhase)
                                              ? highlightKey
                                              : null,
                                          color: normalCardColor,
                                          child: ListTile(
                                            dense: true,
                                            onTap: () => _showSolarTimesDialog(
                                                context,
                                                poyaDate,
                                                localizations),
                                            leading: Text(
                                              DateFormat('MMM dd')
                                                  .format(poyaDate),
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
                                              specialStr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _translateSeason(
                                                      poyaDay.season,
                                                      localizations),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: const CircleBorder(),
                                                    padding: EdgeInsets.zero,
                                                    minimumSize:
                                                        const Size(36, 36),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    elevation: 2,
                                                  ),
                                                  onPressed: () =>
                                                      _showSolarTimesDialog(
                                                          context,
                                                          poyaDate,
                                                          localizations),
                                                  child: const Icon(
                                                    Icons.info_outline,
                                                    size: 20,
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
      },
    );
  }
}
