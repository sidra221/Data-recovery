from datetime import timedelta
from unittest.mock import patch

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import AppSettings, Customer, Job, StatusLog
from .services.whatsapp import to_international, wa_me_number


class JobApiTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()
        self.user = user_model.objects.create_user(username="emp", password="pass12345")
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")
        self.payload = {
            "customer_name": "أحمد علي",
            "customer_phone": "0791234567",
            "hard_disk_type": "hdd_25",
            "notes": "هارد ما بقلع",
        }

    def test_create_job_from_barcode(self):
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["customer_name"], "أحمد علي")
        self.assertEqual(response.data["barcode"], response.data["invoice_number"])
        self.assertEqual(response.data["status"], "received")
        self.assertTrue(response.data["invoice_number"].startswith("01-"))
        self.assertEqual(len(response.data["status_logs"]), 1)

    def test_scan_barcode(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        barcode = created.data["barcode"]
        response = self.client.get(f"/api/jobs/scan/{barcode}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["customer_phone"], "0791234567")

    def test_barcode_matches_invoice_number(self):
        self.assertNotIn("barcode", self.payload)
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["barcode"], response.data["invoice_number"])
        self.assertTrue(response.data["invoice_number"])

    def test_update_followup_status(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        response = self.client.post(
            f"/api/jobs/{job_id}/status/",
            {"status": "completed", "note": "تم الإصلاح"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], "completed")
        self.assertEqual(response.data["status_label"], "Completed")
        self.assertEqual(len(response.data["status_logs"]), 2)

    def test_update_client_report_and_work_status(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        self.assertEqual(created.data["status"], "received")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"client_report": "agree"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["client_report"], "agree")
        self.assertEqual(response.data["client_report_label"], "Agree")
        self.assertEqual(response.data["status"], "received")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"work_status": "in_progress"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["work_status"], "in_progress")
        self.assertEqual(response.data["work_status_label"], "In progress")
        self.assertEqual(response.data["client_report"], "agree")
        self.assertEqual(response.data["status"], "received")

    def test_client_report_and_work_status_are_logged(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        self.assertEqual(len(created.data["status_logs"]), 1)
        self.assertEqual(created.data["status_logs"][0]["field_name"], "status")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"client_report": "agree"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data["status_logs"]), 2)
        self.assertEqual(response.data["status_logs"][0]["field_name"], "client_report")
        self.assertEqual(response.data["status_logs"][0]["status"], "agree")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"work_status": "in_progress"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        logs = response.data["status_logs"]
        self.assertEqual(len(logs), 3)
        self.assertEqual(logs[0]["field_name"], "work_status")
        self.assertEqual(logs[0]["status"], "in_progress")
        self.assertEqual(logs[1]["field_name"], "client_report")
        self.assertEqual(logs[-1]["field_name"], "status")

    def test_reject_client_report(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        response = self.client.patch(
            f"/api/jobs/{created.data['id']}/",
            {"client_report": "rejected"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["client_report"], "rejected")
        self.assertEqual(response.data["client_report_label"], "Rejected")

    def test_mark_delivered(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertIsNone(created.data["delivered_at"])
        response = self.client.post(f"/api/jobs/{created.data['id']}/deliver/")
        self.assertEqual(response.status_code, 200)
        self.assertIsNotNone(response.data["delivered_at"])

    def test_update_price_and_report_flag(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        self.assertEqual(created.data["status"], "received")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"price": "150.00", "report_flag": "no_spare_parts"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(str(response.data["price"]), "150.00")
        self.assertEqual(response.data["report_flag"], "no_spare_parts")
        self.assertEqual(response.data["report_flag_label"], "No spare parts")
        self.assertEqual(response.data["status"], "received")

    def test_invoice_and_send(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        invoice = self.client.get(f"/api/jobs/{job_id}/invoice/")
        self.assertEqual(invoice.status_code, 200)
        self.assertIn("فاتورة رقم", invoice.data["share_text"])
        self.assertIn("wa.me", invoice.data["whatsapp_url"])

        sent = self.client.post(f"/api/jobs/{job_id}/send/")
        self.assertEqual(sent.status_code, 200)
        self.assertIsNotNone(sent.data["invoice_sent_at"])

    def test_wait_client_overdue_flag(self):
        AppSettings.objects.create(wait_client_alert_days=1)
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"client_report": "wait_client"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["wait_client_overdue"])

        StatusLog.objects.filter(
            job_id=job_id,
            field_name=StatusLog.FieldName.CLIENT_REPORT,
        ).update(created_at=timezone.now() - timedelta(days=2))

        response = self.client.get(f"/api/jobs/{job_id}/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["wait_client_overdue"])

    def test_send_invoice_includes_auto_send_status(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        sent = self.client.post(f"/api/jobs/{created.data['id']}/send/")
        self.assertEqual(sent.status_code, 200)
        self.assertIn("auto_send", sent.data)
        self.assertFalse(sent.data["auto_send"]["sent"])
        self.assertEqual(sent.data["auto_send"]["provider"], "none")
        self.assertIsNotNone(sent.data["invoice_sent_at"])

    def test_filter_by_status(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        created = self.client.post("/api/jobs/", self.payload, format="json")
        self.client.post(
            f"/api/jobs/{created.data['id']}/status/",
            {"status": "has_problems"},
            format="json",
        )
        response = self.client.get("/api/jobs/?status=has_problems")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["barcode"], created.data["barcode"])

    def test_filter_by_client_report_and_work_status(self):
        rejected = self.client.post("/api/jobs/", self.payload, format="json")
        in_progress = self.client.post("/api/jobs/", self.payload, format="json")
        self.client.patch(
            f"/api/jobs/{rejected.data['id']}/",
            {"client_report": "rejected"},
            format="json",
        )
        self.client.patch(
            f"/api/jobs/{in_progress.data['id']}/",
            {"work_status": "in_progress"},
            format="json",
        )

        response = self.client.get("/api/jobs/?client_report=rejected")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["id"], rejected.data["id"])

        response = self.client.get("/api/jobs/?work_status=in_progress")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["id"], in_progress.data["id"])

    def test_search_by_new_fields(self):
        first = self.client.post(
            "/api/jobs/",
            dict(self.payload, device_model="Western Digital"),
            format="json",
        )
        self.client.post(
            "/api/jobs/",
            dict(self.payload, device_model="Toshiba"),
            format="json",
        )
        response = self.client.get("/api/jobs/?search=Western")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["barcode"], first.data["barcode"])
        self.assertEqual(response.data["results"][0]["device_model"], "Western Digital")

    def test_unauthenticated_rejected(self):
        self.client.credentials()
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 401)

    def test_login(self):
        self.client.credentials()
        response = self.client.post(
            "/api/auth/login/",
            {"username": "emp", "password": "pass12345"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("token", response.data)

    def test_invalid_phone(self):
        payload = dict(self.payload, customer_phone="12")
        response = self.client.post("/api/jobs/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("customer_phone", response.data)

    def test_create_job_with_new_optional_fields(self):
        payload = dict(
            self.payload,
            problem="لا يعمل من قبل المستخدم",
            device_model="Western Digital",
            serial_number="PDAC2",
            customer_email="ahmad@example.com",
            attached_equipment="كيبل، شنطة",
            inspection_notes="الفحص يحتاج قطع",
        )
        response = self.client.post("/api/jobs/", payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["problem"], "لا يعمل من قبل المستخدم")
        self.assertEqual(response.data["device_model"], "Western Digital")
        self.assertEqual(response.data["serial_number"], "PDAC2")
        self.assertEqual(response.data["customer_email"], "ahmad@example.com")
        self.assertEqual(response.data["attached_equipment"], "كيبل، شنطة")
        self.assertEqual(response.data["inspection_notes"], "الفحص يحتاج قطع")
        self.assertIsNone(response.data["ready_notified_at"])

    def test_new_fields_optional(self):
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["problem"], "")
        self.assertEqual(response.data["device_model"], "")
        self.assertIsNone(response.data["ready_notified_at"])

    def test_meta_choices(self):
        response = self.client.get("/api/meta/")
        self.assertEqual(response.status_code, 200)
        status_values = {item["value"] for item in response.data["statuses"]}
        self.assertEqual(status_values, {"received", "completed", "has_problems"})
        self.assertTrue(Job.objects.count() == 0)

    def test_dashboard_stats(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        self.client.post("/api/jobs/", self.payload, format="json")
        second = self.client.post("/api/jobs/", self.payload, format="json")
        response = self.client.get("/api/dashboard/stats/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status_counts"]["received"], 3)
        self.assertEqual(response.data["total_jobs"], 3)
        self.assertEqual(response.data["total_customers"], 1)
        self.assertGreaterEqual(response.data["jobs_created_today"], 3)
        self.assertEqual(response.data["total_delivered"], 0)
        delivered = self.client.post(f"/api/jobs/{second.data['id']}/deliver/")
        self.assertEqual(delivered.status_code, 200)
        response = self.client.get("/api/dashboard/stats/")
        self.assertEqual(response.data["total_delivered"], 1)

    def test_filter_jobs_by_date_range(self):
        """created_from / created_to بيفلترا بتاريخ الإنشاء، شاملة للطرفين."""
        from datetime import timedelta

        from jobs.models import Job

        created = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(created.status_code, 201)
        job = Job.objects.get(pk=created.data["id"])
        day = job.created_at.date()

        def count(params):
            response = self.client.get("/api/jobs/", params)
            self.assertEqual(response.status_code, 200)
            return response.data["count"]

        # نفس اليوم — لازم يلاقيها (الطرفين شاملين)
        self.assertEqual(count({"created_from": day.isoformat()}), 1)
        self.assertEqual(count({"created_to": day.isoformat()}), 1)
        self.assertEqual(
            count({"created_from": day.isoformat(), "created_to": day.isoformat()}), 1
        )

        # نطاق قبل اليوم — لازم يرجّع فاضي
        before = (day - timedelta(days=2)).isoformat()
        yesterday = (day - timedelta(days=1)).isoformat()
        self.assertEqual(count({"created_from": before, "created_to": yesterday}), 0)

        # نطاق بعد اليوم — فاضي كمان
        tomorrow = (day + timedelta(days=1)).isoformat()
        self.assertEqual(count({"created_from": tomorrow}), 0)

        # تاريخ غير صالح بينتجاهل، ما بينهار
        self.assertEqual(count({"created_from": "خربوطة"}), 1)
        self.assertEqual(count({"created_to": "2026-99-99"}), 1)

    def test_filter_jobs_by_customer(self):
        """?customer=<id> بيرجّع قضايا هالعميل فقط."""
        from jobs.models import Customer, Job

        created = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(created.status_code, 201)
        job = Job.objects.get(pk=created.data["id"])

        other = Customer.objects.create(full_name="عميل تاني", phone="0799999999")
        mine = job.customer
        self.assertIsNotNone(mine, "إنشاء القضية لازم يربطها بعميل")

        response = self.client.get("/api/jobs/", {"customer": mine.id})
        self.assertEqual(response.status_code, 200)
        ids = {row["id"] for row in response.data["results"]}
        self.assertIn(job.id, ids)

        response = self.client.get("/api/jobs/", {"customer": other.id})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 0)

        # قيمة غير رقمية ما بتنهار، بترجّع فاضي
        response = self.client.get("/api/jobs/", {"customer": "abc"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 0)


class CustomerApiTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()
        self.user = user_model.objects.create_user(username="emp", password="pass12345")
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")
        self.payload = {
            "customer_name": "أحمد علي",
            "customer_phone": "0791234567",
            "hard_disk_type": "hdd_25",
            "notes": "هارد ما بقلع",
        }

    def test_customer_created_automatically_on_job_creation(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(created.status_code, 201)
        self.assertEqual(Customer.objects.count(), 1)
        customer = Customer.objects.get()
        self.assertEqual(customer.phone, "0791234567")
        self.assertEqual(customer.full_name, "أحمد علي")

        response = self.client.get("/api/customers/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["phone"], "0791234567")

    def test_customer_stats(self):
        first = self.client.post("/api/jobs/", self.payload, format="json")
        self.client.post("/api/jobs/", self.payload, format="json")
        self.client.patch(
            f"/api/jobs/{first.data['id']}/",
            {"price": "100.00"},
            format="json",
        )
        customer = Customer.objects.get()
        response = self.client.get(f"/api/customers/{customer.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["total_repairs"], 2)
        self.assertEqual(str(response.data["total_spent"]), "100.00")

    def test_second_job_reuses_existing_customer(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(Customer.objects.count(), 1)
        self.assertEqual(Job.objects.count(), 2)

    def test_delete_customer_with_jobs_rejected(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        customer = Customer.objects.get()
        response = self.client.delete(f"/api/customers/{customer.id}/")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Customer.objects.count(), 1)


class QuotationApiTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()
        self.user = user_model.objects.create_user(username="emp", password="pass12345")
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")
        self.payload = {
            "customer_name": "أحمد علي",
            "customer_phone": "0791234567",
            "hard_disk_type": "hdd_25",
            "notes": "هارد ما بقلع",
        }
        self.items = [
            {"description": "فحص", "quantity": "2", "unit_price": "50.00"},
            {"description": "إصلاح", "quantity": "1", "unit_price": "100.00"},
        ]

    def _create_job(self):
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 201)
        return response.data["id"]

    def test_create_quotation_with_items(self):
        job_id = self._create_job()
        response = self.client.post(
            "/api/quotations/",
            {"job": job_id, "items": self.items, "discount": "0", "tax_rate": "0"},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(str(response.data["subtotal"]), "200.00")
        self.assertEqual(str(response.data["total"]), "200.00")

    def test_quotation_totals_with_discount_and_tax(self):
        job_id = self._create_job()
        response = self.client.post(
            "/api/quotations/",
            {
                "job": job_id,
                "items": self.items,
                "discount": "20.00",
                "tax_rate": "10.00",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(str(response.data["subtotal"]), "200.00")
        self.assertEqual(str(response.data["tax_amount"]), "18.00")
        self.assertEqual(str(response.data["total"]), "198.00")

    def test_quotation_filtered_by_job(self):
        first_job = self._create_job()
        second_job = self._create_job()
        self.client.post(
            "/api/quotations/",
            {"job": first_job, "items": self.items},
            format="json",
        )
        self.client.post(
            "/api/quotations/",
            {"job": second_job, "items": self.items},
            format="json",
        )
        response = self.client.get(f"/api/quotations/?job={first_job}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["job"], first_job)

    def test_send_quotation(self):
        job_id = self._create_job()
        created = self.client.post(
            "/api/quotations/",
            {"job": job_id, "items": self.items},
            format="json",
        )
        response = self.client.post(f"/api/quotations/{created.data['id']}/send/")
        self.assertEqual(response.status_code, 200)
        self.assertIsNotNone(response.data["sent_at"])

    def test_quotation_invoice_view(self):
        job_id = self._create_job()
        created = self.client.post(
            "/api/quotations/",
            {"job": job_id, "items": self.items, "discount": "0", "tax_rate": "0"},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        job = Job.objects.get(pk=job_id)
        response = self.client.get(f"/api/quotations/{created.data['id']}/invoice/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["invoice_number"], job.invoice_number)
        self.assertEqual(response.data["customer"]["name"], "أحمد علي")
        self.assertEqual(len(response.data["items"]), 2)
        self.assertEqual(str(response.data["total"]), "200.00")
        self.assertEqual(response.data["company"]["name"], settings.COMPANY_NAME)
        self.assertEqual(
            response.data["company"]["tax_number"], settings.COMPANY_TAX_NUMBER
        )


class WhatsAppNumberTests(SimpleTestCase):
    def test_local_jordan_number(self):
        self.assertEqual(to_international("0791111111"), "+962791111111")
        self.assertEqual(wa_me_number("0791111111"), "962791111111")

    def test_plus_number_unchanged(self):
        self.assertEqual(to_international("+962791111111"), "+962791111111")


class ProfileAndAttachmentApiTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()
        self.user = user_model.objects.create_user(
            username="emp",
            password="pass12345",
            email="emp@datarecovery.io",
        )
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")

    def test_login_includes_profile(self):
        self.client.credentials()
        response = self.client.post(
            "/api/auth/login/",
            {"username": "emp", "password": "pass12345"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["email"], "emp@datarecovery.io")
        self.assertEqual(response.data["role"], "IT Employee")
        self.assertIn("phone", response.data)

    def test_me_get_and_patch(self):
        response = self.client.get("/api/auth/me/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["username"], "emp")
        patched = self.client.patch(
            "/api/auth/me/",
            {"phone": "0790000000", "role": "Technician"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.data["phone"], "0790000000")
        self.assertEqual(patched.data["role"], "Technician")

    def test_upload_job_attachment(self):
        created = self.client.post(
            "/api/jobs/",
            {
                "customer_name": "أحمد علي",
                "customer_phone": "0791234567",
                "hard_disk_type": "hdd_25",
            },
            format="json",
        )
        job_id = created.data["id"]
        upload = SimpleUploadedFile("note.txt", b"hello", content_type="text/plain")
        response = self.client.post(
            f"/api/jobs/{job_id}/attachments/",
            {"file": upload},
            format="multipart",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data[0]["original_name"], "note.txt")
        listed = self.client.get(f"/api/jobs/{job_id}/")
        self.assertEqual(len(listed.data["attachments"]), 1)

    @patch("jobs.views.send_whatsapp_message")
    def test_send_invoice_uses_custom_message(self, mock_send):
        mock_send.return_value = {
            "sent": False,
            "provider": "none",
            "detail": "WhatsApp API not configured yet - manual send required",
        }
        created = self.client.post(
            "/api/jobs/",
            {
                "customer_name": "أحمد علي",
                "customer_phone": "0791234567",
                "hard_disk_type": "hdd_25",
            },
            format="json",
        )
        response = self.client.post(
            f"/api/jobs/{created.data['id']}/send/",
            {"message": "hello custom"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        mock_send.assert_called_once()
        sent_job = mock_send.call_args[0][0]
        self.assertEqual(sent_job.pk, created.data["id"])
        self.assertEqual(sent_job.customer_phone, "0791234567")
