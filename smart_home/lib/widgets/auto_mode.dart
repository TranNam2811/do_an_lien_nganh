import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home/Device/device.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class AutoMode extends StatefulWidget {
  final Device device;

  AutoMode({required this.device});

  @override
  _AutoModeState createState() => _AutoModeState();
}

class _AutoModeState extends State<AutoMode> {
  bool _isAutoModeEnabled = false;
  TimeOfDay _onTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _offTime = TimeOfDay(hour: 19, minute: 0);
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();
  late String _uid;
  late StreamController<Map<dynamic, dynamic>> _streamController;
  late StreamSubscription<DatabaseEvent> _streamSubscription;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _streamController = StreamController<Map<dynamic, dynamic>>();
    _listenToDatabaseChanges();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _streamController.close();
    super.dispose();
  }

  void _listenToDatabaseChanges() {
    _streamSubscription = _databaseReference
        .child('users')
        .child(_uid)
        .child(widget.device.espid)
        .child(widget.device.id)
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      _streamController.add(data);
    });
  }

  void _fetchInitialData() async {
    final snapshot = await _databaseReference
        .child('users')
        .child(_uid)
        .child(widget.device.espid)
        .child(widget.device.id)
        .once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
    if (data != null) {
      setState(() {
        _isAutoModeEnabled = data['AutoMode'] ?? false;
        if (data['onTime'] != null) {
          _onTime = _parseTime(data['onTime']);
        }
        if (data['offTime'] != null) {
          _offTime = _parseTime(data['offTime']);
        }
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final format = DateFormat.Hm(); // 'HH:mm' format
    final dateTime = format.parse(time);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Future<void> _selectTime(BuildContext context, bool isOnTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOnTime ? _onTime : _offTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOnTime) {
          _onTime = picked;
        } else {
          _offTime = picked;
        }
        _updateDatabase();
      });
    }
  }

  void _updateDatabase() {
    final onTimeFormatted = DateFormat.Hm().format(
      DateTime(0, 0, 0, _onTime.hour, _onTime.minute),
    );
    final offTimeFormatted = DateFormat.Hm().format(
      DateTime(0, 0, 0, _offTime.hour, _offTime.minute),
    );
    _databaseReference
        .child('users')
        .child(_uid)
        .child(widget.device.espid)
        .child(widget.device.id)
        .update({
      'AutoMode': _isAutoModeEnabled,
      'onTime': onTimeFormatted,
      'offTime': offTimeFormatted,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Auto mode",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<Map<dynamic, dynamic>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            _isAutoModeEnabled = data['AutoMode'] ?? false;
            if (data['onTime'] != null) {
              _onTime = _parseTime(data['onTime']);
            }
            if (data['offTime'] != null) {
              _offTime = _parseTime(data['offTime']);
            }
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text('Enable Auto Mode',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700),),
                  value: _isAutoModeEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isAutoModeEnabled = value;
                      _updateDatabase();
                    });
                  },
                ),
                if (_isAutoModeEnabled) ...[
                  ListTile(
                    title: Text("Select On Time"),
                    subtitle: Text("${_onTime.format(context)}"),
                    trailing: Icon(Icons.access_time),
                    onTap: () => _selectTime(context, true),
                  ),
                  ListTile(
                    title: Text("Select Off Time"),
                    subtitle: Text("${_offTime.format(context)}"),
                    trailing: Icon(Icons.access_time),
                    onTap: () => _selectTime(context, false),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
