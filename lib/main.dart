import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/kdn/ros/view/mainView.dart';
import 'package:vms_app/kdn/usm/view/LoginView.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/ros/viewModel/NavigationViewModel.dart';

import 'firebase_options.dart';
import 'kdn/main/viewModel/VesselSearchViewModel.dart';
import 'kdn/usm/viewModel/UserState.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: '중요 알림을 위한 채널입니다.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings(); // ✅ iOS 초기화 추가(매우 중요)

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _setupFlutterNotifications();

  await initializeDateFormatting('ko_KR', null);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? tokenget = prefs.getString('firebase_token');
  bool? auto_login = prefs.getBool('auto_login');

  await dotenv.load(fileName: ".env");
  //MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RosNavigationViewModel()), //항행이력 목록조회
        ChangeNotifierProvider(create: (_) => UserState()),              //사용자 권한 가져오기
        ChangeNotifierProvider(create: (_) => VesselSearchViewModel()), //현재선박 좌표 조회
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}


class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: getColorwhite_type1(),
        appBarTheme: AppBarTheme(
          backgroundColor: getColorwhite_type1(),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: getColorblack_type1()),
          titleTextStyle: TextStyle(
            color: getColorblack_type1(),
            fontSize: getSize20().toDouble(),
            fontWeight: getTextbold(),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(prefs: prefs), // ✅ prefs 전달
    );
  }
}

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String fcmToken = ''; // fcm 토큰

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); //앱 실행될 때, 현재 자동로그인 상태 유/무 체크
  }
  final String apiUrl = dotenv.env['kdn_loginForm_key'] ?? '';
  final String apiUrl2 = dotenv.env['kdn_usm_select_role_data_key'] ?? '';

  //자동로그인 상태 유/무 체크
  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (!mounted) return;

    String? token = widget.prefs.getString('firebase_token');
    bool? auto_login = widget.prefs.getBool('auto_login');

    fcmToken = await FirebaseMessaging.instance.getToken() ?? ''; //FCM 토큰 가져오기

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (token != null && auto_login == true) {

        String? username = widget.prefs.getString('username');

        try {
          //자동 로그인을 서버에 요청
          Response response = await Dio().post(
            apiUrl,
            data: {
              'auto_login': auto_login,
              'fcm_token': fcmToken,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
              },
            ),
          );

          if (response.statusCode == 200) {
            String? fetchedUsername;

            if (response.data is Map && response.data.containsKey('username')) {
              fetchedUsername = response.data['username']?.toString();
            }

            if (fetchedUsername == null || fetchedUsername.isEmpty) {
              fetchedUsername = username ?? '사용자';
            } else {
              await widget.prefs.setString('username', fetchedUsername);
            }

            //사용자 권한 가져오기
            try {
              Response roleResponse = await Dio().post(
                apiUrl2,
                data: {'user_id': fetchedUsername},
              );

              if (roleResponse.statusCode == 200) {
                String role = roleResponse.data['role'];
                int mmsi = roleResponse.data['mmsi'];

                Provider.of<UserState>(context, listen: false).setRole(role); //역할 상태 저장
                Provider.of<UserState>(context, listen: false).setMmsi(mmsi); //mmsi 번호 저장
              }
            } catch (e) {

            }

            _navigateToMain(fetchedUsername);
          } else {
            await widget.prefs.setBool('auto_login', false);
            _navigateToLogin(); //로그인 페이지로 이동
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            await widget.prefs.setBool('auto_login', false);
            _navigateToLogin();
          } else {
            _navigateToLogin();
          }
        } catch (e) {
          _navigateToLogin();
        }
      }

      if (token != null && auto_login == false) {
        _navigateToLogin();
      }

      if (token == null && auto_login == null) {
        _navigateToLogin();
      }

      if (token != null && auto_login == null) {
        _navigateToLogin();
      }

    });
  }

  void _navigateToMain(String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => mainView(username: username,)),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
