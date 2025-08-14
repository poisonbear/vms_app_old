import 'package:flutter/material.dart';

class FindAccountView extends StatefulWidget {
  const FindAccountView({super.key});

  @override
  State<FindAccountView> createState() => _FindAccountViewState();
}

class _FindAccountViewState extends State<FindAccountView> with SingleTickerProviderStateMixin {
  // 변경 사항: isEmailSelected 변수를 유지하되 항상 true로 설정 (다른 코드에 영향 없도록)
  bool isEmailSelected = true;

  // TabController 추가
  late TabController _tabController;

  // TextField 컨트롤러 추가
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // 버튼 활성화 상태 관리 변수 추가
  bool _isIdTabButtonActive = false;
  bool _isPasswordTabButtonActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 탭 변경 시 이벤트 리스너 추가
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 탭이 변경될 때 텍스트 필드 비우기
        _emailController.clear();
        _idController.clear();
        // 버튼 상태 초기화
        setState(() {
          _isIdTabButtonActive = false;
          _isPasswordTabButtonActive = false;
        });
      }
    });

    // 텍스트 필드 입력 감지 리스너 추가
    _emailController.addListener(_updateButtonState);
    _idController.addListener(_updateButtonState);
  }

  // 버튼 상태 업데이트 함수
  void _updateButtonState() {
    setState(() {
      // 아이디 찾기 탭 버튼 활성화 여부 (이메일 입력 있을 때)
      if (_tabController.index == 0) {
        _isIdTabButtonActive = _emailController.text.isNotEmpty;
      }
      // 비밀번호 찾기 탭 버튼 활성화 여부 (아이디와 이메일 모두 입력 있을 때)
      else if (_tabController.index == 1) {
        _isPasswordTabButtonActive = _idController.text.isNotEmpty && _emailController.text.isNotEmpty;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      // 키보드가 UI를 밀어올리지 않도록 설정
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78), // 전체 높이 조절
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // 기본 back 제거
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 28), // 상태바 밑 여백
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF333333)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '아이디/비밀번호 찾기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 오른쪽 여백 확보 (아이콘 자리 맞춤용)
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // TabBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 2.5, color: Color(0xFF333333)),
                    insets: EdgeInsets.zero, // 양쪽 끝 여백 없애기
                  ),
                  indicatorPadding: EdgeInsets.zero,  // indicatorPadding을 없애서 밑줄을 탭 끝까지 꽉 차게 만듦
                  indicatorSize: TabBarIndicatorSize.tab,  // 탭 크기만큼 밑줄 설정
                  labelColor: const Color(0xFF333333),
                  unselectedLabelColor: const Color(0xFFD1D1D1),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                  tabs: const [
                    SizedBox(width: 200, child: Tab(text: '아이디 찾기')),
                    SizedBox(width: 200, child: Tab(text: '비밀번호 찾기')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 콘텐츠 영역 - 스크롤 가능
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 첫 번째 탭: 아이디 찾기
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 96), // 버튼 높이 + 패딩
                        child: _buildEmailVerificationSection(),
                      ),
                    ),

                    // 두 번째 탭: 비밀번호 찾기
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 96), // 버튼 높이 + 패딩
                        child: _buildPasswordFindSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 하단 고정 버튼 - 스택을 사용하여 위치 고정
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFF9F9F9), // 배경색 설정
              child: _tabController.index == 0
                  ? _buildActionButton('이메일로 아이디 찾기', _isIdTabButtonActive)
                  : _buildActionButton('비밀번호 찾기', _isPasswordTabButtonActive),
            ),
          ),
        ],
      ),
    );
  }

  // 본문 이메일 인증
  Widget _buildEmailVerificationSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이메일 인증',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'Pretendard',
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '가입 시 이메일을 입력하여 주시기 바랍니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF999999),
              fontFamily: 'Pretendard',
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: '@포함한 이메일 입력',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B0B0),
                  fontFamily: 'Pretendard',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

//비밀번호 찾기
  Widget _buildPasswordFindSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 여기서 Text 위젯을 Row 위젯으로 변경
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '아이디',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                  fontFamily: 'Pretendard',
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3), // 텍스트와 원 사이 간격
              CustomPaint(
                size: const Size(4, 4), // 원 크기 (4x4)
                painter: RedCirclePainter(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _idController,
              decoration: InputDecoration(
                hintText: '아이디를 입력해주세요',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B0B0),  // 이메일 힌트와 동일한 회색으로 변경
                  fontFamily: 'Pretendard',
                ),
                // suffixIcon 제거함
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '이메일 입력',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'Pretendard',
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '가입 시 이메일을 입력하여 주시기 바랍니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF999999),
              fontFamily: 'Pretendard',
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: '@포함한 이메일 입력',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B0B0),
                  fontFamily: 'Pretendard',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 버튼 위젯 - isActive 파라미터 추가
  Widget _buildActionButton(String buttonText, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          // 활성화 상태에 따라 onPressed 설정
          onPressed: isActive ? () {} : null,
          style: ElevatedButton.styleFrom(
            // 활성화 상태에 따라 배경색 변경
            backgroundColor: isActive ? const Color(0xFF5CA1F6) : const Color(0xFFCCCCCC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.zero, // 내부 padding 제거
          ),
          child: Center(
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
                color: Colors.white,
                height: 1.0, // 라인 높이 조정
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// RedCirclePainter 클래스 추가
class RedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}