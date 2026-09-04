from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import Customer, Job, StatusLog
from .serializers import (
    CustomerSerializer,
    InvoiceSerializer,
    JobCreateSerializer,
    JobSerializer,
    StatusUpdateSerializer,
)


class LoginView(ObtainAuthToken):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {
                "token": token.key,
                "user_id": user.id,
                "username": user.username,
            }
        )


class JobViewSet(viewsets.ModelViewSet):
    queryset = Job.objects.select_related("created_by").prefetch_related("status_logs__created_by")
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_serializer_class(self):
        if self.action == "create":
            return JobCreateSerializer
        return JobSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get("status")
        search = self.request.query_params.get("search")
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if search:
            queryset = queryset.filter(
                Q(customer_name__icontains=search)
                | Q(customer_phone__icontains=search)
                | Q(barcode__icontains=search)
                | Q(invoice_number__icontains=search)
                | Q(device_model__icontains=search)
                | Q(serial_number__icontains=search)
                | Q(problem__icontains=search)
            )
        return queryset

    def perform_create(self, serializer):
        job = serializer.save(created_by=self.request.user, status=Job.Status.RECEIVED)
        StatusLog.objects.create(
            job=job,
            field_name=StatusLog.FieldName.STATUS,
            status=job.status,
            note="تم إنشاء الفاتورة",
            created_by=self.request.user,
        )
        customer, created = Customer.objects.get_or_create(
            phone=job.customer_phone,
            defaults={
                "full_name": job.customer_name,
                "email": job.customer_email,
            },
        )
        if not created:
            customer.full_name = job.customer_name
            customer.email = job.customer_email
            customer.save(update_fields=["full_name", "email"])
        job.customer = customer
        job.save(update_fields=["customer"])

    def perform_update(self, serializer):
        old_client_report = serializer.instance.client_report
        old_work_status = serializer.instance.work_status
        job = serializer.save()
        if "client_report" in serializer.validated_data and job.client_report != old_client_report:
            StatusLog.objects.create(
                job=job,
                field_name=StatusLog.FieldName.CLIENT_REPORT,
                status=job.client_report,
                created_by=self.request.user,
            )
        if "work_status" in serializer.validated_data and job.work_status != old_work_status:
            StatusLog.objects.create(
                job=job,
                field_name=StatusLog.FieldName.WORK_STATUS,
                status=job.work_status,
                created_by=self.request.user,
            )

    @action(detail=False, methods=["get"], url_path="scan/(?P<barcode>[^/.]+)")
    def scan(self, request, barcode=None):
        job = get_object_or_404(self.get_queryset(), barcode=barcode.strip())
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=["post"], url_path="status")
    def update_status(self, request, pk=None):
        job = self.get_object()
        serializer = StatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data["status"]
        note = serializer.validated_data.get("note", "")
        job.status = new_status
        job.save(update_fields=["status", "updated_at"])
        StatusLog.objects.create(
            job=job,
            field_name=StatusLog.FieldName.STATUS,
            status=new_status,
            note=note,
            created_by=request.user,
        )
        job = self.get_queryset().get(pk=job.pk)
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=["get"])
    def invoice(self, request, pk=None):
        return Response(InvoiceSerializer(self.get_object()).data)

    @action(detail=True, methods=["post"])
    def send(self, request, pk=None):
        job = self.get_object()
        job.mark_invoice_sent()
        return Response(InvoiceSerializer(job).data)


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all().order_by("-created_at")
    serializer_class = CustomerSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "patch", "delete", "head", "options"]

    def get_queryset(self):
        queryset = super().get_queryset()
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search)
                | Q(phone__icontains=search)
                | Q(email__icontains=search)
            )
        return queryset

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.jobs.exists():
            return Response(
                {"detail": "لا يمكن حذف عميل لديه فواتير مرتبطة"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return super().destroy(request, *args, **kwargs)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def meta(request):
    return Response(
        {
            "hard_disk_types": [
                {"value": value, "label": label} for value, label in Job.DiskType.choices
            ],
            "statuses": [
                {"value": value, "label": label} for value, label in Job.Status.choices
            ],
            "client_reports": [
                {"value": v, "label": l} for v, l in Job.ClientReport.choices
            ],
            "work_statuses": [
                {"value": v, "label": l} for v, l in Job.WorkStatus.choices
            ],
        }
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def health(request):
    return Response({"ok": True, "service": "01 Data Recovery"})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    status_counts = {
        value: Job.objects.filter(status=value).count()
        for value, _ in Job.Status.choices
    }
    client_report_counts = {
        value: Job.objects.filter(client_report=value).count()
        for value, _ in Job.ClientReport.choices
    }
    client_report_counts["unset"] = Job.objects.filter(client_report="").count()
    work_status_counts = {
        value: Job.objects.filter(work_status=value).count()
        for value, _ in Job.WorkStatus.choices
    }
    work_status_counts["unset"] = Job.objects.filter(work_status="").count()

    today = timezone.localdate()
    jobs_created_today = Job.objects.filter(created_at__date=today).count()
    status_changes_today = StatusLog.objects.filter(created_at__date=today).count()

    return Response(
        {
            "status_counts": status_counts,
            "client_report_counts": client_report_counts,
            "work_status_counts": work_status_counts,
            "total_customers": Customer.objects.count(),
            "total_jobs": Job.objects.count(),
            "jobs_created_today": jobs_created_today,
            "status_changes_today": status_changes_today,
        }
    )
