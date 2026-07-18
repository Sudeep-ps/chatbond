class AuthUser {
  final String uid;
  final String? email;
  final String? name;
  final String? pfpUrl;
  final bool isVerified;

  AuthUser({
    required this.uid,
    this.email,
    this.name,
    this.pfpUrl,
    this.isVerified = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['id'] ?? '',
      email: json['email'],
      name: json['name'],
      pfpUrl: json['pfpUrl'],
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
    );
  }
}
