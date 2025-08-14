
import '../dataSource/VesselSearchSource.dart';
import '../model/VesselSearchModel.dart';
//[Repository] Source를 감싸서 ViewModel 또는 다른 로직과 연결해주는 중간계층
//ViewModel에게 받은 요청을 Source에 넘겨서 데이터를 받아오는 구조

// 실제 데이터 요청을 처리하는 Source
final VesselSearchSource _vesselSearchSource = VesselSearchSource();

class VesselSearchRepository {
  Future<List<VesselSearchModel>> getVesselList({
    String? regDt,
    int? mmsi
  })
  {
    //ViewModesl에서 받은 요청을 Source로 전달
    return _vesselSearchSource.getVesselList(
        regDt: regDt,
        mmsi: mmsi
    );
  }
}
