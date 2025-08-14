import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 원형 버튼 위젯 - 지도 화면의 우측 버튼들에 사용
class CircularButton extends StatefulWidget {
  final String svgPath;
  final Color colorOn;
  final Color colorOff;
  final int widthSize;
  final int heightSize;
  final VoidCallback onTap;
  final bool initialState;

  const CircularButton({
    Key? key,
    required this.svgPath,
    required this.colorOn,
    required this.colorOff,
    required this.widthSize,
    required this.heightSize,
    required this.onTap,
    this.initialState = false,
  }) : super(key: key);

  @override
  CircularButtonState createState() => CircularButtonState();
}

class CircularButtonState extends State<CircularButton> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialState;
  }

  void toggleState() {
    setState(() {
      isOn = !isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        toggleState();
        widget.onTap();
      },
      child: Container(
        width: widget.widthSize.toDouble(),
        height: widget.heightSize.toDouble(),
        decoration: BoxDecoration(
          color: isOn ? widget.colorOn : widget.colorOff,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          widget.svgPath,
          width: 24.0,
          height: 24.0,
        ),
      ),
    );
  }
}