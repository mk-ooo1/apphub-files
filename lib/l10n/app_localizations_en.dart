// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get moneyManage => 'Money Manage';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get addContact => 'Add Contact';

  @override
  String get addBank => 'Add Bank';

  @override
  String get editContact => 'Edit Contact';

  @override
  String get gave => 'Gave';

  @override
  String get got => 'Got';

  @override
  String get principal => 'Principal';

  @override
  String get interest => 'Interest';

  @override
  String get settings => 'Settings';

  @override
  String get reports => 'Reports';

  @override
  String get reminders => 'Reminders';

  @override
  String get splitBill => 'Split Bill';

  @override
  String get searchContacts => 'Search contacts';

  @override
  String get searchTxn => 'Search transactions';

  @override
  String get totalReceivable => 'Total Receivable';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get netLoss => 'Net Loss';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get category => 'Category';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get reminder => 'Reminder';

  @override
  String get repeat => 'Repeat';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get none => 'None';

  @override
  String get settled => 'Settled';

  @override
  String get youWillGet => 'You will get';

  @override
  String get youWillGive => 'You will give';

  @override
  String get personal => 'Personal';

  @override
  String get business => 'Business';

  @override
  String get bank => 'Bank';

  @override
  String get deposit => 'Deposit';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get bankName => 'Bank Name';

  @override
  String get totalBankBalance => 'Total Bank Balance';

  @override
  String get allContacts => 'All Contacts';

  @override
  String get noContacts => 'No contacts yet. Tap + to add one.';

  @override
  String deleteContactWarning(String name) {
    return 'This deletes $name and all their transactions. This cannot be undone.';
  }

  @override
  String get lockedTransaction => 'Locked Transaction';

  @override
  String get lockedSubtitle =>
      'Locked transactions are cumulative and cannot be edited.';

  @override
  String get financialReports => 'Financial Reports';

  @override
  String get activeReminders => 'Active Reminders';

  @override
  String get noReminders => 'No active reminders found';

  @override
  String get exportReport => 'Export Report';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get exportCsv => 'Export as CSV';

  @override
  String get deleteContact => 'Delete contact?';

  @override
  String get generalPrincipal => 'General (Principal)';

  @override
  String get interestAccount => 'Interest Account';

  @override
  String get principalTransactions => 'Principal Transactions';

  @override
  String get interestRecords => 'Interest Records';

  @override
  String get swipeToDelete => 'Swipe left to delete';

  @override
  String get noInterestTransactions => 'No interest transactions yet';

  @override
  String get noPrincipalTransactions => 'No principal transactions yet';

  @override
  String get principalReceivable => 'Principal Receivable';

  @override
  String get principalPayable => 'Principal Payable';

  @override
  String get totalInterestEarned => 'Total Interest Earned';

  @override
  String get totalInterestOwed => 'Total Interest Owed';

  @override
  String get totalInterest => 'Total Interest';

  @override
  String get principalBalance => 'Principal Balance';

  @override
  String get netTotal => 'NET TOTAL';

  @override
  String get timezone => 'Timezone';

  @override
  String get selectTimezone => 'Select Timezone';

  @override
  String get account => 'Account';

  @override
  String get bankBalance => 'Bank Balance';

  @override
  String get liveBankBalance => 'Live Bank Balance';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get updateBaseBalance => 'Update Base Balance';

  @override
  String get initialBankAmount => 'Initial Bank Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get contacts => 'Contacts';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get lossBalance => 'Loss Balance';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get authSubtitle => 'Store your data securely and sync across devices';

  @override
  String signInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get deleteTransaction => 'Delete transaction?';

  @override
  String get deleteTransactionWarning =>
      'Are you sure you want to delete this transaction? This cannot be undone.';

  @override
  String get clearPin => 'Clear App PIN?';

  @override
  String get clearPinWarning =>
      'Are you sure you want to remove the App PIN security?';
}
