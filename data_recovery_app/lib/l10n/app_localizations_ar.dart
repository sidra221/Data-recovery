// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'استعادة البيانات';

  @override
  String get welcomeBack => 'أهلاً بعودتك';

  @override
  String get loginSubtitle => 'ادخل على لوحتك وتابع قضايا استعادة البيانات';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة السر';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCases => 'القضايا';

  @override
  String get navCustomer => 'العملاء';

  @override
  String get navSetting => 'الإعدادات';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get clear => 'تصفير';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get send => 'إرسال';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get update => 'تحديث';

  @override
  String get ok => 'موافق';

  @override
  String get search => 'بحث';

  @override
  String get loadMore => 'عرض المزيد';

  @override
  String get notSet => 'غير محدّد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get reports => 'التقارير';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get typeHdd35 => 'هارد 3.5';

  @override
  String get typeHdd25 => 'هارد 2.5';

  @override
  String get typeSsd => 'SSD';

  @override
  String get typeNvme => 'NVMe';

  @override
  String get typeExternal => 'هارد خارجي';

  @override
  String get typeUsb => 'فلاش USB';

  @override
  String get typeMemoryCard => 'كرت ذاكرة';

  @override
  String get typeOther => 'أخرى';

  @override
  String get statusReceived => 'تم الاستلام';

  @override
  String get statusCompleted => 'مكتملة';

  @override
  String get statusHasProblems => 'فيها مشاكل';

  @override
  String get workPending => 'قيد الانتظار';

  @override
  String get workInProgress => 'قيد التنفيذ';

  @override
  String get workDone => 'انتهى الإصلاح';

  @override
  String get clientAgree => 'موافق على السعر';

  @override
  String get clientWaitClient => 'بانتظار رد العميل';

  @override
  String get clientReady => 'جاهز للاستلام';

  @override
  String get clientRejected => 'مرفوض من العميل';

  @override
  String get flagNone => 'بدون';

  @override
  String get flagNoSpareParts => 'لا يوجد قطع غيار';

  @override
  String get flagSendToChina => 'يُرسل للصين';

  @override
  String get recoveryProgress => 'سير الاستعادة';

  @override
  String get readyForReturn => 'جاهز للاستلام';

  @override
  String get finishedReadyToCollect => 'انتهى / جاهز للاستلام';

  @override
  String get viewCases => 'عرض القضايا';

  @override
  String casesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قضية',
      two: 'قضيتان',
      one: 'قضية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get todaysActivity => 'نشاط اليوم';

  @override
  String get newCases => 'قضايا جديدة';

  @override
  String get updates => 'تحديثات';

  @override
  String agreeChip(int count) {
    return 'موافق $count';
  }

  @override
  String get filterAll => 'الكل';

  @override
  String get filterInspection => 'فحص';

  @override
  String get noRepairs => 'لا يوجد إصلاحات';

  @override
  String get noRepairsHint => 'ما عندك إصلاحات حالياً';

  @override
  String get barcodeNotFound => 'الباركود غير موجود';

  @override
  String get caseTitle => 'قضية';

  @override
  String get sectionCustomer => 'العميل';

  @override
  String get sectionDevice => 'الجهاز';

  @override
  String get sectionBilling => 'الفاتورة';

  @override
  String get sectionAttachments => 'المرفقات';

  @override
  String get sectionHistory => 'السجل';

  @override
  String get labelName => 'الاسم';

  @override
  String get labelPhone => 'الهاتف';

  @override
  String get labelEmail => 'الإيميل';

  @override
  String get labelType => 'النوع';

  @override
  String get labelModel => 'الموديل';

  @override
  String get labelSerial => 'السيريال';

  @override
  String get labelAttached => 'الملحقات';

  @override
  String get labelProblem => 'المشكلة';

  @override
  String get labelInspection => 'الفحص';

  @override
  String get labelNotes => 'ملاحظات';

  @override
  String get labelInvoice => 'الفاتورة';

  @override
  String get labelBarcode => 'الباركود';

  @override
  String get labelPrice => 'السعر';

  @override
  String get labelInvoiceSent => 'أُرسلت الفاتورة';

  @override
  String get labelDelivered => 'التسليم';

  @override
  String get labelStatus => 'الحالة';

  @override
  String get labelWork => 'الشغل';

  @override
  String get labelClient => 'العميل';

  @override
  String get overdue => 'متأخرة';

  @override
  String get noAttachments => 'لا يوجد مرفقات';

  @override
  String get noChangesYet => 'لا يوجد تغييرات بعد';

  @override
  String get failedToLoadCase => 'تعذّر تحميل القضية';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get notifyCustomer => 'إشعار العميل';

  @override
  String get quotationInvoice => 'عرض السعر / الفاتورة';

  @override
  String get createNewCase => 'إنشاء قضية جديدة';

  @override
  String get addCase => 'إضافة القضية';

  @override
  String get customerInformation => 'معلومات العميل';

  @override
  String get deviceDetails => 'تفاصيل الجهاز';

  @override
  String get mediaAndDocument => 'الصور والمستندات';

  @override
  String get statusSection => 'الحالة';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterFullName => 'اكتب الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get emailAddress => 'الإيميل';

  @override
  String get deviceType => 'نوع الجهاز';

  @override
  String get serialNumber => 'الرقم التسلسلي';

  @override
  String get scanSerial => 'مسح السيريال';

  @override
  String get recoveryDetails => 'تفاصيل الاستعادة';

  @override
  String get whatCustomerReported => 'شو اشتكى منه العميل';

  @override
  String get currentStatus => 'الحالة الحالية';

  @override
  String get addPhotosDocuments => 'إضافة صور أو مستندات';

  @override
  String get uploadHint => 'JPG أو PNG أو PDF بحد أقصى 10 ميجا';

  @override
  String get takePhoto => 'تصوير بالكاميرا';

  @override
  String get chooseFromGallery => 'اختيار من الاستديو';

  @override
  String get chooseFile => 'اختيار ملف (PDF أو صورة)';

  @override
  String get caseCreated => 'تم إنشاء القضية';

  @override
  String get failedToCreateCase => 'تعذّر إنشاء القضية';

  @override
  String get customerDetails => 'تفاصيل العميل';

  @override
  String get customerState => 'حالة العميل';

  @override
  String get devices => 'الأجهزة';

  @override
  String get totalRepairs => 'عدد الإصلاحات';

  @override
  String get totalSpent => 'إجمالي المدفوع';

  @override
  String get firstVisit => 'أول زيارة';

  @override
  String get lastVisit => 'آخر زيارة';

  @override
  String get noDevicesYet => 'ما في أجهزة لهذا العميل بعد';

  @override
  String get deleteCustomer => 'حذف العميل';

  @override
  String get deleteCustomerConfirm => 'متأكد إنك بدك تحذف هذا العميل؟';

  @override
  String get updatedSuccessfully => 'تم التحديث';

  @override
  String get failedToUpdate => 'تعذّر التحديث';

  @override
  String get failedToLoadCustomer => 'تعذّر تحميل بيانات العميل';

  @override
  String get failedToDeleteCustomer => 'تعذّر حذف العميل';

  @override
  String get customersList => 'قائمة العملاء';

  @override
  String get searchCustomersHint => 'ابحث بالاسم أو الإيميل أو الهاتف';

  @override
  String get noCustomersFound => 'ما في عملاء';

  @override
  String get lastDash => 'الأخيرة: -';

  @override
  String get searchReportsHint => 'سيريال أو هاتف أو اسم أو رقم فاتورة';

  @override
  String get searchReportsEmptyHint =>
      'ابحث بالسيريال أو الهاتف أو الاسم أو رقم الفاتورة — أو بنطاق تاريخ';

  @override
  String get searchNeedsCriteria =>
      'اكتب سيريال أو هاتف أو اسم أو رقم فاتورة — أو اختر نطاق تاريخ';

  @override
  String get noCasesMatch => 'ما في قضايا تطابق هذا البحث';

  @override
  String get searchFailed => 'تعذّر البحث';

  @override
  String get dateFrom => 'من';

  @override
  String get dateTo => 'إلى';

  @override
  String get dateAny => 'الكل';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
    );
    return '$_temp0';
  }

  @override
  String showingOf(int shown, int total) {
    return 'معروض $shown من $total — ضيّق البحث أكثر';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get sectionAccount => 'الحساب';

  @override
  String get sectionSupport => 'الدعم';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get logOutConfirm => 'متأكد إنك بدك تسجّل خروج؟';

  @override
  String get employee => 'موظف';

  @override
  String get itEmployee => 'موظف تقني';

  @override
  String get roleDepartment => 'الوظيفة / القسم';

  @override
  String get phoneNumberCaps => 'رقم الهاتف';

  @override
  String get emailAddressCaps => 'الإيميل';

  @override
  String get photoUpdated => 'تم تحديث الصورة';

  @override
  String get failedToUploadPhoto => 'تعذّر رفع الصورة';

  @override
  String get howCanWeHelp => 'كيف نقدر نساعدك؟';

  @override
  String get emailUs => 'راسلنا بالإيميل';

  @override
  String get couldNotOpenEmail => 'تعذّر فتح تطبيق الإيميل';

  @override
  String get supportRequest => 'طلب دعم من مركز المساعدة';

  @override
  String get noOverdueCases => 'ما في قضايا متأخرة بانتظار العميل';

  @override
  String get failedToLoadAlerts => 'تعذّر تحميل التنبيهات';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get enterCode => 'اكتب الرمز';

  @override
  String get financialOffer => 'عرض السعر';

  @override
  String get quotation => 'عرض السعر';

  @override
  String get addItem => 'إضافة بند';

  @override
  String get item => 'بند';

  @override
  String get description => 'الوصف';

  @override
  String get qty => 'الكمية';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get total => 'الإجمالي';

  @override
  String get subtotal => 'المجموع';

  @override
  String get discount => 'الخصم';

  @override
  String get taxRate => 'نسبة الضريبة %';

  @override
  String get tax => 'الضريبة';

  @override
  String get totalExclTax => 'الإجمالي بدون ضريبة';

  @override
  String get totalWithTax => 'الإجمالي مع الضريبة';

  @override
  String get termsAndConditions => 'الشروط والأحكام:';

  @override
  String get pricesInRiyals => 'جميع الأسعار بالريال السعودي.';

  @override
  String get paymentCash => 'الدفع: 100% نقداً';

  @override
  String get addAtLeastOneItem => 'أضف بند واحد على الأقل';

  @override
  String get enterPriceGreaterThanZero => 'اكتب سعر أكبر من صفر';

  @override
  String get failedToSendQuotation => 'تعذّر إرسال عرض السعر';

  @override
  String get personName => 'اسم الشخص';

  @override
  String get mobile => 'الجوال';

  @override
  String get labelDate => 'التاريخ';

  @override
  String get fromColon => 'من:';

  @override
  String get toColon => 'إلى:';

  @override
  String get sellerSignature => 'توقيع البائع';

  @override
  String get receiverSignature => 'توقيع المستلم';

  @override
  String get tapToSign => 'اضغط للتوقيع';

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get share => 'مشاركة';

  @override
  String get saveAndPrint => 'حفظ وطباعة';

  @override
  String get price => 'السعر';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get sendPickupNotification => 'إرسال إشعار الاستلام';

  @override
  String get sentAutomatically => 'بينبعت تلقائياً من السيرفر';

  @override
  String get notifyDeviceReady => 'إشعار العميل - الجهاز جاهز';

  @override
  String get failedToLoadInvoiceText => 'تعذّر تحميل نص الفاتورة';

  @override
  String get failedToOpenWhatsapp => 'تعذّر فتح واتساب أو تسجيل الإرسال';

  @override
  String get failedToRecordSend => 'تعذّر تسجيل الإرسال';

  @override
  String get whatsappUnavailable => 'رابط واتساب غير متاح';

  @override
  String get workStatusSection => 'حالة الشغل';

  @override
  String get clientDecisionSection => 'قرار العميل';

  @override
  String get handoverSection => 'التسليم';

  @override
  String get waitingToStart => 'بانتظار البدء';

  @override
  String get technicianWorking => 'الفني عم يشتغل على الإصلاح';

  @override
  String get repairFinished => 'الإصلاح انتهى';

  @override
  String get customerAcceptedPrice => 'العميل وافق على السعر';

  @override
  String get waitingCustomerReply => 'بانتظار رد العميل';

  @override
  String get customerRejectedOffer => 'العميل رفض العرض';

  @override
  String get finishedAndReady => 'انتهى وجاهز للاستلام';

  @override
  String get markDelivered => 'تعليم كمُسلَّم';

  @override
  String get alreadyDelivered => 'مُسلَّم مسبقاً';

  @override
  String get customerCollected => 'العميل استلم الجهاز';

  @override
  String get createReportAndInvoice => 'إنشاء تقرير وفاتورة';

  @override
  String get sendReportToCustomer => 'إرسال التقرير للعميل';

  @override
  String get failedToUpdateStatus => 'تعذّر تحديث الحالة';

  @override
  String get filter => 'تصفية';

  @override
  String get dateRange => 'نطاق التاريخ';

  @override
  String get allTime => 'كل الفترات';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get custom => 'مخصّص';

  @override
  String get applyFilter => 'تطبيق التصفية';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get typeManually => 'كتابة';

  @override
  String get popularArticles => 'المقالات الشائعة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get stillNeedHelp => 'ما زلت بحاجة لمساعدة؟';

  @override
  String get supportAvailable247 =>
      'فريق الدعم متاح على مدار الساعة للإجابة على أي استفسار.';

  @override
  String get helpPhotosTitle => 'كيفية استعادة الصور المحذوفة';

  @override
  String get helpPhotosStep1 =>
      'أنشئ قضية جديدة واختر الجهاز الذي كانت الصور مخزّنة عليه.';

  @override
  String get helpPhotosStep2 =>
      'أبقِ القرص موصولاً بالطاقة وتجنّب كتابة ملفات جديدة عليه.';

  @override
  String get helpPhotosStep3 =>
      'انتظر انتهاء الفحص، ثم راجع الملفات المستعادة مع العميل.';

  @override
  String get helpSsdTitle => 'توصيل قرص SSD خارجي';

  @override
  String get helpSsdStep1 => 'أطفئ جهاز العمل قبل توصيل القرص.';

  @override
  String get helpSsdStep2 => 'وصّل الـ SSD بكابل أو قاعدة متوافقة.';

  @override
  String get helpSsdStep3 => 'افتح قضية جديدة واختر SSD كنوع للقرص.';

  @override
  String get helpSsdStep4 => 'ابدأ الفحص وتابع تحديثات حالة القضية.';

  @override
  String get helpBillingTitle => 'أسئلة شائعة عن الاشتراك والفوترة';

  @override
  String get helpBillingStep1 =>
      'أضف السعر المتفق عليه على القضية بعد موافقة العميل على عرض السعر.';

  @override
  String get helpBillingStep2 => 'أرسل الفاتورة للعميل من شاشة تفاصيل القضية.';

  @override
  String get helpBillingStep3 =>
      'علّم العمل كمُسلَّم بعد اكتمال الدفع والتسليم.';

  @override
  String get tel => 'هاتف';

  @override
  String get pricesForQuantity =>
      'الأسعار محسوبة للكمية المذكورة ولا تنطبق عند تغيير الكمية.';

  @override
  String get electronicInvoice => 'فاتورة إلكترونية';

  @override
  String get invoiceIdLabel => 'رقم الفاتورة';

  @override
  String get failedToLoadInvoice => 'تعذّر تحميل الفاتورة';

  @override
  String get invoiceType => 'نوع الفاتورة';

  @override
  String get taxInvoice => 'فاتورة ضريبية';

  @override
  String get invoiceTime => 'وقت الفاتورة';

  @override
  String get customer => 'العميل';

  @override
  String get customerOrCompany => 'العميل / الشركة';

  @override
  String get mainEmployee => 'الموظف المسؤول';

  @override
  String get nationalAddress => 'العنوان الوطني';

  @override
  String get branchName => 'اسم الفرع';

  @override
  String get cash => 'نقداً';

  @override
  String get colNo => 'م';

  @override
  String get colItem => 'الصنف';

  @override
  String get colDescription => 'الوصف';

  @override
  String get colQty => 'الكمية';

  @override
  String get colPrice => 'السعر';

  @override
  String get colDisc => 'خصم';

  @override
  String get colTax => 'ضريبة';

  @override
  String get colTotal => 'الإجمالي';

  @override
  String get noItems => 'لا توجد بنود';

  @override
  String get paidOnMainFund => 'مدفوع على (1) الصندوق الرئيسي';

  @override
  String get paidOnTwo => 'مدفوع على (2)';

  @override
  String get paidOnThree => 'مدفوع على (3)';

  @override
  String get offline => 'غير متصل';

  @override
  String showingSavedData(String when) {
    return 'عم نعرض بيانات محفوظة $when';
  }

  @override
  String get justNow => 'هلق';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count دقائق',
      one: 'من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count ساعات',
      one: 'من ساعة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count أيام',
      one: 'من يوم',
    );
    return '$_temp0';
  }

  @override
  String get failedToLoadStats => 'تعذّر تحميل الإحصائيات';

  @override
  String get serverUnreachable => 'ما قدرنا نوصل للسيرفر';

  @override
  String get noSavedData => 'ما في بيانات محفوظة للعرض';

  @override
  String get searchHelpHint => 'ابحث بالمقالات';

  @override
  String get noArticlesMatch => 'ما في مقالات بتطابق البحث';

  @override
  String get savedOfflineWillSync =>
      'انحفظت على الجهاز. رح تنبعت أول ما يرجع السيرفر.';

  @override
  String get noOfflineNumbersLeft =>
      'خلصت أرقام الفواتير المحجوزة لليوم. لازم توصل بالسيرفر أول.';

  @override
  String get attachmentsNeedServer =>
      'المرفقات ما انرفعت. ضيفها كمان مرة لما يرجع السيرفر.';

  @override
  String pendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعديلات مستنية الرفع',
      one: 'تعديل واحد مستني الرفع',
    );
    return '$_temp0';
  }

  @override
  String rejectedSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعديلات انرفضت',
      one: 'تعديل واحد انرفض',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'ارفع هلق';

  @override
  String syncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انبعتوا $count تعديلات',
      one: 'انبعت تعديل واحد',
    );
    return '$_temp0';
  }

  @override
  String get pendingUpload => 'لسا ما انرفعت';

  @override
  String get printDocuments => 'طباعة المستندات';

  @override
  String get printSticker => 'ستيكر القطعة';

  @override
  String get printStickerHint => 'بينلزق على القطعة المستلمة';

  @override
  String get printReceipt => 'سند الاستلام';

  @override
  String get printReceiptHint => 'بينعطى للعميل';

  @override
  String get printFailed => 'تعذّر فتح نافذة الطباعة';
}
