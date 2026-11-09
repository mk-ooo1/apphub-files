import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_stock.dart';
import '../services/inventory_service.dart';
import '../utils/theme.dart';
import 'add_product_screen.dart';

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

  void _showAdjustStockDialog(ProductStock product, StockLogType type) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isStockIn = type == StockLogType.stockIn;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isStockIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isStockIn ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isStockIn ? 'Stock In (Add)' : 'Stock Out (Reduce)'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Current Stock: ${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity.toStringAsFixed(2)} ${product.unit}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isStockIn ? 'Quantity to Add *' : 'Quantity to Reduce *',
                  suffixText: product.unit,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note / Reason (Optional)',
                  hintText: 'e.g. Purchase invoice, Customer order, Damage',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isStockIn ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text.trim());
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }

              Navigator.pop(ctx);
              await _service.adjustStock(
                product: product,
                changeQty: qty,
                type: type,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isStockIn
                          ? 'Added $qty ${product.unit} to ${product.name}'
                          : 'Reduced $qty ${product.unit} from ${product.name}',
                    ),
                  ),
                );
              }
            },
            child: Text(isStockIn ? 'Add Stock' : 'Reduce Stock'),
          ),
        ],
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
          final totalProducts = allProducts.length;
          final lowStockCount = allProducts.where((p) => p.isLowStock).length;
          final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;
          final totalValuation = allProducts.fold<double>(0, (sum, p) => sum + p.totalBuyValue);
          final totalRetailValuation = allProducts.fold<double>(0, (sum, p) => sum + p.totalSellValue);

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
              // 1. Dashboard Header Summary Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryItem(
                          title: 'Total Items',
                          value: totalProducts.toString(),
                          icon: Icons.inventory,
                          color: AppColors.primary,
                        ),
                        _buildSummaryItem(
                          title: 'Low Stock',
                          value: lowStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: lowStockCount > 0 ? Colors.orange.shade800 : Colors.grey,
                        ),
                        _buildSummaryItem(
                          title: 'Out of Stock',
                          value: outOfStockCount.toString(),
                          icon: Icons.remove_shopping_cart_outlined,
                          color: outOfStockCount > 0 ? Colors.red.shade800 : Colors.grey,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Buy Valuation', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(_currency.format(totalValuation), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Retail Potential Value', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              _currency.format(totalRetailValuation),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search product, SKU or category...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
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

                          Color statusColor = Colors.green;
                          String statusText = 'In Stock';
                          if (isOut) {
                            statusColor = Colors.red;
                            statusText = 'Out of Stock';
                          } else if (isLow) {
                            statusColor = Colors.amber.shade800;
                            statusText = 'Low Stock';
                          }

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Title, Category, Status Tag
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.inventory_2, color: statusColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (product.category != null && product.category!.isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      product.category!,
                                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
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
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Stock: ${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity.toStringAsFixed(2)} ${product.unit}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isOut ? Colors.red : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            statusText,
                                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
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
                                          onPressed: () => _showAdjustStockDialog(product, StockLogType.stockIn),
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
                                          onPressed: () => _showAdjustStockDialog(product, StockLogType.stockOut),
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
                          );
                        },
                      ),
              ),
            ],
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

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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
