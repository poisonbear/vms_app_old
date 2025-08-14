import 'package:dio/dio.dart';
import 'package:vms_app/kdn/ros/model/RouteSearchModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/logger.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';
import 'package:vms_app/kdn/ros/model/VesselRouteResponseModel.dart';

/*
 * [GIS]특정 선박의 과거 항로 목록을 조회한다.
 *
 * @param Map<String, Object> param
 * @return List<Map<String, Object>> result
 * @throws Exception
 */

class RouteSearchSource{
  //dioRequest 객체 생성 HTTP클라이언트를 wrap한 클래스 내부에 dio.get(..) 있음.
  final dioRequest = DioRequest();

  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_Route'] ?? '';

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
      //logger.d("[param] : ${queryParams}");
      //logger.d("[Response] : ${response.data}");

      // 응답 데이터가 Map인 경우, pred와 past를 분리해서 반환합니다.
      if (response.data is Map) {
        return VesselRouteResponse.fromJson(response.data);
      }

      // 만약 List 형태로 온다면, 임의로 past에 담고 pred는 빈 리스트로 처리
      if (response.data is List) {
        List<PastRouteSearchModel> list = (response.data as List)
            .map((json) => PastRouteSearchModel.fromJson(json))
            .toList();
        return VesselRouteResponse(pred: [], past: list);
      }

      return VesselRouteResponse(pred: [], past: []);

    } catch (e) {
      //예외 처리
      logger.e("오류 발생. 관리자에게 문의 바랍니다. $e");
      return VesselRouteResponse(pred: [], past: []);
    }
  }
}