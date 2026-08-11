import 'package:cloud_firestore/cloud_firestore.dart';

enum TxnDirection { gave, got }

enum TransactionType { principal, interest }

enum ReminderRepeat { none, daily, weekly, monthly }

class LedgerTransaction {
  final String id;
  final String contactId;
  final double amount;
  final TxnDirection direction;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final DateTime? reminderAt;
  final ReminderRepeat reminderRepeat;
  final bool reminderFired;
  final String? photoUrl;
  final bool isLocked;

  LedgerTransaction({
    required this.id,
    required this.contactId,
    required this.amount,
    required this.direction,
    this.type = TransactionType.principal,
    this.note,
    required this.date,
    this.reminderAt,
    this.reminderRepeat = ReminderRepeat.none,
    this.reminderFired = false,
    this.photoUrl,
    this.isLocked = false,
  });

  double get signedAmount => direction == TxnDirection.gave ? amount : -amount;

  Map<String, dynamic> toMap() => {
        'contactId': contactId,
        'amount': amount,
        'direction': direction.name,
        'type': type.name,
        'note': note,
        'date': Timestamp.fromDate(date),
        'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
        'reminderRepeat': reminderRepeat.name,
        'reminderFired': reminderFired,
        'photoUrl': photoUrl,
        'isLocked': isLocked,
      };

  factory LedgerTransaction.fromMap(String id, Map<String, dynamic> map) {
    return LedgerTransaction(
      id: id,
      contactId: map['contactId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      direction: map['direction'] == 'got' ? TxnDirection.got : TxnDirection.gave,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'principal'),
        orElse: () => TransactionType.principal,
      ),
      note: map['note'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reminderAt: (map['reminderAt'] as Timestamp?)?.toDate(),
      reminderRepeat: ReminderRepeat.values.firstWhere(
        (e) => e.name == (map['reminderRepeat'] ?? 'none'),
        orElse: () => ReminderRepeat.none,
      ),
      reminderFired: map['reminderFired'] ?? false,
      photoUrl: map['photoUrl'],
      isLocked: map['isLocked'] ?? false,
    );
  }
}
