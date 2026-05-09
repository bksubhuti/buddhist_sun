import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/buddhavassa_data.dart';

class PoyaBottomSheet {
  static String _translateSeason(String raw, AppLocalizations l) {
    switch (raw) {
      case 'Hemanta':
        return l.beSeason_Hemanta;
      case 'Gimhana':
        return l.beSeason_Gimhana;
      case 'Vassana':
        return l.beSeason_Vassana;
      case 'ReHemanta':
        return l.beSeason_ReHemanta;
      default:
        return raw;
    }
  }

  static void show(BuildContext context, DateTime selectedDate, CalendarTradition tradition, AppLocalizations l) {
    final int selYear = selectedDate.year;
    final poyaList = BuddhavassaData.getPoyaList(tradition);
    final yearPoyas = poyaList.where((p) => p.date.startsWith(selYear.toString())).toList();

    final selectedStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Find the index to highlight:
    // - exact match if selected date is a poya, otherwise the next upcoming poya.
    int highlightIndex = yearPoyas.indexWhere((p) => p.date == selectedStr);
    final bool isSelectedPoya = highlightIndex >= 0;
    if (!isSelectedPoya) {
      highlightIndex = yearPoyas.indexWhere((p) => p.date.compareTo(selectedStr) > 0);
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
                  final ctx = highlightKey.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$selYear ${l.bePoyaTitle}',
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
                  child: yearPoyas.isEmpty
                      ? const Center(child: Text("No Data"))
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: yearPoyas.asMap().entries.map((entry) {
                              final index = entry.key;
                              final p = entry.value;
                              final dt = DateTime.parse(p.date);
                              final pName = p.moonPhase
                                  .replaceAll("FullMoon", l.beFullMoon)
                                  .replaceAll("NewMoon", l.beNewMoon);

                              Color? cardColor;
                              if (index == highlightIndex) {
                                cardColor = isSelectedPoya
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : (Theme.of(context).colorScheme.tertiaryContainer);
                              }

                              return Card(
                                key: index == highlightIndex ? highlightKey : null,
                                color: cardColor,
                                child: ListTile(
                                  dense: true,
                                  leading: Text(
                                    DateFormat('MMM dd').format(dt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index == highlightIndex
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : null,
                                    ),
                                  ),
                                  title: Text(
                                    pName,
                                    style: TextStyle(
                                      fontWeight: index == highlightIndex ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Text(
                                    _translateSeason(p.season, l),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              );
                            }).toList(),
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
