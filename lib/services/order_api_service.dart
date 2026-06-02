import '../api/api_client.dart';
import '../utils/app_logger.dart';

/// Service for managing orders via the backend API
class OrderApiService {
  final ApiClient _apiClient;

  OrderApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all orders
  Future<List<Map<String, dynamic>>> getOrders({int? restaurantId}) async {
    try {
      appLogger.i('📤 Fetching orders...');
      final uri = restaurantId != null
          ? '/api/orders?restaurant_id=$restaurantId'
          : '/api/orders';

      final response = await _apiClient.getData(uri);

      if (response.statusCode == 200) {
        final orders = _extractOrdersList(response.body);
        appLogger.i('✅ Fetched ${orders.length} orders');
        return orders;
      }

      appLogger.i('❌ Failed to fetch orders: ${response.statusCode}');
      return [];
    } catch (e) {
      appLogger.i('💥 Error fetching orders: $e');
      return [];
    }
  }

  /// Get a single order by ID
  Future<Map<String, dynamic>?> getOrder(int orderId) async {
    try {
      appLogger.i('📤 Fetching order #$orderId...');
      final response = await _apiClient.getData('/api/orders/$orderId');

      if (response.statusCode == 200) {
        final order = _extractOrder(response.body);
        appLogger.i('✅ Fetched order #$orderId');
        return order;
      }

      appLogger.i('❌ Failed to fetch order: ${response.statusCode}');
      return null;
    } catch (e) {
      appLogger.i('💥 Error fetching order: $e');
      return null;
    }
  }

  /// Update order status
  /// Backend accepts: PATCH, PUT, or POST to /api/orders/{id}/status
  /// or POST to /api/orders/{id}/update-status
  Future<bool> updateOrderStatus({
    required int orderId,
    required String status,
    String? paymentStatus,
    String? cancelReason,
  }) async {
    try {
      appLogger.i('📤 Updating order #$orderId status to: $status');

      final body = <String, dynamic>{
        'status': status,
        'payment_status': paymentStatus,
        'cancel_reason': cancelReason,
      };

      // Try PATCH first (RESTful)
      final response = await _apiClient.postData(
        '/api/orders/$orderId/update-status',
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        appLogger.i('✅ Order status updated successfully');
        return true;
      }

      appLogger.i('❌ Failed to update order status: ${response.statusCode}');
      appLogger.i('📄 Response: ${response.body}');
      return false;
    } catch (e) {
      appLogger.i('💥 Error updating order status: $e');
      return false;
    }
  }

  /// Delete an order
  /// Note: Backend doesn't have a delete endpoint for orders yet
  /// This will use a workaround or return false if not supported
  Future<bool> deleteOrder(int orderId) async {
    try {
      appLogger.i('📤 Deleting order #$orderId...');

      // Check if backend supports order deletion
      // For now, we'll use a soft delete approach by setting status to cancelled
      // if a hard delete endpoint is not available
      final response = await _apiClient.deleteData('/api/orders/$orderId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        appLogger.i('✅ Order deleted successfully');
        return true;
      }

      appLogger.i(
        '⚠️ Delete endpoint not available (HTTP ${response.statusCode})',
      );
      appLogger.i('📄 Response: ${response.body}');
      return false;
    } catch (e) {
      appLogger.i('💥 Error deleting order: $e');
      return false;
    }
  }

  /// Soft delete by cancelling the order
  Future<bool> cancelOrder({required int orderId, String? reason}) async {
    try {
      appLogger.i('📤 Cancelling order #$orderId...');

      final body = <String, dynamic>{
        'status': 'cancelled',
        if (reason?.isNotEmpty ?? false) 'cancel_reason': reason,
      };

      final response = await _apiClient.postData(
        '/api/orders/$orderId/update-status',
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        appLogger.i('✅ Order cancelled successfully');
        return true;
      }

      appLogger.i('❌ Failed to cancel order: ${response.statusCode}');
      return false;
    } catch (e) {
      appLogger.i('💥 Error cancelling order: $e');
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractOrdersList(dynamic body) {
    if (body == null) return [];

    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (body is Map) {
      // Check for data wrapper
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // Check for orders key
      final orders = body['orders'];
      if (orders is List) {
        return orders
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // Single order in root
      if (body.containsKey('id')) {
        return [Map<String, dynamic>.from(body)];
      }
    }

    return [];
  }

  Map<String, dynamic>? _extractOrder(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      // Check for data wrapper
      final data = body['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      // Check for order key
      final order = body['order'];
      if (order is Map) {
        return Map<String, dynamic>.from(order);
      }

      // Single order in root
      return Map<String, dynamic>.from(body);
    }

    if (body is List && body.isNotEmpty) {
      return Map<String, dynamic>.from(body.first);
    }

    return null;
  }
}
