import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import '../services/ledger_service.dart';
import '../utils/theme.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _service = LedgerService();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<LedgerContact> _selectedContacts = [];
  bool _includeMe = true;
  bool _saving = false;

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _saving = true);

    final totalParticipants = _selectedContacts.length + (_includeMe ? 1 : 0);
    final sharePerPerson = amount / totalParticipants;
    final note = _noteCtrl.text.trim();
    final displayNote = note.isEmpty ? 'Split Bill' : note;

    for (final contact in _selectedContacts) {
      final txn = LedgerTransaction(
        id: '',
        contactId: contact.id,
        amount: sharePerPerson,
        direction: TxnDirection.gave, // Current user gave money (paid for them)
        note: '$displayNote (Split share)',
        date: DateTime.now(),
      );
      await _service.addTransaction(txn);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Split bill of ${_currency.format(amount)} among $totalParticipants people')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitBill)),
      body: StreamBuilder<List<LedgerContact>>(
        stream: _service.watchContacts(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final contacts = snap.data!;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Total Bill Amount',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              labelText: '${l10n.note} (${l10n.none})',
                              hintText: 'Dinner, Movie, Rent...',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text('Include my share in division'),
                            subtitle: const Text('Check this if you also participated in the expense'),
                            value: _includeMe,
                            onChanged: (v) => setState(() => _includeMe = v ?? true),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Select Contacts to Split With:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (contacts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: Text(l10n.noContacts)),
                      )
                    else
                      ...contacts.map((c) {
                        final isSelected = _selectedContacts.any((sc) => sc.id == c.id);
                        return CheckboxListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedContacts.add(c);
                              } else {
                                _selectedContacts.removeWhere((sc) => sc.id == c.id);
                              }
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.splitBill, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
