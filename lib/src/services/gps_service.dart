import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/country_service.dart';

class GpsService {
  static Future<(String? errorMessage, Position? position, String cityName)>
      initAndSaveGps({
    bool updateCity = true,
  }) async {
//    if (!Prefs.autoGpsEnabled) return (null, null, "");
    //if (_initPerformed) return (null, null, "");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return ("Location services are disabled.", null, "");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return ("Location permissions are denied.", null, "");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return ("Location permissions are permanently denied.", null, "");
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position == null) {
      return ("Could not acquire GPS position.", null, "");
    }

    String city = "";
    bool gotCountry = false;
    if (updateCity && Prefs.retrieveCityName) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        city = placemarks.first.subAdministrativeArea ?? "Unknown";
        final iso = placemarks.first.isoCountryCode;
        if (iso != null && iso.isNotEmpty) {
          Prefs.countryCode = iso;
          gotCountry = true;
        }
      } catch (_) {
        city = "Unknown";
      }
    }

    // Keep the country code current so a stale one does not stick after
    // travel. Falls back to an IP lookup when reverse geocoding gave none.
    if (!gotCountry) {
      CountryService.getCountryCode(); // background check
    }

    Prefs.lat = position.latitude;
    Prefs.lng = position.longitude;
    Prefs.cityName = city;
    Prefs.offset = DateTime.now().timeZoneOffset.inMinutes / 60;

    return (null, position, city);
  }
}
