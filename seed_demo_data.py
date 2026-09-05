from django.contrib.auth import get_user_model
from jobs.models import Job, StatusLog, Customer, Quotation, QuotationItem

User = get_user_model()
employee = User.objects.first()
if not employee:
    print("لازم تعمل موظف أول: python manage.py create_employee sidra 123456")
else:
    samples = [
        dict(customer_name="أحمد سعيد", customer_phone="0791111111", customer_email="ahmad@example.com",
             hard_disk_type="hdd_25", barcode="HD-9001", device_model="Western Digital",
             serial_number="WD9001", problem="الهارد ما بينقلع", status="received"),
        dict(customer_name="ريما خليل", customer_phone="0792222222", customer_email="rima@example.com",
             hard_disk_type="ssd", barcode="HD-9002", device_model="Samsung",
             serial_number="SSD9002", problem="فقدان بيانات بعد فورمات", status="finished",
             client_report="agree", work_status="in_progress", price="150.00"),
        dict(customer_name="أحمد سعيد", customer_phone="0791111111", customer_email="ahmad@example.com",
             hard_disk_type="usb", barcode="HD-9003", device_model="Kingston",
             serial_number="USB9003", problem="فلاش ما بينعرف عالجهاز", status="completed",
             client_report="finished", work_status="finished", price="60.00"),
        dict(customer_name="محمد نور", customer_phone="0793333333",
             hard_disk_type="external", barcode="HD-9004", device_model="Seagate",
             serial_number="EXT9004", problem="صوت طقطقة بالهارد", status="has_problems",
             report_flag="no_spare_parts"),
    ]

    for data in samples:
        status = data.pop("status")
        job = Job.objects.create(created_by=employee, status=status, **data)
        StatusLog.objects.create(job=job, field_name="status", status=status,
                                  note="بيانات تجريبية", created_by=employee)
        customer, _ = Customer.objects.get_or_create(
            phone=job.customer_phone,
            defaults={"full_name": job.customer_name, "email": job.customer_email},
        )
        job.customer = customer
        job.save(update_fields=["customer"])
        print("Created:", job.invoice_number, job.customer_name)

    first_job = Job.objects.filter(barcode="HD-9001").first()
    if first_job and not first_job.quotations.exists():
        q = Quotation.objects.create(job=first_job, created_by=employee,
                                      discount="10.00", tax_rate="5.00",
                                      terms="Payment: 100% CASH")
        QuotationItem.objects.create(quotation=q, description="فحص الهارد", quantity=1, unit_price="50.00")
        QuotationItem.objects.create(quotation=q, description="استرجاع بيانات", quantity=1, unit_price="200.00")
        print("Quotation created for", first_job.invoice_number)

    print("Total jobs:", Job.objects.count())
    print("Total customers:", Customer.objects.count())
