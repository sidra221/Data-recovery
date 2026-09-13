import uuid

import requests
from django.conf import settings


def to_international(phone_number: str) -> str:
    raw = "".join((phone_number or "").split())
    if raw.lower().startswith("whatsapp:"):
        raw = raw.split(":", 1)[1]
    if raw.startswith("00"):
        raw = "+" + raw[2:]
    if raw.startswith("+"):
        digits = "".join(ch for ch in raw[1:] if ch.isdigit())
        return f"+{digits}" if digits else raw
    digits = "".join(ch for ch in raw if ch.isdigit())
    if digits.startswith("07") and len(digits) == 10:
        return f"+962{digits[1:]}"
    if digits.startswith("962"):
        return f"+{digits}"
    if digits:
        return f"+{digits}"
    return raw


def wa_me_number(phone_number: str) -> str:
    return "".join(ch for ch in to_international(phone_number) if ch.isdigit())


def send_whatsapp_message(job) -> dict:
    api_key = getattr(settings, "LIGHTOTP_API_KEY", "") or ""
    template_id = getattr(settings, "LIGHTOTP_TEMPLATE_ID", "") or ""
    if not api_key or not template_id:
        return {
            "sent": False,
            "provider": "none",
            "detail": "WhatsApp API not configured yet - manual send required",
        }

    body = {
        "templateId": settings.LIGHTOTP_TEMPLATE_ID,
        "toPhoneE164": to_international(job.customer_phone),
        "bodyParameters": [
            job.customer_name,
            job.device_model or job.get_hard_disk_type_display(),
            job.invoice_number,
        ],
        "idempotencyKey": str(uuid.uuid4()),
    }
    try:
        response = requests.post(
            "https://api.lightotp.com/SendUtilityMessage",
            headers={
                "X-Api-Key": settings.LIGHTOTP_API_KEY,
                "Content-Type": "application/json",
            },
            json=body,
            timeout=10,
        )
        if response.status_code == 200:
            data = {}
            try:
                data = response.json()
            except ValueError:
                data = {}
            return {
                "sent": True,
                "provider": "lightotp",
                "detail": data.get("messageStatus", "Sent"),
                "id": data.get("id"),
            }

        error_message = f"HTTP {response.status_code}"
        try:
            parsed = response.json().get("errorMessage")
            if parsed:
                error_message = parsed
        except ValueError:
            pass
        return {
            "sent": False,
            "provider": "lightotp",
            "detail": error_message,
        }
    except requests.RequestException as exc:
        return {
            "sent": False,
            "provider": "lightotp",
            "detail": str(exc),
        }
