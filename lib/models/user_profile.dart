import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final DateTime? premiumUntil;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.premiumUntil,
  });

  bool get isPremiumActive => premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'premiumUntil': premiumUntil != null ? Timestamp.fromDate(premiumUntil!) : null,
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    DateTime? exp;
    if (map['premiumUntil'] != null) {
      exp = (map['premiumUntil'] as Timestamp).toDate();
    } else if (map['isPremium'] == true) {
      exp = DateTime.now().add(const Duration(days: 365)); // Legacy fallback
    }

    return UserProfile(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? 'User',
      premiumUntil: exp,
    );
  }
}
