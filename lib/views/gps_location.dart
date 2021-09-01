import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';

class GPSLocation extends StatefulWidget {
  GPSLocation({required this.goToHome});
  final VoidCallback goToHome;
  @override
  _GPSLocationState createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
//  Geolocator geoLocator = Geolocator();
  bool _initPerformed = false;
  late Position _position;
  bool _bLoading = false;
  String _message = "Press and wait for new GPS.";
  String _currentGPSText = "";
  bool isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  String _cityName = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getGpsPrefs() async {
    super.initState();

    setState(() {
      _currentGPSText =
          "${AppLocalizations.of(this.context)!.previous_gps_is}:\nlat: ${Prefs.lat}\nlng: ${Prefs.lng}";
    });
  }

  void initGps() async {
    if (Platform.isAndroid || Platform.isIOS) {
      setState(() {
        _bLoading = true;
      });
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
          await showGpsPermissionInfoDialog(context);
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
      _message =
          '${AppLocalizations.of(context)!.gps}: ${_position.latitude}, ${_position.longitude}';
      _cityName = "${AppLocalizations.of(context)!.gps}: ";
      saveGps();// first success save settings
      //refresh internet connection checker.
      if (Prefs.retrieveCityName == true) {
        bool hasInternet = await InternetConnectionChecker().hasConnection;
        if (hasInternet) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
              _position.latitude, _position.longitude);
          _cityName += placemarks[0].subAdministrativeArea ?? "Unknown";
          saveGps(); // full success save settings with city name
          print(placemarks);
        } else {
          _displayMotionToast(
              context, AppLocalizations.of(context)!.set_gps_city);
        }
      }
    } else {
      _message = 'GPS is not supported on Desktops}';
    }
    ;
    _bLoading = false;

    setState(() {});
  }

  void saveGps() async {
    DateTime now = DateTime.now();
    var timezoneOffset = now.timeZoneOffset;

    Prefs.cityName = _cityName;
    Prefs.lat = _position.latitude;
    Prefs.lng = _position.longitude;
    Prefs.offset = timezoneOffset.inMinutes / 60;
    //widget.goToHome();
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    getGpsPrefs();

    return Container(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(height: 25),
        (_bLoading)
            ? SpinKitPulse(
                color: Colors.blue,
                size: 50.0,
              )
            : Text(
                "$_message",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
        SizedBox(height: 25.0),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(
            icon: Icon(Icons.gps_fixed),
            onPressed: (isDesktop)
                ? null
                : () {
                    initGps();
                  },
            label: Text("${AppLocalizations.of(context)!.get_gps}"),
          ),
          /*SizedBox(width: 6.0),
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            onPressed: (isDesktop) ? null : saveGps,
            label: Text("${AppLocalizations.of(context)!.save_gps}"),
          ),*/
        ]),
        CheckboxListTile(
          title: Text(
            "${AppLocalizations.of(context)!.set_gps_city}",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
          value: Prefs.retrieveCityName,
          onChanged: (newValue) {
            setState(() {
              Prefs.retrieveCityName = newValue!;
            });
          },
          controlAffinity:
              ListTileControlAffinity.leading, //  <-- leading Checkbox
        ),
        SizedBox(height: 80.0),
        Text(
          "$_currentGPSText",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 80.0),
        Text(
          "$_cityName",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    ));
  }

  Future showGpsPermissionInfoDialog(BuildContext context) async {
    // set up the button
    Widget okButton = TextButton(
      child: Text(AppLocalizations.of(context)!.ok),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog help = AlertDialog(
      title: Text(AppLocalizations.of(context)!.gps_permission),
      content: SingleChildScrollView(
        child: Text(AppLocalizations.of(context)!.gps_permission_content,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            )),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }

  _displayMotionToast(BuildContext context, String message) {
    MotionToast(
      title: AppLocalizations.of(context)!.notification,
      titleStyle: TextStyle(
          color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      description: message,
      descriptionStyle:
          TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
      layoutOrientation: ORIENTATION.RTL,
      animationType: ANIMATION.FROM_RIGHT,
      width: 300,
//      height: 90,
      icon: Icons.battery_charging_full,
      color: Colors.blue,
    ).show(context);
  }
}
