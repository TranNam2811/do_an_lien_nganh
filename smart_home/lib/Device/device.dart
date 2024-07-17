import 'dart:async';
import 'package:flutter/foundation.dart';

class Device {
  String name;
  String id;
  bool status;
  String type;
  late ValueNotifier<bool> _statusNotifier;
  late StreamController<bool> _statusController;

  Device({
    required this.name,
    required this.id,
    this.status = false,
    required this.type, // Thêm tham số type vào constructor
  }) {
    _statusNotifier = ValueNotifier<bool>(status);
    _statusController = StreamController<bool>.broadcast(onListen: () {
      _statusController.add(status);
    });
  }

  ValueNotifier<bool> get statusNotifier => _statusNotifier;

  Stream<bool> get statusStream => _statusController.stream;

  void setStatus(bool newStatus) {
    status = newStatus;
    _statusNotifier.value = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusNotifier.dispose();
    _statusController.close();
  }
}

class Door extends Device {
  String password;

  Door({
    required String name,
    required String id,
    bool status = false,
    required this.password,
  }) : super(name: name, id: id, status: status, type: 'Door'); // Thiết lập type là 'door' cho Door

  @override
  void setStatus(bool newStatus) {
    super.setStatus(newStatus);
    // Additional logic specific to Door status changes, if any
  }
}
