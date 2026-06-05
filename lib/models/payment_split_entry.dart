import '../utils/payment_method_utils.dart';

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
    final rawMethod = (json['payment_method'] ?? json['method'] ?? '')
        .toString()
        .trim();
    final normalizedMethod = normalizePaymentMethod(rawMethod);
    final rawAmount = json['amount'] ?? json['montant'] ?? 0;
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString().replaceAll(',', '.')) ?? 0.0;
    final rawTimestamp = json['timestamp'] ?? json['created_at'];
    final parsedTimestamp = rawTimestamp is String && rawTimestamp.trim().isNotEmpty
        ? DateTime.tryParse(rawTimestamp)
        : null;

    return PaymentSplitEntry(
      paymentMethod: normalizedMethod.isEmpty
          ? (rawMethod.isEmpty ? paymentMethodOther : rawMethod)
          : normalizedMethod,
      amount: amount,
      timestamp: parsedTimestamp ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PaymentSplitEntry(method: $paymentMethod, amount: $amount)';
  }
}
