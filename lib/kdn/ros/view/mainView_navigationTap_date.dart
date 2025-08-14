import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:collection/collection.dart';
import 'mainView_navigationTap.dart';

class MainViewNavigationDate extends StatefulWidget {
  final String title;

  MainViewNavigationDate({required this.title});

  @override
  _MainViewNavigationDateState createState() => _MainViewNavigationDateState();
}

class _MainViewNavigationDateState extends State<MainViewNavigationDate> {
  String _selectedDay = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";  // 선택된 날짜 저장
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
  void initState() {
    super.initState();
    // 시작일자 또는 종료일자 선택 화면에 따라 초기값 설정
    if (widget.title == '시작일자 선택') {
      _selectedDay = selectedStartDate;
    } else if (widget.title == '종료일자 선택') {
      _selectedDay = selectedEndDate;
    }
  }

  // 안전하게 화면 전환하는 함수
  void safelyNavigateBack() {
    // 위젯이 아직 마운트 상태인지 확인
    if (mounted) {
      // 전역 변수는 DateTime 타입이므로 String으로 변환하지 않고 바로 할당
      if (widget.title == '시작일자 선택') {
        selectedStartDate = _selectedDay; // DateTime 그대로 할당

      } else if (widget.title == '종료일자 선택') {
        selectedEndDate = _selectedDay; // DateTime 그대로 할당

      }

      // 현재 화면 닫기
      Navigator.pop(context);

      // 약간의 딜레이 후 항행이력 화면 열기
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _bottomSheetController = Scaffold.of(context).showBottomSheet(
                (context) {
              return MainViewNavigationSheet(
                onClose: () {

                },
                resetDate: false, // 날짜 초기화하지 않도록 설정
                resetSearch: false, // MMSI, 선박명 초기화하지 않음
              );
            },
            backgroundColor: getColorblack_type3(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼이 눌리면 BottomSheet를 다시 연다
        safelyNavigateBack();
        return false; // 뒤로가기 이벤트를 막음 (앱이 종료되지 않도록)
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidgetString(
                    widget.title,
                    getTextleft(),
                    getSize20(),
                    getText700(),
                    getColorblack_type2(),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: SvgPicture.asset('assets/kdn/usm/img/close.svg', width: 24, height: 24),
                      onPressed: () {
                        safelyNavigateBack();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: TableCalendar(
                  locale: 'ko_KR',
                  focusedDay: _parseDate(_selectedDay),
                  firstDay: DateTime(1900, 1, 1),
                  lastDay: DateTime(2999, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_parseDate(_selectedDay), day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    // 1. 안전하게 상태 업데이트
                    if (mounted) {
                      setState(() {
                        // DateTime을 String으로 변환
                        _selectedDay = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                      });
                    }

                    // 2. 전역 변수에 선택한 날짜 저장 (String 형식으로 변환)
                    if (widget.title == '시작일자 선택') {
                      selectedStartDate = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    } else if (widget.title == '종료일자 선택') {
                      selectedEndDate = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                    }

                    // 3. 약간의 지연 후 화면 전환 (UI가 업데이트될 시간을 주기 위해)
                    Future.delayed(Duration(milliseconds: 100), () {
                      safelyNavigateBack();
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
                      bool isSelected = isSameDay(_parseDate(_selectedDay), day);
                      DateTime? holiday = holidays.firstWhereOrNull(
                              (holiday) => holiday.year == day.year && holiday.month == day.month && holiday.day == day.day);

                      return Container(
                        decoration: isSelected
                            ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
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
String formatDate(DateTime date) {
  return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
}
DateTime _parseDate(String dateString) {
  List<String> parts = dateString.split('-');
  if (parts.length == 3) {
    return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2])
    );
  }
  return DateTime.now(); // 변환 실패 시 현재 날짜 반환
}