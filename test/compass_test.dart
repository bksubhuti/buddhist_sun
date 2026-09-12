import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/widgets/place_selector.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  group('Compass Prefs and PlaceSelector Tests', () {
    test('Default compass prefs are correct', () {
      expect(Prefs.targetName, equals('bodhGaya'));
      expect(Prefs.targetLat, equals(24.6951));
      expect(Prefs.targetLong, equals(84.9913));
      expect(Prefs.vibeOn, isFalse);
      expect(Prefs.compassShowMap, isFalse);
      expect(Prefs.userDest1, isEmpty);
      expect(Prefs.userDest1Lat, equals(0.0));
      expect(Prefs.userDest1Long, equals(0.0));
    });

    test('Compass prefs getters and setters work correctly', () {
      Prefs.targetName = 'shwedagonPagoda';
      Prefs.targetLat = 16.7984;
      Prefs.targetLong = 96.1495;
      Prefs.vibeOn = true;
      Prefs.compassShowMap = true;
      Prefs.compassViewMode = 'earth';
      Prefs.userDest1 = 'My Temple';
      Prefs.userDest1Lat = 12.34;
      Prefs.userDest1Long = 56.78;

      expect(Prefs.targetName, equals('shwedagonPagoda'));
      expect(Prefs.targetLat, equals(16.7984));
      expect(Prefs.targetLong, equals(96.1495));
      expect(Prefs.vibeOn, isTrue);
      expect(Prefs.compassShowMap, isTrue);
      expect(Prefs.compassViewMode, equals('earth'));
      expect(Prefs.userDest1, equals('My Temple'));
      expect(Prefs.userDest1Lat, equals(12.34));
      expect(Prefs.userDest1Long, equals(56.78));

      // Test 3 view modes persistence
      Prefs.compassViewMode = 'compass';
      expect(Prefs.compassViewMode, equals('compass'));
      Prefs.compassViewMode = 'map2d';
      expect(Prefs.compassViewMode, equals('map2d'));
      Prefs.compassViewMode = 'earth';
      expect(Prefs.compassViewMode, equals('earth'));
    });

    test('Earth auto-framing calculation gives expected zoom levels (65% of card)', () {
      // Sri Lanka to Bodh Gaya (~2000 km): points span 65% of card (20% less than original 85%)
      // Statue of Liberty (~14000 km, other side of globe): Earth is 65% visible (zoom = 0.0)
      const double targetSpan = 188.5;
      const double baseRadius = 94.25;
      const double earthRadiusKm = 6371.0;

      double computeZoom(double distanceKm) {
        if (distanceKm <= 0.0) return 0.0;
        final double theta = (distanceKm / earthRadiusKm).clamp(0.01, 3.141592653589793);
        if (distanceKm >= 9500 || theta >= (3.141592653589793 * 0.52)) {
          return 0.0;
        }
        final double desiredRadius = targetSpan / (2.0 * (theta / 2.0));
        return desiredRadius / baseRadius;
      }

      // At zoom 0.0, the Earth diameter is exactly 188.5 px = 65% of 290 px card
      expect(2 * baseRadius, equals(targetSpan));
      expect(targetSpan / 290.0, closeTo(0.65, 0.01));

      // Bodh Gaya (~2000 km) zooms in
      expect(computeZoom(2000.0), greaterThan(1.0));
      // Statue of Liberty (~14000 km) stays at zoom 0.0
      expect(computeZoom(14000.0), equals(0.0));
    });

    testWidgets('PlaceSelector renders with localized options',
        (WidgetTester tester) async {
      Prefs.targetName = 'bodhGaya';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: PlaceSelector(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlaceSelector), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('Bodh Gaya'), findsOneWidget);
    });

    testWidgets(
        'PlaceSelector includes Mahamuni, Wat Phra Kaew, and enter custom',
        (WidgetTester tester) async {
      Prefs.targetName = 'userDest1';
      Prefs.userDest1 = '';
      Prefs.userDest1Lat = 0.0;
      Prefs.userDest1Long = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: PlaceSelector(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Custom place initially defaults to 'enter custom'
      expect(find.text('enter custom'), findsOneWidget);
      // An edit button is present when userDest1 is selected
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Open dropdown to see items
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Mahamuni Pagoda'), findsWidgets);
      expect(find.text('Wat Phra Kaew'), findsWidgets);
    });
  });
}
