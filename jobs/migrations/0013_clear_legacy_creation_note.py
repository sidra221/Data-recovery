from django.db import migrations


LEGACY_NOTE = "تم إنشاء الفاتورة"


def clear_note(apps, schema_editor):
    """بيفضّي الملاحظة العربية الثابتة من سجلات الإنشاء القديمة.

    كانت بتنكتب نصاً عربياً بقاعدة البيانات، فبتظهر عربية بالتطبيق حتى لو
    كان بالإنكليزي. ما بتضيع معلومة: نفس الصف فيه الحالة "received" مع
    وقتها واسم الموظف، وهي بتقول نفس الشي.
    """
    StatusLog = apps.get_model("jobs", "StatusLog")
    StatusLog.objects.filter(note=LEGACY_NOTE).update(note="")


def restore_note(apps, schema_editor):
    """بترجّع الملاحظة لسجلات الإنشاء إذا انرجعنا عن الترحيل."""
    StatusLog = apps.get_model("jobs", "StatusLog")
    StatusLog.objects.filter(
        field_name="status", status="received", note="",
    ).update(note=LEGACY_NOTE)


class Migration(migrations.Migration):
    dependencies = [("jobs", "0012_devicenumberblock")]

    operations = [migrations.RunPython(clear_note, restore_note)]
