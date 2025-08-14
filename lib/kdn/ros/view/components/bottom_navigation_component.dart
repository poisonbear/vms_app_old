import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';

/// 하단 네비게이션 바 컴포넌트
class BottomNavigationComponent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationComponent({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: getColorgray_Type4(), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: getColorgray_Type8(),
        unselectedItemColor: getColorgray_Type2(),
        selectedLabelStyle: TextStyle(
          fontSize: getSize16().toDouble(),
          fontWeight: getText700(),
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: getSize16().toDouble(),
          fontWeight: getText700(),
        ),
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: <BottomNavigationBarItem>[
          _buildNavigationItem(
            index: 0,
            selectedIcon: 'assets/kdn/ros/img/Home_on.svg',
            unselectedIcon: 'assets/kdn/ros/img/Home_off.svg',
            label: '홈',
          ),
          _buildNavigationItem(
            index: 1,
            selectedIcon: 'assets/kdn/ros/img/cloud-sun_on.svg',
            unselectedIcon: 'assets/kdn/ros/img/cloud-sun_off.svg',
            label: '기상정보',
          ),
          _buildNavigationItem(
            index: 2,
            selectedIcon: 'assets/kdn/ros/img/ship_on.svg',
            unselectedIcon: 'assets/kdn/ros/img/ship_off.svg',
            label: '항행이력',
          ),
          _buildNavigationItem(
            index: 3,
            selectedIcon: 'assets/kdn/ros/img/user-alt-1_on.svg',
            unselectedIcon: 'assets/kdn/ros/img/user-alt-1_off.svg',
            label: '마이',
          ),
        ],
      ),
    );
  }

  /// 네비게이션 아이템 빌드
  BottomNavigationBarItem _buildNavigationItem({
    required int index,
    required String selectedIcon,
    required String unselectedIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(bottom: getSize8().toDouble()),
        child: Column(
          children: [
            SizedBox(height: getSize12().toDouble()),
            Container(
              width: getSize24().toDouble(),
              height: getSize24().toDouble(),
              child: SvgPicture.asset(
                selectedIndex == index ? selectedIcon : unselectedIcon,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}