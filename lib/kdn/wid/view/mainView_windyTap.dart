import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';

import 'package:vms_app/kdn/wid/viewModel/WidWeatherInfoViewModel.dart';


// 택스트 위젯 - string
Widget mainViewWindy(context, {Function? onClose}) {
  PersistentBottomSheetController? _bottomSheetController;
  return FutureProvider<WidWeatherInfoViewModel>(
    create: (_) async {
      final viewModel = WidWeatherInfoViewModel();
      await viewModel.getWidList();
      return viewModel;
    },
    initialData: WidWeatherInfoViewModel(),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // height: 450, // 고정 높이 제거
        constraints: BoxConstraints(
          minHeight: 350, // 최소 높이 설정
          maxHeight: MediaQuery.of(context).size.height * 0.61, // 화면 높이의 80%로 제한
        ),
        width: double.infinity,
        padding: EdgeInsets.all(getSize20().toDouble()),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 닫기 버튼 행
            Padding(
              padding: EdgeInsets.all(0),
              child: Row(
                children: [
                  Spacer(),
                  Container(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: SvgPicture.asset('assets/kdn/usm/img/close.svg', width: 24, height: 24,),
                        onPressed: () {
                          if (onClose != null) {
                            onClose();
                          }

                          // BottomSheet 닫기
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 제목 행
            Row(
              children: [
                TextWidgetString('기상정보', getTextleft(), getSize30(), getText700(), getColorblack_type2()),
              ],
            ),
            // 나머지 영역은 Expanded로 감싸서 스크롤 가능하게 만듦
            Flexible(
             child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 레이블 열
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: getSize6().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize10().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('시간', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize20().toDouble(), bottom: getSize37().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('풍향', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize10().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('풍속', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize10().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('파고', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize10().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('돌풍', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: getSize10().toDouble(), bottom: getSize10().toDouble(), left: getSize8().toDouble(), right: getSize8().toDouble()),
                          child: TextWidgetString('온도', getTextleft(), getSize16(), getText700(), getColorblack_type2()),
                        ),
                      ],
                    ),

                    // 오른쪽 데이터 영역 - 가로 스크롤로 변경
                    Expanded(
                      child: Consumer<WidWeatherInfoViewModel>(
                        builder: (context, provider, child) {
                          // 로딩 중인 경우 뻥글이(로딩 인디케이터) 표시
                          if (provider.isLoading) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.4, // 전체 높이의 절반을 사용
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          var widList = provider.WidList;
                          if (widList == null || widList.isEmpty) {
                            return Center(child: Text('데이터가 없습니다'));
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0; i < widList.length; i++)...[
                                  Column(
                                    children: [
                                      // 날짜
                                      Padding(
                                        padding: EdgeInsets.all(getSize10().toDouble()),
                                        child: TextWidgetString(
                                            ('${widList[i].ts}').substring(11, 13) == "00" || i == 0 ? ('${widList[i].ts}').substring(0, 10) : '', getTextleft(), getSize12(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: DottedBorder(
                                          borderType: BorderType.RRect,
                                          radius: Radius.circular(6),
                                          dashPattern: [6, 3],
                                          color: getColorgray_Type7(),
                                          strokeWidth: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: getColorgray_Type12(),
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: Column(
                                              children: [
                                                // 시간
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: TextWidgetString(
                                                      ('${widList[i].ts}').substring(11, 13) + '시', getTextleft(), getSize16(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                  ),
                                                ),
                                                // 풍향 아이콘
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: Column(
                                                    children: [
                                                      // 풍향 아이콘
                                                      FutureBuilder<Widget>(
                                                          future: svgload('assets/kdn/wid/img/gray_point_rotation0.svg', 40, 40,
                                                              i < provider.windIcon.length ? provider.windIcon[i] : "ro0",
                                                              i < provider.windSpeed.length ? provider.windSpeed[i] : "0 m/s"
                                                          ),
                                                          builder: (context, snapshot) {
                                                            if (snapshot.hasData) {
                                                              return snapshot.data!;
                                                            }
                                                            return SizedBox(width: 40, height: 40);
                                                          }
                                                      ),
                                                      // 풍향 텍스트
                                                      SizedBox(height: 5), // 아이콘과 텍스트 사이 간격
                                                      TextWidgetString(i < provider.windDirection.length ? provider.windDirection[i] : "", getTextleft(), getSize10(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // 풍속
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: TextWidgetString(i < provider.windSpeed.length ? provider.windSpeed[i] : "0 m/s", getTextleft(), getSize16(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                  ),
                                                ),
                                                // 파고
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: TextWidgetString(('${widList[i].wave_height?.toStringAsFixed(1)}' + ' m'), getTextleft(), getSize16(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                  ),
                                                ),
                                                // 돌풍
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: TextWidgetString(('${widList[i].gust_surface?.toStringAsFixed(0)}' + ' m/s'), getTextleft(), getSize16(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                  ),
                                                ),
                                                // 온도
                                                Padding(
                                                  padding: EdgeInsets.all(getSize10().toDouble()),
                                                  child: TextWidgetString(('${((widList[i].current_temp ?? 0) - 273.15).toStringAsFixed(0)}' + '°C'), getTextleft(), getSize16(), getText700(), i > 0 ? getColorblack_type2() : getColorsky_Type2()
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ],
                            ),
                          );
                        },
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
  );
}

Future<Widget> svgload(String svgurl, double height, double width, String windIcon, String windSpeed) async {
  try {
    print('SVG 로딩: url=$svgurl, windIcon=$windIcon, windSpeed=$windSpeed');

    // 기본값 사용
    final speedStr = windSpeed.isEmpty ? '0' : windSpeed.replaceAll('m/s', '').trim();
    final speed = double.tryParse(speedStr) ?? 0;

    final String svgString = await rootBundle.loadString(svgurl);
    String pathFillColor = '';

    if (speed < 5) {
      pathFillColor = '#666666';
    } else if (speed >= 5 && speed < 10) {
      pathFillColor = '#FFD700';
    } else if (speed >= 10) {
      pathFillColor = '#FF0000';
    }

    // 정규식으로 path 태그만 찾기
    RegExp pathRegex = RegExp(r'<path[^>]*>');
    RegExp strokeRectRegex = RegExp(r'<rect[^>]*stroke="#[0-9A-Fa-f]{6}"[^>]*>');
    String modifiedSvg = svgString;

    // path 태그를 찾아서 해당 부분만 fill 색상 변경
    modifiedSvg = modifiedSvg.replaceAllMapped(pathRegex, (Match match) {
      String matchText = match.group(0) ?? '';

      // fill 속성 변경
      if (matchText.contains('fill="#')) {
        return matchText.replaceAll(
            RegExp(r'fill="#[0-9A-Fa-f]{6}"'),
            'fill="$pathFillColor"'
        );
      }

      return matchText;
    });

    // stroke 속성이 있는 rect 태그 변경
    modifiedSvg = modifiedSvg.replaceAllMapped(strokeRectRegex, (Match match) {
      String matchText = match.group(0) ?? '';

      if (matchText.contains('stroke="#')) {
        return matchText.replaceAll(
            RegExp(r'stroke="#[0-9A-Fa-f]{6}"'),
            'stroke="$pathFillColor"');
      }
      return matchText;
    });

    // 기본 아이콘 사용
    final iconName = windIcon.isEmpty ? 'ro0' : windIcon;

    if (iconName.startsWith('ro')) {
      final angleStr = iconName.replaceAll('ro', '');
      final angle = int.tryParse(angleStr) ?? 0;
      return Transform.rotate(
        angle: angle * pi / 180,
        child: SvgPicture.string(
          modifiedSvg,
          height: height,
          width: width,
          fit: BoxFit.contain,
        ),
      );
    }

    return SvgPicture.string(
      modifiedSvg,
      height: height,
      width: width,
      fit: BoxFit.contain,
    );
  } catch (e) {
    print('SVG 로딩 오류: $e');
    // 오류 발생시 기본 위젯 반환
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.error_outline, size: 20),
      ),
    );
  }
}