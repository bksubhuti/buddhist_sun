import 'package:buddhist_sun/views/choose_location.dart';
import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/countdown_timer_view.dart';
import 'package:buddhist_sun/views/dummy_page.dart';

import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'dart:io' show Platform;
import 'package:buddhist_sun/src/models/prefs.dart';

// #docregion LocalizationDelegatesImport
//import 'package:flutter_localizations/flutter_localizations.dart';

// #enddocregion LocalizationDelegatesImport
// #docregion AppLocalizationsImport
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// #enddocregion AppLocalizationsImport

class HomePageContainer extends StatefulWidget {
  const HomePageContainer({Key? key}) : super(key: key);

  @override
  Home_PageContainerState createState() => Home_PageContainerState();
}

class Home_PageContainerState extends State<HomePageContainer> {
  //late List<Widget> _pages;
  final bool isDesktop =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  late PageController _pageController;

  final String page1 = "Home";
  final String page2 = "TMR";
  final String page3 = "GPS";
  final String page4 = "Cities";
  final String page5 = "GMT";
  final String title = "Buddhist Sun";
  final _bgcolorBlue = Colors.indigo[700];
  final _bgcolorGrey = Colors.grey[200];
  Color bgColor = Colors.indigo[700]!;

  void goToHome() {
    _currentIndex = 0;
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
  }

  late Home _page1;
  late CountdownTimerView _page2;
  late StatefulWidget _page3;
  late ChooseLocation _page4;
  late ChooseOffset _page5;
  //late DummyPage _dummyPage;

  int _currentIndex = 0;
  //Widget _currentPage = Home();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // these toggles always get set to false
    Prefs.backgroundOn = false;
    Prefs.screenAlwaysOn = false;
    Prefs.speakIsOn = false;

//    _dummyPage = DummyPage();
    _page1 = Home();
    _page2 = CountdownTimerView(goToHome: goToHome);
    _page3 = ((isDesktop) ? DummyPage() : GPSLocation(goToHome: goToHome));
    _page4 = ChooseLocation(goToHome: goToHome);
    _page5 = ChooseOffset(goToHome: goToHome);

    //_pages = [_page1, _page2, _page3, _page4, _page5];

    _currentIndex = 0;
    //_currentPage = _page1;
  }

  @override
  void dispose() {
    // cleanup the switches to always false
    // this does not get called.. but it is here anyway.
    // no dispose on exit is called. :)
    Prefs.backgroundOn = false;
    Prefs.screenAlwaysOn = false;
    Prefs.speakIsOn = false;
    print("set the toggles in prefs to false");

    _pageController.dispose();
    super.dispose();
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
      //_currentPage = _pages[index];

      // need to update the state._page1.;
    });
  }

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.buddhistSun),
        actions: [
          IconButton(
              onPressed: () {
                showHelpDialog(context);
              },
              icon: Icon(Icons.help),
              color: Colors.yellow[50]),
        ],
      ),
      backgroundColor: bgColor,
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  Text('Buddhist Sun',
                      style: TextStyle(fontSize: 17, color: Colors.white)),
                  SizedBox(height: 15.0),
                  CircleAvatar(
                    backgroundImage: AssetImage("assets/buddhist_sun.png"),
                    radius: 40.0,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Help'),
              onTap: () {
                showHelpDialog(context);
              },
            ),
            ListTile(
              title: const Text('About'),
              onTap: () {
                showAboutDialog(context);
              },
            ),
            ListTile(
              title: const Text('Licences'),
              onTap: () {
                showLicenseDialog(context);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavyBar(
          backgroundColor: Colors.blue[200],
          showElevation: true,
          itemCornerRadius: 24,
          curve: Curves.easeIn,
          selectedIndex: _currentIndex,
          onItemSelected: (index) {
            int diffIndex = _currentIndex - index;
            diffIndex = (diffIndex < 0) ? diffIndex * -1 : diffIndex;
            setState(() => _currentIndex = index);
            if (diffIndex == 1) {
              _pageController.animateToPage(index,
                  duration: Duration(milliseconds: 200), curve: Curves.easeIn);
            } else {
              _pageController.jumpToPage(index);
            }
          },
          items: <BottomNavyBarItem>[
            BottomNavyBarItem(title: Text(page1), icon: Icon(Icons.home)),
            BottomNavyBarItem(title: Text(page2), icon: Icon(Icons.timer)),
            BottomNavyBarItem(
                title: Text(page3), icon: Icon(Icons.gps_fixed_rounded)),
            BottomNavyBarItem(
                title: Text(page4), icon: Icon(Icons.location_city)),
            BottomNavyBarItem(title: Text(page5), icon: Icon(Icons.more_time)),
          ]),
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              if (_currentIndex < 1) {
                bgColor = _bgcolorBlue!;
              } else
                bgColor = _bgcolorGrey!;
            });

            //setState(() => _currentIndex = index);
          },
          children: <Widget>[
            _page1,
            _page2,
            _page3,
            _page4,
            _page5,
          ],
        ),
      ),
    );
  }

  showAboutDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("About", style: TextStyle(fontSize: 15, color: Colors.blue)),
      content: SingleChildScrollView(
        child: Text(
            "Buddhist Sun is a small app for Buddhist monks and nuns to display the Solar Noon time without any flipping through screens, etc. "
            "Because I usually eat with my hands, I needed to have a \"hands free\" way to know when the Noon was approaching. "
            "Now I am able to know how much time is left while I'm eating without the need to touch my phone.  Because Myanmar considers "
            "green tea as a food, I do not drink green tea "
            "in the afternoon, so the timer comes in handy also for drinking tea. "
            "I enjoy using the app, and I hope that you do too."
            "\n\nWhy is this important?\n"
            "Those who follow Buddhist monastic rules are not allowed to eat after Noon.  The rule is according to the sun at its zenith in the sky rather than a clock. "
            "They did not have clocks in the Buddha's time.  Others who follow 8 or 10 precepts may find this app useful too.\n"
            "\nI recommend https://TimeandDate.com to verify this app's accuracy.  "
            "This application is meant for \"present moment/location\" use.  "
            "\n\nMay this help you to reach Nibbāna quickly and safely!",
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showLicenseDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog license = AlertDialog(
      title: Text("License"),
      content: SingleChildScrollView(
        child: Text(
            "This is an Open Source Project.  Licenses for the Flutter and Flutter development Packages used here are found on the repository website\n\n"
            ''' https://github.com/bksubhuti/buddhist_sun/  

            and
            
             https://github.com/flutter/flutter/blob/master/LICENSE '''
            "\n\n"
            '''
sun picture derived by creativecommons cc-sa-attrib
Own self; User:Bruno_Vallette, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons


citydb.db created from source information that is creative commons attrib
https://simplemaps.com/data/world-cities'''
            '''
External Packages used:  (see pub.dev)

  flutter_spinkit: "^5.0.0"
  https://pub.flutter-io.cn/packages?q=flutter_spinkit

  solar_calculator: ^1.0.2
  https://pub.flutter-io.cn/packages/solar_calculator

  path_provider: ^2.0.2
  https://pub.flutter-io.cn/packages/path_provider

  sqflite_common_ffi: ^2.0.0+1
  https://pub.flutter-io.cn/packages/sqflite_common_ffi

  sqflite: ^2.0.0+3
  https://pub.flutter-io.cn/packages/sqflite

  shared_preferences: ^2.0.6
  https://pub.flutter-io.cn/packages/shared_preferences

  geolocator: ^7.4.0
  https://pub.flutter-io.cn/packages/geolocator

  bottom_navy_bar: ^6.0.0
  https://pub.flutter-io.cn/packages/bottom_navy_bar

  flutter_tts: ^3.2.2
  https://pub.flutter-io.cn/packages/flutter_tts

  wakelock: ^0.5.3+3
  https://pub.flutter-io.cn/packages/wakelock

  flutter_background: ^1.0.2+1
  https://pub.flutter-io.cn/packages/flutter_background

  motion_toast: ^1.3.0
  https://pub.flutter-io.cn/packages/motion_toast

''',
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return license;
      },
    );
  }

  showHelpDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog help = AlertDialog(
      title: Text("Help"),
      content: SingleChildScrollView(
        child: Text(
            "Calculations:\n"
            "The calculations are based on equations from Astronomical Algorithms, by Jean Meeus. The sunrise and sunset results are theoretically accurate to within a minute for locations between +/- 72° of latitud. "
            "Please consider stopping well before the stated time. "
            "\n\nHOME:\n"
            "The Home screen displays the Solar Noon for the current day as selected by GPS or City in an easy to view manner. "
            "\n\nGPS:\n"
            "GPS will automatically set the GMT offset.  However, if you select your own city, you will need to set the offset yourself.  "
            "However, if you use GPS first, and you are in the same timezone, the offset should be correct.  It is recommended that you "
            "use the GPS settings for your location because the Solar Noon will be most accurate this way and the GMT offset is automatic "
            "although it was not tested in \"Day Light Savings\" locations. \n\n"
            "\nTimer:\n"
            "The Timer screen allows for hands free audio notifications.  TTS means \"Text to Speech\".  The TTS volume is controlled by your media volume.  "
            "Under normal conditions the TTS only works while the screen is on.  To counter this, you can make the screen stay awake with the \"Screen Always On\" switch, "
            "or you can enable the \"TTS with screen off\" feature.  This will enable \"background\" operation while your screen is off and prevent the device from entering sleep mode. "
            "You should test this background feature a few times before relying on it.  Some phones or battery saving modes may not allow it to work. "
            "We are not responsible for anything nor will we pay for trips to India for bathing in the Ganges.  When you close the applicaton, a method "
            "is called to stop the background task.  You will know the app is running in the background by the sun icon displayed in the top of your "
            "phone's notification area (where the time and signal bars are).  If Buddhist Sun is not in \"background mode\", you will not see a sun icon.  "
            "This feature is not available for iOS users.\n"
            "The timings of TTS announcements are in the following minute intervals: 50,40,30,20,15,10,8,6,5,4,3,2,1,0"
            "\n\nPrivacy:\n"
            "A full privacy statement is located at:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n"
            "\nWe do not collect information and we do not establish an internet "
            "connection.  The Application does not run in the background when the app is closed.  GPS is engaged for the single request ONLY "
            "when you press the GPS button. "
            "You are quite safe as far as I know, however, this app was used with packages from the pub.dev website. "
            "A list of those packages are listed in the license page of this app or on github code repository listed there too.",
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }
}
