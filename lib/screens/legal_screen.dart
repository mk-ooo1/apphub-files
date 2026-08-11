import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class LegalTexts {
  static const String privacyPolicy = """
Privacy Policy

Effective Date: October 2023

1. Introduction
Money Manage App ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information about you when you use our mobile application.

2. Information We Collect
- Account Information: When you sign in with Google, we collect your name, email address, and profile picture provided by Google.
- Financial Data: We store the transaction details, contact names, and notes you enter into the app to provide the ledger service.
- Device Information: We may collect basic device information such as model and OS version to improve app performance.

3. How We Use Information
- To provide and maintain our Service.
- To sync your data across your devices using Google Cloud (Firebase).
- To send you local reminders/notifications as requested by you.

4. Data Security
Your data is stored securely in Firebase (Google Cloud). We use industry-standard security measures to protect your information. Your financial data is private to your account and is not shared with other users.

5. Third-Party Services
We use Google Sign-In and Firebase for authentication and data storage. These services have their own privacy policies.

6. Your Rights
You can delete your data by deleting transactions or contacts within the app. If you wish to delete your entire account, please contact us.

7. Changes to This Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.

8. Contact Us
If you have any questions about this Privacy Policy, please contact us at bg00998835@gmail.com
""";

  static const String termsAndConditions = """
Terms and Conditions

1. Acceptance of Terms
By downloading or using Money Manage App, you agree to be bound by these Terms and Conditions.

2. Use of Service
Money Manage is a tool for personal and business ledger tracking. You are responsible for the accuracy of the data you enter.

3. Data Backup
While we use Google Firebase for data storage and sync, we recommend users periodically export their data (PDF/CSV) for their own records. We are not liable for data loss due to service interruptions.

4. Privacy
Your use of the app is also governed by our Privacy Policy.

5. Limitation of Liability
Money Manage App is provided "as is" without any warranties. We are not liable for any financial losses or errors resulting from the use of the app. The app is a tracking tool and does not provide financial or legal advice.

6. Modifications
We reserve the right to modify or discontinue the Service at any time.

7. Contact
For support or inquiries, contact us at bg00998835@gmail.com
""";
}
