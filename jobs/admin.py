from django.contrib import admin

from .models import Job, StatusLog


class StatusLogInline(admin.TabularInline):
    model = StatusLog
    extra = 0
    readonly_fields = ("field_name", "status", "note", "created_by", "created_at")
    can_delete = False


@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = (
        "invoice_number",
        "customer_name",
        "customer_phone",
        "hard_disk_type",
        "barcode",
        "status",
        "client_report",
        "work_status",
        "created_at",
    )
    list_filter = ("status", "client_report", "work_status", "hard_disk_type", "created_at")
    search_fields = ("invoice_number", "barcode", "customer_name", "customer_phone", "serial_number", "device_model")
    readonly_fields = ("invoice_number", "invoice_sent_at", "ready_notified_at", "created_at", "updated_at")
    inlines = [StatusLogInline]


@admin.register(StatusLog)
class StatusLogAdmin(admin.ModelAdmin):
    list_display = ("job", "field_name", "status", "note", "created_by", "created_at")
    list_filter = ("field_name", "status", "created_at")
    search_fields = ("job__invoice_number", "job__barcode", "note")
