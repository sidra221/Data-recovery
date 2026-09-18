from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from django.conf import settings as django_settings

from .models import (
    Customer,
    DeviceNumberBlock,
    EmployeeProfile,
    Job,
    JobAttachment,
    Quotation,
    StatusLog,
)
from .services.whatsapp import send_whatsapp_message
from .serializers import (
    CustomerSerializer,
    EmployeeProfileSerializer,
    InvoiceSerializer,
    JobAttachmentSerializer,
    JobCreateSerializer,
    JobSerializer,
    QuotationInvoiceSerializer,
    QuotationSerializer,
    StatusUpdateSerializer,
)


MAX_ATTACHMENT_BYTES = 10 * 1024 * 1024


def _profile_data(user, request):
    profile, _ = EmployeeProfile.objects.get_or_create(user=user)
    return EmployeeProfileSerializer(profile, context={"request": request}).data


class LoginView(ObtainAuthToken):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        data = _profile_data(user, request)
        data.update({"token": token.key, "user_id": user.id, "username": user.username})
        return Response(data)


class MeView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get(self, request):
        return Response(_profile_data(request.user, request))

    def patch(self, request):
        profile, _ = EmployeeProfile.objects.get_or_create(user=request.user)
        serializer = EmployeeProfileSerializer(
            profile,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class JobViewSet(viewsets.ModelViewSet):
    queryset = Job.objects.select_related("created_by").prefetch_related(
        "status_logs__created_by",
        "attachments",
    )
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_serializer_class(self):
        if self.action == "create":
            return JobCreateSerializer
        return JobSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get("status")
        client_report_filter = self.request.query_params.get("client_report")
        work_status_filter = self.request.query_params.get("work_status")
        customer_filter = self.request.query_params.get("customer")
        created_from = self.request.query_params.get("created_from")
        created_to = self.request.query_params.get("created_to")
        search = self.request.query_params.get("search")
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if client_report_filter:
            queryset = queryset.filter(client_report=client_report_filter)
        if work_status_filter:
            queryset = queryset.filter(work_status=work_status_filter)
        if customer_filter:
            # فلترة بمعرّف العميل — أدقّ من البحث بالهاتف يلي ممكن
            # يطابق أرقام عملاء تانيين. قيمة غير رقمية بترجّع فاضي.
            if customer_filter.isdigit():
                queryset = queryset.filter(customer_id=int(customer_filter))
            else:
                queryset = queryset.none()
        # فلترة بتاريخ الإنشاء — YYYY-MM-DD، شاملة للطرفين.
        # تاريخ غير صالح بينتجاهل بدل ما يرجّع 500.
        for value, lookup in ((created_from, "gte"), (created_to, "lte")):
            if not value:
                continue
            try:
                parsed = parse_date(value)
            except ValueError:
                # صيغة سليمة بقيمة مستحيلة مثل 2026-99-99 — parse_date
                # بترفع ValueError مو بترجّع None.
                parsed = None
            if parsed is not None:
                queryset = queryset.filter(**{f"created_at__date__{lookup}": parsed})
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
        overdue = self.request.query_params.get("overdue")
        if overdue == "true":
            # property مش عمود DB — فلترة Python بعد تقييد wait_client.
            # إذا كبر الحجم نحوّلها لحقل DB.
            wait_client_jobs = list(
                queryset.filter(client_report=Job.ClientReport.WAIT_CLIENT)
            )
            overdue_ids = [job.pk for job in wait_client_jobs if job.wait_client_overdue]
            queryset = queryset.filter(pk__in=overdue_ids)
        return queryset

    def perform_create(self, serializer):
        job = serializer.save(created_by=self.request.user, status=Job.Status.RECEIVED)
        StatusLog.objects.create(
            job=job,
            field_name=StatusLog.FieldName.STATUS,
            status=job.status,
            # بدون ملاحظة عن قصد: الحالة "Received" مع الوقت واسم الموظف
            # بيقولوا "انعملت القضية" بالضبط. أي نص هون بينحفظ بلغة وحدة
            # بقاعدة البيانات وما بيقدر يتبع لغة التطبيق.
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
        invoice = InvoiceSerializer(job).data
        message = ""
        if hasattr(request.data, "get"):
            message = (request.data.get("message") or "").strip()
        if not message:
            message = invoice["share_text"]
        job.mark_invoice_sent()
        invoice = InvoiceSerializer(job).data
        invoice["auto_send"] = send_whatsapp_message(job)
        return Response(invoice)

    @action(detail=False, methods=["post"], url_path="device-block")
    def device_block(self, request):
        """بيحجز مدى أرقام للجهاز حتى يقدر يولّد أرقام فواتير وهو أوفلاين.

        idempotent: نفس `device_id` بيرجّع نفس المدى دايماً، فالأب بيقدر
        ينادي كل مرة يفوت بدون ما يستهلك مدايات جديدة.
        """
        device_id = str(request.data.get("device_id") or "").strip()
        if not device_id:
            return Response(
                {"detail": "device_id is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(device_id) > 64:
            return Response(
                {"detail": "device_id is too long"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        block = DeviceNumberBlock.for_device(device_id, user=request.user)
        return Response(
            {
                "device_id": block.device_id,
                "prefix": django_settings.INVOICE_PREFIX,
                "block_start": block.block_start,
                "block_end": block.block_end,
                "block_size": block.block_size,
            }
        )

    @action(detail=True, methods=["get", "post"], url_path="attachments")
    def attachments(self, request, pk=None):
        job = self.get_object()
        if request.method == "GET":
            serializer = JobAttachmentSerializer(
                job.attachments.all(),
                many=True,
                context={"request": request},
            )
            return Response(serializer.data)

        files = request.FILES.getlist("files")
        if not files and "file" in request.FILES:
            files = [request.FILES["file"]]
        if not files:
            return Response(
                {"detail": "No file uploaded"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        created = []
        for uploaded in files:
            if uploaded.size and uploaded.size > MAX_ATTACHMENT_BYTES:
                return Response(
                    {"detail": "File is larger than 10MB"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            attachment = JobAttachment.objects.create(
                job=job,
                file=uploaded,
                original_name=uploaded.name,
            )
            created.append(
                JobAttachmentSerializer(attachment, context={"request": request}).data
            )
        return Response(created, status=status.HTTP_201_CREATED)

    @action(
        detail=True,
        methods=["delete"],
        url_path=r"attachments/(?P<attachment_id>[0-9]+)",
    )
    def delete_attachment(self, request, pk=None, attachment_id=None):
        job = self.get_object()
        attachment = get_object_or_404(job.attachments, pk=attachment_id)
        attachment.file.delete(save=False)
        attachment.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"])
    def deliver(self, request, pk=None):
        job = self.get_object()
        job.mark_delivered()
        return Response(JobSerializer(job).data)


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
            # النص إنكليزي كاحتياطي، والرمز هو يلي بيترجمه التطبيق بلغته.
            return Response(
                {
                    "detail": "Cannot delete a customer that has jobs",
                    "code": "customer_has_jobs",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        return super().destroy(request, *args, **kwargs)


class QuotationViewSet(viewsets.ModelViewSet):
    queryset = Quotation.objects.select_related("created_by").prefetch_related("items")
    serializer_class = QuotationSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_queryset(self):
        queryset = super().get_queryset()
        job_id = self.request.query_params.get("job")
        if job_id:
            queryset = queryset.filter(job_id=job_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=["post"])
    def send(self, request, pk=None):
        quotation = self.get_object()
        quotation.mark_sent()
        quotation = self.get_queryset().get(pk=quotation.pk)
        return Response(QuotationSerializer(quotation).data)

    @action(detail=True, methods=["get"])
    def invoice(self, request, pk=None):
        quotation = self.get_object()
        return Response(QuotationInvoiceSerializer(quotation).data)


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
            "total_delivered": Job.objects.filter(delivered_at__isnull=False).count(),
        }
    )
