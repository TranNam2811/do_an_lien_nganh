import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/Device/device.dart';
import 'package:smart_home/widgets/setting_device.dart';

class DeviceListWidget extends StatefulWidget {
  DeviceListWidget();
  @override
  _DeviceListWidget createState() => _DeviceListWidget();
}

class _DeviceListWidget extends State<DeviceListWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  late StreamController<List<Device>> _deviceStreamController;
  late StreamSubscription<QuerySnapshot> _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _deviceStreamController = StreamController<List<Device>>();
    _listenToDeviceChanges();
  }

  @override
  void dispose() {
    _deviceStreamController.close();
    _deviceSubscription.cancel();
    super.dispose();
  }

  void _listenToDeviceChanges() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final _uid = user.uid;
      _deviceSubscription = _firestore
          .collection('users')
          .doc(_uid)
          .collection('devices')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        _fetchDevices();
      });
    }
  }

  Future<List<Map<String, dynamic>>> getDeviceNames() async {
    List<Map<String, dynamic>> devices = [];
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final _uid = user!.uid;
      QuerySnapshot querySnapshot =
      await _firestore.collection('users').doc(_uid).collection('devices').get();
      for (var doc in querySnapshot.docs) {
        devices.add({
          'id': doc['id'],
          'name': doc['name'],
          'type': doc['type']
        });
      }
    } catch (e) {
      print('Error fetching devices: $e');
    }
    return devices;
  }

  Future<bool?> getDeviceStatus(String uid, String deviceId) async {
    try {
      DatabaseReference ref =
      FirebaseDatabase.instance.reference().child('users').child(uid).child(deviceId);
      DatabaseEvent event = await ref.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        return data['status'] as bool?;
      }
    } catch (e) {
      print('Error fetching device status: $e');
    }
    return null;
  }

  void _fetchDevices() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final _uid = user!.uid;

      List<Map<String, dynamic>> devices = await getDeviceNames();

      List<Device> deviceList = [];
      for (var device in devices) {
        bool? status = await getDeviceStatus(_uid, device['id']);
        // Create Device instance with StreamController
        Device newDevice = Device(
          id: device['id'],
          name: device['name'],
          status: status ?? false,
          type: device['type'],
        );
        // Listen to status changes
        _database
            .reference()
            .child('users')
            .child(_uid)
            .child(device['id'])
            .child('status')
            .onValue
            .listen((event) {
          DataSnapshot snapshot = event.snapshot;
          bool? newStatus = snapshot.value as bool?;
          if (newStatus != null) {
            newDevice.setStatus(newStatus); // Update device status
            _deviceStreamController.add(deviceList); // Update stream with new device list
          }
        });
        deviceList.add(newDevice);
      }

      _deviceStreamController.add(deviceList); // Initial device list
    } catch (e) {
      print('Error fetching combined devices: $e');
    }
  }
  final Map<String, IconData> dIcons = {
    'Door': Icons.door_back_door_outlined,
    'Light': Icons.lightbulb_outline,
    'Quạt': Icons.wind_power,
    'Điều hòa': Icons.ac_unit_outlined,
    'Nóng lạnh': Icons.thermostat,
  };
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Device>>(
      stream: _deviceStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No devices found.'));
        } else {
          List<Device> devices = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Handle device tap, e.g., navigate to device details
                },
                child: Card(
                  color: devices[index].status ? Colors.blueGrey[100] : Colors.red[100],
                  elevation: 8,
                  child: Container(
                    padding: EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Icon(
                              dIcons[devices[index].type]
                          ),
                        ),
                        Text(
                          devices[index].name,
                          style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DeviceStatusWidget(device: devices[index]),
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SettingDevice(device: devices[index]),
                                  ),
                                );
                              },
                              icon: Icon(Icons.settings, size: 35),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class DeviceStatusWidget extends StatelessWidget {
  final Device device;

  DeviceStatusWidget({required this.device});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: device.statusNotifier,
      builder: (context, value, child) {
        return ToggleButtons(
          borderColor: Colors.black26,
          selectedBorderColor: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          constraints: BoxConstraints(
            minHeight: 40,
            minWidth: 50,
          ),
          children: [
            Text(
              'Mở',
              style: TextStyle(color: value ? Colors.blue : Colors.grey,fontWeight: FontWeight.bold),
            ),
            Text(
              'Đóng',
              style: TextStyle(color: value ? Colors.grey : Colors.red,fontWeight: FontWeight.bold),
            ),
          ],
          isSelected: [value, !value],
          onPressed: (int index) {
            bool newStatus = index == 0;
            device.setStatus(newStatus);
            _updateDeviceStatus(device, newStatus);
          },
        );
      },
    );
  }

  void _updateDeviceStatus(Device device, bool newStatus) {
    final User? user = FirebaseAuth.instance.currentUser;
    final _uid = user!.uid;
    // Implement logic to update status in Firebase Realtime Database
    if (device.type != "Door" || newStatus) {
      FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(_uid)
          .child(device.id)
          .child('status')
          .set(newStatus);
    }
  }
}
