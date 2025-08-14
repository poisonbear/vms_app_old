import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';

/// 경고 팝업 관리 클래스
class WarningPopups {

  /// 터빈 진입 경고 팝업
  static void showTurbineWarningPopup(
      BuildContext context,
      String title,
      String message,
      VoidCallback onClose,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildWarningDialog(
          context: context,
          title: "터빈 구역 진입 금지 경고",
          message: "터빈 진입 금지 구역입니다. 지금 바로 우회하세요.",
          iconPath: 'assets/kdn/home/img/red_triangle-exclamation.svg',
          onClose: onClose,
        );
      },
    );
  }

  /// 기상 경고 팝업
  static void showWeatherWarningPopup(
      BuildContext context,
      String title,
      String message,
      VoidCallback onClose,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildWarningDialog(
          context: context,
          title: title,
          message: message,
          iconPath: 'assets/kdn/home/img/red_triangle-exclamation.svg',
          onClose: onClose,
        );
      },
    );
  }

  /// 해저케이블 경고 팝업
  static void showSubmarineCableWarningPopup(
      BuildContext context,
      String title,
      String message,
      VoidCallback onClose,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildWarningDialog(
          context: context,
          title: "해저케이블 구역 진입 경보",
          message: "해저케이블 구역입니다. 지금 바로 우회하세요.",
          iconPath: 'assets/kdn/home/img/red_triangle-exclamation.svg',
          onClose: onClose,
        );
      },
    );
  }

  /// 공통 경고 다이얼로그 빌더
  static Widget _buildWarningDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String iconPath,
    required VoidCallback onClose,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 310,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 60,
              height: 60,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDF2B2E),
                height: 1.0,
                letterSpacing: 0,
                fontFamily: 'Pretendard Variable',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Container(
              width: 300,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                  height: 1.0,
                  letterSpacing: 0,
                  fontFamily: 'Pretendard Variable',
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: 32),
            Container(
              width: 270,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: Color(0xFF5CA1F6), width: 1),
                  ),
                  elevation: 0,
                  minimumSize: Size(270, 48),
                ),
                child: Text(
                  "알람 종료하기",
                  style: TextStyle(
                    color: Color(0xFF5CA1F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}