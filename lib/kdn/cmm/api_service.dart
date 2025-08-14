// lib/kdn/cmm/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';
import '../../logger.dart';

/// API 응답 래퍼 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// Dio 인스턴스 싱글톤
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal() {
    _initializeDio(); // 생성자에서 자동 초기화
  }

  late final Dio _dio;
  bool _isInitialized = false;

  void _initializeDio() {
    if (_isInitialized) return; // 중복 초기화 방지

    _dio = Dio(BaseOptions(
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
      headers: {
        'User-Agent': 'PostmanRuntime/7.43.0',
        'ngrok-skip-browser-warning': '100',
      },
    ));

    // 인터셉터 추가
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: false,
      responseHeader: false,
      logPrint: (log) => logger.d(log),
    ));

    _isInitialized = true;
  }

  /// 외부에서 명시적으로 초기화하는 경우 (옵션)
  void init() {
    _initializeDio();
  }

  Dio get dio {
    if (!_isInitialized) {
      _initializeDio();
    }
    return _dio;
  }
}

/// API 서비스 베이스 클래스
abstract class BaseApiService {
  final DioClient _dioClient = DioClient();

  Dio get dio => _dioClient.dio;

  /// GET 요청
  Future<ApiResponse<T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        String? token,
        T Function(dynamic)? parser,
      }) async {
    try {
      final url = dotenv.env[endpoint] ?? '';
      if (url.isEmpty) {
        logger.w("Empty URL for endpoint: $endpoint");
        return ApiResponse.error('API 엔드포인트를 찾을 수 없습니다.');
      }

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await dio.get(
        url,
        queryParameters: queryParams,
        options: options,
      );

      final parsedData = parser != null ? parser(response.data) : response.data;
      return ApiResponse.success(parsedData, statusCode: response.statusCode);

    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      logger.e("API Error: $e");
      return ApiResponse.error(e.toString());
    }
  }

  /// POST 요청
  Future<ApiResponse<T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? data,
        String? token,
        T Function(dynamic)? parser,
      }) async {
    try {
      final url = dotenv.env[endpoint] ?? '';
      if (url.isEmpty) {
        logger.w("Empty URL for endpoint: $endpoint");
        return ApiResponse.error('API 엔드포인트를 찾을 수 없습니다.');
      }

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await dio.post(
        url,
        data: data,
        options: options,
      );

      final parsedData = parser != null ? parser(response.data) : response.data;
      return ApiResponse.success(parsedData, statusCode: response.statusCode);

    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      logger.e("API Error: $e");
      return ApiResponse.error(e.toString());
    }
  }

  /// Dio 에러 처리
  ApiResponse<T> _handleDioError<T>(DioException e) {
    String errorMessage;
    int? statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = '연결 시간이 초과되었습니다.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          errorMessage = '인증이 만료되었습니다. 다시 로그인해주세요.';
        } else if (statusCode == 404) {
          errorMessage = '요청한 정보를 찾을 수 없습니다.';
        } else if (statusCode == 500) {
          errorMessage = '서버 오류가 발생했습니다.';
        } else {
          errorMessage = e.response?.data['message'] ?? '서버 오류가 발생했습니다.';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = '요청이 취소되었습니다.';
        break;
      default:
        errorMessage = '네트워크 연결을 확인해주세요.';
    }

    logger.e("DioError: $errorMessage", error: e);
    return ApiResponse.error(errorMessage, statusCode: statusCode);
  }
}

/// 사용자 API 서비스
class UserApiService extends BaseApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

  /// 로그인
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String id,
    required String password,
    required bool autoLogin,
    required String fcmToken,
    String? uuid,
    String? firebaseToken,
  }) async {
    return await post<Map<String, dynamic>>(
      AppConstants.loginFormKey,
      data: {
        'user_id': id,
        'user_pwd': password,
        'auto_login': autoLogin,
        'fcm_tkn': fcmToken,
        if (uuid != null) 'uuid': uuid,
      },
      token: firebaseToken,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// 사용자 역할 조회
  Future<ApiResponse<Map<String, dynamic>>> getUserRole(String userId) async {
    return await post<Map<String, dynamic>>(
      AppConstants.roleDataKey,
      data: {'user_id': userId},
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// 회원가입
  Future<ApiResponse<Map<String, dynamic>>> register({
    required Map<String, dynamic> userData,
  }) async {
    return await post<Map<String, dynamic>>(
      AppConstants.membershipKey,
      data: userData,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// 아이디 중복 확인
  Future<ApiResponse<int>> checkIdDuplicate(String userId) async {
    return await post<int>(
      AppConstants.membershipSearchKey,
      data: {'user_id': userId},
      parser: (data) => data as int,
    );
  }

  /// 회원정보 조회
  Future<ApiResponse<Map<String, dynamic>>> getMemberInfo({
    required String uuid,
    required String token,
  }) async {
    return await post<Map<String, dynamic>>(
      AppConstants.memberInfoDataKey,
      data: {'uuid': uuid},
      token: token,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// 회원정보 수정
  Future<ApiResponse<Map<String, dynamic>>> updateMemberInfo({
    required Map<String, dynamic> userData,
    required String token,
  }) async {
    return await post<Map<String, dynamic>>(
      AppConstants.memberInfoUpdateKey,
      data: userData,
      token: token,
      parser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// 선박 API 서비스
class VesselApiService extends BaseApiService {
  static final VesselApiService _instance = VesselApiService._internal();
  factory VesselApiService() => _instance;
  VesselApiService._internal();

  /// 선박 목록 조회
  Future<ApiResponse<List<dynamic>>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    final response = await get<dynamic>(
      AppConstants.vesselListKey,
      queryParams: {
        if (mmsi != null) 'mmsi': mmsi,
        if (regDt != null) 'reg_dt': regDt,
      },
    );

    if (response.success && response.data != null) {
      List<dynamic> items = [];
      if (response.data is Map) {
        items = (response.data as Map)['mmsi'] ?? [];
      } else if (response.data is List) {
        items = response.data as List;
      }
      return ApiResponse.success(items);
    }

    return ApiResponse.error(response.error ?? AppConstants.msgDataLoadError);
  }

  /// 선박 항로 조회
  Future<ApiResponse<Map<String, dynamic>>> getVesselRoute({
    String? regDt,
    int? mmsi,
  }) async {
    return await get<Map<String, dynamic>>(
      AppConstants.vesselRouteKey,
      queryParams: {
        if (mmsi != null) 'mmsi': mmsi,
        if (regDt != null) 'reg_dt': regDt,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// 항행 API 서비스
class NavigationApiService extends BaseApiService {
  static final NavigationApiService _instance = NavigationApiService._internal();
  factory NavigationApiService() => _instance;
  NavigationApiService._internal();

  /// 항행 이력 조회
  Future<ApiResponse<List<dynamic>>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    final response = await get<dynamic>(
      AppConstants.navigationInfoKey,
      queryParams: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (mmsi != null) 'mmsi': mmsi,
        if (shipName != null) 'shipName': shipName,
      },
    );

    if (response.success && response.data != null) {
      List<dynamic> items = [];
      if (response.data is Map) {
        items = (response.data as Map)['mmsi'] ?? [];
      } else if (response.data is List) {
        items = response.data as List;
      }
      return ApiResponse.success(items);
    }

    return ApiResponse.error(response.error ?? AppConstants.msgDataLoadError);
  }

  /// 날씨 정보 조회
  Future<ApiResponse<Map<String, dynamic>>> getWeatherInfo() async {
    return await post<Map<String, dynamic>>(
      AppConstants.visibilityInfoKey,
      data: {},
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// 항행 경보 조회
  Future<ApiResponse<List<String>>> getNavigationWarnings() async {
    final response = await post<Map<String, dynamic>>(
      AppConstants.navigationWarnKey,
      data: {},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final List<dynamic> warnings = response.data!['data'] ?? [];
      return ApiResponse.success(warnings.map((e) => e.toString()).toList());
    }

    return ApiResponse.error(response.error ?? AppConstants.msgDataLoadError);
  }
}

/// 기상 API 서비스
class WeatherApiService extends BaseApiService {
  static final WeatherApiService _instance = WeatherApiService._internal();
  factory WeatherApiService() => _instance;
  WeatherApiService._internal();

  /// 기상 정보 조회
  Future<ApiResponse<List<dynamic>>> getWeatherInfo() async {
    final response = await get<dynamic>(
      AppConstants.weatherInfoKey,
    );

    if (response.success && response.data != null) {
      List<dynamic> items = [];
      if (response.data is Map) {
        items = (response.data as Map)['ts'] ?? [];
      } else if (response.data is List) {
        items = response.data as List;
      }
      return ApiResponse.success(items);
    }

    return ApiResponse.error(response.error ?? AppConstants.msgDataLoadError);
  }
}

/// 약관 API 서비스
class TermsApiService extends BaseApiService {
  static final TermsApiService _instance = TermsApiService._internal();
  factory TermsApiService() => _instance;
  TermsApiService._internal();

  /// 약관 목록 조회
  Future<ApiResponse<List<dynamic>>> getTermsList() async {
    final response = await get<dynamic>(
      AppConstants.cmdKey,
    );

    if (response.success && response.data != null) {
      if (response.data is List) {
        return ApiResponse.success(response.data as List);
      }
    }

    return ApiResponse.error(response.error ?? AppConstants.msgDataLoadError);
  }
}