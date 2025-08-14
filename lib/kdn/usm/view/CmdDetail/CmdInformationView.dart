import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdInformationViewModel.dart';
import "package:vms_app/kdn/usm/model/CmdModel.dart";
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/layer/AppBarLayerView.dart';
import 'package:vms_app/kdn/usm/view/CmdChoiceView.dart';



class CmdInformationView extends StatefulWidget {
  const CmdInformationView({super.key});

  @override
  State<CmdInformationView> createState() => _CmdViewState();
}

class _CmdViewState extends State<CmdInformationView> {
  late List<CmdModel> CmdList;


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      // 앱 상단 제목
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


      body: Consumer<CmdInformationViewModel>( // 데이터를 불러 올 때는 Consumer 항상 viewmodel을 거쳐서 가져오기

        builder: (context, provider, child) {
          CmdList = provider.CmdList!;
          return ListView.builder(
            itemCount: CmdList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(getSize20().toDouble()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 1 , 2, 3
                    Padding(
                      padding: EdgeInsets.only(bottom:  getSize20().toDouble()),
                      child: Row(
                          children: [
                            const Spacer(),
                            Padding(
                              padding: EdgeInsets.only(left: getSize8().toDouble()),
                              child: svgload('assets/kdn/usm/img/Frame_one_on.svg',getSize32().toDouble(),getSize32().toDouble()),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: getSize8().toDouble()),
                              child: svgload('assets/kdn/usm/img/Frame_two_off.svg',getSize32().toDouble(),getSize32().toDouble()),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: getSize8().toDouble()),
                              child: svgload('assets/kdn/usm/img/Frame_three_off.svg',getSize32().toDouble(),getSize32().toDouble()),
                            )

                          ]
                      ),
                    ),

                    // 제목
                    TextWidgetString('K-VMS',getTextcenter(),getSize32(),getText700(),getColorblack_type2()),
                    TextWidgetString('약관동의',getTextcenter(),getSize32(),getText700(),getColorblack_type2()),

                    // 소제목
                    Padding(
                      padding: EdgeInsets.only(top: getSize12().toDouble() , bottom: getSize40().toDouble()),
                      child: TextWidgetString('회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',getTextcenter(),getSize12(),getText700(),getColorgray_Type2()),
                    ),

                    // 약관타입
                    Padding(
                        padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                        child: Row(
                            children: [
                              TextWidgetString('${CmdList[0].terms_nm}',getTextcenter(),getSize20(),getText700(),getColorblack_type1()),
                              Padding(
                                  padding: EdgeInsets.only(left: getSize4().toDouble()),
                                  child : TextWidgetString('필수',getTextcenter(),getSize12(),getText700(),getColorsky_Type2())
                              ),]
                        )
                    ),

                    // 약관 전체내용
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.55, // 화면 높이의 50%로 제한
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: getColorgray_Type4(), // 테두리 색상
                          width: getSize1().toDouble(), // 테두리 두께
                        ),
                        borderRadius: BorderRadius.circular(getSize4().toDouble()), // 테두리 둥글게
                      ),
                      padding: EdgeInsets.all(getSize20().toDouble()), // 내부 여백
                      child: SingleChildScrollView( // 스크롤 가능하도록 추가
                        child: TextWidgetString(
                          '${CmdList[0].terms_ctt}', // 약관 내용
                          getTextleft(),
                          getSize14(),
                          getTextnormal(),
                          getColorblack_type1(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
