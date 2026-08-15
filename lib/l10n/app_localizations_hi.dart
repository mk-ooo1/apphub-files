// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get moneyManage => 'मनी मैनेज';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get addContact => 'संपर्क जोड़ें';

  @override
  String get addBank => 'बैंक जोड़ें';

  @override
  String get editContact => 'संपर्क संपादित करें';

  @override
  String get gave => 'दिए';

  @override
  String get got => 'मिले';

  @override
  String get principal => 'मूलधन';

  @override
  String get interest => 'ब्याज';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get reports => 'रिपोर्ट्स';

  @override
  String get reminders => 'रिमाइंडर';

  @override
  String get splitBill => 'बिल बांटें';

  @override
  String get searchContacts => 'संपर्क खोजें';

  @override
  String get searchTxn => 'लेन-देन खोजें';

  @override
  String get totalReceivable => 'कुल लेना';

  @override
  String get totalPayable => 'कुल देना';

  @override
  String get netProfit => 'शुद्ध लाभ';

  @override
  String get netLoss => 'शुद्ध हानि';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get save => 'सहेजें';

  @override
  String get update => 'अपडेट करें';

  @override
  String get name => 'नाम';

  @override
  String get phone => 'फोन';

  @override
  String get category => 'श्रेणी';

  @override
  String get note => 'नोट';

  @override
  String get date => 'तिथि';

  @override
  String get reminder => 'रिमाइंडर';

  @override
  String get repeat => 'दोहराना';

  @override
  String get daily => 'दैनिक';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get monthly => 'मासिक';

  @override
  String get none => 'कोई नहीं';

  @override
  String get settled => 'चुकता';

  @override
  String get youWillGet => 'आपको मिलेंगे';

  @override
  String get youWillGive => 'आपको देने हैं';

  @override
  String get personal => 'व्यक्तिगत';

  @override
  String get business => 'व्यवसाय';

  @override
  String get bank => 'बैंक';

  @override
  String get deposit => 'जमा (Deposit)';

  @override
  String get withdraw => 'निकासी (Withdraw)';

  @override
  String get bankName => 'बैंक का नाम';

  @override
  String get totalBankBalance => 'कुल बैंक बैलेंस';

  @override
  String get allContacts => 'सभी संपर्क';

  @override
  String get noContacts =>
      'अभी कोई संपर्क नहीं है। जोड़ने के लिए + पर टैप करें।';

  @override
  String deleteContactWarning(String name) {
    return 'यह $name और उनके सभी लेन-देन को हटा देगा। इसे वापस नहीं लिया जा सकता।';
  }

  @override
  String get lockedTransaction => 'लॉक किया गया लेन-देन';

  @override
  String get lockedSubtitle =>
      'लॉक किए गए लेन-देन संचयी होते हैं और उन्हें संपादित नहीं किया जा सकता है।';

  @override
  String get financialReports => 'वित्तीय रिपोर्ट';

  @override
  String get activeReminders => 'सक्रिय रिमाइंडर';

  @override
  String get noReminders => 'कोई सक्रिय रिमाइंडर नहीं मिला';

  @override
  String get exportReport => 'रिपोर्ट निर्यात करें';

  @override
  String get exportPdf => 'पीडीएफ के रूप में निर्यात करें';

  @override
  String get exportCsv => 'सीएसवी के रूप में निर्यात करें';

  @override
  String get deleteContact => 'संपर्क हटाएं?';

  @override
  String get generalPrincipal => 'सामान्य (मूलधन)';

  @override
  String get interestAccount => 'ब्याज खाता';

  @override
  String get principalTransactions => 'मूलधन लेन-देन';

  @override
  String get interestRecords => 'ब्याज रिकॉर्ड';

  @override
  String get swipeToDelete => 'हटाने के लिए बाईं ओर स्वाइप करें';

  @override
  String get noInterestTransactions => 'अभी तक कोई ब्याज लेन-देन नहीं है';

  @override
  String get noPrincipalTransactions => 'अभी तक कोई मूलधन लेन-देन नहीं है';

  @override
  String get principalReceivable => 'मूलधन लेना';

  @override
  String get principalPayable => 'मूलधन देना';

  @override
  String get totalInterestEarned => 'कुल अर्जित ब्याज';

  @override
  String get totalInterestOwed => 'कुल देय ब्याज';

  @override
  String get totalInterest => 'कुल ब्याज';

  @override
  String get principalBalance => 'मूलधन शेष';

  @override
  String get netTotal => 'कुल शेष';

  @override
  String get timezone => 'समय क्षेत्र (Timezone)';

  @override
  String get selectTimezone => 'समय क्षेत्र चुनें';

  @override
  String get account => 'खाता';

  @override
  String get bankBalance => 'बैंक बैलेंस';

  @override
  String get liveBankBalance => 'लाइव बैंक बैलेंस';

  @override
  String get allTransactions => 'सभी लेन-देन';

  @override
  String get all => 'सब';

  @override
  String get updateBaseBalance => 'मुख्य बैलेंस अपडेट करें';

  @override
  String get initialBankAmount => 'प्रारंभिक बैंक राशि';

  @override
  String get enterAmount => 'राशि दर्ज करें';

  @override
  String get contacts => 'संपर्क';

  @override
  String get currentBalance => 'वर्तमान बैलेंस';

  @override
  String get lossBalance => 'हानि बैलेंस';

  @override
  String get signInWithGoogle => 'गूगल के साथ साइन इन करें';

  @override
  String get authSubtitle =>
      'अपना डेटा सुरक्षित रूप से सहेजें और सभी डिवाइस पर सिंक करें';

  @override
  String signInFailed(String error) {
    return 'साइन-इन विफल रहा: $error';
  }

  @override
  String get deleteTransaction => 'लेन-देन हटाएं?';

  @override
  String get deleteTransactionWarning =>
      'क्या आप वाकई इस लेन-देन को हटाना चाहते हैं? इसे वापस नहीं लिया जा सकता।';

  @override
  String get clearPin => 'ऐप पिन हटाएं?';

  @override
  String get clearPinWarning => 'क्या आप वाकई ऐप पिन सुरक्षा हटाना चाहते हैं?';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteAccountWarning =>
      'यह आपके खाते और संपर्कों और लेन-देन सहित आपके सभी डेटा को स्थायी रूप से हटा देगा। यह क्रिया वापस नहीं ली जा सकती।';

  @override
  String get recentLoginRequired =>
      'सुरक्षा के लिए, कृपया अपना खाता हटाने से पहले लॉग आउट करें और फिर से लॉग इन करें।';

  @override
  String get accountDeleted => 'खाता और डेटा सफलतापूर्वक हटा दिया गया।';
}
