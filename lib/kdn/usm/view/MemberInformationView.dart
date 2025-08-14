import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/kdn/usm/view/LoginView.dart';
import 'package:vms_app/kdn/cmm/common_action.dart'; // createSlideTransition 함수 정의 파일 import
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/layer/AppBarLayerView.dart';
import 'package:vms_app/kdn/usm/view/MemberInformationChange.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ros/view/mainView.dart';


class MemberInformationView extends StatefulWidget {

  final String username;

  const MemberInformationView({super.key, required this.username});

  @override
  _MembershipClearViewState createState() => _MembershipClearViewState();
}

class _MembershipClearViewState extends State<MemberInformationView> {

  bool _isSwitched = false;

  @override
  void initState() {
    super.initState();
    _loadAutoLogin(); // 자동 로그인 상태 불러오기
  }

  //SharedPreferences에서 자동 로그인 상태 불러오기
  Future<void> _loadAutoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitched = prefs.getBool('auto_login') ?? false; // 기본값 true
    });
  }
  Future<void> _saveAutoLogin(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login', value);
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() async {
      await prefs.remove('firebase_token');
      await prefs.remove('auto_login');
      await prefs.remove('username');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const AppBarLayerView('마이페이지'),
        centerTitle: true,
        // 기본 뒤로가기 버튼 사용 (custom leading 속성 제거)
      ),
      body: SingleChildScrollView(  // ← 이 부분이 핵심! Column을 SingleChildScrollView로 감싸기
        child: Padding(
          padding: EdgeInsets.only(
            right: getSize20().toDouble(),
            left: getSize20().toDouble(),
            bottom: getSize20().toDouble(),
          ),
          child: Column(
            children: [
              // 프로필 이미지와 이름 (세로 배치로 변경)
              Padding(
                padding: EdgeInsets.only(top: getSize40().toDouble()),
                child: Column(
                  children: [
                    // 프로필 이미지 (+ 아이콘 제거)
                    Center(
                      child: SizedBox(
                        width: getSize96().toDouble(), // 원래 크기로 복원
                        height: getSize96().toDouble(),
                        child: SvgPicture.asset(
                          'assets/kdn/usm/img/defult_img.svg',
                          height: getSize96().toDouble(),
                          width: getSize96().toDouble(),
                        ),
                      ),
                    ),
                    // 이름과 환영 메시지 (세로 배치)
                    Padding(
                      padding: EdgeInsets.only(top: getSize6().toDouble()),
                      child: Column(
                        children: [
                          TextWidgetString('${widget.username}님', getTextcenter(), getSize20(), getText700(), getColorblack_type2()),
                          SizedBox(height: getSize8().toDouble()),
                          TextWidgetString('반갑습니다.', getTextcenter(), getSize12(), getText700(), getColorgray_Type3()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 프로필과 로그인/회원정보 섹션 사이 간격 추가
              SizedBox(height: getSize20().toDouble()),

              Padding(
                padding: EdgeInsets.only(top: getSize20().toDouble(), bottom: getSize20().toDouble()),
                child: Align(alignment: Alignment.centerLeft,
                  child: TextWidgetString('로그인/회원정보',getTextleft(),getSize20(),getText700(),getColorblack_type2(),
                  ),
                ),
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(right: getSize12().toDouble(),left: getSize12().toDouble(),bottom: getSize8().toDouble(), top:getSize8().toDouble()),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextWidgetString('로그인 정보',getTextleft(),getSize16(),getText700(),getColorgray_Type3(),),
                        const Spacer(),

                        GestureDetector(
                          onTap: () async {
                            _logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginView()),
                                  (Route<dynamic> route) => false,
                            );
                          },
                          child: TextWidgetString('로그아웃',getTextleft(),getSize16(),getText700(),getColorred_type3(),),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              Divider(
                thickness: 1,  // 선의 두께
                height: 12,     // Divider 위아래 간격
                indent: 0,     // 좌측 여백
                endIndent: 0,  // 우측 여백
                color: getColorgray_Type10(), // 색상
              ),

              Padding(
                padding: EdgeInsets.only(right: getSize12().toDouble(),left: getSize12().toDouble()),
                child:Align(alignment: Alignment.centerLeft,
                    child: Row(
                        children: [
                          TextWidgetString('자동 로그인',getTextleft(),getSize16(),getText700(),getColorgray_Type3()),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSwitched = !_isSwitched;
                                _saveAutoLogin(_isSwitched);
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: getSize70().toDouble(),
                              height: getSize36().toDouble(),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  // ✅ 테두리 색 변경 가능
                                  color: _isSwitched ? getColorsky_Type2() : getColorgray_Type11(),
                                ),
                                color:
                                _isSwitched ? getColorsky_Type2() : getColorgray_Type11(),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    left: _isSwitched ? getSize30().toDouble() : getSize0().toDouble(),
                                    right: _isSwitched ? getSize0().toDouble() : getSize30().toDouble(),
                                    top: getSize4().toDouble(), // 상단 간격 추가
                                    bottom: getSize4().toDouble(), // 하단 간격 추가
                                    child: Container(
                                      width: getSize30().toDouble(),
                                      height: getSize30().toDouble(),

                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                        _isSwitched ? getColorwhite_type1() : getColorwhite_type1(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                    )
                ),
              ),
              Divider(
                thickness: 1,  // 선의 두께
                height: 12,     // Divider 위아래 간격
                indent: 0,     // 좌측 여백
                endIndent: 0,  // 우측 여백
                color: getColorgray_Type10(), // 색상
              ),

              Container(
                child: Padding(
                  padding: EdgeInsets.only(right: getSize12().toDouble(),left: getSize12().toDouble(),bottom: getSize8().toDouble(), top:getSize8().toDouble()),
                  child: GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      Navigator.push(
                        context,
                        createSlideTransition(
                          MemberInformationChange(nowTime: now),
                        ),
                      );
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          TextWidgetString(
                            '회원정보 수정',
                            getTextleft(),
                            getSize16(),
                            getText700(),
                            getColorgray_Type3(),
                          ),
                          Spacer(),
                          SvgPicture.asset(
                            'assets/kdn/usm/img/chevron-right_type1.svg',
                            height: getSize24().toDouble(),
                            width: getSize24().toDouble(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 키보드가 올라와도 충분한 여백 확보
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + getSize50().toDouble()),
            ],
          ),
        ),
      ),
    );
  }
}