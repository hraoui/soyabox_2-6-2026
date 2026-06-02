import 'dart:async';
import 'package:caisse_1/api/api_client.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/app_constants.dart';
import '../services/auth_session_service.dart'; // ✅ Pour récupérer le token de session
import '../services/order_dashboard_api_service.dart';
import '../utils/app_logger.dart';

/// Modèle de données pour les statistiques du dashboard
class DashboardOrderStats {
  final int totalOrders;
  final double totalRevenue;
  final int apiTotalCount; // ✅ Nombre total retourné par l'API (peut être limité)
  
  // Par type de commande (fulfillment_type)
  final Map<String, int> ordersByType;
  final Map<String, double> revenueByType;
  
  // Par channel
  final Map<String, int> ordersByChannel;
  final Map<String, double> revenueByChannel;
  
  final DateTime dateFrom;
  final DateTime dateTo;

  DashboardOrderStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.apiTotalCount,
    required this.ordersByType,
    required this.revenueByType,
    required this.ordersByChannel,
    required this.revenueByChannel,
    required this.dateFrom,
    required this.dateTo,
  });
}

class AdminDashboardController extends GetxController {
  static AdminDashboardController get instance => Get.find();

  final Rx<DashboardOrderStats?> _stats = Rx<DashboardOrderStats?>(null);
  DashboardOrderStats? get stats => _stats.value;

  final Rx<Map<String, dynamic>?> _apiResponse = Rx<Map<String, dynamic>?>(null);
  Map<String, dynamic>? get apiResponse => _apiResponse.value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _error = ''.obs;
  String get error => _error.value;

  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  DateTime get selectedDate => _selectedDate.value;

  late OrderDashboardApiService _apiService;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _apiService = OrderDashboardApiService(
      apiClient: Get.find<ApiClient>(),
      baseUrl: AppConstant.baseUrl,
    );
    
    // ✅ NE PAS charger automatiquement - attendre que l'utilisateur ouvre la page
    // loadDashboardData();
    
    // ✅ NE PAS démarrer l'auto-refresh automatiquement
    // startAutoRefresh(); // Appel manuel requis si besoin
    
    appLogger.i('📊 [ADMIN DASHBOARD] Controller initialized (waiting for manual load)');
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
    appLogger.i('📊 [ADMIN DASHBOARD] Controller closed, auto-refresh stopped');
  }

  /// ✅ Synchronise le token de ApiClient avec AuthSessionService
  void _syncApiClientToken() {
    if (Get.isRegistered<ApiClient>()) {
      final apiClient = Get.find<ApiClient>();
      final sessionToken = AuthSessionService.instance.token;
      
      if (sessionToken.isNotEmpty) {
        apiClient.updateHeaders(sessionToken);
        appLogger.d('🔑 [DASHBOARD] ApiClient token synced from session');
      } else {
        appLogger.w('⚠️ [DASHBOARD] No session token available');
      }
    }
  }

  /// Change la date sélectionnée et recharge les données
  void changeSelectedDate(DateTime newDate) {
    _selectedDate.value = newDate;
    loadDashboardData();
  }

  /// Charge les données du dashboard depuis l'API backend
  Future<void> loadDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = '';
      update();

      // ✅ S'assurer que ApiClient a le token le plus récent
      _syncApiClientToken();

      // Récupérer le restaurant de l'admin connecté
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      final restaurantId = auth?.currentUser?.restaurantId;

      if (restaurantId == null || restaurantId <= 0) {
        throw Exception('Restaurant ID non disponible');
      }

      // Calculer les dates de début et fin
      final startDate = DateTime(
        _selectedDate.value.year,
        _selectedDate.value.month,
        _selectedDate.value.day,
      );
      final endDate = startDate.add(const Duration(days: 1));

      appLogger.d(
        '📊 [DASHBOARD] Loading data for restaurant $restaurantId, '
        'date: ${startDate.toString().substring(0, 10)}',
      );

      // Appeler l'API backend
      final response = await _apiService.getOrdersByRestaurant(
        restaurantId: restaurantId,
        startDate: startDate,
        endDate: endDate,
      );

      // Parser les données
      final stats = _parseApiResponse(response, startDate, endDate);
      
      _stats.value = stats;
      _apiResponse.value = response; // ✅ Stocker la réponse complète
      _error.value = '';
      
      appLogger.d(
        '✅ [DASHBOARD] Data loaded: ${stats.totalOrders} orders, '
        'revenue: ${stats.totalRevenue.toStringAsFixed(2)} MAD',
      );
    } catch (e) {
      _error.value = e.toString();
      appLogger.e('❌ [DASHBOARD] Error loading data: $e');
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  /// Parse la réponse de l'API et calcule les statistiques
  DashboardOrderStats _parseApiResponse(
    Map<String, dynamic> response,
    DateTime dateFrom,
    DateTime dateTo,
  ) {
    final orders = response['orders'] as List<dynamic>;
    final apiCount = response['count'] as int? ?? 0; // ✅ Nombre total retourné par l'API
    
    int totalOrders = 0;
    double totalRevenue = 0.0;
    
    final ordersByType = <String, int>{};
    final revenueByType = <String, double>{};
    final ordersByChannel = <String, int>{};
    final revenueByChannel = <String, double>{};

    for (final order in orders) {
      // ✅ Compter TOUTES les commandes (pas seulement payées)
      totalOrders++;
      final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += totalPrice;

      // Statistiques par fulfillment_type
      final fulfillmentType = (order['fulfillment_type'] as String?) ?? 'unknown';
      ordersByType[fulfillmentType] = (ordersByType[fulfillmentType] ?? 0) + 1;
      revenueByType[fulfillmentType] = 
          (revenueByType[fulfillmentType] ?? 0.0) + totalPrice;

      // Statistiques par channel
      final channel = (order['channel'] as String?) ?? 'unknown';
      ordersByChannel[channel] = (ordersByChannel[channel] ?? 0) + 1;
      revenueByChannel[channel] = 
          (revenueByChannel[channel] ?? 0.0) + totalPrice;
    }

    appLogger.d(
      '📊 [DASHBOARD PARSE] API returned $apiCount orders, '
      'all statuses included',
    );

    return DashboardOrderStats(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      apiTotalCount: apiCount, // ✅ Stocker le count de l'API
      ordersByType: ordersByType,
      revenueByType: revenueByType,
      ordersByChannel: ordersByChannel,
      revenueByChannel: revenueByChannel,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Démarre le rafraîchissement automatique toutes les 60 secondes
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      appLogger.d('🔄 [DASHBOARD] Auto-refresh triggered');
      loadDashboardData();
    });
    appLogger.d('🔄 [DASHBOARD] Auto-refresh started');
  }

  /// Arrête le rafraîchissement automatique
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    appLogger.d('⏹️ [DASHBOARD] Auto-refresh stopped');
  }

  /// Rafraîchissement manuel
  Future<void> manualRefresh() async {
    appLogger.d('🔄 [DASHBOARD] Manual refresh triggered');
    await loadDashboardData();
  }

  /// Formater un montant en MAD
  String formatMoney(double amount) {
    return '${amount.toStringAsFixed(2)} MAD';
  }

  /// Obtenir un label lisible pour le fulfillment type
  String getFulfillmentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'on_site':
        return 'Sur place';
      case 'pickup':
        return 'À emporter';
      case 'delivery':
        return 'Livraison';
      default:
        return type;
    }
  }

  /// Obtenir un label lisible pour le channel
  String getChannelLabel(String channel) {
    switch (channel.toLowerCase()) {
      case 'pos':
        return 'POS';
      case 'api':
      case 'web':
        return 'API / Web';
      case 'kiosk':
        return 'Kiosk';
      default:
        return channel.toUpperCase();
    }
  }
}
