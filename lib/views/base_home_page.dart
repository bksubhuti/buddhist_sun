import 'package:buddhist_sun/views/about_buddhist_sun_dialog.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:buddhist_sun/views/moon_view.dart';
import 'package:buddhist_sun/views/settings_page.dart';
import 'package:buddhist_sun/views/dawn_page.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/countdown_timer_view.dart';
//import 'package:buddhist_sun/views/dummy_page.dart';

import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'dart:io' show Platform;
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';

// #docregion LocalizationDelegatesImport
//import 'package:flutter_localizations/flutter_localizations.dart';

// #enddocregion LocalizationDelegatesImport
// #docregion AppLocalizationsImport
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
// #enddocregion AppLocalizationsImport

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

  final String title = "Buddhist Sun";

  void goToHome() {
    _currentIndex = 0;
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
  }

  late Home _page1;
  late CountdownTimerView _page2;
  late DawnPage _page3;
  late MoonPage _page4;
  late GPSLocation _page5;
  //late DummyPage _dummyPage;

  int _currentIndex = (Prefs.lat == 1.1) ? 4 : 0;
  //Widget _currentPage = Home();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // these toggles always get set to false
    Prefs.backgroundOn = false;
    Prefs.screenAlwaysOn = false;
    Prefs.speakIsOn = false;
    //    _dummyPage = DummyPage();
    _page1 = Home();
    _page2 = CountdownTimerView(goToHome: goToHome);
    _page3 = DawnPage();
    _page4 = MoonPage();
    _page5 = GPSLocation();
//    _page4 = ((isDesktop) ? DummyPage() : GPSLocation(goToHome: goToHome));
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
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
              (context);
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).canvasColor,
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
                  ColoredText(AppLocalizations.of(context)!.buddhistSun,
                      style: TextStyle(
                        fontSize: 17,
                      )),
                  SizedBox(height: 15.0),
                  ClipOval(
                    child: Image.asset(
                      "assets/buddhist_sun_app_logo.png",
                      fit: BoxFit.cover,
                      width: 80.0,
                      height: 80.0,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context); // close the drawer
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: ColoredText(AppLocalizations.of(context)!.help,
                  style: TextStyle()),
              onTap: () {
                showHelpDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: ColoredText(AppLocalizations.of(context)!.about,
                  style: TextStyle()),
              onTap: () {
                showAboutBuddhistSunDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.verified),
              title: ColoredText(AppLocalizations.of(context)!.verify,
                  style: TextStyle()),
              onTap: () async {
                final Uri url = Uri.parse(
                    'https://www.timeanddate.com/sun/@${Prefs.lat},${Prefs.lng}');
                // another website 'https://gml.noaa.gov/grad/solcalc/table.php?lat=${Prefs.lat}.833&lon=${Prefs.lng}&year=$year');

                if (!await launchUrl(url)) {
                  throw Exception('Could not launch $url');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.star), // Added Icon
              title: ColoredText(AppLocalizations.of(context)!.rateThisApp),
              focusColor: Theme.of(context).focusColor,
              hoverColor: Theme.of(context).hoverColor,
              onTap: () {
                final InAppReview inAppReview = InAppReview.instance;
                inAppReview.openStoreListing(appStoreId: '1585091207');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavyBar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
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
                activeColor: Theme.of(context).primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.noon,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
                icon: Icon(
                  Icons.brightness_5_sharp,
                  color: Theme.of(context).primaryColor,
                )),
            BottomNavyBarItem(
                activeColor: Theme.of(context).primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.timer,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
                icon: Icon(
                  Icons.timer,
                  color: Theme.of(context).primaryColor,
                )),
            BottomNavyBarItem(
                activeColor: Theme.of(context).primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.dawn,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
                icon: Icon(
                  Icons.brightness_4,
                  color: Theme.of(context).primaryColor,
                )),
            BottomNavyBarItem(
                activeColor: Theme.of(context).primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.moon,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
                icon: Icon(
                  Icons.dark_mode,
                  color: Theme.of(context).primaryColor,
                )),
            BottomNavyBarItem(
                activeColor: Theme.of(context).primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.gps,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
                icon: Icon(
                  Icons.gps_fixed_rounded,
                  color: Theme.of(context).primaryColor,
                )),
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

  showHelpDialog(BuildContext context) {
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
      title: ColoredText(AppLocalizations.of(context)!.help),
      content: SingleChildScrollView(
        child: ColoredText(AppLocalizations.of(context)!.help_content,
            style: TextStyle(
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
