import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/Device/device.dart';
import 'package:smart_home/Services/device_service.dart';
import '../widgets/home_navbar.dart';

class SelectDeviceTypePage extends StatelessWidget {
  final List<String> deviceTypes = [
    'Door',
    'Light',
    'Quạt',
    'Điều hòa',
    'Nóng lạnh',
  ];

  final Map<String, IconData> deviceIcons = {
    'Door': Icons.door_back_door_outlined,
    'Light': Icons.lightbulb_outline,
    'Quạt': Icons.wind_power,
    'Điều hòa': Icons.ac_unit_outlined,
    'Nóng lạnh': Icons.thermostat,
  };

  void _navigateToAddDevicePage(BuildContext context, String deviceType) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddDevicePage(deviceType: deviceType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm thiết bị',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: deviceTypes.length,
          itemBuilder: (context, index) {
            String deviceType = deviceTypes[index];
            return GestureDetector(
              onTap: () {
                _navigateToAddDevicePage(context, deviceType);
              },
              child: Card(
                color: Colors.white38,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      color: Colors.blueGrey,
                      deviceIcons[deviceType],
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      deviceType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddDevicePage extends StatefulWidget {
  final String deviceType;

  AddDevicePage({required this.deviceType});

  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController doorpasswordController = TextEditingController();
  TextEditingController emailpasswordController = TextEditingController();
  bool status = false;
  final DeviceService _deviceService = DeviceService();
  List<String> devices = [];
  String? selectedDevice;
  String? selectedPin;
  bool? isconnected = false;
  MDnsClient? _mdnsClient;

  @override
  void initState() {
    super.initState();
    if (widget.deviceType == 'Door') {
      _startMdnsSearch();
    }
  }

  void _startMdnsSearch() async {
    devices.clear();
    _mdnsClient = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
      return RawDatagramSocket.bind(host, port, reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl);
    });
    await _mdnsClient!.start();

    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_http._tcp'))) {
      final String fullDomain = ptr.domainName;
      // Tách phần tên thiết bị từ domainName
      String deviceName = fullDomain.split('._http._tcp.local')[0]; // Lấy phần trước '.local'
      print(deviceName);
      setState(() {
        devices.add(deviceName);
      });
    }
  }


  @override
  void dispose() {
    nameController.dispose();
    if (widget.deviceType == 'Door') {
      doorpasswordController.dispose();
    }
    _mdnsClient?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết lập ${widget.deviceType}',
          style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 28,
        ),
      ),
      backgroundColor: Colors.blueGrey,
        actions: [
          if(isconnected == true)
            TextButton(
              onPressed: () {
                _saveDevice();
              },
              child: Text('Thêm thiết bị',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Tên thiết bị'),
              ),
              SizedBox(height: 10.0),
              Column(
                children: [
                  SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: _startMdnsSearch,
                    child: Text('Tìm thiết bị'),
                  ),
                  SizedBox(height: 10.0),
                  Container(
                    height: 200, // Đặt chiều cao cho Container
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        String value = devices[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0), // Thêm padding cho Card
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đảm bảo nút kết nối được căn phải
                              children: [
                                Expanded(
                                  child: ListTile(
                                    title: Text(value),
                                  ),
                                ),
                                if (isconnected == null)
                                  CircularProgressIndicator()
                                else if(isconnected == false)
                                  TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        // isconnected = true;
                                        selectedDevice = value;
                                      });
                                      if(widget.deviceType == 'Door'){
                                        await _showEspDoorConnect(context);
                                      }else{
                                        await _showEspLedConnect(context);
                                      }

                                      },
                                    child: Text('Kết nối'),
                                  ),
                                if(isconnected == true && value == selectedDevice)
                                  Text('Connected')
                              ],
                            ),
                          ),
                        );},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              // if (widget.deviceType != 'Door')
              //   CheckboxListTile(
              //     title: Text('Trạng thái mặc định: Đóng'),
              //     value: status,
              //     onChanged: (bool? value) {
              //       setState(() {
              //         status = value ?? false;
              //       });
              //     },
              //   ),
              // if (widget.deviceType != 'Door')
              //   Center(
              //     child: ElevatedButton(
              //       onPressed: () {
              //         _saveDevice();
              //       },
              //       child: Text('Thêm thiết bị'),
              //     ),
              //   ),
              // SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }


  void _saveDevice() async {
    String name = nameController.text.trim();
    String? password = widget.deviceType == 'Door' ? doorpasswordController.text.trim() : null;

    if (name.isNotEmpty && (password != null ? password.isNotEmpty : true) && (widget.deviceType != 'Door' || selectedDevice != null)) {
      try {
        if (widget.deviceType == 'Door') {
          Door door = Door(name: name, status: status, password: password!, id: selectedDevice!);
          await _sendSaveInfoToESP32(selectedDevice!);
          await _deviceService.addDoor(door);
        } else {
          Device newDevice = Device(name: name,espid:selectedDevice!,id: name, status: status, type: widget.deviceType);
          await _sendSaveInfoToESP32(selectedDevice!);
          await _sendSetPinEspLed(selectedDevice!,selectedPin!);
          await _deviceService.addDevice(newDevice);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeNavBar()),
              (route) => false,
        );
      } catch (e) {
        print('Error saving device: $e');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Lỗi'),
              content: Text('Đã xảy ra lỗi khi lưu thiết bị. Vui lòng thử lại sau.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Đóng'),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Lỗi'),
            content: Text('Vui lòng điền đầy đủ thông tin thiết bị.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Đóng'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _sendUSERToESP32(String esp32Name, String user) async {
    final url = 'http://$esp32Name.local/set_user-email?user-email=$user';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('UID set successfully on ESP32');
      } else {
        print('Failed to set UID on ESP32');
      }
    } catch (e) {
      print('Error setting UID on ESP32: $e');
    }
  }

  Future<void> _sendPASSWORDToESP32(String esp32Name, String password) async {
    final url = 'http://$esp32Name.local/set_user-password?user-password=$password';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('UID set successfully on ESP32');
      } else {
        print('Failed to set UID on ESP32');
      }
    } catch (e) {
      print('Error setting UID on ESP32: $e');
    }
  }

  Future<void> _sendDoorPASSWORDToESP32(String esp32Name, String password) async {
    final url = 'http://$esp32Name.local/set_door-password?door-password=$password';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('UID set successfully on ESP32');
      } else {
        print('Failed to set UID on ESP32');
      }
    } catch (e) {
      print('Error setting UID on ESP32: $e');
    }
  }

  Future<void> _sendSaveInfoToESP32(String esp32Name) async {
    final url = 'http://$esp32Name.local/save-data?save=save';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('UID set successfully on ESP32');
      } else {
        print('Failed to set UID on ESP32');
      }
    } catch (e) {
      print('Error setting UID on ESP32: $e');
    }
  }

  Future<void> _checkESP32Response(String esp32Name, String uid) async {
    final url = 'http://$esp32Name.local/check_uid?uid=$uid'; // Đổi thành endpoint kiểm tra UID
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Nếu nhận được response 200 OK từ ESP32
        String responseBody = response.body;
        if (responseBody.toLowerCase().contains('ok')) {
          print('ESP32 đã nhận UID thành công');
          setState(() {
            isconnected = true; // Đã kết nối thành công
          });
        } else {
          print('ESP32 không nhận được UID');
          setState(() {
            isconnected = false; // Không kết nối thành công
          });
        }
      } else {
        print('Failed to check UID on ESP32');
        setState(() {
          isconnected = false; // Không kết nối thành công
        });
      }
    } catch (e) {
      print('Error checking UID on ESP32: $e');
      setState(() {
        isconnected = false; // Không kết nối thành công
      });
    }
  }
  Future<void> _showEspDoorConnect(BuildContext context) async {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút để đóng hộp thoại
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kết nối'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Email password',
                  ),
                  obscureText: true,
                ),
                TextField(
                  controller: doorpasswordController,
                  decoration: InputDecoration(labelText: 'Door Password'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Kết nối'),
              onPressed: () async {
                final passwordRegExp = RegExp(r'^\d{8}$');
                if (!passwordRegExp.hasMatch(doorpasswordController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password must be exactly 8 digits.')),
                  );
                  return;
                }
                String email = emailController.text.trim();
                String password = passwordController.text.trim();
                String doorpassword = doorpasswordController.text;
                Navigator.of(context).pop(); // Đóng hộp thoại
                User? user = await signInWithEmailAndPassword(email, password);
                if (user != null) {
                  setState(() {
                    isconnected = null; // Đánh dấu đang kiểm tra
                  });
                  await _sendUSERToESP32(selectedDevice!, email);
                  await _sendPASSWORDToESP32(selectedDevice!, password);
                  await _sendDoorPASSWORDToESP32(selectedDevice!, doorpassword);
                  await _checkESP32Response(selectedDevice!, user.uid);
                } else {
                  setState(() {
                    isconnected = false; // Không kết nối thành công
                  });
                  // Hiển thị thông báo lỗi
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Lỗi'),
                        content: Text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Đóng'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<List<String>> _getPinNotUsedEspLed(String esp32Name) async {
    final url = 'http://$esp32Name.local/get-pinNotUsed';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> pins = jsonResponse['pins'];
        return pins.map((pin) => pin.toString()).toList();
      } else {
        print('Failed to get pin not used, status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<void> _sendSetPinEspLed(String esp32Name, String pin) async {
    final url = 'http://$esp32Name.local/set-pin?pin=$pin';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('set pin successfully on ESP32');
      } else {
        print('Failed to set pin on ESP32');
      }
    } catch (e) {
      print('Error setting pin on ESP32: $e');
    }
  }

  Future<void> _showEspLedConnect(BuildContext context) async {
    List<String> pins = await _getPinNotUsedEspLed(selectedDevice!);
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Kết nối'),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: ListBody(
                    children: <Widget>[
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: pins.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              color: selectedPin == pins[index] ? Colors.blueGrey : Colors.white,
                              elevation: 5,
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                title: Text(pins[index]),
                                onTap: () {
                                  setState(() {
                                    selectedPin = pins[index];
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Kết nối'),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email và mật khẩu không được để trống'),
                        ),
                      );
                      return;
                    }

                    User? user = await signInWithEmailAndPassword(email, password);
                    if (selectedPin != null && selectedPin!.isNotEmpty && user != null) {
                      setState(() {
                        isconnected = null; // Đánh dấu đang kiểm tra
                      });
                      await _sendUSERToESP32(selectedDevice!, email);
                      await _sendPASSWORDToESP32(selectedDevice!, password);
                      await _checkESP32Response(selectedDevice!, user.uid);
                      Navigator.of(context).pop(); // Đóng hộp thoại
                    } else {
                      setState(() {
                        isconnected = false; // Không kết nối thành công
                      });
                      // Hiển thị thông báo lỗi
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Lỗi'),
                            content: Text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Đóng'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }



}