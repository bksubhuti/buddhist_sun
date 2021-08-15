import 'package:buddhist_sun/views/choose_offset.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/views/home.dart';
import 'package:buddhist_sun/views/choose_location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:buddhist_sun/views/gps_location.dart';
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
      routes: {
//      '/': (context) => const Loading(),
        '/home': (context) => const Home(),
        '/location': (context) => ChooseLocation(),
        '/gps': (context) => GPSLocation(),
        '/offset': (context) => ChooseOffset(),
      },

      title: 'Flutter Demo',
      //debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}
