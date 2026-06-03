// ignore_for_file: unused_import

import 'dart:convert';
import 'package:get/get.dart';
import '../utils/app_logger.dart';
import 'package:intl/intl.dart';
import '../models/pos_order.dart';
import '../services/database_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/payment_method_utils.dart';

/// Service pour générer les rapports quotidiens complets
/// Utilise les données existantes sans modifier la logique actuelle
class DailyReportService {
  /// Génère un rapport quotidien complet pour la date spécifiée
  static Future<Map<String, dynamic>> generateDailyReport({
    required DateTime date,
    required int staffId,
    required String staffName,
    DateTime? openedAt,
    DateTime? closedAt,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Charger toutes les commandes POS de la journée
    final orders = await DatabaseService.getPosOrdersByDateRange(
      startOfDay,
      endOfDay,
    );

    // Calculer les statistiques détaillées
    final summary = await _calculateDetailedSummary(orders);

    // Préparer les données des commandes
    final ordersData = await _prepareOrdersData(orders);

    // Obtenir le restaurant_id via Get.find pour éviter les problèmes d'initialisation
    int restaurantId = 1;
    try {
      final authController = Get.find<AuthController>();
      restaurantId = authController.currentUser?.restaurantId ?? 1;
    } catch (e) {
      appLogger.e('Erreur lors de l\'obtention du restaurant_id: $e');
    }

    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'restaurant_id': restaurantId,
      'staff_id': staffId,
      'staff_name': staffName,
      'opened_at': openedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'summary': summary,
      'orders': ordersData,
    };
  }

  /// Calcule le résumé détaillé des statistiques
  static Future<Map<String, dynamic>> _calculateDetailedSummary(
    List<PosOrder> orders,
  ) async {
    double totalRevenue = 0.0;
    int totalOrders = orders.length;

    // Répartition par mode de paiement (basée sur les montants réellement payés)
    final paymentMethods = <String, double>{
      'cash': 0.0,
      'tpe': 0.0,
      'en_compte': 0.0,
      'other': 0.0,
    };

    // Répartition par type de commande
    final orderTypes = <String, int>{'onsite': 0, 'pickup': 0, 'delivery': 0};

    // Répartition par canal
    final channels = <String, double>{
      'pos': 0.0,
      'api': 0.0,
      'web': 0.0,
      'kiosk': 0.0,
    };

    // Statistiques par serveur
    final staffStats = <int, Map<String, dynamic>>{};

    // Statistiques par livreur
    final deliveryStats = <int, Map<String, dynamic>>{};

    final userNameCache = <int, String?>{};

    Future<String?> resolveUserName(int? userId) async {
      if (userId == null) return null;
      if (userNameCache.containsKey(userId)) return userNameCache[userId];
      final user = await DatabaseService.getUserById(userId);
      final name = user?.name;
      userNameCache[userId] = name;
      return name;
    }

    for (final order in orders) {
      final orderPaidMetrics = await _extractOrderPaymentMetrics(order);
      final orderPaidAmount = orderPaidMetrics['paid_amount'] as double;
      final orderPaymentMethods =
          orderPaidMetrics['payment_methods'] as Map<String, double>;

      totalRevenue += orderPaidAmount;

      for (final entry in orderPaymentMethods.entries) {
        paymentMethods[entry.key] =
            (paymentMethods[entry.key] ?? 0.0) + entry.value;
      }

      final fulfillmentType = (order.fulfillmentType).toLowerCase();
      if (fulfillmentType == 'delivery') {
        orderTypes['delivery'] = (orderTypes['delivery'] ?? 0) + 1;
      } else if (fulfillmentType == 'pickup') {
        orderTypes['pickup'] = (orderTypes['pickup'] ?? 0) + 1;
      } else {
        orderTypes['onsite'] = (orderTypes['onsite'] ?? 0) + 1;
      }

      final orderPrice = order.totalPrice;
      final channel = (order.channel).toLowerCase();
      if (channel == 'api') {
        channels['api'] = (channels['api'] ?? 0.0) + orderPrice;
      } else if (channel == 'web') {
        channels['web'] = (channels['web'] ?? 0.0) + orderPrice;
      } else if (channel == 'kiosk') {
        channels['kiosk'] = (channels['kiosk'] ?? 0.0) + orderPrice;
      } else {
        channels['pos'] = (channels['pos'] ?? 0.0) + orderPrice;
      }

      final staffId = order.staffId;
      if (!staffStats.containsKey(staffId)) {
        final staffName = (await resolveUserName(staffId))?.trim();
        staffStats[staffId] = {
          'staff_id': staffId,
          'staff_name': staffName != null && staffName.isNotEmpty
              ? staffName
              : 'Serveur #$staffId',
          'orders_count': 0,
          'total_revenue': 0.0,
          'payment_methods': {
            'cash': 0.0,
            'tpe': 0.0,
            'en_compte': 0.0,
            'other': 0.0,
          },
        };
      }

      final staffStat = staffStats[staffId]!;
      staffStat['orders_count'] = (staffStat['orders_count'] as int) + 1;

      if (orderPaidAmount > 0) {
        staffStat['total_revenue'] =
            (staffStat['total_revenue'] as double) + orderPaidAmount;
        final staffPaymentMethods =
            staffStat['payment_methods'] as Map<String, double>;
        for (final entry in orderPaymentMethods.entries) {
          staffPaymentMethods[entry.key] =
              (staffPaymentMethods[entry.key] ?? 0.0) + entry.value;
        }
      }

      if (order.deliveryLivreurId != null) {
        final deliveryStaffId = order.deliveryLivreurId!;
        if (!deliveryStats.containsKey(deliveryStaffId)) {
          final deliveryStaffName = (await resolveUserName(deliveryStaffId))?.trim() ?? order.deliveryLivreurName?.trim();
          deliveryStats[deliveryStaffId] = {
            'delivery_staff_id': deliveryStaffId,
            'delivery_staff_name': deliveryStaffName != null && deliveryStaffName.isNotEmpty
                ? deliveryStaffName
                : 'Livreur #$deliveryStaffId',
            'delivery_count': 0,
            'delivery_revenue': 0.0,
          };
        }

        final deliveryStat = deliveryStats[deliveryStaffId]!;
        deliveryStat['delivery_count'] =
            (deliveryStat['delivery_count'] as int) + 1;
        if (orderPrice > 0) {
          deliveryStat['delivery_revenue'] =
              (deliveryStat['delivery_revenue'] as double) + orderPrice;
        }
      }
    }

    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'payment_methods': paymentMethods,
      'order_types': orderTypes,
      'channels': channels,
      'staff_breakdown': staffStats.values.toList(),
      'delivery_breakdown': deliveryStats.values.toList(),
    };
  }

  /// Prépare les données des commandes pour le rapport
  static Future<List<Map<String, dynamic>>> _prepareOrdersData(
    List<PosOrder> orders,
  ) async {
    final ordersData = <Map<String, dynamic>>[];

    for (final order in orders) {
      // Obtenir les items de la commande
      final items = await DatabaseService.getPosOrderItems(order.id);
      final itemsCount = items.length;

      final orderStaffUser = await DatabaseService.getUserById(order.staffId);
      final orderStaffName = orderStaffUser?.name.trim();
      final orderDeliveryUser = order.deliveryLivreurId != null
          ? await DatabaseService.getUserById(order.deliveryLivreurId!)
          : null;
      final orderDeliveryStaffName = orderDeliveryUser != null
          ? orderDeliveryUser.name.trim()
          : order.deliveryLivreurName?.trim();

      ordersData.add({
        'order_id': order.id,
        'table_number': order.tableNumber,
        'customer_name': order.customerName,
        'total_amount': order.totalPrice,
        'payment_method': order.paymentMethod,
        'payment_status': order.paymentStatus,
        'order_type': order.fulfillmentType,
        'channel': order.channel,
        'items_count': itemsCount,
        'created_at': order.createdAt.toIso8601String(),
        'staff_id': order.staffId,
        'staff_name': orderStaffName,
        'delivery_staff_id': order.deliveryLivreurId,
        'delivery_staff_name': orderDeliveryStaffName,
      });
    }

    return ordersData;
  }

  static Future<Map<String, dynamic>> _extractOrderPaymentMetrics(
    PosOrder order,
  ) async {
    final metrics = <String, double>{
      'cash': 0.0,
      'tpe': 0.0,
      'en_compte': 0.0,
      'other': 0.0,
    };

    double paidAmount = 0.0;

    // Prefer paymentSplit if available
    if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
      try {
        final decoded = jsonDecode(order.paymentSplit!) as List<dynamic>;
        for (final payment in decoded) {
          final method = normalizePaymentMethod(
            (payment['payment_method'] as String?) ?? '',
          );
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
          paidAmount += amount;
          if (metrics.containsKey(method)) {
            metrics[method] = (metrics[method] ?? 0.0) + amount;
          } else {
            metrics['other'] = (metrics['other'] ?? 0.0) + amount;
          }
        }
      } catch (_) {
        // ignore malformed split, fallback below
      }
    }

    if (paidAmount <= 0) {
      // If paymentSplit is not present or malformed, infer from status + order items
      if (order.paymentStatus.trim().toLowerCase() == 'paid') {
        paidAmount = order.totalPrice;
        final method = normalizePaymentMethod(order.paymentMethod);
        if (metrics.containsKey(method)) {
          metrics[method] = (metrics[method] ?? 0.0) + paidAmount;
        } else {
          metrics['other'] = (metrics['other'] ?? 0.0) + paidAmount;
        }
      } else if (order.paymentStatus.trim().toLowerCase() == 'partially_paid') {
        final items = await DatabaseService.getPosOrderItems(order.id);
        final itemPaid = items.fold<double>(
          0.0,
          (sum, i) => sum + i.paidAmount,
        );
        if (itemPaid > 0) {
          paidAmount = itemPaid;
          if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
            try {
              final decoded = jsonDecode(order.paymentSplit!) as List<dynamic>;
              for (final payment in decoded) {
                final method = normalizePaymentMethod(
                  (payment['payment_method'] as String?) ?? '',
                );
                final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
                if (metrics.containsKey(method)) {
                  metrics[method] = (metrics[method] ?? 0.0) + amount;
                } else {
                  metrics['other'] = (metrics['other'] ?? 0.0) + amount;
                }
              }
            } catch (_) {
              final method = normalizePaymentMethod(order.paymentMethod);
              if (metrics.containsKey(method)) {
                metrics[method] = (metrics[method] ?? 0.0) + itemPaid;
              } else {
                metrics['other'] = (metrics['other'] ?? 0.0) + itemPaid;
              }
            }
          } else {
            final method = normalizePaymentMethod(order.paymentMethod);
            if (metrics.containsKey(method)) {
              metrics[method] = (metrics[method] ?? 0.0) + itemPaid;
            } else {
              metrics['other'] = (metrics['other'] ?? 0.0) + itemPaid;
            }
          }
        }
      }
    }

    return {'paid_amount': paidAmount, 'payment_methods': metrics};
  }
}
