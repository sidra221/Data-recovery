import 'api_config.dart';

class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConfig.apiBaseUrl,
  );
  /// اسم الشركة على المطبوعات (ملصق، سند استلام، عرض سعر).
  ///
  /// إنكليزي بس عن قصد: العلامة معروفة هيك، والترجمة العربية طويلة
  /// ("مكتب من الصفر إلى الواحد لاسترجاع الملفات") وما حدا بيستعملها.
  static const String companyName = '01 Data Recovery';

  static const String tokenKey = 'auth_token';
  static const String localeKey = 'app_locale';

  /// بصمة البناء — بيحطها build_app.sh وقت البناء.
  /// موجودة حتى نعرف بثانية أي نسخة مثبّتة على أي جهاز.
  static const String buildId = String.fromEnvironment(
    'BUILD_ID',
    defaultValue: 'dev',
  );
}
