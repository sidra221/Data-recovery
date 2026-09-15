// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Data Recovery';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Access your dashboard and manage recovery cases';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get invalidCredentials => 'Invalid login credentials';

  @override
  String get navHome => 'Home';

  @override
  String get navCases => 'Cases';

  @override
  String get navCustomer => 'Customer';

  @override
  String get navSetting => 'Setting';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get send => 'Send';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get update => 'Update';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Search';

  @override
  String get loadMore => 'Load more';

  @override
  String get notSet => 'Not set';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get reports => 'Reports';

  @override
  String get notifications => 'Notifications';

  @override
  String get typeHdd35 => 'HDD 3.5';

  @override
  String get typeHdd25 => 'HDD 2.5';

  @override
  String get typeSsd => 'SSD';

  @override
  String get typeNvme => 'NVMe';

  @override
  String get typeExternal => 'External HDD';

  @override
  String get typeUsb => 'USB Flash';

  @override
  String get typeMemoryCard => 'Memory Card';

  @override
  String get typeOther => 'Other';

  @override
  String get statusReceived => 'Received';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusHasProblems => 'Has problems';

  @override
  String get workPending => 'Pending';

  @override
  String get workInProgress => 'In progress';

  @override
  String get workDone => 'Done';

  @override
  String get clientAgree => 'Agree';

  @override
  String get clientWaitClient => 'Wait client';

  @override
  String get clientReady => 'Ready';

  @override
  String get clientRejected => 'Rejected';

  @override
  String get flagNone => 'None';

  @override
  String get flagNoSpareParts => 'No spare parts';

  @override
  String get flagSendToChina => 'Send to China';

  @override
  String get recoveryProgress => 'Recovery Progress';

  @override
  String get readyForReturn => 'READY FOR RETURN';

  @override
  String get finishedReadyToCollect => 'Finished / ready to collect';

  @override
  String get viewCases => 'View Cases';

  @override
  String casesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Cases',
      one: '1 Case',
    );
    return '$_temp0';
  }

  @override
  String get todaysActivity => 'Today\'s Activity';

  @override
  String get newCases => 'New Cases';

  @override
  String get updates => 'Updates';

  @override
  String agreeChip(int count) {
    return 'Agree $count';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterInspection => 'Inspection';

  @override
  String get noRepairs => 'No Repairs';

  @override
  String get noRepairsHint => 'You have no repairs currently';

  @override
  String get barcodeNotFound => 'Barcode not found';

  @override
  String get caseTitle => 'Case';

  @override
  String get sectionCustomer => 'CUSTOMER';

  @override
  String get sectionDevice => 'DEVICE';

  @override
  String get sectionBilling => 'BILLING';

  @override
  String get sectionAttachments => 'ATTACHMENTS';

  @override
  String get sectionHistory => 'HISTORY';

  @override
  String get labelName => 'Name';

  @override
  String get labelPhone => 'Phone';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelType => 'Type';

  @override
  String get labelModel => 'Model';

  @override
  String get labelSerial => 'Serial';

  @override
  String get labelAttached => 'Attached';

  @override
  String get labelProblem => 'Problem';

  @override
  String get labelInspection => 'Inspection';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelInvoice => 'Invoice';

  @override
  String get labelBarcode => 'Barcode';

  @override
  String get labelPrice => 'Price';

  @override
  String get labelInvoiceSent => 'Invoice sent';

  @override
  String get labelDelivered => 'Delivered';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelWork => 'Work';

  @override
  String get labelClient => 'Client';

  @override
  String get overdue => 'Overdue';

  @override
  String get noAttachments => 'No attachments';

  @override
  String get noChangesYet => 'No changes yet';

  @override
  String get failedToLoadCase => 'Failed to load case';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get notifyCustomer => 'Notify Customer';

  @override
  String get quotationInvoice => 'Quotation / Invoice';

  @override
  String get createNewCase => 'Create New Case';

  @override
  String get addCase => 'Add Case';

  @override
  String get customerInformation => 'CUSTOMER INFORMATION';

  @override
  String get deviceDetails => 'DEVICE DETAILS';

  @override
  String get mediaAndDocument => 'MEDIA & DOCUMENT';

  @override
  String get statusSection => 'STATUS';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get deviceType => 'Device Type';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get scanSerial => 'Scan serial';

  @override
  String get recoveryDetails => 'Recovery Details';

  @override
  String get whatCustomerReported => 'What the customer reported';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get addPhotosDocuments => 'Add Photos/Documents';

  @override
  String get uploadHint => 'Upload JPG, PNG or PDF up to 10MB';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get chooseFile => 'Choose a file (PDF, image)';

  @override
  String get caseCreated => 'Case created successfully';

  @override
  String get failedToCreateCase => 'Failed to create case';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get customerState => 'Customer state';

  @override
  String get devices => 'DEVICES';

  @override
  String get totalRepairs => 'Total Repairs';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get firstVisit => 'First visit';

  @override
  String get lastVisit => 'Last visit';

  @override
  String get noDevicesYet => 'No devices for this customer yet';

  @override
  String get deleteCustomer => 'Delete Customer';

  @override
  String get deleteCustomerConfirm =>
      'Are you sure you want to delete this Customer?';

  @override
  String get updatedSuccessfully => 'Updated successfully';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get failedToLoadCustomer => 'Failed to load customer';

  @override
  String get failedToDeleteCustomer => 'Failed to delete customer';

  @override
  String get customersList => 'Customers List';

  @override
  String get searchCustomersHint => 'Search Name, Email, phone';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get lastDash => 'Last: -';

  @override
  String get searchReportsHint => 'Serial, phone, name or invoice number';

  @override
  String get searchReportsEmptyHint =>
      'Search by serial, phone, name, invoice number — or a date range';

  @override
  String get searchNeedsCriteria =>
      'Enter a serial, phone, name, invoice — or pick a date range';

  @override
  String get noCasesMatch => 'No cases match this search';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get dateFrom => 'From';

  @override
  String get dateTo => 'To';

  @override
  String get dateAny => 'Any';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String showingOf(int shown, int total) {
    return 'Showing $shown of $total — refine the search to narrow it';
  }

  @override
  String get settings => 'Setting';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirm => 'Are you sure you want to log out?';

  @override
  String get employee => 'Employee';

  @override
  String get itEmployee => 'IT Employee';

  @override
  String get roleDepartment => 'ROLE / DEPARTMENT';

  @override
  String get phoneNumberCaps => 'PHONE NUMBER';

  @override
  String get emailAddressCaps => 'EMAIL ADDRESS';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get failedToUploadPhoto => 'Failed to upload photo';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get emailUs => 'Email Us';

  @override
  String get couldNotOpenEmail => 'Could not open email app';

  @override
  String get supportRequest => 'Help Center support request';

  @override
  String get noOverdueCases => 'No overdue wait-client cases';

  @override
  String get failedToLoadAlerts => 'Failed to load alerts';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get enterCode => 'Enter code';

  @override
  String get financialOffer => 'Financial Offer';

  @override
  String get quotation => 'QUOTATION';

  @override
  String get addItem => 'Add Item';

  @override
  String get item => 'Item';

  @override
  String get description => 'DESCRIPTION';

  @override
  String get qty => 'QTY';

  @override
  String get unitPrice => 'UNIT PRICE';

  @override
  String get total => 'TOTAL';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get taxRate => 'Tax Rate %';

  @override
  String get tax => 'Tax';

  @override
  String get totalExclTax => 'Total Excl. Tax';

  @override
  String get totalWithTax => 'Total With Tax';

  @override
  String get termsAndConditions => 'TERMS AND CONDITIONS:';

  @override
  String get pricesInRiyals => 'All prices are in Saudi Riyals.';

  @override
  String get paymentCash => 'Payment: 100% CASH';

  @override
  String get addAtLeastOneItem => 'Add at least one item';

  @override
  String get enterPriceGreaterThanZero => 'Enter a price greater than zero';

  @override
  String get failedToSendQuotation => 'Failed to send quotation';

  @override
  String get personName => 'Person name';

  @override
  String get mobile => 'Mobile';

  @override
  String get labelDate => 'Date';

  @override
  String get fromColon => 'From:';

  @override
  String get toColon => 'To :';

  @override
  String get sellerSignature => 'Seller Signature';

  @override
  String get receiverSignature => 'Receiver Signature';

  @override
  String get tapToSign => 'Tap to sign';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get share => 'Share';

  @override
  String get saveAndPrint => 'Save & Print';

  @override
  String get price => 'Price';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sendPickupNotification => 'Send pickup notification';

  @override
  String get sentAutomatically => 'Sent automatically via server';

  @override
  String get notifyDeviceReady => 'Notify Customer - Device Ready';

  @override
  String get failedToLoadInvoiceText => 'Failed to load invoice text';

  @override
  String get failedToOpenWhatsapp => 'Failed to open WhatsApp or record send';

  @override
  String get failedToRecordSend => 'Failed to record send';

  @override
  String get whatsappUnavailable => 'WhatsApp link is unavailable';

  @override
  String get workStatusSection => 'WORK STATUS';

  @override
  String get clientDecisionSection => 'CLIENT DECISION';

  @override
  String get handoverSection => 'HANDOVER';

  @override
  String get waitingToStart => 'Waiting to start';

  @override
  String get technicianWorking => 'Technician working on repair';

  @override
  String get repairFinished => 'Repair finished';

  @override
  String get customerAcceptedPrice => 'Customer accepted the price';

  @override
  String get waitingCustomerReply => 'Waiting for the customer reply';

  @override
  String get customerRejectedOffer => 'Customer rejected the offer';

  @override
  String get finishedAndReady => 'Finished and ready to collect';

  @override
  String get markDelivered => 'Mark delivered';

  @override
  String get alreadyDelivered => 'Already marked as delivered';

  @override
  String get customerCollected => 'Customer collected the device';

  @override
  String get createReportAndInvoice => 'Create Report & Invoice';

  @override
  String get sendReportToCustomer => 'Send report to customer';

  @override
  String get failedToUpdateStatus => 'Failed to update status';

  @override
  String get filter => 'Filter';

  @override
  String get dateRange => 'Date Range';

  @override
  String get allTime => 'All Time';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get custom => 'Custom';

  @override
  String get applyFilter => 'Apply Filter';

  @override
  String get clearAll => 'Clear All';

  @override
  String get typeManually => 'Type';

  @override
  String get searchKnowledgeBase =>
      'Search our knowledge base or browse categories below';

  @override
  String get popularArticles => 'POPULAR ARTICLES';

  @override
  String get viewAll => 'View All';

  @override
  String get stillNeedHelp => 'Still need help?';

  @override
  String get supportAvailable247 =>
      'Our support team is available 24/7 to assist you with any questions.';

  @override
  String get helpPhotosTitle => 'How to recover deleted photos';

  @override
  String get helpPhotosStep1 =>
      'Create a new case and choose the device that stored the photos.';

  @override
  String get helpPhotosStep2 =>
      'Keep the drive powered on and avoid writing new files to it.';

  @override
  String get helpPhotosStep3 =>
      'Wait until inspection finishes, then review recovered files with the customer.';

  @override
  String get helpSsdTitle => 'Connecting an external SSD';

  @override
  String get helpSsdStep1 =>
      'Power off the workstation before attaching the drive.';

  @override
  String get helpSsdStep2 => 'Connect the SSD with a compatible cable or dock.';

  @override
  String get helpSsdStep3 => 'Open a new case and select SSD as the disk type.';

  @override
  String get helpSsdStep4 =>
      'Start inspection and follow the case status updates.';

  @override
  String get helpBillingTitle => 'Subscription & Billing FAQs';

  @override
  String get helpBillingStep1 =>
      'Add the agreed price on the case after the customer approves the quotation.';

  @override
  String get helpBillingStep2 =>
      'Send the invoice to the customer from the case details screen.';

  @override
  String get helpBillingStep3 =>
      'Mark the job as delivered after payment and handover are complete.';

  @override
  String get tel => 'Tel';

  @override
  String get pricesForQuantity =>
      'Prices are quoted for quantity mentioned and not applicable if change in quantity.';

  @override
  String get electronicInvoice => 'Electronic Invoice';

  @override
  String get invoiceIdLabel => 'invoice ID';

  @override
  String get failedToLoadInvoice => 'Failed to load invoice';

  @override
  String get invoiceType => 'Invoice Type';

  @override
  String get taxInvoice => 'Tax Invoice';

  @override
  String get invoiceTime => 'Invoice Time';

  @override
  String get customer => 'Customer';

  @override
  String get customerOrCompany => 'Customer / Company';

  @override
  String get mainEmployee => 'Main Employee';

  @override
  String get nationalAddress => 'National Address';

  @override
  String get branchName => 'Branch Name';

  @override
  String get cash => 'Cash';

  @override
  String get colNo => 'No.';

  @override
  String get colItem => 'Item';

  @override
  String get colDescription => 'Description';

  @override
  String get colQty => 'Qty';

  @override
  String get colPrice => 'Price';

  @override
  String get colDisc => 'Disc.';

  @override
  String get colTax => 'Tax';

  @override
  String get colTotal => 'Total';

  @override
  String get noItems => 'No items';

  @override
  String get paidOnMainFund => 'Paid on (1) Main Fund';

  @override
  String get paidOnTwo => 'Paid on (2)';

  @override
  String get paidOnThree => 'Paid on (3)';
}
