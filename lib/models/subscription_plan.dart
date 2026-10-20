import 'package:uuid/uuid.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final int days;
  final double price;

  SubscriptionPlan({
    String? id,
    required this.name,
    required this.days,
    required this.price,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days': days,
      'price': price,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'],
      name: map['name'] ?? 'Plan',
      days: map['days']?.toInt() ?? 30,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
