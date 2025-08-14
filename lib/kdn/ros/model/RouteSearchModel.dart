/*
 * [GIS] 특정 선박의 과거 항로 목록을 조회한다.
 *
 * @param Map<String, Object> param
 * @return List<Map<String, Object>> result
 * @throws Exception
 */

//GIS 과거 항행이력 조회 클래스 정의 및 멤버변수선언
class PastRouteSearchModel {
  int? regDt;    //등록일시
  int? mmsi;
  double? lntd; //수신 위치 위도
  double? lttd; //수신 위치 경도
  double? spd;          //속도(노트)
  double? cog;

  //생성자 작성 객체만들때 값을 전달해서 변수를 초기화 해주는 역할 ex) var ship = GisModel(mmsi: 123456789, shipName: "가람호");
  PastRouteSearchModel({
    this.regDt,
    this.mmsi,
    this.lntd,
    this.lttd,
    this.spd,
    this.cog
  });

  //JSON을 받아서 GisModel객체로 바꿔주는 함수 작성
  //fromJson()을 통해 받은 JSON을 Dart객체로 변환 mmsi(클래스변수명) : json['(실제 데이터 컬림명)'];
  factory PastRouteSearchModel.fromJson(Map<String, dynamic> json) {
    return PastRouteSearchModel(
        regDt: json['reg_dt'],
        mmsi: json['mmsi'],
        lntd: json['rcv_loc_lntd'],
        lttd: json['rcv_loc_lttd'],
        spd: json['spd'],
        cog: json['course']
    );
  }

  @override
  String toString() {
    return 'RouteSearchModel(regDt: $regDt, mmsi: $mmsi, lntd: $lntd, lttd: $lttd, spd: $spd, cog: $cog)';
  }
}

//GIS 항로예측 항행이력 조회 클래스 정의 및 멤버변수선언
class PredRouteSearchModel {
  int? pdcthh;    //예측일시
  double? lntd; //수신 위치 위도
  double? lttd; //수신 위치 경도
  double? spd;          //속도(노트)

  //생성자 작성 객체만들때 값을 전달해서 변수를 초기화 해주는 역할 ex) var ship = GisModel(mmsi: 123456789, shipName: "가람호");
  PredRouteSearchModel({
    this.pdcthh,
    this.lntd,
    this.lttd,
    this.spd
  });

  //JSON을 받아서 GisModel객체로 바꿔주는 함수 작성
  //fromJson()을 통해 받은 JSON을 Dart객체로 변환 mmsi(클래스변수명) : json['(실제 데이터 컬림명)'];
  factory PredRouteSearchModel.fromJson(Map<String, dynamic> json) {
    return PredRouteSearchModel(
        pdcthh: json['pdct_cord_hh'],
        lntd: json['pdct_lntd'],
        lttd: json['pdct_lttd'],
        spd: json['pdct_sog']
    );
  }

  @override
  String toString() {
    return 'RouteSearchModel(regDt: $pdcthh, lntd: $lntd, lttd: $lttd, spd: $spd)';
  }
}