import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../data/app_constants.dart';

/// Service to sync order status changes from Flutter to Laravel backend
class OrderSyncService {
  static final OrderSyncService _instance = OrderSyncService._internal();
  factory OrderSyncService() => _instance;
  OrderSyncService._internal();

  String _baseUrl = AppConstant.baseUrl;
  String get baseUrl => _baseUrl;

  void updateBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  /// Sync order status to backend
  /// Returns true if sync successful
  Future<bool> syncOrderStatus({
    required int orderId,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    String? cancelReason,
    int? sourceLocalId,
    int? restaurantId,
    String? deliveryLivreurId,
    String? deliveryLivreurName,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (status != null) body['status'] = status;
      if (paymentStatus != null) body['payment_status'] = paymentStatus;
      if (deliveryStatus != null) body['delivery_status'] = deliveryStatus;
      if (cancelReason != null) body['cancel_reason'] = cancelReason;
      if (sourceLocalId != null) body['source_local_id'] = sourceLocalId;
      if (restaurantId != null) body['restaurant_id'] = restaurantId;
      if (deliveryLivreurId != null) body['delivery_livreur_id'] = deliveryLivreurId;
      if (deliveryLivreurName != null) body['delivery_livreur_name'] = deliveryLivreurName;

      if (body.isEmpty) {
        debugPrint('⚠️ OrderSync: Nothing to sync for order $orderId');
        return false;
      }

      debugPrint('🔄 OrderSync: Syncing order $orderId with status: $status');

      final response = await http.patch(
        Uri.parse('$_baseUrl/api/orders/$orderId/sync-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ OrderSync: Successfully synced order $orderId');
          return true;
        }
      }

      debugPrint('❌ OrderSync: Failed to sync order $orderId - Status: ${response.statusCode}');
      debugPrint('   Response: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ OrderSync: Exception syncing order $orderId: $e');
      return false;
    }
  }

  /// Sync with retry mechanism (3 attempts)
  Future<bool> syncOrderStatusWithRetry({
    required int orderId,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    String? cancelReason,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final success = await syncOrderStatus(
        orderId: orderId,
        status: status,
        paymentStatus: paymentStatus,
        deliveryStatus: deliveryStatus,
        cancelReason: cancelReason,
      );

      if (success) return true;

      if (attempt < maxRetries) {
        debugPrint('🔄 OrderSync: Retry $attempt/$maxRetries for order $orderId');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    debugPrint('❌ OrderSync: All retries failed for order $orderId');
    return false;
  }

  /// Queue-based sync for offline support
  final List<Map<String, dynamic>> _syncQueue = [];
  bool _isSyncing = false;

  void queueStatusSync({
    required int orderId,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    String? cancelReason,
    String? deliveryLivreurId,
    String? deliveryLivreurName,
  }) {
    _syncQueue.add({
      'order_id': orderId,
      'status': status,
      'payment_status': paymentStatus,
      'delivery_status': deliveryStatus,
      'cancel_reason': cancelReason,
      'delivery_livreur_id': deliveryLivreurId,
      'delivery_livreur_name': deliveryLivreurName,
    });

    debugPrint('📦 OrderSync: Queued sync for order $orderId (${_syncQueue.length} in queue)');
    _processSyncQueue();
  }

  Future<void> _processSyncQueue() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    _isSyncing = true;

    while (_syncQueue.isNotEmpty) {
      final item = _syncQueue.first;
      final success = await syncOrderStatus(
        orderId: item['order_id'],
        status: item['status'],
        paymentStatus: item['payment_status'],
        deliveryStatus: item['delivery_status'],
        cancelReason: item['cancel_reason'],
        deliveryLivreurId: item['delivery_livreur_id'],
        deliveryLivreurName: item['delivery_livreur_name'],
      );

      if (success) {
        _syncQueue.removeAt(0);
        debugPrint('✅ OrderSync: Processed queued item (${_syncQueue.length} remaining)');
      } else {
        debugPrint('⏸️ OrderSync: Queue paused - will retry later');
        break;
      }
    }

    _isSyncing = false;
  }
}
