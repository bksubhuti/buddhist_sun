import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/buddhavassa_data.dart';
import '../utils/buddhavassa_calculator.dart';
import '../l10n/app_localizations.dart';
import '../src/models/prefs.dart';
import '../widgets/poya_bottom_sheet.dart';

class BuddhavassaPage extends StatefulWidget {
  const BuddhavassaPage({Key? key}) : super(key: key);

  @override
  State<BuddhavassaPage> createState() => _BuddhavassaPageState();
}

class _BuddhavassaPageState extends State<BuddhavassaPage> with RouteAware {
  DateTime _selectedDate = DateTime.now();

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
    _selectedDate = DateTime.now();
  }

  String _translateSeason(String raw, AppLocalizations l) {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final loc = BuddhavassaLocalization(
      paliTemplate: (animal, season, month, paksha, tithi, weekday) =>
          l.bePaliTemplate(animal, season, month, paksha, tithi, weekday),
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
        "Magha": l.beMonth_Magha,
        "Phagguna": l.beMonth_Phagguna,
        "Citta": l.beMonth_Citta,
        "Adhivesakha": l.beMonth_Adhivesakha,
        "Vesakha": l.beMonth_Vesakha,
        "Jettha": l.beMonth_Jettha,
        "Asalha": l.beMonth_Asalha,
        "Savana": l.beMonth_Savana,
        "Potthapada": l.beMonth_Potthapada,
        "Assayuja": l.beMonth_Assayuja,
        "Kattika": l.beMonth_Kattika,
        "Maghasira": l.beMonth_Maghasira,
        "Phussa": l.beMonth_Phussa,
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

    final poyaList = BuddhavassaData.getPoyaList(_tradition);
    final calc = BuddhavassaCalculator.calculate(_selectedDate, loc, poyaList);

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(l.beTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showPoyaModal(l),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.bePoyaMenu,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.list_alt, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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

  void _onMenuSelected(int item, AppLocalizations l) {
    switch (item) {
      case 1:
        _showPoyaModal(l);
        break;
      case 2:
        _showVasModal(l);
        break;
    }
  }

  void _showPoyaModal(AppLocalizations l) {
    PoyaBottomSheet.show(context, _selectedDate, _tradition, l);
  }

  void _showVasModal(AppLocalizations l) {
    final y = _selectedDate.year;
    final poyaList = BuddhavassaData.getPoyaList(_tradition);
    final yearPoyas =
        poyaList.where((p) => p.date.startsWith(y.toString())).toList();
    final gim = yearPoyas.where((p) => p.season == "Gimhana").toList();
    final vas = yearPoyas.where((p) => p.season == "Vassana").toList();

    String p1 = "-", p2 = "-", p3 = "-", p4 = "-";
    if (gim.isNotEmpty) {
      final d1 = DateTime.parse(gim.last.date).add(const Duration(days: 1));
      p1 = DateFormat('yyyy/MM/dd').format(d1);
    }
    if (vas.length >= 6) {
      p2 = DateFormat('yyyy/MM/dd').format(DateTime.parse(vas[5].date));
    }
    if (vas.length >= 2) {
      final d3 = DateTime.parse(vas[1].date).add(const Duration(days: 1));
      p3 = DateFormat('yyyy/MM/dd').format(d3);
    }
    if (vas.length >= 8) {
      p4 = DateFormat('yyyy/MM/dd').format(DateTime.parse(vas[7].date));
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
