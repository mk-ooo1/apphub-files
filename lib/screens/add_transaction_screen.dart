import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import '../services/ledger_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final LedgerContact contact;
  final TxnDirection direction;
  final LedgerTransaction? existing; // pass this to edit instead of create
  const AddTransactionScreen({
    super.key,
    required this.contact,
    required this.direction,
    this.existing,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _amountCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.amount.toStringAsFixed(2) : '');
  late final _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late DateTime? _reminder = widget.existing?.reminderAt;
  late ReminderRepeat _repeat = widget.existing?.reminderRepeat ?? ReminderRepeat.none;
  late bool _isLocked = widget.existing?.isLocked ?? false;
  late TransactionType _type = widget.existing?.type ?? TransactionType.principal;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;
  bool get _canEdit => !_isLocked || !_isEditing;

  final _service = LedgerService();

  bool get _isGave => widget.direction == TxnDirection.gave;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context, 
      initialTime: _reminder != null ? TimeOfDay.fromDateTime(_reminder!) : TimeOfDay.now()
    );
    if (time == null) return;
    setState(() {
      _reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final txn = LedgerTransaction(
        id: widget.existing?.id ?? '',
        contactId: widget.contact.id,
        amount: double.parse(_amountCtrl.text),
        direction: widget.direction,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        date: _date,
        reminderAt: _reminder,
        reminderRepeat: _repeat,
        isLocked: _isLocked,
        type: _type,
      );

      final String id;
      if (_isEditing) {
        id = txn.id;
        await _service.updateTransaction(txn);
        await NotificationService().cancelReminder(id.hashCode);
      } else {
        id = await _service.addTransaction(txn);
      }

      if (_reminder != null) {
        try {
          await NotificationService().scheduleTransactionReminder(
            txnId: id,
            contactName: widget.contact.name,
            amount: txn.amount,
            direction: txn.direction,
            dateTime: _reminder!,
            repeat: _repeat,
          );
        } catch (e) {
          debugPrint('Failed to schedule reminder: $e');
          if (mounted) {
            String msg = 'Saved. Reminder setup failed.';
            if (e.toString().contains('exact_alarms_not_permitted')) {
              msg = 'Saved. Please enable "Alarms & Reminders" in settings for exact timing.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationService().cancelReminder(widget.existing!.id.hashCode);
    await _service.deleteTransaction(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _isGave ? AppColors.gave : AppColors.got;
    final l10n = AppLocalizations.of(context)!;
    final isBank = widget.contact.mode == ContactMode.bank;

    String appBarTitle;
    if (isBank) {
      appBarTitle = _isGave ? '${l10n.withdraw} — ${widget.contact.name}' : '${l10n.deposit} — ${widget.contact.name}';
    } else {
      appBarTitle = _isGave ? '${l10n.youWillGive} — ${widget.contact.name}' : '${l10n.youWillGet} — ${widget.contact.name}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: color,
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              enabled: _canEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: l10n.moneyManage, // Should be "Amount", but let's check if I have it in arb
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (!isBank) ...[
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(value: TransactionType.principal, label: Text(l10n.principal)),
                  ButtonSegment(value: TransactionType.interest, label: Text(l10n.interest)),
                ],
                selected: {_type},
                onSelectionChanged: _canEdit ? (s) => setState(() => _type = s.first) : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              enabled: _canEdit,
              decoration: InputDecoration(
                labelText: '${l10n.note} (${l10n.none})',
                hintText: 'e.g. Advance for order, rent, loan...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              enabled: _canEdit,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.date),
              subtitle: Text(DateFormat('d MMM yyyy').format(_date)),
              onTap: _canEdit ? _pickDate : null,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(l10n.lockedTransaction),
              subtitle: Text(l10n.lockedSubtitle),
              secondary: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.orange : null),
              value: _isLocked,
              onChanged: (v) => setState(() => _isLocked = v),
            ),
            const Divider(height: 32),
            Text(l10n.reminder, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ListTile(
              enabled: _canEdit,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
              leading: Icon(Icons.alarm, color: _reminder != null ? AppColors.primary : null),
              title: Text(l10n.reminder),
              subtitle: Text(_reminder == null
                  ? l10n.noReminders
                  : DateFormat('d MMM yyyy, h:mm a').format(_reminder!)),
              trailing: (_reminder != null && _canEdit)
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _reminder = null;
                        _repeat = ReminderRepeat.none;
                      }),
                    )
                  : null,
              onTap: _canEdit ? _pickReminder : null,
            ),
            if (_reminder != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<ReminderRepeat>(
                initialValue: _repeat,
                decoration: InputDecoration(
                  labelText: l10n.repeat,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.repeat),
                ),
                items: ReminderRepeat.values.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(r == ReminderRepeat.daily ? l10n.daily : r == ReminderRepeat.weekly ? l10n.weekly : r == ReminderRepeat.monthly ? l10n.monthly : l10n.none),
                  );
                }).toList(),
                onChanged: _canEdit ? (v) => setState(() => _repeat = v ?? ReminderRepeat.none) : null,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? l10n.update : (isBank ? (widget.direction == TxnDirection.gave ? l10n.withdraw : l10n.deposit) : l10n.save)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
