import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/ledger_service.dart';
import '../models/user_profile.dart';
import '../models/subscription_plan.dart';
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
  late TextEditingController _upiCtrl;
  late TextEditingController _waCtrl;
  late List<SubscriptionPlan> _plans;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: widget.currentConfig.updateMessage);
    _urlCtrl = TextEditingController(text: widget.currentConfig.updateUrl);
    _pwdCtrl = TextEditingController(text: widget.currentConfig.adminPassword);
    _upiCtrl = TextEditingController(text: widget.currentConfig.upiId);
    _waCtrl = TextEditingController(text: widget.currentConfig.adminWhatsApp);
    _plans = List.from(widget.currentConfig.plans);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _urlCtrl.dispose();
    _pwdCtrl.dispose();
    _upiCtrl.dispose();
    _waCtrl.dispose();
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
        upiId: _upiCtrl.text.trim(),
        adminWhatsApp: _waCtrl.text.trim(),
        plans: _plans,
      );
      await AdminService().updateConfig(newConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App configuration updated successfully')),
        );
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

  void _addPlan() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final daysCtrl = TextEditingController();
        final priceCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Monthly)')),
              TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Days'), keyboardType: TextInputType.number),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final days = int.tryParse(daysCtrl.text) ?? 30;
                final price = double.tryParse(priceCtrl.text) ?? 99;
                setState(() {
                  _plans.add(SubscriptionPlan(name: nameCtrl.text, days: days, price: price));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hidden Admin Panel'),
          backgroundColor: Colors.red.shade800,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'App Config'),
              Tab(text: 'Manage Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildConfigTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigTab() {
    return Form(
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
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Premium Setup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextButton.icon(onPressed: _addPlan, icon: const Icon(Icons.add), label: const Text('Add Plan')),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _upiCtrl,
            decoration: const InputDecoration(
              labelText: 'Your UPI ID (Receiving Account)',
              border: OutlineInputBorder(),
              hintText: 'mk@ybl',
            ),
            validator: (v) => v == null || v.isEmpty ? 'Cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _waCtrl,
            decoration: const InputDecoration(
              labelText: 'Admin WhatsApp Number (with Country Code)',
              border: OutlineInputBorder(),
              hintText: '919876543210',
            ),
            validator: (v) => v == null || v.isEmpty ? 'Cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          if (_plans.isEmpty) const Text('No plans added.', style: TextStyle(color: Colors.grey)),
          ..._plans.map((p) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.name),
            subtitle: Text('${p.days} Days - ₹${p.price}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _plans.remove(p)),
            ),
          )),
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
    );
  }

  Widget _buildUsersTab() {
    final dateFmt = DateFormat('d MMM yy');
    
    return StreamBuilder<List<UserProfile>>(
      stream: LedgerService().watchAllUserProfiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: Ensure Firebase Rules allow admin access.\n${snapshot.error}', textAlign: TextAlign.center));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final users = snapshot.data!;
        if (users.isEmpty) return const Center(child: Text('No users found.'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isActive = user.isPremiumActive;
            final isPending = user.pendingRequestPlan != null;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                child: Icon(isActive ? Icons.star : Icons.person, color: isActive ? Colors.amber : Colors.grey),
              ),
              title: Row(
                children: [
                  Text(user.name),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Requested', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  Text('UID: ${user.uid}', style: const TextStyle(fontSize: 9, color: Colors.grey)), // Debug info
                  if (isPending) 
                    Text('Plan: ${user.pendingRequestPlan}', style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  if (user.premiumUntil != null)
                    Text(
                      isActive ? 'Active till: ${dateFmt.format(user.premiumUntil!)}' : 'Expired on: ${dateFmt.format(user.premiumUntil!)}',
                      style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              isThreeLine: user.premiumUntil != null || isPending,
              trailing: PopupMenuButton<int>(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                tooltip: 'Grant Premium Days',
                onSelected: (days) async {
                  if (days == -1) {
                    await LedgerService().revokePremium(user.uid);
                  } else {
                    await LedgerService().grantPremiumDays(user.uid, days);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated.')));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 30, child: Text('+ 30 Days')),
                  const PopupMenuItem(value: 90, child: Text('+ 90 Days')),
                  const PopupMenuItem(value: 365, child: Text('+ 365 Days')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: -1, child: Text('Revoke / Reject', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
        );
      }
    );
  }
}
