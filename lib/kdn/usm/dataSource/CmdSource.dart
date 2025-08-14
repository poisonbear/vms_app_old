import '../model/CmdModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/logger.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';

class CmdSource {

  final dioRequest = DioRequest();


  Future<List<CmdModel>> getCmdList() async {
    try {
      final String apiUrl = dotenv.env['kdn_usm_select_cmd_key'] ?? '';
      final response = await dioRequest.dio.get(apiUrl);

      // 로그 출력
      logger.d("[API URL] : $apiUrl");
      logger.d("[Response] : ${response.data}");

      return (response.data as List)
          .map<CmdModel>((json) => CmdModel.fromJson(json))
          .toList();
    } catch (e) {
      // 예외 처리
      logger.e("Error occurred: $e");
      return [];
    }
  }
}
