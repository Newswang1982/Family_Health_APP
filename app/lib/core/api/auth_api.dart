import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_providers.dart';
import '../models/user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> register({
    required String password,
    String phone = '',
    String name = '',
    String email = '',
  }) async {
    final data = <String, dynamic>{
      'password': password,
    };
    if (phone.isNotEmpty) data['phone'] = phone;
    if (name.isNotEmpty) data['name'] = name;
    if (email.isNotEmpty) data['email'] = email;
    final response = await _client.dio.post('/auth/register', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    String phone = '',
    String email = '',
    required String password,
  }) async {
    final data = <String, dynamic>{
      'password': password,
    };
    if (phone.isNotEmpty) {
      data['phone'] = phone;
    } else if (email.isNotEmpty) {
      data['email'] = email;
    }
    final response = await _client.dio.post('/auth/login', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<User> getProfile() async {
    final response = await _client.dio.get('/auth/profile');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    String? name,
    String? avatarUrl,
    String? password,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (password != null) data['password'] = password;
    if (email != null) data['email'] = email;
    final response = await _client.dio.put('/auth/profile', data: data);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── WeChat OAuth ──

  /// Returns the WeChat authorization URL from the server.
  Future<Map<String, dynamic>> getWeChatAuthUrl() async {
    final response = await _client.dio.get('/auth/wechat/auth-url');
    return response.data as Map<String, dynamic>;
  }

  /// Exchange WeChat code for login token.
  Future<Map<String, dynamic>> weChatCallback(String code) async {
    final response = await _client.dio.post('/auth/wechat/callback', data: {
      'code': code,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Bind WeChat to current account.
  Future<void> bindWeChat(String code) async {
    await _client.dio.post('/auth/wechat/bind', data: {
      'code': code,
    });
  }

  /// Unbind WeChat from current account.
  Future<void> unbindWeChat() async {
    await _client.dio.post('/auth/wechat/unbind');
  }

  /// Check if current account has WeChat bound.
  Future<bool> isWeChatBound() async {
    final response = await _client.dio.get('/auth/wechat/check');
    final data = response.data as Map<String, dynamic>;
    return data['bound'] == true;
  }

  // ── QQ OAuth ──

  /// Returns the QQ authorization URL from the server.
  Future<Map<String, dynamic>> getQQAuthUrl() async {
    final response = await _client.dio.get('/auth/qq/auth-url');
    return response.data as Map<String, dynamic>;
  }

  /// Exchange QQ code for login token.
  Future<Map<String, dynamic>> qqCallback(String code) async {
    final response = await _client.dio.post('/auth/qq/callback', data: {
      'code': code,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Bind QQ to current account.
  Future<void> bindQQ(String code) async {
    await _client.dio.post('/auth/qq/bind', data: {
      'code': code,
    });
  }

  /// Unbind QQ from current account.
  Future<void> unbindQQ() async {
    await _client.dio.post('/auth/qq/unbind');
  }

  /// Check if current account has QQ bound.
  Future<bool> isQQBound() async {
    final response = await _client.dio.get('/auth/qq/check');
    final data = response.data as Map<String, dynamic>;
    return data['bound'] == true;
  }
}
