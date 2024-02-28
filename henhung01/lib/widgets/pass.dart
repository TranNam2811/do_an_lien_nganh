import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
class MyPass extends StatefulWidget {
  @override
  _MyPassState createState() => _MyPassState();
}

class _MyPassState extends State<MyPass> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  late DatabaseReference _passReference;
  late DatabaseReference _ledReference;
  int _ledValue = 0;
  String _passValue = '';

  @override
  void initState() {
    super.initState();
    _ledReference = FirebaseDatabase.instance.reference().child('led');
    _passReference = FirebaseDatabase.instance.reference().child('password');
    // Lắng nghe sự thay đổi của trường password
    _passReference.onValue.listen((DatabaseEvent event) {
      if(event.snapshot.value != null) {
        _passValue = event.snapshot.value.toString();
      } else {
        print('Không tìm thấy giá trị password trong cơ sở dữ liệu.');
      }
    });
  }

  final passoldController = TextEditingController();
  final passnewdController = TextEditingController();
  final passnewd1Controller = TextEditingController();

  bool containsNonNumericCharacter(String input) {
    // Sử dụng biểu thức chính quy để kiểm tra xem chuỗi có chứa ký tự khác số không
    RegExp regExp = RegExp(r'[^0-9]');
    return regExp.hasMatch(input);
  }
  bool checkPass() {
    if (passnewdController.text.length > 6 || containsNonNumericCharacter(passnewdController.text)) return false;

    if (_passValue != passoldController.text) return false;
    if (passnewd1Controller.text != passnewdController.text) return false;

    return true;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Pass',
            style:  TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 30,
            )
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(
              elevation: 5,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Mật khẩu cũ'),
                      controller: passoldController,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Mật khẩu mới'),
                      controller: passnewdController,
                      obscureText: true,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                      controller: passnewd1Controller,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            // Text(
            //
            //   'Trạng thái LED: $_passValue',
            //   style: TextStyle(fontSize: 20),
            // ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if(checkPass()) {
                  String newPassValue = passnewd1Controller.text;
                  _passReference.set(newPassValue);
                  // setState(() {
                  //   // _ledValue = newLedValue;
                  //   _passValue = newPassValue;
                  // });
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Đổi mật khẩu thành công'),
                        content: Text('Mật khẩu đã được cập nhập!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Đóng'),
                          ),
                        ],
                      );
                    },
                  );
                  passoldController.clear();
                  passnewdController.clear();
                  passnewd1Controller.clear();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Lỗi'),
                        content: Text('Mật khẩu cũ hoặc Mật khẩu mới không trùng khớp. Vui lòng thử lại'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Đóng'),
                          ),
                        ],
                      );
                    },
                  );

                  passoldController.clear();
                  passnewdController.clear();
                  passnewd1Controller.clear();
                }
              },
              child: Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}