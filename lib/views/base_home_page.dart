import 'package:buddhist_sun/views/settings_page.dart';
import 'package:buddhist_sun/views/dawn_page.dart';
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

// for the theme
import 'package:flex_color_scheme/flex_color_scheme.dart';

class HomePageContainer extends StatefulWidget {
  const HomePageContainer({
    Key? key,
  }) : super(key: key);

  @override
  Home_PageContainerState createState() => Home_PageContainerState();
}

class Home_PageContainerState extends State<HomePageContainer> {
  //late List<Widget> _pages;
  final bool isDesktop =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  late PageController _pageController;

  final String page1 = "Noon";
  final String page2 = "Dawn";
  final String page3 = "TMR";
  final String page4 = "GPS";
  final String page5 = "Settings";
  final String title = "Buddhist Sun";

  void goToHome() {
    _currentIndex = 0;
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
  }

  late Home _page1;
  late DawnPage _page2;
  late CountdownTimerView _page3;
  late StatefulWidget _page4;
  late SettingsPage _page5;
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
    _page2 = DawnPage();
    _page3 = CountdownTimerView(goToHome: goToHome);
    _page4 = ((isDesktop) ? DummyPage() : GPSLocation(goToHome: goToHome));
    _page5 = SettingsPage(goToHome: goToHome);

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
          ),
        ],
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(),
              child: Column(
                children: [
                  Text('Buddhist Sun',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 17,
                      )),
                  SizedBox(height: 15.0),
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    backgroundImage: AssetImage("assets/buddhist_sun.png"),
                    radius: 40.0,
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Help',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  )),
              onTap: () {
                showHelpDialog(context);
              },
            ),
            ListTile(
              title: Text('About',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  )),
              onTap: () {
                showAboutDialog(context);
              },
            ),
            ListTile(
              title: Text('Licences',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  )),
              onTap: () {
                showLicenseDialog(context);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavyBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
            BottomNavyBarItem(
                activeColor: Theme.of(context).bottomAppBarColor,
                title: Text(
                  page1,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                ),
                icon: Icon(Icons.brightness_5_sharp,
                    color: Theme.of(context).appBarTheme.foregroundColor)),
            BottomNavyBarItem(
                activeColor: Theme.of(context).bottomAppBarColor,
                title: Text(
                  page2,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                ),
                icon: Icon(Icons.brightness_4,
                    color: Theme.of(context).appBarTheme.foregroundColor)),
            BottomNavyBarItem(
                activeColor: Theme.of(context).bottomAppBarColor,
                title: Text(
                  page3,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                ),
                icon: Icon(Icons.timer,
                    color: Theme.of(context).appBarTheme.foregroundColor)),
            BottomNavyBarItem(
                activeColor: Theme.of(context).bottomAppBarColor,
                title: Text(
                  page4,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                ),
                icon: Icon(
                  Icons.gps_fixed_rounded,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                )),
            BottomNavyBarItem(
                activeColor: Theme.of(context).bottomAppBarColor,
                title: Text(
                  page5,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                ),
                icon: Icon(Icons.settings,
                    color: Theme.of(context).appBarTheme.foregroundColor)),
//            BottomNavyBarItem(title: Text(page5), icon: Icon(Icons.more_time)),
          ]),
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
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
      title: Text("About",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 15,
          )),
      content: SingleChildScrollView(
        child: Text(AppLocalizations.of(context)!.about_content,
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
      title: Text(AppLocalizations.of(context)!.help),
      content: SingleChildScrollView(
        child: Text(AppLocalizations.of(context)!.help_content,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }
}
