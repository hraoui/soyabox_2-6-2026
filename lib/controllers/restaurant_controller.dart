import 'package:get/get.dart';
import '../models/restaurant.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import 'auth_controller.dart';
import 'pos_controller.dart'; // ✅ Import pour accéder au staff actif

class RestaurantController extends GetxController {
  static RestaurantController get instance => Get.find();

  final RxList<Restaurant> _restaurants = <Restaurant>[].obs;
  List<Restaurant> get restaurants => _restaurants.toList();
  final RxnInt _selectedRestaurantId = RxnInt();
  int? get selectedRestaurantId => _selectedRestaurantId.value;

  /// ✅ Récupère l'ID du restaurant importé selon le contexte
  /// - Si un staff est connecté (via PIN/Badge) : retourne SON restaurant
  /// - Si un admin est connecté : retourne SON restaurant
  /// - Sinon : retourne le premier restaurant actif (fallback)
  int? getImportedRestaurantId() {
    // 1. Priorité MAXIMALE : Utiliser le restaurant du staff actif (PosController)
    // Cela permet aux serveurs de se connecter avec leur propre restaurant, même si un admin d'un autre restaurant est connecté
    if (Get.isRegistered<PosController>()) {
      final pos = Get.find<PosController>();
      final activeStaff = pos.activeStaff;
      
      if (activeStaff != null && 
          activeStaff.restaurantId != null && 
          activeStaff.restaurantId! > 0) {
        
        // Vérifier que ce restaurant existe bien dans la liste locale
        final staffRestaurant = _restaurants.firstWhereOrNull(
          (r) => r.id == activeStaff.restaurantId,
        );
        
        if (staffRestaurant != null) {
          appLogger.d(
            '🍽️ [RESTAURANT] Using active STAFF\'s restaurant: ID ${activeStaff.restaurantId} (${staffRestaurant.name})',
          );
          return activeStaff.restaurantId;
        }
      }
    }

    // 2. Priorité secondaire : Utiliser le restaurant de l'admin connecté (AuthController)
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final currentUser = auth.currentUser;
      
      // Si un utilisateur est connecté et a un restaurant_id valide
      if (currentUser != null && 
          currentUser.restaurantId != null && 
          currentUser.restaurantId! > 0) {
        
        // Vérifier que ce restaurant existe bien dans la liste locale
        final userRestaurant = _restaurants.firstWhereOrNull(
          (r) => r.id == currentUser.restaurantId,
        );
        
        if (userRestaurant != null) {
          appLogger.d(
            '🍽️ [RESTAURANT] Using connected ADMIN\'s restaurant: ID ${currentUser.restaurantId} (${userRestaurant.name})',
          );
          return currentUser.restaurantId;
        }
      }
    }

    // 3. Fallback : Premier restaurant actif
    final activeRestaurants = getActiveRestaurants();
    if (activeRestaurants.isNotEmpty) {
      appLogger.d(
        '🍽️ [RESTAURANT] No connected user/staff, using first active restaurant: ID ${activeRestaurants.first.id}',
      );
      return activeRestaurants.first.id;
    }

    // 4. Fallback ultime : Premier restaurant (même inactif)
    if (_restaurants.isNotEmpty) {
      appLogger.w(
        '⚠️ [RESTAURANT] No active restaurants, using first restaurant: ID ${_restaurants.first.id}',
      );
      return _restaurants.first.id;
    }

    // 5. Aucun restaurant trouvé
    appLogger.w('⚠️ [RESTAURANT] No restaurants found in local database');
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    print(
      '🍽️ [RESTAURANT] RestaurantController initialized (waiting for manual import)',
    );

    // ✅ Auto-load restaurants from local database on init
    // This allows getImportedRestaurantId() to work immediately,
    // even before manual import or user login
    _loadLocalRestaurants();
  }

  /// Load restaurants from local database (not from API)
  Future<void> _loadLocalRestaurants() async {
    try {
      final allRestaurants = await DatabaseService.getAllRestaurants();
      
      // ✅ Filtrer par restaurant du staff actif ou de l'admin connecté
      List<Restaurant> restaurantsToLoad;
      
      // Priorité 1: Staff actif (via PosController)
      if (Get.isRegistered<PosController>()) {
        final pos = Get.find<PosController>();
        final activeStaff = pos.activeStaff;
        
        if (activeStaff != null && 
            activeStaff.restaurantId != null && 
            activeStaff.restaurantId! > 0) {
          
          // Filtrer pour ne garder que le restaurant du staff
          restaurantsToLoad = allRestaurants.where((r) {
            return r.id == activeStaff.restaurantId;
          }).toList();
          
          appLogger.d(
            '🍽️ [RESTAURANT] Filtering by active STAFF\'s restaurant ID: ${activeStaff.restaurantId}',
          );
        } else {
          // Pas de staff actif → vérifier admin
          restaurantsToLoad = _filterByAdminOrAll(allRestaurants);
        }
      } else {
        // PosController non disponible → vérifier admin
        restaurantsToLoad = _filterByAdminOrAll(allRestaurants);
      }

      _restaurants.assignAll(restaurantsToLoad);

      if (_selectedRestaurantId.value == null && restaurantsToLoad.isNotEmpty) {
        _selectedRestaurantId.value = restaurantsToLoad.first.id;
      }

      if (restaurantsToLoad.isNotEmpty) {
        appLogger.d(
          '🍽️ [RESTAURANT] Loaded ${restaurantsToLoad.length} restaurant(s) from local DB',
        );
      }
    } catch (e) {
      appLogger.w('⚠️ [RESTAURANT] Failed to load local restaurants: $e');
    }
  }

  /// Helper method to filter by admin or load all restaurants
  List<Restaurant> _filterByAdminOrAll(List<Restaurant> allRestaurants) {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final currentUser = auth.currentUser;
      
      // Si un utilisateur est connecté et a un restaurant_id valide
      if (currentUser != null && 
          currentUser.restaurantId != null && 
          currentUser.restaurantId! > 0) {
        
        // Filtrer pour ne garder que le restaurant de l'utilisateur
        return allRestaurants.where((r) {
          return r.id == currentUser.restaurantId;
        }).toList();
      }
    }
    
    // Pas d'utilisateur ou pas de restaurant_id → charger tous
    return allRestaurants;
  }

  Future<void> fetchAllRestaurants() async {
    try {
      final allRestaurants = await DatabaseService.getAllRestaurants();

      // ✅ Priorité 1: Staff actif (via PosController)
      int? targetRestaurantId;
      
      if (Get.isRegistered<PosController>()) {
        final pos = Get.find<PosController>();
        final activeStaff = pos.activeStaff;
        
        if (activeStaff != null && 
            activeStaff.restaurantId != null && 
            activeStaff.restaurantId! > 0) {
          targetRestaurantId = activeStaff.restaurantId;
          appLogger.d(
            '🍽️ [RESTAURANT] Fetching by active STAFF\'s restaurant ID: $targetRestaurantId',
          );
        }
      }

      // ✅ Priorité 2: Admin connecté (via AuthController)
      if (targetRestaurantId == null && Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final currentUser = auth.currentUser;
        
        if (currentUser != null && 
            currentUser.restaurantId != null && 
            currentUser.restaurantId! > 0) {
          targetRestaurantId = currentUser.restaurantId;
          appLogger.d(
            '🍽️ [RESTAURANT] Fetching by connected ADMIN\'s restaurant ID: $targetRestaurantId',
          );
        }
      }

      // Filtrer par restaurant cible (si défini)
      List<Restaurant> restaurants;
      if (targetRestaurantId != null) {
        restaurants = allRestaurants.where((r) {
          return r.id == targetRestaurantId;
        }).toList();
      } else {
        // Superadmin ou pas de restaurant → tous les restaurants
        restaurants = allRestaurants;
        appLogger.d('🍽️ [RESTAURANT] Fetching ALL restaurants (superadmin or no context)');
      }

      _restaurants.assignAll(restaurants);
      if (_selectedRestaurantId.value == null && restaurants.isNotEmpty) {
        _selectedRestaurantId.value = restaurants.first.id;
      }
    } catch (e) {
      appLogger.i('Error fetching restaurants: $e');
      rethrow;
    }
  }

  /// Clear in-memory restaurant cache after a local reset
  void clearLocalRestaurants() {
    _restaurants.clear();
    _selectedRestaurantId.value = null;
    update();
  }

  void setSelectedRestaurantId(int? id) {
    _selectedRestaurantId.value = id;
  }

  // Create a new restaurant
  Future<bool> createRestaurant({
    required String name,
    required String address,
    required String phone,
    bool isActive = true,
  }) async {
    try {
      // Create new restaurant
      final newRestaurant = Restaurant(
        name: name,
        address: address,
        phone: phone,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save restaurant to database
      final restaurantId = await DatabaseService.createRestaurant(
        newRestaurant,
      );

      if (restaurantId != 0) {
        _restaurants.add(newRestaurant);
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error creating restaurant: $e');
      rethrow;
    }
  }

  // Update restaurant
  Future<bool> updateRestaurant({
    required int restaurantId,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      // Get the restaurant from database
      final restaurant = await DatabaseService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        throw Exception('Restaurant introuvable');
      }

      // Update fields if provided
      if (name != null) restaurant.name = name;
      if (address != null) restaurant.address = address;
      if (phone != null) restaurant.phone = phone;
      if (isActive != null) restaurant.isActive = isActive;

      restaurant.updatedAt = DateTime.now();

      // Update restaurant in database
      final result = await DatabaseService.updateRestaurant(restaurant);

      if (result != 0) {
        // Update the restaurant in the observable list
        final index = _restaurants.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _restaurants[index] = restaurant;
        } else {
          // If not in the list, add it
          _restaurants.add(restaurant);
        }
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error updating restaurant: $e');
      rethrow;
    }
  }

  // Toggle restaurant activation status
  Future<bool> toggleRestaurantActivation(int restaurantId) async {
    try {
      final restaurant = await DatabaseService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        throw Exception('Restaurant introuvable');
      }

      // Toggle the active status
      restaurant.isActive = !restaurant.isActive;
      restaurant.updatedAt = DateTime.now();

      final result = await DatabaseService.updateRestaurant(restaurant);

      if (result != 0) {
        // Update the restaurant in the observable list
        final index = _restaurants.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _restaurants[index] = restaurant;
        }
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error toggling restaurant activation: $e');
      rethrow;
    }
  }

  Future<bool> deleteRestaurant(int restaurantId) async {
    try {
      final result = await DatabaseService.deleteRestaurant(restaurantId);
      if (result) {
        _restaurants.removeWhere((r) => r.id == restaurantId);
        return true;
      }
      return false;
    } catch (e) {
      appLogger.i('Error deleting restaurant: $e');
      rethrow;
    }
  }

  // Get active restaurants only
  List<Restaurant> getActiveRestaurants() {
    return _restaurants.where((restaurant) => restaurant.isActive).toList();
  }

  // Get inactive restaurants only
  List<Restaurant> getInactiveRestaurants() {
    return _restaurants.where((restaurant) => !restaurant.isActive).toList();
  }

  // Set the selected restaurant ID
  void setRestaurantId(int? restaurantId) {
    _selectedRestaurantId.value = restaurantId;
  }
}
