import 'package:flutter/material.dart';
import '../models/product_stock.dart';
import '../services/inventory_service.dart';
import '../utils/theme.dart';

class AddProductScreen extends StatefulWidget {
  final ProductStock? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InventoryService();

  late final _nameCtrl = TextEditingController(text: widget.existingProduct?.name ?? '');
  late final _skuCtrl = TextEditingController(text: widget.existingProduct?.sku ?? '');
  late final _categoryCtrl = TextEditingController(text: widget.existingProduct?.category ?? '');
  late final _buyPriceCtrl = TextEditingController(
    text: widget.existingProduct != null ? widget.existingProduct!.buyPrice.toStringAsFixed(2) : '',
  );
  late final _sellPriceCtrl = TextEditingController(
    text: widget.existingProduct != null ? widget.existingProduct!.sellPrice.toStringAsFixed(2) : '',
  );
  late final _qtyCtrl = TextEditingController(
    text: widget.existingProduct != null ? widget.existingProduct!.quantity.toStringAsFixed(0) : '0',
  );
  late final _minStockCtrl = TextEditingController(
    text: widget.existingProduct != null ? widget.existingProduct!.minStock.toStringAsFixed(0) : '5',
  );

  String _selectedUnit = 'Pcs';
  bool _saving = false;

  final List<String> _unitOptions = ['Pcs', 'Kg', 'Ltr', 'Box', 'Meter', 'Packet', 'Set', 'Gm'];

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null && _unitOptions.contains(widget.existingProduct!.unit)) {
      _selectedUnit = widget.existingProduct!.unit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _categoryCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final sku = _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim();
      final category = _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();
      final buyPrice = double.tryParse(_buyPriceCtrl.text.trim()) ?? 0.0;
      final sellPrice = double.tryParse(_sellPriceCtrl.text.trim()) ?? 0.0;
      final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
      final minStock = double.tryParse(_minStockCtrl.text.trim()) ?? 5.0;

      final product = ProductStock(
        id: widget.existingProduct?.id ?? '',
        name: name,
        sku: sku,
        category: category,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: qty,
        unit: _selectedUnit,
        minStock: minStock,
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _service.updateProduct(product);
      } else {
        await _service.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Product updated successfully' : 'Product added to stock')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
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
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Basic Info Section
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g. Rice 10kg, Wireless Mouse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Barcode',
                      hintText: 'e.g. ITEM-001',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Groceries',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pricing & Unit Section
            _buildSectionTitle('Pricing & Unit'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Buy Price (₹) *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Valid price required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Sell Price (₹) *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Valid price required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit of Measurement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              items: _unitOptions
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedUnit = val);
              },
            ),
            const SizedBox(height: 24),

            // Stock Details Section
            _buildSectionTitle('Stock Quantity & Limits'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    enabled: !_isEditing, // Only set initial quantity when creating
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _isEditing ? 'Current Quantity' : 'Initial Quantity',
                      border: const OutlineInputBorder(),
                      suffixText: _selectedUnit,
                      helperText: _isEditing ? 'Use Stock In/Out on main screen' : null,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter valid quantity';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Low Stock Alert Limit',
                      border: const OutlineInputBorder(),
                      suffixText: _selectedUnit,
                      helperText: 'Alert when stock falls below this',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter valid limit';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle_outline),
                label: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Update Product' : 'Save Product',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
