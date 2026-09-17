from decimal import Decimal

from rest_framework import serializers
from django.db.models import Sum

from .models import (
    Customer,
    DeviceNumberBlock,
    EmployeeProfile,
    Job,
    JobAttachment,
    Quotation,
    QuotationItem,
    StatusLog,
)
from .services.whatsapp import wa_me_number


class EmployeeProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.EmailField(source="user.email", allow_blank=True, required=False)
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = EmployeeProfile
        fields = ("username", "email", "phone", "role", "department", "photo", "photo_url")
        extra_kwargs = {"photo": {"write_only": True, "required": False}}

    def get_photo_url(self, obj):
        if not obj.photo:
            return ""
        request = self.context.get("request")
        url = obj.photo.url
        if request:
            return request.build_absolute_uri(url)
        return url

    def update(self, instance, validated_data):
        user_data = validated_data.pop("user", None)
        instance = super().update(instance, validated_data)
        if user_data and "email" in user_data:
            instance.user.email = user_data["email"]
            instance.user.save(update_fields=["email"])
        return instance


class JobAttachmentSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = JobAttachment
        fields = ("id", "original_name", "url", "uploaded_at")
        read_only_fields = fields

    def get_url(self, obj):
        request = self.context.get("request")
        url = obj.file.url
        if request:
            return request.build_absolute_uri(url)
        return url


class CustomerSerializer(serializers.ModelSerializer):
    total_repairs = serializers.SerializerMethodField()
    total_spent = serializers.SerializerMethodField()
    first_visit = serializers.SerializerMethodField()
    last_visit = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = (
            "id",
            "full_name",
            "phone",
            "email",
            "created_at",
            "total_repairs",
            "total_spent",
            "first_visit",
            "last_visit",
        )
        read_only_fields = (
            "id",
            "created_at",
            "total_repairs",
            "total_spent",
            "first_visit",
            "last_visit",
        )

    def get_total_repairs(self, obj):
        return obj.jobs.count()

    def get_total_spent(self, obj):
        total = obj.jobs.exclude(price=None).aggregate(total=Sum("price"))["total"]
        if total is None:
            return "0.00"
        return f"{Decimal(total):.2f}"

    def get_first_visit(self, obj):
        return obj.jobs.order_by("created_at").values_list("created_at", flat=True).first()

    def get_last_visit(self, obj):
        return obj.jobs.order_by("-created_at").values_list("created_at", flat=True).first()


class StatusLogSerializer(serializers.ModelSerializer):
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    field_name_label = serializers.CharField(source="get_field_name_display", read_only=True)
    created_by_name = serializers.CharField(source="created_by.username", read_only=True)

    class Meta:
        model = StatusLog
        fields = ("id", "field_name", "field_name_label", "status", "status_label", "note", "created_by_name", "created_at")


class JobSerializer(serializers.ModelSerializer):
    hard_disk_type_label = serializers.CharField(source="get_hard_disk_type_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    client_report_label = serializers.CharField(source="get_client_report_display", read_only=True)
    work_status_label = serializers.CharField(source="get_work_status_display", read_only=True)
    report_flag_label = serializers.CharField(source="get_report_flag_display", read_only=True)
    created_by_name = serializers.CharField(source="created_by.username", read_only=True)
    status_logs = StatusLogSerializer(many=True, read_only=True)
    invoice_sent = serializers.SerializerMethodField()
    wait_client_overdue = serializers.BooleanField(read_only=True)
    attachments = JobAttachmentSerializer(many=True, read_only=True)

    class Meta:
        model = Job
        fields = (
            "id",
            "invoice_number",
            "barcode",
            "customer_name",
            "customer_phone",
            "hard_disk_type",
            "hard_disk_type_label",
            "status",
            "status_label",
            "client_report",
            "client_report_label",
            "work_status",
            "work_status_label",
            "notes",
            "problem",
            "device_model",
            "serial_number",
            "customer_email",
            "attached_equipment",
            "inspection_notes",
            "ready_notified_at",
            "delivered_at",
            "price",
            "report_flag",
            "report_flag_label",
            "created_by_name",
            "invoice_sent",
            "invoice_sent_at",
            "created_at",
            "updated_at",
            "status_logs",
            "wait_client_overdue",
            "attachments",
        )
        read_only_fields = (
            "id",
            "invoice_number",
            "barcode",
            "status",
            "created_by_name",
            "invoice_sent",
            "invoice_sent_at",
            "ready_notified_at",
            "delivered_at",
            "created_at",
            "updated_at",
            "status_logs",
            "wait_client_overdue",
            "attachments",
        )

    def get_invoice_sent(self, obj):
        return obj.invoice_sent_at is not None

    def validate_customer_phone(self, value):
        digits = "".join(ch for ch in value if ch.isdigit() or ch == "+")
        if len(digits) < 8:
            raise serializers.ValidationError("رقم التليفون غير صحيح.")
        return value


class JobCreateSerializer(JobSerializer):
    """الإنشاء العادي + حالة الأوفلاين.

    `invoice_number` عادة بيولّده السيرفر. بس لما الجهاز ينشئ عملية وهو
    أوفلاين بيولّد رقم من المدى المحجوز إله ويطبع الستيكر فوراً، وبعدين
    بيبعت نفس الرقم وقت المزامنة — فلازم نقبله لو إجا.
    """

    invoice_number = serializers.CharField(required=False, allow_blank=True)

    class Meta(JobSerializer.Meta):
        extra_kwargs = {
            "customer_name": {"required": True},
            "customer_phone": {"required": True},
            "hard_disk_type": {"required": True},
        }

    def validate_invoice_number(self, value):
        value = (value or "").strip()
        if not value:
            return value
        sequence = _offline_sequence(value)
        if sequence is None:
            raise serializers.ValidationError(
                "invoice_number must look like PREFIX-YYYYMMDD-NNNN"
            )
        if sequence < DeviceNumberBlock.OFFLINE_FLOOR:
            # أرقام تحت الحد بيوزّعها السيرفر. لو قبلناها من الأب منفتح
            # باب تصادم مع رقم السيرفر رح يوزّعه بعدين.
            raise serializers.ValidationError(
                "only numbers inside a reserved device block may be supplied"
            )
        if Job.objects.filter(invoice_number=value).exists():
            raise serializers.ValidationError("invoice_number already exists")
        return value


def _offline_sequence(invoice_number):
    """بيرجّع التسلسل من `PREFIX-YYYYMMDD-NNNN`، أو None لو الشكل غلط."""
    parts = invoice_number.rsplit("-", 1)
    if len(parts) != 2 or not parts[1].isdigit():
        return None
    return int(parts[1])


class StatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Job.Status.choices)
    note = serializers.CharField(max_length=255, required=False, allow_blank=True)


class InvoiceSerializer(serializers.ModelSerializer):
    hard_disk_type_label = serializers.CharField(source="get_hard_disk_type_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    company = serializers.SerializerMethodField()
    share_text = serializers.SerializerMethodField()
    whatsapp_url = serializers.SerializerMethodField()

    class Meta:
        model = Job
        fields = (
            "invoice_number",
            "barcode",
            "customer_name",
            "customer_phone",
            "hard_disk_type",
            "hard_disk_type_label",
            "status",
            "status_label",
            "notes",
            "created_at",
            "invoice_sent_at",
            "company",
            "share_text",
            "whatsapp_url",
        )

    def get_company(self, obj):
        from django.conf import settings

        return settings.COMPANY_NAME

    def get_share_text(self, obj):
        from django.conf import settings

        return (
            f"{settings.COMPANY_NAME}\n"
            f"فاتورة رقم: {obj.invoice_number}\n"
            f"العميل: {obj.customer_name}\n"
            f"التليفون: {obj.customer_phone}\n"
            f"نوع الهارد: {obj.get_hard_disk_type_display()}\n"
            f"الباركود: {obj.barcode}\n"
            f"الحالة: {obj.get_status_display()}"
        )

    def get_whatsapp_url(self, obj):
        from urllib.parse import quote

        phone = wa_me_number(obj.customer_phone)
        text = self.get_share_text(obj)
        return f"https://wa.me/{phone}?text={quote(text)}"


class QuotationItemSerializer(serializers.ModelSerializer):
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = QuotationItem
        fields = ("id", "description", "quantity", "unit_price", "total")


class QuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True)
    subtotal = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    tax_amount = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    created_by_name = serializers.CharField(source="created_by.username", read_only=True)

    class Meta:
        model = Quotation
        fields = (
            "id", "job", "items", "discount", "tax_rate", "terms",
            "subtotal", "tax_amount", "total", "created_by_name",
            "created_at", "sent_at",
        )
        read_only_fields = ("id", "created_by_name", "created_at", "sent_at")

    def create(self, validated_data):
        items_data = validated_data.pop("items")
        quotation = Quotation.objects.create(**validated_data)
        for item in items_data:
            QuotationItem.objects.create(quotation=quotation, **item)
        return quotation

    def update(self, instance, validated_data):
        items_data = validated_data.pop("items", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if items_data is not None:
            instance.items.all().delete()
            for item in items_data:
                QuotationItem.objects.create(quotation=instance, **item)
        return instance


class QuotationInvoiceSerializer(serializers.Serializer):
    company = serializers.SerializerMethodField()
    invoice_number = serializers.CharField(source="job.invoice_number", read_only=True)
    customer = serializers.SerializerMethodField()
    device = serializers.SerializerMethodField()
    items = QuotationItemSerializer(many=True, read_only=True)
    subtotal = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    discount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    tax_rate = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    tax_amount = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    terms = serializers.CharField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)

    def get_company(self, obj):
        from django.conf import settings

        return {
            "name": settings.COMPANY_NAME,
            "tax_number": settings.COMPANY_TAX_NUMBER,
            "cr_number": settings.COMPANY_CR_NUMBER,
            "address": settings.COMPANY_ADDRESS,
        }

    def get_customer(self, obj):
        job = obj.job
        return {
            "name": job.customer_name,
            "phone": job.customer_phone,
            "email": job.customer_email,
        }

    def get_device(self, obj):
        job = obj.job
        return {
            "type": job.get_hard_disk_type_display(),
            "model": job.device_model,
            "serial_number": job.serial_number,
        }
