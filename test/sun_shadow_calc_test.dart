import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    // Use Bodh Gaya coordinates for test
    Prefs.lat = 24.6951;
    Prefs.lng = 84.9913;
    Prefs.offset = 5.5;
  });

  group('Solar Position & Shadow Calculation Tests', () {
    test('Solar position returns valid coordinates at solar noon', () {
      final noon = getSolarNoonRaw();
      // noon is at ~11:48 local time
      final noonUtcConstruct = DateTime.utc(
        noon.year,
        noon.month,
        noon.day,
        noon.hour,
        noon.minute,
        noon.second,
      );
      final pos = getSolarPositionAt(noon);

      // At solar noon, elevation should be high (> 50 degrees in September in Bodh Gaya)
      expect(pos.elevation, greaterThan(50.0));
      expect(pos.elevation, lessThanOrEqualTo(90.0));
      expect(pos.isDay, isTrue);

      // Shadow azimuth should be near 0° or 360° (pointing North) when sun is South (~180°)
      final diff = (pos.shadowAzimuth - pos.azimuth).abs();
      expect((diff - 180.0).abs(), lessThan(0.01));

      // Shadow length should be non-null and positive
      expect(pos.shadowLength, isNotNull);
      expect(pos.shadowLength!, greaterThan(0.0));
    });

    test('Solar noon has shortest shadow compared to morning and afternoon',
        () {
      final noon = getSolarNoonRaw();
      final morning = noon.subtract(const Duration(hours: 3));
      final afternoon = noon.add(const Duration(hours: 3));

      final posNoon = getSolarPositionAt(noon);
      final posMorning = getSolarPositionAt(morning);
      final posAfternoon = getSolarPositionAt(afternoon);

      expect(posNoon.shadowLength!, lessThan(posMorning.shadowLength!));
      expect(posNoon.shadowLength!, lessThan(posAfternoon.shadowLength!));
      expect(posNoon.elevation, greaterThan(posMorning.elevation));
      expect(posNoon.elevation, greaterThan(posAfternoon.elevation));
    });

    test('getDaySolarArc returns sampled positions across 24 hours', () {
      final date = DateTime(2026, 6, 21);
      final arc = getDaySolarArc(date, samples: 24);

      expect(arc.length, equals(25)); // 0..24 inclusive
      expect(arc.any((p) => p.isDay), isTrue);
      expect(arc.any((p) => !p.isDay), isTrue);
    });

    test('Midnight solar position is below horizon and has null shadow', () {
      final midnight = DateTime(2026, 6, 21, 0, 0, 0);
      final pos = getSolarPositionAt(midnight);
      expect(pos.elevation, lessThan(0.0));
      expect(pos.isDay, isFalse);
      expect(pos.shadowLength, isNull);
    });

    test('getSelectedDawn respects Prefs.dawnVal setting', () {
      // Test Nautical Twilight (dawnVal = 0)
      Prefs.dawnVal = 0;
      final nautical = getSelectedDawn();
      expect(nautical, equals(getNauticalTwilight()));

      // Test Sunrise - 40 min (dawnVal = 1)
      Prefs.dawnVal = 1;
      final sr40 = getSelectedDawn();
      expect(sr40, equals(getSunrise40()));

      // Test Civil Twilight (dawnVal = 6)
      Prefs.dawnVal = 6;
      final civil = getSelectedDawn();
      expect(civil, equals(getCivilTwilight()));

      // Test Sunrise (dawnVal = 7)
      Prefs.dawnVal = 7;
      final sr = getSelectedDawn();
      expect(sr, equals(getSunrise()));
    });

    test('Civil Dusk occurs after Sunset', () {
      final sunset = getSunset();
      final dusk = getCivilDusk();
      expect(dusk.isAfter(sunset), isTrue);
    });

    test(
        'Compass projection correctly transforms world coordinates into device frame',
        () {
      // Suppose an object (like North or a shadow) is at true North: x = 0, y = 1
      const x = 0.0;
      const y = 1.0;

      // 1. Phone pointing North (heading = 0°): Object should be straight ahead (x1 = 0, y1 = 1)
      double heading = 0.0;
      double yaw = heading * (3.141592653589793 / 180.0);
      double x1 = x * math.cos(yaw) - y * math.sin(yaw);
      double y1 = x * math.sin(yaw) + y * math.cos(yaw);
      expect(x1.abs(), lessThan(1e-6));
      expect(y1, closeTo(1.0, 1e-6));

      // 2. Phone pointing East (heading = 90°): North should be to the left of phone (x1 = -1, y1 = 0)
      heading = 90.0;
      yaw = heading * (3.141592653589793 / 180.0);
      x1 = x * math.cos(yaw) - y * math.sin(yaw);
      y1 = x * math.sin(yaw) + y * math.cos(yaw);
      expect(x1, closeTo(-1.0, 1e-6));
      expect(y1.abs(), lessThan(1e-6));

      // 3. Phone pointing West (heading = 270°): North should be to the right of phone (x1 = +1, y1 = 0)
      heading = 270.0;
      yaw = heading * (3.141592653589793 / 180.0);
      x1 = x * math.cos(yaw) - y * math.sin(yaw);
      y1 = x * math.sin(yaw) + y * math.cos(yaw);
      expect(x1, closeTo(1.0, 1e-6));
      expect(y1.abs(), lessThan(1e-6));
    });
  });
}
