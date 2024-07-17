import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final _uid = user.uid;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      setState(() {
        _userName = snapshot.get('name'); // Replace 'name' with your field name
      });
    }
  }

  void changePassword(String newPassword) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to login screen or home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          title: Text(_userName!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 30,
            ),
          ),
          backgroundColor: Colors.blueAccent,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // ListTile(
          //   title: Text('User Name'),
          //   subtitle: Text(_userName ?? 'Loading...'),
          // ),
          // Divider(),
          // ListTile(
          //   title: Text('Dark Mode'),
          //   trailing: Switch(
          //     value: Theme.of(context).brightness == Brightness.dark,
          //     onChanged: (value) {
          //       DynamicTheme.of(context)!.setBrightness(
          //         value ? Brightness.dark : Brightness.light,
          //       );
          //     },
          //   ),
          // ),
          // Divider(),
          ListTile(
            title: Text('Change Password'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController _controller = TextEditingController();
                  return AlertDialog(
                    title: Text('Change Password'),
                    content: TextField(
                      controller: _controller,
                      decoration: InputDecoration(labelText: 'New Password'),
                      obscureText: true,
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
                        onPressed: () {
                          changePassword(_controller.text);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Sign Out'),
            onTap: () {
              signOut();
              // Navigate to login screen or home screen
            },
          ),
        ],
      ),
    );
  }
}
