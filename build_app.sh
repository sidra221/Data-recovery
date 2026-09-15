#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/data_recovery_app"
NGROK_URL_FILE="$ROOT_DIR/.ngrok_url"
LOCAL_API_URL="http://127.0.0.1:8000/api/"
SERVER_API_URL="https://api.datarecovery-sa.com/api/"

cd "$ROOT_DIR"

echo "Build the 01 Data Recovery Flutter app"
echo "--------------------------------------"
echo
echo "Which API should this build use?"
echo "  1) localhost   (http://127.0.0.1:8000/api/)"
echo "  2) ngrok       (public HTTPS URL for external testers)"
echo "  3) server      (${SERVER_API_URL})"
echo

API_CHOICE=""
while [[ -z "${API_CHOICE}" ]]; do
  read -r -p "Enter 1, 2, or 3: " REPLY
  case "${REPLY}" in
    1)
      API_CHOICE="localhost"
      ;;
    2)
      API_CHOICE="ngrok"
      ;;
    3)
      API_CHOICE="server"
      ;;
    *)
      echo "Please enter 1, 2, or 3."
      ;;
  esac
done

normalize_api_url() {
  local url="$1"
  url="${url%"${url##*[![:space:]]}"}"
  url="${url#"${url%%[![:space:]]*}"}"
  url="${url%/}"
  if [[ "${url}" != */api ]]; then
    url="${url}/api"
  fi
  printf '%s/\n' "${url}"
}

fetch_ngrok_https_url() {
  python3 - <<'PY'
import json
import urllib.request

try:
    with urllib.request.urlopen("http://127.0.0.1:4040/api/tunnels", timeout=2) as response:
        data = json.load(response)
except Exception:
    raise SystemExit(1)

for tunnel in data.get("tunnels", []):
    url = tunnel.get("public_url") or ""
    if url.startswith("https://"):
        print(url)
        raise SystemExit(0)

raise SystemExit(1)
PY
}

if [[ "${API_CHOICE}" == "localhost" ]]; then
  API_BASE_URL="${LOCAL_API_URL}"
  echo
  echo "Using localhost API: ${API_BASE_URL}"
  echo "Note: this only works on this machine or an Android emulator."
elif [[ "${API_CHOICE}" == "server" ]]; then
  API_BASE_URL="${SERVER_API_URL}"
  echo
  echo "Using production server API: ${API_BASE_URL}"
  echo "Note: this is plain HTTP - traffic is not encrypted."
else
  NGROK_HTTPS="$(fetch_ngrok_https_url 2>/dev/null || true)"
  if [[ -z "${NGROK_HTTPS}" && -f "${ROOT_DIR}/.env" ]]; then
    NGROK_HTTPS="$(python3 - <<'PY'
from pathlib import Path
values = {}
path = Path(".env")
if path.exists():
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        values[key.strip()] = value.strip()
print(values.get("NGROK_PUBLIC_URL", "").strip())
PY
)"
  fi
  if [[ -z "${NGROK_HTTPS}" && -f "${NGROK_URL_FILE}" ]]; then
    NGROK_HTTPS="$(tr -d '[:space:]' < "${NGROK_URL_FILE}")"
  fi
  if [[ -z "${NGROK_HTTPS}" ]]; then
    echo
    echo "No running ngrok tunnel was found."
    echo "Start one in another terminal with: ./start_ngrok.sh"
    read -r -p "Or paste the ngrok HTTPS URL now: " NGROK_HTTPS
  fi
  if [[ -z "${NGROK_HTTPS}" ]]; then
    echo "No ngrok URL provided. Aborting."
    exit 1
  fi
  if [[ "${NGROK_HTTPS}" != https://* ]]; then
    echo "The ngrok URL must start with https://"
    exit 1
  fi
  API_BASE_URL="$(normalize_api_url "${NGROK_HTTPS}")"
  echo
  echo "Using ngrok API: ${API_BASE_URL}"
fi

echo
echo "What do you want to build?"
echo "  1) Android APK"
echo "  2) Web"
echo "  3) Both"
echo

BUILD_TARGET=""
while [[ -z "${BUILD_TARGET}" ]]; do
  read -r -p "Enter 1, 2, or 3: " REPLY
  case "${REPLY}" in
    1)
      BUILD_TARGET="apk"
      ;;
    2)
      BUILD_TARGET="web"
      ;;
    3)
      BUILD_TARGET="both"
      ;;
    *)
      echo "Please enter 1, 2, or 3."
      ;;
  esac
done

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not installed or not in PATH."
  exit 1
fi

cd "$APP_DIR"
DART_DEFINE="API_BASE_URL=${API_BASE_URL}"
# بصمة البناء: أول ٧ حروف من الكوميت + وقت البناء. بتظهر بشاشة الدخول
# حتى يكون واضح أي نسخة مثبّتة على الجهاز بدون تخمين.
GIT_SHA="$(git -C "${ROOT_DIR}" rev-parse --short=7 HEAD 2>/dev/null || echo nogit)"
if [ -n "$(git -C "${ROOT_DIR}" status --porcelain 2>/dev/null)" ]; then
  GIT_SHA="${GIT_SHA}+"
fi
BUILD_DEFINE="BUILD_ID=${GIT_SHA} $(date '+%m-%d %H:%M')"

build_apk() {
  echo
  echo "Building Android APK..."
  flutter build apk --release --dart-define="${DART_DEFINE}" --dart-define="${BUILD_DEFINE}"
  echo
  echo "APK: ${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
}

build_web() {
  echo
  echo "Building web..."
  flutter build web --release --dart-define="${DART_DEFINE}" --dart-define="${BUILD_DEFINE}"
  echo
  echo "Web build: ${APP_DIR}/build/web"
}

case "${BUILD_TARGET}" in
  apk)
    build_apk
    ;;
  web)
    build_web
    ;;
  both)
    build_apk
    build_web
    ;;
esac

echo
echo "Build finished."
echo "API used: ${API_BASE_URL}"
