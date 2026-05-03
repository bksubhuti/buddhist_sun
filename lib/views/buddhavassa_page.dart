import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/buddhavassa_data.dart';
import '../utils/buddhavassa_calculator.dart';
import '../src/provider/locale_change_notifier.dart';
import '../l10n/app_localizations.dart';

class BuddhavassaPage extends StatefulWidget {
  const BuddhavassaPage({Key? key}) : super(key: key);

  @override
  State<BuddhavassaPage> createState() => _BuddhavassaPageState();
}

class _BuddhavassaPageState extends State<BuddhavassaPage> {
  DateTime _selectedDate = DateTime.now();

  String _translateSeason(String raw, AppLocalizations l) {
    switch (raw) {
      case 'හේමන්ත':
        return l.beSeason_Hemanta;
      case 'ගිම්හාන':
        return l.beSeason_Gimhana;
      case 'වස්සාන':
        return l.beSeason_Vassana;
      case 'නැවත හේමන්ත':
        return l.beSeason_ReHemanta;
      default:
        return raw;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _resetToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleChangeNotifier>(context);
    final l = AppLocalizations.of(context)!;
    final String currentLang =
        localeProvider.localeString == 'si' ? 'si' : 'en';

    final loc = BuddhavassaLocalization(
      paliTemplate: (a, s, m, p, t, w) => l.bePaliTemplate(a, s, m, p, t, w),
      poyaSuffix: l.bePoyaSuffix,
      fullMoon: l.beFullMoon,
      newMoon: l.beNewMoon,
      pakshaSukka: l.bePaksha_Sukka,
      pakshaKanha: l.bePaksha_Kanha,
      animals: [
        l.beAnimal_0,
        l.beAnimal_1,
        l.beAnimal_2,
        l.beAnimal_3,
        l.beAnimal_4,
        l.beAnimal_5,
        l.beAnimal_6,
        l.beAnimal_7,
        l.beAnimal_8,
        l.beAnimal_9,
        l.beAnimal_10,
        l.beAnimal_11
      ],
      seasons: {
        'Hemanta': l.beSeason_Hemanta,
        'Gimhana': l.beSeason_Gimhana,
        'Vassana': l.beSeason_Vassana,
        'ReHemanta': l.beSeason_ReHemanta,
      },
      weekDays: [
        l.beWeek_0,
        l.beWeek_1,
        l.beWeek_2,
        l.beWeek_3,
        l.beWeek_4,
        l.beWeek_5,
        l.beWeek_6
      ],
      months: {
        "මාඝ": l.beMonth_Magha,
        "ඵග්ගුන": l.beMonth_Phagguna,
        "චිත්ත": l.beMonth_Citta,
        "අධිවේසාඛ": l.beMonth_Adhivesakha,
        "වේසාඛ": l.beMonth_Vesakha,
        "ජෙට්ඨ": l.beMonth_Jettha,
        "ආසාළ්හ": l.beMonth_Asalha,
        "සාවන": l.beMonth_Savana,
        "පොට්ඨපාද": l.beMonth_Potthapada,
        "අස්සයුජ": l.beMonth_Assayuja,
        "කත්තික": l.beMonth_Kattika,
        "මාඝසිර": l.beMonth_Maghasira,
        "ඵුස්ස": l.beMonth_Phussa,
      },
      tithis: [
        l.beTithi_1,
        l.beTithi_2,
        l.beTithi_3,
        l.beTithi_4,
        l.beTithi_5,
        l.beTithi_6,
        l.beTithi_7,
        l.beTithi_8,
        l.beTithi_9,
        l.beTithi_10,
        l.beTithi_11,
        l.beTithi_12,
        l.beTithi_13,
        l.beTithi_14,
        l.beTithi_15,
      ],
      daysToPoya: (days, poya) => l.beDaysToPoya(days.toString(), poya),
    );

    final calc =
        BuddhavassaCalculator.calculate(_selectedDate, currentLang, loc);

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(l.beTitle),
        actions: [
          PopupMenuButton<int>(
            onSelected: (item) => _onMenuSelected(item, l, currentLang),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text(l.bePoyaMenu),
              ),
              PopupMenuItem(
                value: 2,
                child: Text(l.beVasMenu),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date picker row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy - MM - dd')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Year / Month / Day cards
            Row(
              children: [
                Expanded(
                    child:
                        _buildInfoCard(l.beYearLabel, calc.bYear.toString())),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _buildInfoCard(l.beMonthLabel, calc.bMonth.toString())),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildInfoCard(l.beDayLabel, calc.bDay.toString())),
              ],
            ),

            // Poya status badge
            if (calc.poyaStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  calc.poyaStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Pali text
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  calc.paliString,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Countdown to next poya
            Center(
              child: Text(
                calc.poyaMessage + (calc.isPoyaDay ? l.bePoyaSuffix : ''),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: calc.isPoyaDay
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Atikkanta & Avasittha
            Row(
              children: [
                Expanded(
                  child: _buildEraCard(
                    title: l.beAtikkanta,
                    y: calc.atikkantaY.toString(),
                    m: calc.atikkantaM.toString(),
                    d: calc.atikkantaD.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEraCard(
                    title: l.beAvasittha,
                    y: calc.avasitthaY.toString(),
                    m: calc.avasitthaM.toString(),
                    d: calc.avasitthaD.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEraCard({
    required String title,
    required String y,
    required String m,
    required String d,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 12),
            Text(
              y,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'M $m  •  D $d',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(int item, AppLocalizations l, String currentLang) {
    switch (item) {
      case 1:
        _showPoyaModal(l, currentLang);
        break;
      case 2:
        _showVasModal(l);
        break;
    }
  }

  void _showPoyaModal(AppLocalizations l, String currentLang) {
    final int selYear = _selectedDate.year;
    final yearPoyas = BuddhavassaData.poyaList
        .where((p) => p.d.startsWith(selYear.toString()))
        .toList();

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find the index to highlight:
    // - exact match if today is a poya, otherwise the next upcoming poya.
    int highlightIndex = yearPoyas.indexWhere((p) => p.d == todayStr);
    final bool isTodayPoya = highlightIndex >= 0;
    if (!isTodayPoya) {
      highlightIndex = yearPoyas.indexWhere((p) => p.d.compareTo(todayStr) > 0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final GlobalKey highlightKey = GlobalKey();

            if (highlightIndex >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = highlightKey.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(
                    ctx,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              final dt = DateTime.parse(p.d);
                              final pName = p.t
                                  .replaceAll("පසළොස්වක", l.beFullMoon)
                                  .replaceAll("අමාවක", l.beNewMoon);

                              Color? cardColor;
                              if (index == highlightIndex) {
                                cardColor = isTodayPoya
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : (Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer);
                              }

                              return Card(
                                key: index == highlightIndex
                                    ? highlightKey
                                    : null,
                                color: cardColor,
                                child: ListTile(
                                  dense: true,
                                  leading: Text(
                                    DateFormat('MMM dd').format(dt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index == highlightIndex
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : null,
                                    ),
                                  ),
                                  title: Text(
                                    pName,
                                    style: TextStyle(
                                      fontWeight: index == highlightIndex
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Text(
                                    _translateSeason(p.r, l),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
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

  void _showVasModal(AppLocalizations l) {
    final y = _selectedDate.year;
    final yearPoyas = BuddhavassaData.poyaList
        .where((p) => p.d.startsWith(y.toString()))
        .toList();
    final gim = yearPoyas.where((p) => p.r == "ගිම්හාන").toList();
    final vas = yearPoyas.where((p) => p.r == "වස්සාන").toList();

    String p1 = "-", p2 = "-", p3 = "-", p4 = "-";
    if (gim.isNotEmpty) {
      final d1 = DateTime.parse(gim.last.d).add(const Duration(days: 1));
      p1 = DateFormat('yyyy/MM/dd').format(d1);
    }
    if (vas.length >= 6) {
      p2 = DateFormat('yyyy/MM/dd').format(DateTime.parse(vas[5].d));
    }
    if (vas.length >= 2) {
      final d3 = DateTime.parse(vas[1].d).add(const Duration(days: 1));
      p3 = DateFormat('yyyy/MM/dd').format(d3);
    }
    if (vas.length >= 8) {
      p4 = DateFormat('yyyy/MM/dd').format(DateTime.parse(vas[7].d));
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.beVasTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildVasRow(l.beVas1, p1),
              _buildVasRow(l.beVas2, p2),
              _buildVasRow(l.beVas3, p3),
              _buildVasRow(l.beVas4, p4),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVasRow(String label, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            date,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
