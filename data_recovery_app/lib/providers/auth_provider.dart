import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/offline_cache.dart';
import '../core/secure_storage.dart';
import '../models/employee_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.profile,
    this.error,
    this.isOffline = false,
  });

  final AuthStatus status;
  final EmployeeProfile? profile;
  final String? error;

  /// فتنا ببروفايل محفوظ لأن السيرفر ما ردّ.
  final bool isOffline;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  String? get username => profile?.username;
}

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    cache: ref.watch(offlineCacheProvider),
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
      await ref
          .read(offlineCacheProvider)
          .write(OfflineCache.keyProfile, profile.toJson());
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(secureStorageProvider).clearToken();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        // التوكن لساته صالح بقد ما منعرف — منفوت بالبروفايل المحفوظ بدل
        // ما تطلع الشاشة باسم وإيميل فاضيين.
        state = AuthState(
          status: AuthStatus.authenticated,
          profile: await _cachedProfile(),
          isOffline: error.isNetworkError,
        );
      }
    } catch (_) {
      state = AuthState(
        status: AuthStatus.authenticated,
        profile: await _cachedProfile(),
        isOffline: true,
      );
    }
  }

  Future<EmployeeProfile?> _cachedProfile() async {
    final cached =
        await ref.read(offlineCacheProvider).read(OfflineCache.keyProfile);
    final data = cached?.data;
    if (data is! Map) return null;
    try {
      return EmployeeProfile.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
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
    // الكاش بيخص الموظف يلي كان داخل — ما لازم يضل للي بعده.
    await ref.read(offlineCacheProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
