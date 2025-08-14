
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:collection/collection.dart';
import 'mainView_windyTap.dart';

class MainViewWindyDate extends StatefulWidget {
  @override
  _MainViewWindyDateState createState() => _MainViewWindyDateState();
}

class _MainViewWindyDateState extends State<MainViewWindyDate> {
  DateTime _selectedDay = DateTime.now();  // ✅ 선택된 날짜 저장
  PersistentBottomSheetController? _bottomSheetController;
  final Set<DateTime> holidays = {
    DateTime(2025, 1, 1), DateTime(2025, 1, 28), DateTime(2025, 1, 29), DateTime(2025, 1, 30),
    DateTime(2025, 3, 1), DateTime(2025, 5, 5), DateTime(2025, 6, 6), DateTime(2025, 8, 15),
    DateTime(2025, 10, 3), DateTime(2025, 10, 9), DateTime(2025, 12, 25),
  };

  String getHolidayName(DateTime date) {
    Map<DateTime, String> holidayNames = {
      DateTime(2025, 1, 1): "신정", DateTime(2025, 1, 28): "", DateTime(2025, 1, 29): "설날", DateTime(2025, 1, 30): "",
      DateTime(2025, 3, 1): "삼일절", DateTime(2025, 5, 5): "어린이날", DateTime(2025, 6, 6): "현충일", DateTime(2025, 8, 15): "광복절",
      DateTime(2025, 10, 3): "개천절", DateTime(2025, 10, 9): "한글날", DateTime(2025, 12, 25): "성탄절",
    };
    return holidayNames[date] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ 뒤로가기 버튼이 눌리면 BottomSheet를 다시 연다
        _bottomSheetController = Scaffold.of(context).showBottomSheet(
              (context) {
            return mainViewWindy(context);
          },
          backgroundColor: getColorblack_type3(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)), // ✅ radius 제거
          ),
        );
        return false; // 🚨 뒤로가기 이벤트를 막음 (앱이 종료되지 않도록)
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 550,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Spacer(),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: SvgPicture.asset('assets/kdn/usm/img/close.svg', width: 24, height: 24),
                      onPressed: () => {
                        _bottomSheetController = Scaffold.of(context).showBottomSheet(
                              (context) {
                            return mainViewWindy(context);
                          },
                          backgroundColor: getColorblack_type3(),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(0)), // ✅ radius 제거
                          ),
                        )
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  TextWidgetString(
                    '날짜 선택',
                    getTextleft(),
                    getSize24(),
                    getText700(),
                    getColorblack_type2(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: TableCalendar(
                  locale: 'ko_KR',
                  focusedDay: _selectedDay,
                  firstDay: DateTime(1900, 1, 1),
                  lastDay: DateTime(2999, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getColorgreen_Type1(),
                    ),
                    todayDecoration: BoxDecoration(),
                    todayTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    todayBuilder: (context, date, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          TextWidgetString('오늘', getTextleft(), getSize14(), getText700(), getColorgray_Type3()),
                        ],
                      );
                    },
                    dowBuilder: (context, day) {
                      switch (day.weekday) {
                        case 1:
                          return const Center(child: Text('월', style: TextStyle(color: Colors.black)));
                        case 2:
                          return const Center(child: Text('화', style: TextStyle(color: Colors.black)));
                        case 3:
                          return const Center(child: Text('수', style: TextStyle(color: Colors.black)));
                        case 4:
                          return const Center(child: Text('목', style: TextStyle(color: Colors.black)));
                        case 5:
                          return const Center(child: Text('금', style: TextStyle(color: Colors.black)));
                        case 6:
                          return const Center(child: Text('토', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
                        case 7:
                          return const Center(child: Text('일', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                        default:
                          return const Center(child: Text(''));
                      }
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      bool isSelected = isSameDay(_selectedDay, day);
                      DateTime? holiday = holidays.firstWhereOrNull(
                              (holiday) => holiday.year == day.year && holiday.month == day.month && holiday.day == day.day);

                      return Container(
                        decoration: isSelected
                            ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2), // ✅ 선택된 날짜 동그란 테두리
                        )
                            : null,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: holiday != null || day.weekday == 7 ? Colors.red : Colors.black,
                                fontWeight: holiday != null || day.weekday == 7 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (holiday != null)
                              Text(
                                getHolidayName(holiday),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


