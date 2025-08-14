
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/CmdChoiceView.dart';
import 'package:vms_app/kdn/ros/view/mainView.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../viewModel/UserState.dart';
import 'FindAccountView.dart';

class LoginView extends StatefulWidget {


  const LoginView({super.key, });

  @override
  State<LoginView> createState() => _CmdViewState();
}

class _CmdViewState extends State<LoginView> {
  final TextEditingController idController = TextEditingController(); // 아이디 입력값
  final TextEditingController passwordController = TextEditingController(); // 비밀번호 입력값
  final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? ''; // 로그인  url
  final String apiUrl2 = dotenv.env['kdn_usm_select_role_data_key'] ??
      ''; // 사용자 역할 권한  url
  bool auto_login = false; // 자동 로그인
  late FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late String fcmToken; //FCM 토큰 저장 변수 추가


  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    initFcmToken(); // FCM 토큰 초기화 함수 호출
  }

  // FCM 토큰 초기화 함수
  Future<void> initFcmToken() async {
    try {
      fcmToken = await messaging.getToken() ?? '';
    } catch (e) {
      fcmToken = ''; // 오류 발생시 빈 문자열로 초기화
    }
  }


  Future<void> submitForm() async {
    final id = '${idController.text.trim()}' + '@kdn.vms.com'; // 아이디
    final password = passwordController.text.trim(); // 비밀번호

    // 유효성 검사
    if (id.isEmpty || password.isEmpty) {
      showTopSnackBar(context, '아이디 비밀번호를 입력해주세요.');
      return;
    }

    try {
      // 토큰 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: id, password: password);

      // ✅ Firebase JWT 토큰 가져오기
      String? firebaseToken = await userCredential.user?.getIdToken();
      String? uuid = userCredential.user?.uid;

      if (firebaseToken == null) {
        showTopSnackBar(context, 'Firebase 토큰을 가져올 수 없습니다.');
        return;
      }

      String? token = firebaseToken;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_token', token); // firebase 토큰 디바이스에 저장

      //String? tokenget = prefs.getString('firebase_token');

      //✅ 서버에 JWT 토큰과 함께 로그인 요청
      Response response = await Dio().post(
        apiUrl,
        data: {
          'user_id': id, // 아이디
          'user_pwd': password, // 비밀번호
          'auto_login': auto_login, // 자동 로그인 false값
          'fcm_tkn': fcmToken, // fcm 토큰
          'uuid': uuid // uuid
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $firebaseToken', // 서버에 JWT 토큰 전달
          },
        ),
      );
      print('=== 로그인 응답 디버깅 시작 ===');
      print("➡️ 로그인 요청 API URL: $apiUrl");
      print('✅ Firebase JWT 토큰: $firebaseToken');
      print('✅ Authorization 헤더: Bearer $firebaseToken');
      print(response.data);
      print(response.statusCode);
      if (response.statusCode == 200) { // 요청 성공
        String username = response.data['username'];
        await prefs.setString('username', username); //username을 디바이스에 저장


        // UUID 저장 코드 추가
        if (response.data.containsKey('uuid')) {
          String uuid = response.data['uuid'];
          await prefs.setString('uuid', uuid);
        }

        //로그인 이후, 자동로그인 값 true로 설정
        auto_login = true;
        await prefs.setBool('auto_login', auto_login); //자동로그인을 디바이스에 저장

        //[1] 역할(role) 요청 API 호출
        Response roleResponse = await Dio().post(
          apiUrl2,
          data: {'user_id': username},
        );

        if (roleResponse.statusCode == 200) {
          print("$roleResponse");
          String role = roleResponse.data['role'];
          int? mmsi = roleResponse.data['mmsi'];

          //[2] Provider에 역할 저장
          context.read<UserState>().setRole(role); // 디바이스에 역할 상태 저장
          context.read<UserState>().setMmsi(mmsi); // 디바에스에 mmsi 상태 저장
        } else {

        }

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => mainView(username: username)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              '로그인 실패: ${response.data['message'] ?? '잘못된 아이디 또는 비밀번호'}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        if (e.message?.contains('password') ?? false) {} else
        if (e.message?.contains('email') ?? false) {} else {
          showTopSnackBar(context, '아이디 또는 비밀번호를 확인해주세요.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 반드시 false
      body: Stack(
        children: [
          // 1. 배경 이미지를 SizedBox로 고정 크기 설정
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/kdn/usm/img/blue_sky2.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center, // 중앙 고정
                  ),
                ),
              ),
            ),
          ),

          // 2. 키보드 터치 시 닫기
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedPadding(
                  duration: Duration(milliseconds: 100), // 부드러운 애니메이션
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight > 0 ? keyboardHeight : 0,
                  ),
                  child: SingleChildScrollView(
                    reverse: false, // 스크롤 방향
                    physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // K-VMS 타이틀
                          Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: TextWidgetString(
                                'K-VMS',
                                getTextcenter(),
                                getSize32(),
                                getTextbold(),
                                getColorblack_type1()
                            ),
                          ),

                          // 로그인 박스
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: Container(
                                width: 400,
                                padding: EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextWidgetString(
                                        '시스템 로그인',
                                        getTextcenter(),
                                        getSize24(),
                                        getTextbold(),
                                        getColorblack_type1()
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: TextWidgetString(
                                          '시스템 사용을 위해 로그인을 해주시기 바랍니다.',
                                          getTextcenter(),
                                          getSize12(),
                                          getTextbold(),
                                          getColorgray_Type1()
                                      ),
                                    ),
                                    // 아이디 입력
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: inputWidget(
                                            getSize266(),
                                            getSize48(),
                                            idController,
                                            '아이디 입력',
                                            getColorgray_Type7()
                                        ),
                                      ),
                                    ),
                                    // 비밀번호 입력
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: inputWidget(
                                            getSize266(),
                                            getSize48(),
                                            passwordController,
                                            '비밀번호 입력',
                                            getColorgray_Type7(),
                                            obscureText: true
                                        ),
                                      ),
                                    ),
                                    // 로그인 버튼
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: SizedBox(
                                        width: getSize266().toDouble(),
                                        height: getSize48().toDouble(),
                                        child: ElevatedButton(
                                          onPressed: submitForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: getColorsky_Type2(),
                                            shape: getTextradius6(),
                                            elevation: 0,
                                          ),
                                          child: TextWidgetString(
                                              '로그인 하기',
                                              getTextcenter(),
                                              getSize16(),
                                              getTextbold(),
                                              getColorwhite_type1()
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 회원가입 버튼
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => const CmdChoiceView(),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                const begin = Offset(1.0, 0.0);
                                                const end = Offset.zero;
                                                const curve = Curves.ease;
                                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                                var offsetAnimation = animation.drive(tween);
                                                return SlideTransition(position: offsetAnimation, child: child);
                                              },
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextWidgetString(
                                                '회원가입하기',
                                                getTextcenter(),
                                                getSize12(),
                                                getTextbold(),
                                                getColorblack_type1()
                                            ),
                                            SizedBox(width: 4),
                                            SvgPicture.asset(
                                              'assets/kdn/usm/img/chevron-right.svg',
                                              height: 16,
                                              width: 16,
                                              fit: BoxFit.contain,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 하단 로고 (고정 위치)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '시스템 문의 : 061-930-4567',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                SvgPicture.asset(
                  'assets/kdn/usm/img/login_footer_logo.svg',
                  height: 20.0,
                  width: 150.0,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
