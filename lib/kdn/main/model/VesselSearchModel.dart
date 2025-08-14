//클래스 정의 및 멤버변수선언
class VesselSearchModel {
  int? mmsi;
  double? lttd;
  double? lntd;
  double? sog;
  double? cog;
  double? hdg;
  String? ship_nm;
  String? ship_knd;
  String? cd_nm;
  int? loc_crlpt_a;
  int? loc_crlpt_b;
  int? loc_crlpt_c;
  int? loc_crlpt_d;
  double? draft;
  String? destn;
  String? escapeRouteGeojson;

  //생성자 작성 객체만들때 값을 전달해서 변수를 초기화 해주는 역할 ex) var ship = GisModel(mmsi: 123456789, shipName: "가람호");
  VesselSearchModel({
    this.mmsi,
    this.lttd,
    this.lntd,
    this.sog,
    this.cog,
    this.hdg,
    this.ship_nm,
    this.ship_knd,
    this.cd_nm,
    this.loc_crlpt_a,
    this.loc_crlpt_b,
    this.loc_crlpt_c,
    this.loc_crlpt_d,
    this.draft,
    this.destn,
    this.escapeRouteGeojson
  });

  //JSON을 받아서 VesselSearchModel 객체로 변환하는 함수
  factory VesselSearchModel.fromJson(Map<String, dynamic> json) {
    return VesselSearchModel(
      // 정수 타입 안전하게 변환
        mmsi: json['mmsi'] is int ? json['mmsi'] : int.tryParse(json['mmsi']?.toString() ?? ''),

        // 실수 타입 안전하게 변환
        lttd: json['lttd'] is double ? json['lttd'] : double.tryParse(json['lttd']?.toString() ?? ''),
        lntd: json['lntd'] is double ? json['lntd'] : double.tryParse(json['lntd']?.toString() ?? ''),
        sog: json['sog'] is double ? json['sog'] : double.tryParse(json['sog']?.toString() ?? ''),
        cog: json['cog'] is double ? json['cog'] : double.tryParse(json['cog']?.toString() ?? ''),
        hdg: json['hdg'] is double ? json['hdg'] : double.tryParse(json['hdg']?.toString() ?? ''),

        // 문자열 타입 안전하게 변환
        ship_nm: json['ship_nm']?.toString(),
        ship_knd: json['ship_knd']?.toString(),
        cd_nm: json['cd_nm']?.toString(),
        // 정수 타입 안전하게 변환
        loc_crlpt_a: json['loc_crlpt_a'] is int ? json['loc_crlpt_a'] : int.tryParse(json['loc_crlpt_a']?.toString() ?? ''),
        loc_crlpt_b: json['loc_crlpt_b'] is int ? json['loc_crlpt_b'] : int.tryParse(json['loc_crlpt_b']?.toString() ?? ''),
        loc_crlpt_c: json['loc_crlpt_c'] is int ? json['loc_crlpt_c'] : int.tryParse(json['loc_crlpt_c']?.toString() ?? ''),
        loc_crlpt_d: json['loc_crlpt_d'] is int ? json['loc_crlpt_d'] : int.tryParse(json['loc_crlpt_d']?.toString() ?? ''),

        // 실수 타입 안전하게 변환
        draft: json['draft'] is double ? json['draft'] : double.tryParse(json['draft']?.toString() ?? ''),

        // 문자열 타입 안전하게 변환
        destn: json['destn']?.toString(),

        //퇴각항로
        escapeRouteGeojson: json['escape_route_geojson']?.toString()

    );
  }
}

