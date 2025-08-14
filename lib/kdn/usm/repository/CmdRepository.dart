import '../dataSource/CmdSource.dart';
import '../model/CmdModel.dart';

// 이용약관 데이터 Load
final CmdSource _dataSource = CmdSource();

class CmdRepository {
  Future<List<CmdModel>> getCmdList() {
    return _dataSource.getCmdList();
  }
}

