import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlaceSelector extends StatefulWidget {
  final Function()? onLocationChanged;

  const PlaceSelector({Key? key, this.onLocationChanged}) : super(key: key);

  @override
  State<PlaceSelector> createState() => _PlaceSelectorState();
}

class _PlaceSelectorState extends State<PlaceSelector> {
  // Stable IDs -> coordinates
  final Map<String, Map<String, double>> _placeById = {
    'bodhGaya': {'latitude': 24.6951, 'longitude': 84.9913}, // Bodh Gaya, India
    'lumbiniPagoda': {
      'latitude': 27.4697,
      'longitude': 83.2752
    }, // Lumbini, Nepal
    'sarnath': {'latitude': 25.3811, 'longitude': 83.0214}, // Sarnath, India
    'kushinagar': {
      'latitude': 26.7407,
      'longitude': 83.8886
    }, // Kushinagar, India
    'shwedagonPagoda': {
      'latitude': 16.7984,
      'longitude': 96.1495
    }, // Shwedagon, Myanmar
    'mahamuni': {
      'latitude': 21.9519,
      'longitude': 96.0785
    }, // Mahamuni, Mandalay, Myanmar
    'watPhraKaew': {
      'latitude': 13.7514,
      'longitude': 100.4925
    }, // Wat Phra Kaew, Bangkok, Thailand
    'mahaCetiya': {
      'latitude': 8.3500,
      'longitude': 80.3964
    }, // Ruwanwelisaya, Sri Lanka
    'toothRelicPagoda': {
      'latitude': 7.2936,
      'longitude': 80.6413
    }, // Sri Dalada Maligawa, Sri Lanka
    'userDest1': {
      'latitude': 0.0,
      'longitude': 0.0,
    }, // Custom place
  };

  late String _selectedId;

  @override
  void initState() {
    super.initState();

    // Rebuild the map with saved coordinates for custom place
    _placeById['userDest1'] = {
      'latitude': Prefs.userDest1Lat,
      'longitude': Prefs.userDest1Long,
    };

    final normalized = _normalizeSavedTarget(Prefs.targetName);
    _selectedId = _placeById.containsKey(normalized) ? normalized : 'bodhGaya';
  }

  String _normalizeSavedTarget(String saved) {
    if (_placeById.containsKey(saved)) return saved;
    switch (saved) {
      case 'Bodh Gaya':
        return 'bodhGaya';
      case 'Lumbini Pagoda':
        return 'lumbiniPagoda';
      case 'Sarnath':
        return 'sarnath';
      case 'kushinagar':
      case 'Kushinagar':
        return 'kushinagar';
      case 'Swedagon Pagoda':
      case 'Shwedagon Pagoda':
        return 'shwedagonPagoda';
      case 'mahamuni':
      case 'Mahamuni':
      case 'Mahamuni Pagoda':
        return 'mahamuni';
      case 'watPhraKaew':
      case 'Wat Phra Kaew':
        return 'watPhraKaew';
      case 'Maha Cetiya':
        return 'mahaCetiya';
      case 'Tooth Relic Pagoda':
        return 'toothRelicPagoda';
      case 'statueOfLiberty':
      case 'Statue of Liberty':
        return 'bodhGaya';
      case 'userDest1':
      case 'enter custom':
        return 'userDest1';
      default:
        return 'bodhGaya';
    }
  }

  String _labelFor(String id, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (id) {
      case 'bodhGaya':
        return t.place_bodhGaya;
      case 'lumbiniPagoda':
        return t.place_lumbiniPagoda;
      case 'sarnath':
        return t.place_sarnath;
      case 'kushinagar':
        return t.place_kushinagar;
      case 'shwedagonPagoda':
        return t.place_shwedagonPagoda;
      case 'mahamuni':
        return t.place_mahamuni;
      case 'watPhraKaew':
        return t.place_watPhraKaew;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      case 'toothRelicPagoda':
        return t.place_toothRelicPagoda;
      case 'userDest1':
        return Prefs.userDest1.trim().isNotEmpty
            ? Prefs.userDest1
            : t.enterCustom;
      default:
        return id;
    }
  }

  Future<void> _showCustomPlaceDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController(
      text: Prefs.userDest1.trim().isNotEmpty ? Prefs.userDest1 : '',
    );
    final latController = TextEditingController(
      text: Prefs.userDest1Lat != 0.0 ? Prefs.userDest1Lat.toString() : '0',
    );
    final longController = TextEditingController(
      text: Prefs.userDest1Long != 0.0 ? Prefs.userDest1Long.toString() : '0',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.edit_location_alt_outlined,
                color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Text(t.enterCustom),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'enter custom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Latitude (-90 to 90)',
                  hintText: '0.0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.explore_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: longController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Longitude (-180 to 180)',
                  hintText: '0.0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.explore_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.ok),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      final lat = double.tryParse(latController.text.trim()) ?? 0.0;
      final long = double.tryParse(longController.text.trim()) ?? 0.0;

      Prefs.userDest1 = name;
      Prefs.userDest1Lat = lat;
      Prefs.userDest1Long = long;

      setState(() {
        _placeById['userDest1'] = {
          'latitude': lat,
          'longitude': long,
        };
        _selectedId = 'userDest1';
      });

      Prefs.targetName = 'userDest1';
      Prefs.targetLat = lat;
      Prefs.targetLong = long;

      widget.onLocationChanged?.call();
    }
  }

  void _onPlaceSelected(String? id) {
    if (id == null) return;

    if (id == 'userDest1') {
      _showCustomPlaceDialog(context);
      return;
    }

    setState(() {
      _selectedId = id;
    });

    final coords = _placeById[id]!;
    Prefs.targetName = id;
    Prefs.targetLat = coords['latitude']!;
    Prefs.targetLong = coords['longitude']!;

    widget.onLocationChanged?.call();
  }

  String? _flagAssetFor(String id) {
    switch (id) {
      case 'bodhGaya':
      case 'sarnath':
      case 'kushinagar':
        return 'assets/images/flags/flag_india.png';
      case 'lumbiniPagoda':
        return 'assets/images/flags/flag_nepal.png';
      case 'shwedagonPagoda':
      case 'mahamuni':
        return 'assets/images/flags/flag_myanmar.png';
      case 'watPhraKaew':
        return 'assets/images/flags/flag_thailand.png';
      case 'mahaCetiya':
      case 'toothRelicPagoda':
        return 'assets/images/flags/flag_sri_lanka.png';
      default:
        return null;
    }
  }

  Widget _buildFlagWidget(String id) {
    final flagPath = _flagAssetFor(id);
    if (flagPath != null) {
      return Container(
        width: 26,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withAlpha(120),
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          flagPath,
          width: 26,
          height: 18,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 26,
      height: 18,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.edit_location_alt_outlined,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedId,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                iconSize: 26,
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: _onPlaceSelected,
                items: _placeById.keys.map((id) {
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Row(
                      children: [
                        _buildFlagWidget(id),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _labelFor(id, context),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: id == _selectedId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_selectedId == 'userDest1') ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: primary),
              tooltip: t.edit,
              visualDensity: VisualDensity.compact,
              onPressed: () => _showCustomPlaceDialog(context),
            ),
          ],
        ],
      ),
    );
  }
}
