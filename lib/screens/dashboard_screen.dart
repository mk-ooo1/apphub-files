import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import '../services/ledger_service.dart';
import '../utils/theme.dart';
import 'contact_detail_screen.dart';
import 'add_contact_screen.dart';
import 'help_screen.dart';
import 'reports_screen.dart';
import 'pin_lock_screen.dart';
import 'split_bill_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import '../services/security_service.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = LedgerService();
  ContactMode? _filter; // null = show all (both)
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.moneyManage),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              tooltip: l10n.reminders,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: l10n.reports,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'How to use',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settings,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'security') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinLockScreen(
                        setupMode: true,
                        onUnlocked: () => Navigator.pop(context),
                      ),
                    ),
                  );
                } else if (v == 'clear_pin') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.clearPin),
                      content: Text(l10n.clearPinWarning),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await SecurityService().clearPin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.settled)),
                      );
                    }
                  }
                } else if (v == 'logout') {
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'security', child: Text('Set App PIN')),
                PopupMenuItem(value: 'clear_pin', child: Text('Clear App PIN')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.contacts),
              Tab(text: l10n.account),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _ContactsTab(
              service: _service,
              filter: _filter,
              search: _search,
              onFilterChanged: (v) => setState(() => _filter = v),
              onSearchChanged: (v) => setState(() => _search = v),
            ),
            _AccountTab(service: _service),
          ],
        ),
        floatingActionButton: Builder(builder: (context) {
          final tabController = DefaultTabController.of(context);
          return ListenableBuilder(
            listenable: tabController,
            builder: (context, _) {
              final isAccountTab = tabController.index == 1;

              if (isAccountTab) {
                return FloatingActionButton.extended(
                  heroTag: 'add_bank',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddContactScreen(forcedMode: ContactMode.bank)),
                  ),
                  icon: const Icon(Icons.account_balance),
                  label: Text(l10n.addBank),
                  backgroundColor: AppColors.primary,
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'split',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SplitBillScreen()),
                    ),
                    icon: const Icon(Icons.call_split),
                    label: Text(l10n.splitBill),
                    backgroundColor: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'add_contact',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddContactScreen()),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: Text(l10n.addContact),
                    backgroundColor: AppColors.primary,
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  final LedgerService service;
  final ContactMode? filter;
  final String search;
  final Function(ContactMode?) onFilterChanged;
  final Function(String) onSearchChanged;

  const _ContactsTab({
    required this.service,
    required this.filter,
    required this.search,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<LedgerContact>>(
      stream: service.watchContacts(),
      builder: (context, contactSnap) {
        if (!contactSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // FILTER: Hide Banks from the Contacts list
        var contacts = contactSnap.data!.where((c) => c.mode != ContactMode.bank).toList();

        if (filter != null) {
          contacts = contacts.where((c) => c.mode == filter).toList();
        }
        if (search.isNotEmpty) {
          contacts = contacts
              .where((c) => c.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        return StreamBuilder<List<LedgerTransaction>>(
          stream: service.watchAllTransactions(),
          builder: (context, txnSnap) {
            final allTxns = txnSnap.data ?? [];
            final byContact = <String, List<LedgerTransaction>>{};
            for (final t in allTxns) {
              byContact.putIfAbsent(t.contactId, () => []).add(t);
            }
            final totals = LedgerService.dashboardTotals(contacts, byContact);

            return Column(
              children: [
                _SummaryCard(totals: totals),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.searchContacts,
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<ContactMode?>(
                        icon: const Icon(Icons.filter_list, color: AppColors.primary),
                        onSelected: onFilterChanged,
                        itemBuilder: (_) => [
                          PopupMenuItem(value: null, child: Text(l10n.allContacts)),
                          PopupMenuItem(value: ContactMode.personal, child: Text(l10n.personal)),
                          PopupMenuItem(value: ContactMode.business, child: Text(l10n.business)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: contacts.isEmpty
                      ? Center(child: Text(l10n.noContacts))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 100),
                          itemCount: contacts.length,
                          itemBuilder: (context, i) {
                            final c = contacts[i];
                            final bal = LedgerService.contactBalance(
                                c, byContact[c.id] ?? []);
                            return _ContactTile(contact: c, balance: bal);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AccountTab extends StatefulWidget {
  final LedgerService service;
  const _AccountTab({required this.service});

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  String _search = '';
  TxnDirection? _directionFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<LedgerContact>>(
      stream: widget.service.watchContacts(),
      builder: (context, contactSnap) {
        final allContacts = contactSnap.data ?? [];
        final banks = allContacts.where((c) => c.mode == ContactMode.bank).toList();

        return StreamBuilder<List<LedgerTransaction>>(
          stream: widget.service.watchAllTransactions(),
          builder: (context, txnSnap) {
            var allTxns = txnSnap.data ?? [];

            // Organize transactions by contact for balance math
            final byContact = <String, List<LedgerTransaction>>{};
            for (final t in allTxns) {
              byContact.putIfAbsent(t.contactId, () => []).add(t);
            }

            final liveTotalBalance = LedgerService.calculateLiveBankBalance(allContacts, byContact);

            if (_search.isNotEmpty) {
              final query = _search.toLowerCase();
              allTxns = allTxns.where((t) {
                final contact = allContacts.firstWhere(
                  (c) => c.id == t.contactId,
                  orElse: () => LedgerContact(
                      id: '',
                      name: 'Unknown',
                      phone: '',
                      mode: ContactMode.personal,
                      createdAt: DateTime.now()),
                );
                final matchesName = contact.name.toLowerCase().contains(query);
                final matchesNote = (t.note ?? '').toLowerCase().contains(query);
                return matchesName || matchesNote;
              }).toList();
            }

            if (_directionFilter != null) {
              allTxns = allTxns.where((t) => t.direction == _directionFilter).toList();
            }

            return Column(
              children: [
                _BankBalanceCard(balance: liveTotalBalance),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('My Banks',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700)),
                      const Spacer(),
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: banks.isEmpty
                      ? const Center(
                          child: Text('No banks',
                              style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: banks.length,
                          itemBuilder: (context, i) {
                            final b = banks[i];
                            final bal = LedgerService.contactBalance(
                                b, byContact[b.id] ?? []);
                            return _BankMiniTile(contact: b, balance: bal);
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(l10n.allTransactions,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700)),
                      const Spacer(),
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.searchTxn,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      PopupMenuButton<TxnDirection?>(
                        icon: Icon(Icons.filter_list, 
                          color: _directionFilter == null ? Colors.grey : AppColors.primary),
                        onSelected: (v) => setState(() => _directionFilter = v),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: null, child: Text(l10n.all)),
                          PopupMenuItem(value: TxnDirection.gave, child: Text(l10n.gave)),
                          PopupMenuItem(value: TxnDirection.got, child: Text(l10n.got)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: allTxns.isEmpty
                      ? const Center(child: Text('No transactions yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: allTxns.length,
                          itemBuilder: (context, i) {
                            final t = allTxns[i];
                            final contact = allContacts.firstWhere(
                                (c) => c.id == t.contactId,
                                orElse: () => LedgerContact(
                                    id: '',
                                    name: 'Unknown',
                                    phone: '',
                                    mode: ContactMode.personal,
                                    createdAt: DateTime.now()));
                            return _GlobalTransactionTile(
                              txn: t,
                              contactName: contact.name,
                              isBankTxn: contact.mode == ContactMode.bank,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BankMiniTile extends StatelessWidget {
  final LedgerContact contact;
  final double balance;
  const _BankMiniTile({required this.contact, required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReceivable = balance >= 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(contact.name, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              _currency.format(balance.abs()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: balance == 0 ? Colors.grey : (isReceivable ? AppColors.got : AppColors.gave),
              ),
            ),
            Text(
              balance == 0 ? l10n.settled : (isReceivable ? l10n.currentBalance : l10n.lossBalance),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalTransactionTile extends StatelessWidget {
  final LedgerTransaction txn;
  final String contactName;
  final bool isBankTxn;
  const _GlobalTransactionTile({required this.txn, required this.contactName, required this.isBankTxn});

  @override
  Widget build(BuildContext context) {
    final isGot = txn.direction == TxnDirection.got;
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: (isGot ? AppColors.got : AppColors.gave).withValues(alpha: 0.1),
          child: Icon(
            isGot ? Icons.arrow_downward : Icons.arrow_upward,
            color: isGot ? AppColors.got : AppColors.gave,
            size: 16,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(contactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Text(
              '${isGot ? "+" : "-"} ${_currency.format(txn.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isGot ? AppColors.got : AppColors.gave,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(dateFmt.format(txn.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (isBankTxn) ...[
              const SizedBox(width: 6),
              const Icon(Icons.account_balance, size: 10, color: Colors.blue),
            ],
            if (txn.type == TransactionType.interest) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: const Text('INT', style: TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
            const Spacer(),
            if (txn.note != null)
              Expanded(
                child: Text(
                  txn.note!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BankBalanceCard extends StatelessWidget {
  final double balance;
  const _BankBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.totalBankBalance, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Icon(Icons.account_balance, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DashboardTotals totals;
  const _SummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totals.net >= 0 ? l10n.netProfit : l10n.netLoss,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            _currency.format(totals.net.abs()),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l10n.youWillGet,
                  value: totals.toReceive,
                  color: Colors.white,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _MiniStat(
                  label: l10n.youWillGive,
                  value: totals.toPay,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
              icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
              label: Text(l10n.reports, style: const TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
          Text(_currency.format(value),
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final LedgerContact contact;
  final double balance;
  const _ContactTile({required this.contact, required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReceivable = balance >= 0;
    final isBank = contact.mode == ContactMode.bank;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isBank ? l10n.bank : (contact.mode == ContactMode.business ? (contact.category ?? l10n.business) : l10n.personal)
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currency.format(balance.abs()),
              style: TextStyle(
                color: balance == 0 ? Colors.grey : (isReceivable ? AppColors.got : AppColors.gave),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              balance == 0 ? l10n.settled : (
                isBank 
                ? (isReceivable ? l10n.currentBalance : l10n.lossBalance)
                : (isReceivable ? l10n.youWillGet : l10n.youWillGive)
              ),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
