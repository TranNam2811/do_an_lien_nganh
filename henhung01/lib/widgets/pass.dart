// import 'dart:io';
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// void initializeFirebase() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   Platform.isAndroid
//       ? await Firebase.initializeApp(
//       options: const FirebaseOptions(
//           apiKey: 'AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw',
//           appId: '1:948180596215:android:cd402baeb7d8ec0bbbaaf2',
//           messagingSenderId: '948180596215',
//           projectId: 'henhung01')
//   ) : await Firebase.initializeApp();
// }
// class MyPass extends StatefulWidget {
//   @override
//   _MyPassState createState() => _MyPassState();
// }
//
// class _MyPassState extends State<MyPass> {
//   final DatabaseReference _database = FirebaseDatabase.instance.reference();
//
//   late DatabaseReference _ledReference;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _ledReference = FirebaseDatabase.instance.reference().child('led');
//     _passReference = FirebaseDatabase.instance.reference().child('password');
//     // Lắng nghe sự thay đổi của trường password
//
//   }
//
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Material();
//   }
// }