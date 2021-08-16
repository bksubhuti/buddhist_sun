import 'package:buddhist_sun/views/choose_location.dart';
import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/gps_location.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';

class HomePageContainer extends StatefulWidget {
  const HomePageContainer({Key? key}) : super(key: key);

  @override
  Home_PageContainerState createState() => Home_PageContainerState();
}

class Home_PageContainerState extends State<HomePageContainer> {
  late List<Widget> _pages;
  late PageController _pageController;

  final String page1 = "Home";
  final String page2 = "Cities";
  final String page3 = "GPS";
  final String page4 = "GMT";
  final String title = "Buddhist Sun";

  void goToHome() {
    _currentIndex = 0;
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
  }

  final _page1 = Home();
  late ChooseLocation _page2;
  late GPSLocation _page3;
  late ChooseOffset _page4;

  int _currentIndex = 0;
  Widget _currentPage = Home();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // _page1 = Home();
    _page2 = ChooseLocation(goToHome: goToHome);
    _page3 = GPSLocation(goToHome: goToHome);
    _page4 = ChooseOffset(goToHome: goToHome);
    _page3 = GPSLocation(goToHome: goToHome);

    _pages = [_page1, _page2, _page3, _page4];

    _currentIndex = 0;
    _currentPage = _page1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
      _currentPage = _pages[index];
      // need to update the state._page1.;
    });
  }

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);
    Color? bgColor = Colors.indigo[700];

    if (_currentIndex != 0) {
      bgColor = Colors.grey[200];
    }

    return Scaffold(
      appBar: AppBar(title: Text("Buddhist Sun")),
      backgroundColor: bgColor,
      bottomNavigationBar: BottomNavyBar(
          //iconSize: 4, // ADD THIS
          //unselectedFontSize: 10, // ADD THIS
          //style: TabStyle.react,
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
            BottomNavyBarItem(
                title: Text(page2), icon: Icon(Icons.location_city)),
            BottomNavyBarItem(
                title: Text(page3), icon: Icon(Icons.gps_fixed_rounded)),
            BottomNavyBarItem(title: Text(page4), icon: Icon(Icons.add)),
          ]),
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: <Widget>[
            _page1,
            _page2,
            _page3,
            _page4,
          ],
        ),
      ),
    );
  }
}
