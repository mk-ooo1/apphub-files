import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminConfig {
  final String updateMessage;
  final String updateUrl;
  final String adminPassword;

  AdminConfig({
    required this.updateMessage,
    required this.updateUrl,
    required this.adminPassword,
  });

  factory AdminConfig.fromMap(Map<String, dynamic> map) {
    return AdminConfig(
      updateMessage: map['updateMessage'] ?? 'New version available! Update now for best experience.',
      updateUrl: map['updateUrl'] ?? 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
      adminPassword: map['adminPassword'] ?? 'admin123', // Default fallback password
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'updateMessage': updateMessage,
      'updateUrl': updateUrl,
      'adminPassword': adminPassword,
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
          updateMessage: 'Update the app to the latest version.',
          updateUrl: 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
          adminPassword: 'admin123',
        );
      }
      return AdminConfig.fromMap(snap.data()!);
    });
  }

  Future<AdminConfig> getConfig() async {
    final snap = await _configDoc.get();
    if (!snap.exists || snap.data() == null) {
      return AdminConfig(
        updateMessage: 'Update the app to the latest version.',
        updateUrl: 'https://github.com/mk-ooo1/apphub-files/raw/main/money-manage/money-manage-latest.apk',
        adminPassword: 'admin123',
      );
    }
    return AdminConfig.fromMap(snap.data()!);
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
