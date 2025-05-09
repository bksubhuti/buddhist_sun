import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

class GpsService {
  static bool _initPerformed = false;

  static Future<(String? errorMessage, Position? position, String cityName)> initAndSaveGps({
    bool updateCity = true,
  }) async {
    if (!Prefs.autoGpsEnabled) return (null, null, "");
    if (_initPerformed) return (null, null, "");

    _initPerformed = true;

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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String city = "";
    if (updateCity && Prefs.retrieveCityName) {
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);
        city = placemarks.first.subAdministrativeArea ?? "Unknown";
      } catch (_) {
        city = "Unknown";
      }
    }

    Prefs.lat = position.latitude;
    Prefs.lng = position.longitude;
    Prefs.cityName = city;
    Prefs.offset = DateTime.now().timeZoneOffset.inMinutes / 60;

    return (null, position, city);
  }
}
