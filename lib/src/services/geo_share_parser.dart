import 'dart:io';

/// Structured result containing coordinates and optional place name.
class GeoLocationResult {
  final double latitude;
  final double longitude;
  final String? name;

  const GeoLocationResult({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  @override
  String toString() =>
      'GeoLocationResult(lat: $latitude, long: $longitude, name: $name)';
}

/// Utility to parse coordinates and location names from:
/// - Short Google Maps links (maps.app.goo.gl, goo.gl/maps)
/// - Full Google Maps URLs
/// - Apple Maps URLs
/// - OpenStreetMap URLs
/// - Geo URIs (geo:lat,long)
/// - Raw coordinates (decimal, DMS, cardinal direction)
class GeoShareParser {
  /// Main entry point to parse any pasted string or shared text.
  static Future<GeoLocationResult?> parse(String input) async {
    final text = input.trim();
    if (text.isEmpty) return null;

    String? placeName;

    // 1. Try to extract place name from leading text if a URL is included
    // e.g., "Wat Pah Nanachat\nhttps://maps.app.goo.gl/..."
    // or "Dropped pin near Forest Hermitage https://..."
    final urlRegex = RegExp(r'https?://[^\s]+');
    final urlMatch = urlRegex.firstMatch(text);

    if (urlMatch != null) {
      final prefix = text.substring(0, urlMatch.start).trim();
      if (prefix.isNotEmpty) {
        final cleanedPrefix = prefix
            .replaceAll(
              RegExp(
                r'^(Dropped pin near|Pinned location near|Dropped pin|Pinned location)\s*:?\s*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        final firstLine = cleanedPrefix.split('\n').first.trim();
        if (firstLine.isNotEmpty && firstLine.length < 80) {
          placeName = firstLine;
        }
      }

      String targetUrl = urlMatch.group(0)!;

      // 2. If it is a shortened URL, resolve the HTTP redirect
      if (_isShortMapsUrl(targetUrl)) {
        final resolved = await _resolveRedirectUrl(targetUrl);
        if (resolved != null) {
          targetUrl = resolved;
        }
      }

      // 3. Extract coordinates from the URL
      final fromUrl = _parseCoordinatesFromUrl(targetUrl);
      if (fromUrl != null) {
        // If no place name yet, check if URL contains place name (/place/Name/...)
        placeName ??= _extractPlaceNameFromUrl(targetUrl);
        return GeoLocationResult(
          latitude: fromUrl.lat,
          longitude: fromUrl.long,
          name: placeName,
        );
      }
    }

    // 4. Try parsing coordinates directly from raw text (decimal, DMS, cardinal)
    final fromText = _parseRawCoordinates(text);
    if (fromText != null) {
      return GeoLocationResult(
        latitude: fromText.lat,
        longitude: fromText.long,
        name: placeName,
      );
    }

    return null;
  }

  static bool _isShortMapsUrl(String url) {
    return url.contains('maps.app.goo.gl') ||
        url.contains('goo.gl/maps') ||
        url.contains('bit.ly') ||
        url.contains('tinyurl.com');
  }

  /// Follows HTTP redirects to extract the expanded Google Maps URL.
  static Future<String?> _resolveRedirectUrl(String shortUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      String current = shortUrl;

      for (int i = 0; i < 5; i++) {
        final uri = Uri.tryParse(current);
        if (uri == null) break;

        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        );
        request.followRedirects = false;

        final response = await request.close().timeout(
              const Duration(seconds: 4),
            );

        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null && location.isNotEmpty) {
            if (location.startsWith('/')) {
              current = uri.resolve(location).toString();
            } else {
              current = location;
            }

            // If coordinates are already found in the redirected URL, stop early
            if (current.contains('/@') ||
                current.contains('?q=') ||
                current.contains('&q=') ||
                current.contains('query=')) {
              return current;
            }
            continue;
          }
        }
        break;
      }
      return current;
    } catch (_) {
      return null;
    }
  }

  /// Extracts coordinates from various map URL formats.
  static ({double lat, double long})? _parseCoordinatesFromUrl(String url) {
    // Format A: /@lat,long (e.g. google.com/maps/place/.../@16.798345,96.149712,17z)
    final atMatch =
        RegExp(r'/@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)').firstMatch(url);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final long = double.tryParse(atMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    // Format B: ?q=lat,long or &q=lat,long or ?query=lat,long
    final qMatch = RegExp(r'[?&](?:q|query)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)')
        .firstMatch(url);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final long = double.tryParse(qMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    // Format C: ?ll=lat,long or &ll=lat,long (Apple Maps / Google Maps)
    final llMatch =
        RegExp(r'[?&]ll=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)').firstMatch(url);
    if (llMatch != null) {
      final lat = double.tryParse(llMatch.group(1)!);
      final long = double.tryParse(llMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    // Format D: OpenStreetMap (openstreetmap.org/#map=zoom/lat/long)
    final osmMatch = RegExp(
            r'openstreetmap\.org/.*#map=\d+/(-?\d{1,2}\.\d+)/(-?\d{1,3}\.\d+)')
        .firstMatch(url);
    if (osmMatch != null) {
      final lat = double.tryParse(osmMatch.group(1)!);
      final long = double.tryParse(osmMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    // Format E: geo:lat,long
    final geoMatch =
        RegExp(r'geo:(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)').firstMatch(url);
    if (geoMatch != null) {
      final lat = double.tryParse(geoMatch.group(1)!);
      final long = double.tryParse(geoMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    return null;
  }

  /// Extracts place name from Google Maps URL if present.
  static String? _extractPlaceNameFromUrl(String url) {
    final placeMatch = RegExp(r'/place/([^/@?#]+)').firstMatch(url);
    if (placeMatch != null) {
      final raw = placeMatch.group(1)!;
      try {
        final decoded = Uri.decodeComponent(raw).replaceAll('+', ' ').trim();
        if (decoded.isNotEmpty &&
            !decoded.startsWith('-') &&
            !decoded.contains(',')) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Parses raw text for coordinates:
  /// - DMS: 16°47'54.0"N 96°08'59.0"E
  /// - Cardinal: 16.7983° N, 96.1497° E
  /// - Decimal: 16.7983, 96.1497
  static ({double lat, double long})? _parseRawCoordinates(String text) {
    // 1. DMS: 16°47'54.0"N 96°08'59.0"E
    final dmsRegex = RegExp(
      r'(\d{1,2})[°\s]+(\d{1,2})[\x27\s]+([\d.]+)"?\s*([NSns])[,\s]+(\d{1,3})[°\s]+(\d{1,2})[\x27\s]+([\d.]+)"?\s*([EWew])',
    );
    final dmsMatch = dmsRegex.firstMatch(text);
    if (dmsMatch != null) {
      final latDeg = double.tryParse(dmsMatch.group(1)!) ?? 0;
      final latMin = double.tryParse(dmsMatch.group(2)!) ?? 0;
      final latSec = double.tryParse(dmsMatch.group(3)!) ?? 0;
      final latDir = dmsMatch.group(4)!.toUpperCase();

      final longDeg = double.tryParse(dmsMatch.group(5)!) ?? 0;
      final longMin = double.tryParse(dmsMatch.group(6)!) ?? 0;
      final longSec = double.tryParse(dmsMatch.group(7)!) ?? 0;
      final longDir = dmsMatch.group(8)!.toUpperCase();

      var lat = latDeg + (latMin / 60.0) + (latSec / 3600.0);
      if (latDir == 'S') lat = -lat;

      var long = longDeg + (longMin / 60.0) + (longSec / 3600.0);
      if (longDir == 'W') long = -long;

      if (_isValidCoord(lat, long)) return (lat: lat, long: long);
    }

    // 2. Cardinal Decimal: 16.798345° N, 96.149712° E
    final cardRegex = RegExp(
      r'(\d{1,2}(?:\.\d+)?)\s*°?\s*([NSns])[,\s]+(\d{1,3}(?:\.\d+)?)\s*°?\s*([EWew])',
    );
    final cardMatch = cardRegex.firstMatch(text);
    if (cardMatch != null) {
      var lat = double.tryParse(cardMatch.group(1)!) ?? 0;
      final latDir = cardMatch.group(2)!.toUpperCase();
      if (latDir == 'S') lat = -lat;

      var long = double.tryParse(cardMatch.group(3)!) ?? 0;
      final longDir = cardMatch.group(4)!.toUpperCase();
      if (longDir == 'W') long = -long;

      if (_isValidCoord(lat, long)) return (lat: lat, long: long);
    }

    // 3. Simple Decimal: 16.798345, 96.149712 or 16.798345, -96.149712
    final decRegex = RegExp(r'(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)');
    final decMatch = decRegex.firstMatch(text);
    if (decMatch != null) {
      final lat = double.tryParse(decMatch.group(1)!);
      final long = double.tryParse(decMatch.group(2)!);
      if (_isValidCoord(lat, long)) return (lat: lat!, long: long!);
    }

    return null;
  }

  static bool _isValidCoord(double? lat, double? long) {
    if (lat == null || long == null) return false;
    return lat >= -90.0 && lat <= 90.0 && long >= -180.0 && long <= 180.0;
  }
}
