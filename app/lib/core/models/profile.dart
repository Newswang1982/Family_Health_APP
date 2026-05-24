class MemberProfile {
  final int id;
  final int familyId;
  final String displayName;
  final String? avatarUrl;
  final String? relation;
  final DateTime? birthDate;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final List<String>? chronicConditions;
  final List<String>? allergies;
  final String? bloodType;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberProfile({
    required this.id,
    required this.familyId,
    required this.displayName,
    this.avatarUrl,
    this.relation,
    this.birthDate,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.chronicConditions,
    this.allergies,
    this.bloodType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      id: json['id'] as int,
      familyId: json['family_id'] as int,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      relation: json['relation'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      chronicConditions: json['chronic_conditions'] != null
          ? (json['chronic_conditions'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      allergies: json['allergies'] != null
          ? (json['allergies'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      bloodType: json['blood_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'relation': relation,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'chronic_conditions': chronicConditions,
      'allergies': allergies,
      'blood_type': bloodType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MemberProfile copyWith({
    int? id,
    int? familyId,
    String? displayName,
    String? avatarUrl,
    String? relation,
    DateTime? birthDate,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? bloodType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberProfile(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      relation: relation ?? this.relation,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      allergies: allergies ?? this.allergies,
      bloodType: bloodType ?? this.bloodType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  String toString() =>
      'MemberProfile(id: $id, name: $displayName, relation: $relation)';
}

class ReferenceRange {
  final String metric;
  final double? minValue;
  final double? maxValue;
  final String unit;
  final String? label;

  ReferenceRange({
    required this.metric,
    this.minValue,
    this.maxValue,
    required this.unit,
    this.label,
  });

  factory ReferenceRange.fromJson(Map<String, dynamic> json) {
    return ReferenceRange(
      metric: json['metric'] as String,
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      unit: json['unit'] as String,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'min_value': minValue,
      'max_value': maxValue,
      'unit': unit,
      'label': label,
    };
  }

  bool isWithinRange(double value) {
    if (minValue != null && value < minValue!) return false;
    if (maxValue != null && value > maxValue!) return false;
    return true;
  }

  @override
  String toString() =>
      'ReferenceRange($metric: $minValue-$maxValue $unit)';
}
