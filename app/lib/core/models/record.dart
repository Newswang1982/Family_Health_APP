/// Base class for all health record types.
/// Each record has an id, profileId, recorded date, notes, and timestamps.
abstract class HealthRecord {
  final int? id;
  final int profileId;
  final DateTime recordedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthRecord({
    this.id,
    required this.profileId,
    required this.recordedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();
}

/// Blood Pressure record
class BloodPressureRecord extends HealthRecord {
  final int systolic;
  final int diastolic;
  final int? heartRate;

  BloodPressureRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
  });

  factory BloodPressureRecord.fromJson(Map<String, dynamic> json) {
    return BloodPressureRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      systolic: json['systolic'] as int,
      diastolic: json['diastolic'] as int,
      heartRate: json['heart_rate'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'blood_pressure',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
    };
  }

  String get classification {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1 Hypertension';
    if (systolic >= 140 || diastolic >= 90) return 'Stage 2 Hypertension';
    return 'Hypertensive Crisis';
  }
}

/// Blood Sugar record
class BloodSugarRecord extends HealthRecord {
  final double value;
  final String unit; // 'mg/dL' or 'mmol/L'
  final String mealTiming; // 'fasting', 'before_meal', 'after_meal', 'bedtime'

  BloodSugarRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.value,
    this.unit = 'mg/dL',
    this.mealTiming = 'fasting',
  });

  factory BloodSugarRecord.fromJson(Map<String, dynamic> json) {
    return BloodSugarRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'mg/dL',
      mealTiming: json['meal_timing'] as String? ?? 'fasting',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'blood_sugar',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'value': value,
      'unit': unit,
      'meal_timing': mealTiming,
    };
  }
}

/// Heart Rate record
class HeartRateRecord extends HealthRecord {
  final int bpm;
  final String activity; // 'resting', 'walking', 'exercise', 'sleeping'

  HeartRateRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.bpm,
    this.activity = 'resting',
  });

  factory HeartRateRecord.fromJson(Map<String, dynamic> json) {
    return HeartRateRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bpm: json['bpm'] as int,
      activity: json['activity'] as String? ?? 'resting',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'heart_rate',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bpm': bpm,
      'activity': activity,
    };
  }
}

/// Sleep record
class SleepRecord extends HealthRecord {
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int? deepSleepMinutes;
  final int? lightSleepMinutes;
  final int? remSleepMinutes;
  final int? awakeMinutes;
  final int? interruptions;
  final String quality; // 'excellent', 'good', 'fair', 'poor'
  final int? sleepLatencyMinutes;

  SleepRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.sleepTime,
    required this.wakeTime,
    this.deepSleepMinutes,
    this.lightSleepMinutes,
    this.remSleepMinutes,
    this.awakeMinutes,
    this.interruptions,
    this.quality = 'good',
    this.sleepLatencyMinutes,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sleepTime: DateTime.parse(json['sleep_time'] as String),
      wakeTime: DateTime.parse(json['wake_time'] as String),
      deepSleepMinutes: json['deep_sleep_minutes'] as int?,
      lightSleepMinutes: json['light_sleep_minutes'] as int?,
      remSleepMinutes: json['rem_sleep_minutes'] as int?,
      awakeMinutes: json['awake_minutes'] as int?,
      interruptions: json['interruptions'] as int?,
      quality: json['quality'] as String? ?? 'good',
      sleepLatencyMinutes: json['sleep_latency_minutes'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'sleep',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sleep_time': sleepTime.toIso8601String(),
      'wake_time': wakeTime.toIso8601String(),
      'deep_sleep_minutes': deepSleepMinutes,
      'light_sleep_minutes': lightSleepMinutes,
      'rem_sleep_minutes': remSleepMinutes,
      'awake_minutes': awakeMinutes,
      'interruptions': interruptions,
      'quality': quality,
      'sleep_latency_minutes': sleepLatencyMinutes,
    };
  }

  int get totalSleepMinutes =>
      wakeTime.difference(sleepTime).inMinutes;

  double get sleepEfficiency {
    final total = totalSleepMinutes;
    if (total <= 0) return 0;
    final actualSleep = total - (awakeMinutes ?? 0);
    return (actualSleep / total) * 100;
  }
}

/// Smoking record
class SmokingRecord extends HealthRecord {
  final int cigarettesCount;
  final int? nicotineMg;
  final String? brand;
  final bool? isQuitAttempt;

  SmokingRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.cigarettesCount,
    this.nicotineMg,
    this.brand,
    this.isQuitAttempt,
  });

  factory SmokingRecord.fromJson(Map<String, dynamic> json) {
    return SmokingRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cigarettesCount: json['cigarettes_count'] as int,
      nicotineMg: json['nicotine_mg'] as int?,
      brand: json['brand'] as String?,
      isQuitAttempt: json['is_quit_attempt'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'smoking',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cigarettes_count': cigarettesCount,
      'nicotine_mg': nicotineMg,
      'brand': brand,
      'is_quit_attempt': isQuitAttempt,
    };
  }
}

/// Weight record
class WeightRecord extends HealthRecord {
  final double weightKg;
  final double? bodyFatPercentage;
  final double? bmi;
  final double? waistCm;
  final double? hipCm;

  WeightRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.weightKg,
    this.bodyFatPercentage,
    this.bmi,
    this.waistCm,
    this.hipCm,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      weightKg: (json['weight_kg'] as num).toDouble(),
      bodyFatPercentage:
          (json['body_fat_percentage'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      hipCm: (json['hip_cm'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'weight',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'weight_kg': weightKg,
      'body_fat_percentage': bodyFatPercentage,
      'bmi': bmi,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
    };
  }
}

/// Exercise record
class ExerciseRecord extends HealthRecord {
  final String exerciseType; // 'running', 'walking', 'cycling', 'swimming', etc.
  final int durationMinutes;
  final double? distanceKm;
  final int? caloriesBurned;
  final String? intensity; // 'low', 'moderate', 'high'

  ExerciseRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.exerciseType,
    required this.durationMinutes,
    this.distanceKm,
    this.caloriesBurned,
    this.intensity,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      exerciseType: json['exercise_type'] as String,
      durationMinutes: json['duration_minutes'] as int,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      caloriesBurned: json['calories_burned'] as int?,
      intensity: json['intensity'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'exercise',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'exercise_type': exerciseType,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
      'intensity': intensity,
    };
  }
}

/// Oxygen Saturation (SpO2) record
class OxygenRecord extends HealthRecord {
  final int spo2Percent;
  final int? heartRate;

  OxygenRecord({
    super.id,
    required super.profileId,
    required super.recordedAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required this.spo2Percent,
    this.heartRate,
  });

  factory OxygenRecord.fromJson(Map<String, dynamic> json) {
    return OxygenRecord(
      id: json['id'] as int?,
      profileId: json['profile_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      spo2Percent: json['spo2_percent'] as int,
      heartRate: json['heart_rate'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': 'oxygen',
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'spo2_percent': spo2Percent,
      'heart_rate': heartRate,
    };
  }
}

/// Helper to decode a record from a JSON map based on record_type field.
HealthRecord recordFromJson(Map<String, dynamic> json) {
  final type = json['record_type'] as String;
  switch (type) {
    case 'blood_pressure':
      return BloodPressureRecord.fromJson(json);
    case 'blood_sugar':
      return BloodSugarRecord.fromJson(json);
    case 'heart_rate':
      return HeartRateRecord.fromJson(json);
    case 'sleep':
      return SleepRecord.fromJson(json);
    case 'smoking':
      return SmokingRecord.fromJson(json);
    case 'weight':
      return WeightRecord.fromJson(json);
    case 'exercise':
      return ExerciseRecord.fromJson(json);
    case 'oxygen':
      return OxygenRecord.fromJson(json);
    default:
      throw ArgumentError('Unknown record type: $type');
  }
}
