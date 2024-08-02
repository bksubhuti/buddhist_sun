import 'package:buddhist_sun/views/show_daylight_savings_notice.dart';
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
import 'package:buddhist_sun/views/show_set_locale_dialog.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class GPSLocation extends StatefulWidget {
  //GPSLocation({required this.goToHome});
  //final VoidCallback goToHome;
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
  List<Marker> _markers = <Marker>[];
  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    if (Prefs.lng != 1.1) {
      _markers.clear();
      _markers.add(Marker(
          markerId: MarkerId(Prefs.cityName),
          position: LatLng(Prefs.lat, Prefs.lng),
          infoWindow: InfoWindow(
            title: Prefs.cityName,
          )));
    } // if not first time loading.
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getGpsPrefs() async {
    setState(() {
      _currentGPSText = "lat: ${Prefs.lat}\nlng: ${Prefs.lng}";
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
          desiredAccuracy: LocationAccuracy.high);
      _message =
          '${AppLocalizations.of(context)!.gps}: ${_position.latitude}, ${_position.longitude}';
      _cityName = "${AppLocalizations.of(context)!.gps}: ";
      saveGps(); // first success save settings
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
    Prefs.offset = timezoneOffset.inMinutes / 60;

    setState(() {
      Prefs.lat = _position.latitude;
      Prefs.lng = _position.longitude;
      _markers.clear();
      _markers.add(Marker(
          markerId: MarkerId(Prefs.cityName),
          position: LatLng(Prefs.lat, Prefs.lng),
          infoWindow: InfoWindow(
            title: Prefs.cityName,
          )));
    });
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(zoom: 16, target: LatLng(Prefs.lat, Prefs.lng))));
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    _message = AppLocalizations.of(context)!.press_wait;
    getGpsPrefs();
    if (Prefs.lat == 1.1 && _bLoading == false) {
      Future.delayed(
          Duration.zero, () => showAskGPSDialog(context)); // import 'dart:asy;
    }

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(height: 25),
        (_bLoading)
            ? SpinKitPulse(
                color: Colors.blue,
                size: 50.0,
              )
            : ColoredText(
                "$_message",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
        SizedBox(height: 15.0),
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
        ]),
        CheckboxListTile(
          title: ColoredText(
            "${AppLocalizations.of(context)!.set_gps_city}",
            style: TextStyle(),
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
        SizedBox(height: 10.0),
        ColoredText(
          "$_currentGPSText",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.0),
        ColoredText(
          "$_cityName",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          width: 350,
          height: 350,
          child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: Set<Marker>.of(_markers),
              mapType: MapType.satellite,
              initialCameraPosition: CameraPosition(
                  zoom: 16, target: LatLng(Prefs.lat, Prefs.lng))),
        ),
      ]),
    ));
  }

  Future showGpsPermissionInfoDialog(BuildContext context) async {
    // set up the button
    Widget okButton = TextButton(
      child: Text(AppLocalizations.of(context)!.ok,
          style: TextStyle(
            color: (!Prefs.darkThemeOn)
                ? Theme.of(context).primaryColor
                : Colors.white,
          )),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog help = AlertDialog(
      title: ColoredText(AppLocalizations.of(context)!.gps_permission),
      content: SingleChildScrollView(
        child: ColoredText(AppLocalizations.of(context)!.gps_permission_content,
            style: TextStyle(
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
      primaryColor: Theme.of(context).primaryColor,
      title: Text(AppLocalizations.of(context)!.notification),
      description: Text(message),
      position: MotionToastPosition.top,
      animationType: AnimationType.fromTop,
      icon: Icons.battery_charging_full,
    ).show(context);
  }

  Future showAskGPSDialog(BuildContext context) async {
    // set up the buttons
    _bLoading = true; // prevent double dialog see build function if statement
    await showSetLocaleDialog(context); // import 'dart:asy;
    await showDaylightSavingsDialog(context);
    _bLoading = false;

    Widget cancelButton = TextButton(
      child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle()),
      onPressed: () {
        Prefs.lat = 1.2;
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text(AppLocalizations.of(context)!.yes, style: TextStyle()),
      onPressed: () {
        initGps();
        Navigator.pop(context);
        ;
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: ColoredText(AppLocalizations.of(context)!.get_gps),
      content: ColoredText(AppLocalizations.of(context)!.gps_recommend),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
