import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';

/// 파고/시정 상태 표시 버튼 위젯
class WeatherStatusButton extends StatelessWidget {
  final String svgPath;
  final Color color;
  final String labelText;
  final String statusText;
  final bool isSelected;
  final VoidCallback? onTap;

  const WeatherStatusButton({
    Key? key,
    required this.svgPath,
    required this.color,
    required this.labelText,
    required this.statusText,
    this.isSelected = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: getSize12().toDouble()),
      child: SizedBox(
        width: getSize160().toDouble(),
        height: getSize56().toDouble(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 확장/축소되는 배경
            Positioned(
              left: 0,
              top: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: isSelected ? getSize160().toDouble() : getSize56().toDouble(),
                height: getSize56().toDouble(),
                decoration: BoxDecoration(
                  color: getColorblack_type1(),
                  borderRadius: BorderRadius.circular(getSize30().toDouble()),
                ),
              ),
            ),

            // 텍스트 영역 (확장 시에만 표시)
            if (isSelected)
              Positioned(
                left: getSize56().toDouble() + 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidgetString(
                          labelText,
                          getTextleft(),
                          getSize14(),
                          getText700(),
                          getColorgray_Type2()
                      ),
                      TextWidgetString(
                          statusText,
                          getTextleft(),
                          getSize14(),
                          getText700(),
                          getColorwhite_type1()
                      ),
                    ],
                  ),
                ),
              ),

            // 원형 아이콘 (항상 왼쪽에 고정)
            Positioned(
              left: 0,
              top: 0,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: getSize56().toDouble(),
                  height: getSize56().toDouble(),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    svgPath,
                    width: getSize24().toDouble(),
                    height: getSize24().toDouble(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}