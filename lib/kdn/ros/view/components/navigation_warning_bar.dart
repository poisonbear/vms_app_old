import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/ros/viewModel/NavigationViewModel.dart';

/// 항행경보 바 컴포넌트
class NavigationWarningBar extends StatelessWidget {
  const NavigationWarningBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<RosNavigationViewModel>(
          builder: (context, viewModel, child) {
            return Container(
              height: 52,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: getColorred_type1(),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/kdn/ros/img/circle-exclamation_white.svg',
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(width: getSize8().toDouble()),
                  Expanded(
                    child: viewModel.combinedNavigationWarnings.isEmpty
                        ? Text(
                      '금일 항행경보가 없습니다.',
                      style: TextStyle(
                        color: getColorwhite_type1(),
                        fontSize: 16,
                        fontWeight: getText700(),
                      ),
                    )
                        : Marquee(
                      text: viewModel.combinedNavigationWarnings,
                      style: TextStyle(
                        color: getColorwhite_type1(),
                        fontSize: 16,
                        fontWeight: getText700(),
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: 300.0,
                      velocity: 50.0,
                      pauseAfterRound: Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: Duration(seconds: 1),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}