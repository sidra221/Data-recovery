from decimal import Decimal

from rest_framework import serializers
from django.db.models import Sum

from .models import Customer, Job, Quotation, QuotationItem, StatusLog


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
            "price",
            "report_flag",
            "report_flag_label",
            "created_by_name",
            "invoice_sent",
            "invoice_sent_at",
            "created_at",
            "updated_at",
            "status_logs",
        )
        read_only_fields = (
            "id",
            "invoice_number",
            "status",
            "created_by_name",
            "invoice_sent",
            "invoice_sent_at",
            "ready_notified_at",
            "created_at",
            "updated_at",
            "status_logs",
        )

    def get_invoice_sent(self, obj):
        return obj.invoice_sent_at is not None

    def validate_barcode(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("الباركود مطلوب.")
        return value

    def validate_customer_phone(self, value):
        digits = "".join(ch for ch in value if ch.isdigit() or ch == "+")
        if len(digits) < 8:
            raise serializers.ValidationError("رقم التليفون غير صحيح.")
        return value


class JobCreateSerializer(JobSerializer):
    class Meta(JobSerializer.Meta):
        extra_kwargs = {
            "customer_name": {"required": True},
            "customer_phone": {"required": True},
            "hard_disk_type": {"required": True},
            "barcode": {"required": True},
        }


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

        phone = "".join(ch for ch in obj.customer_phone if ch.isdigit())
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
