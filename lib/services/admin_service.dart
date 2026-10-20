import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';

class AdminConfig {
  final String updateMessage;
  final String updateUrl;
  final String adminPassword;
  final String upiId;
  final String adminWhatsApp;
  final List<SubscriptionPlan> plans;

  AdminConfig({
    required this.updateMessage,
    required this.updateUrl,
    required this.adminPassword,
    required this.upiId,
    required this.adminWhatsApp,
    required this.plans,
  });

  factory AdminConfig.fromMap(Map<String, dynamic> map) {
    return AdminConfig(
      updateMessage: map['updateMessage'] ?? 'New version available! Update now for best experience.',
      updateUrl: map['updateUrl'] ?? 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
      adminPassword: map['adminPassword'] ?? 'admin123',
      upiId: map['upiId'] ?? 'your_upi_id@ybl',
      adminWhatsApp: map['adminWhatsApp'] ?? '919876543210',
      plans: map['plans'] != null 
          ? (map['plans'] as List).map((p) => SubscriptionPlan.fromMap(p)).toList()
          : [
              SubscriptionPlan(name: 'Monthly', days: 30, price: 99),
              SubscriptionPlan(name: 'Yearly', days: 365, price: 999),
            ],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'updateMessage': updateMessage,
      'updateUrl': updateUrl,
      'adminPassword': adminPassword,
      'upiId': upiId,
      'adminWhatsApp': adminWhatsApp,
      'plans': plans.map((p) => p.toMap()).toList(),
    };
  }
}

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final _db = FirebaseFirestore.instance;

  // We use a single, global document for app configuration.
  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _db.collection('admin').doc('config');

  Stream<AdminConfig> watchConfig() {
    return _configDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        // Return default config if doc doesn't exist yet
        return AdminConfig(
          updateMessage: 'New version available! Update now for best experience.',
          updateUrl: 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
          adminPassword: 'admin123',
          upiId: 'your_upi_id@ybl',
          adminWhatsApp: '919876543210',
          plans: [
            SubscriptionPlan(name: 'Monthly', days: 30, price: 99),
            SubscriptionPlan(name: 'Yearly', days: 365, price: 999),
          ],
        );
      }
      return AdminConfig.fromMap(snap.data()!);
    });
  }

  Future<AdminConfig> getConfig() async {
    try {
      final snap = await _configDoc.get();
      if (!snap.exists || snap.data() == null) {
        return AdminConfig(
          updateMessage: 'New version available! Update now for best experience.',
          updateUrl: 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
          adminPassword: 'admin123',
          upiId: 'your_upi_id@ybl',
          adminWhatsApp: '919876543210',
          plans: [
            SubscriptionPlan(name: 'Monthly', days: 30, price: 99),
            SubscriptionPlan(name: 'Yearly', days: 365, price: 999),
          ],
        );
      }
      return AdminConfig.fromMap(snap.data()!);
    } catch (e) {
      debugPrint('Error getting admin config: $e');
      // Fallback in case of permission or network errors
      return AdminConfig(
        updateMessage: 'New version available! Update now for best experience.',
        updateUrl: 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
        adminPassword: 'admin123',
        upiId: 'your_upi_id@ybl',
        adminWhatsApp: '919876543210',
        plans: [
          SubscriptionPlan(name: 'Monthly', days: 30, price: 99),
          SubscriptionPlan(name: 'Yearly', days: 365, price: 999),
        ],
      );
    }
  }

  Future<void> updateConfig(AdminConfig config) async {
    try {
      await _configDoc.set(config.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating admin config: $e');
      rethrow;
    }
  }
}
