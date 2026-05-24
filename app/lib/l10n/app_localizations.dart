import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Health'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get navCharts;

  /// No description provided for @navDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get navDevices;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Health'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your family health'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone / Email'**
  String get loginPhoneHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get loginNoAccount;

  /// No description provided for @loginWeChat.
  ///
  /// In en, this message translates to:
  /// **'WeChat'**
  String get loginWeChat;

  /// No description provided for @loginQQ.
  ///
  /// In en, this message translates to:
  /// **'QQ'**
  String get loginQQ;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginOtherWays.
  ///
  /// In en, this message translates to:
  /// **'Other ways to sign in'**
  String get loginOtherWays;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registerNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get registerNickname;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registerPhone;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerConfirmPwd.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPwd;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get registerHaveAccount;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good {timeOfDay}'**
  String homeGreeting(Object timeOfDay);

  /// No description provided for @homeHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get homeHeartRate;

  /// No description provided for @homeSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get homeSteps;

  /// No description provided for @homeSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get homeSleep;

  /// No description provided for @homeQuickRecord.
  ///
  /// In en, this message translates to:
  /// **'Quick Record'**
  String get homeQuickRecord;

  /// No description provided for @homeSmartDevice.
  ///
  /// In en, this message translates to:
  /// **'Smart Device'**
  String get homeSmartDevice;

  /// No description provided for @homeNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get homeNotConnected;

  /// No description provided for @homeConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get homeConnect;

  /// No description provided for @homeRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent Records'**
  String get homeRecentRecords;

  /// No description provided for @recordSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get recordSleep;

  /// No description provided for @recordSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get recordSmoking;

  /// No description provided for @recordDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get recordDrinking;

  /// No description provided for @recordWorkPosture.
  ///
  /// In en, this message translates to:
  /// **'Work Posture'**
  String get recordWorkPosture;

  /// No description provided for @recordDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get recordDiet;

  /// No description provided for @recordSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get recordSugar;

  /// No description provided for @recordFoodDetail.
  ///
  /// In en, this message translates to:
  /// **'Food Detail'**
  String get recordFoodDetail;

  /// No description provided for @recordEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get recordEnvironment;

  /// No description provided for @recordVitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get recordVitals;

  /// No description provided for @recordNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get recordNoData;

  /// No description provided for @recordToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get recordToday;

  /// No description provided for @recordSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get recordSave;

  /// No description provided for @recordCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get recordCancel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsFamily.
  ///
  /// In en, this message translates to:
  /// **'Family Management'**
  String get settingsFamily;

  /// No description provided for @settingsFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get settingsFamilyMembers;

  /// No description provided for @settingsReferenceRanges.
  ///
  /// In en, this message translates to:
  /// **'Health Reference Ranges'**
  String get settingsReferenceRanges;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDataMgmt.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataMgmt;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get settingsServer;

  /// No description provided for @settingsAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Account Linking'**
  String get settingsAccountLink;

  /// No description provided for @settingsWeChat.
  ///
  /// In en, this message translates to:
  /// **'WeChat'**
  String get settingsWeChat;

  /// No description provided for @settingsQQ.
  ///
  /// In en, this message translates to:
  /// **'QQ'**
  String get settingsQQ;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get settingsLogoutConfirm;

  /// No description provided for @deviceScan.
  ///
  /// In en, this message translates to:
  /// **'Scan for devices'**
  String get deviceScan;

  /// No description provided for @deviceNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get deviceNoDevice;

  /// No description provided for @deviceScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get deviceScanning;

  /// No description provided for @deviceBound.
  ///
  /// In en, this message translates to:
  /// **'Bound'**
  String get deviceBound;

  /// No description provided for @deviceUnbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get deviceUnbind;

  /// No description provided for @chartKLine.
  ///
  /// In en, this message translates to:
  /// **'K-Line Chart'**
  String get chartKLine;

  /// No description provided for @chartStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get chartStatistics;

  /// No description provided for @chartMean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get chartMean;

  /// No description provided for @chartMedian.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get chartMedian;

  /// No description provided for @chartReport.
  ///
  /// In en, this message translates to:
  /// **'Health Report'**
  String get chartReport;

  /// No description provided for @chartGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get chartGenerate;

  /// No description provided for @chartShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get chartShare;

  /// No description provided for @serverLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get serverLocal;

  /// No description provided for @serverCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get serverCloud;

  /// No description provided for @serverSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get serverSwitch;

  /// No description provided for @serverCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get serverCancel;

  /// No description provided for @timeMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get timeMorning;

  /// No description provided for @timeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get timeAfternoon;

  /// No description provided for @timeEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get timeEvening;

  /// No description provided for @timeNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get timeNight;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get errorTimeout;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;

  /// No description provided for @errorPhoneRegistered.
  ///
  /// In en, this message translates to:
  /// **'Phone already registered'**
  String get errorPhoneRegistered;

  /// No description provided for @errorEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get errorEmailRegistered;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @bind.
  ///
  /// In en, this message translates to:
  /// **'Bind'**
  String get bind;

  /// No description provided for @unbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get unbind;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
