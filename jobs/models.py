from django.conf import settings
from django.db import models, transaction
from django.utils import timezone


class Job(models.Model):
    class DiskType(models.TextChoices):
        HDD_35 = "hdd_35", "HDD 3.5"
        HDD_25 = "hdd_25", "HDD 2.5"
        SSD = "ssd", "SSD"
        NVME = "nvme", "NVMe"
        EXTERNAL = "external", "هارد خارجي"
        USB = "usb", "فلاش USB"
        MEMORY_CARD = "memory_card", "كرت ذاكرة"
        OTHER = "other", "أخرى"

    class Status(models.TextChoices):
        RECEIVED = "received", "تم الاستلام"
        FINISHED = "finished", "فنش"
        COMPLETED = "completed", "خلص"
        HAS_PROBLEMS = "has_problems", "في مشاكل"

    class ClientReport(models.TextChoices):
        AGREE = "agree", "موافق على السعر"
        WAIT_CLIENT = "wait_client", "بانتظار رد العميل"
        FINISHED = "finished", "خلص / جاهز للاستلام"

    class WorkStatus(models.TextChoices):
        PENDING = "pending", "قيد الانتظار"
        IN_PROGRESS = "in_progress", "قيد التنفيذ / البحث عن قطع"
        FINISHED = "finished", "انتهى الإصلاح"

    invoice_number = models.CharField("رقم الفاتورة", max_length=32, unique=True, editable=False)
    barcode = models.CharField("الباركود", max_length=64, unique=True, db_index=True)
    customer_name = models.CharField("اسم العميل", max_length=120)
    customer_phone = models.CharField("رقم التليفون", max_length=20)
    hard_disk_type = models.CharField("نوع الهارد", max_length=20, choices=DiskType)
    status = models.CharField(
        "حالة المتابعة",
        max_length=20,
        choices=Status,
        default=Status.RECEIVED,
    )
    client_report = models.CharField(
        "قرار العميل على السعر", max_length=20, choices=ClientReport, blank=True,
    )
    work_status = models.CharField(
        "حالة الشغل (بعد الموافقة)", max_length=20, choices=WorkStatus, blank=True,
    )
    notes = models.TextField("ملاحظات", blank=True)
    problem = models.TextField(
        "المشكلة (كلام العميل)",
        blank=True,
        help_text="نص حر - يلي قاله العميل عن المشكلة (Customer Comments)",
    )
    device_model = models.CharField(
        "الموديل / الماركة",
        max_length=120,
        blank=True,
        help_text="مثال: Western Digital، Toshiba",
    )
    serial_number = models.CharField("الرقم التسلسلي S/N", max_length=120, blank=True)
    customer_email = models.EmailField("إيميل العميل", blank=True)
    attached_equipment = models.TextField(
        "الملحقات المرافقة",
        blank=True,
        help_text="مثال: كيبل، علبة، شنطة",
    )
    inspection_notes = models.TextField(
        "ملاحظات الفحص",
        blank=True,
        help_text="ملاحظات الموظف بعد الفحص - منفصلة عن كلام العميل",
    )
    ready_notified_at = models.DateTimeField("وقت تبليغ العميل بالجاهزية", null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="jobs",
        verbose_name="الموظف",
    )
    invoice_sent_at = models.DateTimeField("وقت إرسال الفاتورة", null=True, blank=True)
    created_at = models.DateTimeField("تاريخ الإنشاء", auto_now_add=True)
    updated_at = models.DateTimeField("آخر تحديث", auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "فاتورة / عملية"
        verbose_name_plural = "الفواتير / العمليات"

    def __str__(self):
        return f"{self.invoice_number} — {self.customer_name}"

    def save(self, *args, **kwargs):
        self.barcode = self.barcode.strip()
        self.customer_name = self.customer_name.strip()
        self.customer_phone = "".join(self.customer_phone.split())
        if not self.invoice_number:
            self.invoice_number = self._next_invoice_number()
        super().save(*args, **kwargs)

    @classmethod
    def _next_invoice_number(cls):
        today = timezone.localdate()
        prefix = f"{settings.INVOICE_PREFIX}-{today:%Y%m%d}-"
        with transaction.atomic():
            last = (
                cls.objects.select_for_update()
                .filter(invoice_number__startswith=prefix)
                .order_by("-invoice_number")
                .first()
            )
            sequence = int(last.invoice_number.rsplit("-", 1)[-1]) + 1 if last else 1
        return f"{prefix}{sequence:04d}"

    def mark_invoice_sent(self):
        self.invoice_sent_at = timezone.now()
        self.save(update_fields=["invoice_sent_at", "updated_at"])

    def mark_ready_notified(self):
        self.ready_notified_at = timezone.now()
        self.save(update_fields=["ready_notified_at", "updated_at"])


class StatusLog(models.Model):
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name="status_logs")
    status = models.CharField(max_length=20, choices=Job.Status)
    note = models.CharField(max_length=255, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="status_logs",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "سجل حالة"
        verbose_name_plural = "سجل الحالات"

    def __str__(self):
        return f"{self.job.invoice_number} → {self.get_status_display()}"
