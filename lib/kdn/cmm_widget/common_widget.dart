import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'common_style_widget.dart';


// svg 파일 불러오기
Widget svgload(svgrul ,height ,width){
  return SvgPicture.asset(
    svgrul,
    height: height,
    width: width,
    fit: BoxFit.contain,
  );
}

// 택스트 위젯 - string
Widget TextWidgetString(title, TextAlign textarray , int size, FontWeight fontWeight, Color color,) {
  return Text(
    title,
    textAlign: textarray,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
    ),
  );
}

// 택스트 위젯 라인 - string
Widget TextWidgetStringLine(title, TextAlign textarray , int size, FontWeight fontWeight, Color color,) {
  return Text(
    title,
    textAlign: textarray,
    style: TextStyle(
      fontFamily: 'PretendardVariable',
      fontSize: size.toDouble(),
      fontWeight: fontWeight,
      color: color,
      decoration: TextDecoration.underline, // 밑줄 추가
    ),
  );
}

// 텍스트 입력값을 받을 때
Widget inputWidget(int widthsize,int heightsize,  TextEditingController controller , String title , Color color, {
  bool obscureText = false,
}) {


  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, decorationThickness: 0),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(fontSize: 16, color: color), // 힌트 스타일
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 기본 테두리 색상과 두께
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 포커스 시 테두리 색상과 두께
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 활성 상태 테두리 색상과 두께
        ),
      ),

    ),
  );


}

// 텍스트 입력값을 받을 때 - .svg 파일 필요 할 때
Widget inputWidgetSvg(int widthsize,int heightsize,  TextEditingController controller , String title , Color color , String svgPath){


  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, decorationThickness: 0),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(fontSize: 16, color: color), // 힌트 스타일
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 기본 테두리 색상과 두께
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 포커스 시 테두리 색상과 두께
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color), // 활성 상태 테두리 색상과 두께
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(12.0), // 아이콘 크기 조절
          child: SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,

          ),
        ),


      ),

    ),
  );


}
// 텍스트를 비활성화 할 때
Widget inputWidget_deactivate(
    int widthsize, int heightsize, TextEditingController controller, String title, Color color,
    {bool isEnabled = true,
     bool isReadOnly = false}) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, decorationThickness: 0),
      enabled: isEnabled, // 비활성화 여부 설정
      readOnly: isReadOnly, //읽기 여부 설정
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(fontSize: 16, color: color),
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
      ),
    ),
  );
}


void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(

    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10, // 상태바 아래 10px 간격
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: getColorgray_Type8(),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: getColorgray_Type9(), blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}




// 현재 날짜 구하기
String getCurrentDateString() {
  DateTime now = DateTime.now();
  return DateFormat('yyyy.MM.dd').format(now);
}

DateTime getCurrentDateDateTime() {
  DateTime now = DateTime.now();
  return DateTime.now();
}





