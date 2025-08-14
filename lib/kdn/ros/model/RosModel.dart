class RosModel {
  int? mmsi;
  int? reg_dt;
  int? odb_reg_date;
  String? shipName;
  String? ship_kdn;
  String? psng_auth;
  String? psng_auth_cd;

  RosModel({
    this.mmsi,
    this.reg_dt,
    this.odb_reg_date,
    this.shipName,
    this.ship_kdn,
    this.psng_auth,
    this.psng_auth_cd
  });

  factory RosModel.fromJson(Map<String, dynamic> json) {
    return RosModel(
        mmsi: json['mmsi'],
        reg_dt: json['reg_dt'],
        odb_reg_date: json['odb_reg_date'],
        shipName: json['ship_nm'],
        ship_kdn: json['ship_kdn'],
        psng_auth: json['psng_auth'],
        psng_auth_cd: json['psng_auth_cd']
    );
  }
}

//날씨 정보(파고, 시정) 가져오기
class WeatherInfo {
  final double wave;
  final double visibility;

  // 파고 알람 데이터 (4개)
  final double walm1;
  final double walm2;
  final double walm3;
  final double walm4;

  // 시정 알람 데이터 (4개)
  final double valm1;
  final double valm2;
  final double valm3;
  final double valm4;


  WeatherInfo({
    required this.wave,
    required this.visibility,
    this.walm1 = 0.0,
    this.walm2 = 0.0,
    this.walm3 = 0.0,
    this.walm4 = 0.0,
    this.valm1 = 0.0,
    this.valm2 = 0.0,
    this.valm3 = 0.0,
    this.valm4 = 0.0,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    double wave = 0.0;
    double visibility = 0.0;

    double walm1 = 0.0; //파고 알람 데이터
    double walm2 = 0.0;
    double walm3 = 0.0;
    double walm4 = 0.0;

    double valm1 = 0.0; //시정 알람 데이터
    double valm2 = 0.0;
    double valm3 = 0.0;
    double valm4 = 0.0;

    if (json.containsKey('data')) {
      Map<String, dynamic> data = json['data'];

      // 현재 파고, 시정 데이터 추출
      if (data.containsKey('nowData')) {
        var nowData = data['nowData'];
        if (nowData != null && nowData is Map) {
          // 현재 파고 값 추출
          if (nowData.containsKey('wvhgt_surf')) {
            try {
              wave = double.parse(nowData['wvhgt_surf'].toString());
            } catch (e) {

            }
          }

          // 현재 시정 값 추출
          if (nowData.containsKey('vdst')) {
            try {
              visibility = double.parse(nowData['vdst'].toString());
            } catch (e) {

            }
          }
        }
      }

      // 파고 알람 데이터 추출
      if (data.containsKey('waveData')) {
        var waveData = data['waveData'];
        if (waveData != null && waveData is Map) {
          // 파고 알람 기준값들 추출
          if (waveData.containsKey('alm_a_val')) {
            try {
              walm1 = double.parse(waveData['alm_a_val'].toString());
            } catch (e) {

            }
          }

          if (waveData.containsKey('alm_b_val')) {
            try {
              walm2 = double.parse(waveData['alm_b_val'].toString());
            } catch (e) {

            }
          }

          if (waveData.containsKey('alm_c_val')) {
            try {
              walm3 = double.parse(waveData['alm_c_val'].toString());
            } catch (e) {

            }
          }

          if (waveData.containsKey('alm_d_val')) {
            try {
              walm4 = double.parse(waveData['alm_d_val'].toString());
            } catch (e) {

            }
          }
        }
      }

      // 시정 알람 데이터 추출
      if (data.containsKey('visibilityData')) {
        var visibilityData = data['visibilityData'];
        if (visibilityData != null && visibilityData is Map) {
          // 시정 알람 기준값들 추출
          if (visibilityData.containsKey('alm_a_val')) {
            try {
              valm1 = double.parse(visibilityData['alm_a_val'].toString());
            } catch (e) {

            }
          }

          if (visibilityData.containsKey('alm_b_val')) {
            try {
              valm2 = double.parse(visibilityData['alm_b_val'].toString());
            } catch (e) {

            }
          }

          if (visibilityData.containsKey('alm_c_val')) {
            try {
              valm3 = double.parse(visibilityData['alm_c_val'].toString());
            } catch (e) {

            }
          }

          if (visibilityData.containsKey('alm_d_val')) {
            try {
              valm4 = double.parse(visibilityData['alm_d_val'].toString());
            } catch (e) {

            }
          }
        }
      }
    }

    return WeatherInfo(
      wave: wave,
      visibility: visibility,
      walm1: walm1,
      walm2: walm2,
      walm3: walm3,
      walm4: walm4,
      valm1: valm1,
      valm2: valm2,
      valm3: valm3,
      valm4: valm4,
    );
  }
}

// 항행경보 알림 데이터 정보
class NavigationWarnings {
  final List<String> warnings;

  NavigationWarnings({required this.warnings});

  factory NavigationWarnings.fromJson(Map<String, dynamic> json) {
    List<dynamic> data = json['data'] ?? [];
    return NavigationWarnings(
      warnings: data.map((item) => item.toString()).toList(),
    );
  }

  // 경고 메시지가 있는지 확인하는 헬퍼 메서드
  bool get hasWarnings => warnings.isNotEmpty;

  // 경고 메시지를 하나의 문자열로 연결 (Marquee용)
  String get combinedWarnings => warnings.join(' | ');
}
