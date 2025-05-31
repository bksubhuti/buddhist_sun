//import 'package:buddhist_sun/views/show_daylight_savings_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' show Platform;
import 'package:buddhist_sun/src/models/prefs.dart';
import '../l10n/app_localizations.dart';
import 'package:buddhist_sun/views/show_set_locale_dialog.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buddhist_sun/src/services/gps_service.dart'; // ⬅️ add this
import 'dart:async';

class GPSLocation extends StatefulWidget {
  //GPSLocation({required this.goToHome});
  //final VoidCallback goToHome;
  @override
  _GPSLocationState createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
//  Geolocator geoLocator = Geolocator();
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
      setState(() => _bLoading = true);

      var (error, position, cityName) =
          await GpsService.initAndSaveGps(updateCity: Prefs.retrieveCityName);

      if (error != null) {
        _message = error;
      } else if (position != null) {
        _position = position;
        _cityName = "${AppLocalizations.of(context)!.gps}: $cityName";
        _message =
            "${AppLocalizations.of(context)!.gps}: ${position.latitude}, ${position.longitude}";
        _markers.clear();
        _markers.add(Marker(
            markerId: MarkerId(cityName),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: cityName)));

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              zoom: 16, target: LatLng(position.latitude, position.longitude)),
        ));

        for (int i = 0; i < 10; i++) {
          HapticFeedback.heavyImpact();
        }
      }
      setState(() => _bLoading = false);
    } else {
      setState(() {
        _message = 'GPS is not supported on Desktops';
      });
    }
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    _message = AppLocalizations.of(context)!.press_wait;
    getGpsPrefs();

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
        SwitchListTile(
          title: ColoredText(AppLocalizations.of(context)!.autoUpdateGps),
          value: Prefs.autoGpsEnabled,
          onChanged: (value) {
            setState(() {
              Prefs.autoGpsEnabled = value;
            });
          },
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
            label: Text(AppLocalizations.of(context)!.get_gps),
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

  Future showAskGPSDialog(BuildContext context) async {
    // set up the buttons
    _bLoading = true; // prevent double dialog see build function if statement
    await showSetLocaleDialog(context); // import 'dart:asy;

    // no longer showing this
    //await showDaylightSavingsDialog(context);
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
