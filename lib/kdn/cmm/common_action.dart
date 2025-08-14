import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/main/model/VesselSearchModel.dart';

import '../ros/viewModel/RouteSearchViewModel.dart';




/// 페이지 전환 애니메이션을 반환하는 함수
Route createSlideTransition(Widget page, {Offset begin = const Offset(1.0, 0.0)}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const end = Offset(0.0, 0.0); // 중앙에 멈춤
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}


/// dio 통신
class DioRequest {
  final Dio _dio = Dio(BaseOptions(
    contentType: Headers.jsonContentType,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 3000),
    headers: {
      'User-Agent': 'PostmanRuntime/7.43.0', // 사용자 정의 User-Agent 헤더 설정
      'ngrok-skip-browser-warning': 100
    },
  ));


  Dio get dio => _dio;
}

/// 경고팝업
Future<void> warningPop(BuildContext context, String title, Color titleColor,String detail , Color detailColor , String alarmicon, Color shadowcolor) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: getSize300()),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          /// ✅ 전체 화면을 덮는 배경 추가
          Positioned.fill(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height, // 전체 화면 크기
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    shadowcolor.withOpacity(0.1),
                    shadowcolor.withOpacity(0.3),
                    shadowcolor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(getSize65().toDouble()),
            child: Center(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          SvgPicture.asset(alarmicon, width: 60, height: 60),
                          SizedBox(height: getSize8().toDouble()),
                          TextWidgetString(title, getTextcenter(), getSize20(), getTextbold(), titleColor),
                          TextWidgetString(detail, getTextcenter(), getSize14(), getTextbold(), detailColor),
                          SizedBox(height: getSize12().toDouble()),



                          SizedBox(height: getSize32().toDouble()),

                          /// 버튼
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                                    child: Center(
                                      child: TextWidgetString(
                                        '알람 종료하기',
                                        getTextcenter(),
                                        getSize16(),
                                        getText700(),
                                        getColorsky_Type2(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 경고팝업
Future<void> warningPopdetail(BuildContext context, String title, Color titleColor, String detail, Color detailColor, String alarmicon, Color  shadowcolor) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: getSize300()),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          /// ✅ 전체 화면을 덮는 배경 추가
          Positioned.fill(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height, // 전체 화면 크기
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    shadowcolor.withOpacity(0.1),
                    shadowcolor.withOpacity(0.3),
                    shadowcolor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(getSize65().toDouble()),
            child: Center(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          SvgPicture.asset(alarmicon, width: 60, height: 60),
                          SizedBox(height: getSize8().toDouble()),
                          TextWidgetString(title, getTextcenter(), getSize20(), getTextbold(), titleColor),
                          TextWidgetString(detail, getTextcenter(), getSize14(), getTextbold(), detailColor),
                          SizedBox(height: getSize12().toDouble()),

                          /// Table 추가
                          Container(
                            width: double.infinity,
                            child: Table(
                              border: TableBorder(
                                top: BorderSide(color: getColorgray_Type7(), width: getSize1().toDouble()),
                                bottom: BorderSide(color: getColorgray_Type7(), width: getSize1().toDouble()),
                                horizontalInside: BorderSide(color: getColorgray_Type7(), width: getSize1().toDouble()),
                                verticalInside: BorderSide(color: getColorgray_Type7(), width: getSize1().toDouble()),
                              ),
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: IntrinsicColumnWidth(),
                                2: IntrinsicColumnWidth(),
                                // 0: FlexColumnWidth(1),
                                // 1: FlexColumnWidth(1),
                                // 2: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: getColorgray_Type10()),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('날짜', getTextcenter(), getSize16(), getText600(), getColorblack_type1()),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('시작시간', getTextcenter(), getSize16(), getText600(), getColorblack_type1()),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('종료시간', getTextcenter(), getSize16(), getText600(), getColorblack_type1()),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('2025.01.10', getTextcenter(), getSize14(), getText600(), getColorblack_type1()),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('09:00:00', getTextcenter(), getSize14(), getText600(), getColorblack_type1()),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: getSize8().toDouble()),
                                      child: TextWidgetString('14:00:00', getTextcenter(), getSize14(), getText600(), getColorblack_type1()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: getSize32().toDouble()),

                          /// 버튼
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                                    child: Center(
                                      child: TextWidgetString(
                                        '알람 종료하기',
                                        getTextcenter(),
                                        getSize16(),
                                        getText700(),
                                        getColorsky_Type2(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}





// 비밀번호 해시화
String hashPassword(String password) {
  final bytes = utf8.encode(password); // UTF-8 인코딩
  return sha256.convert(bytes).toString(); // Hex 문자열 반환
}

String hashAndEncode(String password) {
  final bytes = utf8.encode(password); // UTF-8 인코딩
  final digest = sha256.convert(bytes);

  print("비밀번호 암호화 : " +base64Encode(digest.bytes));


  return base64Encode(digest.bytes); // Base64 인코딩
}


// UUID , sessionId 저장
Future<void> saveUuid(String v5) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('uuid', v5); // uuid

}

// UUID 불러오기
Future<String?> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('uuid');
}

// sessionId 저장
Future<void> sessionId(String sessionId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('sessionId', sessionId); // JSESSIONID
}

// sessionId 불러오기
Future<String?> getsessionId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('sessionId');
}

// 저장된 데이터 디버깅 출력
Future<void> readData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  log("저장된 UUID: ${prefs.getString('uuid')}");
  log("저장된 sessionId: ${prefs.getString('sessionId')}");
}











