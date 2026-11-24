import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_stock.dart';
import '../services/inventory_service.dart';
import '../services/user_prefs_provider.dart';
import '../utils/theme.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = InventoryService();

  // Option 1: CSV State
  final _csvTextCtrl = TextEditingController();
  List<ProductStock> _parsedCsvProducts = [];

  // Option 2: AI Bill Snap State
  final _billTextCtrl = TextEditingController();
  List<ProductStock> _parsedBillProducts = [];

  // Option 3: Spreadsheet State
  final List<_SpreadsheetRow> _spreadsheetRows = [
    _SpreadsheetRow(),
    _SpreadsheetRow(),
    _SpreadsheetRow(),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _csvTextCtrl.dispose();
    _billTextCtrl.dispose();
    for (final r in _spreadsheetRows) {
      r.dispose();
    }
    super.dispose();
  }

  // ---------- Option 1: CSV Helpers ----------

  Future<void> _shareCsvTemplate() async {
    try {
      const csvContent = 'Name,SKU,Category,BuyPrice,SellPrice,Stock,Unit,MinStock\n'
          'Amul Butter 500g,BUTTER-500,Dairy,240,275,20,Pcs,5\n'
          'Basmati Rice 5kg,RICE-BAS-5,Groceries,450,520,15,Bag,3\n'
          'Wireless Mouse,SKU-WM-01,Electronics,350,599,10,Pcs,2\n';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inventory_sample_template.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Download and fill this sample inventory template in Excel / Google Sheets, then paste/upload into Money Manage.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share template: $e')),
        );
      }
    }
  }

  Future<void> _pickAndReadCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';

        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        }

        if (content.isNotEmpty) {
          setState(() {
            _csvTextCtrl.text = content;
          });
          _parseCsvText();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Loaded "${file.name}" successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _parseCsvText() {
    final raw = _csvTextCtrl.text.trim();
    if (raw.isEmpty) return;

    final lines = raw.split(RegExp(r'\r?\n'));
    final List<ProductStock> list = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip header row if present
      if (i == 0 && line.toLowerCase().contains('name') && line.toLowerCase().contains('buyprice')) {
        continue;
      }

      final parts = line.split(',');
      if (parts.isEmpty) continue;

      final name = parts[0].trim();
      if (name.isEmpty) continue;

      final sku = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : null;
      final category = parts.length > 2 && parts[2].trim().isNotEmpty ? parts[2].trim() : null;
      final buyPrice = parts.length > 3 ? (double.tryParse(parts[3].trim()) ?? 0.0) : 0.0;
      final sellPrice = parts.length > 4 ? (double.tryParse(parts[4].trim()) ?? 0.0) : buyPrice;
      final qty = parts.length > 5 ? (double.tryParse(parts[5].trim()) ?? 0.0) : 0.0;
      final unit = parts.length > 6 && parts[6].trim().isNotEmpty ? parts[6].trim() : 'Pcs';
      final minStock = parts.length > 7 ? (double.tryParse(parts[7].trim()) ?? 5.0) : 5.0;

      list.add(
        ProductStock(
          id: '',
          name: name,
          sku: sku,
          category: category,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          quantity: qty,
          unit: unit,
          minStock: minStock,
          updatedAt: DateTime.now(),
        ),
      );
    }

    setState(() {
      _parsedCsvProducts = list;
    });

    if (list.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid rows found. Please check CSV format.')),
      );
    }
  }

  // ---------- Option 2: AI Bill Snap Helpers ----------

  bool _isAiParsing = false;

  Future<void> _parseBillText() async {
    final raw = _billTextCtrl.text.trim();
    if (raw.isEmpty) return;

    final prefs = Provider.of<UserPrefsProvider>(context, listen: false);
    final apiKey = prefs.geminiApiKey;

    setState(() => _isAiParsing = true);

    try {
      if (apiKey.isNotEmpty) {
        final geminiResults = await _callGeminiBillParser(apiKey, raw);
        setState(() {
          _parsedBillProducts = geminiResults;
        });
      } else {
        _parseBillTextRegex(raw);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parsed locally. Add Gemini API Key for AI extraction!'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      _parseBillTextRegex(raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gemini error: ${e.toString().split("\n").first}. Used local parser.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiParsing = false);
    }
  }

  Future<List<ProductStock>> _callGeminiBillParser(String apiKey, String billText) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    const promptText = '''
You are an expert supplier bill & invoice line item parser.
Extract all product items from the following bill/invoice text into a strict JSON array.
Each JSON object in the array MUST have these keys:
- "name": string (product item name)
- "quantity": number (quantity purchased)
- "costPrice": number (unit purchase/cost price)
- "sellingPrice": number (suggested retail selling price, e.g. costPrice * 1.20 if not specified)

Return ONLY valid JSON with no markdown formatting or extra text outside the JSON array.

Bill Text:
''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": '$promptText\n$billText'}
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    });

    final client = HttpClient();
    final request = await client.postUrl(url);
    request.headers.contentType = ContentType.json;
    request.write(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();

    if (response.statusCode == 200) {
      final parsed = jsonDecode(responseBody);
      final rawJsonText = parsed['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
      final List<dynamic> jsonList = jsonDecode(rawJsonText);

      return jsonList.map((item) {
        final name = item['name']?.toString() ?? 'Product';
        final qty = (item['quantity'] ?? 1.0).toDouble();
        final buyPrice = (item['costPrice'] ?? 0.0).toDouble();
        final sellPrice = (item['sellingPrice'] ?? (buyPrice * 1.2)).toDouble();

        return ProductStock(
          id: '',
          name: name,
          buyPrice: buyPrice,
          sellPrice: sellPrice > 0 ? sellPrice : buyPrice,
          quantity: qty,
          unit: 'Pcs',
          minStock: 5.0,
          updatedAt: DateTime.now(),
        );
      }).toList();
    } else {
      throw Exception('Gemini API Error (${response.statusCode}): $responseBody');
    }
  }

  void _parseBillTextRegex(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    final List<ProductStock> list = [];

    final lineRegex = RegExp(r'([A-Za-z0-9\s.-]+?)\s+(\d+(?:\.\d+)?)\s*(?:pcs|kg|ltr|box|pkt)?\s*@?\s*(?:rs|₹)?\s*(\d+(?:\.\d+)?)', caseSensitive: false);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = lineRegex.firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1)?.trim() ?? 'Product';
        final qty = double.tryParse(match.group(2) ?? '1') ?? 1.0;
        final buyPrice = double.tryParse(match.group(3) ?? '0') ?? 0.0;
        final sellPrice = (buyPrice * 1.2).roundToDouble(); // Auto 20% margin suggestion

        list.add(
          ProductStock(
            id: '',
            name: name,
            buyPrice: buyPrice,
            sellPrice: sellPrice > 0 ? sellPrice : buyPrice,
            quantity: qty,
            unit: 'Pcs',
            minStock: 5.0,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Fallback simple line parsing
        list.add(
          ProductStock(
            id: '',
            name: trimmed,
            buyPrice: 0.0,
            sellPrice: 0.0,
            quantity: 1.0,
            unit: 'Pcs',
            minStock: 5.0,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    setState(() {
      _parsedBillProducts = list;
    });
  }

  // ---------- Save All Bulk Commitment ----------

  Future<void> _commitBulk(List<ProductStock> products) async {
    if (products.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await _service.bulkAddProducts(products);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added ${products.length} products to inventory!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save bulk products: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Add Products'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.file_upload_outlined), text: 'Option 1: CSV'),
            Tab(icon: Icon(Icons.document_scanner), text: 'Option 2: Bill AI'),
            Tab(icon: Icon(Icons.grid_on), text: 'Option 3: Quick Grid'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCsvOptionTab(),
          _buildBillOptionTab(),
          _buildSpreadsheetOptionTab(),
        ],
      ),
    );
  }

  // ---------- Option 1: CSV Tab ----------
  Widget _buildCsvOptionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Download Template Action Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_chart, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Option 1: Excel / CSV Bulk File Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Download the sample template, fill your items in Excel/Google Sheets, and paste/upload the CSV lines below.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Sample Template'),
                      onPressed: _shareCsvTemplate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload CSV File'),
                      onPressed: _pickAndReadCsvFile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Paste CSV Area
        const Text('Paste CSV Text:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _csvTextCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'e.g. Amul Butter, BUTTER-500, Dairy, 240, 275, 20, Pcs',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.sync),
            label: const Text('Parse CSV Rows'),
            onPressed: _parseCsvText,
          ),
        ),
        const SizedBox(height: 20),

        // Parsed Preview Section
        if (_parsedCsvProducts.isNotEmpty) ...[
          Text('Parsed Products (${_parsedCsvProducts.length} Items):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._parsedCsvProducts.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Buy: ₹${p.buyPrice} | Sell: ₹${p.sellPrice} | Stock: ${p.quantity} ${p.unit}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _parsedCsvProducts.remove(p)),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: _isSaving ? null : () => _commitBulk(_parsedCsvProducts),
              icon: const Icon(Icons.check_circle),
              label: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save All (${_parsedCsvProducts.length} Items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  void _showGeminiGuideModal(BuildContext context) {
    final prefs = Provider.of<UserPrefsProvider>(context, listen: false);
    final keyCtrl = TextEditingController(text: prefs.geminiApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Gemini AI Setup'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your Gemini API Key to enable AI bill extraction (gemini-2.5-flash):'),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 14),
              const Text('How to get a FREE Key:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text(
                '1. Open Google AI Studio (aistudio.google.com)\n'
                '2. Log in with Google\n'
                '3. Tap "Create API Key"\n'
                '4. Paste the key here!',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Google AI Studio'),
                onPressed: () async {
                  final uri = Uri.parse('https://aistudio.google.com/app/apikey');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await prefs.setGeminiApiKey(keyCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API Key saved successfully!')),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  // ---------- Option 2: AI Bill Snap Tab ----------
  Widget _buildBillOptionTab() {
    final prefs = Provider.of<UserPrefsProvider>(context);
    final hasKey = prefs.geminiApiKey.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!hasKey) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: Colors.amber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Gemini API Key recommended for AI bill extraction.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => _showGeminiGuideModal(context),
                  child: const Text('Add Key'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Option 2: AI Bill / Invoice Snap Parser', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Paste line items from a supplier paper bill or price list. Gemini 2.5 Flash extracts item names, quantities, and prices into structured cards.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Paste Bill Lines / Invoice Text:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _billTextCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'e.g.\nAmul Milk 10 Pcs @ Rs 30\nCadbury Silk 5 Pcs @ Rs 180\nFortune Oil 2 Ltr @ Rs 240',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade800),
            icon: _isAiParsing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isAiParsing ? 'Gemini 2.5 Flash Extracting...' : 'AI Extract Bill Line Items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _isAiParsing ? null : _parseBillText,
          ),
        ),
        const SizedBox(height: 20),

        if (_parsedBillProducts.isNotEmpty) ...[
          Text('Extracted Items (${_parsedBillProducts.length} Items):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Review and fix any typos before saving:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          ..._parsedBillProducts.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: p.name,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              _parsedBillProducts[idx] = ProductStock(
                                id: p.id,
                                name: val,
                                buyPrice: p.buyPrice,
                                sellPrice: p.sellPrice,
                                quantity: p.quantity,
                                unit: p.unit,
                                minStock: p.minStock,
                                updatedAt: DateTime.now(),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _parsedBillProducts.removeAt(idx)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: p.quantity.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final qty = double.tryParse(val) ?? 1.0;
                              _parsedBillProducts[idx] = ProductStock(
                                id: p.id,
                                name: p.name,
                                buyPrice: p.buyPrice,
                                sellPrice: p.sellPrice,
                                quantity: qty,
                                unit: p.unit,
                                minStock: p.minStock,
                                updatedAt: DateTime.now(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: p.buyPrice.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cost ₹',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final cost = double.tryParse(val) ?? 0.0;
                              _parsedBillProducts[idx] = ProductStock(
                                id: p.id,
                                name: p.name,
                                buyPrice: cost,
                                sellPrice: p.sellPrice,
                                quantity: p.quantity,
                                unit: p.unit,
                                minStock: p.minStock,
                                updatedAt: DateTime.now(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: p.sellPrice.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sell ₹',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final sell = double.tryParse(val) ?? 0.0;
                              _parsedBillProducts[idx] = ProductStock(
                                id: p.id,
                                name: p.name,
                                buyPrice: p.buyPrice,
                                sellPrice: sell,
                                quantity: p.quantity,
                                unit: p.unit,
                                minStock: p.minStock,
                                updatedAt: DateTime.now(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: _isSaving ? null : () => _commitBulk(_parsedBillProducts),
              icon: const Icon(Icons.check_circle),
              label: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Add All (${_parsedBillProducts.length} Items) to Inventory', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- Option 3: Rapid Quick-Add Grid Tab ----------
  Widget _buildSpreadsheetOptionTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Multi-Row Rapid Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                    onPressed: () {
                      setState(() {
                        _spreadsheetRows.add(_SpreadsheetRow());
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _spreadsheetRows.length,
            itemBuilder: (context, index) {
              final row = _spreadsheetRows[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Product Name *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              if (_spreadsheetRows.length > 1) {
                                setState(() {
                                  _spreadsheetRows.removeAt(index);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.skuCtrl,
                              decoration: const InputDecoration(
                                hintText: 'SKU / Barcode',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: row.buyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Buy ₹',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: row.sellCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Sell ₹',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: row.qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Qty',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _isSaving
                  ? null
                  : () {
                      final List<ProductStock> items = [];
                      for (final row in _spreadsheetRows) {
                        final name = row.nameCtrl.text.trim();
                        if (name.isEmpty) continue;

                        final sku = row.skuCtrl.text.trim().isEmpty ? null : row.skuCtrl.text.trim();
                        final buyPrice = double.tryParse(row.buyCtrl.text.trim()) ?? 0.0;
                        final sellPrice = double.tryParse(row.sellCtrl.text.trim()) ?? buyPrice;
                        final qty = double.tryParse(row.qtyCtrl.text.trim()) ?? 1.0;

                        items.add(ProductStock(
                          id: '',
                          name: name,
                          sku: sku,
                          buyPrice: buyPrice,
                          sellPrice: sellPrice,
                          quantity: qty,
                          unit: 'Pcs',
                          minStock: 5.0,
                          updatedAt: DateTime.now(),
                        ));
                      }

                      if (items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter at least one product name.')),
                        );
                        return;
                      }

                      _commitBulk(items);
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save All (${_spreadsheetRows.where((r) => r.nameCtrl.text.trim().isNotEmpty).length} Items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpreadsheetRow {
  final nameCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final buyCtrl = TextEditingController();
  final sellCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  void dispose() {
    nameCtrl.dispose();
    skuCtrl.dispose();
    buyCtrl.dispose();
    sellCtrl.dispose();
    qtyCtrl.dispose();
  }
}
