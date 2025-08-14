import 'package:vms_app/kdn/ros/dataSource/RosSource.dart';
import 'package:vms_app/kdn/ros/model/RosModel.dart';

// 항행이력 데이터 Load
final RosSource _dataSource = RosSource();

class RosRepository {
  Future<List<RosModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName
  })
  {
    return _dataSource.getRosList(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName
    );
  }
  //날씨 정보(파고, 시정) 가져오기
  Future<WeatherInfo?> getWeatherInfo() {
    return _dataSource.getWeatherInfo(); //RosSource에서 함수 호출
  }
  // 항행경보 알림 데이터 가져오기
  Future<List<String>?> getNavigationWarnings() {
    return _dataSource.getNavigationWarnings();
  }

}