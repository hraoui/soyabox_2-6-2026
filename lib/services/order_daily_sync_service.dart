import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/daily_sync_models.dart';
import '../utils/app_logger.dart';

// ============================================================
// 3️⃣ SERVICE HTTP POUR LA SYNCHRONISATION DAILY
// ============================================================

/// Service pour la synchronisation daily des commandes
///
/// Responsabilités:
/// - Envoyer les batches quotidiens des commandes
/// - Récupérer les rapports daily
/// - Gérer les erreurs HTTP
/// - Formatter les requêtes/réponses
class OrderDailySyncService {
  final http.Client _httpClient;
  final String _baseUrl;
  String? _authToken;

  /// Constructeur
  ///
  /// Parameters:
  /// - [httpClient] : Client HTTP (injecté pour testabilité)
  /// - [baseUrl] : URL de base du backend (ex: http://localhost:8000)
  /// - [authToken] : Token Bearer pour l'authentification
  OrderDailySyncService({
    required http.Client httpClient,
    required String baseUrl,
    String? authToken,
  }) : _httpClient = httpClient,
       _baseUrl = baseUrl,
       _authToken = authToken;

  /// Update the auth token (e.g., after user login)
  void updateAuthToken(String? newToken) {
    _authToken = newToken;
    appLogger.d('[DailySync] 🔑 Auth token updated');
  }

  /// Envoyer le batch daily des commandes du jour
  ///
  /// POST /api/orders/daily-sync
  ///
  /// Parameters:
  /// - [batch] : Batch de commandes à synchroniser
  ///
  /// Returns:
  /// - DailySyncResponse avec les statistiques
  ///
  /// Throws:
  /// - Retourne une erreur dans la réponse en cas d'échec
  Future<DailySyncResponse> syncDailyOrders(DailyOrderBatch batch) async {
    try {
      appLogger.d(
        '📤 [DailySync] Sending ${batch.orders.length} orders batch...',
      );

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final requestBody = jsonEncode(batch.toJson());

      appLogger.d(
        '📤 [DailySync] Request body size: ${requestBody.length} bytes',
      );

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/api/orders/daily-sync'),
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 60));

      appLogger.d('📥 [DailySync] Response received: ${response.statusCode}');

      return DailySyncResponse.fromResponse(response);
    } catch (e) {
      appLogger.e('🔥 [DailySync] Error sending orders: $e');
      return DailySyncResponse.error(
        message: 'Failed to sync daily orders: $e',
        statusCode: 0,
      );
    }
  }

  /// Récupérer le rapport daily
  ///
  /// GET /api/orders/daily-report?restaurant_id=X&date=YYYY-MM-DD
  ///
  /// Parameters:
  /// - [restaurantId] : ID du restaurant
  /// - [date] : Date pour le rapport (optionnel, défaut: aujourd'hui)
  ///
  /// Returns:
  /// - DailyReportResponse avec les données du rapport
  Future<DailyReportResponse> getDailyReport({
    required int restaurantId,
    DateTime? date,
  }) async {
    try {
      final queryParams = {
        'restaurant_id': restaurantId.toString(),
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      };

      final uri = Uri.parse(
        '$_baseUrl/api/orders/daily-report',
      ).replace(queryParameters: queryParams);

      appLogger.d(
        '📥 [DailyReport] Fetching report for restaurant: $restaurantId',
      );

      final headers = {
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      appLogger.d('📥 [DailyReport] Response received: ${response.statusCode}');

      return DailyReportResponse.fromResponse(response);
    } catch (e) {
      appLogger.e('🔥 [DailyReport] Error fetching report: $e');
      return DailyReportResponse.error(
        message: 'Failed to fetch daily report: $e',
        statusCode: 0,
      );
    }
  }

  /// Vérifier la connexion au backend
  ///
  /// GET /api/health
  ///
  /// Returns:
  /// - true si le backend est accessible
  Future<bool> checkConnection() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      appLogger.e('🔥 [Health] Connection check failed: $e');
      return false;
    }
  }
}
