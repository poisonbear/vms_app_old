import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:dio/dio.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/MembershipClearView.dart';
import 'package:vms_app/kdn/usm/view/layer/AppBarLayerView.dart';
import 'package:vms_app/kdn/usm/view/CmdChoiceView.dart';


class Membershipview extends StatefulWidget {
  final DateTime nowTime;

  const Membershipview({super.key, required this.nowTime});

  @override
  State<Membershipview> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<Membershipview> {
  final TextEditingController idController = TextEditingController();              // 아이디 입력값
  final TextEditingController passwordController = TextEditingController();        // 비밀번호 입력값
  final TextEditingController confirmPasswordController = TextEditingController(); // 비밀번호 확인 입력값
  final TextEditingController mmsiController = TextEditingController();            // mmsi 번호 입력값
  final TextEditingController phoneController = TextEditingController();           // 휴대폰 번호 입력값
  final TextEditingController emailController = TextEditingController();           // 이메일 입력값
  final TextEditingController emailaddrController = TextEditingController();       // 이메일 주소 입력값  naver.com , google.com 등등

  bool isIdValid = true;       // 아이디 상태값
  bool isValpw = true;         // 비밀번호 상태값
  bool isValms = true;         // mmsi 상태값
  bool isValphone = true;      // 휴대폰 번호 상태값
  bool isValemail = true;      // 이메일 상태값
  bool isValemailaddr = true;  // 이메일 주소 상태값

  int? isIdAvailable;  // 아이디 중복조회

  List<String> items = ['naver.com', 'gmail.com', 'hanmail.net']; // 이메일 주소
  String? selectedValue; // 이메일 주소 직접이력
  TextEditingController controller = TextEditingController(); // 이메일 주소 직접입력 시 이메일 주소 입력값


  final String apiUrl = dotenv.env['kdn_usm_insert_membership_key'] ?? ''; // 회원가입 url
  final String apisearchUrl = dotenv.env['kdn_usm_select_membership_search_key'] ?? ''; // 회원조회 url
  final dioRequest = DioRequest();


  // 시작
  // 이벤트 초기화
  @override
  void initState() {
    super.initState();
    idController.addListener(validateId);           // 아이디 이벤트 초기화
    passwordController.addListener(validatepw);     // 비밀번호 이벤트 초기화
    mmsiController.addListener(validatems);         // mmsi 이벤트 초기화
    phoneController.addListener(validatephone);     // 휴대폰 번호 이벤트 초기화
    emailController.addListener(validateemail);     // 이메일 이벤트 초기화
    emailaddrController.addListener(validateemail); // 이메일 주소 이벤트 초기화

  }

  // 종료
  // 이벤트 초기화
  @override
  void dispose() {
    idController.removeListener(validateId);         //  아이디 이벤트 삭제
    idController.dispose();                          //  아이디 컨트롤러 삭제
    passwordController.removeListener(validatepw);   // 비밀번호 리스너 삭제
    passwordController.dispose();                    // 비밀번호 컨트롤러 삭제
    confirmPasswordController.dispose();             // 비밀번호 확인 컨트롤러 삭제
    mmsiController.dispose();                        // mmsi 번호 컨트롤러 삭제
    mmsiController.removeListener(validatems);       // mmsi 번호 리스너 삭제
    phoneController.dispose();                       // 휴대폰 번호 컨트롤러 삭제
    phoneController.removeListener(validatephone);   // 휴대폰 번호 리스너 삭제
    emailController.removeListener(validateemail);   // 이메일 리스너 삭제
    emailController.dispose();                       // 이메일 컨트롤러 삭제
    emailaddrController.removeListener(validateemail); // 이메일 주소 리스너 삭제
    emailaddrController.dispose();                   // 이메일 주소 컨트롤러 삭제
    super.dispose();
  }

  // 아이디 유효성 검사 함수  - 문자 및 숫자로 8~12자리 검사
  void validateId() {
    setState(() {
      RegExp regex = RegExp(r'^[a-zA-Z0-9]{8,12}$');
      isIdValid = regex.hasMatch(idController.text);

      // 아이디가 변경되면 중복확인 상태 초기화
      if (isIdAvailable != null) {
        isIdAvailable = null;
      }
    });
  }

  // 비밀번호 유효성 검사 - 문자 및 숫자로 6~12자리 검사
  void validatepw() {
    setState(() {
      String password = passwordController.text;

      bool hasMinLength = password.length >= 6 && password.length <= 12;
      bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
      bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
      bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

      isValpw = hasMinLength && hasLetter && hasNumber && hasSpecial;
    });
  }

  // mmsi 번호 유효성 검사 - 숫자 9자리만 허용
  void validatems() {
    setState(() {
      String mmsi = mmsiController.text;
      if (mmsi.isEmpty) {
        isValms = true; // 빈 값은 일단 유효한 것으로 처리 (필수 체크는 submitForm에서)
      } else {
        RegExp regex = RegExp(r'^\d{9}$');
        isValms = regex.hasMatch(mmsi);
      }
    });
  }

  // 휴대폰 번호 유효성 검사 - 숫자 11자리만 허용
  void validatephone() {
    setState(() {
      String phone = phoneController.text;
      if (phone.isEmpty) {
        isValphone = true; // 빈 값은 일단 유효한 것으로 처리 (필수 체크는 submitForm에서)
      } else {
        RegExp regex = RegExp(r'^\d{11}$');
        isValphone = regex.hasMatch(phone);
      }
    });
  }

  // 이메일 유효성 검사 함수
  void validateemail() {
    setState(() {
      String email = emailController.text;
      String emailaddr = emailaddrController.text;
      isValemail = email.isNotEmpty;
      isValemailaddr = emailaddr.isNotEmpty;
    });
  }


  // 아이디 중복 조회
  Future<void> searchForm() async {
    String id = idController.text.trim(); // 공백 제거

    // 1. 빈 값 체크
    if (id.isEmpty) {
      showTopSnackBar(context, '아이디를 입력해주세요.');
      return;
    }

    // 2. 아이디 유효성 체크
    if (!isIdValid) {
      showTopSnackBar(context, '아이디 형식이 올바르지 않습니다.\n문자, 숫자 8~12자리로 입력해주세요.');
      return;
    }

    try {
      Response response = await dioRequest.dio.post(
        apisearchUrl,
        data: { 'user_id': id },
      );

      setState(() {
        if (response.data is int) {
          isIdAvailable = response.data;
        } else {
          isIdAvailable = null;
        }
      });

      // 결과에 따른 메시지 표시 (선택사항)
      if (isIdAvailable == 0) {
        showTopSnackBar(context, '사용 가능한 아이디입니다.');
      } else if (isIdAvailable == 1) {
        showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
      }

    } catch (e) {
      log("아이디 중복 확인 오류: $e");
      setState(() {
        isIdAvailable = null;
      });
      showTopSnackBar(context, '서버 오류 발생. 다시 시도해주세요.');
    }
  }

  // 회원가입 url
  Future<void> submitForm() async {
    String id = idController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    if (id.isEmpty || password.isEmpty || confirmPassword.isEmpty || mmsi.isEmpty ) {
      showTopSnackBar(context, '회원가입을 위해 필수 항목을 입력해주세요.');
      return;
    }

    if (isIdAvailable == null) {
      showTopSnackBar(context, '아이디 중복 확인을 해주세요.');
      return;
    }

    if (isIdAvailable == 1) {
      showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
      return;
    }


    if (!isIdValid) {
      showTopSnackBar(context,'아이디 형식이 올바르지 않습니다.');
      return;
    }

    if (!isValpw) {
      showTopSnackBar(context,'비밀번호 형식이 올바르지 않습니다.');
      return;
    }

    if (!isValms) {
      showTopSnackBar(context,'선박 MMSI 번호 형식이 올바르지 않거나\n 9자리에 벗어납니다.');
      return;
    }

    if (!isValphone) {
      showTopSnackBar(context,'휴대폰 번호 형식이 올바르지 않거나\n 11자리에 벗어납니다.');
      return;
    }

    //if (!isValemail) {
    //  showTopSnackBar(context,'이메일을 입력해주세요.');
    //  return;
    //}

    //if (!isValemailaddr) {
    //  showTopSnackBar(context,'이메일 주소를 입력해주세요.');
    //  return;
    //}

    if (emailaddr=='직접입력'){

      showTopSnackBar(context,'이메일 주소가 올바르지 않습니다.');
      return;
    }

    if (password != confirmPassword) {

      showTopSnackBar(context,'비밀번호가 일치하지 않습니다.');

      return;
    }

    try {
      // Firebase Authentication으로 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: '${id.trim()}@kdn.vms.com',
        password: password.trim(),
      );
      String uuid = userCredential.user!.uid;

      // 서버 전송 데이터에 firebaseUID 추가
      Map<String, dynamic> dataToSend = {
        'user_id': id,
        'user_pwd': password,
        'mmsi': mmsi,
        'mphn_no': phone,
        'choice_time': widget.nowTime.toIso8601String(),
        'firebase_uuid': uuid,
        'email_addr': (email.isNotEmpty && emailaddr.isNotEmpty) ? '$email@$emailaddr' : '',
      };
      Response response;
      response = await dioRequest.dio.post(
        apiUrl,
        data: dataToSend,
      );



      if (response.statusCode == 200) {
        Navigator.push(
          context,
          createSlideTransition(
            const MembershipClearView(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 실패. 다시 시도해주세요.')),
        );
      }
    } catch (e, stackTrace) {
      log("회원가입 중 에러 발생: $e", stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: $e')),
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 화면 밀리지 않게
      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        leading:  IconButton(
          icon: svgload('assets/kdn/usm/img/arrow-left.svg', getSize24().toDouble(), getSize24().toDouble()),
          onPressed: () {
            Navigator.pop(
                context,
                MaterialPageRoute(builder: (context) => const CmdChoiceView(),
                )
            );
          },
        ),
        centerTitle: true,
      ),


      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: getSize20().toDouble(),
          right: getSize20().toDouble(),
          top: getSize20().toDouble(),
          bottom: MediaQuery.of(context).viewInsets.bottom + getSize20().toDouble(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 , 2, 3
            Padding(
              padding: EdgeInsets.only(bottom:  getSize20().toDouble()),
              child: Row(
                  children: [
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(left: getSize8().toDouble()),
                      child:  svgload('assets/kdn/usm/img/Frame_one_off.svg',getSize32().toDouble(),getSize32().toDouble()),),
                    Padding(
                      padding: EdgeInsets.only(left: getSize8().toDouble()),
                      child: svgload('assets/kdn/usm/img/Frame_two_on.svg',getSize32().toDouble(),getSize32().toDouble()),),
                    Padding(
                      padding: EdgeInsets.only(left: getSize8().toDouble()),
                      child: svgload('assets/kdn/usm/img/Frame_three_off.svg',getSize32().toDouble(),getSize32().toDouble()),),
                  ]
              ),
            ),

            // 제목
            TextWidgetString('K-VMS',getTextcenter(),getSize32(),getText700(),getColorblack_type2()),
            TextWidgetString('회원정보입력',getTextcenter(),getSize32(),getText700(),getColorblack_type2()),

            // 소제목
            Padding(
              padding: EdgeInsets.only(top: getSize12().toDouble() , bottom: getSize32().toDouble()),
              child: TextWidgetString('회원가입을 위한 필요 정보를 입력해주시기 바랍니다.',getTextcenter(),getSize12(),getText700(),getColorgray_Type2()),
            ),

            // 아이디
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TextWidgetString('아이디',getTextcenter(),getSize16(), getText700(),getColorgray_Type8(),),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: Row(
                  children: [
                    Expanded(
                      child: inputWidgetSvg(getSize100(), getSize48(), idController, '아이디', getColorgray_Type7() , 'assets/kdn/usm/img/circle-xmark.svg',),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: getSize20().toDouble()),
                      child: ElevatedButton(
                        onPressed: searchForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColorwhite_type1(),
                          shape: RoundedRectangleBorder(
                            borderRadius: getTextradius6_direct(),
                            side: BorderSide(
                              color: getColorgray_Type7(),
                              width: getSize1().toDouble(),
                            ),
                          ),
                          elevation: getSize0().toDouble(),
                          padding: EdgeInsets.symmetric(
                            vertical: getSize12().toDouble(),
                            horizontal: getSize32().toDouble(),
                          ),
                        ),
                        child: TextWidgetString('중복확인',getTextcenter(),getSize16(),getText700(),getColorgray_Type2(),),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 아이디 유효성 메시지
            if (!isIdValid)
              Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble(), bottom: getSize8().toDouble()),
                child: TextWidgetString(
                  '아이디는 문자, 숫자를 포함한 8자리 이상 12자리 이하로 입력하여야 합니다.',
                  getTextleft(),
                  getSize12(),
                  getText700(),
                  getColorred_type3(),
                ),
              )
            else if (isIdAvailable == 0)
              Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble(), bottom: getSize8().toDouble()),
                child: TextWidgetString(
                    '사용가능한 아이디 입니다.',
                    getTextcenter(),
                    getSize12(),
                    getText700(),
                    getColorgreen_Type1()
                ),
              )
            else if (isIdAvailable == 1)
                Padding(
                  padding: EdgeInsets.only(top: getSize8().toDouble(), bottom: getSize8().toDouble()),
                  child: TextWidgetString(
                      '이미 사용중인 아이디 입니다.',
                      getTextcenter(),
                      getSize12(),
                      getText700(),
                      getColorred_type3()
                  ),
                ),

            // 비밀번호
            Padding(
              padding: EdgeInsets.only(top: getSize8().toDouble()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TextWidgetString('비밀번호',getTextcenter(),getSize16(), getText700(),getColorgray_Type8(),),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: inputWidget(getSize266(),getSize48(),passwordController , '비밀번호',getColorgray_Type7() , obscureText: true),
              ),
            ),

            if (!isValpw)
              Padding(
                  padding: EdgeInsets.only(top: getSize8().toDouble()  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidgetString('비밀번호는 문자, 숫자 및 특수문자를 포함한 6자리 이상 12자리 이하로 입력하여야 합니다.',getTextleft(),getSize12(), getText700(),getColorred_type3()),
                    ],
                  )
              ),

            // 비밀번호 확인
            Padding(
              padding:  EdgeInsets.only(top: getSize8().toDouble()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidgetString('비밀번호 확인 ',getTextcenter(),getSize16(), getText700(),getColorgray_Type8(),),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: inputWidget(getSize266(),getSize48(),confirmPasswordController , '비밀번호 확인',getColorgray_Type7(), obscureText: true),
              ),
            ),

            // MMSI
            Padding(
              padding: EdgeInsets.only(top: getSize8().toDouble()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidgetString('선박 MMSI 번호',getTextcenter(),getSize16(), getText700(),getColorgray_Type8(),),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: inputWidget(getSize266(),getSize48(),mmsiController , 'MMSI 번호(숫자 9자리)를 입력해주세요',getColorgray_Type7()),
              ),
            ),

            // 휴대폰 번호
            Padding(
              padding: EdgeInsets.only(top: getSize8().toDouble()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidgetString('휴대폰 번호',getTextcenter(),getSize16(), getText700(),getColorgray_Type8(),),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    //painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: inputWidget(getSize266(),getSize48(),phoneController, '- 제외한 11자리',getColorgray_Type7()),
              ),
            ),

            // 이메일
            Padding(
              padding: EdgeInsets.only(top: getSize8().toDouble()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidgetString('이메일', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
                  SizedBox(width: getSize3().toDouble()),
                  CustomPaint(
                    size: Size(getSize4().toDouble(), getSize4().toDouble()),
                    //painter: RedCirclePainter(),
                  ),
                ],
              ),
            ),

            SizedBox(
              child: Padding(
                padding: EdgeInsets.only(top: getSize8().toDouble() , bottom: getSize8().toDouble()),
                child: Row(
                  children: [
                    Expanded(
                      child: inputWidget(
                        getSize133(),
                        getSize48(),
                        emailController,
                        '이메일 아이디 입력',
                        getColorgray_Type7(),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: getSize4().toDouble()),
                      child: TextWidgetString('@', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
                    ),

                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: emailaddrController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: getColorwhite_type1(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),

                          PopupMenuButton<String>(
                            icon: SvgPicture.asset(
                              'assets/kdn/usm/img/down_select_img.svg',
                              width: 24,
                              height: 24,
                            ),
                            color: Colors.white,
                            onSelected: (String value) {
                              setState(() {
                                selectedValue = value;
                                emailaddrController.text = value;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return items.map((String value) {
                                return PopupMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Center(
                child: SizedBox(
                  width: double.infinity, // 버튼의 가로 크기를 화면 너비로 설정
                  child: ElevatedButton(

                    onPressed: submitForm,
                    child: TextWidgetString('회원가입 완료',getTextcenter(),getSize16(),getText700(),getColorwhite_type1()),


                    style: ElevatedButton.styleFrom(
                        backgroundColor: getColorsky_Type2(),
                        shape: getTextradius6(), // 테두리 제거
                        elevation: getSize0().toDouble(), // 그림자 제거 (선택 사항)
                        padding: EdgeInsets.all(getSize18().toDouble() )
                    ),
                  ),
                )
            ),
          ],
         ),
        ),
      ),
    );
  }
}
class RedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), // 원 중심
      size.width / 2, // 반지름
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}