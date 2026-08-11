import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactMode { personal, business, bank }

class LedgerContact {
  final String id;
  final String name;
  final String phone;
  final ContactMode mode;
  final String? category; // e.g. "Supplier", "Friend", "Customer"
  final double openingBalance; // +ve = they owe you, -ve = you owe them
  final DateTime createdAt;
  final String? photoUrl;

  LedgerContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.mode,
    this.category,
    this.openingBalance = 0,
    required this.createdAt,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'mode': mode.name,
        'category': category,
        'openingBalance': openingBalance,
        'createdAt': Timestamp.fromDate(createdAt),
        'photoUrl': photoUrl,
      };

  factory LedgerContact.fromMap(String id, Map<String, dynamic> map) {
    return LedgerContact(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      mode: ContactMode.values.firstWhere(
        (e) => e.name == (map['mode'] ?? 'personal'),
        orElse: () => ContactMode.personal,
      ),
      category: map['category'],
      openingBalance: (map['openingBalance'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'],
    );
  }
}
