// lib/kdn/cmm/common_utils.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// 날짜 관련 유틸리티
class DateUtils {
  static String getCurrentDateString() {
    return DateFormat('yyyy.MM.dd').format(DateTime.now());
  }

  static String formatDate(DateTime date, {String format = 'yyyy.MM.dd'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateFromMillis(int milliseconds, {String format = 'yyyy.MM.dd'}) {
    return DateFormat(format).format(
        DateTime.fromMillisecondsSinceEpoch(milliseconds)
    );
  }

  static String getTimeRange(int? startMillis, int? endMillis) {
    if (startMillis == null || endMillis == null) {
      return "00:00:00~00:00:00";
    }

    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);

    return "${formatTime(start)}~${formatTime(end)}";
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }
}

/// 비밀번호 관련 유틸리티
class PasswordUtils {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static String hashAndEncode(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  static bool validatePassword(String password) {
    if (password.length < 6 || password.length > 12) return false;

    bool hasLetter = AppConstants.letterPattern.hasMatch(password);
    bool hasNumber = AppConstants.numberPattern.hasMatch(password);
    bool hasSpecial = AppConstants.specialPattern.hasMatch(password);

    return hasLetter && hasNumber && hasSpecial;
  }
}

/// SharedPreferences 관련 유틸리티
class PreferencesUtils {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String 저장/불러오기
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // Bool 저장/불러오기
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Int 저장/불러오기
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // 삭제
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // 전체 삭제
  static Future<void> clear() async {
    await _prefs.clear();
  }

  // 사용자 정보 관련
  static Future<void> saveUserInfo({
    String? token,
    String? username,
    String? uuid,
    bool? autoLogin,
  }) async {
    if (token != null) await setString(AppConstants.prefFirebaseToken, token);
    if (username != null) await setString(AppConstants.prefUsername, username);
    if (uuid != null) await setString(AppConstants.prefUuid, uuid);
    if (autoLogin != null) await setBool(AppConstants.prefAutoLogin, autoLogin);
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    return {
      'token': getString(AppConstants.prefFirebaseToken),
      'username': getString(AppConstants.prefUsername),
      'uuid': getString(AppConstants.prefUuid),
      'autoLogin': getBool(AppConstants.prefAutoLogin),
      'role': getString(AppConstants.prefUserRole),
      'mmsi': getInt(AppConstants.prefUserMmsi),
    };
  }

  static Future<void> clearUserInfo() async {
    await remove(AppConstants.prefFirebaseToken);
    await remove(AppConstants.prefUsername);
    await remove(AppConstants.prefUuid);
    await remove(AppConstants.prefAutoLogin);
    await remove(AppConstants.prefUserRole);
    await remove(AppConstants.prefUserMmsi);
  }
}

/// 유효성 검사 유틸리티
class ValidationUtils {
  static bool isValidId(String id) {
    return AppConstants.idPattern.hasMatch(id);
  }

  static bool isValidMmsi(String mmsi) {
    return AppConstants.mmsiPattern.hasMatch(mmsi);
  }

  static bool isValidPhone(String phone) {
    return AppConstants.phonePattern.hasMatch(phone);
  }

  static bool isValidEmail(String email, String domain) {
    return email.isNotEmpty && domain.isNotEmpty;
  }

  static String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요.';
    }

    switch (fieldName) {
      case '아이디':
        return isValidId(value) ? null : ValidationMessages.idFormat;
      case '비밀번호':
        return PasswordUtils.validatePassword(value) ? null : ValidationMessages.passwordFormat;
      case 'MMSI':
        return isValidMmsi(value) ? null : ValidationMessages.mmsiFormat;
      case '휴대폰':
        return isValidPhone(value) ? null : ValidationMessages.phoneFormat;
      default:
        return null;
    }
  }
}

/// 스낵바 유틸리티
class SnackBarUtils {
  static void showTopSnackBar(BuildContext context, String message, {
    Color backgroundColor = const Color(0xFF333333),
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showBottomSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
}

/// 디버그 유틸리티
class DebugUtils {
  static void printUserData() async {
    final userInfo = await PreferencesUtils.getUserInfo();
    print("=== 저장된 사용자 정보 ===");
    userInfo.forEach((key, value) {
      print("$key: $value");
    });
    print("=====================");
  }

  static void printApiCall(String apiName, dynamic params, dynamic response) {
    print("=== API 호출: $apiName ===");
    print("Parameters: $params");
    print("Response: $response");
    print("========================");
  }
}