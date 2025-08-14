import 'package:dio/dio.dart';
import 'package:vms_app/kdn/main/model/VesselSearchModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/logger.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';

class VesselSearchSource {
  //dioRequest 객체 생성 HTTP클라이언트를 wrap한 클래스 내부에 dio.get(..) 있음.
  final dioRequest = DioRequest();

  Future<List<VesselSearchModel>> getVesselList({
    String? regDt,
    int? mmsi
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_List'] ?? '';
      
      //서버에 전달할 요청 데이터 준비(해당 값이 HTTP 요청의 body에 들어감
      final Map<String, dynamic> queryParams = {
        'mmsi' : mmsi,
        'reg_dt' : regDt
      };

      //응답 대기 시간(100초) 설정
      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      //GET 방식으로 요청 보냄.
      final response = await dioRequest.dio.get(
          apiUrl,
          data: queryParams,
          options: options
      );

      // 로그 출력
      //logger.d("[API URL] : ${apiUrl}");
      //logger.d("[Response] : ${response.data}");

      //Map일 경우 ex "mmsi": [ { "id": 1, "name": "선박A" }, { "id": 2, "name": "선박B" }]
      if(response.data is Map){
        final List items = response.data['mmsi'] ?? [];
        return items.map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json)).toList();
      }

      //List일 경우 [ { "id": 1, "name": "선박A" },{ "id": 2, "name": "선박B" }]
      if(response.data is List){
        return (response.data as List).map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json)).toList();
      }

      return [];

    } catch (e) {
      //예외 처리
      logger.e("오류 발생. 관리자에게 문의 바랍니다. $e");
      return [];
    }
  }
}


