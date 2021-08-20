import 'package:buddhist_sun/views/choose_location.dart';
import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/countdown_timer_view.dart';

import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';

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

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);

    return Scaffold(
      appBar: AppBar(
        title: Text("Buddhist Sun"),
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
      title: Text("About", style: TextStyle(fontSize: 15, color: Colors.blue)),
      content: SingleChildScrollView(
        child: Text(
            "Buddhist Sun is a small app for Buddhist monks and nuns to display the Solar Noon time without any flipping through screens, etc. "
            "Because I usually eat with my hands, I needed to have a \"hands free\" way to know when the Noon was approaching. "
            "Now I am able to know how much time is left while I'm eating without the need to touch my phone.  My family had a rule: \nNo phone during"
            "mealtimes.\n (We only had one wired house phones back then.)  Because Myanmar considers green tea as a food, I do not drink green tea "
            "in the afternoon, so the timer comes in handy also for drinking tea"
            "I enjoy using the app, I hope that you do too."
            "\n\nWhy is this important?\n"
            "Those who follow Buddhist monastic rules are not allowed to eat after Noon.  The rule is according to the sun rather than a clock. "
            "They did not have clocks in the Buddha's time.  Others who follow 8 or 10 precepts may this app useful too.\n"
            "\nI recommend LunaSoCal (Android) for other features or verifying the accuracy of this application.  TimeandDate.com is also a good "
            "resource. This application meant for \"present moment/location\" use"
            "\n\nMay this help you reach Nibbāna safely and quickly!",
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
            "This is an Open Source Project.  Licenses for the Flutter development Packages used here are found on the repository website\n\n"
            ''' github.com/bksubhuti/buddhist_sun/  '''
            "\n\n"
            '''
sun picture derived by creativecommons cc-sa-attrib
Own self; User:Bruno_Vallette, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons


citydb.db created from source information thatis creative commons attrib
https://simplemaps.com/data/world-cities'''
            '''
External Packages used:  (see pub.dev)
  intl: ^0.17.0
  flutter_spinkit: "^5.0.0"
  solar_calculator: ^1.0.2
  path_provider: ^2.0.2
  cupertino_icons: ^1.0.2
  sqflite_common_ffi: ^2.0.0+1
  sqflite: ^2.0.0+3
  shared_preferences: ^2.0.6
  geolocator: ^7.4.0
  bottom_navy_bar: ^6.0.0
  circular_countdown_timer: ^0.2.0
  flutter_tts: ^3.2.2
  wakelock: ^0.5.3+3
  flutter_background: ^1.0.2+1
  motion_toast: ^1.3.0

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
            "HOME:\n"
            "The Home screen displays the Solar Noon for the current day as selected by GPS or City in an easy to view manner. "
            "\n\nGPS:\n"
            "GPS will automatically set the GMT offset.  However, if you select your own city, you will need to set the offset yourself.  "
            "However, if you use GPS first, and you are in the same timezone, the offset should be correct.  It is recommended that you "
            "use the GPS settings for your location because the Solar Noon will be most accurate this way and the GMT offset is automatic "
            "although it was not tested in \"Day Light Savings\" locations. \n\n"
            "\nTimer:\n"
            "The Timer screen allows for hands free audio notifications.  TTS means \"Text to Speech\".  The TTS volume is controlled by your music volum.  "
            "Under normal conditions the TTS only works while the screen is on.  To counter this, you can make the screen stay awake with the \"Screen Always On\" switch, "
            "or you can switch on \"TTS with screen off.\"\n  This will enable background operation while your screen is off and prevent from sleeping."
            "You should test this background feature a few times before relying on it.  Some phones might be too aggressive in battery saving mode. "
            "We are not responsible for anything.  When you close the applicaton, a method is called to stop the background task.  This feature is disabled for iOS users."
            "\n\nPrivacy:\n"
            "We do not collect information and we do not establish an internet "
            "connection.  The Application does not run in the background when the app is closed.  GPS is engaged for the single request ONLY "
            "when you press the GPS button. "
            "You are quite safe as far as I know, however, this app was used with packages from the pub.dev website. "
            "A list of those packages listed in the Licence file",
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
