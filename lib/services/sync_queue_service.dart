import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../utils/path_utils.dart';
import 'package:synchronized/synchronized.dart';

import '../data/app_constants.dart';
import '../models/category_model.dart';
import '../models/delivery.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/product_model.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import 'api_order_pull_service.dart';
import 'database_service.dart';

class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  // Sync toggle: send orders to backend
  static const bool _syncOrdersEnabled = true;
  static const int _maxRetryCount = 3;
  static const Duration _minRequestSpacing = Duration(milliseconds: 300);
  static const Duration _defaultRateLimitDelay = Duration(seconds: 5);
  static const Duration _maxRateLimitDelay = Duration(minutes: 5);
  static const Duration _periodicFlushInterval = Duration(seconds: 45);
  static const Duration _enqueueFlushDebounce = Duration(seconds: 2);

  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _deadLetterQueue = <Map<String, dynamic>>[];
  final Map<int, String> _ordersSyncState = <int, String>{};
  final Map<String, String> _usersSyncState =
      <String, String>{}; // email -> updatedAt

  // CRITICAL FIX #1: Add lock to prevent race conditions
  final _enqueueLock = Lock();
  final _syncStateLock = Lock();
  final _usersSyncStateLock = Lock();

  Timer? _timer;
  Timer? _flushDebounceTimer;
  File? _queueFile;
  File? _deadLetterFile;
  File? _ordersStateFile;
  File? _ordersStateBackupFile;
  File? _ordersStateTxnFile;
  File? _usersStateFile;
  bool _initialized = false;
  bool _isFlushing = false;
  String _baseUrlRaw = AppConstant.baseUrl;
  String get _baseUrl => _baseUrlRaw.replaceAll(RegExp(r'/+$'), '');
  String _authToken = AppConstant.apiToken;
  bool get _hasAuthToken => _authToken.trim().isNotEmpty;
  int get pendingCount => _queue.length;
  List<Map<String, dynamic>> getFailedItems() => _deadLetterQueue
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
  DateTime? _lastRequestAt;
  DateTime? _rateLimitedUntil;
  int _rateLimitStrikeCount = 0;

  Future<void> init({String? baseUrl, String? authToken}) async {
    appLogger.i('🔄 [SYNCQ] Initializing SyncQueueService...');
    if (_initialized) {
      if (baseUrl != null && baseUrl.trim().isNotEmpty) {
        _baseUrlRaw = baseUrl.trim();
      }
      if (authToken != null) {
        _authToken = authToken.trim();
      }
      appLogger.i('✅ [SYNCQ] Already initialized, updated config');
      return;
    }
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrlRaw = baseUrl.trim();
    }
    if (authToken != null) {
      _authToken = authToken.trim();
    }
    appLogger.i('📁 [SYNCQ] Getting documents directory...');
    final dir = await getAppDocumentsDirectory();
    appLogger.i('✅ [SYNCQ] Directory: ${dir.path}');

    _queueFile = File('${dir.path}/sync_queue.json');
    _deadLetterFile = File('${dir.path}/sync_dead_letter_queue.json');
    _ordersStateFile = File('${dir.path}/orders_sync_state.json');
    _ordersStateBackupFile = File('${dir.path}/orders_sync_state.json.backup');
    _ordersStateTxnFile = File('${dir.path}/orders_sync_state.pending.json');
    _usersStateFile = File('${dir.path}/users_sync_state.json');
    appLogger.i('📖 [SYNCQ] Loading queue (${_queueFile!.path})...');

    await _loadQueue();
    appLogger.i('✅ [SYNCQ] Queue loaded (${_queue.length} items)');

    appLogger.i('📖 [SYNCQ] Loading dead letter queue...');
    await _loadDeadLetterQueue();
    appLogger.i(
      '✅ [SYNCQ] Dead letter queue loaded (${_deadLetterQueue.length} items)',
    );

    appLogger.i('📖 [SYNCQ] Loading orders sync state...');
    final loadStateStart = DateTime.now();
    try {
      await _loadOrdersSyncState();
      final loadStateDuration = DateTime.now().difference(loadStateStart);
      appLogger.i(
        '✅ [SYNCQ] Orders sync state loaded (${_ordersSyncState.length} orders) in ${loadStateDuration.inMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      appLogger.i('❌ [SYNCQ] Failed to load orders sync state: $e');
      appLogger.e(
        'Failed to load orders sync state',
        error: e,
        stackTrace: stackTrace,
      );
      _ordersSyncState.clear();
    }

    appLogger.i('🔧 [SYNCQ] Recovering orders state transaction...');
    final recoverStart = DateTime.now();
    try {
      await _recoverOrdersStateTransaction();
      final recoverDuration = DateTime.now().difference(recoverStart);
      appLogger.i(
        '✅ [SYNCQ] Orders state transaction recovered in ${recoverDuration.inMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      appLogger.i('❌ [SYNCQ] Failed to recover orders state transaction: $e');
      appLogger.e(
        'Failed to recover orders state transaction',
        error: e,
        stackTrace: stackTrace,
      );
    }

    appLogger.i('⏰ [SYNCQ] Starting periodic flush timer...');
    final timerStart = DateTime.now();
    try {
      _startPeriodicFlush();
      final timerDuration = DateTime.now().difference(timerStart);
      appLogger.i(
        '✅ [SYNCQ] Periodic flush started in ${timerDuration.inMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      appLogger.i('❌ [SYNCQ] Failed to start periodic flush: $e');
      appLogger.e(
        'Failed to start periodic flush',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _initialized = true;
    appLogger.i('✅ [SYNCQ] SyncQueueService initialized successfully');
  }

  void updateBaseUrl(String baseUrl) {
    if (baseUrl.trim().isEmpty) return;
    _baseUrlRaw = baseUrl.trim();
  }

  void updateAuthToken(String token) {
    final oldToken = _authToken;
    _authToken = token.trim();
    final newTokenPreview = _authToken.isNotEmpty
        ? '${_authToken.substring(0, _authToken.length > 20 ? 20 : _authToken.length)}...'
        : 'EMPTY';
    final oldTokenPreview = oldToken.isNotEmpty
        ? '${oldToken.substring(0, oldToken.length > 20 ? 20 : oldToken.length)}...'
        : 'EMPTY';

    if (oldToken != _authToken) {
      appLogger.i(
        '🔑 [SYNCQ] Token updated: $oldTokenPreview → $newTokenPreview',
      );
    }
  }

  Future<void> enqueueUserUpsert(User user) async {
    await _enqueue(
      entity: 'users',
      action: 'upsert',
      dedupeKey: 'users:upsert:${user.email.toLowerCase()}',
      payload: {
        'id': user.id,
        'name': user.name,
        'phone': user.phone,
        'email': user.email,
        'password': user.password,
        'role': user.role,
        'restaurant_id': user.restaurantId,
        'pin_code': user.pinCode,
        // 'badge_code': user.badgeCode, // ❌ Not supported by backend
        'is_active': user.isActive,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueUserDelete(int userId, {String? email}) async {
    await _enqueue(
      entity: 'users',
      action: 'delete',
      dedupeKey: 'users:delete:${email?.toLowerCase() ?? userId}',
      payload: {'id': userId, 'email': email},
    );
  }

  // 🚚 Sync des livreurs (Deliveries)
  Future<void> enqueueDeliveryUpsert(Delivery delivery) async {
    await _enqueue(
      entity: 'deliveries',
      action: 'upsert',
      dedupeKey: 'deliveries:upsert:${delivery.email.toLowerCase()}',
      payload: {
        'id': delivery.id,
        'name': delivery.name,
        'phone': delivery.phone,
        'email': delivery.email,
        'password': delivery.password,
        'restaurant_id': delivery.restaurantId,
        'is_active': delivery.isActive,
        'pin_code': delivery.pinCode,
        'role': 'livreur',
        'created_at': delivery.createdAt.toIso8601String(),
        'updated_at': delivery.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueDeliveryDelete(int deliveryId, {String? email}) async {
    await _enqueue(
      entity: 'deliveries',
      action: 'delete',
      dedupeKey: 'deliveries:delete:${email?.toLowerCase() ?? deliveryId}',
      payload: {'id': deliveryId, 'email': email},
    );
  }

  Future<void> enqueueCategoryUpsert(Category category) async {
    await _enqueue(
      entity: 'categories',
      action: 'upsert',
      dedupeKey: 'categories:upsert:${category.id}',
      payload: {
        'id': category.id,
        'name': category.name,
        'image': category.image,
        'is_deleted': category.isDeleted,
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueCategoryDelete(int categoryId) async {
    await _enqueue(
      entity: 'categories',
      action: 'delete',
      dedupeKey: 'categories:delete:$categoryId',
      payload: {'id': categoryId},
    );
  }

  Future<void> enqueueProductUpsert(Product product) async {
    await _enqueue(
      entity: 'products',
      action: 'upsert',
      dedupeKey: 'products:upsert:${product.id}',
      payload: {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'image': product.image,
        'category_id': product.categoryId,
        'offer': product.offer,
        'is_available': product.isAvailable,
        'sort_order': product.sortOrder,
        'created_at': product.createdAt.toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueProductDelete(int productId) async {
    await _enqueue(
      entity: 'products',
      action: 'delete',
      dedupeKey: 'products:delete:$productId',
      payload: {'id': productId},
    );
  }

  /// Synchroniser le statut d'une commande API vers le backend
  /// Utilisé pour mettre à jour le statut des commandes web/api sans resynchroniser toute la commande
  Future<bool> syncApiOrderStatus({
    required PosOrder order,
    required String status,
    String? paymentStatus,
    String? cancelReason,
  }) async {
    if (!_syncOrdersEnabled) {
      appLogger.w('⚠️ [SYNC STATUS] Order sync disabled, skipping');
      return false;
    }
    if (!_hasAuthToken) {
      appLogger.w('⚠️ [SYNC STATUS] No auth token, skipping');
      return false;
    }
    if (!_isRemoteOrderChannel(order.channel)) {
      appLogger.w(
        '⚠️ [SYNC STATUS] Order #${order.id} is not a remote channel (${order.channel}), skipping',
      );
      return false;
    }

    try {
      final normalizedStatus = _normalizeOrderStatus(status);
      ApiOrderPullService.instance.updateAuthToken(_authToken);
      final ok = await ApiOrderPullService.instance
          .pushRemoteOrderStatusByLocalId(
            localOrderId: order.id,
            status: normalizedStatus,
            paymentStatus: paymentStatus,
            cancelReason: cancelReason,
          );
      if (ok) {
        appLogger.i(
          '✅ [SYNC STATUS] Order #${order.id} status synced successfully',
        );
        // Mettre à jour l'état de synchronisation
        _ordersSyncState[order.id] = order.updatedAt.toIso8601String();
        await _saveOrdersSyncState();
        return true;
      } else {
        appLogger.e('❌ [SYNC STATUS] Failed to sync order #${order.id} status');
        return false;
      }
    } catch (e) {
      appLogger.e('❌ [SYNC STATUS] Error syncing order status: $e');
      return false;
    }
  }

  Future<void> enqueueRemoteOrderStatusSync({
    required PosOrder order,
    String? status,
    String? paymentStatus,
    String? cancelReason,
  }) async {
    if (!_syncOrdersEnabled) return;
    if (!_isRemoteOrderChannel(order.channel)) return;

    await _enqueue(
      entity: 'orders',
      action: 'status',
      dedupeKey: 'orders:status:${order.id}',
      payload: {
        'local_id': order.id,
        'source_local_id': order.sourceLocalId ?? order.id,
        'channel': order.channel,
        'status': _normalizeOrderStatus(status ?? order.status),
        'payment_status': paymentStatus ?? order.paymentStatus,
        'cancel_reason': cancelReason ?? order.cancelReason,
        'updated_at': order.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueOrderUpsert(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    // CRITICAL FIX #2: Use lock to prevent race conditions
    await _enqueueLock.synchronized(() async {
      await _enqueueOrderUpsertInternal(order, items);
    });
  }

  Future<void> _enqueueOrderUpsertInternal(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    if (!_syncOrdersEnabled) return;
    if (!_shouldSyncOrderUpsert(order)) {
      return;
    }

    // CRITICAL: Check if order is already in queue BEFORE any other check
    // This prevents the same order from being added multiple times
    final alreadyInQueue = _queue.where((item) {
      if (item['entity'] != 'orders' || item['action'] != 'upsert') {
        return false;
      }
      final payload = item['payload'] as Map<String, dynamic>?;
      return payload?['local_id'] == order.id;
    }).toList();

    if (alreadyInQueue.isNotEmpty) {
      appLogger.d(
        '⏭️ [ENQUEUE SKIP] Order #${order.id} already in queue (${alreadyInQueue.length} times), skipping',
      );
      return;
    }

    final updatedAt = order.updatedAt.toIso8601String();
    final lastSyncedUpdatedAt = _ordersSyncState[order.id];

    // Skip if already synced (syncedAt >= updatedAt)
    if (lastSyncedUpdatedAt != null) {
      try {
        final syncedAt = DateTime.parse(lastSyncedUpdatedAt);
        final now = DateTime.now();

        // FIX: Detect and clear invalid future dates in sync state
        if (syncedAt.isAfter(now.add(const Duration(minutes: 5)))) {
          appLogger.w(
            '🚨 [SYNC STATE FIX] Order #${order.id} has FUTURE syncedAt ($lastSyncedUpdatedAt), clearing invalid state',
          );
          _ordersSyncState.remove(order.id);
          await _saveOrdersSyncState();
        } else if (!syncedAt.isBefore(order.updatedAt)) {
          appLogger.d(
            '⏭️ [SYNC SKIP] Order #${order.id} already synced '
            '(syncedAt=$lastSyncedUpdatedAt >= updatedAt=$updatedAt)',
          );
          return;
        }
      } catch (e) {
        appLogger.w(
          '⚠️ [SYNC SKIP] Failed to parse syncedAt for Order #${order.id}: $lastSyncedUpdatedAt, error: $e',
        );
      }
    }

    // CRITICAL FIX #3: Validate order data BEFORE syncing
    if (order.staffId <= 0) {
      appLogger.e(
        '❌ [SYNC SKIP] Order #${order.id} has invalid staffId: ${order.staffId}',
      );
      return;
    }

    final staffUser = await DatabaseService.getUserById(order.staffId);
    final resolvedRestaurantId = order.restaurantId ?? staffUser?.restaurantId;

    if (resolvedRestaurantId == null || resolvedRestaurantId <= 0) {
      appLogger.e(
        '❌ [SYNC SKIP] Order #${order.id} has invalid restaurantId: $resolvedRestaurantId',
      );
      return;
    }

    final normalizedStatus = _normalizeOrderStatus(order.status);
    final normalizedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final resolvedProductId = await _resolveProductIdForSync(item);
      final itemData = <String, dynamic>{
        'local_id': item.id,
        'source_local_item_id': item.id,
        'product_id': resolvedProductId,
        'product_name': item.productName,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
        'group_number': item.groupNumber,
        'group_label': item.groupLabel,
        'item_note': item.itemNote,
        'service_course_key': item.serviceCourseKey,
        'service_course_label': item.serviceCourseLabel,
        'price_type': item.priceType, // Glovo price type
        'created_at': item.createdAt.toIso8601String(),
      };
      // Add base price and supplement for Glovo orders
      if (item.priceType == 'glovo' && item.glovoBasePrice != null) {
        itemData['base_price'] = item.glovoBasePrice;
        itemData['glovo_supplement'] = item.unitPrice - item.glovoBasePrice!;
      }
      normalizedItems.add(itemData);
    }

    await _enqueue(
      entity: 'orders',
      action: 'upsert',
      dedupeKey: 'orders:upsert:${order.id}',
      payload: {
        'local_id': order.id,
        'source_local_id': order.sourceLocalId ?? order.id,
        'staff_id': order.staffId,
        'user_id': order.staffId,
        'restaurant_id': resolvedRestaurantId,
        'staff_name': staffUser?.name,
        'client_order_id': 'pos-${order.id}',
        'synced_from': 'flutter_pos',
        'channel': order.channel,
        'is_from_api': order.isFromApi,
        'fulfillment_type': order.fulfillmentType,
        'is_glovo_delivery': order.isGlovoDelivery, // Glovo delivery flag
        'status': normalizedStatus,
        'payment_status': order.paymentStatus,
        'payment_method':
            order.paymentMethod ?? 'cod', // ✅ Valeur par défaut si null
        'total_price': order.totalPrice,
        'original_total': order.originalTotal,
        'discount_amount': order.discountAmount,
        'has_discount': order.hasDiscount,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'delivery_address': order.deliveryAddress,
        'glovo_order_number': order.glovoOrderNumber,
        'table_number': order.tableNumber,
        'note': order.note,
        'reward_id': order.rewardId,
        'cancel_reason': order.cancelReason,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': updatedAt,
        'items': normalizedItems,
      },
    );
  }

  Future<void> enqueueOrderDelete(int localOrderId) async {
    if (!_syncOrdersEnabled) return;
    await init();
    final order = await DatabaseService.getPosOrderById(localOrderId);
    if (order != null) {
      if (!_shouldSyncOrderUpsert(order)) {
        return;
      }
    }

    await _enqueue(
      entity: 'orders',
      action: 'delete',
      dedupeKey: 'orders:delete:$localOrderId',
      payload: {
        'local_id': localOrderId,
        'source_local_id': order?.sourceLocalId ?? localOrderId,
      },
    );
  }

  Future<void> queueUnsyncedOrders({int? onlyStaffId}) async {
    if (!_syncOrdersEnabled) return;
    await init();
    await DatabaseService.init();

    // ✅ FIX: Use calendar day 00:00-23:59 instead of service day 06:00-05:59
    final now = DateTime.now().toLocal();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      0,
      0,
      0,
    ); // 00:00 today
    final end = start.add(
      const Duration(days: 1),
    ); // 24 hours later (00:00 tomorrow)

    List<PosOrder> allOrders;
    try {
      allOrders = await DatabaseService.getPosOrders();
    } catch (e) {
      appLogger.e('❌ [QUEUE SCAN] Failed to load PosOrders: $e');
      // If we can't read orders due to corruption, skip this scan
      // The corruption handler in DatabaseService should have cleared the data
      return;
    }
    final orders = allOrders.where((o) {
      // Only orders from current calendar day (00:00-23:59)
      final isToday = !o.createdAt.isBefore(start) && o.createdAt.isBefore(end);
      return isToday;
    }).toList();

    appLogger.d(
      '📋 [QUEUE SCAN] Calendar day: ${start.toString().substring(0, 19)} to ${end.toString().substring(0, 19)} (00:00-23:59), '
      'filtered ${allOrders.length} -> ${orders.length} orders',
    );

    // Build a set of orders already in the queue to avoid duplicates
    final queuedOrderIds = <int>{};
    for (final item in _queue) {
      if (item['entity'] == 'orders' && item['action'] == 'upsert') {
        final payload = item['payload'] as Map<String, dynamic>?;
        final localId = payload?['local_id'] as int?;
        if (localId != null) {
          queuedOrderIds.add(localId);
        }
      }
    }

    appLogger.d(
      '📋 [QUEUE SCAN] Scanning ${orders.length} orders, ${queuedOrderIds.length} already in queue',
    );

    int addedCount = 0;
    int skippedCount = 0;
    int syncedCount = 0;

    for (final order in orders) {
      // ✅ SKIP si commande reçue de API/Web (déjà sur backend)
      if (order.isFromApi) {
        appLogger.d(
          '⏭️ [SKIP API ORDER] Order #${order.id} isFromApi=true, skipping sync',
        );
        continue;
      }

      if (!_shouldSyncOrderUpsert(order)) {
        continue;
      }

      if (onlyStaffId != null &&
          onlyStaffId > 0 &&
          order.staffId != onlyStaffId) {
        continue;
      }

      // Skip if already in queue
      if (queuedOrderIds.contains(order.id)) {
        appLogger.d(
          '⏭️ [QUEUE SKIP] Order #${order.id} already in queue, skipping',
        );
        skippedCount++;
        continue;
      }

      final currentUpdatedAt = order.updatedAt.toIso8601String();
      final syncedUpdatedAt = _ordersSyncState[order.id];

      // Debug: Log sync state for this order
      appLogger.d(
        '🔍 [SYNC CHECK] Order #${order.id}: updatedAt=$currentUpdatedAt, syncedAt=$syncedUpdatedAt',
      );

      // Skip if already synced (syncedAt >= updatedAt means it was synced after last update)
      if (syncedUpdatedAt != null) {
        try {
          final syncedAt = DateTime.parse(syncedUpdatedAt);
          final now = DateTime.now();

          // FIX: Detect and clear invalid future dates in sync state
          if (syncedAt.isAfter(now.add(const Duration(minutes: 5)))) {
            appLogger.w(
              '🚨 [SYNC STATE FIX] Order #${order.id} has FUTURE syncedAt ($syncedUpdatedAt), clearing invalid state',
            );
            _ordersSyncState.remove(order.id);
            await _saveOrdersSyncState();
          } else {
            final isSynced = !syncedAt.isBefore(order.updatedAt);
            appLogger.d(
              '🔍 [SYNC CHECK] Order #${order.id}: syncedAt.isBefore(updatedAt)=${syncedAt.isBefore(order.updatedAt)}, isSynced=$isSynced',
            );
            if (isSynced) {
              appLogger.d(
                '⏭️ [SYNC STATE SKIP] Order #${order.id} already synced '
                '(syncedAt=$syncedUpdatedAt >= updatedAt=$currentUpdatedAt)',
              );
              syncedCount++;
              continue;
            }
          }
        } catch (e) {
          appLogger.w(
            '⚠️ [SYNC STATE] Failed to parse syncedAt for Order #${order.id}: $syncedUpdatedAt, error: $e',
          );
        }
      }

      appLogger.i(
        '📥 [QUEUE ADD] Order #${order.id} queued for sync '
        '(updatedAt=$currentUpdatedAt, syncedAt=$syncedUpdatedAt)',
      );

      final items = await DatabaseService.getPosOrderItems(order.id);
      await enqueueOrderUpsert(order, items);
      queuedOrderIds.add(
        order.id,
      ); // Add to set to avoid re-adding in same scan
      addedCount++;
    }

    appLogger.i(
      '📊 [QUEUE SCAN] Complete: added=$addedCount, skipped=$skippedCount, synced=$syncedCount, queue_size=${_queue.length}',
    );
  }

  /// Queue unsynced users to backend (local -> backend only)
  /// Does NOT pull users from backend to local
  Future<void> queueUnsyncedUsers() async {
    if (!_syncOrdersEnabled) return;
    await init();
    await DatabaseService.init();

    final allUsers = await DatabaseService.getAllUsers();

    appLogger.d(
      '📋 [USER QUEUE SCAN] Scanning ${allUsers.length} local users for sync to backend',
    );

    int addedCount = 0;
    int skippedCount = 0;

    for (final user in allUsers) {
      // Skip if user has no email (invalid user)
      final email = user.email.trim();
      if (email.isEmpty) {
        appLogger.d(
          '⏭️ [USER SKIP] User #${user.id} has no email, skipping sync',
        );
        skippedCount++;
        continue;
      }

      final emailKey = email.toLowerCase();
      final currentUpdatedAt = user.updatedAt.toIso8601String();
      final syncedUpdatedAt = _usersSyncState[emailKey];

      // Skip if already in queue
      final alreadyInQueue = _queue.where((item) {
        if (item['entity'] != 'users' || item['action'] != 'upsert') {
          return false;
        }
        final payload = item['payload'] as Map<String, dynamic>?;
        return payload?['email']?.toLowerCase() == emailKey;
      }).toList();

      if (alreadyInQueue.isNotEmpty) {
        appLogger.d(
          '⏭️ [USER QUEUE SKIP] User ${user.email} already in queue, skipping',
        );
        skippedCount++;
        continue;
      }

      // Skip if already synced (syncedAt >= updatedAt)
      if (syncedUpdatedAt != null) {
        try {
          final syncedAt = DateTime.parse(syncedUpdatedAt);
          final now = DateTime.now();

          // Detect and clear invalid future dates
          if (syncedAt.isAfter(now.add(const Duration(minutes: 5)))) {
            appLogger.w(
              '🚨 [USER SYNC STATE FIX] User ${user.email} has FUTURE syncedAt, clearing state',
            );
            _usersSyncState.remove(emailKey);
            await _saveUsersSyncState();
          } else if (!syncedAt.isBefore(user.updatedAt)) {
            appLogger.d(
              '⏭️ [USER SYNC SKIP] User ${user.email} already synced '
              '(syncedAt=$syncedUpdatedAt >= updatedAt=$currentUpdatedAt)',
            );
            skippedCount++;
            continue;
          }
        } catch (e) {
          appLogger.w(
            '⚠️ [USER SYNC STATE] Failed to parse syncedAt for User ${user.email}: $syncedUpdatedAt, error: $e',
          );
        }
      }

      appLogger.i(
        '📥 [USER QUEUE ADD] User ${user.email} (ID:${user.id}) queued for sync to backend',
      );

      await enqueueUserUpsert(user);
      addedCount++;
    }

    appLogger.i(
      '📊 [USER QUEUE SCAN] Complete: added=$addedCount, skipped=$skippedCount, queue_size=${_queue.length}',
    );
  }

  Future<void> flushQueue() async {
    await init();
    appLogger.d(
      '🔄 flushQueue: pending=${_queue.length}, hasAuth=$_hasAuthToken, rateLimited=$_isRateLimited',
    );
    if (_isFlushing || _queue.isEmpty || !_hasAuthToken || _isRateLimited) {
      appLogger.d(
        '⚠️ flushQueue skipped: isFlushing=$_isFlushing, empty=${_queue.isEmpty}, noAuth=${!_hasAuthToken}, rateLimited=$_isRateLimited',
      );
      return;
    }
    _isFlushing = true;
    try {
      appLogger.d('📤 Starting to flush ${_queue.length} items from queue');
      final failedItems = <Map<String, dynamic>>[];
      final snapshot = List<Map<String, dynamic>>.from(_queue);
      int successCount = 0;
      int failedCount = 0;

      for (var index = 0; index < snapshot.length; index++) {
        final item = snapshot[index];
        appLogger.d(
          '📦 Processing queue item ${index + 1}/${snapshot.length}: entity=${item['entity']}, action=${item['action']}',
        );
        if (_isRateLimited) {
          appLogger.d('⏳ Rate limited, stopping flush');
          failedItems.addAll(snapshot.skip(index));
          break;
        }
        await _prepareOrdersStateTransaction(item);
        final outcome = await _sendItem(item);
        if (outcome == _QueueSendOutcome.deadLettered ||
            item['dead_lettered'] == true) {
          await _clearOrdersStateTransaction();
          appLogger.d(
            '🚨 Queue item moved to dead letter: entity=${item['entity']}, action=${item['action']}, reason=${item['skip_reason']}',
          );
          failedCount++;
          continue;
        }
        if (outcome == _QueueSendOutcome.retryable) {
          await _clearOrdersStateTransaction();
          appLogger.d(
            '❌ Failed to send item: entity=${item['entity']}, action=${item['action']}',
          );
          failedItems.add(item);
          failedCount++;
          continue;
        }
        appLogger.d(
          '✅ Successfully sent item: entity=${item['entity']}, action=${item['action']}',
        );
        successCount++;

        // CRITICAL FIX #7: Update sync state IMMEDIATELY after success
        // This prevents re-sync if app crashes before queue is cleared
        if (item['entity'] == 'orders' &&
            (item['action'] == 'upsert' || item['action'] == 'status') &&
            item['payload'] is Map<String, dynamic>) {
          final payload = item['payload'] as Map<String, dynamic>;
          final localId = payload['local_id'];
          final updatedAt = payload['updated_at'];
          if (localId is int && updatedAt is String) {
            _ordersSyncState[localId] = updatedAt;
            // Save immediately after each successful sync
            await _saveOrdersSyncState();
            appLogger.d('💾 [SYNC STATE] Saved sync state for Order #$localId');
          }
        }

        // ✅ Save user sync state after successful sync
        if (item['entity'] == 'users' &&
            item['action'] == 'upsert' &&
            item['payload'] is Map<String, dynamic>) {
          final payload = item['payload'] as Map<String, dynamic>;
          final email = payload['email']?.toString().toLowerCase();
          final updatedAt = payload['updated_at'];
          if (email != null && email.isNotEmpty && updatedAt is String) {
            _usersSyncState[email] = updatedAt;
            // Save immediately after each successful sync
            await _saveUsersSyncState();
            appLogger.d(
              '💾 [USER SYNC STATE] Saved sync state for User $email',
            );
          }
        }

        await _clearOrdersStateTransaction();
      }

      appLogger.i(
        '📊 [FLUSH QUEUE] Complete: success=$successCount, failed=$failedCount, remaining=${failedItems.length}',
      );

      _queue
        ..clear()
        ..addAll(failedItems);
      await _saveQueue();
    } finally {
      _isFlushing = false;
    }
  }

  void _startPeriodicFlush() {
    _timer?.cancel();
    _timer = Timer.periodic(_periodicFlushInterval, (_) async {
      await queueUnsyncedOrders();
      await queueUnsyncedUsers(); // ✅ Add users to sync queue
      await flushQueue();
    });
  }

  Future<void> _enqueue({
    required String entity,
    required String action,
    required String dedupeKey,
    required Map<String, dynamic> payload,
  }) async {
    await init();
    final existingIndex = _queue.indexWhere(
      (item) => item['dedupe_key'] == dedupeKey,
    );
    final previousItem = existingIndex >= 0
        ? _queue.removeAt(existingIndex)
        : null;
    _queue.add({
      'entity': entity,
      'action': action,
      'dedupe_key': dedupeKey,
      'queued_at': DateTime.now().toIso8601String(),
      'payload': payload,
      'retry_count': _readInt(previousItem?['retry_count']) ?? 0,
      'last_attempt_at': previousItem?['last_attempt_at'],
      'first_error': previousItem?['first_error'],
      'skip_reason': previousItem?['skip_reason'],
    });
    await _saveQueue();
    _scheduleFlushDebounced();
  }

  Future<_QueueSendOutcome> _sendItem(Map<String, dynamic> item) async {
    if (!_syncOrdersEnabled && item['entity'] == 'orders') {
      return _QueueSendOutcome.success;
    }
    if (_isRateLimited) {
      item['last_error'] = 'rate_limited';
      return _QueueSendOutcome.retryable;
    }
    if (!_hasAuthToken) {
      appLogger.d('❌ _sendItem: No auth token available');
      item['last_error'] = 'no_auth_token';
      return _QueueSendOutcome.retryable;
    }
    final entity = item['entity'];
    final action = item['action'];
    if (entity is! String || action is! String) {
      return _QueueSendOutcome.success;
    }
    final payload = item['payload'];
    item['last_attempt_at'] = DateTime.now().toIso8601String();

    if (entity == 'orders' &&
        action == 'status' &&
        payload is Map<String, dynamic>) {
      final localOrderId = _readInt(payload['local_id']);
      final status = payload['status']?.toString().trim();
      if (localOrderId == null || localOrderId <= 0 || status == null) {
        item['last_error'] = 'invalid_status_payload';
        return _QueueSendOutcome.retryable;
      }

      ApiOrderPullService.instance.updateAuthToken(_authToken);
      final ok = await ApiOrderPullService.instance
          .pushRemoteOrderStatusByLocalId(
            localOrderId: localOrderId,
            status: status,
            paymentStatus: payload['payment_status']?.toString(),
            cancelReason: payload['cancel_reason']?.toString(),
          );
      if (!ok) {
        // Check if the remote order ID was cleared from cache (404 = order doesn't exist)
        // If cache was cleared, mark as success to skip retries
        final remoteIdStillInCache = await ApiOrderPullService.instance
            .remoteOrderIdForLocalId(localOrderId);
        if (remoteIdStillInCache == null || remoteIdStillInCache <= 0) {
          appLogger.w(
            '⏭️ [SKIP RETRY] Remote order for local #$localOrderId was cleared from cache (404). '
            'Marking queue item as success to skip retries.',
          );
          return _QueueSendOutcome.success;
        }

        // Check if this is a 401 unauthorized error
        final lastError = item['last_error']?.toString() ?? '';
        if (lastError.contains('unauthorized_401') ||
            lastError.contains('401')) {
          // 401 errors won't recover without re-login, move to dead letter after max retries
          final retryCount = _recordCountedFailure(
            item,
            reason: 'unauthorized_401',
            error:
                'Status sync failed: 401 Unauthorized for local order #$localOrderId',
          );
          if (retryCount >= _maxRetryCount) {
            await _moveToDeadLetter(
              item,
              reason: 'max_retries_unauthorized',
              details:
                  'Status sync failed after $_maxRetryCount attempts due to 401 Unauthorized. '
                  'User needs to re-login. local_order=$localOrderId',
            );
            appLogger.d(
              '🚨 Queue item moved to dead letter: status sync for local #$localOrderId '
              'failed after $_maxRetryCount attempts due to 401',
            );
            return _QueueSendOutcome.deadLettered;
          }
          appLogger.d(
            '⚠️ Status sync 401 for local #$localOrderId, attempt $retryCount/$_maxRetryCount',
          );
        }

        item['last_error'] = 'remote_status_sync_failed';
        return _QueueSendOutcome.retryable;
      }
      return _QueueSendOutcome.success;
    }

    if (entity == 'orders' &&
        action == 'upsert' &&
        payload is Map<String, dynamic>) {
      if (!_shouldSyncOrderPayload(payload)) {
        return _QueueSendOutcome.success;
      }
      final channel = _normalizeOrderChannel(payload['channel']);
      appLogger.d(
        '🚀 Syncing order to backend: local_id=${payload['local_id']}, channel=$channel, status=${payload['status']}',
      );
    }

    final endpoint = _resolveEndpoint(entity: entity, action: action);
    if (endpoint == null) {
      appLogger.d('❌ No endpoint for entity=$entity, action=$action');
      return _QueueSendOutcome.success;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');

    // ✅ DEBUG: Log token being used (masked for security)
    final tokenPreview = _authToken.isNotEmpty
        ? '${_authToken.substring(0, _authToken.length > 20 ? 20 : _authToken.length)}...'
        : 'EMPTY';
    appLogger.d(
      '🔑 [SYNCQ] Using token: $tokenPreview (length=${_authToken.length})',
    );

    final headers = {
      'Content-Type': 'application/json',
      if (_authToken.isNotEmpty && !endpoint.startsWith('/api/sync/public/'))
        'Authorization': 'Bearer $_authToken',
    };

    appLogger.d('🌐 Sending to: $_baseUrl$endpoint');
    appLogger.d(
      '📦 Payload: ${payload.toString().substring(0, payload.toString().length > 200 ? 200 : payload.toString().length)}...',
    );

    try {
      late http.Response response;
      await _respectRequestSpacing();
      appLogger.d('📡 POST request to: $uri');
      response = await http.post(
        uri,
        headers: headers,
        body: json.encode(payload),
      );
      appLogger.d('📥 Response status: ${response.statusCode} for $endpoint');
      appLogger.d(
        '📥 Response body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...',
      );

      if (response.statusCode == 401) {
        appLogger.d(
          '❌ Sync unauthorized; token missing/invalid. endpoint=$endpoint',
        );
        final retryCount = _recordCountedFailure(
          item,
          reason: 'unauthorized_401',
          error: 'HTTP 401 Unauthorized for endpoint=$endpoint',
        );
        if (retryCount >= _maxRetryCount) {
          await _moveToDeadLetter(
            item,
            reason: 'max_retries_unauthorized',
            details:
                'HTTP 401 persisted after $_maxRetryCount attempts for endpoint=$endpoint. '
                'User needs to re-login.',
          );
          appLogger.d(
            '🚨 Queue item moved to dead letter after $retryCount 401 errors: entity=$entity action=$action',
          );
          return _QueueSendOutcome.deadLettered;
        }
        appLogger.d(
          '⚠️ Sync 401 [$entity/$action] endpoint=$endpoint attempt=$retryCount/$_maxRetryCount',
        );
        return _QueueSendOutcome.retryable;
      }
      if (response.statusCode == 429) {
        final retryIn = _applyRateLimitFromResponse(response);
        appLogger.d(
          '⏳ Sync throttled (429) [$entity/$action] endpoint=$endpoint retry_in=${retryIn.inSeconds}s',
        );
        item['last_error'] = 'rate_limited_429';
        return _QueueSendOutcome.retryable;
      }
      if (response.statusCode == 403 &&
          entity == 'orders' &&
          action == 'upsert' &&
          payload is Map<String, dynamic> &&
          _isStaffScopeForbidden(response.body)) {
        final retryCount = _recordCountedFailure(
          item,
          reason: 'staff_scope_403',
          error: '403 staff scope: staff users can only sync their own orders',
        );
        if (retryCount >= _maxRetryCount) {
          await _moveToDeadLetter(
            item,
            reason: 'staff_scope_403',
            details:
                'HTTP 403 persisted after $_maxRetryCount attempts for endpoint=$endpoint',
          );
          appLogger.d(
            '🚨 Dead letter order sync after repeated 403 staff scope [$entity/$action] endpoint=$endpoint',
          );
          return _QueueSendOutcome.deadLettered;
        }
        appLogger.d(
          '⚠️ Sync forbidden (403 staff scope) [$entity/$action] endpoint=$endpoint attempt=$retryCount/$_maxRetryCount',
        );
        return _QueueSendOutcome.retryable;
      }
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (ok) {
        appLogger.d(
          '✅ Sync successful [$entity/$action] endpoint=$endpoint status=${response.statusCode}',
        );
        _clearRateLimitBackoff();
        _clearFailureTracking(item);
      }
      if (response.statusCode == 422) {
        if (entity == 'orders' &&
            action == 'upsert' &&
            payload is Map<String, dynamic>) {
          final fallbackOk = await _retryOrderUpsertWithFallbackStatus(
            uri: uri,
            headers: headers,
            payload: payload,
          );
          if (fallbackOk) {
            _clearRateLimitBackoff();
            _clearFailureTracking(item);
            return _QueueSendOutcome.success;
          }
        }
        final body = response.body;
        final preview = body.length > 500
            ? '${body.substring(0, 500)}...'
            : body;
        appLogger.d(
          '⚠️ Sync dropped (422 validation) [$entity/$action] endpoint=$endpoint body=$preview',
        );
        _clearFailureTracking(item);
        return _QueueSendOutcome.success;
      }
      if (!ok) {
        final body = response.body;
        final preview = body.length > 500
            ? '${body.substring(0, 500)}...'
            : body;
        final retryCount = _recordCountedFailure(
          item,
          reason: 'http_${response.statusCode}',
          error:
              'HTTP ${response.statusCode} [$entity/$action] endpoint=$endpoint body=$preview',
        );
        appLogger.d(
          '❌ Sync failed [$entity/$action] status=${response.statusCode} endpoint=$endpoint body=$preview attempt=$retryCount/$_maxRetryCount',
        );
        if (retryCount >= _maxRetryCount) {
          await _moveToDeadLetter(
            item,
            reason: 'max_retries_exceeded',
            details:
                'Permanent sync failure after $_maxRetryCount attempts. last_reason=${item['skip_reason']}',
          );
          appLogger.d(
            '🚨 Queue item dropped after repeated failures [$entity/$action] endpoint=$endpoint',
          );
          return _QueueSendOutcome.deadLettered;
        }
      }
      return ok ? _QueueSendOutcome.success : _QueueSendOutcome.retryable;
    } catch (error) {
      item['last_error'] = 'exception:$error';
      return _QueueSendOutcome.retryable;
    }
  }

  Future<bool> _retryOrderUpsertWithFallbackStatus({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> payload,
  }) async {
    final currentStatus = payload['status']?.toString().trim().toLowerCase();
    if (currentStatus == 'cancelled') {
      appLogger.d(
        '⚠️ Skip fallback status retry for cancelled order local_id=${payload['local_id']}',
      );
      return false;
    }
    final fallbacks = <String>['pending', 'confirmed', 'delivered'];
    for (final candidate in fallbacks) {
      if (candidate == currentStatus) continue;
      final mutated = Map<String, dynamic>.from(payload)
        ..['status'] = candidate;
      appLogger.d(
        '🔁 Retrying order upsert with fallback status candidate=$candidate original=$currentStatus local_id=${payload['local_id']}',
      );
      try {
        await _respectRequestSpacing();
        final res = await http.post(
          uri,
          headers: headers,
          body: json.encode(mutated),
        );
        if (res.statusCode == 429) {
          _applyRateLimitFromResponse(res);
          appLogger.d(
            '⏳ Fallback status candidate=$candidate hit rate limit for local_id=${payload['local_id']}',
          );
          return false;
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _clearRateLimitBackoff();
          appLogger.d(
            '✅ Fallback status accepted candidate=$candidate local_id=${payload['local_id']}',
          );
          return true;
        }
        appLogger.d(
          '❌ Fallback status rejected candidate=$candidate status=${res.statusCode} local_id=${payload['local_id']}',
        );
      } catch (error) {
        appLogger.d(
          '❌ Fallback status error candidate=$candidate local_id=${payload['local_id']} error=$error',
        );
      }
    }
    appLogger.d(
      '⚠️ Exhausted fallback statuses for local_id=${payload['local_id']} original=$currentStatus',
    );
    return false;
  }

  void _scheduleFlushDebounced() {
    _flushDebounceTimer?.cancel();
    _flushDebounceTimer = Timer(_enqueueFlushDebounce, () {
      _flushDebounceTimer = null;
      unawaited(flushQueue());
    });
  }

  int _recordCountedFailure(
    Map<String, dynamic> item, {
    required String reason,
    required String error,
  }) {
    final nextCount = (_readInt(item['retry_count']) ?? 0) + 1;
    item['retry_count'] = nextCount;
    item['skip_reason'] = reason;
    item['first_error'] ??= error;
    item['last_error'] = error;
    return nextCount;
  }

  void _clearFailureTracking(Map<String, dynamic> item) {
    item['retry_count'] = 0;
    item.remove('skip_reason');
    item.remove('first_error');
    item.remove('last_error');
  }

  Future<void> _moveToDeadLetter(
    Map<String, dynamic> item, {
    required String reason,
    required String details,
  }) async {
    final snapshot = Map<String, dynamic>.from(item)
      ..['skip_reason'] = reason
      ..['dead_lettered_at'] = DateTime.now().toIso8601String()
      ..['dead_letter_details'] = details;
    item['dead_lettered'] = true;
    item['skip_reason'] = reason;
    _deadLetterQueue.add(snapshot);
    await _saveDeadLetterQueue();
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool get _isRateLimited {
    final until = _rateLimitedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  Duration _remainingRateLimit() {
    final until = _rateLimitedUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _respectRequestSpacing() async {
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final elapsed = DateTime.now().difference(lastRequestAt);
      if (elapsed < _minRequestSpacing) {
        await Future.delayed(_minRequestSpacing - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  Duration _applyRateLimitFromResponse(http.Response response) {
    _rateLimitStrikeCount += 1;
    if (_rateLimitStrikeCount > 8) {
      _rateLimitStrikeCount = 8;
    }
    var delay =
        _parseRetryAfter(response.headers['retry-after']) ??
        _exponentialRateLimitDelay(_rateLimitStrikeCount);
    if (delay < const Duration(seconds: 2)) {
      delay = const Duration(seconds: 2);
    }
    if (delay > _maxRateLimitDelay) {
      delay = _maxRateLimitDelay;
    }
    final until = DateTime.now().add(delay);
    if (_rateLimitedUntil == null || until.isAfter(_rateLimitedUntil!)) {
      _rateLimitedUntil = until;
    }
    final remaining = _remainingRateLimit();
    return remaining > Duration.zero ? remaining : delay;
  }

  Duration? _parseRetryAfter(String? rawValue) {
    if (rawValue == null) return null;
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    final asSeconds = int.tryParse(value);
    if (asSeconds != null) {
      if (asSeconds <= 0) return const Duration(seconds: 1);
      return Duration(seconds: asSeconds);
    }

    try {
      final retryDate = HttpDate.parse(value);
      final delta = retryDate.difference(DateTime.now().toUtc());
      if (delta.isNegative) return const Duration(seconds: 1);
      return delta;
    } catch (_) {
      return null;
    }
  }

  Duration _exponentialRateLimitDelay(int strikeCount) {
    var safeStrike = strikeCount;
    if (safeStrike < 1) safeStrike = 1;
    if (safeStrike > 6) safeStrike = 6;
    final seconds = _defaultRateLimitDelay.inSeconds * (1 << (safeStrike - 1));
    return Duration(seconds: seconds);
  }

  void _clearRateLimitBackoff() {
    _rateLimitStrikeCount = 0;
    _rateLimitedUntil = null;
  }

  bool _isStaffScopeForbidden(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is! Map) return false;
      final errors = decoded['errors'];
      if (errors is! Map) return false;
      final staffErrors = errors['staff_id'];
      if (staffErrors is List) {
        final text = staffErrors
            .map((e) => e.toString())
            .join(' ')
            .toLowerCase();
        return text.contains('staff users can only sync their own orders');
      }
      if (staffErrors is String) {
        return staffErrors.toLowerCase().contains(
          'staff users can only sync their own orders',
        );
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String? _resolveEndpoint({required String entity, required String action}) {
    final publicEntities = ['users', 'orders', 'categories', 'products'];
    if (action == 'upsert' && publicEntities.contains(entity)) {
      return '/api/sync/public/$entity/upsert';
    }
    if (entity == 'orders' && action == 'status') {
      return null;
    }
    if (action == 'upsert') {
      return '/api/sync/$entity/upsert';
    }
    if (action == 'delete') {
      return '/api/sync/$entity/delete';
    }
    return null;
  }

  String _normalizeOrderStatus(String rawStatus) {
    final value = rawStatus.trim().toLowerCase();
    switch (value) {
      case 'cancelled':
      case 'pending':
      case 'confirmed':
      case 'preparing':
      case 'ready':
      case 'delivered':
        return value;
      case 'paid':
      case 'completed':
        return 'delivered';
      default:
        return 'pending';
    }
  }

  String _normalizeOrderChannel(dynamic rawChannel) {
    final channel = rawChannel?.toString().trim().toLowerCase() ?? '';
    switch (channel) {
      case 'api':
      case 'mobile':
      case 'mobile_app':
      case 'app':
      case 'android':
      case 'ios':
        return 'api';
      case 'web':
      case 'website':
      case 'site':
      case 'online':
        return 'web';
      case 'kiosk':
      case 'borne':
        return 'kiosk';
      case 'pos':
      case 'onsite':
      case 'in_store':
      case 'in-store':
      default:
        return channel;
    }
  }

  bool _isRemoteOrderChannel(dynamic rawChannel) {
    final channel = _normalizeOrderChannel(rawChannel);
    return channel == 'api' || channel == 'web' || channel == 'kiosk';
  }

  bool _shouldSyncOrderUpsert(PosOrder order) {
    if (order.isFromApi) return false;
    return !_isRemoteOrderChannel(order.channel);
  }

  bool _shouldSyncOrderPayload(Map<String, dynamic> payload) {
    final isFromApi = payload['is_from_api'] == true;
    if (isFromApi) return false;
    return !_isRemoteOrderChannel(payload['channel']);
  }

  Future<int> _resolveProductIdForSync(PosOrderItem item) async {
    final byId = await DatabaseService.getProductById(item.productId);
    if (byId != null) return item.productId;

    final byName = await DatabaseService.getProductByName(item.productName);
    if (byName != null) {
      item.productId = byName.id;
      await DatabaseService.updatePosOrderItem(item);
      return byName.id;
    }

    return item.productId;
  }

  Future<void> _loadQueue() async {
    final file = _queueFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is List) {
        _queue
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map((e) {
              return Map<String, dynamic>.from(e);
            }),
          );
      }
    } catch (_) {}
  }

  Future<void> _saveQueue() async {
    final file = _queueFile;
    if (file == null) return;
    await _writeJsonAtomically(file: file, content: json.encode(_queue));
  }

  Future<void> _loadDeadLetterQueue() async {
    final file = _deadLetterFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is List) {
        _deadLetterQueue
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map((e) {
              return Map<String, dynamic>.from(e);
            }),
          );
      }
    } catch (_) {}
  }

  Future<void> _saveDeadLetterQueue() async {
    final file = _deadLetterFile;
    if (file == null) return;
    await file.writeAsString(json.encode(_deadLetterQueue));
  }

  Future<void> _loadOrdersSyncState() async {
    // CRITICAL FIX #4: Use lock for thread-safe state loading
    await _syncStateLock.synchronized(() async {
      final file = _ordersStateFile;
      if (file == null) {
        appLogger.w('⚠️ [SYNC STATE] _ordersStateFile is null');
        return;
      }
      if (!await file.exists()) {
        appLogger.d('📄 [SYNC STATE] State file does not exist: ${file.path}');
        return;
      }
      try {
        final content = await file.readAsString();
        if (content.trim().isEmpty) {
          appLogger.d('📄 [SYNC STATE] State file is empty');
          return;
        }
        final decoded = json.decode(content);
        if (decoded is Map<String, dynamic>) {
          _ordersSyncState.clear();
          final now = DateTime.now();
          final futureThreshold = now.add(const Duration(minutes: 5));
          int invalidCount = 0;
          for (final entry in decoded.entries) {
            final localId = int.tryParse(entry.key);
            final updatedAt = entry.value;
            if (localId != null && updatedAt is String) {
              try {
                final parsedDate = DateTime.parse(updatedAt);
                // Skip entries with future dates (invalid data)
                if (parsedDate.isAfter(futureThreshold)) {
                  appLogger.w(
                    '🚨 [SYNC STATE FIX] Skipping FUTURE date for Order #$localId: $updatedAt',
                  );
                  invalidCount++;
                  continue;
                }
                _ordersSyncState[localId] = updatedAt;
              } catch (e) {
                appLogger.w(
                  '⚠️ [SYNC STATE] Failed to parse date for Order #$localId: $updatedAt, error: $e',
                );
              }
            }
          }
          if (invalidCount > 0) {
            appLogger.w(
              '🚨 [SYNC STATE FIX] Removed $invalidCount invalid future-dated entries from sync state',
            );
            // ✅ FIX: Save cleaned state AFTER a delay to avoid blocking startup
            // Schedule save for after init completes
            Future.delayed(const Duration(milliseconds: 500), () {
              appLogger.d('💾 [SYNC STATE] Saving cleaned state (deferred)...');
              _saveOrdersSyncState();
            });
          }
          appLogger.d(
            '✅ [SYNC STATE] Loaded ${_ordersSyncState.length} entries from ${file.path}',
          );
        } else {
          appLogger.w(
            '⚠️ [SYNC STATE] Invalid state file format: expected Map, got ${decoded.runtimeType}',
          );
        }
      } catch (e, st) {
        appLogger.e(
          '❌ [SYNC STATE] Failed to load state from ${file.path}',
          error: e,
          stackTrace: st,
        );
        // CRITICAL FIX #5: Don't lose state on error - try backup
        await _restoreFromBackup();
      }
    });
  }

  Future<void> _restoreFromBackup() async {
    final backupFile = _ordersStateBackupFile;
    final stateFile = _ordersStateFile;
    if (backupFile == null || stateFile == null) return;
    if (!await backupFile.exists()) return;

    try {
      appLogger.d('🔄 [SYNC STATE] Restoring from backup...');
      await backupFile.copy(stateFile.path);
      await _loadOrdersSyncState(); // Retry loading
      appLogger.i('✅ [SYNC STATE] Restored from backup successfully');
    } catch (e, st) {
      appLogger.e(
        '❌ [SYNC STATE] Failed to restore from backup',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _saveOrdersSyncState() async {
    // CRITICAL FIX #6: Use lock for thread-safe state saving
    await _syncStateLock.synchronized(() async {
      final file = _ordersStateFile;
      if (file == null) return;
      final encoded = <String, String>{
        for (final entry in _ordersSyncState.entries)
          entry.key.toString(): entry.value,
      };
      await _writeJsonAtomically(
        file: file,
        backupFile: _ordersStateBackupFile,
        content: json.encode(encoded),
      );
    });
  }

  Future<void> _prepareOrdersStateTransaction(Map<String, dynamic> item) async {
    if (!_isOrdersUpsertItem(item)) return;
    final txnFile = _ordersStateTxnFile;
    if (txnFile == null) return;
    await _snapshotOrdersStateBackup();
    final payload = item['payload'] as Map<String, dynamic>;
    await _writeJsonAtomically(
      file: txnFile,
      content: json.encode({
        'prepared_at': DateTime.now().toIso8601String(),
        'local_id': payload['local_id'],
        'updated_at': payload['updated_at'],
        'queue_item': item,
      }),
    );
  }

  Future<void> _recoverOrdersStateTransaction() async {
    final txnFile = _ordersStateTxnFile;
    if (txnFile == null || !await txnFile.exists()) return;

    try {
      final content = await txnFile.readAsString();
      if (content.trim().isEmpty) {
        await txnFile.delete();
        return;
      }
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) {
        await txnFile.delete();
        return;
      }

      await _restoreOrdersStateBackup();

      final queueItem = decoded['queue_item'];
      if (queueItem is Map) {
        final recoveredItem = Map<String, dynamic>.from(queueItem);
        final dedupeKey = recoveredItem['dedupe_key'];
        final alreadyQueued =
            dedupeKey is String &&
            _queue.any((item) => item['dedupe_key'] == dedupeKey);
        if (!alreadyQueued) {
          _queue.insert(0, recoveredItem);
          await _saveQueue();
        }
      }
      appLogger.d('♻️ Recovered pending sync-state transaction after restart');
    } catch (_) {
      await _restoreOrdersStateBackup();
    } finally {
      await _clearOrdersStateTransaction();
    }
  }

  Future<void> _restoreOrdersStateBackup() async {
    final backupFile = _ordersStateBackupFile;
    final stateFile = _ordersStateFile;
    if (backupFile == null || stateFile == null) return;
    if (!await backupFile.exists()) return;
    await backupFile.copy(stateFile.path);
    await _loadOrdersSyncState();
  }

  Future<void> _snapshotOrdersStateBackup() async {
    final backupFile = _ordersStateBackupFile;
    final stateFile = _ordersStateFile;
    if (backupFile == null || stateFile == null) return;

    if (await stateFile.exists()) {
      await stateFile.copy(backupFile.path);
      return;
    }
    final encoded = <String, String>{
      for (final entry in _ordersSyncState.entries)
        entry.key.toString(): entry.value,
    };
    await backupFile.writeAsString(json.encode(encoded));
  }

  Future<void> _clearOrdersStateTransaction() async {
    final txnFile = _ordersStateTxnFile;
    if (txnFile == null || !await txnFile.exists()) return;
    await txnFile.delete();
  }

  // ==================== USERS SYNC STATE ====================

  Future<void> _saveUsersSyncState() async {
    await _usersSyncStateLock.synchronized(() async {
      final file = _usersStateFile;
      if (file == null) return;
      final encoded = <String, String>{
        for (final entry in _usersSyncState.entries)
          entry.key.toString(): entry.value,
      };
      try {
        await _writeJsonAtomically(file: file, content: json.encode(encoded));
      } catch (e, st) {
        appLogger.e(
          '❌ [USER SYNC STATE] Failed to save',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  bool _isOrdersUpsertItem(Map<String, dynamic> item) {
    return item['entity'] == 'orders' &&
        item['action'] == 'upsert' &&
        item['payload'] is Map<String, dynamic>;
  }

  Future<void> _writeJsonAtomically({
    required File file,
    required String content,
    File? backupFile,
  }) async {
    try {
      // Ensure directory exists BEFORE creating temp file
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(content);
      if (backupFile != null && await file.exists()) {
        await file.copy(backupFile.path);
      }
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    } catch (e, st) {
      appLogger.e(
        '❌ [SYNC STATE] Failed to write file: ${file.path}',
        error: e,
        stackTrace: st,
      );
      // Try to write directly if atomic write fails
      try {
        // Ensure directory exists for direct write too
        final dir = file.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        await file.writeAsString(content);
      } catch (e2, st2) {
        appLogger.e(
          '❌ [SYNC STATE] Direct write also failed',
          error: e2,
          stackTrace: st2,
        );
      }
    }
  }
}

enum _QueueSendOutcome { success, retryable, deadLettered }
