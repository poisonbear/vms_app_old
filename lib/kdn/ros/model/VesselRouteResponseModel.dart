import 'RouteSearchModel.dart';

/*
 * [GIS] 한꺼번에 들어오는 응답을 예측항로와 과거항적으로 분리하기위한 모델
 *
 * @param Map<String, Object> param
 * @return List<Map<String, Object>> result
 * @throws Exception
 */
class VesselRouteResponse {
  final List<PredRouteSearchModel> pred;
  final List<PastRouteSearchModel> past;

  VesselRouteResponse({required this.pred, required this.past});

  factory VesselRouteResponse.fromJson(Map<String, dynamic> json) {
    // pred, past 키가 존재하지 않거나, null이면 빈 리스트로 초기화
    final List<dynamic> predList = json['pred'] ?? [];
    final List<dynamic> pastList = json['past'] ?? [];
    return VesselRouteResponse(
      pred: predList.map((item) => PredRouteSearchModel.fromJson(item)).toList(),
      past: pastList.map((item) => PastRouteSearchModel.fromJson(item)).toList(),
    );
  }

}




