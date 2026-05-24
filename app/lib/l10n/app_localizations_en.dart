// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Health';

  @override
  String get navHome => 'Home';

  @override
  String get navRecords => 'Records';

  @override
  String get navCharts => 'Charts';

  @override
  String get navDevices => 'Devices';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Family Health';

  @override
  String get loginSubtitle => 'Sign in to manage your family health';

  @override
  String get loginPhoneHint => 'Phone / Email';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account? Register';

  @override
  String get loginWeChat => 'WeChat';

  @override
  String get loginQQ => 'QQ';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginOtherWays => 'Other ways to sign in';

  @override
  String get registerTitle => 'Register';

  @override
  String get registerNickname => 'Nickname';

  @override
  String get registerPhone => 'Phone';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerConfirmPwd => 'Confirm Password';

  @override
  String get registerButton => 'Register';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String homeGreeting(Object timeOfDay) {
    return 'Good $timeOfDay';
  }

  @override
  String get homeHeartRate => 'Heart Rate';

  @override
  String get homeSteps => 'Steps';

  @override
  String get homeSleep => 'Sleep';

  @override
  String get homeQuickRecord => 'Quick Record';

  @override
  String get homeSmartDevice => 'Smart Device';

  @override
  String get homeNotConnected => 'Not Connected';

  @override
  String get homeConnect => 'Connect';

  @override
  String get homeRecentRecords => 'Recent Records';

  @override
  String get recordSleep => 'Sleep';

  @override
  String get recordSmoking => 'Smoking';

  @override
  String get recordDrinking => 'Drinking';

  @override
  String get recordWorkPosture => 'Work Posture';

  @override
  String get recordDiet => 'Diet';

  @override
  String get recordSugar => 'Sugar';

  @override
  String get recordFoodDetail => 'Food Detail';

  @override
  String get recordEnvironment => 'Environment';

  @override
  String get recordVitals => 'Vitals';

  @override
  String get recordNoData => 'No data';

  @override
  String get recordToday => 'Today';

  @override
  String get recordSave => 'Save';

  @override
  String get recordCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsFamily => 'Family Management';

  @override
  String get settingsFamilyMembers => 'Family Members';

  @override
  String get settingsReferenceRanges => 'Health Reference Ranges';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDataMgmt => 'Data Management';

  @override
  String get settingsServer => 'Server Settings';

  @override
  String get settingsAccountLink => 'Account Linking';

  @override
  String get settingsWeChat => 'WeChat';

  @override
  String get settingsQQ => 'QQ';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get deviceScan => 'Scan for devices';

  @override
  String get deviceNoDevice => 'No devices found';

  @override
  String get deviceScanning => 'Scanning...';

  @override
  String get deviceBound => 'Bound';

  @override
  String get deviceUnbind => 'Unbind';

  @override
  String get chartKLine => 'K-Line Chart';

  @override
  String get chartStatistics => 'Statistics';

  @override
  String get chartMean => 'Mean';

  @override
  String get chartMedian => 'Median';

  @override
  String get chartReport => 'Health Report';

  @override
  String get chartGenerate => 'Generate Report';

  @override
  String get chartShare => 'Share';

  @override
  String get serverLocal => 'Local';

  @override
  String get serverCloud => 'Cloud';

  @override
  String get serverSwitch => 'Switch';

  @override
  String get serverCancel => 'Cancel';

  @override
  String get timeMorning => 'Good morning';

  @override
  String get timeAfternoon => 'Good afternoon';

  @override
  String get timeEvening => 'Good evening';

  @override
  String get timeNight => 'Good night';

  @override
  String get errorNetwork => 'Cannot connect to server';

  @override
  String get errorTimeout => 'Connection timeout';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorPhoneRegistered => 'Phone already registered';

  @override
  String get errorEmailRegistered => 'Email already registered';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get bind => 'Bind';

  @override
  String get unbind => 'Unbind';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get comingSoon => 'Coming soon';
}
