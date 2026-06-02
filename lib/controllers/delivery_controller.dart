import 'package:get/get.dart';
import '../models/delivery.dart';
import '../services/database_service.dart';
import '../services/api_import_service.dart';
import '../services/sync_queue_service.dart';
import '../data/app_constants.dart';
import '../api/api_client.dart';
import '../utils/app_logger.dart';
import 'auth_controller.dart';

class DeliveryController extends GetxController {
  static DeliveryController get instance => Get.find();

  final RxList<Delivery> _deliveries = <Delivery>[].obs;
  List<Delivery> get deliveries => _deliveries.toList();
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  late ApiImportService _apiService;

  // ✅ Flag to track if deliveries have been synced to backend (in-memory only)
  bool _hasSyncedDeliveriesToBackend = false;

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    print('🚚 [DELIVERY] DeliveryController initialized');
    _apiService = ApiImportService(
      baseUrl: AppConstant.baseUrl,
      authToken: Get.find<ApiClient>().token,
    );
    // Don't auto-fetch deliveries on init - let the UI call fetchDeliveriesByRestaurant()
    // when needed (e.g., when the deliveries screen is shown)
  }

  // ✅ Initialize deliveries after login (call this from AuthController after successful login)
  Future<void> initAfterLogin() async {
    try {
      print('🚚 [DELIVERY] Initializing after login...');
      final restId = Get.find<AuthController>().currentUser?.restaurantId;
      await fetchDeliveriesByRestaurant(restId);

      // ✅ Auto-sync local deliveries to backend (send local deliveries to backend)
      await syncLocalDeliveriesToBackend();
      print('✅ [DELIVERY] Delivery initialization completed');
    } catch (e, stackTrace) {
      print('❌ [DELIVERY] Delivery initialization failed: $e');
      appLogger.e('Delivery init failed', error: e, stackTrace: stackTrace);
    }
  }

  void updateApiToken(String token) {
    _apiService.updateAuthToken(token);
  }

  Future<void> fetchDeliveriesByRestaurant(int? restaurantId) async {
    try {
      if (restaurantId == null || restaurantId <= 0) {
        _deliveries.clear();
        return;
      }
      _isLoading.value = true;
      // First, try to fetch from API
      try {
        final apiDeliveries = await _apiService.fetchDeliveries(
          restaurantId: restaurantId,
        );
        // Save to database
        for (final apiDelivery in apiDeliveries) {
          final existing = await DatabaseService.getDeliveryByEmail(
            apiDelivery.email,
          );
          if (existing == null) {
            await DatabaseService.createDelivery(apiDelivery);
          } else {
            apiDelivery.id = existing.id;
            await DatabaseService.updateDelivery(apiDelivery);
          }
        }
      } catch (e) {
        appLogger.i('⚠️ API fetch failed, using local data: $e');
      }
      // Then load from database
      final list = await DatabaseService.getDeliveriesByRestaurant(
        restaurantId,
      );
      _deliveries.assignAll(list);
    } catch (e) {
      appLogger.i('Error fetching deliveries: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Delivery?> createDelivery({
    required String name,
    required String phone,
    required String email,
    required String password,
    required int restaurantId,
    bool isActive = true,
  }) async {
    try {
      // Validate phone format BEFORE creating locally
      final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
      if (phoneDigits.length != 10) {
        throw Exception(
          'Le numéro de téléphone doit contenir exactement 10 chiffres',
        );
      }

      final existing = await DatabaseService.getDeliveryByEmail(email);
      if (existing != null) {
        throw Exception('Un livreur avec cet email existe déjà');
      }

      // ✅ Step 1: Create in database FIRST (always succeeds)
      final newDelivery = Delivery(
        name: name,
        phone: phoneDigits, // Store normalized phone
        email: email,
        password: Delivery.hashPassword(password),
        restaurantId: restaurantId,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await DatabaseService.createDelivery(newDelivery);
      if (id == 0) {
        throw Exception('Échec de la création locale du livreur');
      }

      _deliveries.add(newDelivery);
      appLogger.i('✅ Delivery created locally with ID: $id');

      // ✅ Step 2: Sync with backend to get auto-generated PIN (non-blocking)
      try {
        final apiDelivery = await _apiService.createDelivery(
          name: name,
          phone: phoneDigits,
          email: email,
          password: password,
          restaurantId: restaurantId,
          isActive: isActive,
        );
        if (apiDelivery != null && apiDelivery.id > 0) {
          // Update local delivery with backend data (including PIN)
          newDelivery.id = apiDelivery.id;
          if (apiDelivery.pinCode != null) {
            newDelivery.pinCode = apiDelivery.pinCode;
            appLogger.i('🔄 PIN backend reçu: ${apiDelivery.pinCode}');
          }
          await DatabaseService.updateDelivery(newDelivery);
          final index = _deliveries.indexWhere((d) => d.id == id);
          if (index != -1) {
            _deliveries[index] = newDelivery;
          }
          appLogger.i(
            '✅ Delivery synced with backend: API ID ${apiDelivery.id}',
          );
        } else {
          appLogger.i('⚠️ Backend sync returned null - will retry later');
        }
      } catch (e) {
        appLogger.i('⚠️ Backend sync failed for create: $e');
        appLogger.i('💡 Livreur créé en local uniquement - ID: $id');
        // Delivery is still valid locally, will sync later via syncLocalDeliveriesToBackend()
      }

      return newDelivery;
    } catch (e) {
      appLogger.i('Error creating delivery: $e');
      rethrow;
    }
  }

  Future<bool> updateDelivery({
    required int deliveryId,
    String? name,
    String? phone,
    String? email,
    bool? isActive,
    String? password,
  }) async {
    try {
      final delivery = await DatabaseService.getDeliveryById(deliveryId);
      if (delivery == null) {
        throw Exception('Livreur introuvable');
      }

      if (name != null) delivery.name = name;
      if (phone != null) delivery.phone = phone;
      if (email != null) delivery.email = email;
      if (isActive != null) delivery.isActive = isActive;
      if (password != null && password.isNotEmpty) {
        delivery.password = Delivery.hashPassword(password);
      }

      delivery.updatedAt = DateTime.now();

      final result = await DatabaseService.updateDelivery(delivery);
      if (result != 0) {
        final index = _deliveries.indexWhere((d) => d.id == deliveryId);
        if (index != -1) {
          _deliveries[index] = delivery;
        } else {
          _deliveries.add(delivery);
        }
        update();

        // Try to sync with backend (non-blocking)
        try {
          await _apiService.updateDelivery(
            remoteId: deliveryId,
            name: name,
            phone: phone,
            email: email,
            isActive: isActive,
            password: password,
          );
        } catch (e) {
          appLogger.i('⚠️ Backend sync failed for update: $e');
        }
        return true;
      }
      return false;
    } catch (e) {
      appLogger.i('Error updating delivery: $e');
      rethrow;
    }
  }

  Future<bool> toggleDeliveryActivation(int deliveryId) async {
    try {
      final delivery = await DatabaseService.getDeliveryById(deliveryId);
      if (delivery == null) {
        throw Exception('Livreur introuvable');
      }

      delivery.isActive = !delivery.isActive;
      delivery.updatedAt = DateTime.now();

      final result = await DatabaseService.updateDelivery(delivery);
      if (result != 0) {
        final index = _deliveries.indexWhere((d) => d.id == deliveryId);
        if (index != -1) {
          _deliveries[index] = delivery;
        }
        update();

        // Try to sync with backend (non-blocking)
        try {
          await _apiService.toggleDeliveryActive(
            remoteId: deliveryId,
            isActive: delivery.isActive,
          );
        } catch (e) {
          appLogger.i('⚠️ Backend sync failed for toggle: $e');
        }
        return true;
      }
      return false;
    } catch (e) {
      appLogger.i('Error toggling delivery activation: $e');
      rethrow;
    }
  }

  Future<bool> deleteDelivery(int deliveryId) async {
    try {
      final delivery = await DatabaseService.getDeliveryById(deliveryId);

      // Try to delete from backend first (non-blocking)
      if (delivery != null && delivery.id > 0) {
        try {
          await _apiService.deleteDelivery(remoteId: deliveryId);
        } catch (e) {
          appLogger.i('⚠️ Backend sync failed for delete: $e');
        }
      }

      final result = await DatabaseService.deleteDelivery(deliveryId);
      if (result) {
        _deliveries.removeWhere((d) => d.id == deliveryId);
        return true;
      }
      return false;
    } catch (e) {
      appLogger.i('Error deleting delivery: $e');
      rethrow;
    }
  }

  List<Delivery> getActiveDeliveries() {
    return _deliveries.where((d) => d.isActive).toList();
  }

  List<Delivery> getInactiveDeliveries() {
    return _deliveries.where((d) => !d.isActive).toList();
  }

  /// Sync local deliveries that don't have API IDs yet
  /// Called only ONCE per session to avoid duplications
  Future<void> syncLocalDeliveriesToBackend() async {
    // ✅ Check if already synced in this session
    if (_hasSyncedDeliveriesToBackend) {
      appLogger.i(
        '✅ Deliveries already synced to backend in this session, skipping',
      );
      return;
    }

    try {
      appLogger.i('🔄 Starting local deliveries sync...');
      final localDeliveries = await DatabaseService.getAllDeliveries();
      final unsyncedDeliveries = localDeliveries
          .where((d) => d.id < 1000)
          .toList();

      if (unsyncedDeliveries.isEmpty) {
        appLogger.i('✅ No unsynced local deliveries');
        _hasSyncedDeliveriesToBackend = true; // Mark as done
        return;
      }

      appLogger.i(
        '📊 Found ${unsyncedDeliveries.length} unsynced local deliveries',
      );

      for (final delivery in unsyncedDeliveries) {
        try {
          // Validate phone BEFORE syncing
          final phoneDigits = delivery.phone.replaceAll(RegExp(r'\D'), '');
          if (phoneDigits.length != 10) {
            appLogger.i(
              '⚠️ Skipping ${delivery.name}: Invalid phone (${delivery.phone})',
            );
            appLogger.i('💡 Please update the phone to 10 digits first');
            continue;
          }

          // Update local phone if it was formatted differently
          if (delivery.phone != phoneDigits) {
            delivery.phone = phoneDigits;
            await DatabaseService.updateDelivery(delivery);
          }

          appLogger.i(
            '📤 Syncing delivery: ${delivery.name} (${delivery.email})...',
          );

          // Try to create on backend via direct API first (for initial creation)
          final apiDelivery = await _apiService.createDelivery(
            name: delivery.name,
            phone: phoneDigits,
            email: delivery.email,
            password:
                delivery.pinCode ?? '123456', // Use existing PIN or default
            restaurantId: delivery.restaurantId,
            isActive: delivery.isActive,
          );

          if (apiDelivery != null && apiDelivery.id > 0) {
            // Update local DB with API ID
            delivery.id = apiDelivery.id;
            await DatabaseService.updateDelivery(delivery);

            // Update local list
            final index = _deliveries.indexWhere(
              (d) => d.email == delivery.email,
            );
            if (index != -1) {
              _deliveries[index] = delivery;
            }

            // ✅ Enqueue to SyncQueueService for future updates
            await SyncQueueService.instance.enqueueDeliveryUpsert(delivery);

            appLogger.i(
              '✅ Synced: ${delivery.name} -> API ID: ${apiDelivery.id}',
            );
          } else {
            appLogger.i('⚠️ Backend returned null for ${delivery.name}');
          }
        } catch (e) {
          appLogger.i('⚠️ Failed to sync ${delivery.name}: $e');
          // Check if it's a duplicate phone error
          if (e.toString().contains('déjà utilisé') ||
              e.toString().contains('already used')) {
            appLogger.i('💡 This phone is already registered in backend');
            appLogger.i(
              '💡 Consider updating the phone number or deleting this delivery',
            );
          }
        }
      }

      appLogger.i('🎉 Local deliveries sync completed!');
      _hasSyncedDeliveriesToBackend = true; // ✅ Mark as done
    } catch (e) {
      appLogger.i('💥 Error in syncLocalDeliveriesToBackend: $e');
    }
  }
}
