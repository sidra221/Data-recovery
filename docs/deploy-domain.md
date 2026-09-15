# ربط `api.datarecovery-sa.com` بالسيرفر

الهدف: التطبيق يشتغل على دومين ثابت بـ HTTPS، بدون ما تنتهي صلاحيته ولا يتغيّر
زي روابط ngrok.

---

## الوضع وقت كتابة هالملف

| الفحص | النتيجة |
| --- | --- |
| `api.datarecovery-sa.com` → `2.24.131.249` | ✅ سجلّ الـ DNS موجود |
| `http://2.24.131.249/api/health/` | ✅ 200 — nginx 1.24 + Django شغّالين |
| `http://api.datarecovery-sa.com/api/health/` | ❌ 400 `DisallowedHost` |
| `https://api.datarecovery-sa.com/` | ❌ timeout — 443 مفتوح بس بدون TLS |

يعني الدومين واصل للسيرفر تمام. الناقص شغلتين: جانغو يقبل الاسم، و TLS ينزبط.

---

## 1) خلّي جانغو يقبل الدومين

على السيرفر، لاقي ملف `.env` تبع المشروع:

```bash
sudo find / -name '.env' -path '*01*' 2>/dev/null
```

عدّل السطرين:

```bash
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,api.datarecovery-sa.com
DJANGO_CSRF_TRUSTED_ORIGINS=https://api.datarecovery-sa.com
```

وتأكّد إن `DJANGO_DEBUG=0` بالإنتاج.

بعدها رجّع تشغيل جانغو (حسب كيف مشغّله — غالباً gunicorn):

```bash
sudo systemctl restart gunicorn && sudo systemctl status gunicorn --no-pager
```

اختبار سريع — لازم يرجع 200 مو 400:

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://api.datarecovery-sa.com/api/health/
```

---

## 2) شهادة HTTPS مع تجديد تلقائي

أول شي شوف شو عم يسمع على 443 (هلق في شي مفتوح وما بيردّ):

```bash
sudo ss -tlnp | grep ':443'
```

ثبّت certbot إذا مش موجود:

```bash
sudo apt update && sudo apt install -y certbot python3-certbot-nginx
```

تأكّد إن الدومين مكتوب بـ `server_name` بملف nginx:

```bash
sudo grep -rn 'server_name' /etc/nginx/sites-enabled/
```

إذا مش موجود، ضيفه على الـ `server` block تبع المشروع:

```nginx
server_name api.datarecovery-sa.com 2.24.131.249;
```

بعدها خلّي certbot يزبّط كل شي لحاله (بيضيف بلوك 443 وبيعمل تحويل من 80):

```bash
sudo certbot --nginx -d api.datarecovery-sa.com
```

**التجديد التلقائي** — هون الجواب على «ما ينتهي صلاحيته». شهادات Let's Encrypt
عمرها 90 يوم، و certbot بيثبّت مؤقّت systemd بيجدّدها لحاله. تأكّد إنه شغّال:

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

إذا الـ dry-run نجح، الشهادة رح تتجدّد لحالها للأبد وما بدّها تدخّل منك.

---

## 3) شغلتين لازم تتأكد منهم بملف nginx

بعد ما certbot يخلّص، افتح ملف الـ nginx وتأكّد من هدول جوّا بلوك الـ 443:

```nginx
# بدون هاد، جانغو بيبني روابط الميديا بـ http:// والصفحة https،
# فالمتصفح بيحجب صور الموظف والمرفقات كـ mixed content.
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Host              $host;
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;

# الافتراضي بـ nginx هو 1 ميغا. التطبيق بيسمح برفع مرفقات لحد 10 ميغا،
# فبدونها أي ملف أكبر من ميغا بيرجع 413.
client_max_body_size 25M;
```

بعد أي تعديل:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 4) التأكيد النهائي

```bash
curl -s -o /dev/null -w 'HTTP %{http_code}  ssl=%{ssl_verify_result}\n' \
  https://api.datarecovery-sa.com/api/health/
```

المطلوب: `HTTP 200  ssl=0`.

وكمان تأكّد إن HTTP بيحوّل على HTTPS:

```bash
curl -s -o /dev/null -w '%{http_code} -> %{redirect_url}\n' \
  http://api.datarecovery-sa.com/api/health/
```

---

## 5) إذا الـ IP تبع السيرفر متغيّر (DDNS)

إذا `2.24.131.249` هو VPS، الـ IP ثابت وما بدك شي زيادة.

بس إذا السيرفر على خط إنترنت بيتغيّر IP-ه (بيت أو مكتب)، سجلّ الـ DNS بيبوظ أول
ما يتغيّر الـ IP. بهالحالة بدك محدّث DDNS يشتغل على السيرفر ويحدّث السجلّ لحاله.
الدومين على Hostinger (`ns1.dns-parking.com`)، فالخيارين:

- محدّث عبر API تبع Hostinger — cron كل 5 دقايق بيقارن الـ IP الحالي بالسجلّ.
- أو تنقل الـ DNS لمزوّد فيه DDNS جاهز (Cloudflare مثلاً) وتستعمل `ddclient`.

خبّرني أي وحدة بتناسبك وبكتبلك السكربت.

---

## الجهة التطبيق

انتهت من هون — انعدّلت بالريبو:

- `data_recovery_app/lib/core/api_config.dart` → `https://api.datarecovery-sa.com/api/`
- `build_app.sh` → خيار «server» صار على الدومين
- `config/settings.py` → `SECURE_PROXY_SSL_HEADER` و `USE_X_FORWARDED_HOST`
- `.env.example` → الدومين بـ `ALLOWED_HOSTS` و `CSRF_TRUSTED_ORIGINS`

بعد ما تخلص خطوات السيرفر، ابنِ نسخة جديدة:

```bash
./build_app.sh   # واختر 3) server
```

**ملاحظة:** `start_ngrok.sh` لسا بيدعس على `api_config.dart` لما تشغّله. إذا ما
عاد بدك ngrok خالص، فينا نشيله.
