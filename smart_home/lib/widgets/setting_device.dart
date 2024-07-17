import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/Device/device.dart';

class SettingDevice extends StatefulWidget {
  Device device;
  SettingDevice({required this.device});

  @override
  State<SettingDevice> createState() => _SettingDeviceState();
}

class _SettingDeviceState extends State<SettingDevice> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Setting " + widget.device.type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename Device'),
              onTap: () {
                // Handle rename device
                _renameDevice(widget.device.id, widget.device.name);
              },
            ),
            if (widget.device.type.toLowerCase().contains('door'))
              ListTile(
                leading: Icon(Icons.history),
                title: Text('View Access History'),
                onTap: () {
                  // Handle view access history
                  _viewAccessHistory(widget.device.id);
                },
              ),
            if (widget.device.type.toLowerCase().contains('door'))
              ListTile(
                leading: Icon(Icons.lock),
                title: Text('Change Door Password'),
                onTap: () {
                  // Handle change door password
                  _changeDoorPassword(widget.device);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Device'),
              onTap: () {
                // Handle delete device
                _deleteDevice(widget.device.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
  void _deleteDevice(String deviceId) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final _uid = user.uid;
      _firestore.collection('users').doc(_uid).collection('devices').doc(deviceId).delete();
      _database.reference().child('users').child(_uid).child(deviceId).remove();
    }
  }
  void _renameDevice(String deviceId, String currentName) {
    TextEditingController _controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Device'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'New Device Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () {
                // Implement rename device logic
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final _uid = user.uid;
                  _firestore.collection('users').doc(_uid).collection('devices').doc(deviceId).update({
                    'name': _controller.text,
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _viewAccessHistory(String deviceId) {
    // Implement view access history logic
    // For example, navigate to another screen that shows the access history
  }

  void _changeDoorPassword(Device device) {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    final User? user = FirebaseAuth.instance.currentUser;
    final _uid = user?.uid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Door Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: InputDecoration(labelText: 'Old Door Password'),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: 'New Door Password'),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                if (user != null) {
                  final oldPassword = oldPasswordController.text;
                  final newPassword = newPasswordController.text;

                  // Check if the new password is exactly 8 digits and contains only numbers
                  final passwordRegExp = RegExp(r'^\d{8}$');
                  if (!passwordRegExp.hasMatch(newPassword)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password must be exactly 8 digits.')),
                    );
                    return;
                  }
                  String? currentPassword;
                  try{
                    DatabaseEvent deviceEvent = await _database.reference()
                        .child('users')
                        .child(_uid!)
                        .child(device.id)
                        .child('password')
                        .once();

                    DataSnapshot deviceSnapshot = deviceEvent.snapshot;
                    currentPassword = deviceSnapshot.value as String?;
                  }catch(e){

                  }
                  try {
                    if (currentPassword == null || oldPassword != currentPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Old password is incorrect.')),
                      );
                      return;
                    }

                    // Update password in Realtime Database
                    await _database.reference()
                        .child('users')
                        .child(_uid!)
                        .child(device.id)
                        .set({
                      'password': newPassword,
                    });

                    // Also update password in Firestore
                    await _firestore.collection('users').doc(_uid).collection('devices').doc(device.id).update({
                      'password': newPassword,
                    });


                  } catch (e) {
                    if (e is FirebaseException && e.code == 'not-found') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Device not found.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating password: $e')),
                      );
                    }
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }


}
