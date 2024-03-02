import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'pass.dart';

void initializeFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw',
          appId: '1:948180596215:android:cd402baeb7d8ec0bbbaaf2',
          messagingSenderId: '948180596215',
          projectId: 'henhung01')
  ) : await Firebase.initializeApp();
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePage createState() => _MyHomePage();
}
class _MyHomePage extends State<MyHomePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  late DatabaseReference _ledReference;
  bool door = false;

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Không đóng được bằng cách nhấn bên ngoài hộp thoại
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bạn có chắc chắn muốn mở cửa không?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Không'),
              onPressed: () {
                // Đóng hộp thoại nếu người dùng chọn "Không"
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Có'),
              onPressed: () {
                // Thực hiện hành động mở cửa nếu người dùng chọn "Có"
                _openDoor();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Trạng thái cửa'),
                      content: Text('Đã mở!'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: Text('Đóng'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
  void _openDoor() {
    _database.update({'door': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home',
        style:  TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 30,
          )
        ),
        backgroundColor: Colors.blueAccent,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(height: 100),
          Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPass()),
                    );
                    // Navigator.of(context).popAndPushNamed("/pass");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.key,
                        color: Colors.lightBlue,
                        size: 50,
                      ),
                      Text('Đổi mật khẩu',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  )
              ),
              ElevatedButton(
                  onPressed: () {
                    _showConfirmationDialog(context);

                    // Navigator.of(context).popAndPushNamed("/pass");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.key,
                        color: Colors.lightBlue,
                        size: 50,
                      ),
                      Text('Mở cửa',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  )
              ),
            ],
          )
        ],
      ),
    );
  }
}