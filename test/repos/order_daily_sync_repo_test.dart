import 'package:caisse_1/models/daily_sync_models.dart';
import 'package:caisse_1/models/local_order_database_interface.dart';
import 'package:caisse_1/repos/order_daily_sync_repo.dart';
import 'package:caisse_1/services/order_daily_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeOrderLocalDatabase implements OrderLocalDatabase {
  _FakeOrderLocalDatabase(this.orders);

  final List<LocalOrder> orders;
  int updateCalls = 0;
  List<String> markedLocalIds = <String>[];
  bool? markedFlag;

  @override
  Future<List<LocalOrder>> getOrdersByDateRange({
    required int restaurantId,
    int? staffId,
    required DateTime startDate,
    required DateTime endDate,
    bool excludeDeleted = false,
    bool excludeAlreadySynced = false,
  }) async {
    return orders;
  }

  @override
  Future<void> updateOrdersSyncFlag({
    required List<String> localIds,
    required bool isDailySynced,
  }) async {
    updateCalls++;
    markedLocalIds = List<String>.from(localIds);
    markedFlag = isDailySynced;
  }

  @override
  Future<LocalOrder?> getOrderByLocalId(String localId) async {
    for (final order in orders) {
      if (order.localId == localId) return order;
    }
    return null;
  }

  @override
  Future<List<LocalOrder>> getUnsyncedOrders({
    required int restaurantId,
  }) async {
    return orders.where((o) => !o.isDailySynced).toList(growable: false);
  }
}

class _FakeOrderDailySyncService extends OrderDailySyncService {
  _FakeOrderDailySyncService({required DailySyncResponse response})
    : _response = response,
      super(httpClient: http.Client(), baseUrl: 'http://localhost:8000');

  final DailySyncResponse _response;
  DailyOrderBatch? lastBatch;

  @override
  Future<DailySyncResponse> syncDailyOrders(DailyOrderBatch batch) async {
    lastBatch = batch;
    return _response;
  }
}

LocalOrder _buildOrder(String localId) {
  final now = DateTime.now();
  return LocalOrder(
    localId: localId,
    staffId: 1,
    restaurantId: 1,
    channel: 'pos',
    fulfillmentType: 'on_site',
    status: 'paid',
    paymentStatus: 'paid',
    totalPrice: 100.0,
    originalTotal: 100.0,
    createdAt: now,
    updatedAt: now,
    items: <LocalOrderItem>[
      LocalOrderItem(
        localId: 'item-$localId',
        productId: 1,
        productName: 'Test product',
        unitPrice: 100.0,
        quantity: 1,
      ),
    ],
  );
}

void main() {
  group('OrderDailySyncRepository.syncTodaysOrders', () {
    test(
      'marks all orders as synced when backend reports no failures',
      () async {
        final db = _FakeOrderLocalDatabase([
          _buildOrder('1'),
          _buildOrder('2'),
        ]);
        final service = _FakeOrderDailySyncService(
          response: DailySyncResponse(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: DailySyncStats(total: 2, inserted: 2, skipped: 0, failed: 0),
          ),
        );
        final repo = OrderDailySyncRepository(
          syncService: service,
          localDb: db,
        );

        final response = await repo.syncTodaysOrders(restaurantId: 1);

        expect(response.success, isTrue);
        expect(db.updateCalls, 1);
        expect(db.markedFlag, isTrue);
        expect(db.markedLocalIds.toSet(), {'1', '2'});
      },
    );

    test(
      'marks only non-failed orders when failure details include local_id',
      () async {
        final db = _FakeOrderLocalDatabase([
          _buildOrder('1'),
          _buildOrder('2'),
        ]);
        final service = _FakeOrderDailySyncService(
          response: DailySyncResponse(
            success: true,
            message: 'partial',
            statusCode: 200,
            data: DailySyncStats(
              total: 2,
              inserted: 1,
              skipped: 0,
              failed: 1,
              errors: [SyncError(localId: '2', message: 'Validation failed')],
            ),
          ),
        );
        final repo = OrderDailySyncRepository(
          syncService: service,
          localDb: db,
        );

        final response = await repo.syncTodaysOrders(restaurantId: 1);

        expect(response.success, isTrue);
        expect(db.updateCalls, 1);
        expect(db.markedLocalIds, ['1']);
      },
    );

    test(
      'does not mark orders if failed entries cannot be mapped safely',
      () async {
        final db = _FakeOrderLocalDatabase([
          _buildOrder('1'),
          _buildOrder('2'),
        ]);
        final service = _FakeOrderDailySyncService(
          response: DailySyncResponse(
            success: true,
            message: 'partial',
            statusCode: 200,
            data: DailySyncStats(
              total: 2,
              inserted: 1,
              skipped: 0,
              failed: 1,
              errors: [SyncError(message: 'Unknown failure shape')],
            ),
          ),
        );
        final repo = OrderDailySyncRepository(
          syncService: service,
          localDb: db,
        );

        final response = await repo.syncTodaysOrders(restaurantId: 1);

        expect(response.success, isTrue);
        expect(db.updateCalls, 0);
        expect(db.markedLocalIds, isEmpty);
      },
    );

    test('supports one-based order_index failure mapping', () async {
      final db = _FakeOrderLocalDatabase([_buildOrder('1'), _buildOrder('2')]);
      final service = _FakeOrderDailySyncService(
        response: DailySyncResponse(
          success: true,
          message: 'partial',
          statusCode: 200,
          data: DailySyncStats(
            total: 2,
            inserted: 1,
            skipped: 0,
            failed: 1,
            errors: [SyncError(orderIndex: 2, message: 'Order failed')],
          ),
        ),
      );
      final repo = OrderDailySyncRepository(syncService: service, localDb: db);

      final response = await repo.syncTodaysOrders(restaurantId: 1);

      expect(response.success, isTrue);
      expect(db.updateCalls, 1);
      expect(db.markedLocalIds, ['1']);
    });
  });
}
