import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home/Device/device.dart'; // Import your Device class here

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> addDevice(Device device) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final _uid = user!.uid;
      await _firestore.collection('users').doc(_uid).collection('devices').doc(device.name).set({
        'name': device.name,
        'id': device.id,
        'type': device.type,
        'espid':device.espid
        // Add other fields as needed
      });
      await _database.reference().child('users').child(_uid).child(device.espid).child(device.id).set({'status': device.status});
      print('Device added successfully!');
    } catch (e) {
      print('Error adding device: $e');
    }
  }

  Future<void> addDoor(Door door) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final _uid = user!.uid;
      await _firestore.collection('users').doc(_uid).collection('devices').doc(door.id).set({
        'name': door.name,
        'password':door.password,
        'id':door.id,
        'espid': door.espid,
        'type': door.type
        // Add other fields as needed
      });
      await _database.reference().child('users').child(_uid).child(door.id).set({
        'status': door.status,
        'password': door.password
      });
      print('Device added successfully!');
    } catch (e) {
      print('Error adding device: $e');
    }
  }
}
