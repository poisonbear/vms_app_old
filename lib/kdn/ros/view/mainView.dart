import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';
import 'package:vms_app/kdn/usm/view/MemberInformationView.dart';
import 'package:vms_app/kdn/wid/view/mainView_windyTap.dart';
import 'package:vms_app/kdn/ros/view/mainView_navigationTap.dart';
import 'package:marquee/marquee.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/kdn/cmm_widget/common_utill.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main/model/VesselSearchModel.dart';
import '../../main/viewModel/VesselSearchViewModel.dart';
import '../../usm/viewModel/UserState.dart';
import '../viewModel/NavigationViewModel.dart';
import '../viewModel/RouteSearchViewModel.dart';

//GeoJSON 파싱 함수
List<LatLng> parseGeoJsonLineString(String geoJsonStr) {
  try {
    final decodedOnce = jsonDecode(geoJsonStr);
    final geoJson = decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;
    final coords = geoJson['coordinates'] as List;
    return coords.map<LatLng>((c) {
      final lon = double.tryParse(c[0].toString());
      final lat = double.tryParse(c[1].toString());
      if (lat == null || lon == null) throw FormatException();
      return LatLng(lat, lon);
    }).toList();
  } catch (_) {
    return [];
  }
}

// MapControllerProvider 지도조작을 위한 컨트롤러 생성
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  void moveToPoint(LatLng point, double zoom) {
    mapController.move(point, zoom);
  }
}
class mainView extends StatefulWidget {
  final String username; // username 저장
  final RouteSearchViewModel? routeSearchViewModel; // 선택적 viewModel 파라미터 추가
  final int initTabIndex; // ✅ 추가

  const mainView({super.key, required this.username, this.routeSearchViewModel, this.initTabIndex = 0,});

  @override
  _mainViewViewState createState() => _mainViewViewState();
}

class CircularButton extends StatefulWidget {
  final String svgPath;
  final Color colorOn;
  final Color colorOff;
  final int widthSize;
  final int heightSize;
  final VoidCallback onTap; // ? onTap을 VoidCallback으로 추가

  const CircularButton({
    Key? key,
    required this.svgPath,
    required this.colorOn,
    required this.colorOff,
    required this.widthSize,
    required this.heightSize,
    required this.onTap, // ? onTap을 생성자로 받음
  }) : super(key: key);

  @override
  _CircularButtonState createState() => _CircularButtonState();
}



class _mainViewViewState extends State<mainView> with TickerProviderStateMixin {

  late RouteSearchViewModel _routeSearchViewModel;    //[GIS] 항행이력 조회 모델
  final MapControllerProvider _mapControllerProvider = MapControllerProvider();

  int? _selectedVesselMmsi;  // 항적을 그려주고 있는 선박의 MMSI를 저장하는 변수 추가

  bool _isTrackingEnabled = false;  // 항적 표시 활성화 플래그를 클래스 내부 변수로 이동

  bool isOtherVesselsVisible = true; // 기본값은 다른 선박이 보이는 상태
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final LocationService _locationService = LocationService();
  final UpdatePoint _UpdatePoint = UpdatePoint();
  bool positionStreamStarted = false;
  late FirebaseMessaging messaging;
  late String fcmToken; // FCM 토큰 저장 변수 추가
  LatLng? _currentPosition;

  bool isWaveSelected = true;        // 파고 선택 여부
  bool isVisibilitySelected = true;  // 시정 선택 여부
  Timer? _timer; // Timer 변수 선언
  bool _isFCMListenerRegistered = false; //fcm lintener

  //화면 깜빡임
  late AnimationController _flashController;
  bool _isFlashing = false;

  Timer? _vesselUpdateTimer; //타선박 위치 갱신용 타이머 변수
  Timer? _routeUpdateTimer;  // 항로 갱신용 타이머 변수

  /// 바텀시트가 닫혔을 때 공통으로 호출할 리셋 로직
  void _resetNavigationHistory() {
    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);
    setState(() {
      _selectedIndex = 0;
      selectedIndex = 0;
    });
  }

  // 현재 표시중인 팝업을 관리하는 Map 추가
  Map<String, bool> _activePopups = {
    'turbine_entry_alert': false,
    'weather_alert': false,
    'submarine_cable_alert': false,
  };

  @override
  void initState() {
    super.initState();

    // 전달받은 viewModel이 있으면 사용하고, 없으면 새로 생성
    _routeSearchViewModel = widget.routeSearchViewModel ?? RouteSearchViewModel();

    // ✅ 이 두 줄을 꼭 추가해!
    selectedIndex = widget.initTabIndex;
    _selectedIndex = widget.initTabIndex;

    // Firebase Messaging 초기화
    messaging = FirebaseMessaging.instance;

    // FCM 토큰 초기화 추가
    messaging.getToken().then((token) {
      fcmToken = token!;
    });

    // 화면이 완전히 빌드된 후 선박 데이터 로드 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVesselDataAndUpdateMap(); // 최초 데이터 로드 및 이동
      // 3초마다 데이터 갱신
      _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _loadVesselDataAndUpdateMap(); // 주기적 데이터 로드
      });
    });

    // 터빈진입 && 해저케이블진입 깜빡임 애니메이션 컨트롤러 초기화
    _flashController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isFlashing) {
          _flashController.forward();
        }
      }
    });

    // 중요: 화면이 완전히 렌더링된 후 권한 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 1000), () {
        _requestPermissionsSequentially();
      });
    });

    //Firebase Cloud Messaging (FCM) 포그라운드 알림 수신 리스너
    if (!_isFCMListenerRegistered) {
      _isFCMListenerRegistered = true;

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final data = message.data;
        final type = data['type'];

        _showForegroundNotification(message);

        //알림 type 종류에 따라 팝업 화면 다르게 분기
        if (type == 'turbine_entry_alert' && !_activePopups['turbine_entry_alert']!) {
          _activePopups['turbine_entry_alert'] = true;
          _startFlashing();
          _showRosPopup(context, message.notification?.title ?? '알림', message.notification?.body ?? '새로운 메시지');
        } else if (type == 'weather_alert' && !_activePopups['weather_alert']!) {
          _activePopups['weather_alert'] = true;
          _showWeatherPopup(context, message.notification?.title ?? '알림', message.notification?.body ?? '새로운 메시지');
        } else if (type == 'submarine_cable_alert' && !_activePopups['submarine_cable_alert']!) {
          _activePopups['submarine_cable_alert'] = true;
          _startFlashing();
          _showMarinPopup(context, message.notification?.title ?? '알림', message.notification?.body ?? '새로운 메시지');
        }
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    });

    // 파고와 시정 데이터 가져오기
    Provider.of<RosNavigationViewModel>(context, listen: false).getWeatherInfo();

    // 파고 알람 데이터 30초마다 데이터 갱신
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      // 기존 값 저장
      final prevWave = Provider.of<RosNavigationViewModel>(context, listen: false).wave;
      final prevVisibility = Provider.of<RosNavigationViewModel>(context, listen: false).visibility;

      Provider.of<RosNavigationViewModel>(context, listen: false).getWeatherInfo().then((_) {
        // 실제로 값이 변경되었는지 확인
        if (mounted) {
          setState(() {
          });
        }
      }).catchError((error) {

      });
    });

    // 항행경보 알림 데이터 가져오기
    Provider.of<RosNavigationViewModel>(context, listen: false).getNavigationWarnings();
  }

  //선박정보 표시
  TableRow _infoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
      ],
    );
  }

//선박정보 팝업에서 항로 조회 버튼 함수
  Future<void> routePop(BuildContext context, VesselSearchModel vessel) {
    double currentZoom = _mapControllerProvider.mapController.camera.zoom;
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: getSize300()),
      pageBuilder: (BuildContext context, Animation<double> animation,Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: getSize26().toDouble(), // 팝업의 Top 위치 설정
                left: getSize20().toDouble(), // 왼쪽 기준 위치 설정
                right: getSize20().toDouble(), // 오른쪽 기준 위치 설정
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(getSize20().toDouble()),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow:  [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: getSize10().toDouble(),
                          offset: Offset(getSize0().toDouble(), getSize4().toDouble()),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬 적용
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                            children: [
                              TextWidgetString('선박 정보',getTextleft(),getSize24(),getTextbold(),getColorblack_type1()),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero, // 패딩 제거
                                  minimumSize: Size(getSize24().toDouble(), getSize24().toDouble()), // 최소 크기 설정 (선택 사항)
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                                ),
                                child: SvgPicture.asset(
                                  'assets/kdn/ros/img/close_popup.svg',
                                  height: getSize24().toDouble(),
                                  width: getSize24().toDouble(),
                                  fit: BoxFit.contain,
                                ),
                              )
                            ]

                        ),
                        SizedBox(height: getSize12().toDouble()),
                        Container(
                          child: Table(
                            columnWidths: { 0: FixedColumnWidth(80), 1: FlexColumnWidth(), },
                            children: [
                              _infoRow('선박명', vessel.ship_nm ?? '-'),
                              _infoRow('MMSI', vessel.mmsi?.toString() ?? '-'),
                              _infoRow('선종', vessel.cd_nm ?? '-'),
                              _infoRow('흘수', vessel.draft != null ? '${vessel.draft} m' : '-'),
                              _infoRow('대지속도', vessel.sog != null ? '${vessel.sog} kn' : '-'),
                              _infoRow('대지침로', vessel.cog != null ? '${vessel.cog}°' : '-'),
                            ],
                          ),
                        ),
                        SizedBox(height: getSize32().toDouble()),
                        if (!_routeSearchViewModel.isNavigationHistoryMode) ...[
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final loadingContext = Navigator.of(context);

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext dialogContext) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      );
                                      try {
                                        if (vessel.mmsi != null) {
                                          // 기존 궤적 초기화는 예측항로 버튼 누를 때만
                                          _routeSearchViewModel.clearRoutes();
                                          _routeSearchViewModel.setNavigationHistoryMode(false);
                                          _stopRouteUpdates();

                                          await _routeSearchViewModel.getVesselRoute(
                                              mmsi: vessel.mmsi,
                                              regDt: DateFormat('yyyy-MM-dd').format(DateTime.now())
                                          );
                                          _mapControllerProvider.mapController.move(
                                            LatLng(vessel.lttd ?? 35.3790988, vessel.lntd ?? 126.167763),
                                            12.0,
                                          );
                                          _selectedVesselMmsi = vessel.mmsi;  // 선택된 선박의 MMSI 저장
                                          _isTrackingEnabled = true;          // 항적 표시 활성화
                                          _vesselUpdateTimer?.cancel();       // 기존에 실행되던 선박 위치 표시 타이머도 초기화
                                          _routeUpdateTimer?.cancel();        // 기존에 실행 중인 타이머가 있다면 취소

                                          final startTime = DateTime.now();

                                          // 선박 위치 갱신 타이머 재시작
                                          _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
                                            _loadVesselDataAndUpdateMap();
                                          });
                                          
                                          // 3초마다 데이터 갱신하는 타이머 시작
                                          _routeUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
                                            try {
                                              if (_isTrackingEnabled) {
                                                // 플래그 체크 없이 항상 갱신
                                                _routeSearchViewModel.getVesselRoute(
                                                    mmsi: _selectedVesselMmsi!,
                                                    regDt: DateFormat('yyyy-MM-dd').format(DateTime.now())
                                                );

                                                // UI 업데이트
                                                if (mounted) {
                                                  setState(() {
                                                    // 여기서는 상태 변경 없이 화면만 갱신
                                                  });
                                                }
                                              }
                                            } catch (e) {

                                            }
                                          });

                                        }

                                        loadingContext.pop(); // 로딩 팝업 닫기
                                        Navigator.of(context).pop(); // 본래 팝업 닫기
                                      } catch (e) {
                                        Navigator.of(context).pop(); // 로딩 팝업 닫기
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('예측항로 로딩 중 오류 발생')),
                                        );
                                      }
                                    },
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

                                SizedBox(width: getSize12().toDouble()), // 버튼 사이 간격
                              ],
                            ),
                          ),
                        ]
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

  //선박 데이터 로드 및 이동 메소드
  // 1️⃣ async/await 스타일로 변경
  Future<void> _loadVesselDataAndUpdateMap() async {
    try {
      final mmsi = context.read<UserState>().mmsi;
      final role = context.read<UserState>().role;
      if (mmsi == null) return;

      // 2️⃣ 한 번만 데이터 가져오기
      if (role == 'ROLE_USER') {
        await context.read<VesselSearchViewModel>().getVesselList(mmsi: mmsi);
      } else {
        await context.read<VesselSearchViewModel>().getVesselList(mmsi: 0);
      }

      // 3️⃣ 마침내 한 번만 리빌드
      if (!mounted) return;
      setState(() {
        // vesselsViewModel.vessels 안에
        // escapeRouteGeojson 까지 모두 들어있습니다.
      });
    } catch (e) {
      debugPrint('[_loadVesselDataAndUpdateMap] error: $e');
    }
  }


// 추가: 권한을 순차적으로 요청하는 메소드
  Future<void> _requestPermissionsSequentially() async {

    // 먼저 권한 상태 확인
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always) {
      print("✅ 이미 위치 권한이 허용되어 있습니다.");
      // 위치 권한이 이미 있으면 바로 위치 업데이트
      await _updateCurrentLocation();
    } else {
      // 위치 권한이 없는 경우에만 요청
      await Future.delayed(Duration(milliseconds: 500));
      await PointRequestUtil.requestPermissionUntilGranted(context);
      await _updateCurrentLocation();
    }

    // 알림 권한 확인
    NotificationSettings notifSettings = await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ 이미 알림 권한이 허용되어 있습니다.");
    } else {
      // 알림 권한이 없는 경우에만 요청
      await Future.delayed(Duration(milliseconds: 500));
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
      await _requestNotificationPermission();
    }
  }

  //화면이 종료될때 타이머 취소
  @override
  void dispose() {
    _flashController.dispose();
    _timer?.cancel();
    _routeUpdateTimer?.cancel(); // 추가: 선박 위치 갱신 타이머 취소
    super.dispose();
  }

  // 항로 갱신 중지 및 데이터 초기화 메소드
  void _stopRouteUpdates() {
    // ViewModel 상태 리셋
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);

    // 1) 즉시 한 번 실행
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = null;

    // UI 리셋
    setState(() {
      _selectedVesselMmsi = null;
      _isTrackingEnabled = false; // 항적 표시 비활성화
    });

    // 선박 위치 갱신 타이머가 없으면 재시작
    if (_vesselUpdateTimer == null) {
      _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _loadVesselDataAndUpdateMap();
      });
    }


  }

  // 권한 요청
  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ 알림 권한 거부됨');
    } else {
      print('⚠️ 알림 권한 상태: ${settings.authorizationStatus}');
    }
  }

  Future<void> _updateCurrentLocation() async {
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  //  연속 알람시 구별
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max, // 🟦 Heads-up 알림
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,

      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '알림 내용이 없습니다.',
      platformChannelSpecifics,
    );
  }

  void _startFlashing() {
    setState(() {
      _isFlashing = true;
    });
    _flashController.forward();
  }

  void _stopFlashing() {
    setState(() {
      _isFlashing = false;
    });
    if (_flashController.isAnimating) {
      _flashController.stop();
    }
  }

  // 기상알림 팝업 (터빈 스타일 UI + 서버 메시지 사용)
  void _showWeatherPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 310,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/kdn/home/img/red_triangle-exclamation.svg',
                  width: 60,
                  height: 60,
                ),
                SizedBox(height: 8),
                Text(
                  title, // 서버에서 받은 제목
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDF2B2E),
                    height: 1.0,
                    letterSpacing: 0,
                    fontFamily: 'Pretendard Variable',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  width: 300,
                  child: Text(
                    message, // 서버에서 받은 메시지
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                      height: 1.0,
                      letterSpacing: 0,
                      fontFamily: 'Pretendard Variable',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(height: 32),
                Container(
                  width: 270,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      _stopFlashing();
                      _activePopups['weather_alert'] = false;  // 이 줄 추가
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Color(0xFF5CA1F6), width: 1),
                      ),
                      elevation: 0,
                      minimumSize: Size(270, 48),
                    ),
                    child: Text(
                      "알람 종료하기",
                      style: TextStyle(
                        color: Color(0xFF5CA1F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //터빈진입 알림 팝업
  void _showRosPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 310, // 전체 팝업 너비
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20), // 팝업 패딩
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/kdn/home/img/red_triangle-exclamation.svg',
                  width: 60,
                  height: 60,
                ),
                SizedBox(height: 8), // 간격
                Text(
                  "터빈 구역 진입 금지 경고",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDF2B2E),
                    height: 1.0,
                    letterSpacing: 0,
                    fontFamily: 'Pretendard Variable',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8), // 간격
                Container(
                  width: 300, // 너비를 더 키움
                  child: Text(
                    "터빈 진입 금지 구역입니다. 지금 바로 우회하세요.",
                    style: TextStyle(
                      fontSize: 12, // 폰트 크기 약간 줄임
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                      height: 1.0,
                      letterSpacing: 0,
                      fontFamily: 'Pretendard Variable',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis, // visible 대신 ellipsis 사용
                    maxLines: 2, // 최대 2줄 허용 (1줄로 표시될 수 있지만, 필요하면 2줄 사용)
                  ),
                ),
                SizedBox(height: 32), // 내용과 버튼 사이 간격
                Container(
                  width: 270, // 버튼 너비
                  height: 48, // 버튼 높이
                  child: ElevatedButton(
                    onPressed: () {
                      _stopFlashing();
                      _activePopups['turbine_entry_alert'] = false;  // 이 줄 추가
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 패딩 수정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Color(0xFF5CA1F6), width: 1),
                      ),
                      elevation: 0,
                      minimumSize: Size(270, 48), // 버튼 최소 크기 설정
                    ),
                    child: Text(
                      "알람 종료하기",
                      style: TextStyle(
                        color: Color(0xFF5CA1F6),
                        fontSize: 14, // 폰트 크기 약간 줄임
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.visible, // 텍스트가 잘리지 않도록
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //해저케이블진입 알림 팝업
  void _showMarinPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 310, // 전체 팝업 너비
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20), // 팝업 패딩
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/kdn/home/img/red_triangle-exclamation.svg',
                  width: 60,
                  height: 60,
                ),
                SizedBox(height: 8), // 간격
                Text(
                  "해저케이블 구역 진입 경보",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDF2B2E),
                    height: 1.0,
                    letterSpacing: 0,
                    fontFamily: 'Pretendard Variable',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8), // 간격
                Container(
                  width: 300, // 너비를 더 키움
                  child: Text(
                    "헤저케이블 구역입니다. 지금 바로 우회하세요.",
                    style: TextStyle(
                      fontSize: 12, // 폰트 크기 약간 줄임
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                      height: 1.0,
                      letterSpacing: 0,
                      fontFamily: 'Pretendard Variable',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis, // visible 대신 ellipsis 사용
                    maxLines: 2, // 최대 2줄 허용 (1줄로 표시될 수 있지만, 필요하면 2줄 사용)
                  ),
                ),
                SizedBox(height: 32), // 내용과 버튼 사이 간격
                Container(
                  width: 270, // 버튼 너비
                  height: 48, // 버튼 높이
                  child: ElevatedButton(
                    onPressed: () {
                      _stopFlashing();
                      _activePopups['submarine_cable_alert'] = false;  // 이 줄 추가
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 패딩 수정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Color(0xFF5CA1F6), width: 1),
                      ),
                      elevation: 0,
                      minimumSize: Size(270, 48), // 버튼 최소 크기 설정
                    ),
                    child: Text(
                      "알람 종료하기",
                      style: TextStyle(
                        color: Color(0xFF5CA1F6),
                        fontSize: 14, // 폰트 크기 약간 줄임
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.visible, // 텍스트가 잘리지 않도록
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int selectedIndex = 0; // 선택된 인덱스를 클래스 변수로 선언
  Color getItemColor(int index) {
    return selectedIndex == index ? getColorgray_Type8() : getColorblack_type2();
  }
  int _selectedIndex = 0;
  PersistentBottomSheetController? _bottomSheetController;

  void _onItemTapped(int index, BuildContext context) {
    // 선택된 탭을 먼저 변경
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
    });

    // 기존 바텀시트가 있으면 닫기
    if (_bottomSheetController != null) {
      _bottomSheetController!.close(); // null이 아님을 명시하는 ! 연산자 추가
      _bottomSheetController = null;
    }

    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(true);

    // 홈 탭이 아닌 경우에만 바텀시트 표시
    if (index != 0) {
      if (index == 1) {
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
              (context) => WillPopScope(
            onWillPop: () async {
              setState(() {
                _selectedIndex = 0;
                selectedIndex = 0;
              });
              return true;
            },
            child: mainViewWindy(context, onClose: () {
              setState(() {
                _selectedIndex = 0;
                selectedIndex = 0;
              });
            }),
          ),
          backgroundColor: getColorblack_type3(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        );
      } else if (index == 2) {
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
              (context) => WillPopScope(
            onWillPop: () async {
              // 뒤로가기 시에도 1번 기능 완전 초기화
              _resetNavigationHistory();
              return true;
            },
            child: MainViewNavigationSheet(onClose: () {
            // 닫기 버튼 눌렀을 때도 1번 기능 초기화
              _resetNavigationHistory();
              }, resetDate: true, // 여기서는 날짜를 초기화함
                 resetSearch: true, // MMSI, 선박명 초기화함

            ),

          ),
          backgroundColor: getColorblack_type3(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        );

        _bottomSheetController?.closed.then((_) {
          _resetNavigationHistory();
        });
      } else if (index == 3) {
        Navigator.push(
          context,
          createSlideTransition(
            MemberInformationView(username: widget.username,),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
        });
      }
    }
  }

  void _showCustomPopuplive(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<Position>(
              stream: _UpdatePoint.toggleListening(), // 실시간 위치 스트림
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("현재 위치를 가져오는 중..."),
                    ],
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("현재 위치를 가져올 수 없습니다.", style: TextStyle(color: Colors.red)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("닫기"),
                      ),
                    ],
                  );
                } else {
                  Position position = snapshot.data!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("실시간 위치", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text("위도: ${position.latitude}"),
                      Text("경도: ${position.longitude}"),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("닫기"),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCustomPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder<Position?>(
              future: _locationService.getCurrentPosition(), // 현재 위치 가져오기
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("현재 위치를 가져오는 중..."),
                    ],
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("현재 위치를 가져올 수 없습니다.", style: TextStyle(color: Colors.red)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("닫기"),
                      ),
                    ],
                  );
                } else {
                  Position position = snapshot.data!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("현재 위치", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text("위도: ${position.latitude}"),
                      Text("경도: ${position.longitude}"),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("닫기"),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role; //로그인한 사용자 역할 가져오기
    final mmsi = context.watch<UserState>().mmsi; //로그인한 사용자 mmsi 가져오기

    // VesselSearchViewModel 추가 - 역할에 따라 자신의 선박 또는 모든 선박 조회
    final vesselsViewModel = context.watch<VesselSearchViewModel>();
    List<VesselSearchModel> vessels; // 여기에 추가

    if(role == 'ROLE_USER'){
      // ROLE_USER인 경우: 자신의 MMSI 선박만 조회
      vessels = vesselsViewModel.vessels.where((vessel) => vessel.mmsi == mmsi).toList();
    } else {
      // 관리자인 경우: 모든 선박 조회
      vessels = vesselsViewModel.vessels;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouteSearchViewModel>.value(
          value: _routeSearchViewModel,
        ),
        ChangeNotifierProvider<MapControllerProvider>.value(
          value: _mapControllerProvider,
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Consumer를 사용하여 Provider에서 predRoutes를 가져와 Polyline으로 그린 FlutterMap
            Consumer<RouteSearchViewModel>(
              builder: (context, routeSearchViewModel, child) {

                // Consumer 또는 Provider.of를 통해 동일 인스턴스를 받아와 FlutterMap에 전달
                final mapController = Provider.of<MapControllerProvider>(context).mapController;
                //point 줄이기 작업(변침+14노트 선박은 AIS신호가 4초마다 들어오는 선박 때문에 point가 너무 많이찍이고, 지도가 느려지기 때문에 줄임)
                int cnt = 20;
                if (routeSearchViewModel.pastRoutes.length <= cnt) cnt = 1;

                var pastRouteLine = <LatLng>[]; // 과거항적 LatLng 리스트 생성

                // 데이터가 있는 경우
                if (routeSearchViewModel.pastRoutes.isNotEmpty) {
                  // 첫 번째 포인트 추가
                  final firstPoint = routeSearchViewModel.pastRoutes.first;
                  pastRouteLine.add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));

                  // 중간 포인트들 추가 (인덱스 1부터 마지막-1까지)
                  if (routeSearchViewModel.pastRoutes.length > 2) {
                    for (int i = 1; i < routeSearchViewModel.pastRoutes.length - 1; i++) {
                      if (i % cnt == 0) {
                        final route = routeSearchViewModel.pastRoutes[i];
                        pastRouteLine.add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
                      }
                    }
                  }

                  // 마지막 포인트 추가
                  final lastPoint = routeSearchViewModel.pastRoutes.last;
                  pastRouteLine.add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));
                }


                //예측항로 LatLng 리스트 생성
                var predRouteLine = <LatLng>[];

                // 기존 예측항로 포인트들 추가
                predRouteLine.addAll(
                    routeSearchViewModel.predRoutes
                        .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
                );

                // 과거항적의 마지막 포인트가 있다면 예측항로 리스트의 맨 앞에 추가
                if (predRouteLine.isNotEmpty) {
                  pastRouteLine.add(predRouteLine.first);
                }

                //_isTrackingEnabled -> main지도에서 선박 클릭을 통해 그려진 과거항적 및 예측항로
                //isNavigationHistoryMode -> 항행이력 탭을 통해 그려진 과거항적
                //즉, refresh버튼을 눌러서 과거항적 및 예측항로를 지웠고, 항행이력 탭을 통해 그려진 과거항적이 아닌경우 항적 지우기!
                if (!_isTrackingEnabled && !routeSearchViewModel.isNavigationHistoryMode) {
                  pastRouteLine.clear();
                  predRouteLine.clear();
                }

                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? LatLng(35.374509, 126.132268),
                    initialZoom: 12.0,
                    maxZoom: 14.0, // 최대 줌 레벨 설정
                    minZoom: 5.5,  // 필요한 경우 최소 줌 레벨도 설정 가능
                    // 회전 비활성화 설정
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (MapPosition position, bool hasGesture) {

                    },
                  ),
                  children: [
                    //전자해도 수심면 레이어
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: ['vms_space:enc_map'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: ['vms_space:t_enc_sou_sp01'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    //터빈 레이어
                    TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                        layers: ['vms_space:t_gis_tur_sp01'],
                        format: 'image/png',
                        transparent: true,
                        version: '1.1.1',
                      ),
                    ),
                    //과거항적 선 레이어
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pastRouteLine,
                          strokeWidth: 1.0,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    //과거항적 포인트 레이어
                    MarkerLayer(
                      markers: pastRouteLine.asMap().entries.map((entry) {
                        int index = entry.key;
                        LatLng point = entry.value;

                        // 과거항적의 첫 시작점을 큰 노란색 원으로 표시
                        if (index == 0) {
                          return Marker(
                            point: point,
                            width: 10,  // 더 큰 크기
                            height: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,  // 노란색
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          );
                        }// 나머지 모든 포인트는 작은 오렌지색 원으로 표시
                        else {
                          return Marker(
                            point: point,
                            width: 4,
                            height: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 0.5),
                              ),
                            ),
                          );
                        }
                      }).toList(),
                    ),
                    //예측항로 선 레이어
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: predRouteLine,
                          strokeWidth: 1.0,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    //예측항로 포인트 레이어
                    MarkerLayer(
                      markers: predRouteLine.map((point) {
                        return Marker(
                          point: point,
                          width: 4,
                          height: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 0.5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //퇴각항로 레이어
                    // 1. 점선 경로
                    PolylineLayer(
                      polylineCulling: false,
                      polylines: vessels
                          .where((v) => v.escapeRouteGeojson != null)
                          .map((v) {
                        final pts = parseGeoJsonLineString(v.escapeRouteGeojson!);
                        return Polyline(
                          points: pts,
                          strokeWidth: 2.0,
                          color: Colors.black,
                          isDotted: true,
                        );
                      }).toList(),
                    ),

                    // 2. 끝점에 삼각형
                    PolygonLayer(
                      polygons: vessels
                          .where((v) => v.escapeRouteGeojson != null)
                          .map((v) {
                        final pts = parseGeoJsonLineString(v.escapeRouteGeojson!);
                        if (pts.length < 2) return null;
                        final end = pts.last;
                        final prev = pts[pts.length - 2];

                        // 1) 진행 벡터와 단위벡터 u
                        final dx = end.longitude - prev.longitude;
                        final dy = end.latitude  - prev.latitude;
                        final dist = sqrt(dx * dx + dy * dy);
                        if (dist == 0) return null;
                        final ux = dx / dist;
                        final uy = dy / dist;

                        // 2) 수직 단위벡터 (왼쪽)
                        final vx = -uy;
                        final vy = ux;

                        // 3) 삼각형 크기 설정 (size: 높이)
                        const double size = 0.0005;

                        // 4) 꼭짓점 계산
                        // apex: 진행 방향으로 size만큼 전진
                        final apex = LatLng(
                          end.latitude  + uy * size,
                          end.longitude + ux * size,
                        );

                        // baseCenter: 뒤쪽으로 size*0.5만큼
                        final baseCenter = LatLng(
                          end.latitude  - uy * (size * 0.5),
                          end.longitude - ux * (size * 0.5),
                        );

                        // base half-width: 정삼각형 한 변 = size*2/sqrt(3) ⇒ half-width = (변/2) = size/√3
                        final halfWidth = size / sqrt(3);

                        final b1 = LatLng(
                          baseCenter.latitude  + vy * halfWidth,
                          baseCenter.longitude + vx * halfWidth,
                        );
                        final b2 = LatLng(
                          baseCenter.latitude  - vy * halfWidth,
                          baseCenter.longitude - vx * halfWidth,
                        );

                        return Polygon(
                          points: [ apex, b1, b2 ],
                          color: Colors.black,
                          borderColor: Colors.black,
                          borderStrokeWidth: 1,
                          isFilled: true,
                        );
                      })
                          .where((poly) => poly != null)
                          .cast<Polygon>()
                          .toList(),
                    ),
                    //현재 선박 레이어
                    MarkerLayer(
                      markers: vessels
                          .where((vessel) => vessel.mmsi == mmsi) // 내 선박만 필터링
                          .map((vessel) {
                        return Marker(
                          point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                          width: 25,
                          height: 25,
                          child: Transform.rotate(
                            angle: (vessel.cog ?? 0) * (pi / 180), // COG를 라디안으로 변환
                            child: SvgPicture.asset(
                              'assets/kdn/home/img/myVessel.svg',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 다른 선박 레이어 (항상 포함되지만 가시성 제어)
                    Opacity(
                      opacity: isOtherVesselsVisible ? 1.0 : 0.0, // 가시성 제어
                      // 완전히 투명하게 만들면 상호작용도 불가능해짐
                      child: IgnorePointer(
                        ignoring: !isOtherVesselsVisible, // 보이지 않을 때는 터치 이벤트도 무시
                        child: MarkerLayer(
                          markers: vessels
                              .where((vessel) => vessel.mmsi != mmsi)
                              .map((vessel) {
                            return Marker(
                              point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                              width: 25,
                              height: 25,
                              child: GestureDetector(
                                onTap: () {
                                  // 선박 정보 팝업 표시
                                  routePop(context, vessel);
                                },
                                child: Transform.rotate(
                                  angle: (vessel.cog ?? 0) * (pi / 180),
                                  child: SvgPicture.asset(
                                    'assets/kdn/home/img/otherVessel.svg',
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // 나머지 위젯들 (버튼, 네비게이션바 등)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<RosNavigationViewModel>(
                    builder: (context, viewModel, _) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: getSize56().toDouble(),
                          bottom: getSize32().toDouble(),
                          right: getSize20().toDouble(),
                          left: getSize20().toDouble(),
                        ),
                        child: Column(
                          children: [
                            // 파고 버튼
                            _buildCircularButton_slide_on(
                              'assets/kdn/home/img/top_pago_img.svg',
                              viewModel.getWaveColor(viewModel.wave),
                              getSize56(),
                              getSize56(),
                              '파고',
                              getSize160(),
                              viewModel.getFormattedWaveThresholdText(viewModel.wave),
                              isSelected: isWaveSelected,
                              onTap: () {
                                setState(() {
                                  isWaveSelected = !isWaveSelected;
                                });
                              },
                            ),

                            // 시정 버튼
                            _buildCircularButton_slide_on(
                              'assets/kdn/home/img/top_visibility_img.svg',
                              viewModel.getVisibilityColor(viewModel.visibility),
                              getSize56(),
                              getSize56(),
                              '시정',
                              getSize160(),
                              viewModel.getFormattedVisibilityThresholdText(viewModel.visibility),
                              isSelected: isVisibilitySelected,
                              onTap: () {
                                setState(() {
                                  isVisibilitySelected = !isVisibilitySelected;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),


            Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: getSize20().toDouble()),
                    child: Row(
                      children: [
                        Spacer(),
                        Column(
                          children: [
                            Consumer<RouteSearchViewModel>(
                              builder: (context, routeViewModel, _) {
                                //과거항적 및 예측항로가 있는지 확인하고, 과거항적을 mainView에서 조회했는지/mainview_navigation에서 조회했는지 체크 isNavigationHistoryMode=true면 항행이력 과거항적 조회
                                if ((routeViewModel.pastRoutes.isNotEmpty || routeViewModel.predRoutes.isNotEmpty) && !routeViewModel.isNavigationHistoryMode && _isTrackingEnabled) {
                                  return Column(
                                    children: [
                                      CircularButton(
                                        svgPath: 'assets/kdn/home/img/refresh.svg',
                                        colorOn: getColorgray_Type8(),
                                        colorOff: getColorgray_Type8(),
                                        widthSize: getSize56(),
                                        heightSize: getSize56(),
                                        onTap: () {
                                          _stopRouteUpdates();
                                          // 사용자에게 피드백 제공
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('항적 데이터가 초기화되었습니다.'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 12),
                                    ],
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                            //관리자만 접근 가능
                            if (role == 'ROLE_ADMIN') ...[
                              CircularButton(
                                svgPath: 'assets/kdn/home/img/bouttom_ship_img.svg',
                                colorOn: getColorgray_Type9(),
                                colorOff: getColorgray_Type8(),
                                widthSize: getSize56(),
                                heightSize: getSize56(),
                                onTap: () {
                                  setState(() {
                                    isOtherVesselsVisible = !isOtherVesselsVisible;
                                  });
                                  // 관리자 전용 기능
                                },
                              ),
                              SizedBox(height: 12),
                            ],
                            // 현재 위치 버튼 - Builder로 감싸서 MultiProvider의 하위 컨텍스트 전달
                            Builder(
                              builder: (context) {
                                final mmsi = context.read<UserState>().mmsi; // 현재 사용자 mmsi 값
                                final vessels = context.watch<VesselSearchViewModel>().vessels; // 선박 목록을 감시

                                // mmsi가 없거나 선박 목록에 사용자의 mmsi가 없으면 버튼을 표시하지 않음
                                if (mmsi == null || !vessels.any((vessel) => vessel.mmsi == mmsi)) {
                                  return SizedBox.shrink(); // 빈 위젯 반환
                                }

                                return CircularButton(
                                  svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
                                  colorOn: getColorgray_Type8(),
                                  colorOff:getColorgray_Type8(),
                                  widthSize: getSize56(),
                                  heightSize: getSize56(),
                                  onTap: () async {
                                    if (mmsi != null) {
                                      // 해당 mmsi의 선박 목록을 조회합니다.
                                      if(role == 'ROLE_ADMIN'){
                                        //관리자일 경우
                                        await context.read<VesselSearchViewModel>().getVesselList(mmsi: 0);
                                      }else{
                                        await context.read<VesselSearchViewModel>().getVesselList(mmsi: mmsi);
                                      }

                                      final vessels = context.read<VesselSearchViewModel>().vessels;

                                      VesselSearchModel? myVessel;

                                      try {
                                        myVessel = vessels.firstWhere(
                                              (vessel) => vessel.mmsi == mmsi,
                                        );
                                      } catch (e) {
                                        myVessel = null;
                                      }

                                      // myVessel 객체가 유효하면 그 좌표를 사용하여 지도 중심을 이동합니다.
                                      if (myVessel != null || myVessel != '') {
                                        final vesselPoint = LatLng(
                                          myVessel?.lttd ?? 35.3790988,  // 위도 (null이면 기본값 사용)
                                          myVessel?.lntd ?? 126.167763,   // 경도 (null이면 기본값 사용)
                                        );

                                        // Builder 내의 context는 MultiProvider 자식이므로 Provider 접근이 가능합니다.
                                        final mapController = Provider.of<MapControllerProvider>(context, listen: false).mapController;
                                        mapController.move(vesselPoint, mapController.camera.zoom);
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            // 실시간 위치 딜레이 있음
                            CircularButton(
                              svgPath: 'assets/kdn/home/img/ico_home.svg',
                              colorOn: getColorgray_Type8(),
                              colorOff: getColorgray_Type8(),
                              widthSize: getSize56(),
                              heightSize: getSize56(),
                              onTap: () {
                                //_showCustomPopuplive(context);
                                _mapControllerProvider.mapController.moveAndRotate(LatLng(35.374509, 126.132268), 12.0, 0.0); // 지도를 기본 위치와 줌 레벨로 이동

                                //_routeSearchViewModel.clearRoutes(); // 과거항적과 예측항로 데이터 초기화
                                //_stopRouteUpdates();                  // 항로 업데이트 중지 및 데이터 초기화
                              },
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: getSize32().toDouble()),
                  Consumer<RosNavigationViewModel>(
                    builder: (context, viewModel, child) {
                      return Container(
                        height: 52,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: getColorred_type1(),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/kdn/ros/img/circle-exclamation_white.svg',
                              width: 24,
                              height: 24,
                            ),
                            SizedBox(width: getSize8().toDouble()),
                            Expanded(
                              child: Marquee(
                                text: viewModel.combinedNavigationWarnings,
                                style: TextStyle(
                                  color: getColorwhite_type1(),
                                  fontSize: 16,
                                  fontWeight: getText700(),
                                ),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                blankSpace: 300.0,
                                velocity: 50.0,
                                pauseAfterRound: Duration(seconds: 1),
                                startPadding: 10.0,
                                accelerationDuration: Duration(seconds: 1),
                                accelerationCurve: Curves.linear,
                                decelerationDuration: Duration(seconds: 1),
                                decelerationCurve: Curves.easeOut,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Stack의 맨 마지막에 추가 (가장 위에 렌더링되도록)
            if (_isFlashing)
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // 전체 투명
                      Container(color: Colors.transparent),

                      // 상단
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 250,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(255, 0, 0, 0.6 * _flashController.value),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 하단 (navigation bar는 안 가리게)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 250,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color.fromRGBO(255, 0, 0, 0.6 * _flashController.value),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 왼쪽
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color.fromRGBO(255, 0, 0, 0.6 * _flashController.value),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 오른쪽
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Color.fromRGBO(255, 0, 0, 0.6 * _flashController.value),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )

          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white, // 배경색 설정
            border: Border(
              top: BorderSide(color: getColorgray_Type4(), width: 1), // 상단 Border 추가
            ),
          ),
          child: Builder(
            builder: (context) => BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // 부모 Container 배경색 사용
              elevation: 0, // 그림자 제거
              selectedItemColor: getColorgray_Type8(),
              unselectedItemColor: getColorgray_Type2(),
              selectedLabelStyle: TextStyle(
                  fontSize: getSize16().toDouble(), fontWeight: getText700()),
              unselectedLabelStyle: TextStyle(
                  fontSize: getSize16().toDouble(), fontWeight: getText700()),
              currentIndex: selectedIndex,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });

                _onItemTapped(index, context);
              },
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                    child: Column(
                      children: [
                        SizedBox(height: getSize12().toDouble()),
                        Container(
                          width: getSize24().toDouble(),
                          height: getSize24().toDouble(),
                          child: SvgPicture.asset(
                            selectedIndex == 0
                                ? 'assets/kdn/ros/img/Home_on.svg'
                                : 'assets/kdn/ros/img/Home_off.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                    child: Column(
                      children: [
                        SizedBox(height: getSize12().toDouble()),
                        Container(
                          width: getSize24().toDouble(),
                          height: getSize24().toDouble(),
                          child: SvgPicture.asset(
                            selectedIndex == 1
                                ? 'assets/kdn/ros/img/cloud-sun_on.svg'
                                : 'assets/kdn/ros/img/cloud-sun_off.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  label: '기상정보',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                    child: Column(
                      children: [
                        SizedBox(height: getSize12().toDouble()),
                        Container(
                          width: getSize24().toDouble(),
                          height: getSize24().toDouble(),
                          child: SvgPicture.asset(
                            selectedIndex == 2
                                ? 'assets/kdn/ros/img/ship_on.svg'
                                : 'assets/kdn/ros/img/ship_off.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  label: '항행이력',
                ),

                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                    child: Column(
                      children: [
                        SizedBox(height: getSize12().toDouble()),
                        Container(
                          width: getSize24().toDouble(),
                          height: getSize24().toDouble(),
                          child: SvgPicture.asset(
                            selectedIndex == 3
                                ? 'assets/kdn/ros/img/user-alt-1_on.svg'
                                : 'assets/kdn/ros/img/user-alt-1_off.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  label: '마이',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildCircularButton_slide_on(
    String svgPath,
    Color color,
    int widthsize,
    int heightsize,
    String labelText,
    int widthSizeline,
    String statusText,
    {VoidCallback? onTap, bool isSelected = true}
    ) {

  return Padding(
    padding: EdgeInsets.only(bottom: getSize12().toDouble()),
    child: SizedBox(
      width: widthSizeline.toDouble(), // 최대 너비로 고정
      height: heightsize.toDouble(),
      child: Stack(
        clipBehavior: Clip.none, // 자식이 영역을 넘어가도록 허용
        children: [
          // 확장/축소되는 배경 (애니메이션)
          Positioned(
            left: 0,
            top: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: isSelected ? widthSizeline.toDouble() : widthsize.toDouble(),
              height: heightsize.toDouble(),
              decoration: BoxDecoration(
                color: getColorblack_type1(),
                borderRadius: BorderRadius.circular(getSize30().toDouble()),
              ),
            ),
          ),

          // 텍스트 영역 (확장 시에만 표시)
          if (isSelected)
            Positioned(
              left: widthsize.toDouble() + 8, // 아이콘 오른쪽 여백 추가
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(labelText, getTextleft(),
                        getSize14(), getText700(), getColorgray_Type2()),
                    TextWidgetString(statusText, getTextleft(),
                        getSize14(), getText700(), getColorwhite_type1()),
                  ],
                ),
              ),
            ),

          // 원형 아이콘 (항상 왼쪽에 고정)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: widthsize.toDouble(),
                height: heightsize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _warningPop_on(String svgPath, Color color, int widthsize,int heightsize, String labelText, int widthSizeline, context, String title,Color titleColor, String detail,Color detailColor,String alarmicon,shadowcolor) {
  return Padding(
    padding: EdgeInsets.only(bottom: getSize12().toDouble()),
    child: GestureDetector(
      onTap: () {
        // 버튼 클릭 시 동작 추가
        warningPop(context ,title,titleColor,detail,detailColor,alarmicon,shadowcolor);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widthSizeline.toDouble(),
            height: heightsize.toDouble(),


          ),
          Positioned(
            left: getSize0().toDouble(),
            child: Container(
              width: widthsize.toDouble(),
              height: heightsize.toDouble(),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                svgPath,
                width: getSize24().toDouble(),
                height: getSize24().toDouble(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _warningPop_on_detail(String svgPath, Color color, int widthsize,int heightsize, String labelText, int widthSizeline, context, String title,Color titleColor, String detail,Color detailColor,String alarmicon,shadowcolor) {
  return Padding(
    padding: EdgeInsets.only(bottom: getSize12().toDouble()),
    child: GestureDetector(
      onTap: () {
        // 버튼 클릭 시 동작 추가
        warningPopdetail(context ,title,titleColor,detail,detailColor,alarmicon, shadowcolor);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widthSizeline.toDouble(),
            height: heightsize.toDouble(),


          ),
          Positioned(
            left: getSize0().toDouble(),
            child: Container(
              width: widthsize.toDouble(),
              height: heightsize.toDouble(),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                svgPath,
                width: getSize24().toDouble(),
                height: getSize24().toDouble(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CircularButtonState extends State<CircularButton> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
        widget.onTap();  //  추가: 클릭 이벤트 실행
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.widthSize.toDouble(),
            height: widget.heightSize.toDouble(),
            decoration: BoxDecoration(
              color: isOn ? widget.colorOn : widget.colorOff,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              widget.svgPath,
              width: 24.0,
              height: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}

