import '../../cmm/constants.dart';

/// 회원가입 유효성 검사 헬퍼
class MembershipValidator {
  /// 아이디 유효성 검사
  static ValidationResult validateId(String id) {
    if (id.isEmpty) {
      return ValidationResult(false, '아이디를 입력해주세요.');
    }

    if (!AppConstants.idPattern.hasMatch(id)) {
      return ValidationResult(false, ValidationMessages.idFormat);
    }

    return ValidationResult(true);
  }

  /// 비밀번호 유효성 검사
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, '비밀번호를 입력해주세요.');
    }

    if (password.length < 6 || password.length > 12) {
      return ValidationResult(false, ValidationMessages.passwordFormat);
    }

    bool hasLetter = AppConstants.letterPattern.hasMatch(password);
    bool hasNumber = AppConstants.numberPattern.hasMatch(password);
    bool hasSpecial = AppConstants.specialPattern.hasMatch(password);

    if (!hasLetter || !hasNumber || !hasSpecial) {
      return ValidationResult(false, ValidationMessages.passwordFormat);
    }

    return ValidationResult(true);
  }

  /// 비밀번호 확인 검사
  static ValidationResult validatePasswordConfirm(
      String password,
      String confirmPassword,
      ) {
    if (confirmPassword.isEmpty) {
      return ValidationResult(false, '비밀번호 확인을 입력해주세요.');
    }

    if (password != confirmPassword) {
      return ValidationResult(false, ValidationMessages.passwordMismatch);
    }

    return ValidationResult(true);
  }

  /// MMSI 유효성 검사
  static ValidationResult validateMmsi(String mmsi, {bool isRequired = true}) {
    if (mmsi.isEmpty) {
      if (isRequired) {
        return ValidationResult(false, 'MMSI 번호를 입력해주세요.');
      }
      return ValidationResult(true);
    }

    if (!AppConstants.mmsiPattern.hasMatch(mmsi)) {
      return ValidationResult(false, ValidationMessages.mmsiFormat);
    }

    return ValidationResult(true);
  }

  /// 휴대폰 번호 유효성 검사
  static ValidationResult validatePhone(String phone, {bool isRequired = false}) {
    if (phone.isEmpty) {
      if (isRequired) {
        return ValidationResult(false, '휴대폰 번호를 입력해주세요.');
      }
      return ValidationResult(true);
    }

    if (!AppConstants.phonePattern.hasMatch(phone)) {
      return ValidationResult(false, ValidationMessages.phoneFormat);
    }

    return ValidationResult(true);
  }

  /// 이메일 유효성 검사
  static ValidationResult validateEmail(
      String email,
      String domain, {
        bool isRequired = false,
      }) {
    if (email.isEmpty && domain.isEmpty) {
      if (isRequired) {
        return ValidationResult(false, '이메일을 입력해주세요.');
      }
      return ValidationResult(true);
    }

    if (email.isEmpty || domain.isEmpty) {
      return ValidationResult(false, '이메일을 완전히 입력해주세요.');
    }

    if (domain == '직접입력') {
      return ValidationResult(false, '이메일 주소가 올바르지 않습니다.');
    }

    return ValidationResult(true);
  }

  /// 전체 폼 유효성 검사
  static FormValidationResult validateForm({
    required String id,
    required String password,
    required String confirmPassword,
    required String mmsi,
    required String phone,
    required String email,
    required String emailDomain,
    required int? idAvailability,
  }) {
    final errors = <String>[];

    // 아이디 중복 확인
    if (idAvailability == null) {
      errors.add(ValidationMessages.idDuplicateCheck);
      return FormValidationResult(false, errors);
    }

    if (idAvailability == 1) {
      errors.add(ValidationMessages.idAlreadyUsed);
      return FormValidationResult(false, errors);
    }

    // 필수 필드 확인
    if (id.isEmpty || password.isEmpty || confirmPassword.isEmpty || mmsi.isEmpty) {
      errors.add(ValidationMessages.requiredFieldsEmpty);
      return FormValidationResult(false, errors);
    }

    // 각 필드 유효성 검사
    final idResult = validateId(id);
    if (!idResult.isValid) errors.add(idResult.message!);

    final passwordResult = validatePassword(password);
    if (!passwordResult.isValid) errors.add(passwordResult.message!);

    final confirmResult = validatePasswordConfirm(password, confirmPassword);
    if (!confirmResult.isValid) errors.add(confirmResult.message!);

    final mmsiResult = validateMmsi(mmsi);
    if (!mmsiResult.isValid) errors.add(mmsiResult.message!);

    final phoneResult = validatePhone(phone);
    if (!phoneResult.isValid) errors.add(phoneResult.message!);

    final emailResult = validateEmail(email, emailDomain);
    if (!emailResult.isValid) errors.add(emailResult.message!);

    return FormValidationResult(errors.isEmpty, errors);
  }
}

/// 유효성 검사 결과
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult(this.isValid, [this.message]);
}

/// 폼 유효성 검사 결과
class FormValidationResult {
  final bool isValid;
  final List<String> errors;

  FormValidationResult(this.isValid, this.errors);

  String get firstError => errors.isNotEmpty ? errors.first : '';
}