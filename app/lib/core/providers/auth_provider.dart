import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';

// ── Auth State ──

sealed class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;
  const AuthAuthenticated({required this.user, required this.token});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && user == other.user && token == other.token;

  @override
  int get hashCode => Object.hash(user, token);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

// ── Auth Notifier ──

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthLoading()) {
    _tryRestoreToken();
  }

  Future<void> _tryRestoreToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        state = AuthAuthenticated(
          user: User(
            id: 0,
            username: 'user',
            email: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          token: token,
        );
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({
    String username = '',
    String email = '',
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final api = AuthApi(ApiClient.instance);
      final Map<String, dynamic> result;
      if (username.isNotEmpty) {
        result = await api.login(phone: username, password: password);
      } else {
        result = await api.login(email: email, password: password);
      }
      final user = User.fromJson(result['user'] as Map<String, dynamic>);
      final token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    String name = '',
    String email = '',
  }) async {
    state = const AuthLoading();
    try {
      final api = AuthApi(ApiClient.instance);
      final result = await api.register(phone: phone, password: password, name: name, email: email);
      final user = User.fromJson(result['user'] as Map<String, dynamic>);
      final token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AuthUnauthenticated();
  }

  void updateUser(User user) {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(user: user, token: current.token);
    }
  }
}

// ── Providers ──

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});

final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.token;
  return null;
});
