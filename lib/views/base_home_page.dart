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
  Color bgColor = Color(255);

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
      appBar: AppBar(title: Text("Buddhist Sun")),
      backgroundColor: bgColor,
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
}
