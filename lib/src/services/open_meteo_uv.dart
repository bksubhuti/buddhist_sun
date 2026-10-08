import 'dart:convert';

import 'package:http/http.dart' as http;

/// Hourly UV data from the Open-Meteo air-quality API (https://open-meteo.com,
/// CC BY 4.0), computed from Copernicus CAMS ozone and aerosol forecasts.
/// Its clear-sky UV agrees with other sources in the tropics; the weather
/// forecast API's UV read ~20% low there and was shifted by about an hour.
///
/// One request returns both:
///  * `uv_index_clear_sky` — clear-sky UV including ozone, altitude and
///    aerosols; used to correct the offline sun-angle estimate.
///  * `uv_index` — the same with forecast clouds; used only when the user
///    picks the "Forecast" sky.
class UvForecast {
  /// Day and rounded location this data belongs to (see controller).
  final String key;
  final DateTime fetchedAt;
  final List<DateTime> times;
  final List<double> uv;
  final List<double> clearSky;

  const UvForecast({
    required this.key,
    required this.fetchedAt,
    required this.times,
    required this.uv,
    required this.clearSky,
  });

  /// Downloads yesterday to tomorrow (UTC) so the whole local day is
  /// covered in any time zone. Returns null on any failure.
  static Future<UvForecast?> fetch({
    required double lat,
    required double lng,
    required String key,
    required DateTime now,
  }) async {
    final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      // ~1 km is plenty for UV and keeps the exact location private.
      'latitude': lat.toStringAsFixed(2),
      'longitude': lng.toStringAsFixed(2),
      'hourly': 'uv_index,uv_index_clear_sky',
      'timeformat': 'unixtime',
      'timezone': 'GMT',
      'past_days': '1',
      'forecast_days': '2',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final hourly =
          (jsonDecode(res.body) as Map<String, dynamic>)['hourly'] as Map;
      final t = hourly['time'] as List;
      final u = hourly['uv_index'] as List;
      final c = hourly['uv_index_clear_sky'] as List;
      final times = <DateTime>[];
      final uv = <double>[];
      final clear = <double>[];
      for (int i = 0; i < t.length && i < u.length && i < c.length; i++) {
        if (u[i] == null || c[i] == null) continue;
        times.add(
            DateTime.fromMillisecondsSinceEpoch((t[i] as num).toInt() * 1000));
        uv.add((u[i] as num).toDouble());
        clear.add((c[i] as num).toDouble());
      }
      if (times.isEmpty) return null;
      return UvForecast(
          key: key, fetchedAt: now, times: times, uv: uv, clearSky: clear);
    } catch (_) {
      return null;
    }
  }

  /// Ratio of forecast UV to clear-sky UV at [t] (cloud factor, 0..1),
  /// interpolated between hours. 1.0 when there is too little UV to tell.
  double cloudFactorAt(DateTime t) {
    double? ratio(int i) =>
        clearSky[i] >= 0.3 ? (uv[i] / clearSky[i]).clamp(0.0, 1.0) : null;
    final ms = t.millisecondsSinceEpoch;
    for (int i = 0; i < times.length - 1; i++) {
      final a = times[i].millisecondsSinceEpoch;
      final b = times[i + 1].millisecondsSinceEpoch;
      if (ms < a || ms > b) continue;
      final ra = ratio(i);
      final rb = ratio(i + 1);
      if (ra == null) return rb ?? 1.0;
      if (rb == null) return ra;
      return ra + (rb - ra) * (ms - a) / (b - a);
    }
    return 1.0;
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
        'times': times.map((d) => d.millisecondsSinceEpoch).toList(),
        'uv': uv,
        'clearSky': clearSky,
      };

  /// Restores saved data, or null if missing or unreadable.
  static UvForecast? load(String json) {
    if (json.isEmpty) return null;
    try {
      final j = jsonDecode(json) as Map<String, dynamic>;
      return UvForecast(
        key: j['key'] as String,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(j['fetchedAt'] as int),
        times: (j['times'] as List)
            .map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
            .toList(),
        uv: (j['uv'] as List).map((e) => (e as num).toDouble()).toList(),
        clearSky:
            (j['clearSky'] as List).map((e) => (e as num).toDouble()).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
