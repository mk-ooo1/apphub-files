import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manage_app/l10n/app_localizations.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import '../services/ledger_service.dart';
import '../utils/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LedgerService();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financialReports)),
      body: StreamBuilder<List<LedgerContact>>(
        stream: service.watchContacts(),
        builder: (context, contactSnap) {
          if (!contactSnap.hasData) return const Center(child: CircularProgressIndicator());

          return StreamBuilder<List<LedgerTransaction>>(
            stream: service.watchAllTransactions(),
            builder: (context, txnSnap) {
              if (!txnSnap.hasData) return const Center(child: CircularProgressIndicator());

              final contacts = contactSnap.data!;
              final allTxns = txnSnap.data!;
              final byContact = <String, List<LedgerTransaction>>{};
              for (final t in allTxns) {
                byContact.putIfAbsent(t.contactId, () => []).add(t);
              }

              final rawBreakdown = LedgerService.contactBreakdown(contacts, byContact);
              final sortedEntries = rawBreakdown.entries.toList()
                ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

              // Prepare Chart Data: Group small amounts into "Others" if more than 6 contacts
              Map<String, double> chartBreakdown = {};
              if (sortedEntries.length > 6) {
                for (var i = 0; i < 5; i++) {
                  chartBreakdown[sortedEntries[i].key] = sortedEntries[i].value;
                }
                double othersSum = 0;
                for (var i = 5; i < sortedEntries.length; i++) {
                  othersSum += sortedEntries[i].value.abs();
                }
                chartBreakdown['Others'] = othersSum;
              } else {
                chartBreakdown = rawBreakdown;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Contact-wise Breakdown', // Could add l10n key if needed
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (rawBreakdown.isEmpty)
                    const Center(child: Text('No data to display'))
                  else ...[
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildChartSections(chartBreakdown),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Detailed Balances',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...sortedEntries.map((entry) {
                      final isPositive = entry.value >= 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(isPositive ? l10n.youWillGet : l10n.youWillGive, style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          currency.format(entry.value.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.got : AppColors.gave,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, double> breakdown) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.pink,
      Colors.grey.shade600, // Color for "Others"
    ];

    int i = 0;
    return breakdown.entries.where((e) => e.value != 0).map((entry) {
      final isOthers = entry.key == 'Others';
      final color = isOthers ? colors.last : colors[i % (colors.length - 1)];
      i++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.abs(),
        title: entry.key,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }
}
