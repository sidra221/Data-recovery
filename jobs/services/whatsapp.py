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

    to_number = f"whatsapp:{to_international(phone_number)}"

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
