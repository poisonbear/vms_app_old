import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'layer/AppBarLayerView.dart';

class MemberInformationChange extends StatefulWidget {
  final DateTime nowTime;

  const MemberInformationChange({super.key, required this.nowTime});

  @override
  State<MemberInformationChange> createState() => _MemberInformationChangeState();
}

class _MemberInformationChangeState extends State<MemberInformationChange> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mmsiController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailDomainController = TextEditingController();
  final _emailDomainFocusNode = FocusNode();

  // Services
  final _userApiService = UserApiService();

  // State
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Validation States
  bool _isCurrentPasswordValid = true;
  bool _isNewPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _isMmsiValid = true;
  bool _isPhoneValid = true;
  bool _isEmailValid = true;

  // Email Domain Options
  final List<String> _emailDomains = ['naver.com', 'gmail.com', 'hanmail.net'];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupListeners();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// 사용자 초기화
  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final id = email.split('@')[0];
      _idController.text = id;
    }
  }

  /// 리스너 설정
  void _setupListeners() {
    _idController.addListener(_validateId);
    _currentPasswordController.addListener(_validateCurrentPassword);
    _newPasswordController.addListener(_validateNewPassword);
    _confirmPasswordController.addListener(_validateNewPassword);
    _mmsiController.addListener(_validateMmsi);
    _phoneController.addListener(_validatePhone);
    _emailController.addListener(_validateEmail);
    _emailDomainController.addListener(_validateEmail);
  }

  /// 컨트롤러 정리
  void _disposeControllers() {
    _idController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _mmsiController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emailDomainController.dispose();
    _emailDomainFocusNode.dispose();
  }

  /// 유효성 검사 메소드들
  void _validateId() {
    setState(() {
      final result = MembershipValidator.validateId(_idController.text);
      // ID는 읽기 전용이므로 유효성 검사만 수행
    });
  }

  void _validateCurrentPassword() {
    if (!_isSubmitting) return;
    setState(() {
      final text = _currentPasswordController.text;
      _isCurrentPasswordValid = text.isEmpty ||
          MembershipValidator.validatePassword(text).isValid;
    });
  }

  void _validateNewPassword() {
    if (!_isSubmitting) return;
    setState(() {
      final newPwd = _newPasswordController.text;
      final confirmPwd = _confirmPasswordController.text;

      _isNewPasswordValid = newPwd.isEmpty ||
          MembershipValidator.validatePassword(newPwd).isValid;
      _isConfirmPasswordValid = confirmPwd.isEmpty ||
          MembershipValidator.validatePassword(confirmPwd).isValid;
    });
  }

  void _validateMmsi() {
    setState(() {
      final result = MembershipValidator.validateMmsi(
        _mmsiController.text,
        isRequired: false,
      );
      _isMmsiValid = result.isValid;
    });
  }

  void _validatePhone() {
    setState(() {
      final result = MembershipValidator.validatePhone(
        _phoneController.text,
        isRequired: false,
      );
      _isPhoneValid = result.isValid;
    });
  }

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

  /// 기존 회원정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final response = await _userApiService.getMemberInfo(
        uuid: user.uid,
        token: token!,
      );

      if (response.success && response.data != null) {
        _populateUserInfo(response.data!);
      }
    } catch (e) {
      debugPrint('회원정보 불러오기 실패: $e');
    }
  }

  /// 사용자 정보 채우기
  void _populateUserInfo(Map<String, dynamic> data) {
    setState(() {
      _mmsiController.text = data['mmsi']?.toString() ?? '';
      _phoneController.text = data['mphn_no']?.toString() ?? '';

      final emailAddr = data['email_addr']?.toString();
      if (emailAddr != null && emailAddr.contains('@')) {
        final parts = emailAddr.split('@');
        _emailController.text = parts[0];
        _emailDomainController.text = parts[1];
      }
    });
  }

  /// 회원정보 수정 처리
  Future<void> _handleUpdate() async {
    setState(() => _isSubmitting = true);

    // 유효성 검사
    final validationResult = _validateForm();
    if (validationResult != null) {
      SnackBarUtils.showTopSnackBar(context, validationResult);
      setState(() => _isSubmitting = false);
      return;
    }

    // 로딩 다이얼로그 표시
    _showLoadingDialog();

    try {
      await _updateMemberInfo();

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        SnackBarUtils.showTopSnackBar(context, '회원정보가 성공적으로 수정되었습니다.');

        // 키보드 닫기
        await SystemChannels.textInput.invokeMethod('TextInput.hide');
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 100));

        Navigator.pop(context); // 이전 화면으로
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _handleUpdateError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 폼 유효성 검사
  String? _validateForm() {
    final currentPwd = _currentPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;
    final mmsi = _mmsiController.text;
    final phone = _phoneController.text;
    final email = _emailController.text;
    final emailDomain = _emailDomainController.text;

    // 비밀번호 변경 검증
    if (newPwd.isNotEmpty) {
      if (currentPwd.isEmpty) {
        return '기존 비밀번호를 입력해주세요.';
      }
      if (confirmPwd.isEmpty) {
        return '새로운 비밀번호 확인란을 입력해주세요.';
      }
      if (!_isCurrentPasswordValid) {
        return '기존 비밀번호 형식이 올바르지 않습니다.';
      }
      if (!_isNewPasswordValid) {
        return '새로운 비밀번호 형식이 올바르지 않습니다.';
      }
      if (currentPwd == newPwd) {
        return '새로운 비밀번호가 기존 비밀번호와 동일합니다.';
      }
      if (newPwd != confirmPwd) {
        return '새로운 비밀번호가 일치하지 않습니다.';
      }
    } else if (currentPwd.isNotEmpty) {
      return '변경하실 새로운 비밀번호를 입력해주세요.';
    }

    // MMSI 검증
    if (mmsi.isNotEmpty && !_isMmsiValid) {
      return ValidationMessages.mmsiFormat;
    }

    // 휴대폰 검증
    if (phone.isNotEmpty && !_isPhoneValid) {
      return ValidationMessages.phoneFormat;
    }

    // 이메일 검증
    if ((email.isNotEmpty || emailDomain.isNotEmpty) && !_isEmailValid) {
      return '이메일을 완전히 입력해주세요.';
    }

    // 수정할 내용이 있는지 확인
    final hasDataToUpdate = newPwd.isNotEmpty ||
        mmsi.isNotEmpty ||
        phone.isNotEmpty ||
        (email.isNotEmpty && emailDomain.isNotEmpty);

    if (!hasDataToUpdate) {
      return '수정할 정보를 하나 이상 올바르게 입력해주세요.';
    }

    return null;
  }

  /// 회원정보 업데이트
  Future<void> _updateMemberInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('로그인이 만료되었습니다.');

    final firebaseToken = await user.getIdToken();
    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    // 업데이트 데이터 구성
    final updateData = _buildUpdateData(user.uid, fcmToken);

    // 서버 업데이트
    final response = await _userApiService.updateMemberInfo(
      userData: updateData,
      token: firebaseToken!,
    );

    if (!response.success) {
      throw Exception(response.error ?? '서버 처리 중 오류가 발생했습니다.');
    }

    // 비밀번호 변경이 있으면 Firebase 업데이트
    if (_newPasswordController.text.isNotEmpty) {
      await _updateFirebasePassword(user);
    }
  }

  /// 업데이트 데이터 구성
  Map<String, dynamic> _buildUpdateData(String uid, String fcmToken) {
    final data = <String, dynamic>{
      'user_id': _idController.text,
      'mmsi': _mmsiController.text,
      'mphn_no': _phoneController.text,
      'choice_time': widget.nowTime.toIso8601String(),
      'uuid': uid,
      'fcm_tkn': fcmToken,
    };

    if (_newPasswordController.text.isNotEmpty) {
      data['user_pwd'] = _currentPasswordController.text;
      data['user_npwd'] = _newPasswordController.text;
    }

    if (_emailController.text.isNotEmpty && _emailDomainController.text.isNotEmpty) {
      data['email_addr'] = '${_emailController.text}@${_emailDomainController.text}';
    }

    return data;
  }

  /// Firebase 비밀번호 업데이트
  Future<void> _updateFirebasePassword(User user) async {
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(_newPasswordController.text);
    await user.reload();
  }

  /// 에러 처리
  void _handleUpdateError(dynamic error) {
    String message = '회원정보 수정 중 오류가 발생했습니다.';

    if (error.toString().contains('401')) {
      message = '기존 비밀번호가 일치하지 않습니다.';
    } else if (error.toString().contains('network')) {
      message = '네트워크 연결을 확인해주세요.';
    }

    SnackBarUtils.showTopSnackBar(context, message);
  }

  /// 로딩 다이얼로그
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const AppBarLayerView('회원정보수정'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  /// 메인 바디
  Widget _buildBody() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: getSize20().toDouble(),
          right: getSize20().toDouble(),
          top: getSize20().toDouble(),
          bottom: MediaQuery.of(context).viewInsets.bottom + getSize20().toDouble(),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildIdField(),
              _buildPasswordFields(),
              _buildMmsiField(),
              _buildPhoneField(),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 아이디 필드 (읽기 전용)
  Widget _buildIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('아이디'),
        const SizedBox(height: 8),
        inputWidget_deactivate(
          266, 48, _idController, '', getColorgray_Type7(),
          isReadOnly: true,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 비밀번호 필드들
  Widget _buildPasswordFields() {
    return Column(
      children: [
        // 기존 비밀번호
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('기존 비밀번호'),
            const SizedBox(height: 8),
            inputWidget(
              266, 48, _currentPasswordController, '비밀번호',
              getColorgray_Type7(), obscureText: true,
            ),
            if (!_isCurrentPasswordValid && _isSubmitting)
              _buildValidationMessage(ValidationMessages.passwordFormat),
            const SizedBox(height: 13),
          ],
        ),

        // 새로운 비밀번호
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('새로운 비밀번호'),
            const SizedBox(height: 8),
            inputWidget(
              266, 48, _newPasswordController, '비밀번호',
              getColorgray_Type7(), obscureText: true,
            ),
            const SizedBox(height: 20),
          ],
        ),

        // 새로운 비밀번호 확인
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('새로운 비밀번호 확인'),
            const SizedBox(height: 8),
            inputWidget(
              266, 48, _confirmPasswordController, '비밀번호 확인',
              getColorgray_Type7(), obscureText: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  /// MMSI 필드
  Widget _buildMmsiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('선박 MMSI 번호'),
        const SizedBox(height: 8),
        inputWidget(
          266, 48, _mmsiController,
          'MMSI 번호(숫자 9자리)를 입력해주세요',
          getColorgray_Type7(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 휴대폰 필드
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('휴대폰 번호'),
        const SizedBox(height: 8),
        inputWidget(
          266, 48, _phoneController,
          "'-' 구분없이 숫자만 입력",
          getColorgray_Type7(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 이메일 필드
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('이메일'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: inputWidget(
                133, 48, _emailController,
                '이메일 아이디 입력',
                getColorgray_Type7(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextWidgetString(
                '@', getTextcenter(), getSize16(),
                getText700(), getColorgray_Type8(),
              ),
            ),
            Expanded(
              child: _buildEmailDomainSelector(),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
          focusNode: _emailDomainFocusNode,
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
          icon: SvgPicture.asset(
            'assets/kdn/usm/img/down_select_img.svg',
            width: 24,
            height: 24,
          ),
          color: Colors.white,
          onSelected: (String value) {
            setState(() {
              _emailDomainController.text = value;
              _emailDomainFocusNode.unfocus();
            });
          },
          itemBuilder: (BuildContext context) {
            return _emailDomains.map((String value) {
              return PopupMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black),
                ),
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
        onPressed: _isLoading ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: getColorsky_Type2(),
          shape: getTextradius6(),
          elevation: 0,
          padding: EdgeInsets.all(getSize18().toDouble()),
        ),
        child: TextWidgetString(
          '회원정보수정 완료하기',
          getTextcenter(),
          getSize16(),
          getText700(),
          getColorwhite_type1(),
        ),
      ),
    );
  }

  /// 라벨 위젯
  Widget _buildLabel(String text) {
    return TextWidgetString(
      text,
      getTextcenter(),
      getSize16(),
      getText700(),
      getColorgray_Type8(),
    );
  }

  /// 유효성 메시지
  Widget _buildValidationMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextWidgetString(
        message,
        getTextleft(),
        getSize12(),
        getText700(),
        getColorred_type3(),
      ),
    );
  }
}