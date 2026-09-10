import 'package:flutter_test/flutter_test.dart';
import 'package:buddhist_sun/src/services/geo_share_parser.dart';

void main() {
  group('GeoShareParser Tests', () {
    test('parses simple decimal coordinates', () async {
      final res = await GeoShareParser.parse('16.798345, 96.149712');
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.798345, 0.0001));
      expect(res.longitude, closeTo(96.149712, 0.0001));
    });

    test('parses negative decimal coordinates', () async {
      final res = await GeoShareParser.parse('-33.8688, 151.2093');
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(-33.8688, 0.0001));
      expect(res.longitude, closeTo(151.2093, 0.0001));
    });

    test('parses cardinal decimal coordinates', () async {
      final res = await GeoShareParser.parse('16.7983° N, 96.1497° E');
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.7983, 0.0001));
      expect(res.longitude, closeTo(96.1497, 0.0001));
    });

    test('parses south/west cardinal decimal coordinates', () async {
      final res = await GeoShareParser.parse('33.8688° S, 70.6693° W');
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(-33.8688, 0.0001));
      expect(res.longitude, closeTo(-70.6693, 0.0001));
    });

    test('parses DMS coordinates', () async {
      final res = await GeoShareParser.parse('16°47\'54.0"N 96°08\'59.0"E');
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.798333, 0.001));
      expect(res.longitude, closeTo(96.149722, 0.001));
    });

    test('parses full Google Maps place URL with name and coordinates', () async {
      const input =
          'https://www.google.com/maps/place/Shwedagon+Pagoda/@16.798345,96.149712,17z/data=!3m1!4b1';
      final res = await GeoShareParser.parse(input);
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.798345, 0.0001));
      expect(res.longitude, closeTo(96.149712, 0.0001));
      expect(res.name, equals('Shwedagon Pagoda'));
    });

    test('parses Google Maps query URL (?q=lat,long)', () async {
      const input = 'https://maps.google.com/?q=16.798345,96.149712';
      final res = await GeoShareParser.parse(input);
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.798345, 0.0001));
      expect(res.longitude, closeTo(96.149712, 0.0001));
    });

    test('parses Apple Maps URL (?ll=lat,long)', () async {
      const input = 'https://maps.apple.com/?ll=16.798345,96.149712&q=Temple';
      final res = await GeoShareParser.parse(input);
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(16.798345, 0.0001));
      expect(res.longitude, closeTo(96.149712, 0.0001));
    });

    test('parses shared text with place name and URL', () async {
      const input =
          'Forest Hermitage\nhttps://www.google.com/maps/place/@15.123456,104.654321,15z';
      final res = await GeoShareParser.parse(input);
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(15.123456, 0.0001));
      expect(res.longitude, closeTo(104.654321, 0.0001));
      expect(res.name, equals('Forest Hermitage'));
    });

    test('parses "Dropped pin near ..." text prefix', () async {
      const input =
          'Dropped pin near Great Monastery\nhttps://www.google.com/maps/@15.123456,104.654321,15z';
      final res = await GeoShareParser.parse(input);
      expect(res, isNotNull);
      expect(res!.latitude, closeTo(15.123456, 0.0001));
      expect(res.longitude, closeTo(104.654321, 0.0001));
      expect(res.name, equals('Great Monastery'));
    });

    test('returns null for invalid/empty text', () async {
      expect(await GeoShareParser.parse(''), isNull);
      expect(await GeoShareParser.parse('hello world'), isNull);
      expect(await GeoShareParser.parse('https://example.com/foo'), isNull);
    });
  });
}
