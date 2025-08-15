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

// 분리한 위젯들 import
import 'package:vms_app/kdn/ros/view/widgets/circular_button.dart';
import 'package:vms_app/kdn/ros/view/widgets/weather_status_button.dart';
import 'package:vms_app/kdn/ros/view/components/warning_popups.dart';
import 'package:vms_app/kdn/ros/view/components/vessel_info_popup.dart';
import 'package:vms_app/kdn/ros/view/components/navigation_warning_bar.dart';
import 'package:vms_app/kdn/ros/view/components/map_layer_component.dart';
import 'package:vms_app/kdn/ros/view/components/bottom_navigation_component.dart';

import '../../main/model/VesselSearchModel.dart';
import '../../main/viewModel/VesselSearchViewModel.dart';
import '../../usm/viewModel/UserState.dart';
import '../viewModel/NavigationViewModel.dart';
import '../viewModel/RouteSearchViewModel.dart';

// MapControllerProvider는 그대로 유지
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  void moveToPoint(LatLng point, double zoom) {
    mapController.move(point, zoom);
  }
}

class mainView extends StatefulWidget {
  final String username;
  final RouteSearchViewModel? routeSearchViewModel;
  final int initTabIndex;

  const mainView({
    super.key,
    required this.username,
    this.routeSearchViewModel,
    this.initTabIndex = 0,
  });

  @override
  _mainViewViewState createState() => _mainViewViewState();
}

class _mainViewViewState extends State<mainView> with TickerProviderStateMixin {
  // ViewModel 및 Controller
  late RouteSearchViewModel _routeSearchViewModel;
  final MapControllerProvider _mapControllerProvider = MapControllerProvider();

  // 상태 변수들
  int? _selectedVesselMmsi;
  bool _isTrackingEnabled = false;
  bool isOtherVesselsVisible = true;
  bool isWaveSelected = true;
  bool isVisibilitySelected = true;
  int selectedIndex = 0;
  int _selectedIndex = 0;

  // Firebase 및 알림 관련
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late FirebaseMessaging messaging;
  late String fcmToken;
  bool _isFCMListenerRegistered = false;

  // 위치 서비스
  final LocationService _locationService = LocationService();
  final UpdatePoint _UpdatePoint = UpdatePoint();
  LatLng? _currentPosition;
  bool positionStreamStarted = false;

  // 타이머
  Timer? _timer;
  Timer? _vesselUpdateTimer;
  Timer? _routeUpdateTimer;

  // 애니메이션
  late AnimationController _flashController;
  bool _isFlashing = false;

  // 바텀시트
  PersistentBottomSheetController? _bottomSheetController;

  // 팝업 상태 관리
  Map<String, bool> _activePopups = {
    'turbine_entry_alert': false,
    'weather_alert': false,
    'submarine_cable_alert': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 앱 초기화 메서드
  void _initializeApp() {
    // ViewModel 초기화
    _routeSearchViewModel = widget.routeSearchViewModel ?? RouteSearchViewModel();
    selectedIndex = widget.initTabIndex;
    _selectedIndex = widget.initTabIndex;

    // Firebase 초기화
    _initializeFirebase();

    // 애니메이션 초기화
    _initializeAnimation();

    // 데이터 로드
    _loadInitialData();

    // 권한 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 1000), () {
        _requestPermissionsSequentially();
      });
    });

    // FCM 리스너 설정
    _setupFCMListener();

    // 날씨 정보 로드 및 타이머 설정
    _setupWeatherTimer();
  }

  /// Firebase 초기화
  void _initializeFirebase() {
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((token) {
      fcmToken = token!;
    });
  }

  /// 애니메이션 초기화
  void _initializeAnimation() {
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
  }

  /// 초기 데이터 로드
  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVesselDataAndUpdateMap();
      _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _loadVesselDataAndUpdateMap();
      });
    });
  }

  /// FCM 리스너 설정
  void _setupFCMListener() {
    if (!_isFCMListenerRegistered) {
      _isFCMListenerRegistered = true;

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final data = message.data;
        final type = data['type'];

        _showForegroundNotification(message);

        if (type == 'turbine_entry_alert' && !_activePopups['turbine_entry_alert']!) {
          _activePopups['turbine_entry_alert'] = true;
          _startFlashing();
          WarningPopups.showTurbineWarningPopup(
            context,
            message.notification?.title ?? '알림',
            message.notification?.body ?? '새로운 메시지',
                () {
              _stopFlashing();
              _activePopups['turbine_entry_alert'] = false;
            },
          );
        } else if (type == 'weather_alert' && !_activePopups['weather_alert']!) {
          _activePopups['weather_alert'] = true;
          WarningPopups.showWeatherWarningPopup(
            context,
            message.notification?.title ?? '알림',
            message.notification?.body ?? '새로운 메시지',
                () {
              _stopFlashing();
              _activePopups['weather_alert'] = false;
            },
          );
        } else if (type == 'submarine_cable_alert' && !_activePopups['submarine_cable_alert']!) {
          _activePopups['submarine_cable_alert'] = true;
          _startFlashing();
          WarningPopups.showSubmarineCableWarningPopup(
            context,
            message.notification?.title ?? '알림',
            message.notification?.body ?? '새로운 메시지',
                () {
              _stopFlashing();
              _activePopups['submarine_cable_alert'] = false;
            },
          );
        }
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  /// 날씨 타이머 설정
  void _setupWeatherTimer() {
    Provider.of<RosNavigationViewModel>(context, listen: false).getWeatherInfo();

    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      Provider.of<RosNavigationViewModel>(context, listen: false).getWeatherInfo().then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((error) {});
    });

    Provider.of<RosNavigationViewModel>(context, listen: false).getNavigationWarnings();
  }

  /// 선박 데이터 로드 및 지도 업데이트
  Future<void> _loadVesselDataAndUpdateMap() async {
    try {
      final mmsi = context.read<UserState>().mmsi;
      final role = context.read<UserState>().role;
      if (mmsi == null) return;

      if (role == 'ROLE_USER') {
        await context.read<VesselSearchViewModel>().getVesselList(mmsi: mmsi);
      } else {
        await context.read<VesselSearchViewModel>().getVesselList(mmsi: 0);
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('[_loadVesselDataAndUpdateMap] error: $e');
    }
  }

  /// 권한 요청
  Future<void> _requestPermissionsSequentially() async {
    // 위치 권한
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always) {
      print("✅ 이미 위치 권한이 허용되어 있습니다.");
      await _updateCurrentLocation();
    } else {
      await Future.delayed(Duration(milliseconds: 500));
      await PointRequestUtil.requestPermissionUntilGranted(context);
      await _updateCurrentLocation();
    }

    // 알림 권한
    NotificationSettings notifSettings = await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ 이미 알림 권한이 허용되어 있습니다.");
    } else {
      await Future.delayed(Duration(milliseconds: 500));
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
      await _requestNotificationPermission();
    }
  }

  /// 알림 권한 요청
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

  /// 현재 위치 업데이트
  Future<void> _updateCurrentLocation() async {
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  /// 포그라운드 알림 표시
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max,
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

  /// 깜빡임 시작
  void _startFlashing() {
    setState(() {
      _isFlashing = true;
    });
    _flashController.forward();
  }

  /// 깜빡임 중지
  void _stopFlashing() {
    setState(() {
      _isFlashing = false;
    });
    if (_flashController.isAnimating) {
      _flashController.stop();
    }
  }

  /// 항로 갱신 중지
  void _stopRouteUpdates() {
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);

    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = null;

    setState(() {
      _selectedVesselMmsi = null;
      _isTrackingEnabled = false;
    });

    if (_vesselUpdateTimer == null) {
      _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _loadVesselDataAndUpdateMap();
      });
    }
  }

  /// 하단 탭 클릭 처리 (수정된 버전)
  void _onItemTapped(int index, BuildContext context) {
    // 상태 업데이트
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
    });

    // 기존 BottomSheet 안전하게 닫기
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }

    // 라우트 관련 상태 초기화
    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(true);

    // 홈 탭이 아닌 경우에만 처리
    if (index != 0) {
      // WidgetsBinding으로 안전하게 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          switch (index) {
            case 1:
              _showWeatherBottomSheet(context);
              break;
            case 2:
              _showNavigationBottomSheet(context);
              break;
            case 3:
              _navigateToMemberInfo(context);
              break;
            default:
              _resetToHomeTab();
              break;
          }
        } catch (e) {
          debugPrint('탭 전환 오류: $e');
          _resetToHomeTab();
        }
      });
    }
  }

  /// 기상정보 BottomSheet 생성
  void _showWeatherBottomSheet(BuildContext context) {
    try {
      _bottomSheetController = Scaffold.of(context).showBottomSheet(
            (context) => WillPopScope(
          onWillPop: () async {
            _resetToHomeTab();
            return true;
          },
          child: mainViewWindy(context, onClose: () {
            _resetToHomeTab();
          }),
        ),
        backgroundColor: getColorblack_type3(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      // BottomSheet가 닫힐 때 콜백 등록
      _bottomSheetController?.closed.then((_) {
        if (mounted) {
          _resetToHomeTab();
        }
      });
    } catch (e) {
      debugPrint('기상정보 BottomSheet 생성 오류: $e');
      _resetToHomeTab();
      _showErrorSnackBar('기상정보를 불러올 수 없습니다.');
    }
  }

  /// 항행이력 BottomSheet 생성
  void _showNavigationBottomSheet(BuildContext context) {
    try {
      _bottomSheetController = Scaffold.of(context).showBottomSheet(
            (context) => WillPopScope(
          onWillPop: () async {
            _resetNavigationHistory();
            return true;
          },
          child: MainViewNavigationSheet(
            onClose: () {
              _resetNavigationHistory();
            },
            resetDate: true,
            resetSearch: true,
          ),
        ),
        backgroundColor: getColorblack_type3(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      );

      // BottomSheet가 닫힐 때 콜백 등록
      _bottomSheetController?.closed.then((_) {
        if (mounted) {
          _resetNavigationHistory();
        }
      });
    } catch (e) {
      debugPrint('항행이력 BottomSheet 생성 오류: $e');
      _resetNavigationHistory();
      _showErrorSnackBar('항행이력을 불러올 수 없습니다.');
    }
  }

  /// 마이페이지 네비게이션
  void _navigateToMemberInfo(BuildContext context) {
    try {
      Navigator.push(
        context,
        createSlideTransition(
          MemberInformationView(username: widget.username),
        ),
      ).then((_) {
        if (mounted) {
          _resetToHomeTab();
        }
      }).catchError((e) {
        debugPrint('마이페이지 네비게이션 오류: $e');
        _resetToHomeTab();
        _showErrorSnackBar('마이페이지를 열 수 없습니다.');
      });
    } catch (e) {
      debugPrint('마이페이지 네비게이션 즉시 오류: $e');
      _resetToHomeTab();
      _showErrorSnackBar('마이페이지를 열 수 없습니다.');
    }
  }

  /// 홈 탭으로 리셋
  void _resetToHomeTab() {
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
        selectedIndex = 0;
      });
    }
  }

  /// 항행이력 리셋 (기존 메서드 개선)
  void _resetNavigationHistory() {
    _stopRouteUpdates();
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);

    if (mounted) {
      setState(() {
        _selectedIndex = 0;
        selectedIndex = 0;
      });
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    _timer?.cancel();
    _routeUpdateTimer?.cancel();
    _vesselUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserState>().role;
    final mmsi = context.watch<UserState>().mmsi;
    final vesselsViewModel = context.watch<VesselSearchViewModel>();

    List<VesselSearchModel> vessels;
    if (role == 'ROLE_USER') {
      vessels = vesselsViewModel.vessels.where((vessel) => vessel.mmsi == mmsi).toList();
    } else {
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
            // 지도 레이어 컴포넌트
            MapLayerComponent(
              mapControllerProvider: _mapControllerProvider,
              routeSearchViewModel: _routeSearchViewModel,
              vessels: vessels,
              currentPosition: _currentPosition,
              isTrackingEnabled: _isTrackingEnabled,
              isOtherVesselsVisible: isOtherVesselsVisible,
              userMmsi: mmsi,
              onVesselTap: (vessel) async {
                await VesselInfoPopup.show(
                  context: context,
                  vessel: vessel,
                  routeSearchViewModel: _routeSearchViewModel,
                  mapControllerProvider: _mapControllerProvider,
                  onRouteLoaded: (mmsi) {
                    setState(() {
                      _selectedVesselMmsi = mmsi;
                      _isTrackingEnabled = true;
                    });

                    // 타이머 재시작
                    _vesselUpdateTimer?.cancel();
                    _routeUpdateTimer?.cancel();

                    _vesselUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
                      _loadVesselDataAndUpdateMap();
                    });

                    _routeUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
                      if (_isTrackingEnabled && _selectedVesselMmsi != null) {
                        _routeSearchViewModel.getVesselRoute(
                            mmsi: _selectedVesselMmsi!,
                            regDt: DateFormat('yyyy-MM-dd').format(DateTime.now())
                        );
                        if (mounted) setState(() {});
                      }
                    });
                  },
                );
              },
            ),

            // 상단 날씨 버튼들
            _buildWeatherButtons(),

            // 우측 컨트롤 버튼들
            _buildControlButtons(context, role, mmsi, vessels),

            // 하단 항행경보 바
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NavigationWarningBar(),
            ),

            // 깜빡임 효과
            if (_isFlashing) _buildFlashingEffect(),
          ],
        ),
        // ✅ Builder로 안전한 context 제공
        bottomNavigationBar: Builder(
          builder: (BuildContext builderContext) {
            return BottomNavigationComponent(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(index, builderContext),
            );
          },
        ),
      ),
    );
  }

  /// 날씨 버튼 빌드
  Widget _buildWeatherButtons() {
    return Positioned(
      top: getSize56().toDouble(),
      left: getSize20().toDouble(),
      // ✅ right 제거하여 좌측 정렬
      child: Consumer<RosNavigationViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ✅ 좌측 정렬 추가
            children: [
              WeatherStatusButton(
                svgPath: 'assets/kdn/home/img/top_pago_img.svg',
                color: viewModel.getWaveColor(viewModel.wave),
                labelText: '파고',
                statusText: viewModel.getFormattedWaveThresholdText(viewModel.wave),
                isSelected: isWaveSelected,
                onTap: () {
                  setState(() {
                    isWaveSelected = !isWaveSelected;
                  });
                },
              ),
              WeatherStatusButton(
                svgPath: 'assets/kdn/home/img/top_visibility_img.svg',
                color: viewModel.getVisibilityColor(viewModel.visibility),
                labelText: '시정',
                statusText: viewModel.getFormattedVisibilityThresholdText(viewModel.visibility),
                isSelected: isVisibilitySelected,
                onTap: () {
                  setState(() {
                    isVisibilitySelected = !isVisibilitySelected;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// 우측 컨트롤 버튼 빌드
  Widget _buildControlButtons(BuildContext context, String role, int? mmsi, List<VesselSearchModel> vessels) {
    return Positioned(
      bottom: getSize100().toDouble(),
      right: getSize20().toDouble(),
      child: Column(
        children: [
          // Refresh 버튼
          Consumer<RouteSearchViewModel>(
            builder: (context, routeViewModel, _) {
              if ((routeViewModel.pastRoutes.isNotEmpty || routeViewModel.predRoutes.isNotEmpty)
                  && !routeViewModel.isNavigationHistoryMode
                  && _isTrackingEnabled) {
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

          // 관리자 전용 버튼
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
              },
            ),
            SizedBox(height: 12),
          ],

          // 현재 위치 버튼
          Builder(
            builder: (context) {
              final mmsi = context.read<UserState>().mmsi;
              final vessels = context.watch<VesselSearchViewModel>().vessels;

              if (mmsi == null || !vessels.any((vessel) => vessel.mmsi == mmsi)) {
                return SizedBox.shrink();
              }

              return CircularButton(
                svgPath: 'assets/kdn/home/img/bouttom_location_img.svg',
                colorOn: getColorgray_Type8(),
                colorOff: getColorgray_Type8(),
                widthSize: getSize56(),
                heightSize: getSize56(),
                onTap: () async {
                  if (mmsi != null) {
                    if (role == 'ROLE_ADMIN') {
                      await context.read<VesselSearchViewModel>().getVesselList(mmsi: 0);
                    } else {
                      await context.read<VesselSearchViewModel>().getVesselList(mmsi: mmsi);
                    }

                    final vessels = context.read<VesselSearchViewModel>().vessels;
                    VesselSearchModel? myVessel;

                    try {
                      myVessel = vessels.firstWhere((vessel) => vessel.mmsi == mmsi);
                    } catch (e) {
                      myVessel = null;
                    }

                    if (myVessel != null) {
                      final vesselPoint = LatLng(
                        myVessel.lttd ?? 35.3790988,
                        myVessel.lntd ?? 126.167763,
                      );

                      final mapController = Provider.of<MapControllerProvider>(context, listen: false).mapController;
                      mapController.move(vesselPoint, mapController.camera.zoom);
                    }
                  }
                },
              );
            },
          ),
          SizedBox(height: 12),

          // 홈 버튼
          CircularButton(
            svgPath: 'assets/kdn/home/img/ico_home.svg',
            colorOn: getColorgray_Type8(),
            colorOff: getColorgray_Type8(),
            widthSize: getSize56(),
            heightSize: getSize56(),
            onTap: () {
              _mapControllerProvider.mapController.moveAndRotate(
                  LatLng(35.374509, 126.132268),
                  12.0,
                  0.0
              );
            },
          ),
        ],
      ),
    );
  }

  /// 깜빡임 효과 빌드
  Widget _buildFlashingEffect() {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        return Stack(
          children: [
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
            // 하단
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
    );
  }

  /// 아이템 색상 가져오기
  Color getItemColor(int index) {
    return selectedIndex == index ? getColorgray_Type8() : getColorblack_type2();
  }
}

// GeoJSON 파싱 함수는 그대로 유지
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