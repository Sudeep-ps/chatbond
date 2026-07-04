class UserProfileEntity {
  final String uid;
  final String name;
  final String? pfpURL;

  UserProfileEntity({
    required this.uid,
    required this.name,
    this.pfpURL,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      uid: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? '',
      pfpURL: json['pfpUrl'] ?? json['pfpURL'],
    );
  }

  factory UserProfileEntity.fromFirestore(Map<String, dynamic> data) {
    return UserProfileEntity(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      pfpURL: data['pfpURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'pfpURL': pfpURL,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'pfpURL': pfpURL,
    };
  }
}
