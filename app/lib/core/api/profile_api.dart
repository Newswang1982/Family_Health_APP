import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'api_client.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.read(apiClientProvider));
});

class ProfileApi {
  final ApiClient _client;

  ProfileApi(this._client);

  Future<Map<String, dynamic>> createProfile(
    String familyId, {
    required String name,
    String gender = '',
    String? birthDate,
    double? heightCm,
    double? weightKg,
  }) async {
    final response = await _client.post('/families/$familyId/profiles', data: {
      'name': name,
      'gender': gender,
      'birth_date': birthDate,
      'height_cm': heightCm,
      'weight_kg': weightKg,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listProfiles(String familyId) async {
    final response = await _client.get('/families/$familyId/profiles');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProfile(String familyId, String profileId) async {
    final response = await _client.get('/families/$familyId/profiles/$profileId');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateProfile(
    String familyId,
    String profileId, {
    String? name,
    String? gender,
    String? birthDate,
    double? heightCm,
    double? weightKg,
  }) async {
    await _client.put('/families/$familyId/profiles/$profileId', data: {
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
    });
  }

  Future<void> deleteProfile(String familyId, String profileId) async {
    await _client.delete('/families/$familyId/profiles/$profileId');
  }

  Future<void> setReferenceRange(
    String profileId, {
    required String indicatorType,
    double? minValue,
    double? maxValue,
    String unit = '',
  }) async {
    await _client.put('/families//profiles/$profileId/reference', data: {
      'indicator_type': indicatorType,
      'min_value': minValue,
      'max_value': maxValue,
      'unit': unit,
    });
  }
}
