import 'dart:async';
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

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePage createState() => _MyHomePage();
}
class _MyHomePage extends State<MyHomePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  static late StreamController<bool> _doorStreamController = StreamController<bool>();
  static late StreamController<bool> _lr1StreamController = StreamController<bool>();
  static late StreamController<bool> _lr2StreamController = StreamController<bool>();
  static late StreamController<bool> _lr3StreamController = StreamController<bool>();
  static late StreamController<bool> _nlStreamController = StreamController<bool>();
    static late StreamController<List<String>> _openStreamController = StreamController<List<String>>();
   static Stream<List<String>> get openStream => _openStreamController.stream;

   static late StreamController<List<String>> _closeStreamController = StreamController<List<String>>();
   static Stream<List<String>> get closeStream => _closeStreamController.stream;
  static  Stream<bool>? get doorStream => _doorStreamController.stream;
  static  Stream<bool>? get lr1Stream => _lr1StreamController.stream;
    static Stream<bool>? get lr2Stream => _lr2StreamController.stream;
  static Stream<bool>? get lr3Stream => _lr3StreamController.stream;
    static Stream<bool>? get nlStream => _nlStreamController.stream;
  late DatabaseReference _ledReference;
  late DatabaseReference _passReference;
  late DatabaseReference _doorReference;
  late DatabaseReference _lr1Reference;
  late DatabaseReference _lr2Reference;
  late DatabaseReference _lr3Reference;
  late DatabaseReference _nlReference;
  late DatabaseReference _openReference;
  late DatabaseReference _closeReference;

  bool doorValue = false;
  bool lr1 = false;
  bool lr2 = false;
  bool lr3= false;
  bool nl = false;
  int _ledValue = 0;
  String _passValue = '';
  List<String> historyClose = [];
  List<String> historyOpen = [];
  DateTime? tO;
  DateTime? tC;
  int dem1=0;
  int dem2=0;
  void listenToPassReference() {
    _passReference.onValue.listen((DatabaseEvent event) {
      // Truy cập snapshot từ event
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        _passValue = snapshot.value.toString();
      } else {
        print('Không tìm thấy giá trị password trong cơ sở dữ liệu.');
      }
    });
  }
  void _addTimeToCloseHistory(String time) {
    DatabaseReference closeRef = _database.child('close');
    closeRef.push().set(time);
  }
  void _addTimeOpenToHistory(String time) {
    DatabaseReference openRef = _database.child('open');
    openRef.push().set(time);
  }



  @override
  void initState() {
    super.initState();
    _ledReference = FirebaseDatabase.instance.reference().child('led');
    _doorReference = FirebaseDatabase.instance.reference().child('door');
    _passReference = FirebaseDatabase.instance.reference().child('password');
    _lr1Reference = FirebaseDatabase.instance.reference().child('R1');
    _lr2Reference = FirebaseDatabase.instance.reference().child('R2');
    _lr3Reference = FirebaseDatabase.instance.reference().child('R3');
    _nlReference = FirebaseDatabase.instance.reference().child('NongLanh');
    _openReference = FirebaseDatabase.instance.reference().child('open');
    _closeReference = FirebaseDatabase.instance.reference().child('close');

    _openStreamController??= StreamController<List<String>>.broadcast();
    _closeStreamController??= StreamController<List<String>>.broadcast();
    _closeStreamController??= StreamController<List<String>>.broadcast();
    _lr1StreamController??= StreamController<bool>.broadcast();
    _doorStreamController??= StreamController<bool>.broadcast();
    _lr2StreamController??= StreamController<bool>.broadcast();
    _lr3StreamController??= StreamController<bool>.broadcast();
    _nlStreamController??= StreamController<bool>.broadcast();


    // Lắng nghe sự thay đổi của door
    _doorReference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      doorValue = snapshots.value as bool;
      bool newdoorValue = doorValue;
      if (event.snapshot.value != null) {
        doorValue = event.snapshot.value as bool;
        // Đưa giá trị mới vào stream
        _doorStreamController.add(doorValue);

        if (doorValue) {
          DateTime currentTimeOpen = DateTime.now();
          int year = currentTimeOpen.year;
          int month = currentTimeOpen.month;
          int day = currentTimeOpen.day;
          int hour = currentTimeOpen.hour;
          int minute = currentTimeOpen.minute;
          int second = currentTimeOpen.second;
          _addTimeOpenToHistory("$hour:$minute:$second-$day/$month/$year");
        }

        else {
          DateTime currentTimeClose = DateTime.now();
          int year = currentTimeClose.year;
          int month = currentTimeClose.month;
          int day = currentTimeClose.day;
          int hour = currentTimeClose.hour;
          int minute = currentTimeClose.minute;
          int second = currentTimeClose.second;
          _addTimeToCloseHistory("$hour:$minute:$second-$day/$month/$year");
        }
      } else {
        print('Không tìm thấy giá trị door trong cơ sở dữ liệu.');
      }
    });

    //pass
    _passReference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      _passValue = snapshots.value.toString();
      if (event.snapshot.value != null) {
        _passValue = event.snapshot.value.toString();
      } else {
        print('Không tìm thấy giá trị password trong cơ sở dữ liệu.');
      }
    });
    //lr1
    _lr1Reference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      lr1 = snapshots.value as bool;
      if (event.snapshot.value != null) {
        lr1 = event.snapshot.value as bool;
        _lr1StreamController.add(lr1);
      } else {
        print('Không tìm thấy giá trị lr1 trong cơ sở dữ liệu.');
      }
    });
    //pass
    _lr2Reference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      lr2 = snapshots.value as bool;
      if (event.snapshot.value != null) {
        lr2 = event.snapshot.value as bool;
        _lr2StreamController.add(lr2);
      } else {
        print('Không tìm thấy giá trị lr2 trong cơ sở dữ liệu.');
      }
    });
    //pass
    _lr3Reference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      lr3 = snapshots.value as bool;
      if (event.snapshot.value != null) {
        lr3 = event.snapshot.value as bool;
        _lr3StreamController.add(lr3);
      } else {
        print('Không tìm thấy giá trị lr3 trong cơ sở dữ liệu.');
      }
    });
    //pass
    _nlReference.onValue.listen((DatabaseEvent event) {
      DataSnapshot snapshots = event.snapshot;
      nl = snapshots.value as bool;
      if (event.snapshot.value != null) {
        nl = event.snapshot.value as bool;
      } else {
        print('Không tìm thấy giá trị nl trong cơ sở dữ liệu.');
      }
    });
    //history open
    _openReference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        if (values != null) {
          List<String> newHistoryOpen = [];
          values.forEach((key, value) {
            if (value is String) {
              String time = value;
               newHistoryOpen.add(time);
            } else {
              print('Giá trị không phải là kiểu String ${value}');
            }
          });
          historyOpen.clear();
          // Thêm các phần tử mới vào danh sách
          historyOpen.addAll(newHistoryOpen);

          // Cập nhật Stream để thông báo rằng có dữ liệu mới
           _openStreamController.add(historyOpen);
          // _historyStreamController.add(historyOpen);
          setState(() {}); // Cập nhật UI khi dữ liệu đã được tải
        } else {
          print('Giá trị snapshot không phải là một Map<dynamic, dynamic>');
        }
      } else {
        print('Giá trị snapshot là null');
      }
    });
    //history close
    _closeReference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

        if (values != null) {
          List<String> newHistoryClose = [];
          values.forEach((key, value) {
            if (value is String) {
              String time = value;
               newHistoryClose.add(time);
            } else {
              print('Giá trị không phải là kiểu String ${value}');
            }
          });;
          historyClose.clear();
          // Thêm các phần tử mới vào danh sách
          historyClose.addAll(newHistoryClose);

          // Cập nhật Stream để thông báo rằng có dữ liệu mới
           _closeStreamController.add(historyClose);
          setState(() {}); // Cập nhật UI khi dữ liệu đã được tải
        } else {
          print('Giá trị snapshot không phải là một Map<dynamic, dynamic>');
        }
      } else {
        print('Giá trị snapshot là null');
      }
    });
  }

  @override
  void dispose() {
    // _openStreamController.close();
    // _closeStreamController.close();
    _lr1StreamController.close();
    _doorStreamController.close();
    _lr2StreamController.close();
    _lr3StreamController.close();
    _nlStreamController.close();
    super.dispose();
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
    if (passnewdController.text.length != 8 || containsNonNumericCharacter(passnewdController.text)) return false;

    if (_passValue != passoldController.text) return false;
    if (passnewd1Controller.text != passnewdController.text) return false;

    return true;
  }

  @override
  void openshowdialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Đổi mật khẩu'),
            content: Container(
              height: 300,
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

                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if(checkPass()) {
                        String newPassValue = passnewd1Controller.text;
                        _passReference.set(newPassValue);
                        _ledReference.set(1);
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
    );
  }
  void _openDoor() {
    _database.update({'door': true});
  }
  @override
  Widget timeDoorOpen(BuildContext context) {
    if (historyOpen.isEmpty) {
      return Text('Không có dữ liệu');
    } else {
      List<Widget> widgetList = historyClose.map((time) {
        return ListTile(
          title: Text('Thời gian đóng: ${time}'),
        );
      }).toList();

      return SingleChildScrollView(
        child: Column(
          children: widgetList,
        ),
      );
    }
  }
  @override
  Widget timeDoorClose(BuildContext context) {
    if (historyClose.isEmpty) {
      return Text('Không có dữ liệu');
    } else {
      List<Widget> widgetList = historyClose.map((time) {
        return ListTile(
          title: Text('Thời gian đóng: ${time}'),
        );
      }).toList();

      return SingleChildScrollView(
        child: Column(
          children: widgetList,
        ),
      );
    }
  }
  void timeD(BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Lịch sử đóng mở cửa'),
            content: Container(
              height: 500,
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: Column(
                  children: [
                    TextButton(onPressed: (){
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Lịch sử mở cửa'),
                              content: Container(
                                height: 500,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      timeDoorOpen(context)
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {

                                    Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                                  },
                                  child: Text('Đóng'),
                                ),
                              ],
                            );
                          }
                      );

                    },
                        child: Text('Lịch sử mở cửa') ),
                    TextButton(onPressed: (){
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Lịch sử đóng cửa'),
                              content: Container(
                                height: 500,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      timeDoorClose(context)
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {

                                    Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                                  },
                                  child: Text('Đóng'),
                                ),
                              ],
                            );
                          }
                      );

                    }, child: Text('Lịch sử đóng cửa')),

                    // Add other functions if needed
                    // timeDoorClose(context),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {

                  Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                },
                child: Text('Đóng'),
              ),
            ],
          );
        }
    );
  }

  void _doorManager (BuildContext context) {
    ValueNotifier<bool> selectedDoorStatus = ValueNotifier<bool>(doorValue);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Quản lý cửa'),
            content: Container(
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trạng thái cửa'),
                      ValueListenableBuilder<bool>(
                        valueListenable: selectedDoorStatus,
                        builder: (context, value, child) {
                          return ToggleButtons(
                            children: [
                              Text(
                                'Mở',
                                style: TextStyle(color: value ? Colors.blue : Colors.grey),
                              ),
                              Text(
                                'Đóng',
                                style: TextStyle(color: value ? Colors.grey : Colors.red),
                              ),
                            ],
                            isSelected: [value, !value],
                            onPressed: (int index) {
                              selectedDoorStatus.value = index == 0;
                            },
                          );
                        },
                      )

                    ],
                  ),
                  // Text('${historyOpen.toString()} + ${historyOpen.toString()}'),
                  TextButton(
                      onPressed: () {
                        openshowdialog(context);
                      },
                      child: Text('Đổi mật khẩu')
                  ),
                  TextButton(
                      onPressed: () {
                        timeD(context);
                      },
                      child: Text('Lịch sử đóng mở cửa')
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _database.update({'door': selectedDoorStatus.value});
                  _doorStreamController.add(selectedDoorStatus.value);

                  Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                },
                child: Text('Xác nhận'),
              ),

            ],
          );
        }
    );
  }
  void ledManager(BuildContext context) {
    ValueNotifier<bool> selectedDoorStatus1 = ValueNotifier<bool>(lr1);
    ValueNotifier<bool> selectedDoorStatus2 = ValueNotifier<bool>(lr2);
    ValueNotifier<bool> selectedDoorStatus3 = ValueNotifier<bool>(lr3);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Trạng thái đèn'),
            content: Container(
              height: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đèn phòng 1'),
                      ValueListenableBuilder<bool>(
                        valueListenable: selectedDoorStatus1,
                        builder: (context, value, child) {
                          return ToggleButtons(
                            children: [
                              Text(
                                'Mở',
                                style: TextStyle(color: value ? Colors.blue : Colors.grey),
                              ),
                              Text(
                                'Đóng',
                                style: TextStyle(color: value ? Colors.grey : Colors.red),
                              ),
                            ],
                            isSelected: [value, !value],
                            onPressed: (int index) {
                              selectedDoorStatus1.value = index == 0;
                            },
                          );
                        },
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đèn phòng 2'),
                      ValueListenableBuilder<bool>(
                        valueListenable: selectedDoorStatus2,
                        builder: (context, value, child) {
                          return ToggleButtons(
                            children: [
                              Text(
                                'Mở',
                                style: TextStyle(color: value ? Colors.blue : Colors.grey),
                              ),
                              Text(
                                'Đóng',
                                style: TextStyle(color: value ? Colors.grey : Colors.red),
                              ),
                            ],
                            isSelected: [value, !value],
                            onPressed: (int index) {
                              selectedDoorStatus2.value = index == 0;
                            },
                          );
                        },
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đèn phòng 3'),
                      ValueListenableBuilder<bool>(
                        valueListenable: selectedDoorStatus3,
                        builder: (context, value, child) {
                          return ToggleButtons(
                            children: [
                              Text(
                                'Mở',
                                style: TextStyle(color: value ? Colors.blue : Colors.grey),
                              ),
                              Text(
                                'Đóng',
                                style: TextStyle(color: value ? Colors.grey : Colors.red),
                              ),
                            ],
                            isSelected: [value, !value],
                            onPressed: (int index) {
                              selectedDoorStatus3.value = index == 0;
                            },
                          );
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _database.update({'R1': selectedDoorStatus1.value});
                  _database.update({'R2': selectedDoorStatus2.value});
                  _database.update({'R3': selectedDoorStatus3.value});

                  Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                },
                child: Text('Xác nhận'),
              ),
            ],
          );
        }
    );
  }
  void nlManager(BuildContext context) {
    ValueNotifier<bool> selectedDoorStatus = ValueNotifier<bool>(nl);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Trạng thái nóng lạnh'),
            content: Container(
              height: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nóng Lạnh'),
                      ValueListenableBuilder<bool>(
                        valueListenable: selectedDoorStatus,
                        builder: (context, value, child) {
                          return ToggleButtons(
                            children: [
                              Text(
                                'Mở',
                                style: TextStyle(color: value ? Colors.blue : Colors.grey),
                              ),
                              Text(
                                'Đóng',
                                style: TextStyle(color: value ? Colors.grey : Colors.red),
                              ),
                            ],
                            isSelected: [value, !value],
                            onPressed: (int index) {
                              selectedDoorStatus.value = index == 0;
                            },
                          );
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _database.update({'NongLanh': selectedDoorStatus.value});

                  // _nlStreamController.add(selectedDoorStatus.value);
                  Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                },
                child: Text('Xác nhận'),
              ),
            ],
          );
        }
    );
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
                    _doorManager(context);
                    // Navigator.of(context).popAndPushNamed("/pass");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.door_sliding,
                        color: Colors.lightBlue,
                        size: 50,
                      ),
                      Text('Cửa',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  )
              ),
              ElevatedButton(
                  onPressed: () {
                    ledManager(context);

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
                      Text('Đèn',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  )
              ),
              ElevatedButton(
                  onPressed: () {
                    nlManager(context);

                    // Navigator.of(context).popAndPushNamed("/pass");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hot_tub,
                        color: Colors.lightBlue,
                        size: 50,
                      ),
                      Text('Nóng lạnh',
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