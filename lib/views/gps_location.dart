import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class GPSLocation extends StatefulWidget {
  @override
  _GPSLocationState createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
  Geolocator geoLocator = Geolocator();

  String _message = "";

  @override
  void initState() {
    initGps();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initGps() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _message = 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _message =
          'Location permissions are permanently denied, we cannot request permissions.';
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cityName", "GPS Generated");
    prefs.setDouble("lat", position.latitude);
    prefs.setDouble("lng", position.longitude);

    _message = 'GPS is set to ${position.latitude}, ${position.longitude}';

    setState(() {});
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text('$_message'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Text("Use GPS here"),
    );
  }
}
