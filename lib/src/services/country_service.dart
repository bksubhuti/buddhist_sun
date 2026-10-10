import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buddhist_sun/src/models/prefs.dart';

class CountryService {
  /// Fetches the country code via IP geolocation (api.country.is, HTTPS,
  /// open source, no key). Only the request's IP address is sent.
  /// Times out after 3 seconds so it never stalls startup or offline use.
  static Future<String?> getCountryCode() async {
    try {
      final res = await http
          .get(Uri.https('api.country.is', '/'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final code = data['country'] as String?;
        if (code != null && code.isNotEmpty) {
          Prefs.countryCode = code;
          return code;
        }
      }
    } catch (_) {}
    return null;
  }
}
