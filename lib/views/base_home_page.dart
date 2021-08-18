import 'package:buddhist_sun/views/choose_location.dart';
import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/countdown_timer_view.dart';

import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter_background/flutter_background.dart';
import 'dart:io' show Platform;

class HomePageContainer extends StatefulWidget {
  const HomePageContainer({Key? key}) : super(key: key);

  @override
  Home_PageContainerState createState() => Home_PageContainerState();
}

class Home_PageContainerState extends State<HomePageContainer> {
  //late List<Widget> _pages;
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
  late GPSLocation _page3;
  late ChooseLocation _page4;
  late ChooseOffset _page5;

  int _currentIndex = 0;
  //Widget _currentPage = Home();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (Platform.isAndroid) {
      //setupBackground();
    }

    _page1 = Home();
    _page2 = CountdownTimerView(goToHome: goToHome);
    _page3 = GPSLocation(goToHome: goToHome);
    _page4 = ChooseLocation(goToHome: goToHome);
    _page5 = ChooseOffset(goToHome: goToHome);

    //_pages = [_page1, _page2, _page3, _page4, _page5];

    _currentIndex = 0;
    //_currentPage = _page1;
  }

  @override
  void dispose() {
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

  void setupBackground() async {
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    print("result from setup backgroud is $success");
  }

  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText:
        "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);

    return Scaffold(
      appBar: AppBar(title: Text("Buddhist Sun")),
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
            int oldIndex = _currentIndex;
            int milliTime = (oldIndex - index) * 200;
            milliTime = (milliTime < 0) ? milliTime * -1 : milliTime;
            setState(() => _currentIndex = index);
            _pageController.animateToPage(index,
                duration: Duration(milliseconds: milliTime),
                curve: Curves.easeIn);
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
      title: Text("About"),
      content: SingleChildScrollView(
        child: Text(
            "Buddhist Sun is a small app for Buddhist monks, 10 and 8 precept yogis "
            "to follow the exact Solar Noon time.  It is intended for those tight moments when you "
            "have little time to eat and repeatedly need to look at your phone for the time."
            "This solves the problem with tts.\n  Be sure to set the offset time if not using gps or if there needs an adjustment for Day Light Savings Time"
            "\nI recommend LunaSoCal (Android) for other features.  This is meant for \"present moment\" use"
            "\nIn android it will work in the background even when the screen is off."),
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
            "This is an Open Source Project.  Licenses for the Flutter development Packages used here are found on the repository website\n\n"
            ''' github.com/bksubhuti/buddhist_sun/  '''
            "\n\n"
            '''
sun picture derived by creativecommons cc-sa-attrib
Own self; User:Bruno_Vallette, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons


citydb.db created from source information thatis creative commons attrib
https://simplemaps.com/data/world-cities'''),
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
}
