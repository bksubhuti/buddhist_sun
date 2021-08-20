import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:buddhist_sun/views/base_home_page.dart';
import 'dart:io' show Platform;

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /*routes: {
//      '/': (context) => const Loading(),
        '/home': (context) => const Home(),
        '/location': (context) => ChooseLocation(),
        '/gps': (context) => GPSLocation(),
        '/offset': (context) => ChooseOffset(),
      },*/

      title: 'Buddhist Sun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        primarySwatch: Colors.blue,
      ),
      home: HomePageContainer(),
    );
  }
}
