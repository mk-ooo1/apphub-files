import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/product_stock.dart';

class InventoryService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('users').doc(_uid).collection('products');

  CollectionReference<Map<String, dynamic>> get _stockLogs =>
      _db.collection('users').doc(_uid).collection('stock_logs');

  // ---------- Products CRUD ----------

  Stream<List<ProductStock>> watchProducts() {
    return _products
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ProductStock.fromMap(d.id, d.data())).toList());
  }

  Future<String> addProduct(ProductStock p) async {
    final id = p.id.isNotEmpty ? p.id : _uuid.v4();
    final newProduct = ProductStock(
      id: id,
      name: p.name,
      sku: p.sku,
      category: p.category,
      buyPrice: p.buyPrice,
      sellPrice: p.sellPrice,
      quantity: p.quantity,
      unit: p.unit,
      minStock: p.minStock,
      updatedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(_products.doc(id), newProduct.toMap());

    // Initial stock log if quantity > 0
    if (p.quantity > 0) {
      final logId = _uuid.v4();
      final log = StockLog(
        id: logId,
        productId: id,
        productName: p.name,
        type: StockLogType.stockIn,
        quantity: p.quantity,
        note: 'Initial Stock Entry',
        date: DateTime.now(),
      );
      batch.set(_stockLogs.doc(logId), log.toMap());
    }

    await batch.commit();
    return id;
  }

  Future<void> updateProduct(ProductStock p) async {
    await _products.doc(p.id).update({
      'name': p.name,
      'sku': p.sku,
      'category': p.category,
      'buyPrice': p.buyPrice,
      'sellPrice': p.sellPrice,
      'unit': p.unit,
      'minStock': p.minStock,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteProduct(String productId) async {
    final batch = _db.batch();
    batch.delete(_products.doc(productId));

    final logs = await _stockLogs.where('productId', isEqualTo: productId).get();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ---------- Stock Adjustments (Stock In / Stock Out) ----------

  Future<void> adjustStock({
    required ProductStock product,
    required double changeQty,
    required StockLogType type,
    String? note,
  }) async {
    final double newQty;
    if (type == StockLogType.stockIn) {
      newQty = product.quantity + changeQty;
    } else if (type == StockLogType.stockOut) {
      newQty = (product.quantity - changeQty).clamp(0.0, double.infinity);
    } else {
      newQty = changeQty; // Direct adjustment set
    }

    final batch = _db.batch();

    // 1. Update product quantity
    batch.update(_products.doc(product.id), {
      'quantity': newQty,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // 2. Create stock log entry
    final logId = _uuid.v4();
    final log = StockLog(
      id: logId,
      productId: product.id,
      productName: product.name,
      type: type,
      quantity: changeQty,
      note: note,
      date: DateTime.now(),
    );
    batch.set(_stockLogs.doc(logId), log.toMap());

    await batch.commit();
  }

  Stream<List<StockLog>> watchStockLogs(String productId) {
    return _stockLogs
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => StockLog.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<StockLog>> watchAllStockLogs() {
    return _stockLogs.snapshots().map((snap) {
      final list = snap.docs.map((d) => StockLog.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }
}
