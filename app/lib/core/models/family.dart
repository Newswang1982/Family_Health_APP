class Family {
  final int id;
  final String name;
  final String? description;
  final String? inviteCode;
  final int memberCount;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  Family({
    required this.id,
    required this.name,
    this.description,
    this.inviteCode,
    this.memberCount = 1,
    this.role = 'owner',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String?,
      memberCount: json['member_count'] as int? ?? 1,
      role: json['role'] as String? ?? 'owner',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'member_count': memberCount,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Family copyWith({
    int? id,
    String? name,
    String? description,
    String? inviteCode,
    int? memberCount,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Family(id: $id, name: $name, members: $memberCount)';
}

class FamilyMember {
  final int id;
  final int familyId;
  final int userId;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.username,
    this.email,
    this.avatarUrl,
    this.role = 'member',
    required this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as int,
      familyId: json['family_id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'FamilyMember(id: $id, username: $username, role: $role)';
}

class FamilyDetail {
  final Family family;
  final List<FamilyMember> members;

  FamilyDetail({required this.family, required this.members});

  factory FamilyDetail.fromJson(Map<String, dynamic> json) {
    return FamilyDetail(
      family: Family.fromJson(json['family'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>)
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family.toJson(),
      'members': members.map((e) => e.toJson()).toList(),
    };
  }
}
