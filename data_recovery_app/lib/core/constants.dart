import 'api_config.dart';

class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConfig.apiBaseUrl,
  );
  static const String tokenKey = 'auth_token';
}
