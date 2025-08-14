
//선박 데이터 조회
import 'package:flutter/cupertino.dart';
import 'package:vms_app/kdn/ros/model/RouteSearchModel.dart';
import 'package:vms_app/kdn/ros/repository/RouteSearchRepository.dart';
import 'package:vms_app/kdn/ros/model/VesselRouteResponseModel.dart';

//[ViewModel : UI를 위한 데이터와 상태를 관리하는 중간 관리자] 데이터보관 / 데이터 바뀌면 UI자동반영 등

//ChangeNotifier를 상속(데이터 바뀌면 UI에 알릴 수 있는 상태 클래스)
class RouteSearchViewModel with ChangeNotifier {

  bool _isNavigationHistoryMode = false;

  //Repository 생성자에서 초기화 해줄거라서 late 사용
  late final RouteSearchRepository _routeSearchRepository;

  // 분리된 pred와 past 데이터를 저장하는 변수
  List<PredRouteSearchModel> _predRoutes = [];
  List<PastRouteSearchModel> _pastRoutes = [];
  bool _isLoading = false;        //로딩여부
  String _errorMessage = '';      //에러메시지

  //Getter (외부에서 이 값들을 읽을 수 있도록 공개)
  //이렇게 하면 View에서 viewModel.VesselList 처럼 사용가능해짐.
  List<PredRouteSearchModel> get predRoutes => _predRoutes;
  List<PastRouteSearchModel> get pastRoutes => _pastRoutes;
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  //생성자
  //생성할 때 Repository도 같이 초기화해줌.
  RouteSearchViewModel(){
    _routeSearchRepository = RouteSearchRepository();

  }

  Future<void> getVesselRoute({
    String? regDt,
    int? mmsi,
    bool includePrediction = true //예측 항로 포함
  }) async {
    try{
      //API호출 전에 로딩중이라고 UI에 알림
      _isLoading = true;
      notifyListeners();

      // Repository로부터 VesselRouteResponse 받아오기
      VesselRouteResponse response = await _routeSearchRepository.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi,
      );

      // includePrediction 파라미터에 따라 분기 처리
      if (includePrediction) {
        // 예측 항로 포함 (기존 동작)
        _predRoutes = response.pred;
      } else {
        // 예측 항로 포함하지 않음 (빈 리스트로 설정)
        _predRoutes = [];
      }

      // 과거 항적은 무조건 설정
      _pastRoutes = response.past;

    }catch (e){
      _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다 : $e';
      _predRoutes = [];
      _pastRoutes = [];
    }finally{
      //로딩상태 false로 바꾸고 UI에 알림.
      _isLoading = false;
      notifyListeners();
    }
  }

  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  // 선택적으로 데이터 초기화 메서드 추가 가능
  void clearRoutes() {
    _predRoutes = [];
    _pastRoutes = [];
    notifyListeners();
  }

  @override
  String toString() {
    return 'RouteSearchViewModel(predRoutes: ${predRoutes.length}, pastRoutes: ${pastRoutes.length})';
  }

}

