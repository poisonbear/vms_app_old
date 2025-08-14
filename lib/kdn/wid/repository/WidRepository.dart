import 'package:vms_app/kdn/wid/dataSource/WidSource.dart';
import 'package:vms_app/kdn/wid/model/WidModel.dart';

// 기상정보 데이터 Load
final WidSource _dataSource = WidSource();

class WidRepository {
  Future<List<WidModel>> getWidList() {

    return _dataSource.getWidList();
  }
}