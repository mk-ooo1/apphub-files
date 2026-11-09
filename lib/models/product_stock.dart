import 'package:cloud_firestore/cloud_firestore.dart';

enum StockLogType { stockIn, stockOut, adjustment }

class ProductStock {
  final String id;
  final String name;
  final String? sku;
  final String? category;
  final double buyPrice;
  final double sellPrice;
  final double quantity;
  final String unit;
  final double minStock;
  final DateTime updatedAt;

  ProductStock({
    required this.id,
    required this.name,
    this.sku,
    this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    this.unit = 'Pcs',
    this.minStock = 5.0,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= minStock;
  bool get isOutOfStock => quantity <= 0;
  double get totalBuyValue => quantity * buyPrice;
  double get totalSellValue => quantity * sellPrice;
  double get potentialProfit => totalSellValue - totalBuyValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
      'unit': unit,
      'minStock': minStock,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductStock.fromMap(String id, Map<String, dynamic> map) {
    return ProductStock(
      id: id,
      name: map['name'] ?? '',
      sku: map['sku'],
      category: map['category'],
      buyPrice: (map['buyPrice'] ?? 0.0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'Pcs',
      minStock: (map['minStock'] ?? 5.0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class StockLog {
  final String id;
  final String productId;
  final String productName;
  final StockLogType type;
  final double quantity;
  final String? note;
  final DateTime date;

  StockLog({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'note': note,
      'date': Timestamp.fromDate(date),
    };
  }

  factory StockLog.fromMap(String id, Map<String, dynamic> map) {
    return StockLog(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: StockLogType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StockLogType.adjustment,
      ),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      note: map['note'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
