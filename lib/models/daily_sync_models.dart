import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
// 1️⃣ MODÈLES DE DONNÉES POUR LE BATCH DAILY SYNC
// ============================================================

/// Batch de commandes à synchroniser
class DailyOrderBatch {
  final List<OrderForDailySync> orders;

  DailyOrderBatch({required this.orders});

  Map<String, dynamic> toJson() => {
    'orders': orders.map((o) => o.toJson()).toList(),
  };
}

/// Commande pour le daily sync
class OrderForDailySync {
  final String localId;
  final int staffId;
  final int restaurantId;
  final String channel;
  final String fulfillmentType;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final double totalPrice;
  final double originalTotal;
  final double discountAmount;
  final bool hasDiscount;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? tableNumber;
  final String? note;
  final int? rewardId;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemForDailySync> items;

  OrderForDailySync({
    required this.localId,
    required this.staffId,
    required this.restaurantId,
    required this.channel,
    required this.fulfillmentType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.totalPrice,
    required this.originalTotal,
    required this.discountAmount,
    required this.hasDiscount,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.tableNumber,
    this.note,
    this.rewardId,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'staff_id': staffId,
    'restaurant_id': restaurantId,
    'channel': channel,
    'fulfillment_type': fulfillmentType,
    'status': status,
    'payment_status': paymentStatus,
    'payment_method': paymentMethod ?? 'cod', // ✅ Valeur par défaut si null
    'total_price': totalPrice,
    'original_total': originalTotal,
    'discount_amount': discountAmount,
    'has_discount': hasDiscount,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'delivery_address': deliveryAddress,
    'table_number': tableNumber,
    'note': note,
    'reward_id': rewardId,
    'cancel_reason': cancelReason,
    'created_at': createdAt
        .toIso8601String()
        .replaceAll('T', ' ')
        .split('.')[0],
    'updated_at': updatedAt
        .toIso8601String()
        .replaceAll('T', ' ')
        .split('.')[0],
    'items': items.map((i) => i.toJson()).toList(),
  };
}

/// Item de commande pour le daily sync
class OrderItemForDailySync {
  final String localId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final int? groupNumber;
  final String? groupLabel;
  final String? itemNote;
  final String? serviceCourseKey;
  final String? serviceCourseLabel;

  OrderItemForDailySync({
    required this.localId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.groupNumber,
    this.groupLabel,
    this.itemNote,
    this.serviceCourseKey,
    this.serviceCourseLabel,
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'group_number': groupNumber,
    'group_label': groupLabel,
    'item_note': itemNote,
    'service_course_key': serviceCourseKey,
    'service_course_label': serviceCourseLabel,
  };
}

// ============================================================
// 2️⃣ MODÈLES DE RÉPONSE
// ============================================================

/// Réponse du daily sync
class DailySyncResponse {
  final bool success;
  final String message;
  final DailySyncStats? data;
  final int statusCode;
  final Map<String, dynamic>? errors;

  DailySyncResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.errors,
  });

  factory DailySyncResponse.fromResponse(http.Response response) {
    try {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return DailySyncResponse.error(
          message: 'Empty response body',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final statusCode = response.statusCode;
      final isSuccess = statusCode >= 200 && statusCode < 300;

      // Safely extract data only if present and we expect it
      final dynamic rawData = json['data'];
      DailySyncStats? stats;
      Map<String, dynamic>? errors;

      if (isSuccess && rawData is Map<String, dynamic>) {
        stats = DailySyncStats.fromJson(rawData);
      } else if (!isSuccess && rawData is Map<String, dynamic>) {
        errors = rawData;
      }

      return DailySyncResponse(
        success: isSuccess,
        message: json['message'] ?? 'Unknown response',
        data: stats,
        statusCode: statusCode,
        errors: errors,
      );
    } catch (e) {
      return DailySyncResponse.error(
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  factory DailySyncResponse.error({
    required String message,
    required int statusCode,
  }) {
    return DailySyncResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Statistiques du daily sync
class DailySyncStats {
  final int total;
  final int inserted;
  final int skipped;
  final int failed;
  final List<SyncError>? errors;

  DailySyncStats({
    required this.total,
    required this.inserted,
    required this.skipped,
    required this.failed,
    this.errors,
  });

  factory DailySyncStats.fromJson(Map<String, dynamic> json) {
    return DailySyncStats(
      total: json['total'] ?? 0,
      inserted: json['inserted'] ?? 0,
      skipped: json['skipped'] ?? 0,
      failed: json['failed'] ?? 0,
      errors: (json['errors'] as List?)
          ?.map((e) => SyncError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Erreur de sync
class SyncError {
  final int? orderIndex;
  final String? localId;
  final String message;
  final int? itemIndex;

  SyncError({
    this.orderIndex,
    this.localId,
    required this.message,
    this.itemIndex,
  });

  factory SyncError.fromJson(Map<String, dynamic> json) {
    return SyncError(
      orderIndex: json['order_index'] as int?,
      localId: json['local_id']?.toString(),
      message: json['message'] ?? 'Unknown error',
      itemIndex: json['item_index'] as int?,
    );
  }

  @override
  String toString() =>
      'Error at order $orderIndex (local_id: $localId): $message';
}

/// Réponse du rapport daily
class DailyReportResponse {
  final bool success;
  final String message;
  final DailyReportData? data;
  final int statusCode;

  DailyReportResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory DailyReportResponse.fromResponse(http.Response response) {
    try {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return DailyReportResponse.error(
          message: 'Empty response body',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final statusCode = response.statusCode;
      final isSuccess = statusCode >= 200 && statusCode < 300;

      // Safely extract data only if present and we expect it
      final dynamic rawData = json['data'];
      DailyReportData? reportData;

      if (isSuccess && rawData is Map<String, dynamic>) {
        reportData = DailyReportData.fromJson(rawData);
      }

      return DailyReportResponse(
        success: isSuccess,
        message: json['message'] ?? 'Unknown response',
        data: reportData,
        statusCode: statusCode,
      );
    } catch (e) {
      return DailyReportResponse.error(
        message: 'Failed to parse report: $e',
        statusCode: response.statusCode,
      );
    }
  }

  factory DailyReportResponse.error({
    required String message,
    required int statusCode,
  }) {
    return DailyReportResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Données du rapport daily
class DailyReportData {
  final String date;
  final int restaurantId;
  final int totalOrders;
  final double totalRevenue;
  final List<dynamic> orders;

  DailyReportData({
    required this.date,
    required this.restaurantId,
    required this.totalOrders,
    required this.totalRevenue,
    required this.orders,
  });

  factory DailyReportData.fromJson(Map<String, dynamic> json) {
    return DailyReportData(
      date: json['date'] ?? '',
      restaurantId: json['restaurant_id'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? [],
    );
  }
}
