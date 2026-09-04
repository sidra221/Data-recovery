from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Job


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
            "barcode": "HD-1001",
            "notes": "هارد ما بقلع",
        }

    def test_create_job_from_barcode(self):
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["customer_name"], "أحمد علي")
        self.assertEqual(response.data["barcode"], "HD-1001")
        self.assertEqual(response.data["status"], "received")
        self.assertTrue(response.data["invoice_number"].startswith("01-"))
        self.assertEqual(len(response.data["status_logs"]), 1)

    def test_scan_barcode(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        response = self.client.get("/api/jobs/scan/HD-1001/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["customer_phone"], "0791234567")

    def test_duplicate_barcode_rejected(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        response = self.client.post("/api/jobs/", self.payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("barcode", response.data)

    def test_update_followup_status(self):
        created = self.client.post("/api/jobs/", self.payload, format="json")
        job_id = created.data["id"]
        response = self.client.post(
            f"/api/jobs/{job_id}/status/",
            {"status": "finished", "note": "تم الإصلاح"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], "finished")
        self.assertEqual(response.data["status_label"], "فنش")
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
        self.assertEqual(response.data["client_report_label"], "موافق على السعر")
        self.assertEqual(response.data["status"], "received")

        response = self.client.patch(
            f"/api/jobs/{job_id}/",
            {"work_status": "in_progress"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["work_status"], "in_progress")
        self.assertEqual(response.data["work_status_label"], "قيد التنفيذ / البحث عن قطع")
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
        self.assertEqual(response.data["report_flag_label"], "لا يوجد قطع غيار")
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

    def test_filter_by_status(self):
        self.client.post("/api/jobs/", self.payload, format="json")
        other = dict(self.payload, barcode="HD-2002")
        created = self.client.post("/api/jobs/", other, format="json")
        self.client.post(
            f"/api/jobs/{created.data['id']}/status/",
            {"status": "has_problems"},
            format="json",
        )
        response = self.client.get("/api/jobs/?status=has_problems")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["barcode"], "HD-2002")

    def test_search_by_new_fields(self):
        self.client.post(
            "/api/jobs/",
            dict(self.payload, barcode="HD-1001", device_model="Western Digital"),
            format="json",
        )
        self.client.post(
            "/api/jobs/",
            dict(self.payload, barcode="HD-2002", device_model="Toshiba"),
            format="json",
        )
        response = self.client.get("/api/jobs/?search=Western")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["barcode"], "HD-1001")
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
        self.assertEqual(status_values, {"received", "finished", "completed", "has_problems"})
        self.assertTrue(Job.objects.count() == 0)
