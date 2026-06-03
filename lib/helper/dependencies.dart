import 'package:caisse_1/api/api_client.dart';
import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:caisse_1/controllers/app_update_controller.dart';
import 'package:caisse_1/controllers/category_controller.dart';
import 'package:caisse_1/controllers/delivery_controller.dart';
import 'package:caisse_1/controllers/import_controller.dart';
import 'package:caisse_1/controllers/product_controller.dart';
import 'package:caisse_1/controllers/restaurant_controller.dart';
import 'package:caisse_1/controllers/settings_controller.dart';
import 'package:caisse_1/controllers/sync_controller.dart';
import 'package:caisse_1/controllers/table_controller.dart';
import 'package:caisse_1/controllers/user_controller.dart';
import 'package:caisse_1/controllers/pos_controller.dart';
import 'package:caisse_1/controllers/cash_register_controller.dart'; // Ajout du contrôleur de caisse
import 'package:caisse_1/data/app_constants.dart';
import 'package:caisse_1/repos/category_repo.dart';
import 'package:caisse_1/repos/product_repo.dart';
import 'package:caisse_1/repos/order_daily_sync_repo.dart';
import 'package:caisse_1/services/auth_session_service.dart';
import 'package:caisse_1/services/app_settings_service.dart';
import 'package:caisse_1/services/api_order_pull_service.dart';
import 'package:caisse_1/services/isar_order_local_database.dart';
import 'package:caisse_1/services/notification_sound_service.dart';
import 'package:caisse_1/services/sync_queue_service.dart';
import 'package:caisse_1/utils/app_logger.dart';
import 'dart:io';

import 'package:get/get.dart';

class DependencyInjection {
  static Future<void> init() async {
    print('🔧 [DEP] Starting dependency injection...');
    try {
      print('🔑 [DEP] Initializing AuthSessionService...');
      await AuthSessionService.instance.init();

      // ✅ Définir le token de fallback pour la sync background si pas de session
      AuthSessionService.instance.setFallbackToken(AppConstant.apiToken);
      print('✅ [DEP] AuthSessionService initialized with fallback token');

      print('⚙️ [DEP] Initializing AppSettingsService...');
      await AppSettingsService.instance.init();
      print('✅ [DEP] AppSettingsService initialized');

      final startupToken = AuthSessionService.instance.token.isNotEmpty
          ? AuthSessionService.instance.token
          : AppConstant.apiToken;
      print(
        '🔑 [DEP] Using startup token: ${startupToken.isNotEmpty ? "YES (masked)" : "NO"}',
      );

      // Api Client - permanent to keep token across navigation
      print('🌐 [DEP] Creating ApiClient...');
      Get.put(
        ApiClient(appBaseUrl: AppConstant.baseUrl, token: startupToken),
        permanent: true,
      );
      print('✅ [DEP] ApiClient created');

      // Repositories
      print('📦 [DEP] Creating CategoryRepo...');
      Get.put(CategoryRepo(apiClient: Get.find()));
      print('✅ [DEP] CategoryRepo created');

      print('📦 [DEP] Creating ProductRepo...');
      Get.put(ProductRepo(apiClient: Get.find()));
      print('✅ [DEP] ProductRepo created');

      // Controllers
      print('👤 [DEP] Creating AuthController...');
      Get.put<AuthController>(AuthController(), permanent: true);
      print('✅ [DEP] AuthController created');

      print('👥 [DEP] Creating UserController...');
      Get.put<UserController>(UserController(), permanent: true);
      print('✅ [DEP] UserController created');

      print('🍽️ [DEP] Creating RestaurantController...');
      Get.put<RestaurantController>(RestaurantController(), permanent: true);
      print('✅ [DEP] RestaurantController created');

      print('⚙️ [DEP] Creating SettingsController...');
      Get.put<SettingsController>(SettingsController(), permanent: true);
      print('✅ [DEP] SettingsController created');

      print('⬆️ [DEP] Creating AppUpdateController...');
      Get.put<AppUpdateController>(AppUpdateController(), permanent: true);
      print('✅ [DEP] AppUpdateController created');

      print('📂 [DEP] Creating CategoryController...');
      Get.put<CategoryController>(CategoryController());
      print('✅ [DEP] CategoryController created');

      print('🛍️ [DEP] Creating ProductController...');
      Get.put<ProductController>(ProductController());
      print('✅ [DEP] ProductController created');

      print('📥 [DEP] Creating ImportController (lazy)...');
      Get.lazyPut<ImportController>(() => ImportController());
      print('✅ [DEP] ImportController registered (lazy)');

      print('🪑 [DEP] Creating TableController (lazy)...');
      Get.lazyPut<TableController>(() => TableController());
      print('✅ [DEP] TableController registered (lazy)');

      print('🚚 [DEP] Creating DeliveryController...');
      Get.put<DeliveryController>(DeliveryController(), permanent: true);
      print('✅ [DEP] DeliveryController created');

      print('🏪 [DEP] Creating PosController...');
      Get.put<PosController>(PosController(), permanent: true);
      print('✅ [DEP] PosController created');

      print('💰 [DEP] Creating CashRegisterController...');
      Get.lazyPut<CashRegisterController>(() => CashRegisterController());
      print('✅ [DEP] CashRegisterController created');

      print('🔄 [DEP] Initializing SyncQueueService...');
      await SyncQueueService.instance.init(
        baseUrl: AppConstant.baseUrl,
        authToken: startupToken,
      );
      print('✅ [DEP] SyncQueueService initialized');

      print('📥 [DEP] Initializing ApiOrderPullService...');
      await ApiOrderPullService.instance.init(
        baseUrl: AppConstant.baseUrl,
        authToken: startupToken,
      );
      print('✅ [DEP] ApiOrderPullService initialized');

      print('📅 [DEP] Initializing Daily Order Sync services...');
      // Register IsarOrderLocalDatabase
      Get.lazyPut<IsarOrderLocalDatabase>(() => IsarOrderLocalDatabase());

      // Register OrderDailySyncRepository
      Get.lazyPut<OrderDailySyncRepository>(
        () => OrderDailySyncRepository.create(
          baseUrl: AppConstant.baseUrl,
          authToken: startupToken.isEmpty ? null : startupToken,
          localDb: Get.find<IsarOrderLocalDatabase>(),
        ),
      );
      print('✅ [DEP] Daily Order Sync services initialized');

      print('🔔 [DEP] Initializing NotificationSoundService...');
      await NotificationSoundService.instance.init();
      print('✅ [DEP] NotificationSoundService initialized');

      // SyncController will be initialized but won't start syncing until user logs in
      print('🔄 [DEP] Creating SyncController...');
      Get.put<SyncController>(SyncController(), permanent: true);
      print('✅ [DEP] SyncController created');

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // ✅ Start background sync immediately for desktop builds only
        print('🎵 [DEP] Starting desktop-only background sync for API orders...');
        Get.find<SyncController>().startBackgroundSync();
        print('✅ [DEP] Desktop background sync started');
      } else {
        print('⏭️ [DEP] Background sync skipped on non-desktop platform');
      }

      print('🎉 [DEP] Dependency injection completed successfully!');
    } catch (e, stackTrace) {
      print('❌ [DEP] Dependency injection FAILED: $e');
      print('❌ [DEP] Stack trace: $stackTrace');
      appLogger.e(
        'Dependency injection failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}