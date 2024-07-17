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
        title: Text('Thêm thiết bị'),
      ),
      body: ListView.builder(
        itemCount: deviceTypes.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(deviceTypes[index]),
              onTap: () {
                _navigateToAddDevicePage(context, deviceTypes[index]);
              },
            ),
          );
        },
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
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailpasswordController = TextEditingController();
  bool status = false;
  final DeviceService _deviceService = DeviceService();
  List<String> devices = [];
  String? selectedDevice;
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
      passwordController.dispose();
    }
    _mdnsClient?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết lập ${widget.deviceType}'),
        actions: [
          if(isconnected == true)
            TextButton(
              onPressed: () {
                _saveDevice();
              },
              child: Text('Thêm thiết bị'),
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
              if (widget.deviceType == 'Door')
                Column(
                  children: [
                    SizedBox(height: 10.0),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Door password'),
                    ),
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
                                        // final _uid = FirebaseAuth.instance.currentUser!.uid;
                                        // final _user = FirebaseAuth.instance.currentUser!.email;
                                        // final _password = emailpasswordController.text;
                                        // Gửi UID cho ESP32
                                        await _showLoginDialog(context);
                                        // await _sendUSERToESP32(value, _user!);
                                        // await _sendPASSWORDToESP32(value, _password);
                                        // await _checkESP32Response(value, _uid);
                                      },
                                      child: Text('Kết nối'),
                                    ),
                                  if(isconnected == true && value == selectedDevice)
                                    Text('Connected')
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 10.0),
              if (widget.deviceType != 'Door')
                CheckboxListTile(
                  title: Text('Trạng thái mặc định: Đóng'),
                  value: status,
                  onChanged: (bool? value) {
                    setState(() {
                      status = value ?? false;
                    });
                  },
                ),
              if (widget.deviceType != 'Door')
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveDevice();
                    },
                    child: Text('Thêm thiết bị'),
                  ),
                ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }


  void _saveDevice() async {
    String name = nameController.text.trim();
    String? password = widget.deviceType == 'Door' ? passwordController.text.trim() : null;

    if (name.isNotEmpty && (password != null ? password.isNotEmpty : true) && (widget.deviceType != 'Door' || selectedDevice != null)) {
      try {
        if (widget.deviceType == 'Door') {
          Door door = Door(name: name, status: status, password: password!, id: selectedDevice!);
          await _deviceService.addDoor(door);
        } else {
          Device newDevice = Device(name: name,id: name, status: status, type: widget.deviceType);
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
  Future<void> _showLoginDialog(BuildContext context) async {
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
                    labelText: 'Mật khẩu',
                  ),
                  obscureText: true,
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
                String email = emailController.text.trim();
                String password = passwordController.text.trim();
                Navigator.of(context).pop(); // Đóng hộp thoại
                User? user = await signInWithEmailAndPassword(email, password);
                if (user != null) {
                  setState(() {
                    isconnected = null; // Đánh dấu đang kiểm tra
                  });
                  await _sendUSERToESP32(selectedDevice!, email);
                  await _sendPASSWORDToESP32(selectedDevice!, password);
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
}