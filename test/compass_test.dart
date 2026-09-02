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
      Prefs.userDest1 = 'My Temple';
      Prefs.userDest1Lat = 12.34;
      Prefs.userDest1Long = 56.78;

      expect(Prefs.targetName, equals('shwedagonPagoda'));
      expect(Prefs.targetLat, equals(16.7984));
      expect(Prefs.targetLong, equals(96.1495));
      expect(Prefs.vibeOn, isTrue);
      expect(Prefs.compassShowMap, isTrue);
      expect(Prefs.userDest1, equals('My Temple'));
      expect(Prefs.userDest1Lat, equals(12.34));
      expect(Prefs.userDest1Long, equals(56.78));
    });

    testWidgets('PlaceSelector renders with localized options', (WidgetTester tester) async {
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
  });
}
