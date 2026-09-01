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
    'mahaCetiya': {
      'latitude': 8.3500,
      'longitude': 80.3964
    }, // Ruwanwelisaya, Sri Lanka
    'toothRelicPagoda': {
      'latitude': 7.2936,
      'longitude': 80.6413
    }, // Sri Dalada Maligawa, Sri Lanka
  };

  late String _selectedId;

  @override
  void initState() {
    super.initState();

    // Rebuild the map fresh every time PlaceSelector is constructed
    if (Prefs.userDest1.isNotEmpty) {
      _placeById['userDest1'] = {
        'latitude': Prefs.userDest1Lat,
        'longitude': Prefs.userDest1Long,
      };
    }

    _selectedId = _normalizeSavedTarget(Prefs.targetName);
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
      case 'Maha Cetiya':
        return 'mahaCetiya';
      case 'Tooth Relic Pagoda':
        return 'toothRelicPagoda';
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
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      case 'toothRelicPagoda':
        return t.place_toothRelicPagoda;
      case 'userDest1':
        return Prefs.userDest1;
      default:
        return id;
    }
  }

  void _onPlaceSelected(String? id) {
    if (id == null) return;

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
        return 'assets/images/flags/flag_myanmar.png';
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
        Icons.place_rounded,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
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
    );
  }
}
