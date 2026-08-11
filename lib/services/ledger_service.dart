import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';

/// Central data access layer. All data is scoped under the signed-in user's
/// uid so multiple people can use the same Firebase project safely.
class LedgerService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _db.collection('users').doc(_uid).collection('contacts');

  CollectionReference<Map<String, dynamic>> get _txns =>
      _db.collection('users').doc(_uid).collection('transactions');

  // ---------- Contacts ----------

  Future<String> addContact(LedgerContact c) async {
    final id = c.id.isNotEmpty ? c.id : _uuid.v4();
    await _contacts.doc(id).set(c.toMap());
    return id;
  }

  Future<void> updateContact(LedgerContact c) => _contacts.doc(c.id).update(c.toMap());

  Future<void> deleteContact(String contactId) async {
    // Delete contact and all its transactions together.
    final batch = _db.batch();
    batch.delete(_contacts.doc(contactId));
    final txns = await _txns.where('contactId', isEqualTo: contactId).get();
    for (final doc in txns.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<LedgerContact>> watchContacts() {
    return _contacts.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => LedgerContact.fromMap(d.id, d.data())).toList(),
        );
  }

  // ---------- Transactions ----------

  Future<String> addTransaction(LedgerTransaction t) async {
    final id = t.id.isNotEmpty ? t.id : _uuid.v4();
    await _txns.doc(id).set(t.toMap());
    return id;
  }

  Future<void> updateTransaction(LedgerTransaction t) => _txns.doc(t.id).update(t.toMap());

  Future<void> deleteTransaction(String id) => _txns.doc(id).delete();

  Stream<List<LedgerTransaction>> watchTransactionsForContact(String contactId) {
    return _txns.where('contactId', isEqualTo: contactId).snapshots().map((snap) {
      final list = snap.docs.map((d) => LedgerTransaction.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<LedgerTransaction>> watchAllTransactions() {
    return _txns
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LedgerTransaction.fromMap(d.id, d.data())).toList());
  }

  Stream<List<LedgerTransaction>> watchPendingReminders() {
    // Show reminders that are either in the future OR are set to repeat
    return _txns
        .where('reminderAt', isNull: false)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => LedgerTransaction.fromMap(d.id, d.data())).toList();
          
          // Filter client-side: keep if in future OR if it's recurring (since it's effectively always pending)
          final filtered = list.where((t) {
            if (t.reminderAt == null) return false;
            if (t.reminderRepeat != ReminderRepeat.none) return true;
            return t.reminderAt!.isAfter(DateTime.now());
          }).toList();

          filtered.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
          return filtered;
        });
  }

  // ---------- Balance / profit-loss math ----------

  /// Balance for one contact: opening balance + sum of transaction amounts.
  static double contactBalance(LedgerContact contact, List<LedgerTransaction> txns) {
    return getContactBreakdown(contact, txns).netBalance;
  }

  /// Detailed breakdown of principal vs interest for a contact.
  static ContactBreakdown getContactBreakdown(LedgerContact contact, List<LedgerTransaction> txns) {
    double principal = contact.openingBalance;
    double interest = 0;
    double cumulativeLocked = 0;
    final isBank = contact.mode == ContactMode.bank;

    for (final t in txns) {
      if (t.isLocked) {
        cumulativeLocked += t.amount;
      }

      if (t.type == TransactionType.interest) {
        // Interest: Got (Earned) is +, Gave (Paid) is -
        interest += (t.direction == TxnDirection.got ? t.amount : -t.amount);
      } else {
        if (isBank) {
          // Bank: Got (Deposit) is +, Gave (Withdraw) is -
          principal += (t.direction == TxnDirection.got ? t.amount : -t.amount);
        } else {
          // Contact: Gave (Receivable) is +, Got (Paid back) is -
          principal += t.signedAmount;
        }
      }
    }

    return ContactBreakdown(
      principalBalance: principal,
      interestTotal: interest,
      cumulativeLocked: cumulativeLocked,
    );
  }

  /// Overall dashboard totals across all contacts.
  static DashboardTotals dashboardTotals(
    List<LedgerContact> contacts,
    Map<String, List<LedgerTransaction>> txnsByContact,
  ) {
    double toReceive = 0;
    double toPay = 0;
    for (final c in contacts) {
      final bal = contactBalance(c, txnsByContact[c.id] ?? []);
      if (bal > 0) {
        toReceive += bal;
      } else {
        toPay += -bal;
      }
    }
    return DashboardTotals(toReceive: toReceive, toPay: toPay);
  }

  /// Breakdown of net balances by category.
  static Map<String, double> categoryBreakdown(
    List<LedgerContact> contacts,
    Map<String, List<LedgerTransaction>> txnsByContact,
  ) {
    final breakdown = <String, double>{};
    for (final c in contacts) {
      final cat = c.category?.trim().isNotEmpty == true 
          ? c.category! 
          : (c.mode == ContactMode.business ? 'Business' : 'Personal');
      
      final bal = contactBalance(c, txnsByContact[c.id] ?? []);
      breakdown[cat] = (breakdown[cat] ?? 0) + bal;
    }
    return breakdown;
  }

  /// Breakdown of net balances by contact name.
  static Map<String, double> contactBreakdown(
    List<LedgerContact> contacts,
    Map<String, List<LedgerTransaction>> txnsByContact,
  ) {
    final breakdown = <String, double>{};
    for (final c in contacts) {
      final bal = contactBalance(c, txnsByContact[c.id] ?? []);
      if (bal != 0) {
        breakdown[c.name] = bal;
      }
    }
    return breakdown;
  }

  /// Calculates the live total bank balance across all "Bank" mode contacts.
  static double calculateLiveBankBalance(List<LedgerContact> allContacts, Map<String, List<LedgerTransaction>> txnsByContact) {
    double total = 0;
    final banks = allContacts.where((c) => c.mode == ContactMode.bank).toList();
    for (final b in banks) {
      total += contactBalance(b, txnsByContact[b.id] ?? []);
    }
    return total;
  }
}

class ContactBreakdown {
  final double principalBalance;
  final double interestTotal;
  final double cumulativeLocked;

  ContactBreakdown({
    required this.principalBalance,
    required this.interestTotal,
    required this.cumulativeLocked,
  });

  double get netBalance {
    if (cumulativeLocked > 0) return cumulativeLocked;
    return principalBalance + interestTotal;
  }
}

class DashboardTotals {
  final double toReceive;
  final double toPay;
  DashboardTotals({required this.toReceive, required this.toPay});

  /// Net position: positive = overall profit/receivable, negative = overall loss/payable.
  double get net => toReceive - toPay;
}
