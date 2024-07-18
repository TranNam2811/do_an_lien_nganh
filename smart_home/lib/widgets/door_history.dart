import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/Device/device.dart';

class DoorHistory extends StatefulWidget {
  final Device device;

  DoorHistory({required this.device});

  @override
  _DoorHistoryState createState() => _DoorHistoryState();
}

class _DoorHistoryState extends State<DoorHistory> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late StreamController<List<Map<String, dynamic>>> _historyStreamController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _historyStreamController = StreamController<List<Map<String, dynamic>>>();
    _fetchDoorHistory();
  }

  @override
  void dispose() {
    _historyStreamController.close();
    super.dispose();
  }

  void _fetchDoorHistory() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    DatabaseReference historyRef = _database
        .reference()
        .child('users')
        .child(user.uid)
        .child(widget.device.id);

    historyRef.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      List<Map<String, dynamic>> historyList = [];

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        if (data['hisopen'] != null) {
          Map<dynamic, dynamic> hisopen = data['hisopen'] as Map<dynamic, dynamic>;
          hisopen.forEach((key, value) {
            historyList.add({
              'type': 'open',
              'timestamp': value,
              'date': _parseTimestamp(value),
            });
          });
        }

        if (data['hisclose'] != null) {
          Map<dynamic, dynamic> hisclose = data['hisclose'] as Map<dynamic, dynamic>;
          hisclose.forEach((key, value) {
            historyList.add({
              'type': 'close',
              'timestamp': value,
              'date': _parseTimestamp(value),
            });
          });
        }

        // Sort history list by date
        historyList.sort((a, b) => b['date'].compareTo(a['date']));
      }

      _historyStreamController.add(_filterHistoryByDateRange(historyList));
    });
  }

  DateTime _parseTimestamp(String timestamp) {
    final parts = timestamp.split(' ');
    final timeParts = parts[0].split(':');
    final dateParts = parts[1].split('/');

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);

    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    return DateTime(year, month, day, hour, minute, second);
  }

  List<Map<String, dynamic>> _filterHistoryByDateRange(List<Map<String, dynamic>> historyList) {
    if (_startDate == null && _endDate == null) {
      return historyList;
    }

    return historyList.where((entry) {
      DateTime entryDate = entry['date'];
      bool afterStart = _startDate == null || entryDate.isAfter(_startDate!);
      bool beforeEnd = _endDate == null || entryDate.isBefore(_endDate!);
      return afterStart && beforeEnd;
    }).toList();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _fetchDoorHistory(); // Re-fetch and filter history
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _fetchDoorHistory(); // Re-fetch and filter history
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Door History: ${widget.device.name}',
          style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 26,
        ),
      ),
      backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () async {
              await _selectStartDate(context);
              await _selectEndDate(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () => _selectStartDate(context),
                        icon: Icon(Icons.date_range_outlined)
                    ),
                    Text(_startDate == null ? 'Select Start Date' : _startDate!.toLocal().toString().split(' ')[0]),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        onPressed: () => _selectEndDate(context),
                        icon: Icon(Icons.date_range_outlined)
                    ),
                    Text(_endDate == null ? 'Select Start Date' : _endDate!.toLocal().toString().split(' ')[0]),
                  ],
                ),

              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _historyStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No history found.'));
                } else {
                  List<Map<String, dynamic>> history = snapshot.data!;
                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: history[index]['type'] == 'open' ? Colors.green[100] : Colors.red[100],
                        child: ListTile(
                          title: Text('Status: ${history[index]['type'] == 'open' ? 'Opened' : 'Closed'}'),
                          subtitle: Text('Time: ${history[index]['timestamp']}'),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
