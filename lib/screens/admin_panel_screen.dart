import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../utils/theme.dart';

class AdminPanelScreen extends StatefulWidget {
  final AdminConfig currentConfig;
  const AdminPanelScreen({super.key, required this.currentConfig});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _msgCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _pwdCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: widget.currentConfig.updateMessage);
    _urlCtrl = TextEditingController(text: widget.currentConfig.updateUrl);
    _pwdCtrl = TextEditingController(text: widget.currentConfig.adminPassword);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _urlCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    try {
      final newConfig = AdminConfig(
        updateMessage: _msgCtrl.text.trim(),
        updateUrl: _urlCtrl.text.trim(),
        adminPassword: _pwdCtrl.text.trim(),
      );
      await AdminService().updateConfig(newConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App configuration updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Admin Panel'),
        backgroundColor: Colors.red.shade800,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'App Update Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Update Message (shown to users)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Update URL (APK link)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                if (!v.startsWith('http')) return 'Must be a valid URL';
                return null;
              },
            ),
            const Divider(height: 48),
            const Text(
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pwdCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                if (v.length < 4) return 'Password must be at least 4 characters';
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _saving ? null : _save,
              child: _saving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Apply Globally'),
            ),
          ],
        ),
      ),
    );
  }
}
