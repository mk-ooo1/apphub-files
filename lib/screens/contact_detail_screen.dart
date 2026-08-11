import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import '../services/ledger_service.dart';
import '../services/receipt_service.dart';
import '../utils/theme.dart';
import 'add_transaction_screen.dart';
import 'add_contact_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _dateFmt = DateFormat('d MMM yyyy, h:mm a');

class ContactDetailScreen extends StatefulWidget {
  final LedgerContact contact;
  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final _service = LedgerService();

  Future<void> _shareReceipt(LedgerTransaction txn, double currentTabBalance) async {
    final file = await ReceiptService.buildTransactionReceipt(
      contact: widget.contact,
      txn: txn,
      runningBalance: currentTabBalance,
    );
    await ReceiptService.shareReceipt(
      file,
      text: 'Receipt for ${widget.contact.name} — ${_currency.format(txn.amount)}',
    );
  }

  Future<void> _deleteTxn(String id) async {
    await _service.deleteTransaction(id);
  }

  Future<void> _exportLedger(List<LedgerTransaction> txns, bool isPdf) async {
    final chronological = txns.reversed.toList();
    final File file;
    if (isPdf) {
      file = await ReceiptService.buildFullLedgerPdf(
        contact: widget.contact,
        txns: chronological,
      );
    } else {
      file = await ReceiptService.generateLedgerCsv(
        contact: widget.contact,
        txns: chronological,
      );
    }
    await ReceiptService.shareReceipt(file, text: 'Money report for ${widget.contact.name}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBank = widget.contact.mode == ContactMode.bank;

    Widget content(List<LedgerTransaction> txns) {
      final breakdown = LedgerService.getContactBreakdown(widget.contact, txns);
      final chronological = txns.reversed.toList();
      
      double pRunning = widget.contact.openingBalance;
      double iRunning = 0;
      final pRunningAfter = <String, double>{};
      final iRunningAfter = <String, double>{};

      for (final t in chronological) {
        if (t.type == TransactionType.interest) {
          iRunning += (t.direction == TxnDirection.got ? t.amount : -t.amount);
          iRunningAfter[t.id] = iRunning;
        } else {
          if (isBank) {
            pRunning += (t.direction == TxnDirection.got ? t.amount : -t.amount);
          } else {
            pRunning += t.signedAmount;
          }
          pRunningAfter[t.id] = pRunning;
        }
      }

      if (isBank) {
        // Simple list for Banks (no tabs)
        return _TransactionListView(
          txns: txns,
          contact: widget.contact,
          breakdown: breakdown,
          runningAfter: pRunningAfter, 
          onDelete: _deleteTxn,
          onShare: _shareReceipt,
          title: 'Bank Transactions',
          tabType: _TabType.principal,
        );
      }

      // 2-tab view for Personal/Business
      final principalTxns = txns.where((t) => t.type == TransactionType.principal).toList();
      final interestTxns = txns.where((t) => t.type == TransactionType.interest).toList();

      return TabBarView(
        children: [
          _TransactionListView(
            txns: principalTxns,
            contact: widget.contact,
            breakdown: breakdown,
            runningAfter: pRunningAfter,
            onDelete: _deleteTxn,
            onShare: _shareReceipt,
            title: l10n.principalTransactions,
            tabType: _TabType.principal,
          ),
          _TransactionListView(
            txns: interestTxns,
            contact: widget.contact,
            breakdown: breakdown,
            runningAfter: iRunningAfter,
            onDelete: _deleteTxn,
            onShare: _shareReceipt,
            title: l10n.interestRecords,
            tabType: _TabType.interest,
          ),
        ],
      );
    }

    return StreamBuilder<List<LedgerTransaction>>(
      stream: _service.watchTransactionsForContact(widget.contact.id),
      builder: (context, snap) {
        final txns = snap.data ?? [];

        if (isBank) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.contact.name),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: l10n.exportReport,
                  onSelected: (v) => _exportLedger(txns, v == 'pdf'),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
                    PopupMenuItem(value: 'csv', child: Text(l10n.exportCsv)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editContact,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddContactScreen(existing: widget.contact)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteContact),
                        content: Text(l10n.deleteContactWarning(widget.contact.name)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _service.deleteContact(widget.contact.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            body: content(txns),
            floatingActionButton: _buildFAB(l10n),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.contact.name),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: l10n.exportReport,
                  onSelected: (v) => _exportLedger(txns, v == 'pdf'),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
                    PopupMenuItem(value: 'csv', child: Text(l10n.exportCsv)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editContact,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddContactScreen(existing: widget.contact)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteContact),
                        content: Text(l10n.deleteContactWarning(widget.contact.name)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _service.deleteContact(widget.contact.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.generalPrincipal),
                  Tab(text: l10n.interestAccount),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
              ),
            ),
            body: content(txns),
            floatingActionButton: _buildFAB(l10n),
          ),
        );
      },
    );
  }

  Widget _buildFAB(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'gave',
          backgroundColor: AppColors.gave,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                contact: widget.contact,
                direction: TxnDirection.gave,
              ),
            ),
          ),
          label: Text(widget.contact.mode == ContactMode.bank ? l10n.withdraw : l10n.gave),
          icon: Icon(widget.contact.mode == ContactMode.bank ? Icons.remove : Icons.arrow_upward),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.extended(
          heroTag: 'got',
          backgroundColor: AppColors.got,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                contact: widget.contact,
                direction: TxnDirection.got,
              ),
            ),
          ),
          label: Text(widget.contact.mode == ContactMode.bank ? l10n.deposit : l10n.got),
          icon: Icon(widget.contact.mode == ContactMode.bank ? Icons.add : Icons.arrow_downward),
        ),
      ],
    );
  }
}

enum _TabType { principal, interest }

class _TransactionListView extends StatefulWidget {
  final List<LedgerTransaction> txns;
  final LedgerContact contact;
  final ContactBreakdown breakdown;
  final Map<String, double> runningAfter;
  final Function(String) onDelete;
  final Function(LedgerTransaction, double) onShare;
  final String title;
  final _TabType tabType;

  const _TransactionListView({
    required this.txns,
    required this.contact,
    required this.breakdown,
    required this.runningAfter,
    required this.onDelete,
    required this.onShare,
    required this.title,
    required this.tabType,
  });

  @override
  State<_TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<_TransactionListView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    var displayTxns = widget.txns;
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      displayTxns = displayTxns.where((t) {
        final matchesNote = (t.note ?? '').toLowerCase().contains(query);
        final matchesAmount = t.amount.toString().contains(query);
        return matchesNote || matchesAmount;
      }).toList();
    }

    return Column(
      children: [
        _BalanceBanner(
            breakdown: widget.breakdown,
            contact: widget.contact,
            tabType: widget.tabType),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12)),
              const Spacer(),
              if (widget.txns.isNotEmpty)
                Text(l10n.swipeToDelete,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
        Expanded(
          child: displayTxns.isEmpty
              ? Center(
                  child: Text(widget.tabType == _TabType.interest
                      ? l10n.noInterestTransactions
                      : l10n.noPrincipalTransactions))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: displayTxns.length,
                  itemBuilder: (context, i) {
                    final t = displayTxns[i];
                    final isGave = t.direction == TxnDirection.gave;
                    final currentRunning = widget.runningAfter[t.id] ?? 0;

                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: t.isLocked
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.deleteTransaction),
                            content: Text(l10n.deleteTransactionWarning),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel)),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.delete,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => widget.onDelete(t.id),
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              contact: widget.contact,
                              direction: t.direction,
                              existing: t,
                            ),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: (isGave ? AppColors.gave : AppColors.got)
                              .withValues(alpha: 0.12),
                          child: Icon(
                            isGave ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isGave ? AppColors.gave : AppColors.got,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(_currency.format(t.amount),
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(_currency.format(currentRunning.abs()),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        subtitle: Text(
                          [
                            _dateFmt.format(t.date),
                            if (t.note != null && t.note!.isNotEmpty) t.note!,
                            if (t.reminderAt != null)
                              '⏰ ${_dateFmt.format(t.reminderAt!)}',
                          ].join('\n'),
                        ),
                        isThreeLine: t.note != null || t.reminderAt != null,
                        trailing: IconButton(
                          icon: const Icon(Icons.share, color: AppColors.primary),
                          onPressed: () => widget.onShare(t, currentRunning),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  final ContactBreakdown breakdown;
  final LedgerContact contact;
  final _TabType tabType;

  const _BalanceBanner({
    required this.breakdown, 
    required this.contact,
    required this.tabType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBank = contact.mode == ContactMode.bank;
    final showPrincipal = tabType == _TabType.principal;
    final mainValue = showPrincipal ? breakdown.principalBalance : breakdown.interestTotal;
    final secondaryLabel = showPrincipal ? l10n.totalInterest : l10n.principalBalance;
    final secondaryValue = showPrincipal ? breakdown.interestTotal : breakdown.principalBalance;
    
    final isMainPositive = mainValue >= 0;

    String mainLabel;
    if (isBank) {
      mainLabel = showPrincipal 
        ? (mainValue >= 0 ? l10n.currentBalance : l10n.lossBalance)
        : (mainValue >= 0 ? l10n.totalInterestEarned : l10n.totalInterestOwed);
    } else {
      mainLabel = showPrincipal 
        ? (mainValue >= 0 ? l10n.principalReceivable : l10n.principalPayable)
        : (mainValue >= 0 ? l10n.totalInterestEarned : l10n.totalInterestOwed);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: (isMainPositive ? AppColors.got : AppColors.gave).withValues(alpha: 0.08),
      child: Column(
        children: [
          Text(
            mainLabel,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            _currency.format(mainValue.abs()),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: mainValue == 0 ? Colors.grey : (isMainPositive ? AppColors.got : AppColors.gave),
            ),
          ),
          if (!isBank && (breakdown.interestTotal != 0 || breakdown.principalBalance != 0)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SmallStat(label: secondaryLabel, value: secondaryValue),
                    const VerticalDivider(width: 32),
                    _SmallStat(label: l10n.netTotal, value: breakdown.netBalance, isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _SmallStat({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(
          _currency.format(value.abs()),
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: value == 0 ? Colors.grey : (isPositive ? AppColors.got : AppColors.gave),
          ),
        ),
      ],
    );
  }
}
