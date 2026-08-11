import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/ledger_transaction.dart';
import 'ledger_service.dart';

/// Builds PDF and CSV exports for transactions and ledgers.
class ReceiptService {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  static Future<File> buildTransactionReceipt({
    required LedgerContact contact,
    required LedgerTransaction txn,
    required double runningBalance,
    String businessName = 'Money Manage',
  }) async {
    final doc = pw.Document();
    final isGave = txn.direction == TxnDirection.gave;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(),
              pw.SizedBox(height: 12),
              _row('To/From', contact.name),
              _row('Phone', contact.phone),
              _row('Date', _dateFmt.format(txn.date)),
              _row('Category', txn.type == TransactionType.interest ? 'Interest' : 'Principal'),
              _row(isGave ? 'You Gave' : 'You Received', 'Rs. ${txn.amount.toStringAsFixed(2)}'),
              if (txn.note != null && txn.note!.isNotEmpty) _row('Note', txn.note!),
              pw.SizedBox(height: 8),
              pw.Divider(),
              _row(
                runningBalance >= 0 ? 'Total Receivable' : 'Total Payable',
                'Rs. ${runningBalance.abs().toStringAsFixed(2)}',
                bold: true,
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated via Money Manage App', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${txn.id}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<File> buildFullLedgerPdf({
    required LedgerContact contact,
    required List<LedgerTransaction> txns, // Assume chronological order (oldest first)
    String businessName = 'Money Manage',
  }) async {
    final doc = pw.Document();
    final isBank = contact.mode == ContactMode.bank;
    
    // Calculate final breakdown for summary
    final breakdown = LedgerService.getContactBreakdown(contact, txns);

    final tableHeaders = isBank 
        ? ['Date', 'Type', 'Note', 'Withdraw (-)', 'Deposit (+)', 'Balance']
        : ['Date', 'Type', 'Note', 'Gave (Dr)', 'Got (Cr)', 'Balance'];
    
    double runningNet = contact.openingBalance;
    final tableData = txns.map((t) {
      final double change;
      if (t.type == TransactionType.interest) {
        change = (t.direction == TxnDirection.got ? t.amount : -t.amount);
      } else {
        change = isBank ? (t.direction == TxnDirection.got ? t.amount : -t.amount) : t.signedAmount;
      }
      
      runningNet += change;

      return [
        _dateFmt.format(t.date),
        t.type == TransactionType.interest ? 'INT' : 'PRIN',
        t.note ?? '-',
        t.direction == TxnDirection.gave ? t.amount.toStringAsFixed(2) : '-',
        t.direction == TxnDirection.got ? t.amount.toStringAsFixed(2) : '-',
        runningNet.toStringAsFixed(2),
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Money Manage Report: ${contact.name}', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Opening Balance:'),
              pw.Text('Rs. ${contact.openingBalance.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: tableHeaders,
            data: tableData,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(
              children: [
                _summaryRow('Principal Balance:', breakdown.principalBalance),
                _summaryRow('Interest Total:', breakdown.interestTotal),
                pw.Divider(color: PdfColors.grey),
                _summaryRow('NET TOTAL:', breakdown.netBalance, bold: true, fontSize: 14),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount} | Generated via Money Manage App',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ledger_${contact.id}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<File> generateLedgerCsv({
    required LedgerContact contact,
    required List<LedgerTransaction> txns,
  }) async {
    final isBank = contact.mode == ContactMode.bank;
    final buffer = StringBuffer();
    buffer.writeln('Money Manage Report for: ${contact.name}');
    buffer.writeln('Date,Type,Note,Direction,Amount,Running Net Balance');
    
    double runningNet = contact.openingBalance;
    buffer.writeln('Opening,,, , ,${runningNet.toStringAsFixed(2)}');

    for (final t in txns) {
      final double change;
      if (t.type == TransactionType.interest) {
        change = (t.direction == TxnDirection.got ? t.amount : -t.amount);
      } else {
        change = isBank ? (t.direction == TxnDirection.got ? t.amount : -t.amount) : t.signedAmount;
      }
      
      runningNet += change;
      
      final note = (t.note ?? '').replaceAll('"', '""');
      buffer.writeln(
        '${_dateFmt.format(t.date)},${t.type.name},"$note",${t.direction.name},${t.amount.toStringAsFixed(2)},${runningNet.toStringAsFixed(2)}'
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ledger_${contact.id}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static pw.Widget _summaryRow(String label, double value, {bool bold = false, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('Rs. ${value.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> shareReceipt(File file, {String? text}) async {
    await Share.shareXFiles([XFile(file.path)], text: text ?? 'Here is your export.');
  }
}
