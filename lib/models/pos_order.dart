import 'package:isar/isar.dart';
import 'dart:convert';
import '../models/payment_split_entry.dart';

part 'pos_order.g.dart';

@Collection()
class PosOrder {
  Id id = Isar.autoIncrement;

  int staffId;
  int? restaurantId;
  @Index()
  int? sourceLocalId;

  @Index()
  String channel; // pos | api | web | kiosk

  @Index()
  bool isFromApi; // ✅ true si commande reçue de API/Web (déjà sur backend)

  String fulfillmentType; // on_site | pickup | delivery

  @Index()
  String status; // pending | paid | cancelled

  double totalPrice;
  double originalTotal;
  double discountAmount;
  bool hasDiscount;
  String? paymentMethod;

  /// JSON string storing multiple payment entries for split payments
  /// Format: List of PaymentSplitEntry JSON objects
  String? paymentSplit;

  /// Detailed payment information for split payments
  @ignore
  List<PaymentSplitEntry>? paymentDetails;

  @Index()
  String paymentStatus; // pending | paid

  /// Staff member who processed the payment (may differ from order creator)
  int? paidByStaffId;

  String? customerName;

  @Index()
  String? customerPhone;

  String? deliveryAddress;
  String? glovoOrderNumber;
  int? deliveryLivreurId;
  String? deliveryLivreurName;
  String? deliveryLivreurPhone;
  int? userId; // ID du créateur de la commande (web/api)
  String? tableNumber;
  String? note;
  int? rewardId;
  String? cancelReason;

  /// Glovo delivery flag (true if order uses Glovo delivery pricing)
  bool isGlovoDelivery = false;

  /// Daily sync flag (true if order has been synced via daily batch sync)
  @Index()
  bool isDailySynced = false;

  @Index()
  DateTime createdAt;

  @Index()
  DateTime updatedAt;

  PosOrder({
    this.id = Isar.autoIncrement,
    required this.staffId,
    this.restaurantId,
    this.sourceLocalId,
    this.channel = 'pos',
    this.isFromApi = false, // ✅ Par défaut false (créée localement)
    required this.fulfillmentType,
    this.status = 'pending',
    this.totalPrice = 0.0,
    this.originalTotal = 0.0,
    this.discountAmount = 0.0,
    this.hasDiscount = false,
    this.paymentMethod,
    this.paymentSplit,
    this.paymentDetails,
    this.paymentStatus = 'pending',
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.glovoOrderNumber,
    this.deliveryLivreurId,
    this.deliveryLivreurName,
    this.deliveryLivreurPhone,
    this.userId,
    this.tableNumber,
    this.note,
    this.rewardId,
    this.cancelReason,
    this.isGlovoDelivery = false,
    this.isDailySynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper method to get parsed payment details
  List<PaymentSplitEntry> getParsedPaymentDetails() {
    if (paymentDetails != null && paymentDetails!.isNotEmpty) {
      return paymentDetails!;
    }
    if (paymentSplit != null && paymentSplit!.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(paymentSplit!);
        return list
            .map((e) => PaymentSplitEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    // If no split payments, return single payment if exists
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      return [
        PaymentSplitEntry(paymentMethod: paymentMethod!, amount: totalPrice),
      ];
    }
    return [];
  }
}
