class User {
  final int id;
  final String username;
  final String? name;      // display name from wechat or registration
  final String email;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name: prefer name, fall back to username
  String get displayName => name ?? username;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] as int?) ?? 0,
      username: json['username']?.toString() ?? json['name']?.toString() ?? json['phone']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'phone': phone,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
