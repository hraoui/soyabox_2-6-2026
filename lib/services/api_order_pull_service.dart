import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;
import '../utils/path_utils.dart';

import '../data/app_constants.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/order_delivery.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

class ApiOrderPullService {
  ApiOrderPullService._();
  static final ApiOrderPullService instance = ApiOrderPullService._();

  bool _initialized = false;
  String _baseUrlRaw = AppConstant.baseUrl;
  String get _baseUrl => _baseUrlRaw.replaceAll(RegExp(r'/+$'), '');
  String _authToken = AppConstant.apiToken;
  File? _stateFile;

  final Map<int, _RemoteOrderSyncState> _remoteState =
      <int, _RemoteOrderSyncState>{};
  final Set<int> _remoteLocalOrderIds = <int>{};
  bool _syncOrdersEndpointUnavailable = false;
  int? _preferredStatusAttemptIndex;

  Future<void> init({String? baseUrl, String? authToken}) async {
    if (_initialized) {
      if (baseUrl != null && baseUrl.trim().isNotEmpty) {
        _baseUrlRaw = baseUrl.trim();
      }
      if (authToken != null) {
        _authToken = authToken.trim();
      }
      return;
    }

    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrlRaw = baseUrl.trim();
    }
    if (authToken != null) {
      _authToken = authToken.trim();
    }

    final dir = await getAppDocumentsDirectory();

    _stateFile = File('${dir.path}/api_orders_sync_state.json');
    try {
      await _loadState();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to load API order pull state',
        error: e,
        stackTrace: stackTrace,
      );
      _remoteState.clear();
      _remoteLocalOrderIds.clear();
    }

    _initialized = true;
  }

  void updateBaseUrl(String baseUrl) {
    if (baseUrl.trim().isEmpty) return;
    _baseUrlRaw = baseUrl.trim();
  }

  void updateAuthToken(String token) {
    _authToken = token.trim();
  }

  bool isRemoteApiLocalOrderIdSync(int localOrderId) {
    return _remoteLocalOrderIds.contains(localOrderId);
  }

  Future<bool> isRemoteApiLocalOrderId(int localOrderId) async {
    await init();
    return _remoteLocalOrderIds.contains(localOrderId);
  }

  int? remoteOrderIdForLocalIdSync(int localOrderId) {
    for (final entry in _remoteState.entries) {
      if (entry.value.localId == localOrderId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<int?> remoteOrderIdForLocalId(int localOrderId) async {
    await init();
    return remoteOrderIdForLocalIdSync(localOrderId);
  }

  Future<int?> ensureRemoteOrderIdForLocalId(int localOrderId) async {
    await init();

    final cachedRemoteId = remoteOrderIdForLocalIdSync(localOrderId);
    if (cachedRemoteId != null && cachedRemoteId > 0) {
      return cachedRemoteId;
    }

    if (_authToken.isEmpty) {
      return null;
    }

    await DatabaseService.init();
    final localOrder = await DatabaseService.getPosOrderById(localOrderId);
    if (localOrder == null) {
      return null;
    }

    return _resolveRemoteOrderIdForLocalOrder(localOrder);
  }

  Future<bool> pushRemoteOrderStatusByLocalId({
    required int localOrderId,
    required String status,
    String? paymentStatus,
    String? cancelReason,
  }) async {
    appLogger.d(
      '🔄 [STATUS SYNC START] Local order ID: $localOrderId, status: $status, '
      'paymentStatus: $paymentStatus, cancelReason: $cancelReason',
    );

    await init();
    if (_authToken.isEmpty) {
      appLogger.w('⚠️ [STATUS SYNC] Auth token is empty, aborting');
      return false;
    }
    await DatabaseService.init();

    final localOrder = await DatabaseService.getPosOrderById(localOrderId);
    if (localOrder == null) {
      appLogger.e('❌ [STATUS SYNC] Local order #$localOrderId not found in DB');
      return false;
    }

    appLogger.d(
      '📦 [STATUS SYNC] Local order found: channel=${localOrder.channel}, '
      'restaurantId=${localOrder.restaurantId}, createdAt=${localOrder.createdAt}',
    );

    var remoteOrderId = remoteOrderIdForLocalIdSync(localOrderId);
    appLogger.d('🔍 [STATUS SYNC] Remote order ID from cache: $remoteOrderId');

    if (remoteOrderId == null || remoteOrderId <= 0) {
      appLogger.d(
        '🔍 [STATUS SYNC] Remote ID not in cache, resolving from backend...',
      );
      remoteOrderId = await _resolveRemoteOrderIdForLocalOrder(localOrder);
    }

    if (remoteOrderId == null || remoteOrderId <= 0) {
      appLogger.e(
        '❌ [STATUS SYNC] Cannot resolve remote order ID for local order '
        '#$localOrderId. Order will NOT be synced to backend.',
      );
      return false;
    }

    appLogger.d(
      '✅ [STATUS SYNC] Resolved remote order ID: $remoteOrderId for local #$localOrderId',
    );

    final channel = _normalizeChannel(localOrder.channel);

    var success = false;
    for (final backendStatus in _backendStatusCandidates(status)) {
      final normalizedPayment = _normalizePaymentStatusForBackend(
        paymentStatus,
        fallbackStatus: backendStatus,
      );
      final payload = <String, dynamic>{
        'status': backendStatus,
        if (normalizedPayment == 'paid') 'payment_status': 'paid',
        if (channel.isNotEmpty) 'channel': channel,
        if (cancelReason != null && cancelReason.trim().isNotEmpty)
          'cancel_reason': cancelReason.trim(),
      };

      appLogger.d(
        '📤 [STATUS SYNC] Attempting to push status: $backendStatus to '
        'remote order #$remoteOrderId with payload: $payload',
      );

      success = await _pushRemoteOrderStatus(
        localOrderId: localOrderId,
        remoteOrderId: remoteOrderId,
        backendStatus: backendStatus,
        payload: payload,
      );

      if (success) {
        appLogger.d(
          '✅ [STATUS SYNC] Successfully pushed status $backendStatus '
          'for remote order #$remoteOrderId',
        );
        break;
      } else {
        appLogger.w(
          '⚠️ [STATUS SYNC] Failed to push status $backendStatus '
          'for remote order #$remoteOrderId',
        );
      }
    }

    if (!success) {
      appLogger.e(
        '❌ [STATUS SYNC] All status push attempts failed for local=$localOrderId '
        'remote=$remoteOrderId status=$status',
      );
      // If we cleared the cache due to 404, the order doesn't exist on backend
      // Return false but the caller should check if remoteOrderId cache was cleared
      // If cache was cleared, this should NOT be retried
      return false;
    }

    final existing = _remoteState[remoteOrderId];
    if (existing == null) {
      appLogger.d(
        '⚠️ [STATUS SYNC] No existing state for remote order #$remoteOrderId, '
        'but status sync succeeded',
      );
      return true;
    }

    _remoteState[remoteOrderId] = _RemoteOrderSyncState(
      localId: existing.localId,
      updatedAt: DateTime.now().toIso8601String(),
      restaurantId: existing.restaurantId,
    );
    await _saveState();

    appLogger.d(
      '✅ [STATUS SYNC COMPLETE] Successfully synced status for '
      'local #$localOrderId -> remote #$remoteOrderId',
    );
    return true;
  }

  Future<int?> _resolveRemoteOrderIdForLocalOrder(PosOrder localOrder) async {
    final restaurantId = localOrder.restaurantId;
    if (restaurantId == null || restaurantId <= 0) return null;

    final remoteOrders = await _fetchOrders(restaurantId: restaurantId);
    if (remoteOrders.isEmpty) return null;

    // FIRST TRY: Match by source_local_id (most reliable)
    for (final raw in remoteOrders) {
      final remoteId = _asInt(raw['id']);
      if (remoteId == null || remoteId <= 0) continue;

      final remoteRestaurantId = _extractRestaurantId(raw);
      if (remoteRestaurantId != null && remoteRestaurantId != restaurantId) {
        continue;
      }

      final sourceLocalId = _asInt(
        raw['source_local_id'] ?? raw['local_id'] ?? raw['sourceLocalId'],
      );
      final expectedSourceLocalId = localOrder.sourceLocalId ?? localOrder.id;
      if (sourceLocalId != expectedSourceLocalId) {
        continue;
      }

      final updatedAt = _asDate(
        raw['updated_at'] ?? raw['created_at'],
      ).toIso8601String();
      _remoteState[remoteId] = _RemoteOrderSyncState(
        localId: localOrder.id,
        updatedAt: updatedAt,
        restaurantId: restaurantId,
      );
      _remoteLocalOrderIds.add(localOrder.id);
      await _saveState();
      appLogger.d(
        '🔗 Resolved remote order by source_local_id local=${localOrder.id} -> remote=$remoteId',
      );
      return remoteId;
    }

    // FALLBACK: For web/API orders, try to match by channel + created_at + total
    // This handles cases where source_local_id doesn't match (e.g., after DB reset)
    appLogger.w(
      '⚠️ [FALLBACK MATCH] No source_local_id match for local order #${localOrder.id}. '
      'Trying heuristic match by channel + timestamp + total...',
    );

    final localChannel = _normalizeChannel(localOrder.channel);
    final localCreatedAt = localOrder.createdAt.toUtc();
    final localTotal = localOrder.totalPrice;
    final localPhone = _normalizePhone(localOrder.customerPhone);
    final localName = (localOrder.customerName ?? '').trim().toLowerCase();

    int? bestRemoteId;
    String? bestUpdatedAt;
    Duration? bestDelta;

    for (final raw in remoteOrders) {
      final remoteId = _asInt(raw['id']);
      if (remoteId == null || remoteId <= 0) continue;

      final remoteRestaurantId = _extractRestaurantId(raw);
      if (remoteRestaurantId != null && remoteRestaurantId != restaurantId) {
        continue;
      }

      final remoteChannel = _normalizeChannel(
        _firstNonEmptyString([
          _asTrimmedString(raw['channel']),
          _asTrimmedString(raw['source']),
          _asTrimmedString(raw['origin']),
        ]),
      );
      if (!_sameChannelFamily(localChannel, remoteChannel)) {
        continue;
      }

      final remoteTotal = _resolveTotalPrice(raw);
      if ((remoteTotal - localTotal).abs() > 0.01) {
        continue;
      }

      final remotePhone = _normalizePhone(
        _asNullableString(raw['customer_phone']),
      );
      if (localPhone.isNotEmpty &&
          remotePhone.isNotEmpty &&
          localPhone != remotePhone) {
        continue;
      }

      final remoteName = _asTrimmedString(raw['customer_name']).toLowerCase();
      if (localName.isNotEmpty &&
          remoteName.isNotEmpty &&
          remoteName != localName) {
        continue;
      }

      final remoteCreatedAt = _asDate(raw['created_at']).toUtc();
      final delta = localCreatedAt.isAfter(remoteCreatedAt)
          ? localCreatedAt.difference(remoteCreatedAt)
          : remoteCreatedAt.difference(localCreatedAt);
      if (delta > const Duration(hours: 12)) {
        continue;
      }

      if (bestDelta == null || delta < bestDelta) {
        bestDelta = delta;
        bestRemoteId = remoteId;
        bestUpdatedAt = _asDate(
          raw['updated_at'] ?? raw['created_at'],
        ).toIso8601String();
      }
    }

    if (bestRemoteId == null) return null;

    _remoteState[bestRemoteId] = _RemoteOrderSyncState(
      localId: localOrder.id,
      updatedAt: bestUpdatedAt ?? DateTime.now().toIso8601String(),
      restaurantId: restaurantId,
    );
    _remoteLocalOrderIds.add(localOrder.id);
    await _saveState();
    appLogger.d(
      '🔗 Resolved remote order mapping local=${localOrder.id} -> remote=$bestRemoteId',
    );
    return bestRemoteId;
  }

  String _normalizePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  bool _sameChannelFamily(String localChannel, String remoteChannel) {
    if (localChannel == remoteChannel) return true;
    const remoteSet = {'api', 'web', 'kiosk'};
    return remoteSet.contains(localChannel) &&
        remoteSet.contains(remoteChannel);
  }

  /// ✅ Méthode légère pour compter les commandes API pending sans lire la DB locale
  /// Utilisé par le login screen pour éviter les erreurs de décodage UTF-8
  Future<int> countApiPendingOrders({required int restaurantId}) async {
    await init();
    if (restaurantId <= 0 || _authToken.isEmpty) {
      return 0;
    }

    final orders = await _fetchOrders(restaurantId: restaurantId);
    if (orders.isEmpty) {
      return 0;
    }

    var pendingCount = 0;
    for (final raw in orders) {
      final orderRestaurantId = _extractRestaurantId(raw) ?? restaurantId;
      if (orderRestaurantId != restaurantId) {
        continue;
      }

      final channel = _asTrimmedString(raw['channel']).toLowerCase();
      final status = _asTrimmedString(raw['status']).toLowerCase();
      final isApiOrder =
          channel == 'api' || channel == 'web' || channel == 'kiosk';
      final isPending = status == 'pending';

      if (isApiOrder && isPending) {
        pendingCount++;
      }
    }

    return pendingCount;
  }

  /// ✅ Méthode qui vérifie le statut LOCAL des commandes API
  /// Retourne uniquement les commandes qui sont vraiment pending en local
  /// Utilisé par le login screen pour éviter de jouer le son pour des commandes déjà confirmées
  Future<int> countTrulyPendingApiOrders({required int restaurantId}) async {
    await init();
    if (restaurantId <= 0 || _authToken.isEmpty) {
      return 0;
    }

    final orders = await _fetchOrders(restaurantId: restaurantId);
    if (orders.isEmpty) {
      return 0;
    }

    var trulyPendingCount = 0;

    for (final raw in orders) {
      final orderRestaurantId = _extractRestaurantId(raw) ?? restaurantId;
      if (orderRestaurantId != restaurantId) {
        continue;
      }

      final channel = _asTrimmedString(raw['channel']).toLowerCase();
      final backendStatus = _asTrimmedString(raw['status']).toLowerCase();
      final isApiOrder =
          channel == 'api' || channel == 'web' || channel == 'kiosk';

      if (!isApiOrder) {
        continue;
      }

      // ✅ Vérifier le statut LOCAL de la commande
      final remoteOrderId = _asInt(raw['id']);
      if (remoteOrderId == null || remoteOrderId <= 0) {
        continue;
      }

      // Vérifier si on a déjà sync cette commande
      final previous = _remoteState[remoteOrderId];
      if (previous != null && previous.localId > 0) {
        // ✅ Lire le statut LOCAL depuis Isar
        await DatabaseService.init();
        final localOrder = await DatabaseService.getPosOrderById(
          previous.localId,
        );
        if (localOrder != null) {
          // ✅ Vérifier si c'est une commande delivery assignée
          final isDelivery =
              localOrder.fulfillmentType.trim().toLowerCase() == 'delivery';
          if (isDelivery) {
            // ✅ Vérifier si la commande delivery a déjà été assignée à un livreur
            final orderDeliveries =
                await DatabaseService.getAllOrderDeliveries();
            final isAssigned = orderDeliveries.any(
              (d) =>
                  d.orderId == localOrder.id &&
                  d.livreurId != null &&
                  d.assignedAt != null,
            );

            if (isAssigned) {
              // ✅ Commande delivery déjà assignée → ne pas compter comme pending
              appLogger.d(
                '✅ [DELIVERY ASSIGNED] Local order #${localOrder.id} delivery already assigned, not counting as pending',
              );
            } else {
              // ✅ Commande delivery pas encore assignée → compter comme pending si status pending
              if (localOrder.status == 'pending') {
                trulyPendingCount++;
                appLogger.d(
                  '📱 [DELIVERY PENDING] Local order #${localOrder.id} delivery not assigned yet, counting as pending',
                );
              } else {
                appLogger.d(
                  '✅ [DELIVERY NOT PENDING] Local order #${localOrder.id} status is ${localOrder.status}',
                );
              }
            }
          } else {
            // ✅ Ce n'est pas une commande delivery → utiliser le statut LOCAL
            if (localOrder.status == 'pending') {
              trulyPendingCount++;
              appLogger.d(
                '📱 [TRUE PENDING] Local order #${localOrder.id} is still pending (backend status: $backendStatus)',
              );
            } else {
              appLogger.d(
                '✅ [NOT PENDING] Local order #${localOrder.id} is ${localOrder.status} (backend status: $backendStatus)',
              );
            }
          }
        }
      } else {
        // Nouvelle commande pas encore sync → compter comme pending
        trulyPendingCount++;
        appLogger.d(
          '🆕 [NEW ORDER] Remote order $remoteOrderId not synced yet, counting as pending',
        );
      }
    }

    appLogger.d(
      '📊 [TRUE PENDING COUNT] Restaurant $restaurantId: $trulyPendingCount truly pending orders',
    );
    return trulyPendingCount;
  }

  Future<ApiOrderSyncResult> syncApiOrdersForRestaurant({
    required int restaurantId,
    int? fallbackStaffId,
    // 🚚 ALL orders are synced (delivery orders will be assigned via OrderDelivery table)
  }) async {
    await init();
    await DatabaseService.init();
    if (restaurantId <= 0 || _authToken.isEmpty) {
      return const ApiOrderSyncResult();
    }

    final orders = await _fetchOrders(restaurantId: restaurantId);
    if (orders.isEmpty) {
      appLogger.w(
        '⚠️ [API PULL] No orders received from backend for restaurant $restaurantId',
      );
      return const ApiOrderSyncResult();
    }

    final orderSummary = <String, int>{};
    final statusSummary = <String, int>{};
    for (final raw in orders) {
      final channel = _asTrimmedString(raw['channel']).toLowerCase();
      final status = _asTrimmedString(raw['status']).toLowerCase();
      if (channel.isNotEmpty) {
        orderSummary[channel] = (orderSummary[channel] ?? 0) + 1;
      } else {
        orderSummary['unknown'] = (orderSummary['unknown'] ?? 0) + 1;
      }
      if (status.isNotEmpty) {
        statusSummary[status] = (statusSummary[status] ?? 0) + 1;
      } else {
        statusSummary['unknown'] = (statusSummary['unknown'] ?? 0) + 1;
      }
    }
    appLogger.d(
      '📊 [API PULL] Received ${orders.length} backend orders for restaurant $restaurantId: '
      'channels=$orderSummary statuses=$statusSummary',
    );

    var changedCount = 0;
    var newOrdersCount = 0;
    var updatedOrdersCount = 0;
    var apiPendingOrdersCount =
        0; // Count API (mobile/web) orders with status pending
    var shouldPersistState = false;
    var skippedByRestaurant = 0;

    for (final raw in orders) {
      // Accepter toutes les commandes API (mobile/web) peu importe le fulfillment.

      final orderRestaurantId = _extractRestaurantId(raw) ?? restaurantId;
      if (orderRestaurantId != restaurantId) {
        skippedByRestaurant += 1;
        continue;
      }

      final remoteOrderId = _asInt(raw['id']);
      if (remoteOrderId == null || remoteOrderId <= 0) continue;

      // Check if this is an API order (mobile/web) with status pending
      final channel = _asTrimmedString(raw['channel']).toLowerCase();
      final status = _asTrimmedString(raw['status']).toLowerCase();
      final isApiOrder =
          channel == 'api' || channel == 'web' || channel == 'kiosk';
      final isPending = status == 'pending';

      // 🚚 Get fulfillment type
      final fulfillmentType = _asTrimmedString(
        raw['fulfillment_type'] ?? raw['fulfillmentType'],
      ).toLowerCase();
      // isDelivery et isOnSiteOrPickup ne sont plus utilisés car shouldCountForAudio gère le filtrage

      // 🚚 ALL orders are synced locally regardless of type/channel
      // Audio notification: only for pending orders that haven't been confirmed locally
      // (Delivery orders will be assigned to delivery staff via OrderDelivery table)
      final shouldCountForAudio = isPending;

      final updatedAtIso = _asDate(
        raw['updated_at'] ?? raw['created_at'],
      ).toIso8601String();
      final previous = _remoteState[remoteOrderId];

      // ✅ Check if order was already synced by localId (more reliable than timestamp)
      if (previous != null && previous.localId > 0) {
        // First check if the local order still exists
        final existingLocalOrder = await DatabaseService.getPosOrderById(
          previous.localId,
        );

        if (existingLocalOrder != null) {
          // ✅ Order exists - check if it needs update
          final needsUpdate = existingLocalOrder.updatedAt.isBefore(
            _asDate(raw['updated_at'] ?? raw['created_at']),
          );

          // 🔇 FIX: Don't count as pending if locally confirmed/updated after backend
          // Even if backend still shows 'pending', local state takes precedence
          final localIsNotPending = existingLocalOrder.status != 'pending';

          if (isApiOrder && isPending && localIsNotPending) {
            appLogger.d(
              '🔇 [SKIP AUDIO] API order $remoteOrderId is pending on backend '
              'but locally ${existingLocalOrder.status} (localId=${previous.localId}, needsUpdate=$needsUpdate)',
            );
          }

          if (!needsUpdate) {
            // ✅ Order is up to date, skip
            _remoteLocalOrderIds.add(previous.localId);
            continue;
          }

          // Order exists but needs update - will be handled by _upsertRemoteOrder
          // 🔇 But don't count as pending if already confirmed locally
          if (isApiOrder && isPending && localIsNotPending) {
            appLogger.d(
              '🔇 [SKIP AUDIO] API order $remoteOrderId pending on backend '
              'but locally ${existingLocalOrder.status} - will preserve local status',
            );
            // Don't count this as pending - it's already confirmed locally
            // Upsert will preserve the local status
          } else {
            appLogger.d(
              '📝 Remote order $remoteOrderId: local order #${previous.localId} exists but needs update',
            );
          }
        } else {
          // Local order was deleted, will recreate
          appLogger.d(
            '⚠️ Remote order $remoteOrderId: local order #${previous.localId} missing, will recreate',
          );
        }
      }

      // 🔇 Only count as pending if not already confirmed locally
      // 🚚 All orders are counted for audio (delivery will be assigned to livreur)
      // ✅ CRITICAL: Check LOCAL status, not backend status
      if (isApiOrder && isPending && shouldCountForAudio) {
        // ✅ Verify local order status before counting
        bool shouldCountAsPending = true;

        // Case 1: Order has been previously synced (has mapping)
        if (previous != null && previous.localId > 0) {
          final existingLocalOrder = await DatabaseService.getPosOrderById(
            previous.localId,
          );

          if (existingLocalOrder != null) {
            final localStatus = existingLocalOrder.status.trim().toLowerCase();
            // ✅ Don't count if locally confirmed/paid/ready/etc.
            if (localStatus != 'pending') {
              shouldCountAsPending = false;
              appLogger.d(
                '🔇 [SKIP AUDIO] API order $remoteOrderId is pending on backend '
                'but locally "$localStatus" (localId=${previous.localId}) - '
                'Local status takes precedence',
              );
            }
          }
        }

        // Case 2: Order exists in local DB but not yet mapped (check by remote_id)
        if (shouldCountAsPending) {
          final existingLocalOrderByRemote =
              await DatabaseService.getPosOrderBySourceLocalId(remoteOrderId);

          if (existingLocalOrderByRemote != null) {
            final localStatus = existingLocalOrderByRemote.status
                .trim()
                .toLowerCase();
            // ✅ Don't count if locally confirmed/paid/ready/etc.
            if (localStatus != 'pending') {
              shouldCountAsPending = false;
              appLogger.d(
                '🔇 [SKIP AUDIO] API order $remoteOrderId is pending on backend '
                'but locally "$localStatus" (found by sourceLocalId) - '
                'Local status takes precedence',
              );
            }
          }
        }

        if (shouldCountAsPending) {
          apiPendingOrdersCount++;
          appLogger.i(
            '📱 API Order pending detected: remote_id=$remoteOrderId, channel=$channel, '
            'fulfillment=$fulfillmentType',
          );
        }
      }

      final localOrderId = await _upsertRemoteOrder(
        raw: raw,
        restaurantId: restaurantId,
        fallbackStaffId: fallbackStaffId,
        localIdHint: previous?.localId,
        remoteOrderId: remoteOrderId,
        // 🔇 Preserve local status if it's more advanced than backend
        preserveLocalStatus:
            isApiOrder && isPending && previous != null && previous.localId > 0,
      );
      if (localOrderId == null || localOrderId.localId <= 0) {
        continue;
      }

      _remoteState[remoteOrderId] = _RemoteOrderSyncState(
        localId: localOrderId.localId,
        updatedAt: updatedAtIso,
        restaurantId: restaurantId,
      );
      _remoteLocalOrderIds.add(localOrderId.localId);

      // ✅ Always mark state for save to preserve mapping
      shouldPersistState = true;

      if (localOrderId.created) {
        newOrdersCount += 1;
        changedCount += 1;
      } else {
        updatedOrdersCount += 1;
        changedCount += 1;
      }
    }

    // ✅ Always save state to preserve order mappings
    if (shouldPersistState || _remoteState.isNotEmpty) {
      await _saveState();
      appLogger.d(
        '💾 [API PULL] State saved: ${_remoteState.length} orders tracked',
      );
    }
    if (skippedByRestaurant > 0) {
      appLogger.d(
        '⚠️ API order pull skipped $skippedByRestaurant orders (restaurant mismatch, expected=$restaurantId)',
      );
    }
    appLogger.i(
      '📊 API Order Sync Result: new=$newOrdersCount, updated=$updatedOrdersCount, api_pending=$apiPendingOrdersCount',
    );
    return ApiOrderSyncResult(
      changedCount: changedCount,
      newOrdersCount: newOrdersCount,
      updatedOrdersCount: updatedOrdersCount,
      apiPendingOrdersCount: apiPendingOrdersCount,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrders({
    required int restaurantId,
  }) async {
    final seenRemoteIds = <int>{};
    final seenFallbackKeys = <String>{};
    final merged = <Map<String, dynamic>>[];

    // ✅ PRIMARY: Use `/api/orders/restaurant/{id}` (NO auth required)
    // This endpoint is public and specifically designed for POS devices
    final primaryOrdersUri =
        Uri.parse('$_baseUrl/api/orders/restaurant/$restaurantId').replace(
          queryParameters: {
            'per_page': '100',
            'limit': '100',
            'order_by': 'id',
            'direction': 'desc',
            'sort': '-id',
          },
        );
    final fallbackOrdersUri = Uri.parse(
      '$_baseUrl/api/orders/restaurant/$restaurantId',
    ).replace(queryParameters: {'per_page': '100', 'limit': '100'});

    // ✅ FALLBACK: If primary fails, try authenticated endpoint with restaurant_id param
    final authenticatedOrdersUri = Uri.parse('$_baseUrl/api/orders').replace(
      queryParameters: {
        'restaurant_id': restaurantId.toString(),
        'restaurantId': restaurantId.toString(),
        'per_page': '100',
        'limit': '100',
        'order_by': 'id',
        'direction': 'desc',
        'sort': '-id',
      },
    );
    final authenticatedFallbackUri = Uri.parse('$_baseUrl/api/orders').replace(
      queryParameters: {
        'restaurant_id': restaurantId.toString(),
        'restaurantId': restaurantId.toString(),
        'per_page': '100',
        'limit': '100',
      },
    );

    // Try unauthenticated route first
    var fetched = await _fetchOrdersFromUri(startUri: primaryOrdersUri);
    if (fetched.isEmpty) {
      fetched = await _fetchOrdersFromUri(startUri: fallbackOrdersUri);
    }

    // If still empty, fallback to authenticated endpoint
    if (fetched.isEmpty) {
      appLogger.d(
        '⚠️ [API PULL] Unauthenticated endpoint returned 0 orders, trying authenticated endpoint...',
      );
      fetched = await _fetchOrdersFromUri(startUri: authenticatedOrdersUri);
      if (fetched.isEmpty) {
        fetched = await _fetchOrdersFromUri(startUri: authenticatedFallbackUri);
      }
    }

    _mergeFetchedOrders(
      source: fetched,
      merged: merged,
      seenRemoteIds: seenRemoteIds,
      seenFallbackKeys: seenFallbackKeys,
    );

    if (!_syncOrdersEndpointUnavailable) {
      final primarySyncUri = Uri.parse('$_baseUrl/api/sync/orders').replace(
        queryParameters: {
          'restaurant_id': restaurantId.toString(),
          'restaurantId': restaurantId.toString(),
          'per_page': '100',
          'limit': '100',
          'order_by': 'id',
          'direction': 'desc',
          'sort': '-id',
        },
      );
      final fallbackSyncUri = Uri.parse('$_baseUrl/api/sync/orders').replace(
        queryParameters: {
          'restaurant_id': restaurantId.toString(),
          'restaurantId': restaurantId.toString(),
          'per_page': '100',
          'limit': '100',
        },
      );

      var fetchedSync = await _fetchOrdersFromUri(startUri: primarySyncUri);
      if (fetchedSync.isEmpty && !_syncOrdersEndpointUnavailable) {
        fetchedSync = await _fetchOrdersFromUri(startUri: fallbackSyncUri);
      }
      _mergeFetchedOrders(
        source: fetchedSync,
        merged: merged,
        seenRemoteIds: seenRemoteIds,
        seenFallbackKeys: seenFallbackKeys,
      );
    }

    return merged;
  }

  void _mergeFetchedOrders({
    required List<Map<String, dynamic>> source,
    required List<Map<String, dynamic>> merged,
    required Set<int> seenRemoteIds,
    required Set<String> seenFallbackKeys,
  }) {
    for (final raw in source) {
      final remoteId = _asInt(raw['id']);
      if (remoteId != null && remoteId > 0) {
        if (!seenRemoteIds.add(remoteId)) continue;
        merged.add(raw);
        continue;
      }

      final fallbackKey = _firstNonEmptyString([
        _asTrimmedString(raw['client_order_id']),
        _asTrimmedString(raw['reference']),
        _asTrimmedString(raw['order_number']),
        json.encode(raw),
      ]);
      if (!seenFallbackKeys.add(fallbackKey)) continue;
      merged.add(raw);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersFromUri({
    required Uri startUri,
  }) async {
    final collected = <Map<String, dynamic>>[];
    final seenUrls = <String>{};
    String? previousPageFingerprint;
    var currentUri = startUri;

    for (var page = 0; page < 12; page++) {
      final currentUrl = currentUri.toString();
      if (!seenUrls.add(currentUrl)) break;

      http.Response response;
      try {
        response = await http.get(
          currentUri,
          headers: _headersForUri(currentUri),
        );
      } catch (_) {
        break;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          appLogger.e(
            '❌ Authentication failed: HTTP 401 on ${currentUri.path}. '
            'Token present=${_authToken.isNotEmpty}, '
            'token_start=${_authToken.isNotEmpty ? _authToken.substring(0, _authToken.length.clamp(0, 30)) : "EMPTY"}...',
          );
        } else if (response.statusCode == 404 &&
            currentUri.path.contains('/api/sync/orders')) {
          _syncOrdersEndpointUnavailable = true;
          appLogger.d('ℹ️ Disable /api/sync/orders pull (HTTP 404)');
        }
        appLogger.d(
          '⚠️ Pull skipped ${currentUri.path}: HTTP ${response.statusCode}',
        );
        break;
      }

      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        break;
      }

      final pageOrders = _extractOrderList(decoded);
      if (pageOrders.isNotEmpty) {
        final pageIds = pageOrders
            .map((order) => _asInt(order['id']))
            .whereType<int>()
            .take(10)
            .toList();
        final pageFingerprint = '${pageOrders.length}:${pageIds.join(',')}';
        if (previousPageFingerprint != null &&
            previousPageFingerprint == pageFingerprint) {
          appLogger.d(
            '⚠️ Stop paging on ${startUri.path}: repeated page signature (page param likely ignored).',
          );
          break;
        }
        previousPageFingerprint = pageFingerprint;
        collected.addAll(pageOrders);
      }

      final next = _extractNextPageUri(
        decoded,
        currentUri: currentUri,
        currentPageIndex: page,
      );
      final fallbackNext =
          next ??
          _fallbackNextPageUri(
            decoded: decoded,
            currentUri: currentUri,
            currentPageIndex: page,
            currentPageCount: pageOrders.length,
          );
      if (fallbackNext == null) break;
      currentUri = fallbackNext;
    }

    if (collected.isNotEmpty) {
      appLogger.d('📥 Pulled ${collected.length} orders from ${startUri.path}');
      final ids = collected
          .map((order) => _asInt(order['id']))
          .whereType<int>()
          .toList();
      if (ids.isNotEmpty) {
        ids.sort();
        appLogger.d(
          '📥 Window ids ${ids.first}..${ids.last} (count=${ids.length})',
        );
      }
    }
    return collected;
  }

  Future<_UpsertRemoteOrderResult?> _upsertRemoteOrder({
    required Map<String, dynamic> raw,
    required int restaurantId,
    required int? fallbackStaffId,
    required int? localIdHint,
    int? remoteOrderId, // ID distant pour le debug
    bool preserveLocalStatus =
        false, // 🔇 Garder le statut local s'il est plus avancé
  }) async {
    if (restaurantId <= 0) {
      appLogger.d(
        '❌ Cannot upsert remote order $remoteOrderId: missing restaurantId',
      );
      return null;
    }
    PosOrder? existingOrder;

    // 1. Si on a un localIdHint, vérifier qu'il existe toujours
    if (localIdHint != null && localIdHint > 0) {
      existingOrder = await _normalizeExistingOrderMatch(
        order: await DatabaseService.getPosOrderById(localIdHint),
        restaurantId: restaurantId,
        remoteOrderId: remoteOrderId,
        matchSource: 'localIdHint',
      );
      if (existingOrder != null) {
        appLogger.d(
          '🔍 Found existing order by localIdHint: #$localIdHint (remote=$remoteOrderId)',
        );
      } else {
        appLogger.d(
          '⚠️ localIdHint #$localIdHint not found in DB, will search for similar',
        );
      }
    }

    final sourceLocalId = _asInt(
      raw['source_local_id'] ?? raw['local_id'] ?? raw['sourceLocalId'],
    );

    if (existingOrder == null) {
      if (sourceLocalId != null && sourceLocalId > 0) {
        existingOrder = await _normalizeExistingOrderMatch(
          order: await DatabaseService.getPosOrderBySourceLocalId(
            sourceLocalId,
          ),
          restaurantId: restaurantId,
          remoteOrderId: remoteOrderId,
          matchSource: 'source_local_id',
        );
        if (existingOrder != null) {
          appLogger.d(
            '🔗 Found existing order by source_local_id: #$sourceLocalId (remote=$remoteOrderId)',
          );
        }
      }
    }

    // 2. Chercher par remoteId si on a un champ remote_id dans le modèle
    // (à implémenter dans une future version)

    final rawStatus = _firstNonEmptyString([
      _asTrimmedString(raw['order_status']),
      _asTrimmedString(raw['orderStatus']),
      _asTrimmedString(raw['status']),
      _asTrimmedString(raw['state']),
    ]);
    final normalizedStatus = _normalizeStatus(rawStatus);
    final rawPaymentStatus = _firstNonEmptyString([
      _asTrimmedString(raw['payment_status']),
      _asTrimmedString(raw['paymentStatus']),
    ]);
    final normalizedFulfillment = _normalizeFulfillment(
      raw['fulfillment_type'],
    );
    final totalPrice = _resolveTotalPrice(raw);
    final discountAmount = _asDouble(raw['discount_amount']);
    final originalTotal = _resolveOriginalTotal(
      raw: raw,
      totalPrice: totalPrice,
      discountAmount: discountAmount,
    );

    final userMap = _extractMap(raw['user']);
    final customerName = _firstNonEmptyString([
      _asTrimmedString(raw['customer_name']),
      _asTrimmedString(userMap['name']),
    ]);
    final customerPhone = _firstNonEmptyString([
      _asTrimmedString(raw['customer_phone']),
      _asTrimmedString(userMap['phone']),
    ]);
    final staffId = _resolveStaffId(raw, fallbackStaffId: fallbackStaffId);
    final createdAt = _asDate(raw['created_at']);
    final updatedAt = _asDate(raw['updated_at'] ?? raw['created_at']);
    final remoteTableNumber = _asNullableString(raw['table_number']);
    final incomingChannel = _normalizeChannel(
      _firstNonEmptyString([
        _asTrimmedString(raw['channel']),
        _asTrimmedString(raw['source']),
        _asTrimmedString(raw['origin']),
      ]),
    );

    appLogger.d(
      '📥 Processing remote order $remoteOrderId: channel=$incomingChannel, '
      'total=$totalPrice, createdAt=$createdAt, table=$remoteTableNumber',
    );

    // Déduplication : si une commande locale POS avec mêmes signature existe,
    // on relie simplement le remoteId sans recréer.
    if (existingOrder == null && incomingChannel == 'pos') {
      appLogger.d('  🔍 Searching for similar local POS order...');

      // 1. Chercher par table + total + heure (critères stricts)
      existingOrder = await DatabaseService.findSimilarLocalPosOrder(
        createdAt: createdAt,
        totalPrice: totalPrice,
        tableNumber: remoteTableNumber,
        fulfillmentType: normalizedFulfillment,
        tolerance: const Duration(seconds: 30),
        sourceLocalId: sourceLocalId,
      );
      existingOrder = await _normalizeExistingOrderMatch(
        order: existingOrder,
        restaurantId: restaurantId,
        remoteOrderId: remoteOrderId,
        matchSource: 'table+total+time',
      );
      if (existingOrder != null) {
        appLogger.d(
          '  🔗 POS dedup found: local #${existingOrder.id} ~= remote $remoteOrderId',
        );
        return _UpsertRemoteOrderResult(
          localId: existingOrder.id,
          created: false,
        );
      }
      appLogger.d('  ❌ No match by table+total+time');

      // 2. Chercher par phone + total si on a un phone client
      if (customerPhone.trim().isNotEmpty) {
        final normalizedPhone = customerPhone.trim().replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );
        existingOrder = await DatabaseService.findSimilarLocalPosOrder(
          createdAt: createdAt,
          totalPrice: totalPrice,
          tableNumber: null,
          fulfillmentType: normalizedFulfillment,
          channel: 'pos',
          tolerance: const Duration(seconds: 30),
          customerPhone: normalizedPhone,
          sourceLocalId: sourceLocalId,
        );
        existingOrder = await _normalizeExistingOrderMatch(
          order: existingOrder,
          restaurantId: restaurantId,
          remoteOrderId: remoteOrderId,
          matchSource: 'phone+total',
        );
        if (existingOrder != null) {
          appLogger.d(
            '  🔗 POS dedup by phone: local #${existingOrder.id} (phone=$normalizedPhone) ~= remote $remoteOrderId',
          );
          return _UpsertRemoteOrderResult(
            localId: existingOrder.id,
            created: false,
          );
        }
        appLogger.d('  ❌ No match by phone');
      }
    }

    // Pour les commandes API/mobile/web, on cherche aussi à dédupliquer
    // par remote_id ou par signature (created_at + total + channel)
    if (existingOrder == null && incomingChannel != 'pos') {
      appLogger.d(
        '  🔍 Searching for similar remote order (channel=$incomingChannel)...',
      );

      // Chercher par remote_id si disponible (futur : ajouter champ remote_id dans PosOrder)
      // Pour l'instant, on utilise created_at + total + channel comme signature unique
      existingOrder = await DatabaseService.findSimilarLocalPosOrder(
        createdAt: createdAt,
        totalPrice: totalPrice,
        tableNumber: null,
        fulfillmentType: normalizedFulfillment,
        channel: incomingChannel,
        customerPhone: customerPhone.trim().isEmpty ? null : customerPhone,
        sourceLocalId: sourceLocalId,
      );
      existingOrder = await _normalizeExistingOrderMatch(
        order: existingOrder,
        restaurantId: restaurantId,
        remoteOrderId: remoteOrderId,
        matchSource: 'remote signature',
      );
      if (existingOrder != null) {
        appLogger.d(
          '  🔗 Remote dedup found: local #${existingOrder.id} ~= remote $remoteOrderId (channel=$incomingChannel)',
        );
        return _UpsertRemoteOrderResult(
          localId: existingOrder.id,
          created: false,
        );
      }
      appLogger.d('  ❌ No match for remote order');
    }

    final localChannel = existingOrder != null
        ? _normalizeChannel(existingOrder.channel)
        : incomingChannel;
    final resolvedChannel = localChannel == 'pos' && incomingChannel != 'pos'
        ? incomingChannel
        : localChannel;

    final isGlovoDelivery = _asBool(raw['is_glovo_delivery']) ?? false;

    final order =
        existingOrder ??
        PosOrder(
          staffId: staffId,
          restaurantId: restaurantId,
          channel: resolvedChannel,
          fulfillmentType: normalizedFulfillment,
          status: normalizedStatus,
          totalPrice: totalPrice,
          originalTotal: originalTotal,
          discountAmount: discountAmount,
          hasDiscount: discountAmount > 0,
          paymentMethod:
              _asNullableString(raw['payment_method']) ??
              'cod', // ✅ Valeur par défaut si null
          paymentStatus: _normalizePaymentStatus(
            rawPaymentStatus,
            status: normalizedStatus,
          ),
          customerName: customerName,
          customerPhone: customerPhone,
          deliveryAddress: _asNullableString(raw['delivery_address']),
          tableNumber: remoteTableNumber,
          note: _asNullableString(raw['note']),
          rewardId: _asInt(raw['reward_id']),
          cancelReason: _asNullableString(raw['cancel_reason']),
          isGlovoDelivery: isGlovoDelivery,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

    order.staffId = staffId;
    order.restaurantId = restaurantId;
    order.sourceLocalId = sourceLocalId ?? order.sourceLocalId;
    order.channel = resolvedChannel;
    // ✅ Ne marquer isFromApi=true QUE pour les commandes NON-POS
    // Les commandes POS pushées puis repullées doivent garder isFromApi=false
    order.isFromApi =
        incomingChannel == 'api' ||
        incomingChannel == 'web' ||
        incomingChannel == 'mobile' ||
        incomingChannel == 'kiosk';
    order.fulfillmentType = normalizedFulfillment;

    // 🔇 Preserve local staffId if backend doesn't have one
    // (e.g., staff confirmed this order locally, backend hasn't synced yet)
    // 🚚 Works for ALL order types: on_site, pickup, delivery (including Web/API)
    if (existingOrder != null && existingOrder.staffId > 0 && staffId <= 0) {
      order.staffId = existingOrder.staffId;
      appLogger.d(
        '🔇 [PRESERVE STAFF] Local order #${existingOrder.id} '
        'staffId=${existingOrder.staffId} preserved (channel=${order.channel}, '
        'fulfillment=${order.fulfillmentType}, backend staffId=$staffId)',
      );
    }

    // 🔇 Preserve local status if it's more advanced than backend
    // (e.g., local is 'confirmed' but backend still shows 'pending')
    if (preserveLocalStatus && existingOrder != null) {
      final statusOrder = [
        'pending',
        'confirmed',
        'preparing',
        'ready',
        'delivered',
      ];
      final localStatusIndex = statusOrder.indexOf(existingOrder.status);
      final backendStatusIndex = statusOrder.indexOf(normalizedStatus);

      if (localStatusIndex > backendStatusIndex) {
        // Local status is more advanced, keep it
        order.status = existingOrder.status;
        order.paymentStatus = existingOrder.paymentStatus;

        // 💳 PRESERVE PAYMENT METHOD & SPLIT
        // Si la commande locale est payée, préserver paymentMethod et paymentSplit
        // Le backend peut ne pas avoir ces infos ou avoir des valeurs obsolètes
        if (existingOrder.paymentStatus == 'paid') {
          order.paymentMethod = existingOrder.paymentMethod;
          order.paymentSplit = existingOrder.paymentSplit;

          appLogger.d(
            '💳 [PRESERVE PAYMENT] Local order #${existingOrder.id} '
            'paymentMethod=${existingOrder.paymentMethod}, '
            'paymentSplit preserved (backend may not have this data)',
          );
        }

        appLogger.d(
          '🔇 [PRESERVE] Local order #${existingOrder.id} status=${existingOrder.status} '
          'is more advanced than backend status=$normalizedStatus (remote=$remoteOrderId)',
        );
      } else {
        order.status = normalizedStatus;
        order.paymentStatus = _normalizePaymentStatus(
          rawPaymentStatus,
          status: normalizedStatus,
        );
      }
    } else {
      order.status = normalizedStatus;
      order.paymentStatus = _normalizePaymentStatus(
        rawPaymentStatus,
        status: normalizedStatus,
      );
    }

    // 💳 PRESERVE LOCAL PAYMENT METHOD IF BACKEND HAS NONE
    // Si la commande existe déjà localement avec un paymentMethod défini
    // mais que le backend n'en a pas (null ou vide), préserver la valeur locale
    if (existingOrder != null) {
      final backendPaymentMethod = _asNullableString(raw['payment_method']);
      final hasLocalPaymentMethod =
          existingOrder.paymentMethod != null &&
          existingOrder.paymentMethod!.isNotEmpty;
      final hasBackendPaymentMethod =
          backendPaymentMethod != null && backendPaymentMethod.isNotEmpty;

      if (hasLocalPaymentMethod && !hasBackendPaymentMethod) {
        order.paymentMethod = existingOrder.paymentMethod;
        appLogger.d(
          '💳 [PRESERVE PAYMENT METHOD] Local order #${existingOrder.id} '
          'paymentMethod=${existingOrder.paymentMethod} preserved '
          '(backend has no payment_method)',
        );
      }

      // 💳 PRESERVE PAYMENT SPLIT IF BACKEND HAS NONE
      // Même logique pour paymentSplit
      final hasLocalPaymentSplit =
          existingOrder.paymentSplit != null &&
          existingOrder.paymentSplit!.isNotEmpty;
      // Le backend ne synchronise généralement pas paymentSplit, donc on préserve toujours si local en a un
      if (hasLocalPaymentSplit) {
        order.paymentSplit = existingOrder.paymentSplit;
        appLogger.d(
          '💳 [PRESERVE PAYMENT SPLIT] Local order #${existingOrder.id} '
          'paymentSplit preserved (${existingOrder.paymentSplit!.length} chars)',
        );
      }
    }

    order.totalPrice = totalPrice;
    order.customerName = customerName;
    order.customerPhone = customerPhone;
    order.deliveryAddress = _asNullableString(raw['delivery_address']);
    // Mapper livreur_id depuis la réponse backend
    order.deliveryLivreurId = _asInt(raw['livreur_id']);
    // Mapper user_id depuis la réponse backend
    order.userId = _asInt(raw['user_id']);
    order.tableNumber = _asNullableString(raw['table_number']);
    order.note = _asNullableString(raw['note']);
    order.rewardId = _asInt(raw['reward_id']);
    order.cancelReason = _asNullableString(raw['cancel_reason']);
    order.isGlovoDelivery = isGlovoDelivery;
    order.createdAt = createdAt;
    order.updatedAt = updatedAt;

    // 🚚 Sync OrderDelivery quand livreur_id est présent et c'est une livraison
    if (order.deliveryLivreurId != null &&
        order.fulfillmentType == 'delivery') {
      await _syncOrderDeliveryFromBackend(order, raw);
    }

    int localOrderId;
    final created = existingOrder == null;
    if (existingOrder == null) {
      localOrderId = await DatabaseService.createPosOrder(order);
      appLogger.d(
        '✅ Created local order #$localOrderId for remote order $remoteOrderId '
        '(channel=${order.channel}, restaurantId=${order.restaurantId}, staffId=${order.staffId})',
      );
    } else {
      localOrderId = order.id;
      await DatabaseService.updatePosOrder(order);
      appLogger.d(
        '🔄 Updated local order #$localOrderId for remote order $remoteOrderId',
      );
    }

    // 🔧 MERGE STRATEGY: Preserve local items if backend has none
    final items = _extractOrderItems(raw);
    
    if (items.isEmpty && !created) {
      // Backend returned no items for existing order - PRESERVE LOCAL ITEMS
      final existingItems = await DatabaseService.getPosOrderItems(localOrderId);
      appLogger.w(
        '⚠️ [API MERGE] Backend returned 0 items for updated order #$localOrderId (remote=$remoteOrderId). '
        'Preserving ${existingItems.length} local items to prevent data loss.',
      );
    } else if (items.isNotEmpty || created) {
      // Backend has items OR this is a new order - DELETE OLD AND CREATE NEW
      if (!created) {
        await DatabaseService.deletePosOrderItems(localOrderId);
        appLogger.d(
          '🗑️ [API MERGE] Deleted existing items for updated order #$localOrderId '
          '(will replace with ${items.length} backend items)',
        );
      }
      
      // Create new items from backend
      appLogger.i(
        '📦 [API] Creating ${items.length} items for local order #$localOrderId (remote=$remoteOrderId)',
      );
      for (final item in items) {
        final orderItem = PosOrderItem(
          orderId: localOrderId,
          productId: item.productId,
          productName: item.productName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          groupNumber: item.groupNumber,
          groupLabel: item.groupLabel,
          itemNote: item.itemNote,
          serviceCourseKey: item.serviceCourseKey,
          serviceCourseLabel: item.serviceCourseLabel,
          priceType: item.priceType,
          glovoBasePrice: item.glovoBasePrice,
          createdAt: createdAt,
        );
        await DatabaseService.createPosOrderItem(orderItem);
      }
      appLogger.i('✅ [API] Items created for order #$localOrderId');
    }

    return _UpsertRemoteOrderResult(localId: localOrderId, created: created);
  }

  Future<PosOrder?> _normalizeExistingOrderMatch({
    required PosOrder? order,
    required int restaurantId,
    required int? remoteOrderId,
    required String matchSource,
  }) async {
    if (order == null) return null;

    final currentRestaurantId = order.restaurantId;
    if (currentRestaurantId == null || currentRestaurantId <= 0) {
      order.restaurantId = restaurantId;
      await DatabaseService.updatePosOrder(order);
      appLogger.d(
        '🔧 Fixed restaurantId for local order #${order.id} before $matchSource matching '
        '(remote=$remoteOrderId, restaurantId=$restaurantId)',
      );
      return order;
    }

    if (currentRestaurantId != restaurantId) {
      appLogger.d(
        '⚠️ Ignoring local order #${order.id} from $matchSource: '
        'restaurantId=$currentRestaurantId expected=$restaurantId (remote=$remoteOrderId)',
      );
      return null;
    }

    return order;
  }

  List<Map<String, dynamic>> _extractOrderList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is! Map) return const [];

    final root = Map<String, dynamic>.from(decoded);
    final rootId = _asInt(root['id']);
    if (rootId != null && rootId > 0) {
      return [root];
    }
    final directCandidates = [
      root['data'],
      root['orders'],
      root['items'],
      root['results'],
    ];
    for (final candidate in directCandidates) {
      final parsed = _mapList(candidate);
      if (parsed.isNotEmpty) return parsed;
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final nestedId = _asInt(nested['id']);
      if (nestedId != null && nestedId > 0) {
        return [nested];
      }
      final nestedCandidates = [
        nested['data'],
        nested['orders'],
        nested['items'],
        nested['results'],
      ];
      for (final candidate in nestedCandidates) {
        final parsed = _mapList(candidate);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    return const [];
  }

  Uri? _extractNextPageUri(
    dynamic decoded, {
    required Uri currentUri,
    required int currentPageIndex,
  }) {
    if (decoded is! Map) return null;
    final root = Map<String, dynamic>.from(decoded);

    final nextRoot = _asTrimmedString(root['next_page_url']);
    if (nextRoot.isNotEmpty) {
      return _resolveUri(nextRoot);
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final nextNested = _asTrimmedString(nested['next_page_url']);
      if (nextNested.isNotEmpty) {
        return _resolveUri(nextNested);
      }
    }

    final linksRoot = root['links'];
    final linksRootNext = _extractNextUriFromLinks(linksRoot);
    if (linksRootNext != null) {
      return linksRootNext;
    }

    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final linksNested = nested['links'];
      final linksNestedNext = _extractNextUriFromLinks(linksNested);
      if (linksNestedNext != null) {
        return linksNestedNext;
      }
    }

    final metaRoot = _extractMap(root['meta']);
    final nextRootFromMeta = _nextUriFromMeta(metaRoot, currentUri: currentUri);
    if (nextRootFromMeta != null) return nextRootFromMeta;

    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final metaNested = _extractMap(nested['meta']);
      final nextNestedFromMeta = _nextUriFromMeta(
        metaNested,
        currentUri: currentUri,
      );
      if (nextNestedFromMeta != null) return nextNestedFromMeta;
    }

    final rootCurrentPage = _asInt(root['current_page']);
    final rootLastPage = _asInt(root['last_page']);
    if (rootCurrentPage != null &&
        rootLastPage != null &&
        rootCurrentPage < rootLastPage) {
      return _replacePageQuery(currentUri, rootCurrentPage + 1);
    }

    if (rootCurrentPage == null && rootLastPage == null) {
      // Last resort when API omits pagination metadata but still expects ?page=
      if (currentPageIndex == 0 &&
          !currentUri.queryParameters.containsKey('page')) {
        return _replacePageQuery(currentUri, 2);
      }
    }

    return null;
  }

  Uri? _extractNextUriFromLinks(dynamic linksValue) {
    if (linksValue is Map) {
      final map = Map<String, dynamic>.from(linksValue);
      final directNext = _asTrimmedString(map['next']);
      if (directNext.isNotEmpty) {
        return _resolveUri(directNext);
      }
    }

    if (linksValue is! List) return null;
    for (final link in linksValue) {
      if (link is! Map) continue;
      final map = Map<String, dynamic>.from(link);
      final label = _asTrimmedString(map['label']).toLowerCase();
      final rel = _asTrimmedString(map['rel']).toLowerCase();
      final url = _asTrimmedString(map['url']);
      if (url.isEmpty) continue;
      if (rel == 'next' ||
          label.contains('next') ||
          label.contains('suivant')) {
        return _resolveUri(url);
      }
    }
    return null;
  }

  Uri? _nextUriFromMeta(Map<String, dynamic> meta, {required Uri currentUri}) {
    if (meta.isEmpty) return null;

    final currentPage = _asInt(meta['current_page']);
    final lastPage = _asInt(meta['last_page']);
    if (currentPage == null || lastPage == null || currentPage >= lastPage) {
      return null;
    }
    return _replacePageQuery(currentUri, currentPage + 1);
  }

  Uri _replacePageQuery(Uri currentUri, int pageNumber) {
    final nextParams = Map<String, String>.from(currentUri.queryParameters);
    nextParams['page'] = pageNumber.toString();
    return currentUri.replace(queryParameters: nextParams);
  }

  Uri? _fallbackNextPageUri({
    required dynamic decoded,
    required Uri currentUri,
    required int currentPageIndex,
    required int currentPageCount,
  }) {
    // Some backend responses never expose next_page_url/meta;
    // probe ?page=2+ when a page is "full".
    if (currentPageCount <= 0) return null;
    if (currentPageIndex >= 10) return null;

    final rawPerPage =
        currentUri.queryParameters['per_page'] ??
        currentUri.queryParameters['limit'];
    final perPage = int.tryParse(rawPerPage ?? '') ?? 0;
    final threshold = perPage > 0 ? perPage : 50;
    if (currentPageCount < threshold) {
      return null;
    }

    if (decoded is Map) {
      final root = Map<String, dynamic>.from(decoded);
      final currentPage = _asInt(root['current_page']);
      final lastPage = _asInt(root['last_page']);
      if (currentPage != null && lastPage != null && currentPage >= lastPage) {
        return null;
      }
      if (currentPage != null) {
        return _replacePageQuery(currentUri, currentPage + 1);
      }
    }

    final currentPageQuery =
        int.tryParse(currentUri.queryParameters['page'] ?? '') ?? 1;
    return _replacePageQuery(currentUri, currentPageQuery + 1);
  }

  Uri? _resolveUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    final base = Uri.tryParse(_baseUrl);
    if (base == null) return null;
    return base.resolve(trimmed);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int? _extractRestaurantId(Map<String, dynamic> raw) {
    final directCandidates = [
      raw['restaurant_id'],
      raw['restaurantId'],
      raw['store_id'],
      raw['storeId'],
      raw['branch_id'],
      raw['branchId'],
      raw['shop_id'],
      raw['shopId'],
      raw['vendor_id'],
      raw['vendorId'],
    ];
    for (final candidate in directCandidates) {
      final parsed = _asInt(candidate);
      if (parsed != null && parsed > 0) return parsed;
    }

    final restaurant = _extractMap(
      raw['restaurant'] ?? raw['store'] ?? raw['branch'],
    );
    final nestedRestaurantCandidates = [
      restaurant['id'],
      restaurant['restaurant_id'],
      restaurant['restaurantId'],
      restaurant['store_id'],
      restaurant['storeId'],
      restaurant['branch_id'],
      restaurant['branchId'],
    ];
    for (final candidate in nestedRestaurantCandidates) {
      final parsed = _asInt(candidate);
      if (parsed != null && parsed > 0) return parsed;
    }

    final userMap = _extractMap(raw['user']);
    final staffMap = _extractMap(raw['staff']);
    final fallbackCandidates = [
      userMap['restaurant_id'],
      userMap['restaurantId'],
      staffMap['restaurant_id'],
      staffMap['restaurantId'],
    ];
    for (final candidate in fallbackCandidates) {
      final parsed = _asInt(candidate);
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
  }

  List<_RemoteOrderItem> _extractOrderItems(Map<String, dynamic> raw) {
    final detailsCandidates = [
      raw['details'],
      raw['orderDetails'],
      raw['items'],
      raw['order_items'],
      raw['orderItems'],
      raw['order_details'],
      raw['products'],
      raw['order_products'],
    ];
    List<dynamic> details = const [];
    for (final candidate in detailsCandidates) {
      if (candidate is List) {
        details = candidate;
        break;
      }
      if (candidate is Map && candidate['data'] is List) {
        details = candidate['data'] as List;
        break;
      }
    }

    appLogger.d(
      '📦 [API] Extracting items from order: found ${details.length} items',
    );
    if (details.isNotEmpty) {
      appLogger.d('📦 [API] Items keys in raw: ${raw.keys.join(', ')}');
    } else {
      // Debug: show all keys and check if any might contain items
      appLogger.d('📦 [API] No items found in response. Raw keys: ${raw.keys.join(', ')}');
      // Check for nested structures
      for (final key in raw.keys) {
        final value = raw[key];
        if (value is List) {
          appLogger.d('   └─ Key "$key" is a List with ${value.length} items');
        } else if (value is Map) {
          appLogger.d(
            '   └─ Key "$key" is a Map with keys: ${value.keys.join(', ')}',
          );
        }
      }
    }

    final parsed = <_RemoteOrderItem>[];
    for (final detail in details) {
      if (detail is! Map) continue;
      final detailMap = Map<String, dynamic>.from(detail);
      final productMap = _extractMap(detailMap['product']);
      final quantity = (_asInt(detailMap['quantity'] ?? detailMap['qty']) ?? 1)
          .clamp(1, 1000000);

      var unitPrice = _asDouble(detailMap['unit_price']);
      if (unitPrice <= 0) unitPrice = _asDouble(detailMap['price']);
      if (unitPrice <= 0) unitPrice = _asDouble(detailMap['total_price']);
      if (unitPrice <= 0) unitPrice = _asDouble(detailMap['product_price']);
      if (unitPrice <= 0) {
        final lineTotal = _asDouble(
          detailMap['line_total'] ?? detailMap['total'],
        );
        if (lineTotal > 0 && quantity > 0) {
          unitPrice = lineTotal / quantity;
        }
      }
      if (unitPrice <= 0) {
        unitPrice = _asDouble(productMap['price']);
      }

      final productId =
          _asInt(
            detailMap['product_id'] ??
                detailMap['productId'] ??
                productMap['id'],
          ) ??
          0;
      final productName = _firstNonEmptyString([
        _asTrimmedString(detailMap['product_name']),
        _asTrimmedString(detailMap['name']),
        _asTrimmedString(productMap['name']),
        productId > 0 ? 'Produit #$productId' : 'Produit',
      ]);

      appLogger.i(
        '📦 [API] Item: productId=$productId, name=$productName, qty=$quantity, price=$unitPrice',
      );

      parsed.add(
        _RemoteOrderItem(
          productId: productId,
          productName: productName,
          unitPrice: unitPrice > 0 ? unitPrice : 0.0,
          quantity: quantity,
          groupNumber: _asInt(
            detailMap['group_number'] ?? detailMap['groupNumber'],
          ),
          groupLabel: _asNullableString(
            detailMap['group_label'] ?? detailMap['groupLabel'],
          ),
          itemNote: _asNullableString(
            detailMap['item_note'] ??
                detailMap['itemNote'] ??
                detailMap['special_note'] ??
                detailMap['specialNote'],
          ),
          serviceCourseKey: _asNullableString(
            detailMap['service_course_key'] ?? detailMap['serviceCourseKey'],
          ),
          serviceCourseLabel: _asNullableString(
            detailMap['service_course_label'] ??
                detailMap['serviceCourseLabel'],
          ),
          priceType: _asNullableString(
            detailMap['price_type'] ?? detailMap['priceType'],
          ),
          glovoBasePrice: _asDouble(
            detailMap['base_price'] ??
                detailMap['glovo_base_price'] ??
                detailMap['glovoBasePrice'],
          ),
        ),
      );
    }
    return parsed;
  }

  int _resolveStaffId(
    Map<String, dynamic> raw, {
    required int? fallbackStaffId,
  }) {
    final staffId = _asInt(raw['staff_id'] ?? raw['staffId']);
    if (staffId != null && staffId > 0) {
      appLogger.d('  📍 staff_id from API: $staffId');
      return staffId;
    }
    if (fallbackStaffId != null && fallbackStaffId > 0) {
      appLogger.d('  📍 Using fallbackStaffId: $fallbackStaffId');
      return fallbackStaffId;
    }
    appLogger.d('  ⚠️ No staffId found, returning 0');
    return 0;
  }

  double _resolveTotalPrice(Map<String, dynamic> raw) {
    final candidates = [
      raw['total_price'],
      raw['total'],
      raw['grand_total'],
      raw['amount'],
    ];
    for (final value in candidates) {
      final parsed = _asDouble(value);
      if (parsed > 0) return parsed;
    }
    return 0.0;
  }

  double _resolveOriginalTotal({
    required Map<String, dynamic> raw,
    required double totalPrice,
    required double discountAmount,
  }) {
    final parsed = _asDouble(raw['original_total'] ?? raw['subtotal']);
    if (parsed > 0) return parsed;
    if (discountAmount > 0) return totalPrice + discountAmount;
    return totalPrice;
  }

  String _normalizeFulfillment(dynamic value) {
    final normalized = _asTrimmedString(value).toLowerCase();
    switch (normalized) {
      case 'on_site':
      case 'pickup':
      case 'delivery':
        return normalized;
      default:
        return 'delivery';
    }
  }

  String _normalizeChannel(dynamic value) {
    final normalized = _asTrimmedString(value).toLowerCase();
    switch (normalized) {
      case '':
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
        return 'pos';
      default:
        return normalized;
    }
  }

  String _normalizeStatus(dynamic value) {
    final normalized = _asTrimmedString(value).toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'confirmed':
      case 'accepted':
        return 'confirmed';
      case 'preparing':
      case 'in_preparation':
      case 'in_progress':
      case 'processing':
        return 'preparing';
      case 'ready':
      case 'prepared':
        return 'ready';
      case 'delivered':
      case 'in_delivery':
      case 'completed':
      case 'paid':
        return 'delivered';
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _normalizePaymentStatus(dynamic value, {required String status}) {
    final normalized = _asTrimmedString(value).toLowerCase();
    if (normalized == 'paid') return 'paid';
    if (status == 'delivered') return 'paid';
    return 'pending';
  }

  String _normalizeStatusForBackend(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'confirmed':
      case 'accepted':
        return 'confirmed';
      case 'preparing':
      case 'in_preparation':
      case 'in_progress':
      case 'processing':
        return 'preparing';
      case 'ready':
      case 'prepared':
        return 'ready';
      case 'delivered':
      case 'in_delivery':
      case 'completed':
      case 'paid':
        return 'delivered';
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  List<String> _backendStatusCandidates(String localStatus) {
    final normalizedLocal = localStatus.trim().toLowerCase();
    final preferred = _normalizeStatusForBackend(normalizedLocal);
    if (preferred.isEmpty) return const ['pending'];
    return [preferred];
  }

  String _normalizePaymentStatusForBackend(
    String? paymentStatus, {
    required String fallbackStatus,
  }) {
    final normalized = paymentStatus?.trim().toLowerCase() ?? '';
    if (normalized == 'paid') return 'paid';
    if (fallbackStatus == 'delivered' ||
        fallbackStatus == 'completed' ||
        fallbackStatus == 'paid') {
      return 'paid';
    }
    return 'pending';
  }

  Future<bool> _pushRemoteOrderStatus({
    required int localOrderId,
    required int remoteOrderId,
    required String backendStatus,
    required Map<String, dynamic> payload,
  }) async {
    const maxPushDuration = Duration(seconds: 4);
    final startedAt = DateTime.now();
    int? lastStatusCode;
    String? lastPath;
    String? lastBodyPreview;

    final attempts = <_OrderStatusEndpointAttempt>[
      _OrderStatusEndpointAttempt(
        method: 'POST',
        path: '/api/sync/public/orders/status',
        payload: {...payload, 'remote_order_id': remoteOrderId},
      ),
      _OrderStatusEndpointAttempt(
        method: 'PATCH',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'PUT',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'POST',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'POST',
        path: '/api/orders/$remoteOrderId/update-status',
        payload: payload,
      ),
    ];

    final orderedAttempts = <_OrderStatusEndpointAttempt>[];
    final preferred = _preferredStatusAttemptIndex;
    if (preferred != null && preferred >= 0 && preferred < attempts.length) {
      orderedAttempts.add(attempts[preferred]);
    }
    for (var i = 0; i < attempts.length; i++) {
      if (i == preferred) continue;
      orderedAttempts.add(attempts[i]);
    }

    for (final attempt in orderedAttempts) {
      if (DateTime.now().difference(startedAt) >= maxPushDuration) {
        appLogger.d(
          '⚠️ Remote status push timed out after ${maxPushDuration.inSeconds}s (remote=$remoteOrderId)',
        );
        break;
      }
      final uri = Uri.parse('$_baseUrl${attempt.path}');
      http.Response response;
      try {
        switch (attempt.method) {
          case 'PATCH':
            response = await http
                .patch(
                  uri,
                  headers: _headers,
                  body: json.encode(attempt.payload),
                )
                .timeout(const Duration(milliseconds: 1400));
            break;
          case 'PUT':
            response = await http
                .put(uri, headers: _headers, body: json.encode(attempt.payload))
                .timeout(const Duration(milliseconds: 1400));
            break;
          case 'POST':
            response = await http
                .post(
                  uri,
                  headers: _headers,
                  body: json.encode(attempt.payload),
                )
                .timeout(const Duration(milliseconds: 1400));
            break;
          default:
            continue;
        }
      } catch (_) {
        continue;
      }

      lastStatusCode = response.statusCode;
      lastPath = attempt.path;
      final rawBody = response.body;
      if (rawBody.isNotEmpty) {
        lastBodyPreview = rawBody.length > 220
            ? '${rawBody.substring(0, 220)}...'
            : rawBody;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final originalIndex = attempts.indexOf(attempt);
        if (originalIndex >= 0) {
          _preferredStatusAttemptIndex = originalIndex;
        }
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        break;
      }

      if (response.statusCode == 422) {
        break;
      }

      if (response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 501) {
        // 404 means the remote order doesn't exist on backend
        // Clear the stale cache entry to prevent repeated failures
        if (response.statusCode == 404) {
          appLogger.w(
            '🗑️ [CACHE CLEAR] Remote order #$remoteOrderId not found on backend (404). '
            'Clearing stale cache mapping for local order #$localOrderId.',
          );
          _remoteState.remove(remoteOrderId);
          _remoteLocalOrderIds.remove(localOrderId);
          _saveState(); // Persist the cache changes immediately
        }
        continue;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 422 ||
          response.statusCode >= 500) {
        final body = response.body;
        final preview = body.length > 240
            ? '${body.substring(0, 240)}...'
            : body;
        appLogger.d(
          '⚠️ Remote status rejected status=${response.statusCode} path=${attempt.path} body=$preview',
        );
      }
    }

    appLogger.d(
      '⚠️ Remote status push failed remote=$remoteOrderId status=$backendStatus last_code=${lastStatusCode ?? '-'} last_path=${lastPath ?? '-'} last_body=${lastBodyPreview ?? '-'}',
    );
    return false;
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

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime _asDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  DateTime? _asDateNullable(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _asTrimmedString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String? _asNullableString(dynamic value) {
    final str = _asTrimmedString(value);
    if (str.isEmpty) return null;
    return str;
  }

  /// 🚚 Créer/mettre à jour OrderDelivery quand le backend envoie livreur_id
  Future<void> _syncOrderDeliveryFromBackend(
    PosOrder order,
    Map<String, dynamic> raw,
  ) async {
    try {
      final livreurId = order.deliveryLivreurId;
      if (livreurId == null) return;

      // Extraire les timestamps et status du backend
      final assignedAt = _asDateNullable(
        raw['assigned_at'] ?? raw['livreur_assigned_at'],
      );
      final pickedUpAt = _asDateNullable(
        raw['picked_up_at'] ?? raw['livreur_picked_at'],
      );
      final deliveredAt = _asDateNullable(
        raw['delivered_at'] ?? raw['livreur_delivered_at'],
      );
      final deliveryStatus =
          _asNullableString(raw['delivery_status'] ?? raw['status']) ??
          (livreurId > 0 ? 'assigned' : 'pending');

      // Vérifier si OrderDelivery existe déjà
      OrderDelivery? delivery = await DatabaseService.getOrderDeliveryByOrderId(
        order.id,
      );

      if (delivery != null) {
        // Mettre à jour l'existant
        delivery.livreurId = livreurId;
        delivery.livreurName =
            _asNullableString(raw['livreur_name']) ?? delivery.livreurName;
        delivery.livreurPhone =
            _asNullableString(raw['livreur_phone']) ?? delivery.livreurPhone;
        delivery.status = deliveryStatus;
        delivery.assignedAt = assignedAt ?? delivery.assignedAt;
        delivery.pickedUpAt = pickedUpAt;
        delivery.deliveredAt = deliveredAt;
        delivery.updatedAt = DateTime.now();
        await DatabaseService.updateOrderDelivery(delivery);
        appLogger.d(
          '🚚 [PULL] OrderDelivery updated for order #${order.id} '
          '(livreur=$livreurId, status=$deliveryStatus)',
        );
      } else {
        // Créer un nouveau
        delivery = OrderDelivery(
          orderId: order.id,
          livreurId: livreurId,
          livreurName: _asNullableString(raw['livreur_name']),
          livreurPhone: _asNullableString(raw['livreur_phone']),
          status: deliveryStatus,
          assignedAt: assignedAt,
          pickedUpAt: pickedUpAt,
          deliveredAt: deliveredAt,
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.createOrderDelivery(delivery);
        appLogger.d(
          '🚚 [PULL] OrderDelivery created for order #${order.id} '
          '(livreur=$livreurId, status=$deliveryStatus)',
        );
      }
    } catch (e) {
      appLogger.e('❌ [PULL] Error syncing OrderDelivery: $e');
    }
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      return null;
    }
    return null;
  }

  String _firstNonEmptyString(List<String> values) {
    for (final value in values) {
      final v = value.trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Always include device token header when available — used by public POS endpoints
    if (AppConstant.apiToken.isNotEmpty) {
      headers['X-Device-Token'] = AppConstant.apiToken;
      headers['X-API-Token'] = AppConstant.apiToken;
    }

    // Add Authorization only when we have a real-looking Bearer token
    if (_authToken.isNotEmpty) {
      final isValidBearerToken =
          !_authToken.startsWith('local_pin_') && _authToken.length > 30;
      if (isValidBearerToken) {
        headers['Authorization'] = 'Bearer $_authToken';
      } else {
        // Do not add Authorization if token looks like PIN; log for diagnostics
        appLogger.d(
          '⚠️ [API HEADERS] Skipping Authorization: token looks like PIN or is too short',
        );
      }
    }

    return headers;
  }

  /// Build headers depending on the target URI.
  /// - Public POS endpoints (e.g. `/api/orders/restaurant/{id}` and
  ///   `ordersByRestaurant`) receive `X-Device-Token`/`X-API-Token`.
  /// - Authenticated endpoints (`/api/orders`, `/api/sync/orders`) receive
  ///   `Authorization: Bearer <token>` only when the token looks like a
  ///   real Sanctum token (not a short PIN token).
  Map<String, String> _headersForUri(Uri uri) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final path = uri.path.toLowerCase();

    final isPublicOrdersEndpoint =
        path.contains('/api/orders/restaurant') ||
        path.contains('/ordersbyrestaurant') ||
        path.contains('/api/orders/restaurant/');

    if (isPublicOrdersEndpoint) {
      if (AppConstant.apiToken.isNotEmpty) {
        headers['X-Device-Token'] = AppConstant.apiToken;
        headers['X-API-Token'] = AppConstant.apiToken;
      }
      return headers;
    }

    // Authenticated endpoints
    final isValidBearerToken =
        _authToken.isNotEmpty &&
        !_authToken.startsWith('local_pin_') &&
        _authToken.length > 30;
    if (isValidBearerToken) {
      headers['Authorization'] = 'Bearer $_authToken';
    } else if (AppConstant.apiToken.isNotEmpty) {
      // Provide device token as a fallback if no valid bearer token is present
      headers['X-Device-Token'] = AppConstant.apiToken;
      headers['X-API-Token'] = AppConstant.apiToken;
    }

    return headers;
  }

  Future<void> _loadState() async {
    final file = _stateFile;
    if (file == null) {
      appLogger.w('⚠️ [API PULL] Cannot load state: _stateFile is null');
      return;
    }
    if (!await file.exists()) {
      appLogger.d('📄 [API PULL] State file does not exist: ${file.path}');
      return;
    }
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        appLogger.d('📄 [API PULL] State file is empty');
        return;
      }
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) {
        appLogger.w('⚠️ [API PULL] Invalid state file format');
        return;
      }

      final rawOrders = decoded['orders'];
      final sourceMap = rawOrders is Map<String, dynamic> ? rawOrders : decoded;

      _remoteState.clear();
      _remoteLocalOrderIds.clear();
      for (final entry in sourceMap.entries) {
        final remoteId = int.tryParse(entry.key);
        if (remoteId == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final parsedValue = Map<String, dynamic>.from(value);
        final localId = _asInt(parsedValue['local_id']);
        final updatedAt = _asTrimmedString(parsedValue['updated_at']);
        final restaurantId = _asInt(parsedValue['restaurant_id']) ?? 0;
        if (localId == null || localId <= 0 || updatedAt.isEmpty) continue;
        _remoteState[remoteId] = _RemoteOrderSyncState(
          localId: localId,
          updatedAt: updatedAt,
          restaurantId: restaurantId,
        );
        _remoteLocalOrderIds.add(localId);
      }
      appLogger.d(
        '✅ [API PULL] Loaded ${_remoteState.length} mappings from ${file.path}',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '❌ [API PULL] Failed to load state from ${file.path}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveState() async {
    final file = _stateFile;
    if (file == null) {
      appLogger.w('⚠️ [API PULL] Cannot save state: _stateFile is null');
      return;
    }
    final payload = <String, dynamic>{
      'orders': <String, dynamic>{
        for (final entry in _remoteState.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    };
    try {
      await file.writeAsString(json.encode(payload));
      appLogger.d(
        '💾 [API PULL] State saved to ${file.path}: ${_remoteState.length} mappings',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '❌ [API PULL] Failed to save state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear le remoteState pour forcer la recréation des commandes.
  /// Si [preserveRecentWithin] est fourni, les commandes API locales récentes
  /// gardent leur mapping distant pour éviter une recréation inutile.
  Future<ApiOrderRemoteStateClearResult> clearRemoteState({
    Duration? preserveRecentWithin,
  }) async {
    await init();
    await DatabaseService.init();

    final preservedState = <int, _RemoteOrderSyncState>{};
    final preservedLocalIds = <int>{};
    final cutoff = preserveRecentWithin == null
        ? null
        : DateTime.now().subtract(preserveRecentWithin);

    var preservedEntriesCount = 0;
    var clearedEntriesCount = 0;
    var recreatedOrdersCount = 0;

    for (final entry in _remoteState.entries) {
      final localOrder = await DatabaseService.getPosOrderById(
        entry.value.localId,
      );
      final isLocalApiOrder =
          localOrder != null &&
          localOrder.channel.trim().toLowerCase() == 'api';

      var shouldPreserve = false;
      if (cutoff != null && isLocalApiOrder) {
        final latestActivity =
            localOrder.updatedAt.isAfter(localOrder.createdAt)
            ? localOrder.updatedAt
            : localOrder.createdAt;
        shouldPreserve = !latestActivity.isBefore(cutoff);
      }

      if (shouldPreserve) {
        preservedState[entry.key] = entry.value;
        preservedLocalIds.add(entry.value.localId);
        preservedEntriesCount += 1;
        continue;
      }

      clearedEntriesCount += 1;
      if (isLocalApiOrder) {
        recreatedOrdersCount += 1;
      }
    }

    _remoteState
      ..clear()
      ..addAll(preservedState);
    _remoteLocalOrderIds
      ..clear()
      ..addAll(preservedLocalIds);
    await _saveState();

    appLogger.d(
      '🗑️ Remote state cleared: cleared=$clearedEntriesCount preserved=$preservedEntriesCount recreated_risk=$recreatedOrdersCount',
    );
    return ApiOrderRemoteStateClearResult(
      clearedEntriesCount: clearedEntriesCount,
      preservedEntriesCount: preservedEntriesCount,
      recreatedOrdersCount: recreatedOrdersCount,
    );
  }
}

class _RemoteOrderSyncState {
  const _RemoteOrderSyncState({
    required this.localId,
    required this.updatedAt,
    required this.restaurantId,
  });

  final int localId;
  final String updatedAt;
  final int restaurantId;

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'updated_at': updatedAt,
    'restaurant_id': restaurantId,
  };
}

class _RemoteOrderItem {
  const _RemoteOrderItem({
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
  });

  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final int? groupNumber;
  final String? groupLabel;
  final String? itemNote;
  final String? serviceCourseKey;
  final String? serviceCourseLabel;
  final String? priceType;
  final double? glovoBasePrice;
}

class _UpsertRemoteOrderResult {
  const _UpsertRemoteOrderResult({
    required this.localId,
    required this.created,
  });

  final int localId;
  final bool created;
}

class ApiOrderSyncResult {
  const ApiOrderSyncResult({
    this.changedCount = 0,
    this.newOrdersCount = 0,
    this.updatedOrdersCount = 0,
    this.apiPendingOrdersCount = 0,
  });

  final int changedCount;
  final int newOrdersCount;
  final int updatedOrdersCount;
  final int
  apiPendingOrdersCount; // NEW: Count of API (mobile/web) orders with status pending
}

class ApiOrderRemoteStateClearResult {
  const ApiOrderRemoteStateClearResult({
    this.clearedEntriesCount = 0,
    this.preservedEntriesCount = 0,
    this.recreatedOrdersCount = 0,
  });

  final int clearedEntriesCount;
  final int preservedEntriesCount;
  final int recreatedOrdersCount;

  bool get willRecreateOrders => recreatedOrdersCount > 0;
}

class _OrderStatusEndpointAttempt {
  const _OrderStatusEndpointAttempt({
    required this.method,
    required this.path,
    required this.payload,
  });

  final String method;
  final String path;
  final Map<String, dynamic> payload;
}
