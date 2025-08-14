import 'dart:math';

import 'package:flutter/material.dart';

import 'package:vms_app/kdn/wid/model/WidModel.dart';
import 'package:vms_app/kdn/wid/repository/WidRepository.dart';

import 'package:vms_app/logger.dart';

// 기상정보 데이터 Load
class WidWeatherInfoViewModel with ChangeNotifier {
  late final WidRepository _WidRepository;
  List<WidModel>? _WidList;
  List<String> _windDirection = [];
  List<String> _windSpeed = [];
  List<String> _windIcon = [];

  List<WidModel>? get WidList => _WidList;
  List<String> get windDirection => _windDirection;
  List<String> get windSpeed => _windSpeed;
  List<String> get windIcon => _windIcon;
  bool _isLoading  = true;
  bool get isLoading => _isLoading;

  WidWeatherInfoViewModel() {
    _WidRepository = WidRepository();
    getWidList();
  }

  void calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('');
      _windSpeed.add('');
      _windIcon.add('');
      return;
    }

    // 풍속 계산
    final windSpeed = sqrt(pow(windU, 2) + pow(windV, 2));
    _windSpeed.add('${windSpeed.toStringAsFixed(0)} m/s');

    // 풍향 각도 계산
    double theta = atan2(windV, windU);
    double degrees = (270 - (theta * 180 / pi)) % 360;
    if (degrees < 0) degrees += 360;

    // 풍향 결정
    if (degrees >= 337.5 || degrees < 22.5) {
      _windDirection.add('북풍');
      _windIcon.add('ro180');
    } else if (degrees >= 22.5 && degrees < 67.5) {
      _windDirection.add('북동풍');
      _windIcon.add('ro225');
    } else if (degrees >= 67.5 && degrees < 112.5) {
      _windDirection.add('동풍');
      _windIcon.add('ro270');
    } else if (degrees >= 112.5 && degrees < 157.5) {
      _windDirection.add('남동풍');
      _windIcon.add('ro315');
    } else if (degrees >= 157.5 && degrees < 202.5) {
      _windDirection.add('남풍');
      _windIcon.add('ro0');
    } else if (degrees >= 202.5 && degrees < 247.5) {
      _windDirection.add('남서풍');
      _windIcon.add('ro45');
    } else if (degrees >= 247.5 && degrees < 292.5) {
      _windDirection.add('서풍');
      _windIcon.add('ro90');
    } else {
      _windDirection.add('북서풍');
      _windIcon.add('ro135');
    }
    notifyListeners();
  }

  Future<void> getWidList() async {
    _isLoading = true; // 로딩 시작 - 여기에 추가
    notifyListeners(); // 로딩 상태 변경 알림 - 여기에 추가

    try {
      List<WidModel> fetchedList = await _WidRepository.getWidList();
      _WidList = fetchedList;

      if (fetchedList.isNotEmpty) {
        for (int i = 0; i < fetchedList.length; i++) {
          calculateWind(
            fetchedList[i].wind_u_surface?.toDouble(),
            fetchedList[i].wind_v_surface?.toDouble(),
          );
        }
      }
    } catch (e) {
      logger.e("Error in getWidList: $e");
      _WidList = [];
      _windDirection = [];
      _windSpeed = [];
      _windIcon = [];
    } finally {
      _isLoading = false; // 오류 발생 시에도 로딩 상태 해제
      notifyListeners();
    }
  }
}
