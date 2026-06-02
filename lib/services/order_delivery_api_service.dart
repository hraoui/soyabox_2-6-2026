import '../api/api_client.dart';
import '../models/order_delivery.dart';
import '../utils/app_logger.dart';

class OrderDeliveryApiService {
  final ApiClient _apiClient;
  final int _restaurantId;

  OrderDeliveryApiService({
    required ApiClient apiClient,
    required int restaurantId,
  }) : _apiClient = apiClient,
       _restaurantId = restaurantId;

  /// Assigner un livreur à une commande
  Future<OrderDelivery?> assignLivreur({
    required int orderId,
    required int livreurId,
  }) async {
    try {
      appLogger.i('📤 Assigning livreur $livreurId to order $orderId...');
      appLogger.i(
        '   - Token: ${_apiClient.token.isNotEmpty ? "PRESENT (${_apiClient.token.substring(0, 10)}...)" : "MISSING"}',
      );

      final response = await _apiClient.postData(
        '/api/restaurants/$_restaurantId/delivery/orders/$orderId/assign',
        {'livreur_id': livreurId},
      );

      appLogger.i('   - Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = _extractDeliveryPayload(response.body);
        if (payload != null) {
          appLogger.i('✅ Livreur assigned successfully');
          return _deliveryFromApi(payload);
        }
      }

      appLogger.i('❌ Failed to assign livreur: ${response.statusCode}');
      appLogger.i('   - Response body: ${response.body}');
      return null;
    } catch (e) {
      appLogger.i('💥 Error assigning livreur: $e');
      return null;
    }
  }

  /// Marquer la commande comme pickup (prise en charge)
  Future<OrderDelivery?> markPickup(int orderId) async {
    try {
      appLogger.i('📤 Marking order $orderId as picked up...');

      final response = await _apiClient.postData(
        '/api/restaurants/$_restaurantId/delivery/orders/$orderId/pickup',
        {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = _extractDeliveryPayload(response.body);
        if (payload != null) {
          appLogger.i('✅ Order marked as picked up');
          return _deliveryFromApi(payload);
        }
      }

      appLogger.i('❌ Failed to mark pickup: ${response.statusCode}');
      return null;
    } catch (e) {
      appLogger.i('💥 Error marking pickup: $e');
      return null;
    }
  }

  /// Marquer la commande comme livrée
  Future<OrderDelivery?> markDelivered(int orderId) async {
    try {
      appLogger.i('📤 Marking order $orderId as delivered...');

      final response = await _apiClient.postData(
        '/api/restaurants/$_restaurantId/delivery/orders/$orderId/deliver',
        {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = _extractDeliveryPayload(response.body);
        if (payload != null) {
          appLogger.i('✅ Order marked as delivered');
          return _deliveryFromApi(payload);
        }
      }

      appLogger.i('❌ Failed to mark delivered: ${response.statusCode}');
      return null;
    } catch (e) {
      appLogger.i('💥 Error marking delivered: $e');
      return null;
    }
  }

  /// Récupérer les détails d'une livraison
  Future<OrderDelivery?> getDeliveryDetails(int orderId) async {
    try {
      final response = await _apiClient.getData('/api/orders/$orderId');

      if (response.statusCode == 200) {
        final payload = _extractDeliveryPayload(response.body);
        if (payload != null) {
          return _deliveryFromApi(payload);
        }
      }
      return null;
    } catch (e) {
      appLogger.i('💥 Error getting delivery details: $e');
      return null;
    }
  }

  OrderDelivery _deliveryFromApi(Map<String, dynamic> data) {
    final livreur = _extractMap(data['livreur']);
    final assignedAtRaw = data['assigned_at'] ?? data['livreur_assigned_at'];
    final pickedUpAtRaw = data['picked_up_at'] ?? data['livreur_picked_at'];
    final deliveredAtRaw = data['delivered_at'] ?? data['livreur_delivered_at'];

    return OrderDelivery(
      orderId: _asInt(data['order_id'] ?? data['id']) ?? 0,
      livreurId: _asInt(data['livreur_id'] ?? livreur['id']),
      livreurName: _asString(data['livreur_name'] ?? livreur['name']),
      livreurPhone: _asString(data['livreur_phone'] ?? livreur['phone']),
      status: _normalizeDeliveryStatus(data),
      assignedAt: assignedAtRaw != null
          ? DateTime.parse(assignedAtRaw as String)
          : null,
      pickedUpAt: pickedUpAtRaw != null
          ? DateTime.parse(pickedUpAtRaw as String)
          : null,
      deliveredAt: deliveredAtRaw != null
          ? DateTime.parse(deliveredAtRaw as String)
          : null,
      note: _asString(data['note']),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic>? _extractDeliveryPayload(dynamic body) {
    if (body is! Map) return null;

    Map<String, dynamic>? pickEntity(Map<String, dynamic> source) {
      const candidateKeys = ['order', 'delivery', 'data'];
      for (final key in candidateKeys) {
        final value = source[key];
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }

      if (source.containsKey('order_id') ||
          source.containsKey('delivery_status') ||
          source.containsKey('status') ||
          source.containsKey('livreur_id')) {
        return source;
      }

      return null;
    }

    final root = Map<String, dynamic>.from(body);
    final direct = pickEntity(root);
    if (direct != null) return direct;

    final nestedData = root['data'];
    if (nestedData is Map) {
      return pickEntity(Map<String, dynamic>.from(nestedData));
    }

    return null;
  }

  Map<String, dynamic> _extractMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  String _normalizeDeliveryStatus(Map<String, dynamic> data) {
    final raw = (data['delivery_status'] ?? data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    switch (raw) {
      case 'assigned':
        return 'assigned';
      case 'picked_up':
      case 'in_delivery':
        return 'picked_up';
      case 'delivered':
        return 'delivered';
      case 'cancelled':
      case 'failed':
        return 'pending';
    }

    if (_asInt(data['livreur_id']) != null ||
        _extractMap(data['livreur']).isNotEmpty) {
      if (data['livreur_delivered_at'] != null ||
          data['delivered_at'] != null) {
        return 'delivered';
      }
      if (data['livreur_picked_at'] != null || data['picked_up_at'] != null) {
        return 'picked_up';
      }
      return 'assigned';
    }

    return 'pending';
  }
}
