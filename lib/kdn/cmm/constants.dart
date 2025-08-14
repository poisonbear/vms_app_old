// lib/kdn/cmm/constants.dart

class AppConstants {
  // API Endpoints - dotenv에서 가져오는 키들
  static const String loginFormKey = 'kdn_loginForm_key';
  static const String roleDataKey = 'kdn_usm_select_role_data_key';
  static const String membershipKey = 'kdn_usm_insert_membership_key';
  static const String membershipSearchKey = 'kdn_usm_select_membership_search_key';
  static const String memberInfoUpdateKey = 'kdn_usm_update_membership_key';
  static const String memberInfoDataKey = 'kdn_usm_select_member_info_data';
  static const String cmdKey = 'kdn_usm_select_cmd_key';
  static const String vesselListKey = 'kdn_gis_select_vessel_List';
  static const String vesselRouteKey = 'kdn_gis_select_vessel_Route';
  static const String navigationInfoKey = 'kdn_ros_select_navigation_Info';
  static const String visibilityInfoKey = 'kdn_ros_select_visibility_Info';
  static const String navigationWarnKey = 'kdn_ros_select_navigation_warn_Info';
  static const String weatherInfoKey = 'kdn_wid_select_weather_Info';
  static const String geoServerUrl = 'GEOSERVER_URL';

  // SharedPreferences Keys
  static const String prefFirebaseToken = 'firebase_token';
  static const String prefAutoLogin = 'auto_login';
  static const String prefUsername = 'username';
  static const String prefUuid = 'uuid';
  static const String prefSessionId = 'sessionId';
  static const String prefUserRole = 'user_role';
  static const String prefUserMmsi = 'user_mmsi';

  // User Roles
  static const String roleUser = 'ROLE_USER';
  static const String roleAdmin = 'ROLE_ADMIN';

  // FCM Message Types
  static const String fcmTypeTurbine = 'turbine_entry_alert';
  static const String fcmTypeWeather = 'weather_alert';
  static const String fcmTypeCable = 'submarine_cable_alert';

  // Notification Channel
  static const String notificationChannelId = 'high_importance_channel';
  static const String notificationChannelName = 'High Importance Notifications';
  static const String notificationChannelDesc = '중요 알림을 위한 채널입니다.';

  // Map Constants
  static const double mapDefaultLat = 35.374509;
  static const double mapDefaultLng = 126.132268;
  static const double mapDefaultZoom = 12.0;
  static const double mapMaxZoom = 14.0;
  static const double mapMinZoom = 5.5;

  // Timing Constants
  static const int vesselUpdateInterval = 2; // seconds
  static const int weatherUpdateInterval = 30; // seconds
  static const int animationDuration = 300; // milliseconds
  static const int flashAnimationDuration = 500; // milliseconds

  // Validation Patterns
  static final RegExp idPattern = RegExp(r'^[a-zA-Z0-9]{8,12}$');
  static final RegExp mmsiPattern = RegExp(r'^\d{9}$');
  static final RegExp phonePattern = RegExp(r'^\d{11}$');
  static final RegExp letterPattern = RegExp(r'[a-zA-Z]');
  static final RegExp numberPattern = RegExp(r'[0-9]');
  static final RegExp specialPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Email Domain Suffix
  static const String emailDomain = '@kdn.vms.com';

  // Asset Paths
  static const String assetPathUsm = 'assets/kdn/usm/img/';
  static const String assetPathRos = 'assets/kdn/ros/img/';
  static const String assetPathHome = 'assets/kdn/home/img/';
  static const String assetPathWid = 'assets/kdn/wid/img/';

  // Messages
  static const String msgLoginRequired = '아이디 비밀번호를 입력해주세요.';
  static const String msgLoginFailed = '아이디 또는 비밀번호를 확인해주세요.';
  static const String msgServerError = '서버 오류 발생. 다시 시도해주세요.';
  static const String msgDataLoadError = '데이터를 불러오는 중 오류가 발생했습니다.';
  static const String msgNoData = '데이터가 없습니다';
  static const String msgLoading = '로딩 중...';
}

class ValidationMessages {
  static const String idFormat = '아이디는 문자, 숫자를 포함한 8자리 이상 12자리 이하로 입력하여야 합니다.';
  static const String passwordFormat = '비밀번호는 문자, 숫자 및 특수문자를 포함한 6자리 이상 12자리 이하로 입력하여야 합니다.';
  static const String mmsiFormat = '선박 MMSI 번호 형식이 올바르지 않거나\n 9자리에 벗어납니다.';
  static const String phoneFormat = '휴대폰 번호 형식이 올바르지 않거나\n 11자리에 벗어납니다.';
  static const String passwordMismatch = '비밀번호가 일치하지 않습니다.';
  static const String idDuplicateCheck = '아이디 중복 확인을 해주세요.';
  static const String idAvailable = '사용가능한 아이디 입니다.';
  static const String idAlreadyUsed = '이미 사용중인 아이디 입니다.';
  static const String requiredFieldsEmpty = '회원가입을 위해 필수 항목을 입력해주세요.';
}

class NavigationMessages {
  static const String noHistory = '해당 기간에 항행 이력이 없습니다.';
  static const String loadingRoute = '항행 경로 데이터를 불러오는 중...';
  static const String routeCleared = '항적 데이터가 초기화되었습니다.';
  static const String predictionRouteError = '예측항로 로딩 중 오류 발생';
}

class WeatherMessages {
  static const String waveNormal = '(정상)';
  static const String waveWarning = '(주의)';
  static const String waveDanger = '(심각)';
  static const String noWarnings = '금일 항행경보가 없습니다.';
}

class AlertMessages {
  static const String turbineTitle = '터빈 구역 진입 금지 경고';
  static const String turbineMessage = '터빈 진입 금지 구역입니다. 지금 바로 우회하세요.';
  static const String cableTitle = '해저케이블 구역 진입 경보';
  static const String cableMessage = '헤저케이블 구역입니다. 지금 바로 우회하세요.';
  static const String endAlarmButton = '알람 종료하기';
}