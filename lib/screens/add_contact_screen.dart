import 'package:flutter/material.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/contact.dart';
import '../services/ledger_service.dart';

class AddContactScreen extends StatefulWidget {
  final LedgerContact? existing; // pass this to edit instead of create
  final ContactMode? forcedMode;

  const AddContactScreen({super.key, this.existing, this.forcedMode});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  late final _categoryCtrl = TextEditingController(text: widget.existing?.category ?? '');
  late final _openingCtrl =
      TextEditingController(text: (widget.existing?.openingBalance ?? 0).toString());
  late ContactMode _mode = widget.forcedMode ?? widget.existing?.mode ?? ContactMode.personal;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  final _service = LedgerService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final contact = LedgerContact(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      mode: _mode,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      openingBalance: double.tryParse(_openingCtrl.text) ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (_isEditing) {
      await _service.updateContact(contact);
    } else {
      await _service.addContact(contact);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editContact : (_mode == ContactMode.bank ? l10n.addBank : l10n.addContact))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.forcedMode == null && !_isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SegmentedButton<ContactMode>(
                  segments: [
                    ButtonSegment(value: ContactMode.personal, label: Text(l10n.personal)),
                    ButtonSegment(value: ContactMode.business, label: Text(l10n.business)),
                    ButtonSegment(value: ContactMode.bank, label: Text(l10n.bank)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: _mode == ContactMode.bank ? l10n.bankName : l10n.name, 
                border: const OutlineInputBorder()
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? '${_mode == ContactMode.bank ? l10n.bankName : l10n.name} is required' : null,
            ),
            if (_mode != ContactMode.bank) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: '${l10n.phone} (for WhatsApp)', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: _mode == ContactMode.business ? '${l10n.category} (Supplier/Customer)' : 'Relation (Friend/Family)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _openingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: _mode == ContactMode.bank ? 'Starting Bank Balance' : 'Opening balance (+ they owe you, - you owe them)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? l10n.update : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
