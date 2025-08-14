import 'package:dio/dio.dart';
import 'package:vms_app/kdn/ros/model/RosModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/logger.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';

class RosSource {

  final dioRequest = DioRequest();

  Future<List<RosModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName
  })
  async {
    try {

      final String apiUrl = dotenv.env['kdn_ros_select_navigation_Info'] ?? '';

      final Map<String, dynamic> queryParams = {
        'startDate' : startDate,
        'endDate' : endDate,
        'mmsi' : mmsi,
        'shipName' : shipName
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.get(
          apiUrl,
          data: queryParams,
          options: options
      );

      // 로그 출력
      //logger.d("[API URL] : ${apiUrl}");
      //logger.d("[Response] : ${response.data}");

      if(response.data is Map){
        final List items = response.data['mmsi'] ?? [];
        return items.map<RosModel>((json) => RosModel.fromJson(json)).toList();
      }

      if(response.data is List){
        return (response.data as List).map<RosModel>((json) => RosModel.fromJson(json)).toList();
      }

      return [];

    } catch (e) {
      // 예외 처리
      logger.e("Error occurred: $e");
      return [];
    }
  }

  //날씨 정보(파고, 시정) 가져오기
  Future<WeatherInfo?> getWeatherInfo() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_visibility_Info'] ?? '';

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        // 필요한 경우 빈 데이터 객체 추가
        data: {},
      );

      if (response.data != null && response.data is Map) {
        WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
        return weatherInfo;
      }

      return null;
    } catch (e) {
      logger.e("Weather API Error: $e");
      return null;
    }
  }
  
  //항행경보 알림 데이터 가져오기
  Future<List<String>> getNavigationWarnings() async {
    try {
      final String apiUrl = dotenv.env['kdn_ros_select_navigation_warn_Info'] ?? '';

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data['data'] != null) {
        return NavigationWarnings.fromJson(response.data).warnings;
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}