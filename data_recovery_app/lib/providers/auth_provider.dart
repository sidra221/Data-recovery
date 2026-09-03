import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.username,
    this.userId,
    this.error,
  });

  final AuthStatus status;
  final String? username;
  final int? userId;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
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
    if (token != null && token.isNotEmpty) {
      state = const AuthState(status: AuthStatus.authenticated);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    try {
      final result = await ref.read(apiClientProvider).login(
            username: username,
            password: password,
          );
      await ref.read(secureStorageProvider).saveToken(result.token);
      state = AuthState(
        status: AuthStatus.authenticated,
        username: result.username,
        userId: result.userId,
      );
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.message,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
