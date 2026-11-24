import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/product_stock.dart';
import '../services/inventory_service.dart';
import '../utils/theme.dart';
import 'add_product_screen.dart';
import 'bulk_import_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = InventoryService();
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _dateFmt = DateFormat('dd MMM, h:mm a');

  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'low', 'out'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openBarcodeScannerSheet() {
    final barcodeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Barcode & SKU Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('Scan or enter SKU to filter instantly', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scanner Visual Viewfinder
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 56),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Continuous Scanner Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SKU Barcode Input Field
              TextField(
                controller: barcodeCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter or scan SKU / Barcode code...',
                  prefixIcon: const Icon(Icons.barcode_reader),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      final text = barcodeCtrl.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(ctx);
                        setState(() {
                          _searchCtrl.text = text;
                          _searchQuery = text;
                        });
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    setState(() {
                      _searchCtrl.text = val.trim();
                      _searchQuery = val.trim();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final text = barcodeCtrl.text.trim();
                    Navigator.pop(ctx);
                    if (text.isNotEmpty) {
                      setState(() {
                        _searchCtrl.text = text;
                        _searchQuery = text;
                      });
                    }
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search / Filter SKU', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickAdjustSheet(ProductStock product, {double initialDelta = 0.0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockQuickAdjustSheet(
        product: product,
        service: _service,
        initialDelta: initialDelta,
      ),
    );
  }

  void _showStockLogs(ProductStock product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Logs: ${product.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Total Available: ${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity.toStringAsFixed(2)} ${product.unit}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<StockLog>>(
                stream: _service.watchStockLogs(product.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final logs = snapshot.data!;
                  if (logs.isEmpty) {
                    return const Center(child: Text('No stock movement logs found.'));
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, idx) {
                      final log = logs[idx];
                      final isIn = log.type == StockLogType.stockIn;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIn ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(
                            isIn ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIn ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${isIn ? "+ Stock In" : "- Stock Out"} (${log.quantity % 1 == 0 ? log.quantity.toInt() : log.quantity.toStringAsFixed(2)} ${product.unit})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIn ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        subtitle: Text(
                          log.note != null && log.note!.isNotEmpty ? log.note! : 'No note',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          _dateFmt.format(log.date),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProductConfirm(ProductStock product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product "${product.name}" deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Bulk Import Products',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BulkImportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductStock>>(
        stream: _service.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading inventory: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data!;

          // Summary Metrics
          final lowStockCount = allProducts.where((p) => p.isLowStock).length;
          final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;
          final totalValuation = allProducts.fold<double>(0, (sum, p) => sum + p.totalBuyValue);
          final totalRetailValuation = allProducts.fold<double>(0, (sum, p) => sum + p.totalSellValue);

          return StreamBuilder<List<StockLog>>(
            stream: _service.watchAllStockLogs(),
            builder: (context, logSnapshot) {
              final allLogs = logSnapshot.data ?? [];
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final todayLogs = allLogs.where((l) => l.date.isAfter(todayStart)).toList();

              final todayIn = todayLogs
                  .where((l) => l.type == StockLogType.stockIn)
                  .fold<double>(0, (sum, l) => sum + l.quantity);
              final todayOut = todayLogs
                  .where((l) => l.type == StockLogType.stockOut)
                  .fold<double>(0, (sum, l) => sum + l.quantity);

              // Filtering
              final filteredProducts = allProducts.where((p) {
                final matchesQuery = _searchQuery.isEmpty ||
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (p.sku != null && p.sku!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                    (p.category != null && p.category!.toLowerCase().contains(_searchQuery.toLowerCase()));

                if (!matchesQuery) return false;

                if (_filterStatus == 'low') return p.isLowStock && !p.isOutOfStock;
                if (_filterStatus == 'out') return p.isOutOfStock;
                return true;
              }).toList();

              return Column(
                children: [
                  // 1. 3-Metric Executive Header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // KPI 1: Total Stock Value
                        Expanded(
                          child: _buildExecutiveKpiCard(
                            title: 'Stock Value',
                            value: _currency.format(totalValuation),
                            subtitle: 'Retail: ${_currency.format(totalRetailValuation)}',
                            icon: Icons.account_balance_wallet_outlined,
                            accentColor: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // KPI 2: Low Stock Alerts (Clickable Filter)
                        Expanded(
                          child: _buildExecutiveKpiCard(
                            title: 'Low Stock',
                            value: '$lowStockCount Alerts',
                            subtitle: _filterStatus == 'low' ? 'Filtering Active' : 'Tap to Filter',
                            icon: Icons.warning_amber_rounded,
                            accentColor: lowStockCount > 0 ? Colors.amber.shade800 : Colors.grey,
                            isDark: isDark,
                            isSelected: _filterStatus == 'low',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filterStatus = _filterStatus == 'low' ? 'all' : 'low';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // KPI 3: Today's Stock Movement (In vs Out)
                        Expanded(
                          child: _buildExecutiveKpiCard(
                            title: "Today's Move",
                            value: '+${todayIn % 1 == 0 ? todayIn.toInt() : todayIn.toStringAsFixed(1)} / -${todayOut % 1 == 0 ? todayOut.toInt() : todayOut.toStringAsFixed(1)}',
                            subtitle: 'Stock In vs Out',
                            icon: Icons.swap_vert_rounded,
                            accentColor: Colors.blue.shade700,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

              // 2. Command & Scan Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search name, SKU, category, or brand...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.manage_search_rounded, color: AppColors.primary),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                                tooltip: 'Scan Barcode / SKU',
                                onPressed: _openBarcodeScannerSheet,
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Products', 'all'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Low Stock ($lowStockCount)', 'low', badgeColor: Colors.amber),
                          const SizedBox(width: 6),
                          _buildFilterChip('Out of Stock ($outOfStockCount)', 'out', badgeColor: Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 3. Product List View (Clean & Non-collapsing)
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || _filterStatus != 'all'
                                  ? 'No matching products found.'
                                  : 'No products added yet.',
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            if (allProducts.isEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Your First Product'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final isOut = product.isOutOfStock;
                          final isLow = product.isLowStock;

                          Color statusColor;
                          Color bgTint;
                          String statusText;
                          IconData statusIcon;

                          if (isOut) {
                            statusColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
                            bgTint = isDark
                                ? Colors.red.shade900.withValues(alpha: 0.35)
                                : Colors.red.shade50.withValues(alpha: 0.55);
                            statusText = 'Out of Stock';
                            statusIcon = Icons.cancel;
                          } else if (isLow) {
                            statusColor = isDark ? Colors.amber.shade400 : Colors.amber.shade900;
                            bgTint = isDark
                                ? Colors.amber.shade900.withValues(alpha: 0.35)
                                : Colors.amber.shade50.withValues(alpha: 0.55);
                            statusText = 'Low Stock';
                            statusIcon = Icons.warning_amber_rounded;
                          } else {
                            statusColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
                            bgTint = isDark
                                ? Colors.green.shade900.withValues(alpha: 0.25)
                                : Colors.green.shade50.withValues(alpha: 0.4);
                            statusText = 'Healthy Stock';
                            statusIcon = Icons.check_circle_outline;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: bgTint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(
                                left: BorderSide(color: statusColor, width: 6),
                                top: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1),
                                right: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1),
                                bottom: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _openQuickAdjustSheet(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  // Product Header with Name, Category/SKU, Traffic Light Pill & Menu
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(statusIcon, color: statusColor, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Traffic Light Status Badge Pill
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        statusText,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (product.category != null && product.category!.isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      product.category!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (product.sku != null && product.sku!.isNotEmpty)
                                                  Text(
                                                    'SKU: ${product.sku}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                            if (product.trackExpiry && product.expiryDate != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.event,
                                                    size: 12,
                                                    color: product.isExpired
                                                        ? Colors.red.shade800
                                                        : (product.isExpiringSoon ? Colors.amber.shade900 : Colors.grey),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    product.isExpired
                                                        ? 'EXPIRED (${DateFormat("d MMM yyyy").format(product.expiryDate!)})'
                                                        : (product.isExpiringSoon
                                                            ? 'Expiring in ${product.daysUntilExpiry} days (${DateFormat("d MMM").format(product.expiryDate!)})'
                                                            : 'Exp: ${DateFormat("d MMM yyyy").format(product.expiryDate!)}'),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: product.isExpiringSoon || product.isExpired
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: product.isExpired
                                                          ? Colors.red.shade800
                                                          : (product.isExpiringSoon ? Colors.amber.shade900 : Colors.grey),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddProductScreen(existingProduct: product),
                                              ),
                                            );
                                          } else if (action == 'delete') {
                                            _deleteProductConfirm(product);
                                          } else if (action == 'logs') {
                                            _showStockLogs(product);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'logs', child: Text('View Stock History')),
                                          PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                                          PopupMenuDivider(),
                                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),

                                  // Quantity & Pricing Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Stock Quantity',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            '${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity.toStringAsFixed(2)} ${product.unit}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Sell: ${_currency.format(product.sellPrice)} / ${product.unit}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Buy: ${_currency.format(product.buyPrice)}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Quick Action Buttons (+ Stock In / - Stock Out)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green.shade800,
                                            side: BorderSide(color: Colors.green.shade300),
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.add_circle_outline, size: 16),
                                          label: const Text('+ Stock In'),
                                          onPressed: () => _openQuickAdjustSheet(product, initialDelta: 1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade800,
                                            side: BorderSide(color: Colors.red.shade300),
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.remove_circle_outline, size: 16),
                                          label: const Text('- Stock Out'),
                                          onPressed: () => _openQuickAdjustSheet(product, initialDelta: -1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.outlined(
                                        icon: const Icon(Icons.history, size: 18),
                                        tooltip: 'History',
                                        onPressed: () => _showStockLogs(product),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
        },
      );
    },
  ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildExecutiveKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : (isDark ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(icon, color: accentColor, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? accentColor : null,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? accentColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? badgeColor}) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = value);
      },
    );
  }
}

class _StockQuickAdjustSheet extends StatefulWidget {
  final ProductStock product;
  final InventoryService service;
  final double initialDelta;

  const _StockQuickAdjustSheet({
    required this.product,
    required this.service,
    this.initialDelta = 0.0,
  });

  @override
  State<_StockQuickAdjustSheet> createState() => _StockQuickAdjustSheetState();
}

class _StockQuickAdjustSheetState extends State<_StockQuickAdjustSheet> {
  late double _delta = widget.initialDelta;
  final _noteCtrl = TextEditingController();
  late final _customDeltaCtrl = TextEditingController(
    text: _delta == 0 ? '0' : (_delta % 1 == 0 ? _delta.toInt().toString() : _delta.toStringAsFixed(1)),
  );

  @override
  void dispose() {
    _noteCtrl.dispose();
    _customDeltaCtrl.dispose();
    super.dispose();
  }

  void _addDelta(double amount) {
    HapticFeedback.lightImpact();
    setState(() {
      _delta += amount;
      _customDeltaCtrl.text = _delta % 1 == 0 ? _delta.toInt().toString() : _delta.toStringAsFixed(1);
    });
  }

  void _setDelta(double val) {
    setState(() {
      _delta = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentQty = widget.product.quantity;
    final newQty = (currentQty + _delta).clamp(0.0, double.infinity);

    final isAddition = _delta > 0;
    final isSubtraction = _delta < 0;

    Color accentColor = AppColors.primary;
    if (isAddition) accentColor = Colors.green.shade700;
    if (isSubtraction) accentColor = Colors.red.shade700;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Category: ${widget.product.category ?? "General"} | Unit: ${widget.product.unit}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Stock Forecast Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Current Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '${currentQty % 1 == 0 ? currentQty.toInt() : currentQty.toStringAsFixed(1)} ${widget.product.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: accentColor),
                  Column(
                    children: [
                      Text('New Total', style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${newQty % 1 == 0 ? newQty.toInt() : newQty.toStringAsFixed(1)} ${widget.product.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Big Thumb Counter (+ / - Buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big Decrement Button
                InkWell(
                  onTap: () => _addDelta(-1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.remove, color: Colors.red.shade800, size: 28),
                  ),
                ),
                const SizedBox(width: 16),

                // Active Adjustment Value Display / Input
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _customDeltaCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      _setDelta(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Big Increment Button
                InkWell(
                  onTap: () => _addDelta(1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.add, color: Colors.green.shade800, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preset Quick Adjustment Pills
            const Text('Quick Preset Adjustments:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetPill('+1', 1, Colors.green),
                  _buildPresetPill('+5', 5, Colors.green),
                  _buildPresetPill('+10', 10, Colors.green),
                  _buildPresetPill('+50', 50, Colors.green),
                  _buildPresetPill('+100', 100, Colors.green),
                  const SizedBox(width: 6),
                  _buildPresetPill('-1', -1, Colors.red),
                  _buildPresetPill('-5', -5, Colors.red),
                  _buildPresetPill('-10', -10, Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason / Note Field
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Reason (e.g. Sale, Supplier Delivery, Damage)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),

            // Confirm & Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _delta == 0 ? Colors.grey : accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _delta == 0
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        final type = _delta > 0
                            ? StockLogType.stockIn
                            : (_delta < 0 ? StockLogType.stockOut : StockLogType.adjustment);

                        Navigator.pop(context);
                        await widget.service.adjustStock(
                          product: widget.product,
                          changeQty: _delta.abs(),
                          type: type,
                          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                        );
                      },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _delta == 0
                      ? 'No Adjustment'
                      : 'Confirm Adjustment (${_delta > 0 ? "+$_delta" : "$_delta"} ${widget.product.unit})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPill(String label, double val, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _addDelta(val),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color.shade800,
            ),
          ),
        ),
      ),
    );
  }
}
