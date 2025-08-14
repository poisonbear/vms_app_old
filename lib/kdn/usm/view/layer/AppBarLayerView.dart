import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdServiceViewModel.dart';
import "package:vms_app/kdn/usm/model/CmdModel.dart";
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';


// 동적 페이지를 구현 할려면
class AppBarLayerView extends StatefulWidget { // StatefulWidget 상속받기
  final String title; // 만약 값을 받아야 한다면  변수 타입과, 변수명 설정 , 추가 설정도 가능
  const AppBarLayerView(this.title, {super.key});

  @override
  State<AppBarLayerView> createState() => _AppBarState();
}

class _AppBarState extends State<AppBarLayerView> {
  late List<CmdModel> cmdList; // 변수명도 camelCase로 수정

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: getSize16().toDouble(),bottom: getSize16().toDouble(),),
      child: TextWidgetString(widget.title,getTextcenter(),getSize20(),getText700(),getColorblack_type1(), // 받은값은 widget.title로 기재 가능

      ),
    );
  }
}