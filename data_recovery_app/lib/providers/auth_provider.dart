import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/employee_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.profile,
    this.error,
  });

  final AuthStatus status;
  final EmployeeProfile? profile;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  String? get username => profile?.username;
}

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    onUnauthorized: () {
      ref.read(authProvider.notifier).forceLogout();
    },
  );
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _restoreSession() async {
    final token = await ref.read(secureStorageProvider).readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final profile = await ref.read(apiClientProvider).getMe();
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(secureStorageProvider).clearToken();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = const AuthState(status: AuthStatus.authenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.authenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    try {
      final profile = await ref.read(apiClientProvider).login(
            username: username,
            password: password,
          );
      final token = profile.token;
      if (token == null || token.isEmpty) {
        throw ApiException('Invalid login credentials');
      }
      await ref.read(secureStorageProvider).saveToken(token);
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.message,
      );
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    final profile = await ref.read(apiClientProvider).getMe();
    state = AuthState(status: AuthStatus.authenticated, profile: profile);
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
