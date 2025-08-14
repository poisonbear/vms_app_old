import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/kdn/ros/model/RosModel.dart';
import 'package:vms_app/kdn/ros/repository/RosRepository.dart';

import '../../cmm_widget/common_style_widget.dart';

// 항행이력 데이터 Load
class RosNavigationViewModel with ChangeNotifier {
  late final RosRepository _RosRepository;

  List<dynamic> _RosList = [];
  bool _isLoading = false;
  bool _isInitialized = false; // 조회 버튼을 눌렀는지 추적하는 변수
  String _errorMessage = '';

  //날씨 정보(파고, 시정) 가져오기
  double wave = 0;
  double visibility = 0;
  // 파고 알람 기준값
  double walm1 = 0.0; // 파고 alm_a_val
  double walm2 = 0.0; // 파고 alm_b_val
  double walm3 = 0.0; // 파고 alm_c_val
  double walm4 = 0.0; // 파고 alm_d_val
  // 시정 알람 기준값
  double valm1 = 0.0; // 파고 alm_a_val
  double valm2 = 0.0; // 파고 alm_b_val
  double valm3 = 0.0; // 파고 alm_c_val
  double valm4 = 0.0; // 파고 alm_d_val

  List<String> _navigationWarnings = []; //항행경보 알림 메시지

  List<dynamic> get RosList => _RosList;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // 조회 버튼 클릭 여부 확인용 getter
  String get errorMessage => _errorMessage;

  RosNavigationViewModel(){
    _RosRepository = RosRepository();
    //getRosList();
    //자동 호출 제거
  }

  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName
  }) async{
      try{
        //로딩 시작
        _isLoading = true;
        notifyListeners();

        List<RosModel> fetchedList = await _RosRepository.getRosList(
            startDate: startDate,
            endDate: endDate,
            mmsi: mmsi,
            shipName: shipName
        );
        _RosList = fetchedList;
        if(_RosList != null || _RosList == []){
          _isInitialized = true; // 조회가 완료되면 isInitialized를 true로 설정
        }
      }catch (e){
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다 : $e';
      _RosList = [];
    }finally{
      //성공/실패에 상관없이 Loading false
      _isLoading = false;
      notifyListeners();
    }
  }

//날씨 정보(파고, 시정) 가져오기
  Future<void> getWeatherInfo() async {
    try {
      final weather = await _RosRepository.getWeatherInfo();
      if (weather != null) {
        wave = weather.wave;
        visibility = weather.visibility;

        // 알람 기준값도 저장
        walm3 = weather.walm3; // 파고 alm_c_val
        walm4 = weather.walm4; // 파고 alm_d_val

        valm3 = weather.valm3; // 시정 alm_c_val
        valm4 = weather.valm4; // 시정 alm_d_val

        notifyListeners(); // UI에 반영
      }
    } catch (e) {

    }
  }

// 파고 색상과 함께 적용된 기준값 반환
  Map<String, dynamic> getWaveColorAndThreshold(double wave) {
    Color color;
    double threshold;
    String warningText = "";

    if (wave == 0) {
        color = getColorwhite_type1();
        threshold = wave;
        //warningText = "(정상)";
    } else if (wave >= walm4) {
        color = getColorred_type2();
        threshold = wave;
        warningText = "(심각)";
    } else if (wave >= walm3) {
        color = getColoryellow_Type2();
        threshold = wave;
        warningText = "(주의)";
    //} else if (wave >= walm2) {
        //color = getColorwhite_type1(); // 관심 레벨도 색깔 설정
        //threshold = wave;
        //warningText = "(관심)";
    //} else if (wave >= walm1) {
        //color = getColorwhite_type1(); // 정상 레벨도 색깔 설정
        //threshold = wave;
        //warningText = "(정상)";
    } else {
        color = getColorwhite_type1();
        threshold = wave;
        warningText = "(정상)";
    }

    return {
      'color': color,
      'threshold': threshold,
      'warningText': warningText
    };
  }

// 시정 색상과 함께 적용된 기준값 반환
  Map<String, dynamic> getVisibilityColorAndThreshold(double visibility) {
    Color color;
    double threshold;
    String warningText = "";

    if (visibility == 0) {
        color = getColorwhite_type1();
        threshold = visibility;
        //warningText = "(정상)";
    } else if (visibility <= valm4) {
        color = getColorred_type2();
        threshold = visibility;
        warningText = "(심각)";
    } else if (visibility <= valm3) {
        color = getColoryellow_Type2();
        threshold = visibility;
        warningText = "(주의)";
    //} else if (visibility <= valm2) {
        //color = getColorwhite_type1(); // 관심 레벨도 흰색으로 설정
        //threshold = visibility;
        //warningText = "(관심)";
    //} else if (visibility <= valm1) {
        //color = getColorwhite_type1(); // 정상 레벨도 흰색으로 설정
        //threshold = visibility;
        //warningText = "(정상)";
    } else {
        color = getColorwhite_type1();
        threshold = visibility;
        warningText = "(정상)";
    }

    return {
      'color': color,
      'threshold': threshold,
      'warningText': warningText
    };
  }

// 파고 색깔만 간편하게 가져오기
  Color getWaveColor(double wave) {
    return getWaveColorAndThreshold(wave)['color'];
  }

// 파고 임계값만 가져오기
  double getWaveThreshold(double wave) {
    return getWaveColorAndThreshold(wave)['threshold'];
  }

// 시정 색깔만 간편하게 가져오기
  Color getVisibilityColor(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['color'];
  }

// 시정 임계값만 가져오기
  double getVisibilityThreshold(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['threshold'];
  }

// 파고 경고 텍스트 가져오기
  String getWaveWarningText(double wave) {
    return getWaveColorAndThreshold(wave)['warningText'];
  }

// 시정 경고 텍스트 가져오기
  String getVisibilityWarningText(double visibility) {
    return getVisibilityColorAndThreshold(visibility)['warningText'];
  }

// 파고 임계값 텍스트 포맷팅
  String getFormattedWaveThresholdText(double wave) {
    double threshold = getWaveThreshold(wave);
    String warningText = getWaveWarningText(wave);
    return '${threshold.toStringAsFixed(2)}m$warningText';
  }

// 시정 임계값 텍스트 포맷팅
  String getFormattedVisibilityThresholdText(double visibility) {
    double threshold = getVisibilityThreshold(visibility);
    String warningText = getVisibilityWarningText(visibility);

    // 임계값이 1000m 이상인 경우 km 단위로 변환
    if (threshold >= 1000) {
      double thresholdInKm = threshold / 1000;
      return '${thresholdInKm.toStringAsFixed(0)}km$warningText';
    } else {
      // 1000m 미만인 경우 m 단위 유지
      return '${threshold.toStringAsFixed(0)}m$warningText';
    }
  }

// 항행 경보 알림 데이터 정보
  Future<void> getNavigationWarnings() async {
    try {
      _navigationWarnings = await _RosRepository.getNavigationWarnings() ?? [];
      _errorMessage = '';
    } catch (e) {
      _navigationWarnings = [];
      _errorMessage = '항행경보 데이터를 불러오는 중 오류가 발생했습니다';
    }

    notifyListeners(); // 데이터 로딩 완료 후 한 번만 알림
  }

// Marquee에 표시할 결합된 항행 경보 메시지
  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return '금일 항행경보가 없습니다.';
    }
    //메시지 결합
    String result = _navigationWarnings.join('             ');

    return result;
  }

}
