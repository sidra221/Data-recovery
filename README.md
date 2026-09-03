# 01 Data Recovery — Backend

باك إند Django خفيف لفواتير استرجاع البيانات ومتابعة حالة الإصلاح.

## الفكرة

الموظف يمسح باركود الهارد، يدخل اسم العميل ورقم تليفونه ونوع الهارد، والنظام يطلع فاتورة. بعدين يتابع الحالة: **فنش** / **خلص** / **في مشاكل**.

## التشغيل

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py create_employee emp pass12345
python manage.py runserver
```

لوحة الأدمن: http://127.0.0.1:8000/admin/

لإنشاء سوبر يوزر للأدمن:

```bash
python manage.py createsuperuser
```

## حالات المتابعة

| القيمة | المعنى |
| --- | --- |
| `received` | تم الاستلام (تلقائي عند إنشاء الفاتورة) |
| `finished` | فنش |
| `completed` | خلص |
| `has_problems` | في مشاكل |

## أنواع الهارد

`hdd_35` · `hdd_25` · `ssd` · `nvme` · `external` · `usb` · `memory_card` · `other`

## الـ API

كل الطلبات ما عدا الدخول والصحة تحتاج هيدر:

```
Authorization: Token <TOKEN>
```

### دخول الموظف

```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"emp","password":"pass12345"}'
```

### إنشاء فاتورة بعد مسح الباركود

```bash
curl -X POST http://127.0.0.1:8000/api/jobs/ \
  -H "Authorization: Token <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "أحمد علي",
    "customer_phone": "0791234567",
    "hard_disk_type": "hdd_25",
    "barcode": "HD-1001"
  }'
```

### قراءة الباركود (جلب الفاتورة)

```bash
curl http://127.0.0.1:8000/api/jobs/scan/HD-1001/ \
  -H "Authorization: Token <TOKEN>"
```

### تحديث حالة المتابعة

```bash
curl -X POST http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"status":"finished","note":"تم الإصلاح"}'
```

### طلّع الفاتورة / ابعتها للعميل

```bash
curl http://127.0.0.1:8000/api/jobs/1/invoice/ \
  -H "Authorization: Token <TOKEN>"

curl -X POST http://127.0.0.1:8000/api/jobs/1/send/ \
  -H "Authorization: Token <TOKEN>"
```

`send` يعلّم الفاتورة إنها انبعت، وبرجع نص جاهز للمشاركة + رابط واتساب `whatsapp_url`.

### باقي المسارات

- `GET /api/jobs/` قائمة الفواتير
- `GET /api/jobs/?status=has_problems` فلترة بالحالة
- `GET /api/jobs/?search=أحمد` بحث بالاسم أو الرقم أو الباركود
- `GET /api/jobs/1/` تفاصيل فاتورة
- `GET /api/meta/` أنواع الهارد + الحالات
- `GET /api/health/` فحص الخدمة
