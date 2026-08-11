import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'services/notification_service.dart';
import 'services/locale_provider.dart';
import 'services/user_prefs_provider.dart';
import 'services/security_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/pin_lock_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserPrefsProvider()),
      ],
      child: const MoneyManageApp(),
    ),
  );
}

class MoneyManageApp extends StatelessWidget {
  const MoneyManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Money Manage',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // One single entry point that manages app state
      home: const AppContentSwitcher(),
    );
  }
}

class AppContentSwitcher extends StatefulWidget {
  const AppContentSwitcher({super.key});

  @override
  State<AppContentSwitcher> createState() => _AppContentSwitcherState();
}

class _AppContentSwitcherState extends State<AppContentSwitcher> {
  bool _initialized = false;
  bool _unlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final prefs = Provider.of<UserPrefsProvider>(context, listen: false);

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await NotificationService().init(timeZoneName: prefs.timezone);
      
      // Check if PIN is set
      final hasPin = await SecurityService().hasPin();
      if (!hasPin) {
        _unlocked = true;
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text('Startup Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _initApp, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Security Gate
    if (!_unlocked) {
      return PinLockScreen(
        onUnlocked: () => setState(() => _unlocked = true),
      );
    }

    // Auth Gate
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (authSnap.hasData) {
          return const DashboardScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
