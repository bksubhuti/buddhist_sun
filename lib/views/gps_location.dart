import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class GPSLocation extends StatefulWidget {
  GPSLocation({required this.goToHome});
  final VoidCallback goToHome;
  @override
  _GPSLocationState createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
  Geolocator geoLocator = Geolocator();
  bool _initPerformed = false;
  late Position _position;
  String _message = "Please wait for GPS";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initGps() async {
    if (!_initPerformed) {
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
      _initPerformed = true;
    } // no finished with init of gps.
    _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    _message = 'GPS Position is: ${_position.latitude}, ${_position.longitude}';
    setState(() {});
  }

  void saveGps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cityName", "GPS Generated");
    prefs.setDouble("lat", _position.latitude);
    prefs.setDouble("lng", _position.longitude);
    widget.goToHome();
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("$_message"),
      SizedBox(height: 6.0),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ElevatedButton.icon(
          icon: Icon(Icons.gps_fixed),
          onPressed: () {
            initGps();
          },
          label: Text("Get GPS"),
        ),
        SizedBox(width: 6.0),
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          onPressed: () {
            saveGps();
          },
          label: Text("Save GPS"),
        ),
      ]),
    ]));
  }
}