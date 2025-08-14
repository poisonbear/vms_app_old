import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/main/model/VesselSearchModel.dart';
import 'package:vms_app/kdn/ros/view/mainView.dart';
import 'package:vms_app/kdn/ros/viewModel/RouteSearchViewModel.dart';

/// 선박 정보 팝업 컴포넌트
class VesselInfoPopup {
  /// 선박 정보 팝업 표시
  static Future<void> show({
    required BuildContext context,
    required VesselSearchModel vessel,
    required RouteSearchViewModel routeSearchViewModel,
    required MapControllerProvider mapControllerProvider,
    required Function(int) onRouteLoaded,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: getSize300()),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: getSize26().toDouble(),
                left: getSize20().toDouble(),
                right: getSize20().toDouble(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(getSize20().toDouble()),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: getSize10().toDouble(),
                          offset: Offset(getSize0().toDouble(), getSize4().toDouble()),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 헤더
                        _buildHeader(context),
                        SizedBox(height: getSize12().toDouble()),

                        // 선박 정보 테이블
                        _buildInfoTable(vessel),
                        SizedBox(height: getSize32().toDouble()),

                        // 예측항로 버튼
                        if (!routeSearchViewModel.isNavigationHistoryMode)
                          _buildRouteButton(
                            context,
                            vessel,
                            routeSearchViewModel,
                            mapControllerProvider,
                            onRouteLoaded,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 헤더 빌드
  static Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        TextWidgetString(
          '선박 정보',
          getTextleft(),
          getSize24(),
          getTextbold(),
          getColorblack_type1(),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(getSize24().toDouble(), getSize24().toDouble()),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: SvgPicture.asset(
            'assets/kdn/ros/img/close_popup.svg',
            height: getSize24().toDouble(),
            width: getSize24().toDouble(),
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  /// 선박 정보 테이블 빌드
  static Widget _buildInfoTable(VesselSearchModel vessel) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(),
      },
      children: [
        _buildInfoRow('선박명', vessel.ship_nm ?? '-'),
        _buildInfoRow('MMSI', vessel.mmsi?.toString() ?? '-'),
        _buildInfoRow('선종', vessel.cd_nm ?? '-'),
        _buildInfoRow('흘수', vessel.draft != null ? '${vessel.draft} m' : '-'),
        _buildInfoRow('대지속도', vessel.sog != null ? '${vessel.sog} kn' : '-'),
        _buildInfoRow('대지침로', vessel.cog != null ? '${vessel.cog}°' : '-'),
      ],
    );
  }

  /// 정보 행 빌드
  static TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// 예측항로 버튼 빌드
  static Widget _buildRouteButton(
      BuildContext context,
      VesselSearchModel vessel,
      RouteSearchViewModel routeSearchViewModel,
      MapControllerProvider mapControllerProvider,
      Function(int) onRouteLoaded,
      ) {
    return Align(
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleRouteButtonPress(
                context,
                vessel,
                routeSearchViewModel,
                mapControllerProvider,
                onRouteLoaded,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: getColorwhite_type1(),
                shape: RoundedRectangleBorder(
                  borderRadius: getTextradius6_direct(),
                  side: BorderSide(
                    color: getColorsky_Type2(),
                    width: getSize1().toDouble(),
                  ),
                ),
                elevation: getSize0().toDouble(),
                padding: EdgeInsets.all(getSize18().toDouble()),
              ),
              child: TextWidgetString(
                '예측항로 및 과거항적',
                getTextcenter(),
                getSize16(),
                getText700(),
                getColorsky_Type2(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 예측항로 버튼 클릭 처리
  static Future<void> _handleRouteButtonPress(
      BuildContext context,
      VesselSearchModel vessel,
      RouteSearchViewModel routeSearchViewModel,
      MapControllerProvider mapControllerProvider,
      Function(int) onRouteLoaded,
      ) async {
    if (vessel.mmsi == null) return;

    // 로딩 다이얼로그 표시
    _showLoadingDialog(context);

    try {
      // 항적 초기화
      routeSearchViewModel.clearRoutes();
      routeSearchViewModel.setNavigationHistoryMode(false);

      // 항로 데이터 로드
      await routeSearchViewModel.getVesselRoute(
        mmsi: vessel.mmsi,
        regDt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      // 지도 이동
      mapControllerProvider.mapController.move(
        LatLng(vessel.lttd ?? 35.3790988, vessel.lntd ?? 126.167763),
        12.0,
      );

      // 콜백 호출
      onRouteLoaded(vessel.mmsi!);

      // 팝업들 닫기
      Navigator.of(context).pop(); // 로딩 팝업 닫기
      Navigator.of(context).pop(); // 본래 팝업 닫기
    } catch (e) {
      // 에러 처리
      Navigator.of(context).pop(); // 로딩 팝업 닫기
      _showErrorMessage(context, '예측항로 로딩 중 오류 발생');
    }
  }

  /// 로딩 다이얼로그 표시
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  /// 에러 메시지 표시
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}