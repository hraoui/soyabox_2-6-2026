import 'package:isar/isar.dart';

import '../models/local_order_database_interface.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

// ============================================================
// ISAR IMPLEMENTATION OF ORDER LOCAL DATABASE
// ============================================================

/// Isar implementation of OrderLocalDatabase interface
///
/// This adapter bridges the abstract OrderLocalDatabase interface
/// with the actual Isar database implementation used in this project.
class IsarOrderLocalDatabase implements OrderLocalDatabase {
  final Isar _isar;

  IsarOrderLocalDatabase({Isar? isar}) : _isar = isar ?? DatabaseService.db;

  @override
  Future<List<LocalOrder>> getOrdersByDateRange({
    required int restaurantId,
    int? staffId,
    required DateTime startDate,
    required DateTime endDate,
    bool excludeDeleted = false,
    bool excludeAlreadySynced = false,
  }) async {
    try {
      // Query Isar for orders in the date range
      var query = _isar.posOrders
          .filter()
          .restaurantIdEqualTo(restaurantId)
          .createdAtBetween(startDate, endDate);

      // Apply optional filters
      if (staffId != null) {
        query = query.and().staffIdEqualTo(staffId);
      }

      final orders = await query.findAll();

      // Convert to LocalOrder models
      final localOrders = <LocalOrder>[];

      for (final order in orders) {
        // Apply exclusion filters
        if (excludeDeleted && order.status == 'cancelled') {
          continue;
        }

        if (excludeAlreadySynced && order.isDailySynced) {
          continue;
        }

        // Fetch items for this order
        final items = await _isar.posOrderItems
            .filter()
            .orderIdEqualTo(order.id)
            .findAll();

        localOrders.add(_convertToLocalOrder(order, items));
      }

      appLogger.d(
        '[IsarOrderLocalDatabase] Found ${localOrders.length} orders '
        'for restaurant $restaurantId in date range',
      );

      return localOrders;
    } catch (e, stackTrace) {
      appLogger.e(
        '[IsarOrderLocalDatabase] Error fetching orders by date range',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateOrdersSyncFlag({
    required List<String> localIds,
    required bool isDailySynced,
  }) async {
    if (localIds.isEmpty) {
      appLogger.d('[IsarOrderLocalDatabase] No orders to mark as synced');
      return;
    }

    try {
      await _isar.writeTxn(() async {
        for (final localId in localIds) {
          // Find order by sourceLocalId
          final order = await _isar.posOrders
              .filter()
              .sourceLocalIdEqualTo(int.tryParse(localId))
              .findFirst();

          if (order != null) {
            // Update the isDailySynced field
            order.isDailySynced = isDailySynced;
            order.updatedAt = DateTime.now();
            await _isar.posOrders.put(order);
          }
        }
      });

      appLogger.d(
        '[IsarOrderLocalDatabase] Marked ${localIds.length} orders as '
        'daily synced (flag=$isDailySynced)',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '[IsarOrderLocalDatabase] Error updating sync flag',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<LocalOrder?> getOrderByLocalId(String localId) async {
    try {
      final order = await _isar.posOrders
          .filter()
          .sourceLocalIdEqualTo(int.tryParse(localId))
          .findFirst();

      if (order == null) {
        return null;
      }

      final items = await _isar.posOrderItems
          .filter()
          .orderIdEqualTo(order.id)
          .findAll();

      return _convertToLocalOrder(order, items);
    } catch (e, stackTrace) {
      appLogger.e(
        '[IsarOrderLocalDatabase] Error fetching order by local ID',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<LocalOrder>> getUnsyncedOrders({
    required int restaurantId,
  }) async {
    try {
      // Get all orders for the restaurant
      final orders = await _isar.posOrders
          .filter()
          .restaurantIdEqualTo(restaurantId)
          .findAll();

      final localOrders = <LocalOrder>[];

      for (final order in orders) {
        // Filter for POS channel orders that haven't been synced
        // (channel == 'pos' and not cancelled)
        if (order.channel == 'pos' && order.status != 'cancelled') {
          final items = await _isar.posOrderItems
              .filter()
              .orderIdEqualTo(order.id)
              .findAll();

          localOrders.add(_convertToLocalOrder(order, items));
        }
      }

      appLogger.d(
        '[IsarOrderLocalDatabase] Found ${localOrders.length} unsynced orders '
        'for restaurant $restaurantId',
      );

      return localOrders;
    } catch (e, stackTrace) {
      appLogger.e(
        '[IsarOrderLocalDatabase] Error fetching unsynced orders',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convert PosOrder + items to LocalOrder model
  LocalOrder _convertToLocalOrder(PosOrder order, List<PosOrderItem> items) {
    return LocalOrder(
      localId: (order.sourceLocalId ?? order.id).toString(),
      staffId: order.staffId,
      restaurantId: order.restaurantId ?? 0,
      channel: order.channel,
      fulfillmentType: order.fulfillmentType,
      status: order.status,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      totalPrice: order.totalPrice,
      originalTotal: order.originalTotal,
      discountAmount: order.discountAmount,
      hasDiscount: order.hasDiscount,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      tableNumber: order.tableNumber,
      note: order.note,
      rewardId: order.rewardId,
      cancelReason: order.cancelReason,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: items
          .map(
            (item) => LocalOrderItem(
              localId: item.id.toString(),
              productId: item.productId,
              productName: item.productName,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              groupNumber: item.groupNumber,
              groupLabel: item.groupLabel,
              itemNote: item.itemNote,
              serviceCourseKey: item.serviceCourseKey,
              serviceCourseLabel: item.serviceCourseLabel,
            ),
          )
          .toList(),
      isDailySynced: order.isDailySynced,
      isDeleted: order.status == 'cancelled',
    );
  }
}
