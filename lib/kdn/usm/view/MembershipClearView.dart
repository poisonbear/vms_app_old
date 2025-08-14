import 'dart:io'; // File 사용 시 필요
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/kdn/usm/view/LoginView.dart';
import 'package:vms_app/kdn/usm/view/MembershipView.dart';
import 'package:vms_app/kdn/cmm/common_action.dart'; // createSlideTransition 함수 정의 파일 import
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/layer/AppBarLayerView.dart';

class MembershipClearView extends StatefulWidget {
  const MembershipClearView({super.key, });

  @override
  _MembershipClearViewState createState() => _MembershipClearViewState();
}

class _MembershipClearViewState extends State<MembershipClearView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        leading:  IconButton(
          icon: svgload('assets/kdn/usm/img/arrow-left.svg', getSize24().toDouble(), getSize24().toDouble()),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView(),
                ),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(getSize20().toDouble()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Row(children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(left: getSize8().toDouble()),
                  child: SvgPicture.asset(
                    'assets/kdn/usm/img/Frame_one_off.svg',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: getSize8().toDouble()),
                  child: SvgPicture.asset(
                    'assets/kdn/usm/img/Frame_two_off.svg',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: getSize8().toDouble()),
                  child: SvgPicture.asset(
                    'assets/kdn/usm/img/Frame_three_on.svg',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                )
              ]),
            ),
            // 이미지 추가 섹션
            Spacer(),
            Container(
              height: 500, // 원하는 높이
              width: double.infinity, // 원하는 너비
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/kdn/usm/img/membership_clear2.png'), // 배경 이미지 경로
                  fit: BoxFit.contain, // 이미지를 컨테이너에 맞게 채움
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      SizedBox(height: getSize20().toDouble()), // 간격 추가
                      TextWidgetString('K-VMS', getTextleft(), getSize32(), getText700(), getColorblack_type2()),
                      TextWidgetString('회원가입완료', getTextleft(), getSize32(), getText700(), getColorsky_Type2()),
                      TextWidgetString('K-VMS 회원가입을 완료하였습니다.', getTextleft(), getSize12(), getText700(), getColorgray_Type2()),
                      TextWidgetString('이제 모든 서비스를 이용하실 수 있습니다.', getTextleft(), getSize12(), getText700(), getColorgray_Type2()),
                    ],
                  ),
                  Positioned(
                    bottom: 0, // 버튼을 화면 아래쪽에 배치
                    left: 0,
                    right: 0,

                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginView(),),
                                (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getColorsky_Type2(),
                            shape: getTextradius6(),
                            elevation: 0,
                            padding: EdgeInsets.all(getSize18().toDouble()),
                          ),
                          child: TextWidgetString(
                            '로그인 하기',
                            getTextcenter(),
                            getSize16(),
                            getText700(),
                            getColorwhite_type1(),
                          ),
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
