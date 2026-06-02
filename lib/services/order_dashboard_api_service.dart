import 'dart:convert';
import 'package:caisse_1/api/api_client.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_logger.dart';


/// Service pour récupérer les commandes depuis le backend Laravel
class OrderDashboardApiService {
  final ApiClient _apiClient;
  final String baseUrl;

  OrderDashboardApiService({
    required ApiClient apiClient,
    required this.baseUrl,
  }) : _apiClient = apiClient;

  /// Récupère toutes les commandes d'un restaurant avec filtrage par date
  /// 
  /// [restaurantId] - ID du restaurant
  /// [startDate] - Date de début (optionnel, format: YYYY-MM-DD)
  /// [endDate] - Date de fin (optionnel, format: YYYY-MM-DD)
  /// [limit] - Nombre max de commandes (0 = pas de limite, défaut: 1000)
  Future<Map<String, dynamic>> getOrdersByRestaurant({
    required int restaurantId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000, // ✅ Augmenté à 1000 par défaut
  }) async {
    try {
      // ✅ S'assurer que le token est à jour avant l'appel API
      _refreshAuthToken();
      
      // Construire l'URL avec paramètres de date optionnels
      String url = '/api/orders/restaurant/$restaurantId';
      
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = _formatDate(endDate);
      }
      // ✅ Ajouter le paramètre limit
      queryParams['limit'] = limit.toString();
      
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        url += '?$queryString';
      }

      appLogger.d('📊 [DASHBOARD API] Fetching orders: $url');

      final response = await _apiClient.getData(url);

      if (response.statusCode == 200) {
        // ✅ response.body est déjà décodé par ApiClient
        final data = response.body;
        
        // Si c'est une String, on la décode, sinon on l'utilise directement
        final Map<String, dynamic> parsedData;
        if (data is String) {
          parsedData = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          parsedData = data;
        } else {
          throw Exception('Format de réponse invalide: ${data.runtimeType}');
        }
        
        if (parsedData['success'] == true) {
          appLogger.d(
            '✅ [DASHBOARD API] Retrieved ${parsedData['count']} orders for restaurant ${parsedData['restaurant_id']}',
          );
          return parsedData;
        } else {
          throw Exception(parsedData['message'] ?? 'Erreur API inconnue');
        }
      } else {
        throw Exception(
          'Erreur HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      appLogger.e('❌ [DASHBOARD API] Error fetching orders: $e');
      rethrow;
    }
  }

  /// Formate la date en YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// ✅ Rafraîchit le token d'authentification avant chaque appel API
  void _refreshAuthToken() {
    // Le token est déjà géré par ApiClient via updateHeaders()
    // Cette méthode sert juste à logger l'état de l'authentification
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final currentUser = auth.currentUser;
      
      if (currentUser != null) {
        appLogger.d(
          '🔑 [DASHBOARD API] Authenticated user: ${currentUser.name} (${currentUser.role})',
        );
      } else {
        appLogger.w('⚠️ [DASHBOARD API] No authenticated user');
      }
    } else {
      appLogger.w('⚠️ [DASHBOARD API] AuthController not registered');
    }
  }
}
