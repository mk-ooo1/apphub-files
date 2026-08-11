import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/ledger_transaction.dart';
import '../models/contact.dart';
import '../services/ledger_service.dart';
import '../utils/theme.dart';
import 'add_transaction_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  /// Calculates the next actual due date for a recurring reminder
  DateTime _getNextDueDate(DateTime start, ReminderRepeat repeat) {
    if (repeat == ReminderRepeat.none || start.isAfter(DateTime.now())) return start;
    
    DateTime next = start;
    while (next.isBefore(DateTime.now())) {
      if (repeat == ReminderRepeat.daily) next = next.add(const Duration(days: 1));
      if (repeat == ReminderRepeat.weekly) next = next.add(const Duration(days: 7));
      if (repeat == ReminderRepeat.monthly) {
        next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final service = LedgerService();
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activeReminders)),
      body: StreamBuilder<List<LedgerContact>>(
        stream: service.watchContacts(),
        builder: (context, contactSnap) {
          if (!contactSnap.hasData) return const Center(child: CircularProgressIndicator());
          final contacts = {for (var c in contactSnap.data!) c.id: c};

          return StreamBuilder<List<LedgerTransaction>>(
            stream: service.watchPendingReminders(),
            builder: (context, txnSnap) {
              if (!txnSnap.hasData) return const Center(child: CircularProgressIndicator());
              final txns = txnSnap.data!;

              if (txns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(l10n.noReminders, style: const TextStyle(color: Colors.grey)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                        child: Text(
                          'Reminders appear here if they are scheduled for the future or set to repeat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: txns.length,
                itemBuilder: (context, i) {
                  final t = txns[i];
                  final contact = contacts[t.contactId];
                  if (contact == null) return const SizedBox.shrink();

                  final isGave = t.direction == TxnDirection.gave;
                  final nextDue = _getNextDueDate(t.reminderAt!, t.reminderRepeat);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            contact: contact,
                            direction: t.direction,
                            existing: t,
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: (isGave ? AppColors.gave : AppColors.got).withValues(alpha: 0.1),
                        child: Icon(
                          t.reminderRepeat != ReminderRepeat.none ? Icons.repeat : Icons.alarm,
                          color: isGave ? AppColors.gave : AppColors.got,
                          size: 20,
                        ),
                      ),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next Due: ${dateFmt.format(nextDue)}', 
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (t.reminderRepeat != ReminderRepeat.none)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat, size: 10, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Repeats ${t.reminderRepeat == ReminderRepeat.daily ? l10n.daily : t.reminderRepeat == ReminderRepeat.weekly ? l10n.weekly : t.reminderRepeat == ReminderRepeat.monthly ? l10n.monthly : l10n.none}', 
                                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currency.format(t.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isGave ? AppColors.gave : AppColors.got,
                              )),
                          Text(isGave ? 'Collect' : 'Pay', // Could add l10n key
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
