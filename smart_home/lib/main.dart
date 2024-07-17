import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/widgets/home_navbar.dart';
import 'package:smart_home/widgets/homepage.dart';
import 'package:smart_home/widgets/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(MyApp());
}

Future<void> initializeFirebase() async {
  Platform.isAndroid
      ? await Firebase.initializeApp(
      options: const FirebaseOptions(
          databaseURL: 'https://smart-home-87097-default-rtdb.asia-southeast1.firebasedatabase.app/',
          apiKey: 'AIzaSyAn9GxD1KR6PuzDwuOXuBa4YY035a6hfgY',
          appId: '1:640465356427:android:02023b151ef04ea9c7f68e',
          messagingSenderId: '640465356427',
          projectId: 'smart-home-87097'))
      : await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeNavBar(),
    );
  }
}




