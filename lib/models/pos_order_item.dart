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

  /// Get remaining amount to pay
  double getRemainingAmount() => getTotalPrice() - paidAmount;
}
