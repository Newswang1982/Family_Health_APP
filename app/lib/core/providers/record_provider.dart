import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/record.dart';

// ── Record State ──

/// Represents the health records management state.
class RecordState {
  final List<HealthRecord> records;
  final bool isLoading;
  final String? error;

  const RecordState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  RecordState copyWith({
    List<HealthRecord>? records,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordState &&
          records == other.records &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => Object.hash(records, isLoading, error);
}

// ── Record Notifier ──

/// Manages CRUD operations for all 8 types of daily health records.
class RecordNotifier extends StateNotifier<RecordState> {
  RecordNotifier() : super(const RecordState());

  /// Query records for a given profile, optionally filtered by type and date range.
  Future<void> queryRecords({
    required int profileId,
    String? recordType,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // final queryParams = {
      //   'profile_id': profileId,
      //   if (recordType != null) 'record_type': recordType,
      //   if (from != null) 'from': from.toIso8601String(),
      //   if (to != null) 'to': to.toIso8601String(),
      //   if (limit != null) 'limit': limit,
      //   if (offset != null) 'offset': offset,
      // };
      // final response = await dio.get('/records', queryParameters: queryParams);
      // final records = (response.data['records'] as List)
      //     .map((e) => recordFromJson(e as Map<String, dynamic>))
      //     .toList();

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(records: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to query records: $e',
      );
    }
  }

  /// Create a new health record.
  /// [record] should be one of the concrete Record types.
  Future<void> createRecord(HealthRecord record) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // final response = await dio.post('/records', data: record.toJson());
      // final created = recordFromJson(response.data);

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        records: [record, ...state.records],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create record: $e',
      );
    }
  }

  /// Update an existing record.
  Future<void> updateRecord(HealthRecord record) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await dio.put('/records/${record.id}', data: record.toJson());

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        records: state.records.map((r) {
          return r.id == record.id ? record : r;
        }).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update record: $e',
      );
    }
  }

  /// Delete a record by id.
  Future<void> deleteRecord(int recordId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await dio.delete('/records/$recordId');

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        records: state.records.where((r) => r.id != recordId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete record: $e',
      );
    }
  }

  /// Convenience: create a sleep record.
  Future<void> createSleepRecord({
    required int profileId,
    required DateTime sleepTime,
    required DateTime wakeTime,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    int? awakeMinutes,
    int? interruptions,
    String quality = 'good',
    int? sleepLatencyMinutes,
    String? notes,
  }) async {
    final record = SleepRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      sleepTime: sleepTime,
      wakeTime: wakeTime,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      awakeMinutes: awakeMinutes,
      interruptions: interruptions,
      quality: quality,
      sleepLatencyMinutes: sleepLatencyMinutes,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create a smoking record.
  Future<void> createSmokingRecord({
    required int profileId,
    required int cigarettesCount,
    int? nicotineMg,
    String? brand,
    bool? isQuitAttempt,
    String? notes,
  }) async {
    final record = SmokingRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      cigarettesCount: cigarettesCount,
      nicotineMg: nicotineMg,
      brand: brand,
      isQuitAttempt: isQuitAttempt,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create a blood pressure record.
  Future<void> createBloodPressureRecord({
    required int profileId,
    required int systolic,
    required int diastolic,
    int? heartRate,
    String? notes,
  }) async {
    final record = BloodPressureRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create a blood sugar record.
  Future<void> createBloodSugarRecord({
    required int profileId,
    required double value,
    String unit = 'mg/dL',
    String mealTiming = 'fasting',
    String? notes,
  }) async {
    final record = BloodSugarRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      value: value,
      unit: unit,
      mealTiming: mealTiming,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create a heart rate record.
  Future<void> createHeartRateRecord({
    required int profileId,
    required int bpm,
    String activity = 'resting',
    String? notes,
  }) async {
    final record = HeartRateRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      bpm: bpm,
      activity: activity,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create a weight record.
  Future<void> createWeightRecord({
    required int profileId,
    required double weightKg,
    double? bodyFatPercentage,
    double? bmi,
    double? waistCm,
    double? hipCm,
    String? notes,
  }) async {
    final record = WeightRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      weightKg: weightKg,
      bodyFatPercentage: bodyFatPercentage,
      bmi: bmi,
      waistCm: waistCm,
      hipCm: hipCm,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create an exercise record.
  Future<void> createExerciseRecord({
    required int profileId,
    required String exerciseType,
    required int durationMinutes,
    double? distanceKm,
    int? caloriesBurned,
    String? intensity,
    String? notes,
  }) async {
    final record = ExerciseRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      exerciseType: exerciseType,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      caloriesBurned: caloriesBurned,
      intensity: intensity,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Convenience: create an oxygen saturation record.
  Future<void> createOxygenRecord({
    required int profileId,
    required int spo2Percent,
    int? heartRate,
    String? notes,
  }) async {
    final record = OxygenRecord(
      profileId: profileId,
      recordedAt: DateTime.now(),
      spo2Percent: spo2Percent,
      heartRate: heartRate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createRecord(record);
  }

  /// Filter the current records by type.
  List<T> recordsOfType<T extends HealthRecord>() {
    return state.records.whereType<T>().toList();
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──

final recordProvider =
    StateNotifierProvider<RecordNotifier, RecordState>((ref) {
  return RecordNotifier();
});
