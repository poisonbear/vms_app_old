import 'package:vms_app/kdn/ros/dataSource/RouteSearchSource.dart';
import 'package:vms_app/kdn/ros/model/VesselRouteResponseModel.dart';

//특정 선박 과거/미래 항로 조회
final RouteSearchSource _RouteSearchSource = RouteSearchSource();

/*
 * [GIS] 특정 선박의 과거 항로 목록을 조회한다.
 *
 * @param Map<String, Object> param
 * @return List<Map<String, Object>> result
 * @throws Exception
 */
class RouteSearchRepository {
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi
  })
  {
    //ViewModesl에서 받은 요청을 Source로 전달
    return _RouteSearchSource.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi
    );
  }
}