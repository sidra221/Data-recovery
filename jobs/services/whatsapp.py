import requests
from django.conf import settings


def send_whatsapp_message(phone_number: str, message: str) -> dict:
    url = getattr(settings, "WHATSAPP_API_URL", "") or ""
    token = getattr(settings, "WHATSAPP_API_TOKEN", "") or ""
    if not url or not token:
        return {
            "sent": False,
            "provider": "none",
            "detail": "WhatsApp API not configured yet - manual send required",
        }
    try:
        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            json={"to": phone_number, "message": message},
            timeout=10,
        )
        response.raise_for_status()
        return {
            "sent": True,
            "provider": "whatsapp",
            "detail": "Message accepted by provider",
        }
    except requests.RequestException as exc:
        return {
            "sent": False,
            "provider": "whatsapp",
            "detail": str(exc),
        }
