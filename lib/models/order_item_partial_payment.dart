/// Represents a partial payment entry for a specific order item
class OrderItemPartialPayment {
  final int itemId; // Reference to PosOrderItem.id
  final int productId;
  final String productName;
  final int quantityPaid; // Quantity paid in this transaction
  final double amountPaid; // Amount paid for these units
  final String paymentMethod; // cash, tpe, en_compte
  final DateTime timestamp;

  OrderItemPartialPayment({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantityPaid,
    required this.amountPaid,
    required this.paymentMethod,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'product_id': productId,
      'product_name': productName,
      'quantity_paid': quantityPaid,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory OrderItemPartialPayment.fromJson(Map<String, dynamic> json) {
    return OrderItemPartialPayment(
      itemId: json['item_id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      quantityPaid: json['quantity_paid'] as int,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'OrderItemPartialPayment(itemId: $itemId, quantityPaid: $quantityPaid, amountPaid: $amountPaid)';
  }
}
