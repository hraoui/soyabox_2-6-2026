import 'package:http/http.dart' as http;

import '../models/daily_sync_models.dart';
import '../models/local_order_database_interface.dart';
import '../services/order_daily_sync_service.dart';
import '../utils/app_logger.dart';

// ============================================================
// 4️⃣ REPOSITORY AVEC RETRY ET LOGIQUE MÉTIER
// ============================================================

/// Repository pour gérer les commandes avec sync daily
///
/// Responsabilités:
/// - Orchestrer la synchronisation daily des commandes
/// - Implémenter la logique de retry exponentielle
/// - Convertir entre modèles locaux et API
/// - Gérer les flags de synchronisation
/// - Logger les opérations
class OrderDailySyncRepository {
  final OrderDailySyncService _syncService;
  final OrderLocalDatabase _localDb;

  /// Constructeur
  ///
  /// Parameters:
  /// - [syncService] : Service HTTP pour la communication
  /// - [localDb] : Interface à la base de données locale
  OrderDailySyncRepository({
    required OrderDailySyncService syncService,
    required OrderLocalDatabase localDb,
  }) : _syncService = syncService,
       _localDb = localDb;

  /// Synchroniser les commandes du jour en batch
  ///
  /// Processus:
  /// 1. Récupérer les commandes locales du jour
  /// 2. Construire le batch
  /// 3. Envoyer avec retry exponentiel
  /// 4. Mettre à jour les flags locaux
  /// 5. Logger les résultats
  ///
  /// Parameters:
  /// - [restaurantId] : ID du restaurant (obligatoire)
  /// - [staffId] : ID du staff (optionnel, pour filtrer)
  /// - [maxRetries] : Nombre de tentatives en cas d'échec (défaut: 3)
  ///
  /// Returns:
  /// - DailySyncResponse avec les statistiques
  ///
  /// Exemple:
  /// ```dart
  /// final response = await repository.syncTodaysOrders(
  ///   restaurantId: 1,
  ///   maxRetries: 3,
  /// );
  ///
  /// if (response.success && response.data != null) {
  ///   print('Inserted: ${response.data!.inserted}');
  /// }
  /// ```
  Future<DailySyncResponse> syncTodaysOrders({
    required int restaurantId,
    int? staffId,
    int maxRetries = 3,
  }) async {
    try {
      appLogger.d('🔄 [DailySync] Starting sync for restaurant: $restaurantId');

      // 1. Récupérer les commandes locales du jour
      final todayOrders = await _getTodayOrdersFromLocal(restaurantId, staffId);

      if (todayOrders.isEmpty) {
        appLogger.d('[DailySync] ℹ️ No orders to sync for today');
        return DailySyncResponse(
          success: true,
          message: 'No orders to sync',
          statusCode: 200,
        );
      }

      appLogger.d('[DailySync] 📊 Found ${todayOrders.length} orders to sync');

      // 2. Construire le batch
      final batch = _buildOrderBatch(todayOrders);

      // 3. Envoyer avec retry exponentiel
      DailySyncResponse response = DailySyncResponse.error(
        message: 'Not started',
        statusCode: 0,
      );
      int attempt = 0;

      do {
        attempt++;
        appLogger.d('[DailySync] 🔁 Attempt $attempt/$maxRetries');

        response = await _syncService.syncDailyOrders(batch);

        if (response.success) {
          appLogger.i('[DailySync] ✅ Sync successful on attempt $attempt');
          break;
        }

        if (attempt < maxRetries) {
          final delaySeconds = (attempt * 5);
          appLogger.w(
            '[DailySync] ⚠️ Attempt $attempt failed, retrying in ${delaySeconds}s...',
          );
          appLogger.w('[DailySync] Error: ${response.message}');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          appLogger.e('[DailySync] ❌ Max retries ($maxRetries) reached');
        }
      } while (attempt < maxRetries);

      // 4. Mettre à jour les flags locaux
      if (response.success && response.data != null) {
        final stats = response.data!;

        // Marquer comme synced
        await _markOrdersAsDailySynced(
          todayOrders.map((o) => o.localId).toList(),
        );

        appLogger.i(
          '[DailySync] 📈 Completed: '
          'Total: ${stats.total}, '
          'Inserted: ${stats.inserted}, '
          'Skipped: ${stats.skipped}, '
          'Failed: ${stats.failed}',
        );

        // Logger les erreurs détaillées
        if (stats.errors != null && stats.errors!.isNotEmpty) {
          appLogger.w('[DailySync] ⚠️ Sync errors encountered:');
          for (final error in stats.errors!) {
            appLogger.w('[DailySync] - $error');
          }
        }
      } else {
        appLogger.e('[DailySync] ❌ Sync failed: ${response.message}');
      }

      return response;
    } catch (e, stackTrace) {
      appLogger.e(
        '[DailySync] 🔥 Unexpected error during sync',
        error: e,
        stackTrace: stackTrace,
      );
      return DailySyncResponse.error(
        message: 'Unexpected error: $e',
        statusCode: 0,
      );
    }
  }

  /// Récupérer les commandes du jour depuis SQLite/Hive/Drift
  ///
  /// Returns: Liste des commandes à synchroniser
  Future<List<LocalOrder>> _getTodayOrdersFromLocal(
    int restaurantId,
    int? staffId,
  ) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _localDb.getOrdersByDateRange(
      restaurantId: restaurantId,
      staffId: staffId,
      startDate: startOfDay,
      endDate: endOfDay,
      excludeDeleted: true,
      excludeAlreadySynced: false, // Inclure tous pour le batch
    );
  }

  /// Construire le batch de commandes
  ///
  /// Convertit les commandes locales en format API
  DailyOrderBatch _buildOrderBatch(List<LocalOrder> orders) {
    return DailyOrderBatch(
      orders: orders
          .map((order) => _convertToOrderForDailySync(order))
          .toList(),
    );
  }

  /// Convertir Order local en OrderForDailySync
  ///
  /// Parameters:
  /// - [order] : Commande locale
  ///
  /// Returns:
  /// - Commande au format API
  OrderForDailySync _convertToOrderForDailySync(LocalOrder order) {
    return OrderForDailySync(
      localId: order.localId.toString(),
      staffId: order.staffId,
      restaurantId: order.restaurantId,
      channel: order.channel,
      fulfillmentType: order.fulfillmentType,
      status: order.status,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      totalPrice: order.totalPrice,
      originalTotal: order.originalTotal,
      discountAmount: order.discountAmount ?? 0.0,
      hasDiscount: order.hasDiscount ?? false,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      tableNumber: order.tableNumber,
      note: order.note,
      rewardId: order.rewardId,
      cancelReason: order.cancelReason,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items
          .map(
            (item) => OrderItemForDailySync(
              localId: item.localId.toString(),
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
    );
  }

  /// Marquer les commandes comme daily-synced
  ///
  /// Ajoute un flag local: isDailySynced = true
  /// NE PAS supprimer les commandes
  ///
  /// Parameters:
  /// - [localIds] : Liste des IDs locales
  Future<void> _markOrdersAsDailySynced(List<String> localIds) async {
    if (localIds.isEmpty) return;

    try {
      await _localDb.updateOrdersSyncFlag(
        localIds: localIds,
        isDailySynced: true,
      );
      appLogger.d('[DailySync] 💾 Marked ${localIds.length} orders as synced');
    } catch (e) {
      appLogger.e('[DailySync] Error marking orders as synced: $e');
      rethrow;
    }
  }

  /// Récupérer le rapport daily
  ///
  /// Parameters:
  /// - [restaurantId] : ID du restaurant
  /// - [date] : Date du rapport (optionnel, défaut: aujourd'hui)
  ///
  /// Returns:
  /// - DailyReportResponse avec les données
  Future<DailyReportResponse> getDailyReport({
    required int restaurantId,
    DateTime? date,
  }) async {
    try {
      appLogger.d(
        '[DailyReport] Fetching report for restaurant: $restaurantId',
      );
      return _syncService.getDailyReport(
        restaurantId: restaurantId,
        date: date,
      );
    } catch (e) {
      appLogger.e('[DailyReport] Error fetching report: $e');
      return DailyReportResponse.error(
        message: 'Failed to fetch daily report: $e',
        statusCode: 0,
      );
    }
  }

  /// Factory statique pour créer une instance
  ///
  /// Utilité: faciliter l'injection de dépendances
  ///
  /// Exemple:
  /// ```dart
  /// final repo = OrderDailySyncRepository.create(
  ///   baseUrl: 'http://localhost:8000',
  ///   authToken: 'your_token',
  ///   localDb: myDatabaseImplementation,
  /// );
  /// ```
  static OrderDailySyncRepository create({
    required String baseUrl,
    required String? authToken,
    required OrderLocalDatabase localDb,
  }) {
    final httpClient = http.Client();
    final syncService = OrderDailySyncService(
      httpClient: httpClient,
      baseUrl: baseUrl,
      authToken: authToken,
    );
    return OrderDailySyncRepository(syncService: syncService, localDb: localDb);
  }

  /// Update the auth token (e.g., after login)
  ///
  /// This is needed when the user logs in and we get a fresh token
  void updateAuthToken(String? authToken) {
    _syncService.updateAuthToken(authToken);
    appLogger.d('[DailySync] 🔑 Auth token updated in sync service');
  }
}
