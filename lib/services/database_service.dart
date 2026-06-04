import 'dart:async';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../utils/path_utils.dart';
import '../controllers/restaurant_controller.dart';
import '../models/user.dart';
import '../models/restaurant.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_price.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/pos_table.dart';
import '../models/delivery.dart';
import '../models/order_delivery.dart';
import '../models/customer.dart';
import '../models/cash_register_state.dart'; // Ajout du modèle CashRegisterState
import '../utils/app_logger.dart';
import '../utils/badge_code_utils.dart';

class DatabaseService {
  static late Isar _isar;
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static Completer<void>? _initCompleter;

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    if (_isInitializing) {
      await _initCompleter!.future;
      return;
    }

    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      final dir = await getAppDocumentsDirectory();

      // Open database
      _isar = await Isar.open([
        UserSchema,
        RestaurantSchema,
        CategorySchema,
        ProductSchema,
        ProductPriceSchema,
        PosOrderSchema,
        PosOrderItemSchema,
        PosTableSchema,
        DeliverySchema,
        OrderDeliverySchema,
        CustomerSchema,
        CashRegisterStateSchema, // Ajout du schéma CashRegisterState
      ], directory: dir.path);

      _isInitialized = true;
      appLogger.i('✅ Database initialized successfully');
    } catch (e) {
      appLogger.e('❌ Database initialization failed: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      _initCompleter!.complete();
    }
  }

  static Future<void> close() async {
    if (_isInitialized) {
      try {
        await Future.delayed(const Duration(milliseconds: 50));
        await _isar.close();
        _isInitialized = false;
        _isInitializing = false;
        _initCompleter = null;
        appLogger.i('✅ Database closed successfully');
      } catch (e) {
        appLogger.e('❌ Database close failed: $e');
      }
    }
  }

  static Isar get db => _isar;

  // User methods
  static Future<int> createUser(User user) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.put(user);
    });
  }

  static Future<User?> getUserById(int id) async {
    return await _isar.users.where().idEqualTo(id).findFirst();
  }

  static Future<User?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final exactMatch = await _isar.users
        .filter()
        .emailEqualTo(normalizedEmail)
        .findFirst();
    if (exactMatch != null) return exactMatch;

    final allUsers = await _isar.users.where().findAll();
    for (final user in allUsers) {
      if (user.email.trim().toLowerCase() == normalizedEmail) {
        return user;
      }
    }
    return null;
  }

  static Future<User?> getUserByPhone(String phone) async {
    return await _isar.users.filter().phoneEqualTo(phone).findFirst();
  }

  static Future<User?> getUserByPin(
    String pin, {
    Set<String>? allowedRoles,
  }) async {
    final users = await _isar.users
        .filter()
        .pinCodeEqualTo(pin)
        .isActiveEqualTo(true)
        .findAll();

    if (users.isEmpty) {
      return null;
    }

    final normalizedAllowedRoles = allowedRoles
        ?.map((role) => role.trim().toLowerCase())
        .toSet();
    final candidates = users.where((user) {
      final role = user.role.trim().toLowerCase();
      return normalizedAllowedRoles == null ||
          normalizedAllowedRoles.contains(role);
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }

    int? importedRestaurantId;
    if (Get.isRegistered<RestaurantController>()) {
      importedRestaurantId = Get.find<RestaurantController>()
          .getImportedRestaurantId();
    }

    int rolePriority(User user) {
      switch (user.role.trim().toLowerCase()) {
        case 'superadmin':
          return 0;
        case 'admin':
          return 1;
        case 'cashier':
          return 2;
        case 'staff':
          return 3;
        case 'livreur':
        case 'delivery':
          return 4;
        default:
          return 5;
      }
    }

    candidates.sort((a, b) {
      final aRestaurantRank =
          importedRestaurantId != null && a.restaurantId == importedRestaurantId
          ? 0
          : 1;
      final bRestaurantRank =
          importedRestaurantId != null && b.restaurantId == importedRestaurantId
          ? 0
          : 1;
      if (aRestaurantRank != bRestaurantRank) {
        return aRestaurantRank.compareTo(bRestaurantRank);
      }

      final aRoleRank = rolePriority(a);
      final bRoleRank = rolePriority(b);
      if (aRoleRank != bRoleRank) {
        return aRoleRank.compareTo(bRoleRank);
      }

      return a.id.compareTo(b.id);
    });

    return candidates.first;
  }

  static Future<User?> getStaffByPin(String pin) async {
    return getUserByPin(
      pin,
      allowedRoles: const {'admin', 'superadmin', 'staff', 'cashier'},
    );
  }

  static Future<User?> getUserByBadgeCode(
    String badgeCode, {
    int? excludeUserId,
  }) async {
    final normalizedBadgeCode = normalizeBadgeCode(badgeCode);
    if (normalizedBadgeCode.isEmpty) return null;

    final users = await _isar.users.where().findAll();
    for (final user in users) {
      if (excludeUserId != null && user.id == excludeUserId) {
        continue;
      }
      if (normalizeBadgeCode(user.badgeCode) == normalizedBadgeCode) {
        return user;
      }
    }
    return null;
  }

  static Future<User?> getStaffByBadgeCode(String badgeCode) async {
    final normalizedBadgeCode = normalizeBadgeCode(badgeCode);
    if (normalizedBadgeCode.isEmpty) return null;

    final users = await _isar.users.where().findAll();
    final matching = users.where((user) {
      final role = user.role.trim().toLowerCase();
      return user.isActive &&
          normalizeBadgeCode(user.badgeCode) == normalizedBadgeCode &&
          (role == 'staff' || role == 'admin' || role == 'superadmin' || role == 'cashier');
    }).toList();

    int? importedRestaurantId;
    if (Get.isRegistered<RestaurantController>()) {
      importedRestaurantId = Get.find<RestaurantController>()
          .getImportedRestaurantId();
    }

    if (importedRestaurantId != null) {
      for (final user in matching) {
        if (user.restaurantId == importedRestaurantId) {
          return user;
        }
      }
    }

    return matching.isEmpty ? null : matching.first;
  }

  static Future<List<User>> getAllUsers() async {
    return await _isar.users.where().findAll();
  }

  static Future<List<User>> getUsersByRestaurant(int? restaurantId) async {
    if (restaurantId == null) {
      return await getAllUsers();
    }
    return await _isar.users
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .findAll();
  }

  static Future<List<User>> getUsersByRole(String role) async {
    return await _isar.users.filter().roleEqualTo(role).findAll();
  }

  static Future<int> updateUser(User user) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.put(user);
    });
  }

  static Future<bool> deleteUser(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.delete(id);
    });
  }

  // Restaurant methods
  static Future<int> createRestaurant(Restaurant restaurant) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.put(restaurant);
    });
  }

  static Future<Restaurant?> getRestaurantById(int id) async {
    return await _isar.restaurants.where().idEqualTo(id).findFirst();
  }

  static Future<List<Restaurant>> getAllRestaurants() async {
    return await _isar.restaurants.where().findAll();
  }

  static Future<int> updateRestaurant(Restaurant restaurant) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.put(restaurant);
    });
  }

  static Future<bool> deleteRestaurant(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.delete(id);
    });
  }

  // Category methods
  static Future<int> createCategory(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  static Future<Category?> getCategoryById(int id) async {
    return await _isar.categorys.where().idEqualTo(id).findFirst();
  }

  static Future<List<Category>> getAllCategories() async {
    return await _isar.categorys.where().findAll();
  }

  static Future<int> updateCategory(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  // Product methods
  static Future<int> createProduct(Product product) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.put(product);
    });
  }

  static Future<Product?> getProductById(int id) async {
    return await _isar.products.where().idEqualTo(id).findFirst();
  }

  static Future<Product?> getProductByNameAndCategory(
    String name,
    int categoryId,
  ) async {
    return await _isar.products
        .filter()
        .nameEqualTo(name)
        .categoryIdEqualTo(categoryId)
        .findFirst();
  }

  static Future<Product?> getProductByName(String name) async {
    return await _isar.products.filter().nameEqualTo(name).findFirst();
  }

  static Future<List<Product>> getAllProducts() async {
    return await _isar.products.where().findAll();
  }

  static Future<int> updateProduct(Product product) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.put(product);
    });
  }

  static Future<bool> deleteProduct(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.delete(id);
    });
  }

  static Future<void> relinkOrderItemsProductId({
    required int fromId,
    required int toId,
  }) async {
    if (fromId == toId) return;
    await _isar.writeTxn(() async {
      final items = await _isar.posOrderItems
          .filter()
          .productIdEqualTo(fromId)
          .findAll();
      for (final item in items) {
        item.productId = toId;
      }
      if (items.isNotEmpty) {
        await _isar.posOrderItems.putAll(items);
      }
    });
  }

  // ProductPrice methods
  static Future<int> createProductPrice(ProductPrice price) async {
    return await _isar.writeTxn(() async {
      return await _isar.productPrices.put(price);
    });
  }

  static Future<ProductPrice?> getProductPriceById(int id) async {
    return await _isar.productPrices.where().idEqualTo(id).findFirst();
  }

  static Future<List<ProductPrice>> getProductPricesByProduct(
    int productId,
  ) async {
    return await _isar.productPrices
        .filter()
        .productIdEqualTo(productId)
        .findAll();
  }

  static Future<ProductPrice?> getProductPriceByType(
    int productId,
    String type,
  ) async {
    final result = await _isar.productPrices
        .filter()
        .productIdEqualTo(productId)
        .and()
        .typeEqualTo(type)
        .findFirst();

    // Debug
    if (result != null) {
      appLogger.i(
        '   🔍 BDD: Trouvé price pour ID=$productId, type=$type => ${result.price}',
      );
    } else {
      appLogger.i('   🔍 BDD: PAS TROUVÉ pour ID=$productId, type=$type');
      // List all prices for this product
      final allPrices = await getProductPricesByProduct(productId);
      appLogger.i(
        '   📋 Tous les prix pour ce produit: ${allPrices.map((p) => '${p.type}=${p.price}').join(', ')}',
      );
    }

    return result;
  }

  static Future<List<ProductPrice>> getAllProductPrices() async {
    return await _isar.productPrices.where().findAll();
  }

  static Future<int> updateProductPrice(ProductPrice price) async {
    return await _isar.writeTxn(() async {
      return await _isar.productPrices.put(price);
    });
  }

  static Future<bool> deleteProductPrice(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.productPrices.delete(id);
    });
  }

  static Future<bool> deleteProductPricesByProduct(int productId) async {
    return await _isar.writeTxn(() async {
      final prices = await getProductPricesByProduct(productId);
      for (final price in prices) {
        await _isar.productPrices.delete(price.id);
      }
      return true;
    });
  }

  // POS Order methods
  static Future<int> createPosOrder(PosOrder order) async {
    return await _isar.writeTxn(() async {
      final savedId = await _isar.posOrders.put(order);
      if (order.channel.trim().toLowerCase() == 'pos' &&
          (order.sourceLocalId == null || order.sourceLocalId! <= 0)) {
        order
          ..id = savedId
          ..sourceLocalId = savedId;
        await _isar.posOrders.put(order);
      }
      return savedId;
    });
  }

  static Future<int> createPosOrderWithItems(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    return await _isar.writeTxn(() async {
      final savedId = await _isar.posOrders.put(order);
      if (order.channel.trim().toLowerCase() == 'pos' &&
          (order.sourceLocalId == null || order.sourceLocalId! <= 0)) {
        order
          ..id = savedId
          ..sourceLocalId = savedId;
        await _isar.posOrders.put(order);
      }

      // Create all items with the correct orderId
      for (final item in items) {
        item.orderId = savedId;
        await _isar.posOrderItems.put(item);
      }

      return savedId;
    });
  }

  static Future<int> updatePosOrder(PosOrder order) async {
    return await _isar.writeTxn(() async {
      // For POS orders, always ensure sourceLocalId matches the local ID
      // This prevents duplicate creation during API sync
      if (order.channel.trim().toLowerCase() == 'pos' && order.id > 0) {
        order.sourceLocalId = order.id;
      }
      return await _isar.posOrders.put(order);
    });
  }

  static Future<PosOrder?> getPosOrderById(int id) async {
    return await _isar.posOrders.where().idEqualTo(id).findFirst();
  }

  static Future<PosOrder?> getPosOrderBySourceLocalId(int sourceLocalId) async {
    try {
      return await _isar.posOrders
          .filter()
          .sourceLocalIdEqualTo(sourceLocalId)
          .findFirst();
    } catch (e) {
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e(
          '⚠️ [DB] PosOrder collection corruption detected in getPosOrderBySourceLocalId: $e',
        );
        return null;
      }
      rethrow;
    }
  }

  static Future<List<PosOrder>> getPosOrders({
    bool retryOnCorruption = true,
  }) async {
    try {
      return await _isar.posOrders.where().sortByCreatedAtDesc().findAll();
    } catch (e) {
      // Handle corrupted records
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e('⚠️ [DB] PosOrder collection corruption detected: $e');

        if (retryOnCorruption) {
          // Attempt to recover by clearing corrupted data
          appLogger.w('🗑️ [DB] Clearing corrupted PosOrder collection...');
          await _isar.writeTxn(() async {
            await _isar.posOrders.clear();
          });
          appLogger.i('✅ [DB] Corrupted PosOrder records cleared');
          // Return empty list instead of retrying to avoid infinite loop
          return [];
        }
      }
      rethrow;
    }
  }

  static Future<List<PosOrder>> getPosOrdersByStatus(String status) async {
    try {
      return await _isar.posOrders.filter().statusEqualTo(status).findAll();
    } catch (e) {
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e(
          '⚠️ [DB] PosOrder collection corruption detected in getPosOrdersByStatus: $e',
        );
        return [];
      }
      rethrow;
    }
  }

  static Future<List<PosOrder>> getPosOrdersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _isar.posOrders
          .filter()
          .createdAtBetween(start, end)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e(
          '⚠️ [DB] PosOrder collection corruption detected in getPosOrdersByDateRange: $e',
        );
        return [];
      }
      rethrow;
    }
  }

  static Future<List<PosOrder>> getPosOrdersByChannel(String channel) async {
    try {
      return await _isar.posOrders
          .filter()
          .channelEqualTo(channel, caseSensitive: false)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e(
          '⚠️ [DB] PosOrder collection corruption detected in getPosOrdersByChannel: $e',
        );
        return [];
      }
      rethrow;
    }
  }

  static Future<PosOrder?> findSimilarLocalPosOrder({
    required DateTime createdAt,
    required double totalPrice,
    String? tableNumber,
    String? fulfillmentType,
    String channel = 'pos',
    Duration tolerance = const Duration(seconds: 30),
    double totalTolerance = 0.01,
    String? customerPhone,
    int? sourceLocalId,
  }) async {
    if (sourceLocalId != null && sourceLocalId > 0) {
      final exact = await getPosOrderBySourceLocalId(sourceLocalId);
      if (exact != null &&
          exact.channel.trim().toLowerCase() == channel.trim().toLowerCase()) {
        return exact;
      }
    }

    var matchingSignals = 0;
    final normalizedTable = tableNumber?.trim();
    if (normalizedTable != null && normalizedTable.isNotEmpty) {
      matchingSignals += 1;
    }
    final normalizedFulfillment = fulfillmentType?.trim();
    if (normalizedFulfillment != null && normalizedFulfillment.isNotEmpty) {
      matchingSignals += 1;
    }
    final normalizedPhone = customerPhone?.trim().replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      matchingSignals += 1;
    }
    if (matchingSignals < 2) {
      return null;
    }

    final start = createdAt.subtract(tolerance);
    final end = createdAt.add(tolerance);
    final lowerTotal = totalPrice - totalTolerance;
    final upperTotal = totalPrice + totalTolerance;

    var query = _isar.posOrders
        .filter()
        .channelEqualTo(channel, caseSensitive: false)
        .createdAtBetween(start, end)
        .totalPriceBetween(lowerTotal, upperTotal);

    if (normalizedTable != null && normalizedTable.isNotEmpty) {
      query = query.tableNumberEqualTo(normalizedTable);
    }
    if (normalizedFulfillment != null && normalizedFulfillment.isNotEmpty) {
      query = query.fulfillmentTypeEqualTo(normalizedFulfillment);
    }

    final results = await query.findAll();

    PosOrder? bestMatch;
    Duration? bestDelta;
    for (final order in results) {
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        final orderPhone = (order.customerPhone ?? '').trim().replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );
        if (orderPhone != normalizedPhone) {
          continue;
        }
      }
      final delta = order.createdAt.isAfter(createdAt)
          ? order.createdAt.difference(createdAt)
          : createdAt.difference(order.createdAt);
      if (bestDelta == null || delta < bestDelta) {
        bestMatch = order;
        bestDelta = delta;
      }
    }
    return bestMatch;
  }

  // POS Order Item methods
  static Future<int> createPosOrderItem(PosOrderItem item) async {
    appLogger.i(
      '📝 [DB] Creating PosOrderItem: orderId=${item.orderId}, product=${item.productName}',
    );
    final result = await _isar.writeTxn(() async {
      return await _isar.posOrderItems.put(item);
    });
    appLogger.i('📝 [DB] PosOrderItem created with id=$result');
    return result;
  }

  static Future<List<PosOrderItem>> getPosOrderItems(int orderId) async {
    final items = await _isar.posOrderItems
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();
    appLogger.i(
      '📦 [DB] getPosOrderItems(orderId=$orderId): ${items.length} items',
    );
    if (items.isEmpty) {
      // Debug: check all items in database
      final allItems = await _isar.posOrderItems.where().findAll();
      appLogger.i('📦 [DB] Total items in DB: ${allItems.length}');
      if (allItems.isNotEmpty) {
        final orderIds = allItems.map((i) => i.orderId).toSet().toList()
          ..sort();
        appLogger.i('📦 [DB] Existing orderIds: $orderIds');
      }
    }
    return items;
  }

  static Future<List<PosOrderItem>> getAllPosOrderItems() async {
    return await _isar.posOrderItems.where().findAll();
  }

  static Future<int> updatePosOrderItem(PosOrderItem item) async {
    return await _isar.writeTxn(() async {
      return await _isar.posOrderItems.put(item);
    });
  }

  static Future<bool> deletePosOrder(int orderId) async {
    appLogger.d('🗑️ [DB] deletePosOrder(orderId=$orderId)');
    try {
      return await _isar.writeTxn(() async {
        // Delete related items within the same transaction to avoid nesting
        final items = await _isar.posOrderItems
            .filter()
            .orderIdEqualTo(orderId)
            .findAll();
        final ids = items.map((e) => e.id).toList();
        final deletedCount = ids.isNotEmpty
            ? await _isar.posOrderItems.deleteAll(ids)
            : 0;

        final deletedOrder = await _isar.posOrders.delete(orderId);
        return (ids.isEmpty || deletedCount == ids.length) && deletedOrder;
      });
    } catch (e, st) {
      // Handle nested transaction attempts: if we're already inside a txn,
      // perform the deletes directly (they will run in the existing txn).
      final msg = e.toString().toLowerCase();
      if (msg.contains('nested') || msg.contains('active transaction')) {
        appLogger.w(
          '⚠️ [DB] deletePosOrder detected nested transaction; falling back to direct deletes',
        );
        final items = await _isar.posOrderItems
            .filter()
            .orderIdEqualTo(orderId)
            .findAll();
        final ids = items.map((e) => e.id).toList();
        final deletedCount = ids.isNotEmpty
            ? await _isar.posOrderItems.deleteAll(ids)
            : 0;
        final deletedOrder = await _isar.posOrders.delete(orderId);
        return (ids.isEmpty || deletedCount == ids.length) && deletedOrder;
      }
      appLogger.e('❌ [DB] deletePosOrder error', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<bool> deletePosOrderItems(int orderId) async {
    appLogger.d('🗑️ [DB] deletePosOrderItems(orderId=$orderId)');
    try {
      return await _isar.writeTxn(() async {
        final items = await _isar.posOrderItems
            .filter()
            .orderIdEqualTo(orderId)
            .findAll();
        final ids = items.map((e) => e.id).toList();
        final deletedCount = await _isar.posOrderItems.deleteAll(ids);
        return deletedCount == ids.length;
      });
    } catch (e, st) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('nested') || msg.contains('active transaction')) {
        appLogger.w(
          '⚠️ [DB] deletePosOrderItems detected nested transaction; falling back to direct deletes',
        );
        final items = await _isar.posOrderItems
            .filter()
            .orderIdEqualTo(orderId)
            .findAll();
        final ids = items.map((e) => e.id).toList();
        final deletedCount = await _isar.posOrderItems.deleteAll(ids);
        return deletedCount == ids.length;
      }
      appLogger.e('❌ [DB] deletePosOrderItems error', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<double> getStaffDailySales(int staffId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final orders = await _isar.posOrders
        .filter()
        .staffIdEqualTo(staffId)
        .createdAtBetween(start, end)
        .findAll();
    return orders.fold<double>(0.0, (sum, o) => sum + o.totalPrice);
  }

  // POS Tables
  static Future<List<PosTable>> getPosTables() async {
    return await _isar.posTables.where().sortByNumber().findAll();
  }

  static Future<List<PosTable>> getPosTablesByRestaurant(
    int restaurantId,
  ) async {
    return await _isar.posTables
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .sortByNumber()
        .findAll();
  }

  static Future<PosTable?> getPosTableByRemoteId(int remoteId) async {
    return await _isar.posTables.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  static Future<PosTable?> getPosTableByNumberAndRestaurant(
    String number,
    int? restaurantId,
  ) async {
    return await _isar.posTables
        .filter()
        .numberEqualTo(number)
        .restaurantIdEqualTo(restaurantId)
        .findFirst();
  }

  static Future<int> createPosTable(PosTable table) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.put(table);
    });
  }

  static Future<int> updatePosTable(PosTable table) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.put(table);
    });
  }

  static Future<bool> deletePosTable(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.delete(id);
    });
  }

  static Future<bool> deletePosTableByRemoteId(int remoteId) async {
    return await _isar.writeTxn(() async {
      final table = await _isar.posTables
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      if (table == null) return false;
      return await _isar.posTables.delete(table.id);
    });
  }

  // Clear local POS/catalog data while keeping users for login access.
  static Future<void> clearLocalBusinessData() async {
    await _isar.writeTxn(() async {
      await _isar.posOrderItems.clear();
      await _isar.posOrders.clear();
      await _isar.posTables.clear();
      await _isar.products.clear();
      await _isar.categorys.clear();
      await _isar.restaurants.clear();
    });
  }

  // ✅ Clear ALL local data EXCEPT superadmin users
  static Future<void> clearAllDataExceptSuperadmins() async {
    // Debug: clearAllDataExceptSuperadmins called
    // appLogger.i('🗑️ clearAllDataExceptSuperadmins() called');

    await _isar.writeTxn(() async {
      // Keep only superadmin users
      // appLogger.i('📊 Fetching all users...');
      final allUsers = await _isar.users.where().findAll();
      // appLogger.i('📊 Total users found: ${allUsers.length}');

      // ignore: unused_local_variable
      int deletedCount = 0;
      for (final user in allUsers) {
        if (user.role != 'superadmin') {
          // appLogger.i('🗑️ Deleting user: ${user.name} (${user.role})');
          await _isar.users.delete(user.id);
          deletedCount++;
        } else {
          // appLogger.i('✅ Keeping superadmin: ${user.name}');
        }
      }

      // appLogger.i('✅ Deleted $deletedCount non-admin users');

      // Clear all other data
      // appLogger.i('🗑️ Clearing posOrderItems...');
      await _isar.posOrderItems.clear();
      // appLogger.i('🗑️ Clearing posOrders...');
      await _isar.posOrders.clear();
      // appLogger.i('🗑️ Clearing posTables...');
      await _isar.posTables.clear();
      // appLogger.i('🗑️ Clearing products...');
      await _isar.products.clear();
      // appLogger.i('🗑️ Clearing productPrices...');
      await _isar.productPrices.clear();
      // appLogger.i('🗑️ Clearing categorys...');
      await _isar.categorys.clear();
      // appLogger.i('🗑️ Clearing restaurants...');
      await _isar.restaurants.clear();
      // appLogger.i('🗑️ Clearing deliverys...');
      await _isar.deliverys.clear();
      // appLogger.i('🗑️ Clearing orderDeliverys...');
      await _isar.orderDeliverys.clear();
      // appLogger.i('🗑️ Clearing customers...');
      await _isar.customers.clear();
    });

    // appLogger.i('✅ All local data cleared except superadmin users');
  }

  // Delivery methods
  static Future<int> createDelivery(Delivery delivery) async {
    return await _isar.writeTxn(() async {
      return await _isar.deliverys.put(delivery);
    });
  }

  static Future<Delivery?> getDeliveryById(int id) async {
    return await _isar.deliverys.where().idEqualTo(id).findFirst();
  }

  static Future<Delivery?> getDeliveryByEmail(String email) async {
    return await _isar.deliverys.filter().emailEqualTo(email).findFirst();
  }

  static Future<Delivery?> getDeliveryByPhone(String phone) async {
    return await _isar.deliverys.filter().phoneEqualTo(phone).findFirst();
  }

  static Future<List<Delivery>> getAllDeliveries() async {
    return await _isar.deliverys.where().findAll();
  }

  static Future<List<Delivery>> getDeliveriesByRestaurant(
    int restaurantId,
  ) async {
    return await _isar.deliverys
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .findAll();
  }

  static Future<int> updateDelivery(Delivery delivery) async {
    return await _isar.writeTxn(() async {
      return await _isar.deliverys.put(delivery);
    });
  }

  static Future<bool> deleteDelivery(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.deliverys.delete(id);
    });
  }

  // OrderDelivery methods
  static Future<int> createOrderDelivery(OrderDelivery delivery) async {
    return await _isar.writeTxn(() async {
      return await _isar.orderDeliverys.put(delivery);
    });
  }

  static Future<int> upsertOrderDeliveryByOrderId(
    OrderDelivery delivery,
  ) async {
    return await _isar.writeTxn(() async {
      final existing = await _isar.orderDeliverys
          .filter()
          .orderIdEqualTo(delivery.orderId)
          .findFirst();
      if (existing != null) {
        delivery.id = existing.id;
      }
      return await _isar.orderDeliverys.put(delivery);
    });
  }

  static Future<OrderDelivery?> getOrderDeliveryByOrderId(int orderId) async {
    return await _isar.orderDeliverys
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();
  }

  static Future<List<OrderDelivery>> getOrderDeliveriesByStatus(
    String status,
  ) async {
    return await _isar.orderDeliverys.filter().statusEqualTo(status).findAll();
  }

  static Future<List<OrderDelivery>> getAllOrderDeliveries() async {
    return await _isar.orderDeliverys.where().findAll();
  }

  static Future<int> updateOrderDelivery(OrderDelivery delivery) async {
    return await _isar.writeTxn(() async {
      return await _isar.orderDeliverys.put(delivery);
    });
  }

  static Future<bool> deleteOrderDelivery(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.orderDeliverys.delete(id);
    });
  }

  /// Assigner un livreur à une commande de livraison (tous canaux : POS, API, Web, etc.)
  /// Cette méthode met à jour la commande ET crée/mise à jour l'enregistrement OrderDelivery
  static Future<OrderDelivery?> assignLivreurToDelivery({
    required PosOrder order,
    required int livreurId,
    String? livreurName,
    String? livreurPhone,
  }) async {
    // Vérifier que c'est une commande de livraison
    if (order.fulfillmentType != 'delivery') {
      appLogger.w(
        'Cannot assign livreur to non-delivery order #${order.id} (channel: ${order.channel})',
      );
      return null;
    }

    try {
      // Mettre à jour la commande avec les infos du livreur
      order.deliveryLivreurId = livreurId;
      order.deliveryLivreurName = livreurName;
      order.deliveryLivreurPhone = livreurPhone;
      order.updatedAt = DateTime.now();
      await updatePosOrder(order);

      // Vérifier s'il existe déjà un enregistrement OrderDelivery
      OrderDelivery? delivery = await getOrderDeliveryByOrderId(order.id);

      if (delivery != null) {
        // Mettre à jour l'enregistrement existant
        delivery.livreurId = livreurId;
        delivery.livreurName = livreurName;
        delivery.livreurPhone = livreurPhone;
        delivery.status = 'assigned';
        delivery.assignedAt = DateTime.now();
        delivery.updatedAt = DateTime.now();
        await updateOrderDelivery(delivery);
      } else {
        // Créer un nouvel enregistrement OrderDelivery
        delivery = OrderDelivery(
          orderId: order.id,
          livreurId: livreurId,
          livreurName: livreurName,
          livreurPhone: livreurPhone,
          status: 'assigned',
          assignedAt: DateTime.now(),
          pickedUpAt: null,
          deliveredAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createOrderDelivery(delivery);
      }

      appLogger.i(
        '✅ Livreur #$livreurId assigned to delivery order #${order.id} (channel: ${order.channel})',
      );
      return delivery;
    } catch (e) {
      appLogger.e('Error assigning livreur to delivery: $e');
      return null;
    }
  }

  /// Obtenir toutes les commandes de livraison (avec ou sans livreur) pour un jour donné
  /// Utilisé pour l'écran d'assignation des livreurs
  static Future<List<PosOrder>> getAllDeliveryOrders({DateTime? date}) async {
    final now = date ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = start.add(const Duration(days: 1));

    final orders = await getPosOrders();
    final deliveryOrders = orders.where((o) {
      final isDelivery = o.fulfillmentType == 'delivery';
      final isToday = !o.createdAt.isBefore(start) && o.createdAt.isBefore(end);
      return isDelivery && isToday;
    }).toList();

    return deliveryOrders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Customer methods
  static Future<int> createCustomer(Customer customer) async {
    return await _isar.writeTxn(() async {
      return await _isar.customers.put(customer);
    });
  }

  static Future<Customer?> getCustomerByPhone(String phone) async {
    return await _isar.customers.filter().phoneEqualTo(phone).findFirst();
  }

  static Future<Customer?> getCustomerById(int id) async {
    return await _isar.customers.get(id);
  }

  static Future<List<Customer>> searchCustomers(String query) async {
    // Get all staff/livreur users to exclude from customer list
    final allUsers = await _isar.users.where().findAll();
    final excludedPhones = allUsers
        .where(
          (u) =>
              u.role == 'staff' || u.role == 'livreur' || u.role == 'delivery',
        )
        .map((u) => u.phone)
        .toSet();
    final excludedEmails = allUsers
        .where(
          (u) =>
              u.role == 'staff' || u.role == 'livreur' || u.role == 'delivery',
        )
        .map((u) => u.email.toLowerCase())
        .toSet();

    if (query.trim().isEmpty) {
      final all = await _isar.customers.where().findAll();
      final filtered = all.where((c) {
        // Exclude customers with phone matching staff/livreur
        if (excludedPhones.contains(c.phone)) return false;
        // Exclude customers with email matching staff/livreur
        if (c.email != null &&
            excludedEmails.contains(c.email!.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
      filtered.sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
      return filtered.take(20).toList();
    }
    final normalizedQuery = query.trim().toLowerCase();
    final allCustomers = await _isar.customers.where().findAll();
    final filtered = allCustomers.where((c) {
      // Exclude customers with phone matching staff/livreur
      if (excludedPhones.contains(c.phone)) return false;
      // Exclude customers with email matching staff/livreur
      if (c.email != null && excludedEmails.contains(c.email!.toLowerCase())) {
        return false;
      }
      // Apply search filter
      return c.name.toLowerCase().contains(normalizedQuery) ||
          c.phone.contains(normalizedQuery);
    }).toList()..sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
    return filtered.take(20).toList();
  }

  static Future<List<Customer>> getAllCustomers() async {
    // Get all staff/livreur users to exclude from customer list
    final allUsers = await _isar.users.where().findAll();
    final excludedPhones = allUsers
        .where(
          (u) =>
              u.role == 'staff' || u.role == 'livreur' || u.role == 'delivery',
        )
        .map((u) => u.phone)
        .toSet();
    final excludedEmails = allUsers
        .where(
          (u) =>
              u.role == 'staff' || u.role == 'livreur' || u.role == 'delivery',
        )
        .map((u) => u.email.toLowerCase())
        .toSet();

    final all = await _isar.customers.where().findAll();
    final filtered = all.where((c) {
      // Exclude customers with phone matching staff/livreur
      if (excludedPhones.contains(c.phone)) return false;
      // Exclude customers with email matching staff/livreur
      if (c.email != null && excludedEmails.contains(c.email!.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    return filtered..sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
  }

  static Future<int> updateCustomer(Customer customer) async {
    return await _isar.writeTxn(() async {
      return await _isar.customers.put(customer);
    });
  }

  static Future<bool> deleteCustomer(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.customers.delete(id);
    });
  }

  static Future<void> updateCustomerStats({
    required int customerId,
    required double amountSpent,
  }) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final updated = customer.copyWith(
        orderCount: customer.orderCount + 1,
        totalSpent: customer.totalSpent + amountSpent,
        lastOrderDate: DateTime.now(),
      );
      await updateCustomer(updated);
    }
  }

  // Get POS orders by staff and date
  // Includes orders created by staff OR paid by staff
  static Future<List<PosOrder>> getPosOrdersByStaffAndDate(
    int staffId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      // Récupérer toutes les commandes de la journée
      final allOrders = await _isar.posOrders
          .filter()
          .createdAtBetween(startOfDay, endOfDay)
          .findAll();

      // Filtrer en mémoire: commandes créées OU payées par le staff
      final filteredOrders = allOrders.where((order) {
        return (order.staffId == staffId || order.paidByStaffId == staffId) &&
            order.status != 'cancelled';
      }).toList();

      return filteredOrders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (e is RangeError ||
          (e.toString().contains('RangeError') ||
              e.toString().contains('Utf8Decoder'))) {
        appLogger.e(
          '⚠️ [DB] PosOrder collection corruption detected in getPosOrdersByStaffAndDate: $e',
        );
        return [];
      }
      rethrow;
    }
  }
}
