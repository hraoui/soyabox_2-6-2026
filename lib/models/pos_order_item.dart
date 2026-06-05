import 'dart:convert';

import 'package:isar/isar.dart';

part 'pos_order_item.g.dart';

@Collection()
class PosOrderItem {
  Id id = Isar.autoIncrement;

  @Index()
  int orderId;

  int productId;
  String productName;
  double unitPrice;
  int quantity;
  int? groupNumber;
  String? groupLabel;
  String? itemNote;
  String? serviceCourseKey;
  String? serviceCourseLabel;

  /// Price type used: 'glovo', 'restaurant', 'retail', or null for default
  String? priceType;

  /// Glovo price (when priceType is 'glovo', this is the base price)
  double? glovoBasePrice;

  /// Payment status for this item: unpaid, paid, or partially_paid
  @Index()
  String paymentStatus = 'unpaid';

  /// Amount paid for this item (0 if unpaid, unitPrice*quantity if fully paid)
  double paidAmount = 0.0;

  /// JSON string storing payment history for partial payments
  /// Format: List of OrderItemPartialPayment JSON objects
  String? partialPaymentHistory;

  DateTime createdAt;

  PosOrderItem({
    this.id = Isar.autoIncrement,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.groupNumber,
    this.groupLabel,
    this.itemNote,
    this.serviceCourseKey,
    this.serviceCourseLabel,
    this.priceType,
    this.glovoBasePrice,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.partialPaymentHistory,
    required this.createdAt,
  });

  /// Get total price for this item
  double getTotalPrice() => unitPrice * quantity;

  /// Check if item is fully paid
  bool isFullyPaid() => paymentStatus == 'paid';

  /// Check if item is partially paid
  bool isPartiallyPaid() => paymentStatus == 'partially_paid';

  /// Check if item is unpaid
  bool isUnpaid() => paymentStatus == 'unpaid';

  /// Check if item is offered (gratuit)
  bool isOffered() => paymentStatus == 'offered';

  int getCoveredQuantity() {
    if (partialPaymentHistory == null || partialPaymentHistory!.isEmpty) {
      if (isOffered()) {
        return quantity;
      }
      if (unitPrice <= 0) {
        return 0;
      }
      return (paidAmount / unitPrice).round().clamp(0, quantity).toInt();
    }

    try {
      final decoded = jsonDecode(partialPaymentHistory!);
      if (decoded is List) {
        final covered = decoded.fold<int>(0, (sum, entry) {
          if (entry is Map && entry['quantity_paid'] is num) {
            return sum + (entry['quantity_paid'] as num).toInt();
          }
          return sum;
        });
        return covered.clamp(0, quantity).toInt();
      }
    } catch (_) {
      // Fallback to paidAmount below.
    }

    if (unitPrice <= 0) {
      return quantity;
    }
    return (paidAmount / unitPrice).round().clamp(0, quantity).toInt();
  }

  int getRemainingQuantity() {
    return (quantity - getCoveredQuantity()).clamp(0, quantity).toInt();
  }

  /// Get the total price to display for this item (free when offered)
  double getDisplayTotalPrice() => isOffered() ? 0.0 : getTotalPrice();

  /// Get the unit price to display for this item (free when offered)
  double getDisplayUnitPrice() => isOffered() ? 0.0 : unitPrice;

  /// Get remaining amount to pay
  double getRemainingAmount() {
    if (isOffered()) {
      return 0.0;
    }

    if (partialPaymentHistory != null && partialPaymentHistory!.isNotEmpty) {
      try {
        final decoded = jsonDecode(partialPaymentHistory!);
        if (decoded is List) {
          double coveredAmount = 0.0;
          for (final raw in decoded) {
            if (raw is! Map) continue;
            final qty = (raw['quantity_paid'] as num?)?.toDouble() ?? 0.0;
            final amountPaid = raw['amount_paid'];
            final isOffered = raw['is_offered'] == true;
            if (isOffered) {
              coveredAmount += qty * unitPrice;
            } else if (amountPaid is num) {
              coveredAmount += amountPaid.toDouble();
            } else {
              coveredAmount += qty * unitPrice;
            }
          }
          return (getTotalPrice() - coveredAmount)
              .clamp(0.0, getTotalPrice())
              .toDouble();
        }
      } catch (_) {
        // Fallback below.
      }
    }

    return (getTotalPrice() - paidAmount).clamp(0.0, getTotalPrice()).toDouble();
  }
}
