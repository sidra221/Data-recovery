from rest_framework import exceptions
from rest_framework.views import exception_handler as drf_exception_handler


def _first_code(detail):
    """بيدوّر على أول رمز خطأ صريح جوّا تفاصيل DRF.

    DRF بيحط `code="invalid"` افتراضياً على كل شي، وهاد ما بيميّز خطأ عن
    غيره — فمنتجاهله ومنرجّع بس الرموز يلي كتبناها إحنا.
    """
    generic = {"invalid", "required", "null", "blank", "error"}

    if isinstance(detail, exceptions.ErrorDetail):
        return None if detail.code in generic else detail.code
    if isinstance(detail, dict):
        for value in detail.values():
            code = _first_code(value)
            if code:
                return code
    if isinstance(detail, list):
        for item in detail:
            code = _first_code(item)
            if code:
                return code
    return None


def exception_handler(exc, context):
    """بيضيف `code` لجسم الخطأ حتى التطبيق يترجمه بلغته.

    بدونه التطبيق ما عنده إلا نص الرسالة، فبيضطر يعرضها متل ما إجت — يعني
    بلغة السيرفر مهما كانت لغة التطبيق. الرمز بيخلّي النص مجرد احتياطي.
    """
    response = drf_exception_handler(exc, context)
    if response is None:
        return None

    code = _first_code(getattr(exc, "detail", None))
    if code and isinstance(response.data, dict):
        response.data.setdefault("code", code)
    return response
