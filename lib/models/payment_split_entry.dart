/// Represents a single payment entry in a split payment scenario
class PaymentSplitEntry {
  final String paymentMethod; // cash, tpe, en_compte, other
  final double amount;
  final DateTime timestamp;

  PaymentSplitEntry({
    required this.paymentMethod,
    required this.amount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PaymentSplitEntry.fromJson(Map<String, dynamic> json) {
    return PaymentSplitEntry(
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'PaymentSplitEntry(method: $paymentMethod, amount: $amount)';
  }
}
