import requests
from django.conf import settings


def send_whatsapp_message(phone_number: str, message: str) -> dict:
    account_sid = getattr(settings, "TWILIO_ACCOUNT_SID", "") or ""
    auth_token = getattr(settings, "TWILIO_AUTH_TOKEN", "") or ""
    from_number = getattr(settings, "TWILIO_WHATSAPP_FROM", "") or ""
    if not account_sid or not auth_token or not from_number:
        return {
            "sent": False,
            "provider": "none",
            "detail": "WhatsApp API not configured yet - manual send required",
        }

    destination = "".join((phone_number or "").split())
    # TODO: stored customer numbers may not include a country code.
    # If they don't start with +, we may need to prefix the local country code later.
    to_number = f"whatsapp:{destination}"

    url = (
        f"https://api.twilio.com/2010-04-01/Accounts/{account_sid}/Messages.json"
    )
    try:
        response = requests.post(
            url,
            auth=(account_sid, auth_token),
            data={
                "From": from_number,
                "To": to_number,
                "Body": message,
            },
            timeout=10,
        )
        if response.status_code in (200, 201):
            payload = {}
            try:
                payload = response.json()
            except ValueError:
                payload = {}
            return {
                "sent": True,
                "provider": "twilio",
                "detail": "Message queued",
                "sid": payload.get("sid"),
            }

        detail = f"Twilio returned HTTP {response.status_code}"
        try:
            error_message = response.json().get("message")
            if error_message:
                detail = error_message
        except ValueError:
            pass
        return {
            "sent": False,
            "provider": "twilio",
            "detail": detail,
        }
    except requests.RequestException as exc:
        return {
            "sent": False,
            "provider": "whatsapp",
            "detail": str(exc),
        }
