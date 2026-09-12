import 'package:buddhist_sun/views/about_buddhist_sun_dialog.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:buddhist_sun/views/moon_view.dart';
import 'package:buddhist_sun/views/settings_page.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/buddhavassa_page.dart';
import 'package:buddhist_sun/views/meditation_timer_page.dart';
import 'package:buddhist_sun/views/compass_page.dart';
import 'package:buddhist_sun/views/sun_shadow_view.dart';
import 'package:buddhist_sun/views/death_contemplation_page.dart';
import 'package:buddhist_sun/widgets/app_help_dialog.dart';
//import 'package:buddhist_sun/views/dummy_page.dart';

import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'dart:io' show Platform;
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';

// #docregion LocalizationDelegatesImport
//import 'package:flutter_localizations/flutter_localizations.dart';

// #enddocregion LocalizationDelegatesImport
// #docregion AppLocalizationsImport
import 'package:buddhist_sun/l10n/app_localizations.dart';
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

  static String _tabIndexToName(int index) {
    switch (index) {
      case 0:
        return 'noon';
      case 1:
        return 'moon';
      case 2:
        return 'gps';
      default:
        return 'noon';
    }
  }

  int _calculateInitialIndex() {
    if (Prefs.lat == 1.1) {
      return 2; // Unconfigured GPS, prioritize GPS setup
    }
    final saved = Prefs.lastScreen;
    switch (saved) {
      case 'noon':
      case 'dawn': // if migrating from old 'dawn' or 'timer' key, go to noon
      case 'timer':
        return 0;
      case 'moon':
        return 1;
      case 'gps':
        return 2;
      default:
        return 0;
    }
  }

  Future<T?> _navigateAndRemember<T>(Widget page, String screenKey) async {
    Prefs.lastScreen = screenKey;
    final result = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    if (mounted) {
      Prefs.lastScreen = _tabIndexToName(_currentIndex);
    }
    return result;
  }

  void _restoreSubPageIfNeeded() {
    if (Prefs.lat == 1.1) return;

    final saved = Prefs.lastScreen;
    Widget? subPage;
    switch (saved) {
      case 'meditation_timer':
        subPage = const MeditationTimerPage();
        break;
      case 'compass':
        subPage = const CompassPage();
        break;
      case 'sun_shadow':
        subPage = const SunShadowPage();
        break;
      case 'buddhavassa':
        subPage = const BuddhavassaPage();
        break;
      case 'settings':
        subPage = SettingsPage();
        break;
      case 'death_contemplation':
        if (showDeath) {
          subPage = const DeathContemplationPage();
        }
        break;
    }

    if (subPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateAndRemember(subPage!, saved);
        }
      });
    }
  }

  void goToHome() {
    _currentIndex = 0;
    Prefs.lastScreen = 'noon';
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
  }

  late Home _page1;
  late MoonPage _page2;
  late GPSLocation _page3;
  //late DummyPage _dummyPage;

  late int _currentIndex;
  //Widget _currentPage = Home();
  bool _initializedAutoStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedAutoStart) {
      _initializedAutoStart = true;
      _autoStartBackgroundTimer();
    }
  }

  Future<void> _autoStartBackgroundTimer() async {
    // 1. FORCE SILENCE FIRST! Ignore whatever was saved from the last session.
    Prefs.speakIsOn = false;
    Prefs.instance.setBool(SPEAKISON, false);

    // 2. NOW it is safe to boot up the service
    final service = SolarTimerService();
    service.delegate?.setSpeakIsOn(false); // Make sure the delegate knows too
    service.doTimerStuff();

    final isDawn = service.isDawnMode;
    final autoStartEnabled =
        isDawn ? Prefs.autoStartDawnTimer : Prefs.autoStartNoonTimer;

    final target = service.countdownTarget;
    final now = DateTime.now();
    final difference = target.difference(now);
    final minutes = difference.inMinutes;

    if (autoStartEnabled && !difference.isNegative && minutes <= 120) {
      // Instead of starting immediately, wait for the screen to finish drawing,
      // then show the permission dialog.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAutoStartDialog(target);
      });
    } else {
      Prefs.speakIsOn = false;
      Prefs.instance.setBool(SPEAKISON, false);
      service.delegate?.setSpeakIsOn(false);
      await BackgroundTimePlayer.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _calculateInitialIndex();
    _pageController = PageController(initialPage: _currentIndex);

    // these toggles always get set to false unless auto-start is true
    Prefs.backgroundOn = false;
    //    _dummyPage = DummyPage();
    _page1 = Home();
    _page2 = MoonPage();
    _page3 = GPSLocation();
//    _page4 = ((isDesktop) ? DummyPage() : GPSLocation(goToHome: goToHome));

    _restoreSubPageIfNeeded();
  }

  @override
  void dispose() {
    // cleanup the switches to always false
    // this does not get called.. but it is here anyway.
    // no dispose on exit is called. :)
    Prefs.backgroundOn = false;
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
    Prefs.lastScreen = _tabIndexToName(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.buddhistSun),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.help,
            onPressed: () {
              if (_currentIndex == 1) {
                showMoonHelpDialog(context);
              } else if (_currentIndex == 2) {
                showGpsHelpDialog(context);
              } else {
                showHomeHelpDialog(context);
              }
            },
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            onPressed: () {
              _navigateAndRemember(SettingsPage(), 'settings');
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
              leading: const Icon(Icons.self_improvement),
              title: ColoredText(AppLocalizations.of(context)!.meditationTimer),
              onTap: () {
                Navigator.pop(context); // close the drawer
                _navigateAndRemember(
                  const MeditationTimerPage(),
                  'meditation_timer',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore),
              title: ColoredText(AppLocalizations.of(context)!.compass),
              onTap: () {
                Navigator.pop(context); // close the drawer
                _navigateAndRemember(
                  const CompassPage(),
                  'compass',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: ColoredText(AppLocalizations.of(context)!.sunAndShadow),
              onTap: () {
                Navigator.pop(context); // close the drawer
                _navigateAndRemember(
                  const SunShadowPage(),
                  'sun_shadow',
                );
              },
            ),
            getDeathContemplationMenuItem(),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: ColoredText(AppLocalizations.of(context)!.beTitle),
              onTap: () {
                Navigator.pop(context); // close the drawer
                _navigateAndRemember(
                  const BuddhavassaPage(),
                  'buddhavassa',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.verified),
              title: ColoredText(AppLocalizations.of(context)!.verify,
                  style: TextStyle()),
              onTap: () async {
                final int safetyOffset = getSafetyOffset();
                if (safetyOffset > 0) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: ColoredText(
                            AppLocalizations.of(context)!.safetyWarning),
                        content: ColoredText(
                          AppLocalizations.of(context)!
                              .safetyWarningMessage(safetyOffset.toString()),
                        ),
                        actions: [
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.cancel),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.proceed),
                            onPressed: () {
                              Navigator.pop(context);
                              _launchVerifyUrl();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _launchVerifyUrl();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: ColoredText(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context); // close the drawer
                _navigateAndRemember(
                  SettingsPage(),
                  'settings',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: ColoredText(AppLocalizations.of(context)!.help,
                  style: const TextStyle()),
              onTap: () {
                Navigator.pop(context);
                showHomeHelpDialog(context);
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
              leading: const Icon(Icons.star), // Added Icon
              title: ColoredText(AppLocalizations.of(context)!.rateThisApp),
              focusColor: Theme.of(context).focusColor,
              hoverColor: Theme.of(context).hoverColor,
              onTap: () {
                final InAppReview inAppReview = InAppReview.instance;
                inAppReview.openStoreListing(appStoreId: '1585091207');
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps),
              title: ColoredText(AppLocalizations.of(context)!.otherApps),
              focusColor: Theme.of(context).focusColor,
              hoverColor: Theme.of(context).hoverColor,
              onTap: () async {
                Navigator.pop(context); // close the drawer
                final Uri url =
                    Uri.parse('https://americanmonk.org/categories/software/');
                if (!await launchUrl(url,
                    mode: LaunchMode.externalApplication)) {
                  throw Exception('Could not launch $url');
                }
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
            Prefs.lastScreen = _tabIndexToName(index);
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
                  AppLocalizations.of(context)!.sun,
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
            Prefs.lastScreen = _tabIndexToName(index);
          },
          children: <Widget>[
            Home(isActive: _currentIndex == 0),
            _page2,
            GPSLocation(isActive: _currentIndex == 2),
          ],
        ),
      ),
    );
  }

  Future<void> _launchVerifyUrl() async {
    // 1. Get the local time and the offset
    final DateTime now = DateTime.now();
    final double tzOffset = now.timeZoneOffset.inMinutes / 60.0;

    // 2. Format strings using 'now' (Local Time), NOT 'utcNow'
    final String dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // 3. Build the URI with the mobile endpoint
    final Uri url = Uri.https(
      'www.kso.ac.at',
      '/beobachtungen/ephem_mob.php',
      {
        'tz': tzOffset.toString(),
        'date': dateStr,
        'time': timeStr,
        'lat': Prefs.lat.toString(),
        'lon': Prefs.lng.toString(),
      },
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget getDeathContemplationMenuItem() {
    if (!showDeath) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.hourglass_bottom),
      title: ColoredText(AppLocalizations.of(context)!.deathContemplation),
      onTap: () {
        Navigator.pop(context); // close the drawer
        _navigateAndRemember(
          const DeathContemplationPage(),
          'death_contemplation',
        );
      },
    );
  }

  void showHelpDialog(BuildContext context) {
    showHomeHelpDialog(context);
  }

  void _showAutoStartDialog(DateTime target) {
    showDialog(
      context: context,
      barrierDismissible: false, // Forces them to make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          title: ColoredText(AppLocalizations.of(context)!.buddhistSun),
          content: ColoredText(
              "Would you like to start the background countdown timer now?"), // Translate this string later!
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.pop(context);
                // If they cancel, make sure everything stays off
                Prefs.speakIsOn = false;
                Prefs.instance.setBool(SPEAKISON, false);
                SolarTimerService().delegate?.setSpeakIsOn(false);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.proceed),
              onPressed: () async {
                // 1. Grab the translations BEFORE destroying the dialog context
                final String titleText =
                    AppLocalizations.of(context)!.buddhistSunCountdown;
                final String artistText =
                    AppLocalizations.of(context)!.buddhistSun;
                final String albumText = AppLocalizations.of(context)!.timer;

                // 2. NOW it is safe to close the dialog
                Navigator.pop(context);

                // 3. Update the state
                Prefs.speakIsOn = true;
                Prefs.instance.setBool(SPEAKISON, true);
                SolarTimerService().delegate?.setSpeakIsOn(true);

                // 4. Start the player using the saved text variables
                await BackgroundTimePlayer.startForTarget(
                  target: target,
                  title: titleText,
                  artist: artistText,
                  album: albumText,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
