import 'package:buddhist_sun/views/choose_location.dart';
import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/gps_location.dart';

class HomePageContainer extends StatefulWidget {
  const HomePageContainer({Key? key}) : super(key: key);

  @override
  Home_PageContainerState createState() => Home_PageContainerState();
}

class Home_PageContainerState extends State<HomePageContainer> {
  late List<Widget> _pages;

  final String page1 = "Home";
  final String page2 = "Cities";
  final String page3 = "GPS";
  final String page4 = "GMT";
  final String title = "Buddhist Sun";

  final _page1 = Home();
  final _page2 = ChooseLocation();
  final _page3 = GPSLocation();
  final _page4 = ChooseOffset();

  int _currentIndex = 0;
  Widget _currentPage = Home();

  @override
  void initState() {
    super.initState();

    // _page1 = Home();
    //_page2 = ChooseLocation();
    //_page3 = GPSLocation();
    //_page4 = ChooseOffset();

    _pages = [_page1, _page2, _page3, _page4];

    _currentIndex = 0;
    _currentPage = _page1;
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
      bottomNavigationBar: BottomNavigationBar(
          //iconSize: 4, // ADD THIS
          //unselectedFontSize: 10, // ADD THIS
          //style: TabStyle.react,
          backgroundColor: Colors.blue[200],
          onTap: (index) => changeTab(index),
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(label: page1, icon: Icon(Icons.home)),
            BottomNavigationBarItem(
                label: page2, icon: Icon(Icons.location_city)),
            BottomNavigationBarItem(
                label: page3, icon: Icon(Icons.gps_fixed_rounded)),
            BottomNavigationBarItem(label: page4, icon: Icon(Icons.add)),
          ]),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(child: _currentPage),
      ),
    );
  }
}
