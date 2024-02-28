import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:henhung01/widgets/homepage.dart';
import 'widgets/pass.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  // Platform.isAndroid ?  await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //       apiKey: 'AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw',
  //       appId: '1:948180596215:android:cd402baeb7d8ec0bbbaaf2',
  //       messagingSenderId: '948180596215',
  //       projectId: 'henhung01')
  // ) : await Firebase.initializeApp();
  runApp(MyApp());
}
Future<void> initializeFirebase() async {
  Platform.isAndroid
      ? await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw',
          appId: '1:948180596215:android:cd402baeb7d8ec0bbbaaf2',
          messagingSenderId: '948180596215',
          projectId: 'henhung01')
  ) : await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      // initialRoute: "/",
      // routes: {
      //   "/": (ctx) => MyHomePage(),
      //   "/pass": (ctx) => MyPass(),
      //  },
       home: MyHomePage(),
    );
  }
}


