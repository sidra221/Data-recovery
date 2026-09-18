import '../l10n/app_localizations.dart';
import 'api_client.dart';

/// بيحوّل خطأ من السيرفر لنص بلغة التطبيق.
///
/// رسالة السيرفر بتجي بلغة وحدة ثابتة، فعرضها متل ما هي بيكسر التعريب. لما
/// السيرفر يبعت [ApiException.code] منعرض نصّنا المترجم؛ وإلا منرجع لرسالته
/// (أحسن من لا شي)، وإذا كانت فاضية منستعمل [fallback].
String apiErrorText(L l, ApiException error, {required String fallback}) {
  switch (error.code) {
    case 'customer_has_jobs':
      return l.cannotDeleteCustomerWithJobs;
    case 'invalid_phone':
      return l.invalidPhone;
  }
  return error.message.isNotEmpty ? error.message : fallback;
}
