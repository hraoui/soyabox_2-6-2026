import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../api/api_client.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../data/app_constants.dart';
import '../models/daily_sync_models.dart';
import '../repos/order_daily_sync_repo.dart';
import '../services/api_import_service.dart';
import '../services/api_order_pull_service.dart';
import '../services/auth_session_service.dart';
import '../services/database_service.dart';
import '../services/isar_order_local_database.dart';
import '../services/notification_sound_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/app_logger.dart';

class SyncController extends GetxController {
  // ✅ Sync every 60 seconds (was 30s)
  static const Duration _autoSyncInterval = Duration(seconds: 60);
  static const Duration _queueRescanInterval = Duration(minutes: 1);
  static const Duration _onlineCheckTimeout = Duration(seconds: 5);
  static const Duration _onlineCheckCacheTtl = Duration(seconds: 10);

  // 📅 Daily batch sync interval (every 5 minutes)
  static const Duration _dailyBatchInterval = Duration(minutes: 5);
  Timer? _dailyBatchTimer;

  final RxBool _isOnline = false.obs;
  final RxBool _isSyncing = false.obs;
  final Rxn<DateTime> _lastSyncAt = Rxn<DateTime>();
  final Rx<_NetworkStatus> _networkStatus = _NetworkStatus.offline.obs;

  bool get isOnline => _isOnline.value;
  bool get isSyncing => _isSyncing.value;
  DateTime? get lastSyncAt => _lastSyncAt.value;
  bool get canManualSync => _isAdminUser;
  bool get isPartiallyOnline => _networkStatus.value == _NetworkStatus.partial;
  Timer? _timer;
  bool _wasOnline = false;
  DateTime? _lastQueueRescanAt;
  DateTime? _lastOnlineCheckAt;
  bool? _lastOnlineCheckResult;

  // Don't auto-start sync on init - wait for user to login first
  // Sync will be started when user logs in via startSyncAfterLogin()

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  bool get _isAdminUser {
    if (!Get.isRegistered<AuthController>()) return false;
    final role = Get.find<AuthController>().currentRole;
    return role == 'admin' || role == 'superadmin';
  }

  /// Start sync only after user has logged in
  void startSyncAfterLogin() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoSyncInterval, (_) async {
      await _tick();
    });
    unawaited(_tick());
  }

  /// Start background sync that runs even without auth
  /// This syncs BOTH incoming API orders AND outgoing local orders/users
  void startBackgroundSync() {
    print(
      '🔄 [SYNC] Starting background sync (full sync, no auth required)...',
    );

    // Cancel existing timer if any
    _timer?.cancel();

    // Start periodic background sync
    _timer = Timer.periodic(_autoSyncInterval, (_) async {
      await _backgroundSyncTick();
    });

    // 📅 Start daily batch sync every 5 minutes
    _startDailyBatchSync();

    // Run immediately on startup
    unawaited(_backgroundSyncTick());

    print(
      '✅ [DEP] Background sync started with ${_autoSyncInterval.inSeconds}s interval',
    );
  }

  Future<void> _backgroundSyncTick() async {
    try {
      print('🔄 [SYNC] Background sync tick starting...');

      // ✅ Step 1: Sync LOCAL → BACKEND (orders and users)
      // This works even without auth if token is available
      await _syncLocalToBackend();

      // ✅ Step 2: Pull users from BACKEND → LOCAL (bidirectional sync)
      await _pullUsersFromBackend();

      // ✅ Step 3: Check for API orders (BACKEND → LOCAL)
      final pullResult = await _pullIncomingApiOrders();

      // ✅ Play notification if API pending orders found
      if (pullResult.apiPendingOrdersCount > 0) {
        print(
          '🔔 [SYNC] API pending orders detected: ${pullResult.apiPendingOrdersCount}',
        );
        try {
          await NotificationSoundService.instance.playNewOrderAlarm();
          await Future.delayed(const Duration(milliseconds: 800));
          await NotificationSoundService.instance.playNewOrderAlarm();
          print('✅ [SYNC] Notification sound played successfully');
        } catch (e, stackTrace) {
          print('❌ [SYNC] Failed to play notification: $e');
          appLogger.e(
            'Failed to play notification',
            error: e,
            stackTrace: stackTrace,
          );
        }
      } else {
        print(
          '🔇 [SYNC] No API pending orders (api_pending=${pullResult.apiPendingOrdersCount})',
        );
      }

      print('✅ [SYNC] Background sync tick completed');
    } catch (e, stackTrace) {
      print('❌ [SYNC] Background sync failed: $e');
      appLogger.e('Background sync failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Sync local data (orders, users) to backend
  /// Works even without authentication if token is available
  Future<void> _syncLocalToBackend() async {
    try {
      print('🔄 [SYNC] Starting local→backend sync...');

      // ✅ Get token from session
      final session = AuthSessionService.instance;
      String token = session.token;

      // If session token is empty, try fallback
      if (token.isEmpty) {
        token = session.tokenOrFallback;
        if (token.isNotEmpty) {
          print('⚠️ [SYNC] Session token empty, using fallback');
        }
      }

      if (token.isEmpty) {
        print(
          '⚠️ [SYNC] No token available (session + fallback), skipping local→backend sync',
        );
        print('   → Session token: ${session.token.isEmpty ? "EMPTY" : "OK"}');
        print('   → User must login for sync to work');
        return;
      }

      print(
        '🔑 [SYNC] Using token: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
      );

      // ✅ Update token in services BEFORE syncing
      SyncQueueService.instance.updateAuthToken(token);
      ApiOrderPullService.instance.updateAuthToken(token);
      print('✅ [SYNC] Token updated in sync services');

      // ✅ Queue unsynced orders
      print('📦 [SYNC] Queuing unsynced orders...');
      await SyncQueueService.instance.queueUnsyncedOrders();
      print('✅ [SYNC] Queued unsynced orders');

      // ✅ Queue unsynced users
      print('👥 [SYNC] Queuing unsynced users...');
      await SyncQueueService.instance.queueUnsyncedUsers();
      print('✅ [SYNC] Queued unsynced users');

      // ✅ Flush queue to backend
      print('📤 [SYNC] Flushing queue to backend...');
      await SyncQueueService.instance.flushQueue();
      print('✅ [SYNC] Flushed queue to backend');

      print('✅ [SYNC] Local→backend sync completed successfully');
    } catch (e, stackTrace) {
      print('❌ [SYNC] Local→backend sync failed: $e');
      appLogger.e(
        'Local→backend sync failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stop sync timer (e.g., on logout)
  void stopSync() {
    _timer?.cancel();
    _timer = null;
    _dailyBatchTimer?.cancel();
    _dailyBatchTimer = null;
    _isOnline.value = false;
    _isSyncing.value = false;
    _lastSyncAt.value = null;
  }

  /// 📅 Start automatic daily batch sync every 5 minutes
  void _startDailyBatchSync() {
    _dailyBatchTimer?.cancel();

    _dailyBatchTimer = Timer.periodic(_dailyBatchInterval, (_) async {
      await _performDailyBatchSync();
    });

    // Run immediately on first startup
    unawaited(_performDailyBatchSync());

    appLogger.i(
      '📅 [DAILY SYNC] Auto-sync started with ${_dailyBatchInterval.inMinutes}min interval',
    );
  }

  /// Perform daily batch sync automatically
  Future<void> _performDailyBatchSync() async {
    try {
      appLogger.d('📅 [DAILY SYNC] Automatic sync triggered...');

      // Only sync if we have a token
      final session = AuthSessionService.instance;
      String token = session.token;
      if (token.isEmpty) {
        token = session.tokenOrFallback;
      }

      if (token.isEmpty) {
        appLogger.d('⏭️ [DAILY SYNC] No token, skipping automatic sync');
        return;
      }

      // Trigger the daily batch sync
      await triggerDailyBatchSync(showNotifications: false);

      appLogger.i('✅ [DAILY SYNC] Automatic sync completed');
    } catch (e, stackTrace) {
      appLogger.e(
        '❌ [DAILY SYNC] Automatic sync failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> syncNow({bool showSuccess = false}) async {
    final online = await _checkOnline(forceRefresh: true);
    _isOnline.value = online;
    if (!online) return;

    final token = await _resolveAndApplySessionToken();
    if (token.isEmpty) {
      // ✅ Don't show snackbar - user might be logged in via PIN
      // Just skip sync silently
      return;
    }

    await _syncInternal(
      showSuccess: showSuccess && _isAdminUser,
      forceQueueRescan: true,
    );
  }

  Future<void> _tick() async {
    final online = await _checkOnline();
    _isOnline.value = online;

    if (!online) {
      _wasOnline = false;
      return;
    }

    final token = await _resolveAndApplySessionToken();
    if (token.isEmpty) return;

    if (!_wasOnline && _isAdminUser) {
      Get.snackbar(
        'Connexion détectée',
        'Synchronisation automatique en cours',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    _wasOnline = true;

    await _syncInternal();
  }

  Future<void> manualSync() async {
    if (!_isAdminUser) return;
    if (!isOnline) {
      Get.snackbar(
        'Hors ligne',
        'Connexion internet indisponible',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _syncInternal(showSuccess: true, forceQueueRescan: true);
  }

  Future<String> _resolveAndApplySessionToken() async {
    final session = AuthSessionService.instance;
    final token = await session.refreshTokenIfNeeded(
      refreshWithPin: _refreshPinSessionToken,
      refreshWithCredentials: _refreshCredentialSessionToken,
    );
    final auth = Get.find<AuthController>();
    final pinSessionActive = _hasActivePinSession(session);
    if (auth.currentUser == null && !pinSessionActive) {
      return '';
    }
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      if (pinSessionActive) {
        appLogger.w(
          'PIN session active but sync remains disabled: missing valid token',
          context: {'sessionEmail': session.email},
        );
      }
      return '';
    }

    SyncQueueService.instance.updateAuthToken(normalizedToken);
    ApiOrderPullService.instance.updateAuthToken(normalizedToken);
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().updateHeaders(normalizedToken);
    }
    return normalizedToken;
  }

  bool _hasActivePinSession(AuthSessionService session) {
    if (!session.isPinSession || !Get.isRegistered<PosController>()) {
      return false;
    }
    final pos = Get.find<PosController>();
    final activeStaff = pos.activeStaff;
    if (activeStaff == null) return false;
    final sessionEmail = session.email.trim().toLowerCase();
    final staffEmail = activeStaff.email.trim().toLowerCase();
    return sessionEmail.isEmpty || sessionEmail == staffEmail;
  }

  Future<String?> _refreshPinSessionToken(String pin) async {
    if (pin.trim().isEmpty || !Get.isRegistered<ApiClient>()) {
      return null;
    }
    try {
      final response = await Get.find<ApiClient>().postData('/api/login-pin', {
        'pin_code': pin,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      final token = AuthController.extractAuthTokenFromApiBody(response.body);
      return token.trim().isEmpty ? null : token.trim();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _refreshCredentialSessionToken(
    String identifier,
    String secret,
  ) async {
    final normalizedPhone = await _resolvePhoneForCredentialLogin(identifier);
    if (normalizedPhone == null ||
        normalizedPhone.isEmpty ||
        !Get.isRegistered<ApiClient>()) {
      return null;
    }
    try {
      final response = await Get.find<ApiClient>().postData('/api/login', {
        'phone': normalizedPhone,
        'password': secret,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      final token = AuthController.extractAuthTokenFromApiBody(response.body);
      return token.trim().isEmpty ? null : token.trim();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolvePhoneForCredentialLogin(String identifier) async {
    final directPhone = _normalizePhoneIdentifier(identifier);
    if (directPhone != null) {
      return directPhone;
    }
    await DatabaseService.init();
    final localUser = await DatabaseService.getUserByEmail(
      identifier.trim().toLowerCase(),
    );
    return _normalizePhoneIdentifier(localUser?.phone ?? '');
  }

  String? _normalizePhoneIdentifier(String rawValue) {
    final normalized = rawValue.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _syncInternal({
    bool showSuccess = false,
    bool forceQueueRescan = false,
  }) async {
    // CRITICAL: Don't sync if no user is logged in
    if (!Get.isRegistered<AuthController>() ||
        Get.find<AuthController>().currentUser == null) {
      appLogger.w('⚠️ [SYNC] Skipped: No user logged in');
      return;
    }

    if (_isSyncing.value) return;
    _isSyncing.value = true;
    try {
      final now = DateTime.now();
      final shouldRescanQueue =
          forceQueueRescan ||
          _lastQueueRescanAt == null ||
          now.difference(_lastQueueRescanAt!) >= _queueRescanInterval;
      if (shouldRescanQueue) {
        final auth = Get.find<AuthController>();
        final currentUser = auth.currentUser;
        final role = auth.currentRole?.toLowerCase();
        final onlyStaffId = role == 'staff' ? currentUser?.id : null;
        await SyncQueueService.instance.queueUnsyncedOrders(
          onlyStaffId: onlyStaffId,
        );
        await SyncQueueService.instance
            .queueUnsyncedUsers(); // ✅ Sync users to backend
        _lastQueueRescanAt = now;
      }
      await SyncQueueService.instance.flushQueue();
      final pullResult = await _pullIncomingApiOrders();
      appLogger.d(
        '📥 API Order Pull Result: new=${pullResult.newOrdersCount}, updated=${pullResult.updatedOrdersCount}, changed=${pullResult.changedCount}, api_pending=${pullResult.apiPendingOrdersCount}',
      );

      // ✅ Play notification for ALL API (mobile/web) orders with status pending
      // ✅ Play even without auth (POS closed, waiting for orders)
      // ✅ Play TWICE to distinguish from local POS orders
      if (pullResult.apiPendingOrdersCount > 0) {
        appLogger.d(
          '🔔 API pending orders detected (${pullResult.apiPendingOrdersCount}), playing notification TWICE...',
        );
        // Play twice with a short interval
        try {
          await NotificationSoundService.instance.playNewOrderAlarm();
          await Future.delayed(const Duration(milliseconds: 800));
          await NotificationSoundService.instance.playNewOrderAlarm();
          appLogger.d('✅ Notification sound played successfully');
        } catch (e, stackTrace) {
          appLogger.e(
            '❌ Failed to play notification sound',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      if (pullResult.changedCount > 0 && Get.isRegistered<PosController>()) {
        await Get.find<PosController>().loadOrdersToday();
      }
      _lastSyncAt.value = DateTime.now();
      if (showSuccess) {
        Get.snackbar(
          'Succès',
          pullResult.newOrdersCount > 0
              ? 'Sync OK: +${pullResult.newOrdersCount} cmd API'
              : 'Synchronisation terminée',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stackTrace) {
      appLogger.e('Sync error', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Erreur sync',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<ApiOrderSyncResult> _pullIncomingApiOrders() async {
    final restaurantId = _resolveRestaurantId();
    if (restaurantId == null || restaurantId <= 0) {
      appLogger.w('⚠️ [API PULL] No restaurant ID, skipping API order pull');
      return const ApiOrderSyncResult();
    }

    // ✅ Get the CORRECT token for authenticated API endpoints
    // Priority: 1) Valid session token (not PIN) 2) Refresh PIN for valid token 3) Fallback
    String token = '';
    String tokenSource = 'none';

    final session = AuthSessionService.instance;

    // 1. Try session token first (if it's not a PIN token)
    if (session.token.isNotEmpty && !session.token.startsWith('local_pin_')) {
      token = session.token;
      tokenSource = 'session_token (valid)';
    }

    // 2. If we have a PIN session, try to refresh credentials to get a valid token
    if (token.isEmpty && session.isPinSession) {
      appLogger.i(
        '🔐 [API PULL] PIN session active, attempting credential refresh for API auth...',
      );
      final pin = session.credentialSecret;
      if (pin.isNotEmpty) {
        final refreshedToken = await _refreshPinSessionToken(pin);
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          token = refreshedToken;
          tokenSource = 'refreshed_pin_token';
          appLogger.i('✅ [API PULL] Got refreshed token from PIN session');
        }
      }
    }

    // 3. Last resort: use fallback (may not work but log it)
    if (token.isEmpty) {
      token = session.tokenOrFallback;
      if (token.isNotEmpty) {
        tokenSource = 'fallback_token';
        if (token.startsWith('local_pin_')) {
          appLogger.w(
            '⚠️ [API PULL] Using PIN token for API endpoints - will likely fail with HTTP 401. '
            'PIN sessions need proper credentials for API access.',
          );
        }
      }
    }

    if (token.isNotEmpty) {
      ApiOrderPullService.instance.updateAuthToken(token);
    }

    final fallbackStaffId = _resolveFallbackStaffId();

    appLogger.d(
      '📡 [API PULL] Pulling API orders for restaurant ID: $restaurantId',
    );
    appLogger.d(
      '📡 [API PULL] Auth token source=$tokenSource, present=${token.isNotEmpty}, '
      'fallbackStaffId=${fallbackStaffId ?? 'none'}',
    );

    final result = await ApiOrderPullService.instance
        .syncApiOrdersForRestaurant(
          restaurantId: restaurantId,
          fallbackStaffId: fallbackStaffId,
        );

    appLogger.d(
      '✅ [API PULL] Completed: '
      '${result.apiPendingOrdersCount} pending, '
      '${result.newOrdersCount} new, '
      '${result.updatedOrdersCount} updated, '
      '${result.changedCount} total changes',
    );

    return result;
  }

  /// Pull users from backend → local (bidirectional sync)
  Future<void> _pullUsersFromBackend() async {
    try {
      final restaurantId = _resolveRestaurantId();
      if (restaurantId == null || restaurantId <= 0) {
        print('⚠️ [SYNC] No restaurant ID, skipping user pull');
        return;
      }

      print(
        '👥 [SYNC] Pulling users from backend (restaurant_id=$restaurantId)...',
      );
      final importService = ApiImportService(baseUrl: AppConstant.baseUrl);

      // Use the session token if available
      final session = AuthSessionService.instance;
      if (session.token.isNotEmpty) {
        importService.updateAuthToken(session.token);
      }

      final success = await importService.importUsers(
        restaurantId: restaurantId,
      );
      if (success) {
        print('✅ [SYNC] User pull completed successfully');
      } else {
        print('⚠️ [SYNC] User pull completed with issues');
      }
    } catch (e) {
      print('❌ [SYNC] Error pulling users from backend: $e');
    }
  }

  int? _resolveRestaurantId() {
    // 1. Try from PosController (if staff logged in with restaurant context)
    if (Get.isRegistered<PosController>()) {
      final pos = Get.find<PosController>();
      final posRestaurantId = pos.restaurantId;
      final posStaffId = pos.activeStaffId;
      if (posRestaurantId != null &&
          posRestaurantId > 0 &&
          posStaffId != null) {
        return posRestaurantId;
      }
    }

    // 2. Try from AuthController (if user logged in)
    final authRestaurantId =
        Get.find<AuthController>().currentUser?.restaurantId;
    if (authRestaurantId != null && authRestaurantId > 0) {
      return authRestaurantId;
    }

    // ✅ 3. FALLBACK: Use imported restaurant from RestaurantController
    // This allows API order sync BEFORE user login (e.g., staff connecting with PIN)
    if (Get.isRegistered<RestaurantController>()) {
      final importedRestaurantId = Get.find<RestaurantController>()
          .getImportedRestaurantId();
      if (importedRestaurantId != null && importedRestaurantId > 0) {
        appLogger.d(
          '🍽️ [SYNC] Using imported restaurant ID: $importedRestaurantId',
        );
        return importedRestaurantId;
      }
    }

    appLogger.w('⚠️ [SYNC] No restaurant ID resolved from any source');
    return null;
  }

  int? _resolveFallbackStaffId() {
    if (Get.isRegistered<PosController>()) {
      final activeStaffId = Get.find<PosController>().activeStaffId;
      if (activeStaffId != null && activeStaffId > 0) {
        return activeStaffId;
      }
    }

    final authUserId = Get.find<AuthController>().currentUser?.id;
    if (authUserId != null && authUserId > 0) {
      return authUserId;
    }

    return null;
  }

  /// Clear le remote state API pour forcer la recréation des commandes
  Future<void> clearApiOrderRemoteState() async {
    await DatabaseService.init();
    final localApiOrders = await DatabaseService.getPosOrdersByChannel('api');
    final result = await ApiOrderPullService.instance.clearRemoteState(
      preserveRecentWithin: const Duration(hours: 24),
    );

    final title = result.willRecreateOrders ? 'Attention' : 'State reset';
    final message = localApiOrders.isEmpty
        ? 'Aucune commande API locale détectée. State reset effectué.'
        : result.willRecreateOrders
        ? '${result.recreatedOrdersCount} commandes API locales anciennes pourront etre recreees au prochain sync. '
              '${result.preservedEntriesCount} commandes recentes ont ete preservees.'
        : result.preservedEntriesCount > 0
        ? '${result.preservedEntriesCount} commandes API recentes ont ete preservees.'
        : 'Les commandes API locales n ont pas de risque immediat de recreation.';

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: result.willRecreateOrders ? 4 : 3),
    );
  }

  Future<bool> _checkOnline({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final lastCheckAt = _lastOnlineCheckAt;
    if (!forceRefresh &&
        lastCheckAt != null &&
        now.difference(lastCheckAt) < _onlineCheckCacheTtl &&
        _lastOnlineCheckResult != null) {
      return _lastOnlineCheckResult!;
    }

    final hosts = _connectivityHosts();
    final checks = await Future.wait(
      hosts.map((host) async => MapEntry(host, await _lookupHost(host))),
    );

    final successfulHosts = checks
        .where((entry) => entry.value)
        .map((e) => e.key)
        .toList();
    final failedHosts = checks
        .where((entry) => !entry.value)
        .map((e) => e.key)
        .toList();

    final online = successfulHosts.isNotEmpty;
    if (!online) {
      _networkStatus.value = _NetworkStatus.offline;
    } else if (failedHosts.isEmpty) {
      _networkStatus.value = _NetworkStatus.online;
    } else {
      _networkStatus.value = _NetworkStatus.partial;
      appLogger.d(
        '⚠️ Partial connectivity: ok=${successfulHosts.join(",")} failed=${failedHosts.join(",")}',
      );
    }

    _lastOnlineCheckAt = now;
    _lastOnlineCheckResult = online;
    return online;
  }

  List<String> _connectivityHosts() {
    final baseHost = Uri.parse(AppConstant.baseUrl).host.trim();
    final hosts = <String>[
      if (baseHost.isNotEmpty) baseHost,
      'google.com',
      'cloudflare.com',
    ];
    return hosts.toSet().toList(growable: false);
  }

  Future<bool> _lookupHost(String host) async {
    try {
      final result = await InternetAddress.lookup(
        host,
      ).timeout(_onlineCheckTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DAILY BATCH SYNC METHODS
  // ============================================================

  /// Trigger daily batch sync for today's orders
  ///
  /// This syncs all local orders from today to the backend in a single batch
  /// Returns the sync response or null if failed
  Future<DailySyncResponse?> triggerDailyBatchSync({
    bool showNotifications = true,
  }) async {
    try {
      appLogger.i('📅 [DAILY SYNC] Starting daily batch sync...');

      // Get or create the repository
      OrderDailySyncRepository dailySyncRepo;

      if (Get.isRegistered<OrderDailySyncRepository>()) {
        dailySyncRepo = Get.find<OrderDailySyncRepository>();
      } else {
        // Create it on-demand
        appLogger.w(
          '⚠️ [DAILY SYNC] Repository not registered, creating on-demand...',
        );
        final localDb = Get.isRegistered<IsarOrderLocalDatabase>()
            ? Get.find<IsarOrderLocalDatabase>()
            : IsarOrderLocalDatabase();

        dailySyncRepo = OrderDailySyncRepository.create(
          baseUrl: AppConstant.baseUrl,
          authToken: null, // Will be updated below
          localDb: localDb,
        );
      }

      // Update auth token before syncing
      final session = AuthSessionService.instance;
      String token = session.token;
      if (token.isEmpty) {
        token = session.tokenOrFallback;
      }

      if (token.isEmpty) {
        appLogger.w('⚠️ [DAILY SYNC] No auth token available');
        if (showNotifications) {
          Get.snackbar(
            'Authentification Requise',
            'Veuillez vous connecter pour synchroniser',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return null;
      }

      // Update token in daily sync service
      dailySyncRepo.updateAuthToken(token);

      // Get restaurant ID
      final restaurantId = _resolveRestaurantId();
      if (restaurantId == null || restaurantId <= 0) {
        appLogger.w('⚠️ [DAILY SYNC] No restaurant ID resolved');
        if (showNotifications) {
          Get.snackbar(
            'Configuration Requise',
            'Restaurant non configuré pour la synchronisation',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return null;
      }

      // Get staff ID (optional)
      int? staffId;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final role = auth.currentRole?.trim().toLowerCase() ?? '';
        if (role == 'staff') {
          staffId = auth.currentUser?.id;
        }
      }

      appLogger.d(
        '[DAILY SYNC] Syncing orders for restaurant $restaurantId...',
      );

      // Perform the sync
      final response = await dailySyncRepo.syncTodaysOrders(
        restaurantId: restaurantId,
        staffId: staffId,
        maxRetries: 3,
      );

      // Handle response
      if (response.success && response.data != null) {
        final stats = response.data!;
        appLogger.i(
          '✅ [DAILY SYNC] Successful: '
          'Inserted=${stats.inserted}, '
          'Skipped=${stats.skipped}, '
          'Failed=${stats.failed}',
        );

        if (showNotifications) {
          Get.snackbar(
            'Synchronisation Réussie ✅',
            '${stats.inserted} commandes envoyées, ${stats.skipped} ignorées, ${stats.failed} échouées',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }

        // Reload orders in POS if registered
        if (Get.isRegistered<PosController>()) {
          await Get.find<PosController>().loadOrdersToday();
        }
      } else {
        appLogger.e('❌ [DAILY SYNC] Failed: ${response.message}');
        if (showNotifications) {
          Get.snackbar(
            'Échec de Synchronisation ❌',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      appLogger.e(
        '🔥 [DAILY SYNC] Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      if (showNotifications) {
        Get.snackbar(
          'Erreur de Synchronisation 🔥',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return null;
    }
  }

  /// Fetch and display the daily report
  Future<DailyReportResponse?> fetchDailyReport({DateTime? date}) async {
    try {
      if (!Get.isRegistered<OrderDailySyncRepository>()) {
        appLogger.w('⚠️ [DAILY REPORT] Repository not registered');
        return null;
      }

      final restaurantId = _resolveRestaurantId();
      if (restaurantId == null || restaurantId <= 0) {
        appLogger.w('⚠️ [DAILY REPORT] No restaurant ID');
        return null;
      }

      final dailySyncRepo = Get.find<OrderDailySyncRepository>();

      // Update auth token
      final session = AuthSessionService.instance;
      String token = session.token;
      if (token.isEmpty) {
        token = session.tokenOrFallback;
      }
      if (token.isNotEmpty) {
        dailySyncRepo.updateAuthToken(token);
      }

      appLogger.d(
        '[DAILY REPORT] Fetching report for restaurant $restaurantId',
      );

      final response = await dailySyncRepo.getDailyReport(
        restaurantId: restaurantId,
        date: date,
      );

      if (response.success && response.data != null) {
        final report = response.data!;
        appLogger.i(
          '✅ [DAILY REPORT] Fetched: '
          'Date=${report.date}, '
          'Orders=${report.totalOrders}, '
          'Revenue=${report.totalRevenue}',
        );
      } else {
        appLogger.e('❌ [DAILY REPORT] Failed: ${response.message}');
      }

      return response;
    } catch (e, stackTrace) {
      appLogger.e('🔥 [DAILY REPORT] Error', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}

enum _NetworkStatus { offline, partial, online }
