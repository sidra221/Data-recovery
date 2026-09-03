import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) {
    return _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> clearToken() {
    return _storage.delete(key: AppConstants.tokenKey);
  }
}
