import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';

// ── Auth State ──

/// Represents the authentication state of the app.
sealed class AuthState {
  const AuthState();
}

/// User is authenticated with a [user] and optionally a [token].
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

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Auth state is being determined (e.g., checking stored token on startup).
class AuthLoading extends AuthState {
  const AuthLoading();
}

// ── Secure Storage Keys ──

const _tokenKey = 'auth_token';
const _userIdKey = 'auth_user_id';

// ── Auth Notifier ──

/// Manages authentication state, including token persistence.
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthNotifier(this._storage) : super(const AuthLoading()) {
    _tryRestoreToken();
  }

  /// Attempt to restore auth state from secure storage on app start.
  Future<void> _tryRestoreToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final userIdStr = await _storage.read(key: _userIdKey);

      if (token != null && userIdStr != null) {
        final userId = int.parse(userIdStr);
        // TODO: fetch full user profile from API using token
        // For now, create a placeholder user.
        state = AuthAuthenticated(
          user: User(
            id: userId,
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

  /// Log in with phone/email and password.
  /// Calls the auth API and persists the token on success.
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

      await _storage.write(key: _tokenKey, value: token);

      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Register a new account.
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

      await _storage.write(key: _tokenKey, value: token);

      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Log out and clear stored token.
  Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
    } catch (_) {
      // Ignore storage errors on logout
    }
    state = const AuthUnauthenticated();
  }

  /// Update the current user object (e.g., after profile fetch).
  void updateUser(User user) {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(user: user, token: current.token);
    }
  }
}

// ── Providers ──

/// Secure storage instance (lazy singleton).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Authentication state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

/// Convenience provider that returns whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

/// Convenience provider that returns the current user (null if not authenticated).
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});

/// Convenience provider that returns the current auth token (null if not authenticated).
final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.token;
  return null;
});
