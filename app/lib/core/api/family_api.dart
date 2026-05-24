import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'api_client.dart';

final familyApiProvider = Provider<FamilyApi>((ref) {
  return FamilyApi(ref.read(apiClientProvider));
});

class FamilyApi {
  final ApiClient _client;

  FamilyApi(this._client);

  Future<Map<String, dynamic>> createFamily(String name) async {
    final response = await _client.post('/families', data: {'name': name});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listFamilies() async {
    final response = await _client.get('/families');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getFamily(String id) async {
    final response = await _client.get('/families/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinFamily(String inviteCode) async {
    final response = await _client.post('/families/join', data: {'invite_code': inviteCode});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> regenerateInviteCode(String familyId) async {
    final response = await _client.post('/families/$familyId/invite');
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeMember(String familyId, String userId) async {
    await _client.delete('/families/$familyId/members/$userId');
  }
}
