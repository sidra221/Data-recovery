from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent


def _load_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        os.environ[key] = value


_load_dotenv(BASE_DIR / ".env")

try:
    from .ngrok_runtime import NGROK_HOST, NGROK_PUBLIC_URL
except ImportError:
    NGROK_HOST = os.environ.get("NGROK_HOST", "").strip()
    NGROK_PUBLIC_URL = os.environ.get("NGROK_PUBLIC_URL", "").strip()

# بالإنتاج لازم يتحدد DJANGO_SECRET_KEY كمتغير بيئة حقيقي.
# لا تعتمدوا على القيمة الافتراضية "django-insecure-..." بره بيئة التطوير.
SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY",
    "django-insecure-dev-only-change-me",
)

DEBUG = os.environ.get("DJANGO_DEBUG", "1") == "1"

ALLOWED_HOSTS = [
    host.strip()
    for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if host.strip()
]

CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get(
        "DJANGO_CSRF_TRUSTED_ORIGINS",
        "http://localhost:8000,http://127.0.0.1:8000",
    ).split(",")
    if origin.strip()
]

# ngrok tunnels used when sharing the backend with external testers
if DEBUG:
    ALLOWED_HOSTS.extend(
        [
            ".ngrok-free.app",
            ".ngrok-free.dev",
            ".ngrok.app",
            ".ngrok.io",
        ]
    )
    CSRF_TRUSTED_ORIGINS.extend(
        [
            "https://*.ngrok-free.app",
            "https://*.ngrok-free.dev",
            "https://*.ngrok.app",
            "https://*.ngrok.io",
        ]
    )

# nginx بينهي الـ TLS وبيمرّر الطلب لجانغو على http. بدون هالسطرين جانغو
# بيضل يفكر إنه الطلب cleartext، فبيبني روابط الميديا (صورة الموظف،
# المرفقات) بـ http:// وهي الصفحة https — المتصفح بيحجبها كـ mixed content.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True

if NGROK_HOST and NGROK_HOST not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(NGROK_HOST)
if NGROK_PUBLIC_URL:
    origin = NGROK_PUBLIC_URL.rstrip("/")
    if origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(origin)

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    "jobs",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# بالإنتاج منستعمل PostgreSQL. إذا POSTGRES_DB مش محدد، منرجع لـ SQLite
# حتى التطوير المحلي والاختبارات يضلوا يشتغلوا بدون أي إعداد إضافي.
POSTGRES_DB = os.environ.get("POSTGRES_DB", "").strip()

if POSTGRES_DB:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": POSTGRES_DB,
            "USER": os.environ.get("POSTGRES_USER", ""),
            "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
            "HOST": os.environ.get("POSTGRES_HOST", "127.0.0.1"),
            "PORT": os.environ.get("POSTGRES_PORT", "5432"),
            "CONN_MAX_AGE": int(os.environ.get("POSTGRES_CONN_MAX_AGE", "60")),
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "ar"
TIME_ZONE = "Asia/Amman"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
# لازم لـ collectstatic بالإنتاج — nginx بيخدم الملفات من هون مباشرة.
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CORS_ALLOW_ALL_ORIGINS = DEBUG

# بالإنتاج CORS مقفول. لتشغيل `flutter run -d chrome` على السيرفر لازم
# نسمح لمصدر التطوير بالتحديد — مثال: http://localhost:5000
# التطبيقات الأصلية (APK) ما بتتأثر بهاد، المتصفح بس.
CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get("DJANGO_CORS_ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

# الاسم بيضل إنكليزي عن قصد: الترجمة العربية ("مكتب من الصفر إلى الواحد
# لاسترجاع الملفات") طويلة وغير مستعملة، والعلامة معروفة بالإنكليزي.
COMPANY_NAME = os.environ.get("COMPANY_NAME", "01 Data Recovery")
COMPANY_TAX_NUMBER = os.environ.get("COMPANY_TAX_NUMBER", "312738260800003")
COMPANY_CR_NUMBER = os.environ.get("COMPANY_CR_NUMBER", "7043150239")
COMPANY_ADDRESS = os.environ.get(
    "COMPANY_ADDRESS", "الرياض، وادي الشعراء، حي الشعراء العليا 12211"
)
INVOICE_PREFIX = "01"

LIGHTOTP_API_KEY = os.environ.get("LIGHTOTP_API_KEY", "")
LIGHTOTP_TEMPLATE_ID = os.environ.get("LIGHTOTP_TEMPLATE_ID", "")

MAILERS = {
    "default": {
        "BACKEND": "django.core.mail.backends.console.EmailBackend",
    },
}
