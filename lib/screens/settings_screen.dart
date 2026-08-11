import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import '../services/user_prefs_provider.dart';
import '../utils/theme.dart';
import 'legal_screen.dart';
import 'pin_lock_screen.dart';
import '../services/security_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.selectLanguage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('English'),
                trailing: localeProvider.locale?.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिन्दी (Hindi)'),
                trailing: localeProvider.locale?.languageCode == 'hi' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('मराठी (Marathi)'),
                trailing: localeProvider.locale?.languageCode == 'mr' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('mr'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTimezonePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserPrefsProvider>(context, listen: false);

    final zones = [
      {'label': 'India (IST)', 'value': 'Asia/Kolkata'},
      {'label': 'Universal (UTC)', 'value': 'UTC'},
      {'label': 'Dubai (GST)', 'value': 'Asia/Dubai'},
      {'label': 'USA (Eastern)', 'value': 'America/New_York'},
      {'label': 'USA (Pacific)', 'value': 'America/Los_Angeles'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.selectTimezone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...zones.map((z) => ListTile(
                title: Text(z['label']!),
                subtitle: Text(z['value']!),
                trailing: prefs.timezone == z['value'] ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  prefs.setTimezone(z['value']!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Timezone updated. Restart app for full effect.')),
                  );
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          if (user != null)
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              accountName: Text(user.displayName ?? 'User'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
              ),
              decoration: const BoxDecoration(color: AppColors.primary),
            ),
          
          const _SectionHeader(title: 'App Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              Provider.of<LocaleProvider>(context).locale?.languageCode == 'hi' ? 'हिन्दी' : 
              Provider.of<LocaleProvider>(context).locale?.languageCode == 'mr' ? 'मराठी' : 'English'
            ),
            onTap: () => _showLanguagePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.timezone),
            subtitle: Text(Provider.of<UserPrefsProvider>(context).timezone),
            onTap: () => _showTimezonePicker(context),
          ),

          const _SectionHeader(title: 'Account & Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Set App PIN'),
            subtitle: const Text('Protect your data with a 4-digit code'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PinLockScreen(
                  setupMode: true,
                  onUnlocked: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Clear App PIN'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.clearPin),
                  content: Text(l10n.clearPinWarning),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await SecurityService().clearPin();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App PIN cleared')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),

          const _SectionHeader(title: 'Support & Feedback'),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Invite Friends'),
            subtitle: const Text('Share Money Manage with others'),
            onTap: () {
              Share.share('Check out Money Manage App to track your daily transactions easily! Download now.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate the App'),
            onTap: () {
              // Replace with your Play Store link when ready
              // launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.MKDevOps.moneyManage'));
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact Support'),
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'bg00998835@gmail.com',
                query: 'subject=Money Manage App Support',
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not find an email app')),
                  );
                }
              }
            },
          ),

          const _SectionHeader(title: 'Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Privacy Policy',
                  content: LegalTexts.privacyPolicy,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms and Conditions'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Terms and Conditions',
                  content: LegalTexts.termsAndConditions,
                ),
              ),
            ),
          ),

          const _SectionHeader(title: 'About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              final build = snapshot.data?.buildNumber ?? '1';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                subtitle: Text('v$version (Build $build)'),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.developer_mode),
            title: Text('Developer'),
            subtitle: Text('MKDevOps'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
