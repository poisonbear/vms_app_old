import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState with ChangeNotifier {
  String _role = '';
  int? _mmsi;

  String get role => _role;
  int? get mmsi => _mmsi;

  void setRole(String newRole) async {
    _role = newRole;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', newRole);
  }

  void setMmsi(int? newMmsi) async {
    _mmsi = newMmsi;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newMmsi != null) {
      await prefs.setInt('user_mmsi', newMmsi);
    } else {
      await prefs.remove('user_mmsi'); // null일 경우 기존 저장 값 제거
    }

  }


  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('user_role') ?? '';
    _mmsi = prefs.getInt('user_mmsi');
    notifyListeners();
  }
}