from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone

from jobs.models import Customer, Job, Quotation, QuotationItem, StatusLog

User = get_user_model()
employee = User.objects.first()
if not employee:
    print("Create an employee first: python manage.py create_employee sidra 123456")
    raise SystemExit(1)

now = timezone.now()

# Varied cases so every Cases filter has something to show.
# Leave barcode empty so it stays equal to the invoice number.
samples = [
    dict(
        serial="DEMO-01",
        days_ago=0,
        customer_name="Ahmed Said",
        customer_phone="0791111111",
        customer_email="ahmed.said@example.com",
        hard_disk_type="hdd_25",
        device_model="Western Digital",
        problem="Drive not spinning",
        status="received",
        work_status="pending",
    ),
    dict(
        serial="DEMO-02",
        days_ago=0,
        customer_name="Rima Khalil",
        customer_phone="0792222222",
        customer_email="rima.khalil@example.com",
        hard_disk_type="ssd",
        device_model="Samsung",
        problem="Data loss after format",
        status="received",
        client_report="agree",
        work_status="pending",
        price="150.00",
    ),
    dict(
        serial="DEMO-03",
        days_ago=1,
        customer_name="Rima Khalil",
        customer_phone="0792222222",
        customer_email="rima.khalil@example.com",
        hard_disk_type="nvme",
        device_model="Kingston NV2",
        problem="NVMe not detected",
        status="received",
        client_report="agree",
        work_status="in_progress",
        price="280.00",
        with_quotation=True,
    ),
    dict(
        serial="DEMO-04",
        days_ago=3,
        customer_name="Mohamed Nour",
        customer_phone="0793333333",
        customer_email="mohamed.nour@example.com",
        hard_disk_type="external",
        device_model="Seagate Backup Plus",
        problem="Clicking sound",
        status="has_problems",
        client_report="rejected",
        work_status="pending",
        report_flag="no_spare_parts",
    ),
    dict(
        serial="DEMO-05",
        days_ago=5,
        overdue_wait=True,
        customer_name="Sara Haddad",
        customer_phone="0794444444",
        customer_email="sara.haddad@example.com",
        hard_disk_type="hdd_35",
        device_model="Toshiba",
        problem="Slow and noisy drive",
        status="received",
        client_report="wait_client",
        work_status="pending",
        price="200.00",
    ),
    dict(
        serial="DEMO-06",
        days_ago=0,
        customer_name="Omar Faris",
        customer_phone="0795555555",
        customer_email="omar.faris@example.com",
        hard_disk_type="usb",
        device_model="SanDisk",
        problem="Flash drive not recognized",
        status="received",
        client_report="wait_client",
        work_status="pending",
        price="40.00",
    ),
    dict(
        serial="DEMO-07",
        days_ago=2,
        customer_name="Lina Saleh",
        customer_phone="0796666666",
        customer_email="lina.saleh@example.com",
        hard_disk_type="usb",
        device_model="Kingston DataTraveler",
        problem="Photos deleted",
        status="completed",
        client_report="finished",
        work_status="finished",
        price="60.00",
        ready=True,
    ),
    dict(
        serial="DEMO-08",
        days_ago=25,
        customer_name="Karim Nasser",
        customer_phone="0797777777",
        customer_email="karim.nasser@example.com",
        hard_disk_type="memory_card",
        device_model="Samsung EVO",
        problem="Memory card unreadable",
        status="completed",
        work_status="finished",
        price="35.00",
    ),
    dict(
        serial="DEMO-09",
        days_ago=0,
        customer_name="Huda Mansour",
        customer_phone="0798888888",
        customer_email="huda.mansour@example.com",
        hard_disk_type="ssd",
        device_model="Crucial MX500",
        problem="Laptop not booting",
        status="received",
        work_status="in_progress",
    ),
    dict(
        serial="DEMO-10",
        days_ago=6,
        customer_name="Tarek Younes",
        customer_phone="0799990000",
        customer_email="tarek.younes@example.com",
        hard_disk_type="hdd_35",
        device_model="WD Purple",
        problem="Dropped drive",
        status="completed",
        client_report="agree",
        work_status="finished",
        price="320.00",
        ready=True,
        with_quotation=True,
    ),
    dict(
        serial="DEMO-11",
        days_ago=1,
        customer_name="Maya Rahim",
        customer_phone="0791010101",
        customer_email="maya.rahim@example.com",
        hard_disk_type="hdd_25",
        device_model="Hitachi",
        problem="Partition missing",
        status="received",
        work_status="pending",
    ),
    dict(
        serial="DEMO-12",
        days_ago=8,
        customer_name="Fadi Kassem",
        customer_phone="0791212121",
        customer_email="fadi.kassem@example.com",
        hard_disk_type="other",
        device_model="Unknown NAS",
        problem="RAID array failed",
        status="has_problems",
        client_report="rejected",
        work_status="finished",
        report_flag="send_out_china",
    ),
    dict(
        serial="DEMO-13",
        days_ago=0,
        customer_name="Nour Alami",
        customer_phone="0791313131",
        customer_email="nour.alami@example.com",
        hard_disk_type="external",
        device_model="WD My Passport",
        problem="Cable damaged, files inaccessible",
        status="received",
        client_report="agree",
        work_status="in_progress",
        price="180.00",
        with_quotation=True,
    ),
    dict(
        serial="DEMO-14",
        days_ago=4,
        customer_name="Ahmed Said",
        customer_phone="0791111111",
        customer_email="ahmed.said@example.com",
        hard_disk_type="ssd",
        device_model="Samsung 980",
        problem="Windows will not start",
        status="completed",
        client_report="finished",
        work_status="finished",
        price="90.00",
        delivered=True,
    ),
]

created = 0
for raw in samples:
    serial = raw["serial"]
    if Job.objects.filter(serial_number=serial).exists():
        print("Skip existing:", serial)
        continue

    days_ago = raw.pop("days_ago", 0)
    overdue_wait = raw.pop("overdue_wait", False)
    with_quotation = raw.pop("with_quotation", False)
    ready = raw.pop("ready", False)
    delivered = raw.pop("delivered", False)
    serial_number = raw.pop("serial")
    status = raw.pop("status")
    client_report = raw.pop("client_report", "")
    work_status = raw.pop("work_status", "")

    job = Job.objects.create(
        created_by=employee,
        status=status,
        serial_number=serial_number,
        client_report=client_report,
        work_status=work_status,
        **raw,
    )
    StatusLog.objects.create(
        job=job,
        field_name=StatusLog.FieldName.STATUS,
        status=status,
        note="Demo data",
        created_by=employee,
    )
    if client_report:
        log = StatusLog.objects.create(
            job=job,
            field_name=StatusLog.FieldName.CLIENT_REPORT,
            status=client_report,
            note="Demo client report",
            created_by=employee,
        )
        if overdue_wait:
            StatusLog.objects.filter(pk=log.pk).update(created_at=now - timedelta(days=5))
    if work_status:
        StatusLog.objects.create(
            job=job,
            field_name=StatusLog.FieldName.WORK_STATUS,
            status=work_status,
            note="Demo work status",
            created_by=employee,
        )

    customer, _ = Customer.objects.get_or_create(
        phone=job.customer_phone,
        defaults={"full_name": job.customer_name, "email": job.customer_email},
    )
    when = now - timedelta(days=days_ago)
    Job.objects.filter(pk=job.pk).update(
        customer=customer,
        created_at=when,
        updated_at=when,
    )
    job.refresh_from_db()

    extra_fields = []
    if ready:
        job.mark_ready_notified()
    if delivered:
        job.mark_delivered()

    if with_quotation and not job.quotations.exists():
        quotation = Quotation.objects.create(
            job=job,
            created_by=employee,
            discount="0.00",
            tax_rate="15.00",
            terms="Payment: 100% CASH",
        )
        QuotationItem.objects.create(
            quotation=quotation,
            description="Head change and recovery data",
            quantity=1,
            unit_price=job.price or "150.00",
        )
        print("Quotation created for", job.invoice_number)

    created += 1
    print(
        "Created:",
        job.invoice_number,
        job.customer_name,
        "report=", job.client_report or "-",
        "work=", job.work_status or "-",
    )

print("New jobs this run:", created)
print("Total jobs:", Job.objects.count())
print("Total customers:", Customer.objects.count())
print("Filter coverage:")
print("  Agree:", Job.objects.filter(client_report="agree").count())
print("  Inspection / In progress:", Job.objects.filter(work_status="in_progress").count())
print("  Wait Client:", Job.objects.filter(client_report="wait_client").count())
print("  Rejected:", Job.objects.filter(client_report="rejected").count())
print("  Pending:", Job.objects.filter(work_status="pending").count())
print("  Done:", Job.objects.filter(work_status="finished").count())
