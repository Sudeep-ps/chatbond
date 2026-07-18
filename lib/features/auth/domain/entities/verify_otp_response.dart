import 'auth_user.dart';

class VerifyOtpResponse {
  final AuthUser? user;
  final String? resetToken;

  VerifyOtpResponse({
    this.user,
    this.resetToken,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      resetToken: json['resetToken'],
    );
  }
}
