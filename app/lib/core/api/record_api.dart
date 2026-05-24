import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'api_client.dart';

final recordApiProvider = Provider<RecordApi>((ref) {
  return RecordApi(ref.read(apiClientProvider));
});

class RecordApi {
  final ApiClient _client;

  RecordApi(this._client);

  // --- Sleep ---
  Future<Map<String, dynamic>> createSleepRecord({
    required String memberProfileId,
    required String recordDate,
    required String sleepTime,
    required String wakeTime,
    double? napHours,
    required int quality,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/sleep', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'sleep_time': sleepTime,
      'wake_time': wakeTime,
      'nap_hours': napHours,
      'quality': quality,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Smoking ---
  Future<Map<String, dynamic>> createSmokingRecord({
    required String memberProfileId,
    required String recordDate,
    required int count,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/smoking', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'count': count,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Drinking ---
  Future<Map<String, dynamic>> createDrinkingRecord({
    required String memberProfileId,
    required String recordDate,
    required String liquorType,
    required double amount,
    required String unit,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/drinking', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'liquor_type': liquorType,
      'amount': amount,
      'unit': unit,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Work Posture ---
  Future<Map<String, dynamic>> createWorkPostureRecord({
    required String memberProfileId,
    required String recordDate,
    required double totalHours,
    required double sittingPct,
    required double standingPct,
    required double walkingPct,
    required double heavyPct,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/work-posture', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'total_hours': totalHours,
      'sitting_pct': sittingPct,
      'standing_pct': standingPct,
      'walking_pct': walkingPct,
      'heavy_pct': heavyPct,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Diet ---
  Future<Map<String, dynamic>> createDietRecord({
    required String memberProfileId,
    required String recordDate,
    required int waterMl,
    required int breakfastOk,
    required int lunchOk,
    required int dinnerOk,
    required int binge,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/diet', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'water_ml': waterMl,
      'breakfast_ok': breakfastOk,
      'lunch_ok': lunchOk,
      'dinner_ok': dinnerOk,
      'binge': binge,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Sugar ---
  Future<Map<String, dynamic>> createSugarRecord({
    required String memberProfileId,
    required String recordDate,
    required int soda,
    required int juice,
    required int milkTea,
    required int cake,
    required int candy,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/sugar', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'soda': soda,
      'juice': juice,
      'milk_tea': milkTea,
      'cake': cake,
      'candy': candy,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Food Detail ---
  Future<Map<String, dynamic>> createFoodDetailRecord({
    required String memberProfileId,
    required String recordDate,
    required int leanMeat,
    required int fattyMeat,
    required int freshwaterFish,
    required int seafood,
    required int highCholesterol,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/food-detail', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'lean_meat': leanMeat,
      'fatty_meat': fattyMeat,
      'freshwater_fish': freshwaterFish,
      'seafood': seafood,
      'high_cholesterol': highCholesterol,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Environment Hazard ---
  Future<Map<String, dynamic>> createEnvironmentHazardRecord({
    required String memberProfileId,
    required String recordDate,
    required int dust,
    required int noise,
    required int chemicalFumes,
    required int highTemp,
    required int damp,
    required int radiation,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/environment', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'dust': dust,
      'noise': noise,
      'chemical_fumes': chemicalFumes,
      'high_temp': highTemp,
      'damp': damp,
      'radiation': radiation,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Health (vitals) ---
  Future<Map<String, dynamic>> createHealthRecord({
    required String memberProfileId,
    required String recordDate,
    required String recordType,
    required Map<String, dynamic> valueJson,
    String note = '',
    String source = 'manual',
  }) async {
    final response = await _client.post('/records/health', data: {
      'member_profile_id': memberProfileId,
      'record_date': recordDate,
      'record_type': recordType,
      'value_json': valueJson,
      'note': note,
      'source': source,
    });
    return response.data as Map<String, dynamic>;
  }

  // --- Query ---
  Future<List<dynamic>> queryRecords({
    String? memberProfileId,
    String? dateFrom,
    String? dateTo,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{};
    if (memberProfileId != null) params['member_profile_id'] = memberProfileId;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (type != null) params['type'] = type;
    params['limit'] = limit;
    params['offset'] = offset;

    final response = await _client.get('/records', queryParameters: params);
    return response.data as List<dynamic>;
  }

  // --- Delete ---
  Future<void> deleteRecord(String id, String table) async {
    await _client.delete('/records/$id', queryParameters: {'table': table});
  }
}
