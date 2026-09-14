import 'api_config.dart';

class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConfig.apiBaseUrl,
  );
  static const String tokenKey = 'auth_token';

  /// بصمة البناء — بيحطها build_app.sh وقت البناء.
  /// موجودة حتى نعرف بثانية أي نسخة مثبّتة على أي جهاز.
  static const String buildId = String.fromEnvironment(
    'BUILD_ID',
    defaultValue: 'dev',
  );
}
