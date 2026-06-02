import 'package:get/get.dart';
import '../services/api_import_service.dart';
import '../services/api_order_pull_service.dart';
import '../data/app_constants.dart';
import 'auth_controller.dart';
import 'restaurant_controller.dart';
import 'pos_controller.dart';
import '../services/sync_queue_service.dart';
import 'user_controller.dart';
import 'category_controller.dart';
import 'product_controller.dart';
import 'delivery_controller.dart';
import '../api/api_client.dart';
import '../utils/app_logger.dart';

class ImportController extends GetxController {
  static ImportController get instance => Get.find();

  final RxBool _isImporting = false.obs;
  final RxString _importStatus = ''.obs;
  final RxDouble _importProgress = 0.0.obs;

  bool get isImporting => _isImporting.value;
  String get importStatus => _importStatus.value;
  double get importProgress => _importProgress.value;

  late ApiImportService _apiService;

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    print('📥 [IMPORT] ImportController initialized');
    // Initialize API service with your backend URL
    _apiService = ApiImportService(
      baseUrl: AppConstant.baseUrl,
      authToken: Get.find<ApiClient>().token,
    ); // Use the configured base URL
  }

  // Update the API base URL
  void updateBaseUrl(String newBaseUrl) {
    _apiService = ApiImportService(
      baseUrl: newBaseUrl,
      authToken: Get.find<ApiClient>().token,
    );
    SyncQueueService.instance.updateBaseUrl(newBaseUrl);
    ApiOrderPullService.instance.updateBaseUrl(newBaseUrl);
  }

  void updateApiToken(String token) {
    _apiService.updateAuthToken(token);
    SyncQueueService.instance.updateAuthToken(token);
    ApiOrderPullService.instance.updateAuthToken(token);
  }

  Future<void> _refreshCategoriesIfReady() async {
    if (!Get.isRegistered<CategoryController>()) return;
    await Get.find<CategoryController>().fetchAllCategories();
  }

  Future<void> _refreshProductsIfReady() async {
    if (!Get.isRegistered<ProductController>()) return;
    await Get.find<ProductController>().fetchAllProducts();
  }

  // Import categories from backend
  Future<bool> importCategories() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des catégories...';
      _importProgress.value = 0.3;

      final success = await _apiService.importCategories();

      if (success) {
        await _refreshCategoriesIfReady();
        _importProgress.value = 0.6;
        _importStatus.value = 'Catégories importées avec succès !';
        return true;
      } else {
        _importStatus.value = 'Échec de l\'import des catégories';
        return false;
      }
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des catégories : $e';
      appLogger.i('Error importing categories: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      // Reset status after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // Import restaurants from backend
  Future<bool> importRestaurants() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des restaurants...';
      _importProgress.value = 0.2;

      // Récupérer le restaurant de l'admin connecté pour filtrer
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      final restaurantId = auth?.currentUser?.restaurantId;

      final success = await _apiService.importRestaurants(
        filterByRestaurantId: restaurantId,
      );

      if (success) {
        if (Get.isRegistered<RestaurantController>()) {
          await Get.find<RestaurantController>().fetchAllRestaurants();
        }
        if (Get.isRegistered<PosController>()) {
          await Get.find<PosController>().refreshRestaurantContext();
        }
        _importProgress.value = 0.4;
        _importStatus.value = 'Restaurants importés avec succès !';
        return true;
      } else {
        _importStatus.value = 'Échec de l\'import des restaurants';
        return false;
      }
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des restaurants : $e';
      appLogger.i('Error importing restaurants: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // Import tables from backend
  Future<bool> importTables({int? restaurantId}) async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des tables...';
      _importProgress.value = 0.2;

      final success = await _apiService.importTables(
        restaurantId: restaurantId,
      );

      if (success) {
        _importProgress.value = 0.4;
        _importStatus.value = 'Tables importées avec succès !';
        return true;
      } else {
        _importStatus.value = 'Échec de l\'import des tables';
        return false;
      }
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des tables : $e';
      appLogger.i('Error importing tables: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // Import products from backend
  Future<bool> importProducts() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des produits...';
      _importProgress.value = 0.6;

      final success = await _apiService.importProducts();

      if (success) {
        await _refreshProductsIfReady();
        _importProgress.value = 0.9;
        _importStatus.value = 'Produits importés avec succès !';
        await SyncQueueService.instance.queueUnsyncedOrders();
        await SyncQueueService.instance.flushQueue();
        return true;
      } else {
        _importStatus.value = 'Échec de l\'import des produits';
        return false;
      }
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des produits : $e';
      appLogger.i('Error importing products: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      // Reset status after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // ⚠️ DISABLED: Import users from backend
  // Users are now created locally first, then synced to backend
  // This prevents backend from overwriting local users
  Future<bool> importUsers() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des utilisateurs...';
      _importProgress.value = 0.8;

      // ⚠️ SKIP import - users are managed locally
      appLogger.i('⚠️ Users import disabled - users are managed locally');
      _importProgress.value = 0.9;
      _importStatus.value = 'Import utilisateurs désactivé (gestion locale)';

      // Just refresh local users if controller is available
      if (Get.isRegistered<UserController>()) {
        final auth = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : null;
        final restaurantId = auth?.currentUser?.restaurantId;
        await Get.find<UserController>().fetchAllUsers(
          restaurantId: restaurantId,
        );
      }

      return true;
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des utilisateurs : $e';
      appLogger.i('Error importing users: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès') ||
            _importStatus.value.contains('désactivé')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // ⚠️ DISABLED: Import deliveries from backend
  // Deliveries are now created locally first, then synced to backend
  // This prevents backend from overwriting local deliveries
  Future<bool> importDeliveries() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Importation des livreurs...';
      _importProgress.value = 0.8;

      // ⚠️ SKIP import - deliveries are managed locally
      appLogger.i(
        '⚠️ Deliveries import disabled - deliveries are managed locally',
      );
      _importProgress.value = 0.9;
      _importStatus.value = 'Import livreurs désactivé (gestion locale)';

      // Just refresh local deliveries if controller is available
      if (Get.isRegistered<DeliveryController>()) {
        final auth = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : null;
        final restaurantId = auth?.currentUser?.restaurantId;
        await Get.find<DeliveryController>().fetchDeliveriesByRestaurant(
          restaurantId,
        );
      }

      return true;
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des livreurs : $e';
      appLogger.i('Error importing deliveries: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      if (_importProgress.value < 1.0) {
        _importProgress.value = 0.0;
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès') ||
            _importStatus.value.contains('désactivé')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // Import all data (categories and products)
  Future<bool> importAllData() async {
    try {
      _isImporting.value = true;
      _importStatus.value = 'Démarrage de l\'import...';
      _importProgress.value = 0.1;

      // Import restaurants first (source of truth for restaurant IDs)
      await importRestaurants();
      _importProgress.value = 0.25;

      // Import tables first (if any)
      await importTables();
      _importProgress.value = 0.45;

      // Import categories
      await importCategories();
      _importProgress.value = 0.7;

      // Then import products
      await importProducts();
      _importProgress.value = 0.85;

      // Then import users
      await importUsers();
      await _refreshCategoriesIfReady();
      await _refreshProductsIfReady();
      _importProgress.value = 0.95;

      // Then import deliveries
      await importDeliveries();
      _importProgress.value = 1.0;
      _importStatus.value =
          'Toutes les données ont été importées avec succès !';

      return true;
    } catch (e) {
      _importStatus.value = 'Erreur lors de l\'import des données : $e';
      appLogger.i('Error importing all data: $e');
      rethrow;
    } finally {
      _isImporting.value = false;
      // Reset status after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_importStatus.value.contains('succès')) {
          _importStatus.value = '';
        }
      });
    }
  }

  // Get restaurant from backend
  Future<Map<String, dynamic>?> getRestaurant(int restaurantId) async {
    try {
      return await _apiService.getRestaurant(restaurantId);
    } catch (e) {
      appLogger.i('Error getting restaurant: $e');
      rethrow;
    }
  }

  // Get all restaurants from backend
  Future<List<Map<String, dynamic>>?> getAllRestaurants() async {
    try {
      return await _apiService.getAllRestaurants();
    } catch (e) {
      appLogger.i('Error getting restaurants: $e');
      rethrow;
    }
  }
}
