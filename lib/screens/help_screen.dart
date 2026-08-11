import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Use Money Manage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpSection(
            icon: Icons.person_add,
            title: '1. Add Contacts',
            body:
                'Tap "Add Contact" to create a profile. Choose between Personal (family/friends) '
                'or Business (suppliers/customers). You can set an opening balance if there '
                'is existing debt.',
          ),
          _HelpSection(
            icon: Icons.call_split,
            title: '2. Split Bills',
            body:
                'Tap the orange "Split Bill" button on the dashboard to divide an expense among multiple '
                'people. The app automatically calculates each person\'s share and adds a transaction to their ledger.',
          ),
          _HelpSection(
            icon: Icons.tab,
            title: '3. Principal & Interest Tabs',
            body:
                'Inside a contact detail, use the tabs to separate standard transactions (Principal) from '
                'Interest records. Each tab has its own independent calculation and running balance.',
          ),
          _HelpSection(
            icon: Icons.lock,
            title: '4. Lock Transactions',
            body:
                'Toggle "Lock Transaction" to make an entry permanent. Locked transactions are cumulative '
                'and cannot be edited or deleted, ensuring the integrity of your records.',
          ),
          _HelpSection(
            icon: Icons.bar_chart,
            title: '5. Detailed Reports',
            body:
                'Tap the chart icon on the dashboard to see a visual breakdown of your money by contact. '
                'Small balances are automatically grouped into "Others" to keep the chart readable.',
          ),
          _HelpSection(
            icon: Icons.file_download_outlined,
            title: '6. PDF & CSV Exports',
            body:
                'Export a full professional report of any contact\'s ledger from the download icon in their profile. '
                'Available in PDF for sharing and CSV for Excel accounting.',
          ),
          _HelpSection(
            icon: Icons.alarm,
            title: '7. Improved Reminders',
            body:
                'Set specific dates and times for any transaction. You can now set **Recurring Reminders** '
                '(Daily, Weekly, Monthly) for regular payments like rent or EMI. One-time reminders '
                'also include an automatic 30-minute advance alert.',
          ),
          _HelpSection(
            icon: Icons.security,
            title: '8. App Security',
            body:
                'Go to the more menu (three dots) on the dashboard to "Set App PIN". This locks your data '
                'behind a 4-digit code for privacy.',
          ),
          _HelpSection(
            icon: Icons.cloud_done,
            title: '9. Google Cloud Sync',
            body:
                'Sign in with Google to securely back up your data to the cloud. This allows you to '
                'access your ledger from any device.',
          ),
          _HelpSection(
            icon: Icons.share,
            title: '10. Share Receipts',
            body:
                'Tap the share icon next to any individual transaction to send a digital payment receipt '
                'directly via WhatsApp or email.',
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _HelpSection({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
