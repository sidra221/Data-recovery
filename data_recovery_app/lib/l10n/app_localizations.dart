import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Recovery'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your dashboard and manage recovery cases'**
  String get loginSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid login credentials'**
  String get invalidCredentials;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get navCases;

  /// No description provided for @navCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get navCustomer;

  /// No description provided for @navSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get navSetting;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @typeHdd35.
  ///
  /// In en, this message translates to:
  /// **'HDD 3.5'**
  String get typeHdd35;

  /// No description provided for @typeHdd25.
  ///
  /// In en, this message translates to:
  /// **'HDD 2.5'**
  String get typeHdd25;

  /// No description provided for @typeSsd.
  ///
  /// In en, this message translates to:
  /// **'SSD'**
  String get typeSsd;

  /// No description provided for @typeNvme.
  ///
  /// In en, this message translates to:
  /// **'NVMe'**
  String get typeNvme;

  /// No description provided for @typeExternal.
  ///
  /// In en, this message translates to:
  /// **'External HDD'**
  String get typeExternal;

  /// No description provided for @typeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB Flash'**
  String get typeUsb;

  /// No description provided for @typeMemoryCard.
  ///
  /// In en, this message translates to:
  /// **'Memory Card'**
  String get typeMemoryCard;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statusReceived;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusHasProblems.
  ///
  /// In en, this message translates to:
  /// **'Has problems'**
  String get statusHasProblems;

  /// No description provided for @workPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get workPending;

  /// No description provided for @workInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get workInProgress;

  /// No description provided for @workDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get workDone;

  /// No description provided for @clientAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get clientAgree;

  /// No description provided for @clientWaitClient.
  ///
  /// In en, this message translates to:
  /// **'Wait client'**
  String get clientWaitClient;

  /// No description provided for @clientReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get clientReady;

  /// No description provided for @clientRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get clientRejected;

  /// No description provided for @flagNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get flagNone;

  /// No description provided for @flagNoSpareParts.
  ///
  /// In en, this message translates to:
  /// **'No spare parts'**
  String get flagNoSpareParts;

  /// No description provided for @flagSendToChina.
  ///
  /// In en, this message translates to:
  /// **'Send to China'**
  String get flagSendToChina;

  /// No description provided for @recoveryProgress.
  ///
  /// In en, this message translates to:
  /// **'Recovery Progress'**
  String get recoveryProgress;

  /// No description provided for @readyForReturn.
  ///
  /// In en, this message translates to:
  /// **'READY FOR RETURN'**
  String get readyForReturn;

  /// No description provided for @finishedReadyToCollect.
  ///
  /// In en, this message translates to:
  /// **'Finished / ready to collect'**
  String get finishedReadyToCollect;

  /// No description provided for @viewCases.
  ///
  /// In en, this message translates to:
  /// **'View Cases'**
  String get viewCases;

  /// No description provided for @casesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Case} other{{count} Cases}}'**
  String casesCount(int count);

  /// No description provided for @todaysActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get todaysActivity;

  /// No description provided for @newCases.
  ///
  /// In en, this message translates to:
  /// **'New Cases'**
  String get newCases;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @agreeChip.
  ///
  /// In en, this message translates to:
  /// **'Agree {count}'**
  String agreeChip(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get filterInspection;

  /// No description provided for @noRepairs.
  ///
  /// In en, this message translates to:
  /// **'No Repairs'**
  String get noRepairs;

  /// No description provided for @noRepairsHint.
  ///
  /// In en, this message translates to:
  /// **'You have no repairs currently'**
  String get noRepairsHint;

  /// No description provided for @barcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Barcode not found'**
  String get barcodeNotFound;

  /// No description provided for @caseTitle.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get caseTitle;

  /// No description provided for @sectionCustomer.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get sectionCustomer;

  /// No description provided for @sectionDevice.
  ///
  /// In en, this message translates to:
  /// **'DEVICE'**
  String get sectionDevice;

  /// No description provided for @sectionBilling.
  ///
  /// In en, this message translates to:
  /// **'BILLING'**
  String get sectionBilling;

  /// No description provided for @sectionAttachments.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS'**
  String get sectionAttachments;

  /// No description provided for @sectionHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get sectionHistory;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get labelPhone;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get labelModel;

  /// No description provided for @labelSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get labelSerial;

  /// No description provided for @labelAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get labelAttached;

  /// No description provided for @labelProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get labelProblem;

  /// No description provided for @labelInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get labelInspection;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @labelInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get labelInvoice;

  /// No description provided for @labelBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get labelBarcode;

  /// No description provided for @labelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get labelPrice;

  /// No description provided for @labelInvoiceSent.
  ///
  /// In en, this message translates to:
  /// **'Invoice sent'**
  String get labelInvoiceSent;

  /// No description provided for @labelDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get labelDelivered;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get labelWork;

  /// No description provided for @labelClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get labelClient;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get noAttachments;

  /// No description provided for @noChangesYet.
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get noChangesYet;

  /// No description provided for @failedToLoadCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to load case'**
  String get failedToLoadCase;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @notifyCustomer.
  ///
  /// In en, this message translates to:
  /// **'Notify Customer'**
  String get notifyCustomer;

  /// No description provided for @quotationInvoice.
  ///
  /// In en, this message translates to:
  /// **'Quotation / Invoice'**
  String get quotationInvoice;

  /// No description provided for @createNewCase.
  ///
  /// In en, this message translates to:
  /// **'Create New Case'**
  String get createNewCase;

  /// No description provided for @addCase.
  ///
  /// In en, this message translates to:
  /// **'Add Case'**
  String get addCase;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER INFORMATION'**
  String get customerInformation;

  /// No description provided for @deviceDetails.
  ///
  /// In en, this message translates to:
  /// **'DEVICE DETAILS'**
  String get deviceDetails;

  /// No description provided for @mediaAndDocument.
  ///
  /// In en, this message translates to:
  /// **'MEDIA & DOCUMENT'**
  String get mediaAndDocument;

  /// No description provided for @statusSection.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusSection;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Full Name'**
  String get enterFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @deviceType.
  ///
  /// In en, this message translates to:
  /// **'Device Type'**
  String get deviceType;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @scanSerial.
  ///
  /// In en, this message translates to:
  /// **'Scan serial'**
  String get scanSerial;

  /// No description provided for @recoveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Recovery Details'**
  String get recoveryDetails;

  /// No description provided for @whatCustomerReported.
  ///
  /// In en, this message translates to:
  /// **'What the customer reported'**
  String get whatCustomerReported;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @addPhotosDocuments.
  ///
  /// In en, this message translates to:
  /// **'Add Photos/Documents'**
  String get addPhotosDocuments;

  /// No description provided for @uploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload JPG, PNG or PDF up to 10MB'**
  String get uploadHint;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file (PDF, image)'**
  String get chooseFile;

  /// No description provided for @caseCreated.
  ///
  /// In en, this message translates to:
  /// **'Case created successfully'**
  String get caseCreated;

  /// No description provided for @failedToCreateCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to create case'**
  String get failedToCreateCase;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @customerState.
  ///
  /// In en, this message translates to:
  /// **'Customer state'**
  String get customerState;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'DEVICES'**
  String get devices;

  /// No description provided for @totalRepairs.
  ///
  /// In en, this message translates to:
  /// **'Total Repairs'**
  String get totalRepairs;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @firstVisit.
  ///
  /// In en, this message translates to:
  /// **'First visit'**
  String get firstVisit;

  /// No description provided for @lastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get lastVisit;

  /// No description provided for @noDevicesYet.
  ///
  /// In en, this message translates to:
  /// **'No devices for this customer yet'**
  String get noDevicesYet;

  /// No description provided for @deleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomer;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Customer?'**
  String get deleteCustomerConfirm;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updatedSuccessfully;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @failedToLoadCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customer'**
  String get failedToLoadCustomer;

  /// No description provided for @failedToDeleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete customer'**
  String get failedToDeleteCustomer;

  /// No description provided for @customersList.
  ///
  /// In en, this message translates to:
  /// **'Customers List'**
  String get customersList;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search Name, Email, phone'**
  String get searchCustomersHint;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @lastDash.
  ///
  /// In en, this message translates to:
  /// **'Last: -'**
  String get lastDash;

  /// No description provided for @searchReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Serial, phone, name or invoice number'**
  String get searchReportsHint;

  /// No description provided for @searchReportsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search by serial, phone, name, invoice number — or a date range'**
  String get searchReportsEmptyHint;

  /// No description provided for @searchNeedsCriteria.
  ///
  /// In en, this message translates to:
  /// **'Enter a serial, phone, name, invoice — or pick a date range'**
  String get searchNeedsCriteria;

  /// No description provided for @noCasesMatch.
  ///
  /// In en, this message translates to:
  /// **'No cases match this search'**
  String get noCasesMatch;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dateTo;

  /// No description provided for @dateAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get dateAny;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @showingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} — refine the search to narrow it'**
  String showingOf(int shown, int total);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get settings;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get sectionSupport;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirm;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @itEmployee.
  ///
  /// In en, this message translates to:
  /// **'IT Employee'**
  String get itEmployee;

  /// No description provided for @roleDepartment.
  ///
  /// In en, this message translates to:
  /// **'ROLE / DEPARTMENT'**
  String get roleDepartment;

  /// No description provided for @phoneNumberCaps.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phoneNumberCaps;

  /// No description provided for @emailAddressCaps.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddressCaps;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @failedToUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get failedToUploadPhoto;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get couldNotOpenEmail;

  /// No description provided for @supportRequest.
  ///
  /// In en, this message translates to:
  /// **'Help Center support request'**
  String get supportRequest;

  /// No description provided for @noOverdueCases.
  ///
  /// In en, this message translates to:
  /// **'No overdue wait-client cases'**
  String get noOverdueCases;

  /// No description provided for @failedToLoadAlerts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load alerts'**
  String get failedToLoadAlerts;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @financialOffer.
  ///
  /// In en, this message translates to:
  /// **'Financial Offer'**
  String get financialOffer;

  /// No description provided for @quotation.
  ///
  /// In en, this message translates to:
  /// **'QUOTATION'**
  String get quotation;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get description;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get qty;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'UNIT PRICE'**
  String get unitPrice;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate %'**
  String get taxRate;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @totalExclTax.
  ///
  /// In en, this message translates to:
  /// **'Total Excl. Tax'**
  String get totalExclTax;

  /// No description provided for @totalWithTax.
  ///
  /// In en, this message translates to:
  /// **'Total With Tax'**
  String get totalWithTax;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'TERMS AND CONDITIONS:'**
  String get termsAndConditions;

  /// No description provided for @pricesInRiyals.
  ///
  /// In en, this message translates to:
  /// **'All prices are in Saudi Riyals.'**
  String get pricesInRiyals;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Payment: 100% CASH'**
  String get paymentCash;

  /// No description provided for @addAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get addAtLeastOneItem;

  /// No description provided for @enterPriceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a price greater than zero'**
  String get enterPriceGreaterThanZero;

  /// No description provided for @failedToSendQuotation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send quotation'**
  String get failedToSendQuotation;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Person name'**
  String get personName;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @fromColon.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get fromColon;

  /// No description provided for @toColon.
  ///
  /// In en, this message translates to:
  /// **'To :'**
  String get toColon;

  /// No description provided for @sellerSignature.
  ///
  /// In en, this message translates to:
  /// **'Seller Signature'**
  String get sellerSignature;

  /// No description provided for @receiverSignature.
  ///
  /// In en, this message translates to:
  /// **'Receiver Signature'**
  String get receiverSignature;

  /// No description provided for @tapToSign.
  ///
  /// In en, this message translates to:
  /// **'Tap to sign'**
  String get tapToSign;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveAndPrint.
  ///
  /// In en, this message translates to:
  /// **'Save & Print'**
  String get saveAndPrint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @sendPickupNotification.
  ///
  /// In en, this message translates to:
  /// **'Send pickup notification'**
  String get sendPickupNotification;

  /// No description provided for @sentAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Sent automatically via server'**
  String get sentAutomatically;

  /// No description provided for @notifyDeviceReady.
  ///
  /// In en, this message translates to:
  /// **'Notify Customer - Device Ready'**
  String get notifyDeviceReady;

  /// No description provided for @failedToLoadInvoiceText.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoice text'**
  String get failedToLoadInvoiceText;

  /// No description provided for @failedToOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Failed to open WhatsApp or record send'**
  String get failedToOpenWhatsapp;

  /// No description provided for @failedToRecordSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to record send'**
  String get failedToRecordSend;

  /// No description provided for @whatsappUnavailable.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp link is unavailable'**
  String get whatsappUnavailable;

  /// No description provided for @workStatusSection.
  ///
  /// In en, this message translates to:
  /// **'WORK STATUS'**
  String get workStatusSection;

  /// No description provided for @clientDecisionSection.
  ///
  /// In en, this message translates to:
  /// **'CLIENT DECISION'**
  String get clientDecisionSection;

  /// No description provided for @handoverSection.
  ///
  /// In en, this message translates to:
  /// **'HANDOVER'**
  String get handoverSection;

  /// No description provided for @waitingToStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting to start'**
  String get waitingToStart;

  /// No description provided for @technicianWorking.
  ///
  /// In en, this message translates to:
  /// **'Technician working on repair'**
  String get technicianWorking;

  /// No description provided for @repairFinished.
  ///
  /// In en, this message translates to:
  /// **'Repair finished'**
  String get repairFinished;

  /// No description provided for @customerAcceptedPrice.
  ///
  /// In en, this message translates to:
  /// **'Customer accepted the price'**
  String get customerAcceptedPrice;

  /// No description provided for @waitingCustomerReply.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer reply'**
  String get waitingCustomerReply;

  /// No description provided for @customerRejectedOffer.
  ///
  /// In en, this message translates to:
  /// **'Customer rejected the offer'**
  String get customerRejectedOffer;

  /// No description provided for @finishedAndReady.
  ///
  /// In en, this message translates to:
  /// **'Finished and ready to collect'**
  String get finishedAndReady;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get markDelivered;

  /// No description provided for @alreadyDelivered.
  ///
  /// In en, this message translates to:
  /// **'Already marked as delivered'**
  String get alreadyDelivered;

  /// No description provided for @customerCollected.
  ///
  /// In en, this message translates to:
  /// **'Customer collected the device'**
  String get customerCollected;

  /// No description provided for @createReportAndInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Report & Invoice'**
  String get createReportAndInvoice;

  /// No description provided for @sendReportToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Send report to customer'**
  String get sendReportToCustomer;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @typeManually.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeManually;

  /// No description provided for @popularArticles.
  ///
  /// In en, this message translates to:
  /// **'POPULAR ARTICLES'**
  String get popularArticles;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @supportAvailable247.
  ///
  /// In en, this message translates to:
  /// **'Our support team is available 24/7 to assist you with any questions.'**
  String get supportAvailable247;

  /// No description provided for @helpPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'How to recover deleted photos'**
  String get helpPhotosTitle;

  /// No description provided for @helpPhotosStep1.
  ///
  /// In en, this message translates to:
  /// **'Create a new case and choose the device that stored the photos.'**
  String get helpPhotosStep1;

  /// No description provided for @helpPhotosStep2.
  ///
  /// In en, this message translates to:
  /// **'Keep the drive powered on and avoid writing new files to it.'**
  String get helpPhotosStep2;

  /// No description provided for @helpPhotosStep3.
  ///
  /// In en, this message translates to:
  /// **'Wait until inspection finishes, then review recovered files with the customer.'**
  String get helpPhotosStep3;

  /// No description provided for @helpSsdTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting an external SSD'**
  String get helpSsdTitle;

  /// No description provided for @helpSsdStep1.
  ///
  /// In en, this message translates to:
  /// **'Power off the workstation before attaching the drive.'**
  String get helpSsdStep1;

  /// No description provided for @helpSsdStep2.
  ///
  /// In en, this message translates to:
  /// **'Connect the SSD with a compatible cable or dock.'**
  String get helpSsdStep2;

  /// No description provided for @helpSsdStep3.
  ///
  /// In en, this message translates to:
  /// **'Open a new case and select SSD as the disk type.'**
  String get helpSsdStep3;

  /// No description provided for @helpSsdStep4.
  ///
  /// In en, this message translates to:
  /// **'Start inspection and follow the case status updates.'**
  String get helpSsdStep4;

  /// No description provided for @helpBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Billing FAQs'**
  String get helpBillingTitle;

  /// No description provided for @helpBillingStep1.
  ///
  /// In en, this message translates to:
  /// **'Add the agreed price on the case after the customer approves the quotation.'**
  String get helpBillingStep1;

  /// No description provided for @helpBillingStep2.
  ///
  /// In en, this message translates to:
  /// **'Send the invoice to the customer from the case details screen.'**
  String get helpBillingStep2;

  /// No description provided for @helpBillingStep3.
  ///
  /// In en, this message translates to:
  /// **'Mark the job as delivered after payment and handover are complete.'**
  String get helpBillingStep3;

  /// No description provided for @tel.
  ///
  /// In en, this message translates to:
  /// **'Tel'**
  String get tel;

  /// No description provided for @pricesForQuantity.
  ///
  /// In en, this message translates to:
  /// **'Prices are quoted for quantity mentioned and not applicable if change in quantity.'**
  String get pricesForQuantity;

  /// No description provided for @electronicInvoice.
  ///
  /// In en, this message translates to:
  /// **'Electronic Invoice'**
  String get electronicInvoice;

  /// No description provided for @invoiceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'invoice ID'**
  String get invoiceIdLabel;

  /// No description provided for @failedToLoadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoice'**
  String get failedToLoadInvoice;

  /// No description provided for @invoiceType.
  ///
  /// In en, this message translates to:
  /// **'Invoice Type'**
  String get invoiceType;

  /// No description provided for @taxInvoice.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice'**
  String get taxInvoice;

  /// No description provided for @invoiceTime.
  ///
  /// In en, this message translates to:
  /// **'Invoice Time'**
  String get invoiceTime;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customerOrCompany.
  ///
  /// In en, this message translates to:
  /// **'Customer / Company'**
  String get customerOrCompany;

  /// No description provided for @mainEmployee.
  ///
  /// In en, this message translates to:
  /// **'Main Employee'**
  String get mainEmployee;

  /// No description provided for @nationalAddress.
  ///
  /// In en, this message translates to:
  /// **'National Address'**
  String get nationalAddress;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchName;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @colNo.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get colNo;

  /// No description provided for @colItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get colItem;

  /// No description provided for @colDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get colDescription;

  /// No description provided for @colQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get colQty;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get colPrice;

  /// No description provided for @colDisc.
  ///
  /// In en, this message translates to:
  /// **'Disc.'**
  String get colDisc;

  /// No description provided for @colTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get colTax;

  /// No description provided for @colTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get colTotal;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @paidOnMainFund.
  ///
  /// In en, this message translates to:
  /// **'Paid on (1) Main Fund'**
  String get paidOnMainFund;

  /// No description provided for @paidOnTwo.
  ///
  /// In en, this message translates to:
  /// **'Paid on (2)'**
  String get paidOnTwo;

  /// No description provided for @paidOnThree.
  ///
  /// In en, this message translates to:
  /// **'Paid on (3)'**
  String get paidOnThree;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @showingSavedData.
  ///
  /// In en, this message translates to:
  /// **'Showing data saved {when}'**
  String showingSavedData(String when);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @failedToLoadStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStats;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server'**
  String get serverUnreachable;

  /// No description provided for @noSavedData.
  ///
  /// In en, this message translates to:
  /// **'No saved data to show'**
  String get noSavedData;

  /// No description provided for @searchHelpHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles'**
  String get searchHelpHint;

  /// No description provided for @noArticlesMatch.
  ///
  /// In en, this message translates to:
  /// **'No articles match this search'**
  String get noArticlesMatch;

  /// No description provided for @savedOfflineWillSync.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. It will be sent when the server is back.'**
  String get savedOfflineWillSync;

  /// No description provided for @noOfflineNumbersLeft.
  ///
  /// In en, this message translates to:
  /// **'No offline invoice numbers left for today. Connect to the server first.'**
  String get noOfflineNumbersLeft;

  /// No description provided for @attachmentsNeedServer.
  ///
  /// In en, this message translates to:
  /// **'Attachments were not uploaded. Add them again once the server is back.'**
  String get attachmentsNeedServer;

  /// No description provided for @pendingSyncCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String pendingSyncCount(int count);

  /// No description provided for @rejectedSyncCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change was rejected} other{{count} changes were rejected}}'**
  String rejectedSyncCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change sent} other{{count} changes sent}}'**
  String syncedCount(int count);

  /// No description provided for @pendingUpload.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get pendingUpload;

  /// No description provided for @printDocuments.
  ///
  /// In en, this message translates to:
  /// **'Print documents'**
  String get printDocuments;

  /// No description provided for @printSticker.
  ///
  /// In en, this message translates to:
  /// **'Device sticker'**
  String get printSticker;

  /// No description provided for @printStickerHint.
  ///
  /// In en, this message translates to:
  /// **'Stick it on the received device'**
  String get printStickerHint;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receiving receipt'**
  String get printReceipt;

  /// No description provided for @printReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Hand it to the customer'**
  String get printReceiptHint;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the print dialog'**
  String get printFailed;

  /// No description provided for @repairsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repair} other{{count} repairs}}'**
  String repairsCount(int count);

  /// No description provided for @lastVisitOn.
  ///
  /// In en, this message translates to:
  /// **'Last: {date}'**
  String lastVisitOn(String date);

  /// No description provided for @allWithCount.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String allWithCount(int count);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
