// lib/kdn/usm/view/MembershipView.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../cmm/constants.dart';
import '../../cmm/common_utils.dart';
import '../../cmm/api_service.dart';
import '../../cmm_widget/common_widget.dart';
import '../../cmm_widget/common_style_widget.dart';
import '../../cmm_widget/common_size_widget.dart';
import '../helper/membership_validator.dart';
import 'MembershipClearView.dart';
import 'CmdChoiceView.dart';

class Membershipview extends StatefulWidget {
  final DateTime nowTime;

  const Membershipview({super.key, required this.nowTime});

  @override
  State<Membershipview> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<Membershipview> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mmsiController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailDomainController = TextEditingController();

  // Services
  final _userApiService = UserApiService();

  // State
  bool _isLoading = false;
  int? _idAvailability;

  // Validation States
  bool _isIdValid = true;
  bool _isPasswordValid = true;
  bool _isMmsiValid = true;
  bool _isPhoneValid = true;
  bool _isEmailValid = true;

  // Email Domain Options
  final List<String> _emailDomains = ['naver.com', 'gmail.com', 'hanmail.net'];
  String? _selectedEmailDomain;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mmsiController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emailDomainController.dispose();
    super.dispose();
  }

  /// 입력 리스너 설정
  void _setupListeners() {
    _idController.addListener(_validateId);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
    _mmsiController.addListener(_validateMmsi);
    _phoneController.addListener(_validatePhone);
    _emailController.addListener(_validateEmail);
    _emailDomainController.addListener(_validateEmail);
  }

  /// 아이디 유효성 검사
  void _validateId() {
    setState(() {
      final result = MembershipValidator.validateId(_idController.text);
      _isIdValid = result.isValid;

      // 아이디가 변경되면 중복확인 초기화
      if (_idAvailability != null) {
        _idAvailability = null;
      }
    });
  }

  /// 비밀번호 유효성 검사
  void _validatePassword() {
    setState(() {
      final result = MembershipValidator.validatePassword(_passwordController.text);
      _isPasswordValid = result.isValid;
    });
  }

  /// MMSI 유효성 검사
  void _validateMmsi() {
    setState(() {
      final result = MembershipValidator.validateMmsi(
        _mmsiController.text,
        isRequired: false,
      );
      _isMmsiValid = result.isValid;
    });
  }

  /// 휴대폰 번호 유효성 검사
  void _validatePhone() {
    setState(() {
      final result = MembershipValidator.validatePhone(
        _phoneController.text,
        isRequired: false,
      );
      _isPhoneValid = result.isValid;
    });
  }

  /// 이메일 유효성 검사
  void _validateEmail() {
    setState(() {
      final result = MembershipValidator.validateEmail(
        _emailController.text,
        _emailDomainController.text,
        isRequired: false,
      );
      _isEmailValid = result.isValid;
    });
  }

  /// 아이디 중복 확인
  Future<void> _checkIdDuplicate() async {
    final id = _idController.text.trim();

    // 유효성 검사
    final validation = MembershipValidator.validateId(id);
    if (!validation.isValid) {
      SnackBarUtils.showTopSnackBar(context, validation.message!);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _userApiService.checkIdDuplicate(id);

      if (response.success && response.data != null) {
        setState(() {
          _idAvailability = response.data;
        });

        final message = _idAvailability == 0
            ? ValidationMessages.idAvailable
            : ValidationMessages.idAlreadyUsed;

        SnackBarUtils.showTopSnackBar(context, message);
      }
    } catch (e) {
      debugPrint('아이디 중복 확인 오류: $e');
      SnackBarUtils.showTopSnackBar(context, AppConstants.msgServerError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 회원가입 처리
  Future<void> _handleSignUp() async {
    // 폼 유효성 검사
    final validation = MembershipValidator.validateForm(
      id: _idController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      mmsi: _mmsiController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      emailDomain: _emailDomainController.text,
      idAvailability: _idAvailability,
    );

    if (!validation.isValid) {
      SnackBarUtils.showTopSnackBar(context, validation.firstError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase 사용자 생성
      final firebaseUid = await _createFirebaseUser();
      if (firebaseUid == null) return;

      // 서버에 회원가입 요청
      await _registerToServer(firebaseUid);

      // 성공 시 완료 화면으로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MembershipClearView(),
          ),
        );
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      SnackBarUtils.showTopSnackBar(context, '회원가입 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Firebase 사용자 생성
  Future<String?> _createFirebaseUser() async {
    try {
      final id = _idController.text.trim();
      final password = _passwordController.text;

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: '$id${AppConstants.emailDomain}',
        password: password,
      );

      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return null;
    }
  }

  /// Firebase 에러 처리
  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = '이미 사용 중인 아이디입니다.';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다.';
        break;
      case 'network-request-failed':
        message = '네트워크 연결을 확인해주세요.';
        break;
      default:
        message = '회원가입 중 오류가 발생했습니다.';
    }
    SnackBarUtils.showTopSnackBar(context, message);
  }

  /// 서버 회원가입
  Future<void> _registerToServer(String firebaseUid) async {
    final userData = {
      'user_id': _idController.text.trim(),
      'user_pwd': _passwordController.text,
      'mmsi': _mmsiController.text,
      'mphn_no': _phoneController.text,
      'choice_time': widget.nowTime.toIso8601String(),
      'firebase_uuid': firebaseUid,
    };

    // 이메일이 입력된 경우에만 추가
    if (_emailController.text.isNotEmpty && _emailDomainController.text.isNotEmpty) {
      userData['email_addr'] = '${_emailController.text}@${_emailDomainController.text}';
    }

    final response = await _userApiService.register(userData: userData);

    if (!response.success) {
      throw Exception(response.error ?? '회원가입 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // AppBarLayerView를 일반 Text 위젯으로 변경
        title: Text(
          '회원가입',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: svgload('assets/kdn/usm/img/arrow-left.svg', 24, 24),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  /// 메인 바디
  Widget _buildBody() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: getSize20().toDouble(),
              right: getSize20().toDouble(),
              top: getSize20().toDouble(),
              bottom: MediaQuery.of(context).viewInsets.bottom + getSize20().toDouble(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressIndicator(),
                _buildTitle(),
                _buildSubtitle(),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// 진행 표시기
  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: getSize20().toDouble()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          svgload('assets/kdn/usm/img/Frame_one_off.svg', 32, 32),
          const SizedBox(width: 8),
          svgload('assets/kdn/usm/img/Frame_two_on.svg', 32, 32),
          const SizedBox(width: 8),
          svgload('assets/kdn/usm/img/Frame_three_off.svg', 32, 32),
        ],
      ),
    );
  }

  /// 제목
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidgetString('K-VMS', getTextleft(), getSize32(), getText700(), getColorblack_type2()),
        TextWidgetString('회원정보입력', getTextleft(), getSize32(), getText700(), getColorblack_type2()),
      ],
    );
  }

  /// 부제목
  Widget _buildSubtitle() {
    return Padding(
      padding: EdgeInsets.only(top: getSize12().toDouble()),
      child: TextWidgetString(
        '회원가입을 위한 필요 정보를 입력해주시기 바랍니다.',
        getTextleft(),
        getSize12(),
        getText700(),
        getColorgray_Type2(),
      ),
    );
  }

  /// 입력 폼
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdField(),
          _buildPasswordField(),
          _buildPasswordConfirmField(),
          _buildMmsiField(),
          _buildPhoneField(),
          _buildEmailField(),
        ],
      ),
    );
  }

  /// 아이디 입력 필드
  Widget _buildIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('아이디', isRequired: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: inputWidgetSvg(
                100,
                48,
                _idController,
                '아이디',
                getColorgray_Type7(),
                'assets/kdn/usm/img/circle-xmark.svg',
              ),
            ),
            const SizedBox(width: 20),
            _buildDuplicateCheckButton(),
          ],
        ),
        _buildIdValidationMessage(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 중복확인 버튼
  Widget _buildDuplicateCheckButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _checkIdDuplicate,
      style: ElevatedButton.styleFrom(
        backgroundColor: getColorwhite_type1(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: getColorgray_Type7(), width: 1),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      ),
      child: TextWidgetString('중복확인', getTextcenter(), getSize16(), getText700(), getColorgray_Type2()),
    );
  }

  /// 아이디 유효성 메시지
  Widget _buildIdValidationMessage() {
    if (!_isIdValid) {
      return _buildValidationMessage(ValidationMessages.idFormat, getColorred_type3());
    }

    if (_idAvailability == 0) {
      return _buildValidationMessage(ValidationMessages.idAvailable, getColorgreen_Type1());
    }

    if (_idAvailability == 1) {
      return _buildValidationMessage(ValidationMessages.idAlreadyUsed, getColorred_type3());
    }

    return const SizedBox.shrink();
  }

  /// 비밀번호 입력 필드
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('비밀번호', isRequired: true),
        const SizedBox(height: 8),
        inputWidget(266, 48, _passwordController, '비밀번호', getColorgray_Type7(), obscureText: true),
        if (!_isPasswordValid)
          _buildValidationMessage(ValidationMessages.passwordFormat, getColorred_type3()),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 비밀번호 확인 필드
  Widget _buildPasswordConfirmField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('비밀번호 확인', isRequired: true),
        const SizedBox(height: 8),
        inputWidget(266, 48, _confirmPasswordController, '비밀번호 확인', getColorgray_Type7(), obscureText: true),
        const SizedBox(height: 16),
      ],
    );
  }

  /// MMSI 입력 필드
  Widget _buildMmsiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('선박 MMSI 번호', isRequired: true),
        const SizedBox(height: 8),
        inputWidget(266, 48, _mmsiController, 'MMSI 번호(숫자 9자리)를 입력해주세요', getColorgray_Type7()),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 휴대폰 번호 입력 필드
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('휴대폰 번호', isRequired: false),
        const SizedBox(height: 8),
        inputWidget(266, 48, _phoneController, "'-' 구분없이 숫자만 입력", getColorgray_Type7()),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 이메일 입력 필드
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('이메일', isRequired: false),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: inputWidget(133, 48, _emailController, '이메일 아이디', getColorgray_Type7()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextWidgetString('@', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
            ),
            Expanded(
              child: _buildEmailDomainSelector(),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 이메일 도메인 선택기
  Widget _buildEmailDomainSelector() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: _emailDomainController,
          decoration: InputDecoration(
            filled: true,
            fillColor: getColorwhite_type1(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        PopupMenuButton<String>(
          icon: SvgPicture.asset('assets/kdn/usm/img/down_select_img.svg', width: 24, height: 24),
          color: Colors.white,
          onSelected: (String value) {
            setState(() {
              _selectedEmailDomain = value;
              _emailDomainController.text = value;
            });
          },
          itemBuilder: (BuildContext context) {
            return _emailDomains.map((String value) {
              return PopupMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.black)),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: getColorsky_Type2(),
          shape: getTextradius6(),
          elevation: 0,
          padding: EdgeInsets.all(getSize18().toDouble()),
        ),
        child: TextWidgetString(
          '회원가입 완료',
          getTextcenter(),
          getSize16(),
          getText700(),
          getColorwhite_type1(),
        ),
      ),
    );
  }

  /// 라벨 위젯
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidgetString(text, getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
        if (isRequired) ...[
          const SizedBox(width: 3),
          CustomPaint(
            size: const Size(4, 4),
            painter: RedCirclePainter(),
          ),
        ],
      ],
    );
  }

  /// 유효성 메시지
  Widget _buildValidationMessage(String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextWidgetString(message, getTextleft(), getSize12(), getText700(), color),
    );
  }

  /// 로딩 오버레이
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 빨간 원 페인터
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}