import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:caisse_1/api/api_client.dart';
import 'package:caisse_1/services/auth_session_service.dart';
import 'package:caisse_1/utils/order_item_grouping.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import 'category_controller.dart';
import 'delivery_controller.dart';
import 'import_controller.dart';
import 'product_controller.dart';
import 'restaurant_controller.dart';
import '../models/category_model.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/product_model.dart';
import '../models/pos_table.dart';
import '../models/user.dart';
import '../models/order_delivery.dart';
import '../models/customer.dart';
import '../services/api_import_service.dart';
import '../services/api_order_pull_service.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import 'cash_register_controller.dart';
import '../services/sync_queue_service.dart';
import '../services/order_delivery_api_service.dart';
import '../services/notification_sound_service.dart';
import '../utils/app_logger.dart';
import '../utils/badge_code_utils.dart';
import '../utils/payment_method_utils.dart';
import 'sync_controller.dart';

class CartItem {
  final Product product;
  int quantity;
  String? priceType; // 'glovo', 'restaurant', 'retail', or null for default
  double? customPrice; // Custom price if set
  double? basePrice; // Base price (for Glovo: prix de base)
  // Champs ajoutés pour supporter les fonctionnalités étendues
  String? itemNote;
  int? groupNumber;
  String? serviceCourseKey;
  String? serviceCourseLabel;

  CartItem({
    required this.product,
    required this.quantity,
    this.priceType,
    this.customPrice,
    this.basePrice,
    this.itemNote,
    this.groupNumber,
    this.serviceCourseKey,
    this.serviceCourseLabel,
  });

  /// Get the unit price based on priceType or customPrice
  double get unitPrice {
    // If customPrice is set, use it (this is the case when Glovo toggle is on)
    if (customPrice != null) return customPrice!;

    // Otherwise use the base product price
    return product.price;
  }

  double get lineTotal => unitPrice * quantity;
}

class _PinUnlockBootstrap {
  const _PinUnlockBootstrap({required this.staff, this.token});

  final User staff;
  final String? token;
}

class _OrderEditSnapshot {
  const _OrderEditSnapshot({
    required this.originalOrder,
    required this.originalItems,
    required this.originalUpdatedAt,
    required this.originalTotal,
    required this.canEditCustomerData,
    required this.canEditConfiguration,
  });

  final PosOrder originalOrder;
  final List<PosOrderItem> originalItems;
  final DateTime originalUpdatedAt;
  final double originalTotal;
  final bool canEditCustomerData;
  final bool canEditConfiguration;

  int get originalLineCount => originalItems.length;
}

class PosController extends GetxController {
  User? _activeStaff;
  User? get activeStaff => _activeStaff;
  int? _activeStaffId;
  int? _restaurantId;
  String? _restaurantName;
  int? get activeStaffId => _activeStaffId;
  int? get restaurantId => _restaurantId;
  String get restaurantName => _restaurantName ?? '';
  String get restaurantLabel {
    if (_restaurantName != null && _restaurantName!.trim().isNotEmpty) {
      return _restaurantName!;
    }
    if (_restaurantId != null) {
      return 'Restaurant ${_restaurantId!}';
    }
    return 'Restaurant -';
  }

  String _fulfillmentType = 'on_site';
  String get fulfillmentType => _fulfillmentType;

  String? _tableNumber;
  String? get tableNumber => _tableNumber;

  String? _customerName;
  String? get customerName => _customerName;
  String? _customerPhone;
  String? get customerPhone => _customerPhone;
  String? _deliveryAddress;
  String? get deliveryAddress => _deliveryAddress;
  int? _deliveryLivreurId;
  int? get deliveryLivreurId => _deliveryLivreurId;
  String? _deliveryLivreurName;
  String? get deliveryLivreurName => _deliveryLivreurName;
  String? _deliveryLivreurPhone;
  String? get deliveryLivreurPhone => _deliveryLivreurPhone;
  String? _note;
  String? get note => _note;

  // Customer selection
  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;
  bool _isCreatingNewCustomer = false;
  bool get isCreatingNewCustomer => _isCreatingNewCustomer;
  final RxList<Customer> _customerSearchResults = <Customer>[].obs;
  List<Customer> get customerSearchResults => _customerSearchResults;

  String? _paymentMethod;
  String? get paymentMethod => _paymentMethod;

  /// Glovo delivery flag
  bool _isGlovoDelivery = false;
  bool get isGlovoDelivery => _isGlovoDelivery;

  final List<CartItem> _cart = [];
  List<CartItem> get cart => List<CartItem>.unmodifiable(_cart);

  // ✅ Gestion des groupes/ensembles
  final List<int> _cartGroups = [];
  List<int> get cartGroups => List<int>.unmodifiable(_cartGroups);
  int? _activeGroupNumber;
  int? get activeGroupNumber => _activeGroupNumber;
  String? get activeGroupLabel => _activeGroupNumber == null
      ? null
      : formatGuestGroupLabel(groupNumber: _activeGroupNumber);

  // ✅ Méthode pour créer un nouveau groupe/ensemble
  void createNewCartGroup() {
    int nextGroup;
    if (_cartGroups.isEmpty) {
      nextGroup = 1;
    } else {
      nextGroup = _cartGroups.reduce(math.max) + 1;
    }
    _cartGroups.add(nextGroup);
    _activeGroupNumber = nextGroup;
    update();
  }

  final List<PosOrder> _ordersToday = [];
  List<PosOrder> get ordersToday => List<PosOrder>.unmodifiable(_ordersToday);

  // Filters
  String _ordersFilter = 'all'; // all | pending | confirmed | cancelled
  String get ordersFilter => _ordersFilter;

  String _ordersChannelFilter = 'all'; // all | pos | remote (api/web/kiosk)
  String get ordersChannelFilter => _ordersChannelFilter;

  String _ordersFulfillmentFilter = 'all'; // all | on_site | pickup
  String get ordersFulfillmentFilter => _ordersFulfillmentFilter;

  final List<PosTable> _tables = [];
  List<PosTable> get tables => List<PosTable>.unmodifiable(_tables);

  int? _editingOrderId;
  int? get editingOrderId => _editingOrderId;

  String? _error;
  String? get error => _error;

  bool _isCreatingOrder = false;
  bool get isCreatingOrder => _isCreatingOrder;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;
  Timer? _postCreateSyncTimer;
  _OrderEditSnapshot? _orderEditSnapshot;

  bool get isLocked => _activeStaff == null;
  bool get canEditOrders =>
      _activeStaff != null &&
      (_activeStaff!.role == 'staff' ||
          _activeStaff!.role == 'admin' ||
          _activeStaff!.role == 'superadmin');
  bool get canModifyOrders =>
      _activeStaff != null &&
      (_activeStaff!.role == 'admin' || _activeStaff!.role == 'superadmin');
  bool get isAdminEditor {
    final role = (_activeStaff?.role ?? '').trim().toLowerCase();
    return role == 'admin' || role == 'superadmin';
  }

  bool get isEditingExistingOrder => _orderEditSnapshot != null;
  bool get canEditCurrentOrderConfiguration =>
      _orderEditSnapshot?.canEditConfiguration ?? true;
  bool get canEditCurrentOrderCustomerData =>
      _orderEditSnapshot?.canEditCustomerData ??
      (_fulfillmentType == 'pickup' || _fulfillmentType == 'delivery');

  // ✅ Vérification de propriété d'une commande
  bool canAccessOrder(PosOrder order) {
    if (_activeStaff == null) return false;
    // Admins peuvent tout voir
    if (isAdminEditor) return true;

    // ✅ FIX: Les commandes API/Web/Kiosk sont accessibles par TOUS les staffs
    // Ces commandes viennent de sources externes et ne sont pas assignées à un staff spécifique
    if (_isRemoteChannel(order.channel)) {
      return true;
    }

    // Staff ne voit que ses commandes POS (staffId correspond)
    return order.staffId == _activeStaff!.id;
  }

  String? get editingSummaryLabel {
    final snapshot = _orderEditSnapshot;
    if (snapshot == null) return null;
    final label = snapshot.originalLineCount <= 1 ? 'produit' : 'produits';
    return '${snapshot.originalLineCount} $label dans la commande actuelle';
  }

  @override
  void onClose() {
    _postCreateSyncTimer?.cancel();
    super.onClose();
  }

  /// Réinitialise tous les états après la fermeture de caisse
  void resetAfterCashRegisterClose() {
    // Vider le panier
    _cart.clear();

    // Vider les commandes du jour
    _ordersToday.clear();

    // Réinitialiser les variables d'état
    _fulfillmentType = 'on_site';
    _tableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    _deliveryLivreurId = null;
    _deliveryLivreurName = null;
    _deliveryLivreurPhone = null;
    _note = null;
    _selectedCustomer = null;
    _isCreatingNewCustomer = false;
    _customerSearchResults.assignAll([]);
    _paymentMethod = null;
    _isGlovoDelivery = false;

    // Réinitialiser les filtres
    _ordersFilter = 'all';

    // Notifier les observateurs
    update();
  }

  bool _isRemoteChannel(String rawChannel) {
    final channel = rawChannel.trim().toLowerCase();
    switch (channel) {
      case 'api':
      case 'web':
      case 'website':
      case 'site':
      case 'online':
      case 'mobile':
      case 'mobile_app':
      case 'app':
      case 'android':
      case 'ios':
      case 'kiosk':
      case 'borne':
        return true;
      default:
        return false;
    }
  }

  bool _isPosChannelOrder(PosOrder order) {
    return order.channel.trim().toLowerCase() == 'pos';
  }

  bool _isSameDayOrder(PosOrder order) {
    final now = DateTime.now();
    return order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
  }

  bool _isStaffContentEditAllowed(PosOrder order) {
    final status = order.status.trim().toLowerCase();
    final paymentStatus = order.paymentStatus.trim().toLowerCase();
    if (paymentStatus == 'paid') {
      return false;
    }
    return _isSameDayOrder(order) &&
        (status == 'pending' || status == 'confirmed');
  }

  bool canEditOrderContent(PosOrder order) {
    if (!canEditOrders || !_isPosChannelOrder(order)) {
      return false;
    }
    if (isAdminEditor) {
      return true;
    }
    return _isStaffContentEditAllowed(order);
  }

  bool canEditOrderCustomerData(PosOrder order) {
    if (!canEditOrderContent(order)) {
      return false;
    }
    if (isAdminEditor) {
      return true;
    }
    final type = order.fulfillmentType.trim().toLowerCase();
    return type == 'pickup' || type == 'delivery';
  }

  bool canEditOrderConfiguration(PosOrder order) {
    return isAdminEditor && _isPosChannelOrder(order);
  }

  bool canOpenAdvancedOrderEditor(PosOrder order) {
    return canEditOrderConfiguration(order);
  }

  String _orderEditRestrictionReason(
    PosOrder order, {
    required bool forContent,
  }) {
    if (!_isPosChannelOrder(order)) {
      return 'Seules les commandes POS sont modifiables depuis cet écran';
    }
    if (isAdminEditor) {
      return 'Modification non autorisée';
    }
    if (!_isSameDayOrder(order)) {
      return 'Le serveur peut modifier seulement les commandes du jour';
    }
    if (order.paymentStatus.trim().toLowerCase() == 'paid') {
      return 'Commande non modifiable car déjà payée';
    }
    final status = order.status.trim().toLowerCase();
    if (status != 'pending' && status != 'confirmed') {
      return forContent
          ? 'Le serveur peut modifier seulement les commandes POS en attente ou confirmées'
          : 'Modification non autorisée pour ce statut';
    }
    return 'Modification non autorisée';
  }

  PosOrder _copyPosOrder(PosOrder order) {
    return PosOrder(
      id: order.id,
      staffId: order.staffId,
      restaurantId: order.restaurantId,
      sourceLocalId: order.sourceLocalId,
      channel: order.channel,
      fulfillmentType: order.fulfillmentType,
      status: order.status,
      totalPrice: order.totalPrice,
      originalTotal: order.originalTotal,
      discountAmount: order.discountAmount,
      hasDiscount: order.hasDiscount,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      tableNumber: order.tableNumber,
      note: order.note,
      rewardId: order.rewardId,
      cancelReason: order.cancelReason,
      isGlovoDelivery: order.isGlovoDelivery,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  PosOrderItem _copyPosOrderItem(PosOrderItem item) {
    return PosOrderItem(
      id: item.id,
      orderId: item.orderId,
      productId: item.productId,
      productName: item.productName,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      groupNumber: item.groupNumber,
      groupLabel: item.groupLabel,
      itemNote: item.itemNote,
      serviceCourseKey: item.serviceCourseKey,
      serviceCourseLabel: item.serviceCourseLabel,
      priceType: item.priceType,
      glovoBasePrice: item.glovoBasePrice,
      createdAt: item.createdAt,
    );
  }

  Future<PosOrder?> _reloadOrderForEditionCheck({
    required int orderId,
    required DateTime expectedUpdatedAt,
  }) async {
    await DatabaseService.init();
    final currentOrder = await DatabaseService.getPosOrderById(orderId);
    if (currentOrder == null) {
      _error = 'Commande introuvable';
      update();
      return null;
    }
    if (!currentOrder.updatedAt.isAtSameMomentAs(expectedUpdatedAt)) {
      _error =
          'Cette commande a été modifiée sur un autre poste. Rechargez puis recommencez.';
      update();
      return null;
    }
    return currentOrder;
  }

  Future<void> _applyEditedOrderTableChanges({
    required PosOrder previousOrder,
    required PosOrder updatedOrder,
  }) async {
    final oldTable = previousOrder.tableNumber?.trim();
    final newTable = updatedOrder.tableNumber?.trim();
    final oldType = previousOrder.fulfillmentType.trim().toLowerCase();
    final newType = updatedOrder.fulfillmentType.trim().toLowerCase();

    if (oldType == 'on_site' &&
        oldTable != null &&
        oldTable.isNotEmpty &&
        (newType != 'on_site' || oldTable != newTable)) {
      await markTableFree(oldTable);
    }
    if (newType == 'on_site' &&
        newTable != null &&
        newTable.isNotEmpty &&
        (oldType != 'on_site' || oldTable != newTable)) {
      await markTableOccupied(newTable);
    }
  }

  Future<void> _enqueueOrderSyncById(int orderId) async {
    final order = await DatabaseService.getPosOrderById(orderId);
    if (order == null) return;

    // Les commandes distantes utilisent une synchro de statut dédiée.
    if (_isRemoteChannel(order.channel)) {
      appLogger.d(
        '🔄 [ENQUEUE] Order #${order.id} is remote channel, using status sync',
      );
      return;
    }

    final items = await DatabaseService.getPosOrderItems(orderId);
    await SyncQueueService.instance.enqueueOrderUpsert(order, items);
  }

  /// Synchroniser le statut d'une commande API/Web/Kiosk vers le backend
  Future<bool> syncApiOrderStatusToBackend({required PosOrder order}) async {
    final channel = order.channel.trim().toLowerCase();
    if (!_isRemoteChannel(channel)) {
      return false;
    }

    final syncService = SyncQueueService.instance;
    return await syncService.syncApiOrderStatus(
      order: order,
      status: order.status,
      paymentStatus: order.paymentStatus,
      cancelReason: order.cancelReason,
    );
  }

  Future<void> _scheduleImmediateOrderSync() async {
    if (!Get.isRegistered<SyncController>()) {
      appLogger.w(
        '⚠️ [SYNC] SyncController not registered, skipping immediate sync',
      );
      return;
    }
    _postCreateSyncTimer?.cancel();
    _postCreateSyncTimer = Timer(const Duration(milliseconds: 700), () async {
      _postCreateSyncTimer = null;
      try {
        final sync = Get.find<SyncController>();
        if (!sync.isOnline) {
          appLogger.w('⚠️ [SYNC] Offline, scheduling retry in 5 seconds');
          // Retry after 5 seconds if offline
          Timer(const Duration(seconds: 5), () async {
            try {
              final sync2 = Get.find<SyncController>();
              if (sync2.isOnline) {
                await sync2.syncNow();
              } else {
                appLogger.e(
                  '❌ [SYNC] Still offline after retry, order will sync later',
                );
              }
            } catch (e, st) {
              appLogger.e('❌ [SYNC] Retry failed', error: e, stackTrace: st);
            }
          });
          return;
        }
        await sync.syncNow();
        appLogger.i('✅ [SYNC] Immediate sync completed');
      } catch (e, st) {
        appLogger.e(
          '❌ [SYNC] Immediate sync failed, will retry on next periodic sync',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<bool> unlockWithPin(String pin) async {
    _error = null;
    final normalized = pin.trim();
    if (normalized.length < 4 ||
        normalized.length > 6 ||
        !RegExp(r'^\d+$').hasMatch(normalized)) {
      _error = 'Code PIN invalide';
      update();
      return false;
    }
    String? token;
    var staff = await DatabaseService.getStaffByPin(normalized);
    if (staff == null) {
      final recovered = await _bootstrapStaffFromBackendPin(normalized);
      staff = recovered?.staff;
      token = recovered?.token;
    }
    if (staff == null) {
      _error = 'Code PIN invalide';
      update();
      return false;
    }

    // ✅ Vérifier que le serveur appartient au restaurant importé
    if (!_isUserAllowedForCurrentRestaurant(staff)) {
      _error = 'Accès refusé : Ce serveur appartient à un autre restaurant.';
      update();
      return false;
    }

    await _activateUnlockedStaff(staff);

    // Tentative de login Sanctum via PIN pour activer la sync
    try {
      token ??= await _resolvePinSyncToken(pin: normalized, staff: staff);
      if (token != null && token.isNotEmpty) {
        await _applyAuthenticatedPinSession(
          token: token,
          email: staff.email,
          pin: normalized,
        );
        appLogger.d('✅ Session PIN authentifiée avec token backend');
      } else {
        // Fallback: utiliser un token local pour la sync locale
        appLogger.w('⚠️ Pas de token backend, utilisation d\'un token local');
        await _applyLocalPinSession(email: staff.email, pin: normalized);
      }
    } catch (e) {
      appLogger.e('❌ Erreur session PIN: $e');
      // Fallback: utiliser un token local pour la sync locale
      await _applyLocalPinSession(email: staff.email, pin: normalized);
    }
    update();
    return true;
  }

  Future<bool> unlockWithBadge(String badgeCode) async {
    _error = null;
    final normalized = normalizeBadgeCode(badgeCode);
    if (normalized.isEmpty) {
      _error = 'Badge invalide';
      update();
      return false;
    }

    final staff = await DatabaseService.getStaffByBadgeCode(normalized);
    if (staff == null) {
      _error = 'Badge inconnu';
      update();
      return false;
    }

    if (!_isUserAllowedForCurrentRestaurant(staff)) {
      _error = 'Accès refusé : Ce serveur appartient à un autre restaurant.';
      update();
      return false;
    }

    await _activateUnlockedStaff(staff);

    try {
      await _restoreSessionForBadgeUnlock(staff);
    } catch (e) {
      appLogger.e('❌ Erreur session badge: $e');
      await _applyLocalBadgeSession(email: staff.email, badgeCode: normalized);
    }

    update();
    return true;
  }

  Future<void> _activateUnlockedStaff(User staff) async {
    _activeStaff = staff;
    _activeStaffId = staff.id;
    _restaurantId = staff.restaurantId;
    await _loadRestaurantName();
    await ensureTables();
    await loadOrdersToday();

    // ⚠️ Catégories locales avec préfixe unique pour éviter les conflits d'IDs API
    // Ces catégories sont créées localement et ne sont PAS synchronisées avec l'API
    // Utilisées uniquement pour le POS (pas pour iOS/Web)
    await ensureLocalCategoriesAndProducts();

    await AuthSessionService.instance.refresh();
  }

  /// ✅ Créer les catégories et produits locaux avec préfixe [LOCAL] pour éviter les conflits API
  Future<void> ensureLocalCategoriesAndProducts() async {
    try {
      await DatabaseService.init();

      final categoryCtrl = Get.isRegistered<CategoryController>()
          ? Get.find<CategoryController>()
          : null;
      final productCtrl = Get.isRegistered<ProductController>()
          ? Get.find<ProductController>()
          : null;

      if (categoryCtrl == null || productCtrl == null) {
        appLogger.w(
          '⚠️ CategoryController ou ProductController non disponible',
        );
        return;
      }

      // Charger les catégories existantes
      await categoryCtrl.fetchAllCategories();
      final existingCategories = categoryCtrl.categories;

      // ✅ Utiliser un préfixe [LOCAL] pour éviter les conflits avec les catégories API
      // 1. Créer ou trouver la catégorie "[LOCAL] Offert"
      Category? offertCategory = existingCategories
          .where((c) => c.name.trim() == '[LOCAL] Offert')
          .firstOrNull;
      if (offertCategory == null) {
        await categoryCtrl.createCategory(name: '[LOCAL] Offert', image: null);
        await categoryCtrl.fetchAllCategories();
        offertCategory = categoryCtrl.categories
            .where((c) => c.name.trim() == '[LOCAL] Offert')
            .firstOrNull;
      }

      // 2. Créer ou trouver la catégorie "[LOCAL] Additions"
      Category? additionsCategory = existingCategories
          .where((c) => c.name.trim() == '[LOCAL] Additions')
          .firstOrNull;
      if (additionsCategory == null) {
        await categoryCtrl.createCategory(
          name: '[LOCAL] Additions',
          image: null,
        );
        await categoryCtrl.fetchAllCategories();
        additionsCategory = categoryCtrl.categories
            .where((c) => c.name.trim() == '[LOCAL] Additions')
            .firstOrNull;
      }

      // Charger les produits existants
      await productCtrl.fetchAllProducts();
      final existingProducts = productCtrl.products;

      // 3. Créer les produits "Offert" si ils n'existent pas
      if (offertCategory != null) {
        final offertProducts = [
          '[LOCAL] Cadeau client',
          '[LOCAL] Invité',
          '[LOCAL] Offre spéciale',
        ];

        for (final productName in offertProducts) {
          final exists = existingProducts.any(
            (p) =>
                p.categoryId == offertCategory!.id &&
                p.name.trim() == productName,
          );
          if (!exists) {
            await productCtrl.createProduct(
              name: productName,
              price: 0.0, // Gratuit
              categoryId: offertCategory.id,
              offer: true,
              isAvailable: true,
              description: 'Produit offert local (gratuit)',
            );
            appLogger.d('✅ Produit offert créé: $productName');
          }
        }
      }

      // 4. Créer les produits "Additions" si ils n'existent pas
      if (additionsCategory != null) {
        final additionProducts = [
          ('[LOCAL] Supplément sauce', 5.0),
          ('[LOCAL] Supplément fromage', 10.0),
          ('[LOCAL] Supplément viande', 15.0),
          ('[LOCAL] Supplément boisson', 8.0),
          ('[LOCAL] Pourboire', 0.0),
          ('[LOCAL] Service', 0.0),
        ];

        for (final entry in additionProducts) {
          final productName = entry.$1;
          final productPrice = entry.$2;

          final exists = existingProducts.any(
            (p) =>
                p.categoryId == additionsCategory!.id &&
                p.name.trim() == productName,
          );
          if (!exists) {
            await productCtrl.createProduct(
              name: productName,
              price: productPrice,
              categoryId: additionsCategory.id,
              offer: false,
              isAvailable: true,
              description: 'Addition locale/Surcoût',
            );
            appLogger.d('✅ Addition créée: $productName ($productPrice DA)');
          }
        }
      }

      // ✅ Rafraîchir les produits pour garantir la cohérence des IDs
      await productCtrl.fetchAllProducts();

      // Rafraîchir l'UI
      categoryCtrl.update();
      productCtrl.update();

      appLogger.i(
        '✅ Catégories et produits locaux initialisés avec préfixe [LOCAL]',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '❌ Erreur initialisation catégories locales',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ✅ Vérifie si un utilisateur est autorisé à se connecter sur ce restaurant
  bool _isUserAllowedForCurrentRestaurant(User user) {
    // 1. Récupérer le restaurant importé
    int? importedRestaurantId;
    if (Get.isRegistered<RestaurantController>()) {
      importedRestaurantId = Get.find<RestaurantController>()
          .getImportedRestaurantId();
    }

    // 2. Si aucun restaurant importé, permettre la connexion
    // (première installation)
    if (importedRestaurantId == null) {
      appLogger.w(
        '⚠️ [POS] Aucun restaurant importé, connexion PIN autorisée (première installation)',
      );
      return true;
    }

    // 3. Vérifier que le restaurant de l'utilisateur correspond
    final userRestaurantId = user.restaurantId;
    if (userRestaurantId == null || userRestaurantId <= 0) {
      appLogger.w('⚠️ [POS] Utilisateur sans restaurant ID: ${user.email}');
      // Utilisateur sans restaurant → accès refusé
      return false;
    }

    if (userRestaurantId != importedRestaurantId) {
      appLogger.e(
        '❌ [POS] Accès refusé: utilisateur restaurant=$userRestaurantId, importé=$importedRestaurantId',
      );
      return false;
    }

    appLogger.d(
      '✅ [POS] Accès autorisé: utilisateur restaurant=$userRestaurantId',
    );
    return true;
  }

  Future<String?> _resolvePinSyncToken({
    required String pin,
    required User staff,
  }) async {
    final session = AuthSessionService.instance;
    final canReuseSavedPinSession = _canReuseSavedPinSessionFor(staff);
    final canReuseSavedCredentials = _canReuseSavedCredentialSessionFor(staff);
    if (canReuseSavedPinSession && !session.isTokenExpired()) {
      return session.token.trim();
    }
    if (canReuseSavedPinSession || canReuseSavedCredentials) {
      final refreshed = await session.refreshTokenIfNeeded(
        refreshWithPin: canReuseSavedPinSession ? _authLoginPin : null,
        refreshWithCredentials: canReuseSavedCredentials
            ? _authLoginWithCredentials
            : null,
      );
      if (refreshed.trim().isNotEmpty) {
        return refreshed.trim();
      }
    }

    final freshToken = await _authLoginPin(pin);
    if (freshToken != null && freshToken.trim().isNotEmpty) {
      return freshToken.trim();
    }

    if (canReuseSavedPinSession || canReuseSavedCredentials) {
      final fallbackToken = await session.refreshTokenIfNeeded(
        refreshWithPin: canReuseSavedPinSession ? _authLoginPin : null,
        refreshWithCredentials: canReuseSavedCredentials
            ? _authLoginWithCredentials
            : null,
      );
      if (fallbackToken.trim().isNotEmpty) {
        return fallbackToken.trim();
      }
    }
    return null;
  }

  bool _canReuseSavedPinSessionFor(User staff) {
    final session = AuthSessionService.instance;
    if (!session.isPinSession) return false;
    final savedEmail = session.email.trim().toLowerCase();
    final staffEmail = staff.email.trim().toLowerCase();
    return savedEmail.isNotEmpty && savedEmail == staffEmail;
  }

  bool _canReuseSavedCredentialSessionFor(User staff) {
    final session = AuthSessionService.instance;
    final savedIdentifier = session.savedPasswordIdentifier
        .trim()
        .toLowerCase();
    final staffEmail = staff.email.trim().toLowerCase();
    return savedIdentifier.isNotEmpty && savedIdentifier == staffEmail;
  }

  Future<String?> _authLoginWithCredentials(
    String identifier,
    String secret,
  ) async {
    final normalizedPhone = await _resolvePhoneForCredentialLogin(identifier);
    if (normalizedPhone == null || normalizedPhone.isEmpty) {
      return null;
    }
    final response = await Get.find<ApiClient>().postData('/api/login', {
      'phone': normalizedPhone,
      'password': secret,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }
    final token = AuthController.extractAuthTokenFromApiBody(response.body);
    return token.trim().isEmpty ? null : token.trim();
  }

  Future<String?> _resolvePhoneForCredentialLogin(String identifier) async {
    final directPhone = _normalizePhoneIdentifier(identifier);
    if (directPhone != null) {
      return directPhone;
    }
    final localUser = await DatabaseService.getUserByEmail(
      identifier.trim().toLowerCase(),
    );
    return _normalizePhoneIdentifier(localUser?.phone ?? '');
  }

  String? _normalizePhoneIdentifier(String rawValue) {
    final normalized = rawValue.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    return normalized.isEmpty ? null : normalized;
  }

  Future<_PinUnlockBootstrap?> _bootstrapStaffFromBackendPin(String pin) async {
    try {
      final client = Get.find<ApiClient>();
      final response = await client.postData('/api/login-pin', {
        'pin_code': pin,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      final token = AuthController.extractAuthTokenFromApiBody(response.body);
      final remoteUser = AuthController.extractAuthUserFromApiBody(
        response.body,
      );
      final role = (remoteUser['role'] ?? '').toString().trim().toLowerCase();
      if (!_isPosEligibleRole(role)) {
        // Debug: PIN login user role not allowed
        // appLogger.i('⚠️ PIN login user role not allowed for POS unlock: $role');
        return null;
      }

      final email = _resolvePinLoginEmail(remoteUser, pin);
      if (token.isNotEmpty) {
        await _applyAuthenticatedPinSession(
          token: token,
          email: email,
          pin: pin,
        );
      }

      User? staff = await _refreshStaffFromBackendImport(
        pin: pin,
        restaurantId: _asInt(remoteUser['restaurant_id']),
      );
      staff ??= await _upsertLocalStaffFromPinLogin(
        pin: pin,
        email: email,
        remoteUser: remoteUser,
      );
      if (staff == null) return null;

      return _PinUnlockBootstrap(
        staff: staff,
        token: token.isEmpty ? null : token,
      );
    } catch (e) {
      // Debug: Backend PIN bootstrap failed
      // appLogger.i('⚠️ Backend PIN bootstrap failed: $e');
      return null;
    }
  }

  Future<void> _applyAuthenticatedPinSession({
    required String token,
    required String email,
    required String pin,
  }) async {
    _applyTokenToServices(token);

    await AuthSessionService.instance.saveSession(
      token: token,
      email: email,
      authMethod: 'pin',
      credentialIdentifier: email,
      credentialSecret: pin,
    );
    // appLogger.i('📌 Token after saveSession: ${AuthSessionService.instance.token}');
    update();
    // appLogger.i('✅ All services updated with new token');
  }

  /// Appliquer une session PIN locale (sans token backend)
  /// Utilise un token factice pour permettre la sync locale
  Future<void> _applyLocalPinSession({
    required String email,
    required String pin,
  }) async {
    // Créer un token local factice pour la sync
    final localToken = 'local_pin_${DateTime.now().millisecondsSinceEpoch}';

    _applyTokenToServices(localToken);

    await AuthSessionService.instance.saveSession(
      token: localToken,
      email: email,
      authMethod: 'pin',
      credentialIdentifier: email,
      credentialSecret: pin,
    );

    appLogger.d('🔑 Session PIN locale appliquée pour $email');
    update();
  }

  void _applyTokenToServices(String token) {
    final apiClient = Get.find<ApiClient>();
    apiClient.updateHeaders(token);
    SyncQueueService.instance.updateAuthToken(token);
    ApiOrderPullService.instance.updateAuthToken(token);
    if (Get.isRegistered<ImportController>()) {
      Get.find<ImportController>().updateApiToken(token);
    }
    if (Get.isRegistered<DeliveryController>()) {
      Get.find<DeliveryController>().updateApiToken(token);
    }
  }

  Future<void> _restoreSessionForBadgeUnlock(User staff) async {
    final session = AuthSessionService.instance;
    await session.refresh();

    final token = await _resolveSavedTokenForUnlockedStaff(staff);
    if (token != null && token.isNotEmpty) {
      _applyTokenToServices(token);
      appLogger.d('🔑 Session restaurée via badge pour ${staff.email}');
      return;
    }

    final sameUserPinSession =
        session.authMethod == 'pin' &&
        session.email.trim().toLowerCase() ==
            staff.email.trim().toLowerCase() &&
        session.credentialSecret.trim().isNotEmpty;
    if (sameUserPinSession) {
      await _applyLocalPinSession(
        email: staff.email,
        pin: session.credentialSecret.trim(),
      );
      return;
    }

    await _applyLocalBadgeSession(
      email: staff.email,
      badgeCode: normalizeBadgeCode(staff.badgeCode),
    );
  }

  Future<String?> _resolveSavedTokenForUnlockedStaff(User staff) async {
    final session = AuthSessionService.instance;
    final staffEmail = staff.email.trim().toLowerCase();
    final sessionEmail = session.email.trim().toLowerCase();
    if (staffEmail.isEmpty) return null;

    if (sessionEmail == staffEmail &&
        session.token.trim().isNotEmpty &&
        !session.isTokenExpired()) {
      return session.token.trim();
    }

    final canReuseSavedPinSession = _canReuseSavedPinSessionFor(staff);
    final canReuseSavedCredentials = _canReuseSavedCredentialSessionFor(staff);
    if (!canReuseSavedPinSession && !canReuseSavedCredentials) {
      return null;
    }

    final refreshed = await session.refreshTokenIfNeeded(
      refreshWithPin: canReuseSavedPinSession ? _authLoginPin : null,
      refreshWithCredentials: canReuseSavedCredentials
          ? _authLoginWithCredentials
          : null,
    );
    return refreshed.trim().isEmpty ? null : refreshed.trim();
  }

  Future<void> _applyLocalBadgeSession({
    required String email,
    required String badgeCode,
  }) async {
    final localToken = 'local_badge_${DateTime.now().millisecondsSinceEpoch}';
    _applyTokenToServices(localToken);

    await AuthSessionService.instance.saveSession(
      token: localToken,
      email: email,
      authMethod: 'badge',
      credentialIdentifier: email,
      credentialSecret: badgeCode,
    );

    appLogger.d('🪪 Session badge locale appliquée pour $email');
    update();
  }

  Future<User?> _refreshStaffFromBackendImport({
    required String pin,
    int? restaurantId,
  }) async {
    try {
      final client = Get.find<ApiClient>();
      final importer = ApiImportService(
        baseUrl: client.appBaseUrl,
        authToken: client.token,
      );
      final imported = await importer.importUsers(restaurantId: restaurantId);
      if (!imported) return null;
      return await DatabaseService.getStaffByPin(pin);
    } catch (e) {
      // Debug: User import after PIN login failed
      // appLogger.i('⚠️ User import after PIN login failed: $e');
      return null;
    }
  }

  Future<User?> _upsertLocalStaffFromPinLogin({
    required String pin,
    required String email,
    required Map<String, dynamic> remoteUser,
  }) async {
    final role = (remoteUser['role'] ?? '').toString().trim().toLowerCase();
    if (!_isPosEligibleRole(role)) {
      return null;
    }

    final remoteId = _asInt(remoteUser['id']);
    User? existing;
    if (remoteId != null && remoteId > 0) {
      existing = await DatabaseService.getUserById(remoteId);
    }
    existing ??= email.isNotEmpty
        ? await DatabaseService.getUserByEmail(email)
        : null;

    final phone = (remoteUser['phone'] ?? existing?.phone ?? '')
        .toString()
        .trim();
    if (existing == null && phone.isNotEmpty) {
      final byPhone = await DatabaseService.getUserByPhone(phone);
      if (byPhone != null && (remoteId == null || byPhone.id == remoteId)) {
        existing = byPhone;
      }
    }

    final now = DateTime.now();
    final isActive = _asBool(
      remoteUser['is_active'],
      defaultValue: existing?.isActive ?? true,
    );
    final localUser = User(
      name: (remoteUser['name'] ?? existing?.name ?? 'Staff POS')
          .toString()
          .trim(),
      phone: phone,
      email: email,
      password: existing?.password ?? User.hashPassword(pin),
      role: role,
      restaurantId:
          _asInt(remoteUser['restaurant_id']) ?? existing?.restaurantId,
      pinCode: pin,
      badgeCode: normalizeBadgeCode(
        remoteUser['badge_code'] ?? existing?.badgeCode,
      ),
      isActive: isActive,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (existing != null) {
      localUser.id = existing.id;
      await DatabaseService.updateUser(localUser);
      return localUser;
    }

    if (remoteId != null && remoteId > 0) {
      localUser.id = remoteId;
    }
    await DatabaseService.createUser(localUser);
    return localUser;
  }

  bool _isPosEligibleRole(String role) {
    return role == 'staff' || role == 'admin' || role == 'superadmin';
  }

  String _resolvePinLoginEmail(Map<String, dynamic> remoteUser, String pin) {
    final email = (remoteUser['email'] ?? '').toString().trim().toLowerCase();
    if (email.isNotEmpty) return email;

    final remoteId = _asInt(remoteUser['id']);
    if (remoteId != null && remoteId > 0) {
      return 'pin_$remoteId@local.pos';
    }
    return 'pin_$pin@local.pos';
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on') {
      return true;
    }
    if (normalized == '0' ||
        normalized == 'false' ||
        normalized == 'no' ||
        normalized == 'off') {
      return false;
    }
    return defaultValue;
  }

  Future<String?> _authLoginPin(String pin) async {
    final client = Get.find<ApiClient>();
    // Debug: ApiClient instance in _authLoginPin
    // appLogger.i('📌 ApiClient instance in _authLoginPin: ${client.hashCode}');

    final response = await client.postData('/api/login-pin', {'pin_code': pin});
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    final token = AuthController.extractAuthTokenFromApiBody(response.body);

    // Debug: Token from API
    // appLogger.i('📌 Token from API: ${token.isNotEmpty ? "${token.substring(0, 10)}..." : "EMPTY"}');
    // appLogger.i('📌 ApiClient token after login: ${client.token}');

    return token.isNotEmpty ? token : null;
  }

  int? _resolveRestaurantIdForOrder(PosOrder order) {
    final orderRestaurantId = order.restaurantId;
    if (orderRestaurantId != null && orderRestaurantId > 0) {
      return orderRestaurantId;
    }

    final activeRestaurantId = _restaurantId;
    if (activeRestaurantId != null && activeRestaurantId > 0) {
      return activeRestaurantId;
    }

    if (Get.isRegistered<AuthController>()) {
      final authRestaurantId =
          Get.find<AuthController>().currentUser?.restaurantId;
      if (authRestaurantId != null && authRestaurantId > 0) {
        return authRestaurantId;
      }
    }

    return null;
  }

  Future<int?> _resolveBackendOrderIdForDelivery(PosOrder order) async {
    var remoteOrderId = await ApiOrderPullService.instance
        .ensureRemoteOrderIdForLocalId(order.id);
    if (remoteOrderId != null && remoteOrderId > 0) {
      return remoteOrderId;
    }

    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
      remoteOrderId = await ApiOrderPullService.instance
          .ensureRemoteOrderIdForLocalId(order.id);
      if (remoteOrderId != null && remoteOrderId > 0) {
        return remoteOrderId;
      }
    }

    return null;
  }

  Future<void> _saveOrderDeliveryLocally(OrderDelivery delivery) async {
    await DatabaseService.upsertOrderDeliveryByOrderId(delivery);
  }

  void lock() {
    _activeStaff = null;
    _activeStaffId = null;
    _restaurantId = null;
    _restaurantName = null;
    _cart.clear();
    _tableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    _deliveryLivreurId = null;
    _deliveryLivreurName = null;
    _deliveryLivreurPhone = null;
    _note = null;
    _paymentMethod = null;
    _editingOrderId = null;
    _orderEditSnapshot = null;
    _isGlovoDelivery = false;
    _ordersToday.clear();
    _tables.clear();
    _error = null;
    update();
  }

  Future<void> _loadRestaurantName() async {
    final id = _restaurantId;
    if (id == null) {
      _restaurantName = null;
      return;
    }
    final restaurant = await DatabaseService.getRestaurantById(id);
    _restaurantName = restaurant?.name;
  }

  Future<void> refreshRestaurantContext() async {
    await _loadRestaurantName();
    update();
  }

  void setFulfillmentType(String value) {
    if (isEditingExistingOrder && !canEditCurrentOrderConfiguration) {
      return;
    }
    _fulfillmentType = value;
    if (_fulfillmentType != 'on_site') {
      _tableNumber = null;
    }
    update();
  }

  void setTableNumber(String value) {
    if (isEditingExistingOrder && !canEditCurrentOrderConfiguration) {
      return;
    }
    _tableNumber = value.trim();
    update();
  }

  /// Prépare le contrôleur pour créer une NOUVELLE commande.
  /// Réinitialise l'état d'édition et le panier pour éviter d'ouvrir
  /// le POS en mode édition lorsqu'on veut créer une nouvelle commande.
  void startNewOrder() {
    // Clear any editing context
    _editingOrderId = null;
    _orderEditSnapshot = null;

    // Reset customer/delivery/context fields
    _fulfillmentType = 'on_site';
    _tableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    _deliveryLivreurId = null;
    _deliveryLivreurName = null;
    _deliveryLivreurPhone = null;
    _note = null;
    _paymentMethod = null;
    _isGlovoDelivery = false;
    _selectedCustomer = null;

    // Clear cart and groups
    _cart.clear();
    _resetCartGroups();

    // Clear transient errors and update UI
    _error = null;
    update();
  }

  void _ensureDefaultCartGroup() {
    if (_fulfillmentType != 'on_site') return;
    if (_cartGroups.isEmpty) {
      _cartGroups.add(1);
    }
    _activeGroupNumber ??= _cartGroups.first;
  }

  void _resetCartGroups() {
    _cartGroups.clear();
    _activeGroupNumber = null;
  }

  void addCartGroup() {
    if (_fulfillmentType != 'on_site') {
      return;
    }
    _ensureDefaultCartGroup();
    final nextGroup = _cartGroups.isEmpty ? 1 : (_cartGroups.last + 1);
    if (!_cartGroups.contains(nextGroup)) {
      _cartGroups.add(nextGroup);
    }
    _activeGroupNumber = nextGroup;
    update();
  }

  void setActiveCartGroup(int groupNumber) {
    if (_fulfillmentType != 'on_site') {
      return;
    }
    if (!_cartGroups.contains(groupNumber)) {
      _cartGroups.add(groupNumber);
      _cartGroups.sort();
    }
    _activeGroupNumber = groupNumber;
    update();
  }

  void setCustomerInfo({String? name, String? phone, String? address}) {
    if (isEditingExistingOrder && !canEditCurrentOrderCustomerData) {
      return;
    }
    _customerName = name?.trim().isEmpty == true ? null : name?.trim();
    _customerPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    _deliveryAddress = address?.trim().isEmpty == true ? null : address?.trim();
    update();
  }

  // Customer search and selection methods
  Future<void> searchCustomers(String query) async {
    try {
      final results = await DatabaseService.searchCustomers(query);
      _customerSearchResults.value = results;
      update();
    } catch (e) {
      appLogger.e('Error searching customers: $e');
      _customerSearchResults.value = [];
      update();
    }
  }

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    _isCreatingNewCustomer = false;
    _customerName = customer.name;
    _customerPhone = customer.phone;
    _deliveryAddress = customer.address;
    _customerSearchResults.value = [];
    update();
  }

  void clearCustomerSelection() {
    _selectedCustomer = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    _deliveryLivreurId = null;
    _deliveryLivreurName = null;
    _deliveryLivreurPhone = null;
    update();
  }

  void setNewCustomerMode(bool value) {
    _isCreatingNewCustomer = value;
    if (value) {
      _selectedCustomer = null;
      _customerName = null;
      _customerPhone = null;
      _deliveryAddress = null;
      _deliveryLivreurId = null;
      _deliveryLivreurName = null;
      _deliveryLivreurPhone = null;
    }
    update();
  }

  void setNote(String? value) {
    if (isEditingExistingOrder && !canEditCurrentOrderCustomerData) {
      return;
    }
    _note = value?.trim().isEmpty == true ? null : value?.trim();
    update();
  }

  void setPaymentMethod(String? value) {
    final normalized = normalizePaymentMethod(value);
    _paymentMethod = normalized.isEmpty ? null : normalized;
    update();
  }

  /// Toggle Glovo delivery mode
  Future<void> setGlovoDelivery(bool value) async {
    if (isEditingExistingOrder && !canEditCurrentOrderConfiguration) {
      return;
    }
    _isGlovoDelivery = value;

    // Update cart items with Glovo price type if enabled
    if (value) {
      appLogger.i('\n🛵 === ACTIVATION GLOVO ===');
      for (int i = 0; i < _cart.length; i++) {
        final item = _cart[i];
        // Get Glovo supplement price from ProductPrice table
        final glovoPrice = await DatabaseService.getProductPriceByType(
          item.product.id,
          'glovo',
        );
        final glovoSupplement = glovoPrice?.price ?? 5.0;
        final totalPrice = item.product.price + glovoSupplement;

        appLogger.i('📦 ${item.product.name} (ID: ${item.product.id}):');
        appLogger.i(
          '   └─ Prix base: ${item.product.price.toStringAsFixed(2)} dh',
        );
        if (glovoPrice != null) {
          appLogger.i(
            '   └─ Supplément Glovo (BDD): ${glovoPrice.price.toStringAsFixed(2)} dh',
          );
        } else {
          appLogger.i(
            '   ⚠️ PAS DE PRIX GLOVO - FALLBACK: ${glovoSupplement.toStringAsFixed(2)} dh',
          );
        }
        appLogger.i('   └─ Prix total: ${totalPrice.toStringAsFixed(2)} dh');

        _cart[i] = CartItem(
          product: item.product,
          quantity: item.quantity,
          priceType: 'glovo',
          customPrice: totalPrice, // Total = base + supplement
          basePrice: item.product.price, // Store base price for display
        );
      }
      appLogger.i('============================\n');
    } else {
      // Reset to default prices
      for (int i = 0; i < _cart.length; i++) {
        final item = _cart[i];
        _cart[i] = CartItem(
          product: item.product,
          quantity: item.quantity,
          priceType: null,
          customPrice: null,
          basePrice: null,
        );
      }
    }

    update();
  }

  Future<void> addToCart(
    Product product, {
    String? itemNote,
    int? groupNumber,
    String? serviceCourseKey,
    String? serviceCourseLabel,
  }) async {
    // ✅ FIX: Vérifier à la fois le product.id ET le groupNumber
    final index = _cart.indexWhere(
      (c) => c.product.id == product.id && c.groupNumber == groupNumber,
    );

    // Determine price type based on Glovo delivery mode
    String? priceType = _isGlovoDelivery ? 'glovo' : null;
    double? customPrice;
    double? basePrice;

    if (_isGlovoDelivery) {
      // Get Glovo supplement price from ProductPrice table
      final glovoPrice = await DatabaseService.getProductPriceByType(
        product.id,
        'glovo',
      );

      appLogger.i('\n🛵 AJOUT PRODUIT (GLOVO ACTIVÉ)');
      appLogger.i('📦 ${product.name} (ID: ${product.id}):');
      appLogger.i('   └─ Prix base: ${product.price.toStringAsFixed(2)} dh');

      if (glovoPrice != null) {
        appLogger.i(
          '   └─ Supplément Glovo (BDD): ${glovoPrice.price.toStringAsFixed(2)} dh',
        );
        appLogger.i('   └─ Glovo price type: ${glovoPrice.type}');
      } else {
        appLogger.i('   ⚠️ PAS DE PRIX GLOVO DANS BDD !');
      }

      final glovoSupplement = glovoPrice?.price ?? 5.0;
      customPrice =
          product.price + glovoSupplement; // Total = base + supplement
      basePrice = product.price; // Store base price for display

      appLogger.i(
        '   └─ Supplément utilisé: ${glovoSupplement.toStringAsFixed(2)} dh',
      );
      appLogger.i('   └─ Prix total: ${customPrice.toStringAsFixed(2)} dh');
    }

    if (index == -1) {
      _cart.add(
        CartItem(
          product: product,
          quantity: 1,
          priceType: priceType,
          customPrice: customPrice,
          basePrice: basePrice,
          itemNote: itemNote,
          groupNumber: groupNumber,
          serviceCourseKey: serviceCourseKey,
          serviceCourseLabel: serviceCourseLabel,
        ),
      );
    } else {
      _cart[index].quantity += 1;
      // Pour les articles existants, on ne met pas à jour les options
      // car l'utilisateur pourrait vouloir des options différentes pour chaque quantité
    }
    update();
  }

  void removeFromCart(Product product, {int? groupNumber}) {
    // ✅ FIX: Vérifier à la fois le product.id ET le groupNumber
    final index = _cart.indexWhere(
      (c) => c.product.id == product.id && c.groupNumber == groupNumber,
    );
    if (index == -1) return;
    if (_cart[index].quantity > 1) {
      _cart[index].quantity -= 1;
    } else {
      _cart.removeAt(index);
    }
    update();
  }

  void setCartItemQuantity(Product product, int quantity, {int? groupNumber}) {
    // ✅ FIX: Vérifier à la fois le product.id ET le groupNumber
    final index = _cart.indexWhere(
      (c) => c.product.id == product.id && c.groupNumber == groupNumber,
    );
    if (index == -1) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].quantity = quantity;
    }
    update();
  }

  double get total => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  Future<int?> createOrder({
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? note,
  }) async {
    if (_isCreatingOrder) {
      appLogger.w('⚠️ [CREATE ORDER] Blocked: already creating order');
      return null; // évite double clics
    }

    // Check if staff is active
    if (_activeStaff == null) {
      appLogger.e('❌ [CREATE ORDER] Blocked: no active staff');
      _error = 'Aucun serveur actif';
      update();
      return null;
    }

    final cashRegisterController = Get.isRegistered<CashRegisterController>()
        ? Get.find<CashRegisterController>()
        : null;
    if (cashRegisterController != null &&
        !cashRegisterController.isCashRegisterOpen &&
        !isAdminEditor) {
      appLogger.w(
        '⚠️ [CREATE ORDER] Blocked: cash register is closed for staff #${_activeStaff?.id}',
      );
      _error = 'La caisse est fermée. Ouvrez-la avant de passer des commandes.';
      update();
      return null;
    }

    _isCreatingOrder = true;
    update();
    _error = null;
    try {
      final resolvedRestaurantId =
          _activeStaff?.restaurantId ??
          _restaurantId ??
          (Get.isRegistered<AuthController>()
              ? Get.find<AuthController>().currentUser?.restaurantId
              : null);
      if (resolvedRestaurantId == null || resolvedRestaurantId <= 0) {
        appLogger.e(
          'Cannot create order: missing restaurantId',
          context: {
            'staffId': _activeStaff?.id,
            'restaurantId': resolvedRestaurantId,
          },
        );
        _error = 'Restaurant introuvable pour cette commande';
        update();
        return null;
      }
      if (_fulfillmentType == 'on_site' &&
          (_tableNumber == null || _tableNumber!.isEmpty)) {
        _error = 'Table obligatoire pour sur place';
        update();
        return null;
      }
      if (_fulfillmentType == 'delivery' &&
          ((_customerName == null || _customerName!.isEmpty) &&
              (_customerPhone == null || _customerPhone!.isEmpty))) {
        _error = 'Nom ou téléphone obligatoire pour livraison';
        update();
        return null;
      }
      if (_fulfillmentType == 'delivery' &&
          (_deliveryAddress == null || _deliveryAddress!.isEmpty)) {
        _error = 'Adresse obligatoire pour livraison';
        update();
        return null;
      }
      if (_cart.isEmpty) {
        _error = 'Panier vide';
        update();
        return null;
      }

      // Validate table status for on_site orders (skip if editing own order)
      final isEditingOrder = _editingOrderId != null;
      if (_fulfillmentType == 'on_site' &&
          _tableNumber != null &&
          _tableNumber!.isNotEmpty &&
          !isEditingOrder) {
        // Check actual table status
        await ensureTables();
        final table = _tables
            .where((t) => t.number == _tableNumber)
            .firstOrNull;

        if (table == null) {
          _error = 'Table $_tableNumber introuvable';
          update();
          return null;
        }

        // Only allow orders on available tables (skip for editing own order)
        if (table.status != 'available') {
          _error = 'Table $_tableNumber est occupée (${table.status})';
          update();
          return null;
        }
      }

      // Calcul du total avec les prix dynamiques
      final total = _cart.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

      final editingSnapshot = _orderEditSnapshot;
      late final PosOrder order;
      int orderId;
      if (isEditingOrder) {
        final existingOrder = editingSnapshot == null
            ? await DatabaseService.getPosOrderById(_editingOrderId!)
            : await _reloadOrderForEditionCheck(
                orderId: _editingOrderId!,
                expectedUpdatedAt: editingSnapshot.originalUpdatedAt,
              );
        if (existingOrder == null) {
          return null;
        }
        final previousOrder = _copyPosOrder(existingOrder);
        final preservedDiscount = existingOrder.hasDiscount
            ? existingOrder.discountAmount
            : 0.0;

        // Get existing items to calculate the correct total
        final existingItems = await DatabaseService.getPosOrderItems(
          existingOrder.id,
        );
        final existingTotal = existingItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.unitPrice * item.quantity),
        );

        // Calculate total from new items in cart
        final newItemsTotal = _cart.fold<double>(
          0.0,
          (sum, item) => sum + (item.unitPrice * item.quantity),
        );

        // New total = existing total + new items total
        final newTotal = existingTotal + newItemsTotal;

        order = _copyPosOrder(existingOrder)
          ..staffId = existingOrder.staffId > 0
              ? existingOrder.staffId
              : _activeStaff!.id
          ..restaurantId = existingOrder.restaurantId ?? resolvedRestaurantId
          ..fulfillmentType = _fulfillmentType
          ..isGlovoDelivery = _isGlovoDelivery && _fulfillmentType == 'delivery'
          ..totalPrice = newTotal
          ..originalTotal = newTotal + preservedDiscount
          ..discountAmount = preservedDiscount
          ..hasDiscount = preservedDiscount > 0
          ..paymentMethod = _paymentMethod
          ..customerName = _customerName ?? customerName
          ..customerPhone = _customerPhone ?? customerPhone
          ..deliveryAddress = _deliveryAddress ?? deliveryAddress
          ..deliveryLivreurId = _deliveryLivreurId
          ..deliveryLivreurName = _deliveryLivreurName
          ..deliveryLivreurPhone = _deliveryLivreurPhone
          ..tableNumber = _tableNumber
          ..note = _note ?? note
          ..updatedAt = DateTime.now();
        if (order.staffId <= 0) {
          order.staffId = _activeStaff!.id;
          appLogger.w(
            '⚠️ [CREATE ORDER] Missing staffId detected on edited order, assigning active staff #${_activeStaff!.id}',
          );
        }
        orderId = await DatabaseService.updatePosOrder(order);

        appLogger.i('✏️ [SAVE EDIT] Order #${order.id} updated locally');
        appLogger.i(
          '   └─ Updated: staffId=${order.staffId}, restaurantId=${order.restaurantId}, '
          'sourceLocalId=${order.sourceLocalId}, updatedAt=${order.updatedAt}',
        );
        appLogger.i(
          '   └─ Totals: existing=$existingTotal, new_items=$newItemsTotal, final=$newTotal',
        );

        // Only add new items, don't delete existing ones
        await _applyEditedOrderTableChanges(
          previousOrder: previousOrder,
          updatedOrder: order,
        );
      } else {
        order = PosOrder(
          staffId: _activeStaff!.id,
          restaurantId: resolvedRestaurantId,
          fulfillmentType: _fulfillmentType,
          isGlovoDelivery: _isGlovoDelivery && _fulfillmentType == 'delivery',
          status: 'confirmed', // Confirmé par défaut car créé par le serveur
          paymentStatus: 'pending',
          totalPrice: total,
          originalTotal: total,
          discountAmount: 0.0,
          hasDiscount: false,
          paymentMethod: _paymentMethod ?? 'cod', // ✅ Valeur par défaut si null
          customerName: _customerName ?? customerName,
          customerPhone: _customerPhone ?? customerPhone,
          deliveryAddress: _deliveryAddress ?? deliveryAddress,
          deliveryLivreurId: _deliveryLivreurId,
          deliveryLivreurName: _deliveryLivreurName,
          deliveryLivreurPhone: _deliveryLivreurPhone,
          tableNumber: _tableNumber,
          note: _note ?? note,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        orderId = await DatabaseService.createPosOrder(order);
      }

      appLogger.i(
        isEditingOrder
            ? '✏️ [SAVE EDIT] Order #$orderId saving (${_cart.length} new items)'
            : '🛒 [CREATE ORDER] Order #$orderId created (${_cart.length} items)',
      );
      appLogger.i(
        '   └─ Context: staffId=${order.staffId}, restaurantId=${order.restaurantId}, '
        'channel=${order.channel}, tableNumber=${order.tableNumber}, '
        'isEditing=$isEditingOrder, activeStaffId=$_activeStaffId',
      );

      if (_cart.isEmpty) {
        appLogger.e('❌ CART IS EMPTY! Cannot create order items.');
      }

      // Create items from cart
      for (final item in _cart) {
        final orderItem = PosOrderItem(
          orderId: orderId,
          productId: item.product.id,
          productName: item.product.name,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          priceType: item.priceType,
          glovoBasePrice: item.basePrice, // Store base price for Glovo orders
          groupNumber: item.groupNumber,
          groupLabel: item.groupNumber != null
              ? formatGuestGroupLabel(groupNumber: item.groupNumber)
              : null,
          itemNote: item.itemNote,
          serviceCourseKey: item.serviceCourseKey,
          serviceCourseLabel: item.serviceCourseLabel,
          createdAt: DateTime.now(),
        );
        appLogger.i(
          '   └─ Item: ${orderItem.productName} x${orderItem.quantity} => orderId=$orderId',
        );
        final itemId = await DatabaseService.createPosOrderItem(orderItem);
        appLogger.i('   ✅ Item saved with ID=$itemId');
      }
      appLogger.i('✅ Order items saved for order #$orderId');

      // Save or update customer if pickup/delivery
      if ((_fulfillmentType == 'pickup' || _fulfillmentType == 'delivery') &&
          _customerPhone != null &&
          _customerPhone!.isNotEmpty) {
        try {
          Customer? customer;
          if (_selectedCustomer != null) {
            // Update existing customer stats
            await DatabaseService.updateCustomerStats(
              customerId: _selectedCustomer!.id,
              amountSpent: total,
            );
          } else if (_customerName != null && _customerName!.isNotEmpty) {
            // Check if phone belongs to a staff/livreur user
            final user = await DatabaseService.getUserByPhone(_customerPhone!);
            if (user != null &&
                (user.role == 'staff' ||
                    user.role == 'livreur' ||
                    user.role == 'delivery')) {
              // Don't create customer for staff/livreur
              appLogger.w(
                'Skipping customer creation for ${user.role}: ${_customerName!}',
              );
            } else {
              // Create new customer
              customer = Customer.create(
                phone: _customerPhone!,
                name: _customerName!,
                address: _deliveryAddress,
                orderCount: 1,
                totalSpent: total,
                lastOrderDate: DateTime.now(),
              );
              final customerId = await DatabaseService.createCustomer(customer);
              customer = await DatabaseService.getCustomerById(customerId);
              if (customer != null) {
                _selectedCustomer = customer;
              }
            }
          }
        } catch (e) {
          appLogger.e('Error saving customer: $e');
          // Continue even if customer save fails
        }
      }
      await _enqueueOrderSyncById(orderId);

      if (isEditingOrder) {
        appLogger.i(
          '🔄 [SYNC EDIT] Order #$orderId enqueued for sync (editing)',
        );
      } else {
        _scheduleImmediateOrderSync();
        appLogger.i('🔄 [SYNC NEW] Order #$orderId enqueued for sync (new)');
      }

      _cart.clear();
      // ✅ Toujours réinitialiser les groupes pour une nouvelle commande
      _resetCartGroups();
      _editingOrderId = null;
      _orderEditSnapshot = null;

      // Recharger les commandes (sans bloquer si erreur)
      try {
        await loadOrdersToday();
      } catch (e, stackTrace) {
        appLogger.w(
          'Error loading orders after create',
          context: {'orderId': orderId, 'staffId': _activeStaff?.id},
        );
        appLogger.e(
          'loadOrdersToday failed after createOrder',
          error: e,
          stackTrace: stackTrace,
        );
      }

      update();
      return orderId;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error in createOrder',
        error: e,
        stackTrace: stackTrace,
        context: {
          'staffId': _activeStaff?.id,
          'restaurantId': _restaurantId ?? _activeStaff?.restaurantId,
        },
      );
      _error = 'Erreur lors de l\'enregistrement: $e';
      update();
      return null;
    } finally {
      _isCreatingOrder = false;
      update();
    }
  }

  Future<void> loadOrdersToday() async {
    // ✅ FIX: Use customizable day hours from app settings (Morocco/Casablanca)
    // Default: 00:00-23:59 (calendar day)
    // Example restaurant: 06:00-05:59 (service day)
    final now = DateTime.now().toLocal();

    // Get custom day hours from settings
    await AppSettingsService.instance.init();
    final settings = AppSettingsService.instance.settings;
    final startHour = settings.dayStartHour.clamp(0, 23);
    final endHour = settings.dayEndHour.clamp(0, 23);

    // Calculate start and end of the business day
    DateTime start;
    DateTime end;

    if (now.hour >= startHour) {
      // We're after the start hour, so the day started today at startHour
      start = DateTime(now.year, now.month, now.day, startHour, 0, 0);
    } else {
      // We're before the start hour, so the day started yesterday at startHour
      start = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        0,
        0,
      ).subtract(const Duration(days: 1));
    }

    // ✅ Calculate end based on whether it crosses midnight
    // If endHour < startHour: day crosses midnight (e.g., 9am → 2am next day)
    // If endHour >= startHour: day doesn't cross midnight (e.g., 9am → 5pm same day)
    if (endHour < startHour) {
      // Day crosses midnight: end is the day after start at endHour:59
      end = DateTime(
        start.year,
        start.month,
        start.day,
        endHour,
        59,
        59,
      ).add(const Duration(days: 1));
    } else {
      // Day doesn't cross midnight: end is the same day at endHour:59
      end = DateTime(start.year, start.month, start.day, endHour, 59, 59);
    }

    final orders = await DatabaseService.getPosOrders();
    final authUser = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser
        : null;
    final restId =
        _restaurantId ?? _activeStaff?.restaurantId ?? authUser?.restaurantId;
    final activeStaffId = _activeStaffId ?? authUser?.id;
    final actorRole = (_activeStaff?.role ?? authUser?.role ?? '')
        .trim()
        .toLowerCase();
    final isAdminScope = actorRole == 'admin' || actorRole == 'superadmin';

    final cashRegister = Get.isRegistered<CashRegisterController>()
        ? Get.find<CashRegisterController>()
        : null;
    final zeroDataActivatedAt = cashRegister?.currentState?.zeroDataActivatedAt;

    appLogger.d(
      '📊 [LOAD ORDERS] Total BDD: ${orders.length}, '
      'restId=$restId, staffId=$activeStaffId, role=$actorRole, admin=$isAdminScope',
    );
    appLogger.d(
      '  📅 Calendar day: ${start.toString().substring(0, 19)} to ${end.toString().substring(0, 19)} (00:00-23:59)',
    );

    // ✅ Play notification sound for pending orders of THIS restaurant only
    final pendingOrders = orders.where((o) {
      final isToday = !o.createdAt.isBefore(start) && o.createdAt.isBefore(end);
      final isPending = o.status.trim().toLowerCase() == 'pending';
      // ✅ Filtre restaurant STRICT pour notifications
      final restaurantOk =
          restId != null && restId > 0 && o.restaurantId == restId;
      return isToday && isPending && restaurantOk;
    }).toList();

    if (pendingOrders.isNotEmpty) {
      appLogger.d(
        '🔔 [NOTIFICATION] ${pendingOrders.length} pending order(s) detected, playing notification...',
      );
      try {
        await NotificationSoundService.instance.playNewOrderAlarm();
        // Play twice to distinguish from local POS orders
        await Future.delayed(const Duration(milliseconds: 800));
        await NotificationSoundService.instance.playNewOrderAlarm();
        appLogger.d('✅ Notification sound played successfully');
      } catch (e, stackTrace) {
        appLogger.e(
          'Failed to play notification',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Debug détaillé pour CHAQUE commande
    for (final o in orders) {
      final isInRange =
          !o.createdAt.isBefore(start) && o.createdAt.isBefore(end);
      final restaurantOk =
          (restId == null ||
          restId <= 0 ||
          o.restaurantId == null ||
          o.restaurantId == restId);
      final staffOk =
          (isAdminScope ||
          o.channel.toLowerCase() != 'pos' ||
          o.staffId == activeStaffId);

      appLogger.d(
        '  📦 Order #${o.id}: [${o.channel}] ${o.fulfillmentType} | '
        'status=${o.status} | restId=${o.restaurantId} | staffId=${o.staffId} | '
        'date=${o.createdAt.toString().substring(0, 16)} | '
        'inRange=$isInRange | restOk=$restaurantOk | staffOk=$staffOk',
      );
    }

    final scoped = orders.where((o) {
      // Filtre restaurant STRICT - aucune commande ne doit passer d'un autre restaurant
      if (restId != null && restId > 0) {
        // Si la commande n'a pas de restaurantId, on la rejette
        if (o.restaurantId == null || o.restaurantId != restId) {
          appLogger.d(
            '  ❌ Order #${o.id} filtered: wrong restaurant '
            '(order=${o.restaurantId}, user=$restId)',
          );
          return false;
        }
      }

      // ✅ FIX: Les commandes API/Web/Kiosk NE DOIVENT PAS être filtrées par date
      // Elles doivent être visibles même si elles sont anciennes (en attente de traitement)
      final isRemoteOrder = _isRemoteChannel(o.channel);

      // Filtre : UNIQUEMENT aujourd'hui (SAUF pour les commandes remote)
      final isToday = !o.createdAt.isBefore(start) && o.createdAt.isBefore(end);
      if (!isToday && !isRemoteOrder) {
        appLogger.d(
          '  ❌ Order #${o.id} filtered: NOT TODAY '
          '(createdAt=${o.createdAt.toString().substring(0, 10)}, today=${start.toString().substring(0, 10)})',
        );
        return false;
      }

      if (!isToday && isRemoteOrder) {
        appLogger.d(
          '  ✅ Order #${o.id} included: remote order from ${o.createdAt.toString().substring(0, 10)} (no date filter for remote)',
        );
      }

      if (zeroDataActivatedAt != null &&
          o.createdAt.isBefore(zeroDataActivatedAt)) {
        appLogger.d(
          '  ❌ Order #${o.id} filtered: before zero-data activation '
          '(createdAt=${o.createdAt.toIso8601String()}, activation=${zeroDataActivatedAt.toIso8601String()})',
        );
        return false;
      }

      // Staff: voir UNIQUEMENT ses commandes (POS et distantes assignées)
      // ✅ Admin voit TOUTES les commandes (y compris cancelled)
      if (activeStaffId != null) {
        if (isAdminScope) {
          appLogger.d(
            '  ✅ Order #${o.id} included: admin scope (all statuses)',
          );
          return true;
        }

        // ✅ FIX: Les commandes API/Web/Kiosk sont visibles par TOUS les serveurs
        // Ces commandes ne sont pas assignées à un staff spécifique
        final isRemoteOrder = _isRemoteChannel(o.channel);
        if (isRemoteOrder) {
          appLogger.d(
            '  ✅ Order #${o.id} included: remote order (channel=${o.channel}) visible to all staff',
          );
          return true;
        }

        // ✅ Staff ne voit que SES commandes POS (staffId correspond)
        if (o.staffId == activeStaffId) {
          appLogger.d('  ✅ Order #${o.id} included: matches current staff');
          return true;
        }
        appLogger.d(
          '  ❌ Order #${o.id} filtered: staff mismatch '
          '(order=${o.staffId}, active=$activeStaffId)',
        );
        return false;
      }
      appLogger.d('  ❌ Order #${o.id} filtered: no active staff');
      return false;
    }).toList();

    appLogger.d('📊 [AFTER SCOPING] ${scoped.length} orders');

    // Filtre par canal
    List<PosOrder> channelScoped = scoped;
    if (_ordersChannelFilter == 'pos') {
      channelScoped = scoped
          .where((o) => o.channel.toLowerCase() == 'pos')
          .toList();
      appLogger.d('  📡 Channel filter=pos: ${channelScoped.length} orders');
    } else if (_ordersChannelFilter == 'remote') {
      channelScoped = scoped.where((o) => _isRemoteChannel(o.channel)).toList();
      appLogger.d('  📡 Channel filter=remote: ${channelScoped.length} orders');
    }

    // Filtre par type de commande
    List<PosOrder> fulfillmentScoped = channelScoped;
    if (_ordersFulfillmentFilter == 'on_site') {
      fulfillmentScoped = channelScoped
          .where((o) => o.fulfillmentType == 'on_site')
          .toList();
      appLogger.d(
        '  🏷️ Type filter=on_site: ${fulfillmentScoped.length} orders',
      );
    } else if (_ordersFulfillmentFilter == 'pickup') {
      fulfillmentScoped = channelScoped
          .where((o) => o.fulfillmentType == 'pickup')
          .toList();
      appLogger.d(
        '  🏷️ Type filter=pickup: ${fulfillmentScoped.length} orders',
      );
    } else if (_ordersFulfillmentFilter == 'delivery') {
      fulfillmentScoped = channelScoped
          .where((o) => o.fulfillmentType == 'delivery')
          .toList();
      appLogger.d(
        '  🏷️ Type filter=delivery: ${fulfillmentScoped.length} orders',
      );
    } else {
      appLogger.d(
        '  🏷️ Type filter=all: ${fulfillmentScoped.length} orders (no filter)',
      );
    }

    // Filtre par status
    final filtered = _ordersFilter == 'all'
        ? fulfillmentScoped
        : fulfillmentScoped.where((o) => o.status == _ordersFilter).toList();

    appLogger.d(
      '📊 [FINAL] ${filtered.length} orders | '
      'statusFilter=$_ordersFilter | typeFilter=$_ordersFulfillmentFilter',
    );

    if (filtered.isEmpty && orders.isNotEmpty) {
      appLogger.w(
        '⚠️ WARNING: No orders displayed! Check filters and staff assignment.',
      );
    }

    _ordersToday
      ..clear()
      ..addAll(filtered);
    update();
  }

  void setOrdersFilter(String value) {
    _ordersFilter = value;
    loadOrdersToday();
  }

  void setOrdersChannelFilter(String value) {
    _ordersChannelFilter = value;
    loadOrdersToday();
  }

  void setOrdersFulfillmentFilter(String value) {
    _ordersFulfillmentFilter = value;
    loadOrdersToday();
  }

  /// Actualiser les commandes (avec sync API)
  Future<void> refreshOrders() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    update();

    try {
      // Lancer une sync API si disponible
      if (Get.isRegistered<SyncController>()) {
        final sync = Get.find<SyncController>();
        await sync.syncNow();
      }

      // Recharger les commandes locales
      await loadOrdersToday();

      Get.snackbar(
        'Actualisé',
        'Les commandes ont été actualisées',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'actualiser les commandes',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isRefreshing = false;
      update();
    }
  }

  Future<bool> markOrderPaid(PosOrder order) async {
    _error = null;
    order.status = 'delivered';
    order.paymentStatus = 'paid';
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);

    // Enqueue for sync
    await _enqueueOrderSyncById(order.id);

    // Try immediate sync for remote orders
    final synced = await _syncApiOrderStatusIfNeeded(order);

    // Force a sync queue flush if SyncController is available
    if (Get.isRegistered<SyncController>()) {
      final sync = Get.find<SyncController>();
      if (sync.isOnline) {
        unawaited(SyncQueueService.instance.flushQueue());
      }
    }

    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<bool> updateOrderStatus(PosOrder order, String status) async {
    _error = null;

    // ✅ Vérification de propriété
    if (!isAdminEditor && !canAccessOrder(order)) {
      _error = 'Vous ne pouvez modifier que vos propres commandes';
      update();
      return false;
    }

    final normalizedStatus = status.trim().toLowerCase();

    // Only support: pending, confirmed, cancelled
    if (!['pending', 'confirmed', 'cancelled'].contains(normalizedStatus)) {
      _error = 'Statut non supporté: $normalizedStatus';
      update();
      return false;
    }

    // Prevent staff from cancelling orders - only admins can cancel
    if (normalizedStatus == 'cancelled') {
      _error = 'Annulation réservée aux administrateurs';
      update();
      return false;
    }

    // Validate status transition for staff users
    if (!isAdminEditor) {
      // Staff can only transition: pending -> confirmed
      final validTransitions = {
        'pending': ['confirmed'],
      };

      final allowedStatuses = validTransitions[order.status] ?? [];
      if (!allowedStatuses.contains(normalizedStatus)) {
        _error = 'Changement de statut non autorisé pour les serveurs';
        update();
        return false;
      }
    }

    // Assigner le staffId au serveur qui confirme la commande API/mobile/web
    if (normalizedStatus == 'confirmed' && _activeStaff != null) {
      final channel = order.channel.toLowerCase();
      // Seulement pour les commandes API/mobile/web (pas POS)
      if (channel != 'pos' && order.staffId <= 0) {
        order.staffId = _activeStaff!.id;
        appLogger.d(
          '📍 Staff #${_activeStaff!.id} confirmed $channel order #${order.id}',
        );
      }
    }

    order.status = normalizedStatus;
    if (normalizedStatus == 'confirmed') {
      // La commande confirmée reste unpaid - le paiement sera fait séparément
      // order.paymentStatus reste 'pending'
    }
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);

    // Enqueue for sync
    await _enqueueOrderSyncById(order.id);

    // Try immediate sync for remote orders
    final synced = await _syncApiOrderStatusIfNeeded(order);

    // Force a sync queue flush if SyncController is available
    if (Get.isRegistered<SyncController>()) {
      final sync = Get.find<SyncController>();
      if (sync.isOnline) {
        // Force immediate queue flush
        unawaited(SyncQueueService.instance.flushQueue());
      }
    }

    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<bool> cancelOrder(PosOrder order, {String? reason}) async {
    if (!canModifyOrders) {
      _error = 'Annulation réservée aux admins';
      update();
      return false;
    }
    _error = null;
    order.status = 'cancelled';
    order.cancelReason = reason;
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);

    // Enqueue for sync
    await _enqueueOrderSyncById(order.id);

    // Try immediate sync for remote orders
    final synced = await _syncApiOrderStatusIfNeeded(
      order,
      cancelReason: reason,
    );

    // Force a sync queue flush if SyncController is available
    if (Get.isRegistered<SyncController>()) {
      final sync = Get.find<SyncController>();
      if (sync.isOnline) {
        unawaited(SyncQueueService.instance.flushQueue());
      }
    }

    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<void> deleteOrder(PosOrder order) async {
    if (!canModifyOrders) {
      _error = 'Suppression réservée aux admins';
      update();
      return;
    }
    await SyncQueueService.instance.enqueueOrderDelete(order.id);
    await DatabaseService.deletePosOrder(order.id);
    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
  }

  Future<bool> _syncApiOrderStatusIfNeeded(
    PosOrder order, {
    String? cancelReason,
  }) async {
    final isTrackedRemoteOrder = ApiOrderPullService.instance
        .isRemoteApiLocalOrderIdSync(order.id);
    final isRemoteChannel = _isRemoteChannel(order.channel);

    // Si ce n'est pas une commande distante, pas besoin de sync
    if (!isTrackedRemoteOrder && !isRemoteChannel) {
      return true;
    }

    // Pour les commandes API/mobile/web, synchroniser le statut immédiatement
    if (isRemoteChannel || isTrackedRemoteOrder) {
      final ok = await syncApiOrderStatusToBackend(order: order);

      if (ok) {
        appLogger.d(
          '✅ Remote status synced for order #${order.id} '
          'status=${order.status}',
        );
        // Force un flush immédiat de la queue pour les autres commandes
        if (Get.isRegistered<SyncController>()) {
          final sync = Get.find<SyncController>();
          if (sync.isOnline) {
            unawaited(SyncQueueService.instance.flushQueue());
          }
        }
        return true;
      }

      await SyncQueueService.instance.enqueueRemoteOrderStatusSync(
        order: order,
        status: order.status,
        paymentStatus: order.paymentStatus,
        cancelReason: cancelReason ?? order.cancelReason,
      );

      appLogger.w(
        '⚠️ Remote status sync delayed for order #${order.id} '
        '(queued for retry)',
      );
      return false;
    }

    return true;
  }

  Future<void> ensureTables() async {
    final restaurantId = _restaurantId;
    final existing = restaurantId == null
        ? await DatabaseService.getPosTables()
        : await DatabaseService.getPosTablesByRestaurant(restaurantId);
    if (existing.isEmpty) {
      final gridPositions = <int, String>{
        1: '1 / 1 / 2 / 2',
        2: '1 / 2 / 2 / 3',
        3: '1 / 3 / 2 / 4',
        4: '1 / 4 / 2 / 5',
        5: '1 / 5 / 2 / 6',
        6: '1 / 6 / 2 / 7',
        7: '1 / 7 / 2 / 8',
        8: '1 / 8 / 2 / 9',
        9: '2 / 1 / 3 / 2',
        10: '2 / 2 / 3 / 3',
        11: '2 / 3 / 3 / 4',
        12: '2 / 4 / 3 / 5',
        13: '2 / 5 / 3 / 6',
        14: '2 / 6 / 3 / 7',
        15: '2 / 7 / 3 / 8',
        16: '2 / 8 / 3 / 9',
        17: '5 / 1 / 6 / 2',
        18: '5 / 2 / 6 / 3',
        19: '5 / 3 / 6 / 4',
        20: '5 / 4 / 6 / 5',
        21: '5 / 5 / 6 / 6',
        22: '5 / 6 / 6 / 7',
        23: '5 / 7 / 6 / 8',
        24: '5 / 8 / 6 / 9',
        25: '6 / 1 / 7 / 2',
        26: '6 / 2 / 7 / 3',
        27: '6 / 3 / 7 / 4',
        28: '6 / 4 / 7 / 5',
        29: '6 / 5 / 7 / 6',
        30: '6 / 6 / 7 / 7',
        31: '1 / 10 / 2 / 11',
        32: '2 / 10 / 3 / 11',
        33: '3 / 10 / 4 / 11',
        34: '4 / 10 / 5 / 11',
        35: '5 / 10 / 6 / 11',
        36: '6 / 10 / 7 / 11',
        37: '1 / 11 / 2 / 12',
        38: '2 / 11 / 3 / 12',
        39: '3 / 11 / 4 / 12',
        40: '4 / 11 / 5 / 12',
        41: '5 / 11 / 6 / 12',
        42: '6 / 11 / 7 / 12',
      };

      for (final entry in gridPositions.entries) {
        final number = entry.key;
        final area = entry.value.replaceAll(' ', '');
        final parts = area.split('/');
        final rowStart = int.parse(parts[0]);
        final colStart = int.parse(parts[1]);
        final rowEnd = int.parse(parts[2]);
        final colEnd = int.parse(parts[3]);
        await DatabaseService.createPosTable(
          PosTable(
            number: 'T$number',
            status: 'available',
            restaurantId: restaurantId,
            gridColumnStart: colStart,
            gridColumnEnd: colEnd,
            gridRowStart: rowStart,
            gridRowEnd: rowEnd,
          ),
        );
      }
    }
    final tables = restaurantId == null
        ? await DatabaseService.getPosTables()
        : await DatabaseService.getPosTablesByRestaurant(restaurantId);
    _tables
      ..clear()
      ..addAll(tables);
    update();
  }

  Future<void> markTableOccupied(
    String tableNumber, {
    int? requestingStaffId,
  }) async {
    PosTable? table;
    for (final t in _tables) {
      if (t.number == tableNumber) {
        table = t;
        break;
      }
    }
    if (table == null) return;

    // Defensive check: are there active orders from a different staff?
    if (requestingStaffId != null) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final orders = await DatabaseService.getPosOrdersByDateRange(
        startOfDay,
        endOfDay,
      );
      final conflictingOrder = orders
          .where(
            (o) =>
                o.tableNumber == tableNumber &&
                o.fulfillmentType == 'on_site' &&
                o.status != 'delivered' &&
                o.status != 'cancelled' &&
                o.staffId != requestingStaffId,
          )
          .firstOrNull;
      if (conflictingOrder != null) {
        throw Exception(
          'Table $tableNumber est déjà assignée au serveur #${conflictingOrder.staffId}',
        );
      }
    }

    table.status = 'occupied';
    await DatabaseService.updatePosTable(table);
    await ensureTables();
  }

  Future<void> markTableFree(String tableNumber) async {
    PosTable? table;
    for (final t in _tables) {
      if (t.number == tableNumber) {
        table = t;
        break;
      }
    }
    if (table == null) return;
    table.status = 'available';
    await DatabaseService.updatePosTable(table);
    await ensureTables();
  }

  Future<void> freeAllTables() async {
    await ensureTables();

    for (final table in _tables) {
      if (table.status != 'available' && table.status != 'free') {
        table.status = 'available';
        await DatabaseService.updatePosTable(table);
      }
    }

    await ensureTables();
  }

  /// Transférer une commande d'une table à une autre
  Future<void> transferTable({
    required String fromTableNumber,
    required String toTableNumber,
    required PosOrder order,
  }) async {
    // Vérifier que la table de destination est libre
    PosTable? toTable;
    for (final t in _tables) {
      if (t.number == toTableNumber) {
        toTable = t;
        break;
      }
    }
    if (toTable == null) {
      throw Exception('Table de destination introuvable');
    }
    if (toTable.status != 'available' && toTable.status != 'free') {
      throw Exception('La table de destination n\'est pas disponible');
    }

    // Mettre à jour la commande avec la nouvelle table
    order.tableNumber = toTableNumber;
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);

    // Libérer l'ancienne table
    await markTableFree(fromTableNumber);

    // Marquer la nouvelle table comme occupée
    toTable.status = 'occupied';
    await DatabaseService.updatePosTable(toTable);
    await ensureTables();

    appLogger.i(
      '🔄 [TRANSFER] Commande #${order.id} transférée de la table $fromTableNumber vers $toTableNumber',
    );
  }

  Future<void> loadTables() async {
    await ensureTables();
  }

  Future<void> markOrderAsPaid(PosOrder order, String paymentMethod) async {
    // ✅ Vérification de propriété
    if (!isAdminEditor && !canAccessOrder(order)) {
      _error = 'Vous ne pouvez payer que vos propres commandes';
      update();
      return;
    }

    final normalized = normalizePaymentMethod(paymentMethod);
    order.paymentMethod = normalized.isEmpty ? paymentMethod : normalized;
    order.paymentStatus = 'paid';
    order.paidByStaffId = activeStaffId; // ✅ Tracer qui a effectué le paiement
    order.updatedAt = DateTime.now();

    // ✅ Sauvegarder paymentSplit s'il existe déjà (pour l'affichage des détails)
    // paymentSplit est défini avant l'appel de cette méthode
    if (order.paymentSplit == null || order.paymentSplit!.isEmpty) {
      // Créer un paymentSplit simple à partir de paymentMethod
      if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) {
        // ✅ Utiliser un JSON valide avec les clés entre guillemets
        // ✅ Utiliser 'payment_method' au lieu de 'method' pour la compatibilité
        final paymentEntry = {
          'payment_method': order.paymentMethod,
          'amount': order.totalPrice,
          'timestamp': DateTime.now().toIso8601String(),
        };
        order.paymentSplit = jsonEncode([paymentEntry]);
      }
    }

    // Libérer la table pour les commandes "on_site"
    if (order.fulfillmentType == 'on_site' && order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
      appLogger.d(
        '🔓 [TABLE FREE] Table ${order.tableNumber} libérée après paiement de la commande #${order.id}',
      );
    }

    await DatabaseService.updatePosOrder(order);

    // Mettre à jour l'UI immédiatement
    update();

    // Recharger les commandes pour afficher l'état mis à jour
    await loadOrdersToday();

    appLogger.i(
      '✅ [PAYMENT] Commande #${order.id} marquée comme payée (method: ${order.paymentMethod}, paidByStaffId: ${order.paidByStaffId})',
    );
    if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
      appLogger.d(
        '💳 [PAYMENT] paymentSplit sauvegardé: ${order.paymentSplit}',
      );
    }
  }

  /// Mark order as paid with split payment (multiple payment methods)
  Future<void> markOrderAsPaidWithSplit(
    PosOrder order,
    List<Map<String, dynamic>> paymentEntries,
  ) async {
    // ✅ Vérification de propriété
    if (!isAdminEditor && !canAccessOrder(order)) {
      _error = 'Vous ne pouvez payer que vos propres commandes';
      update();
      return;
    }

    if (paymentEntries.isEmpty) {
      throw Exception('Aucun paiement fourni');
    }

    // If only one payment, use the simple method
    if (paymentEntries.length == 1) {
      final entry = paymentEntries.first;
      await markOrderAsPaid(order, entry['method'] as String);
      return;
    }

    // Multiple payments - store as JSON
    final paymentList = paymentEntries.map((entry) {
      return {
        'payment_method': entry['method'],
        'amount': entry['amount'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).toList();

    order.paymentSplit = jsonEncode(paymentList);
    order.paymentMethod = 'split'; // Mark as split payment
    order.paymentStatus = 'paid';
    order.paidByStaffId = activeStaffId; // ✅ Tracer qui a effectué le paiement
    order.updatedAt = DateTime.now();

    // Libérer la table pour les commandes "on_site"
    if (order.fulfillmentType == 'on_site' && order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
      appLogger.d(
        '🔓 [TABLE FREE] Table ${order.tableNumber} libérée après paiement de la commande #${order.id}',
      );
    }

    await DatabaseService.updatePosOrder(order);

    // Mettre à jour l'UI immédiatement
    update();

    // Recharger les commandes pour afficher l'état mis à jour
    await loadOrdersToday();

    final methods = paymentEntries
        .map((e) => paymentMethodLabel(e['method'] as String?))
        .join(', ');
    appLogger.i(
      '✅ [PAYMENT SPLIT] Commande #${order.id} marquée comme payée (methods: $methods)',
    );
  }

  /// Mark specific order items as paid (partial payment by selection of products)
  Future<void> markOrderItemsAsPartiallyPaid(
    PosOrder order,
    Map<int, int> itemQuantities,
    List<Map<String, dynamic>> paymentEntries,
  ) async {
    // Permission check
    if (!isAdminEditor && !canAccessOrder(order)) {
      _error = 'Vous ne pouvez payer que vos propres commandes';
      update();
      return;
    }

    appLogger.i(
      '🔍 [PARTIAL PAYMENT] order=${order.id} start itemQuantities=${itemQuantities.keys.toList()} entries=$paymentEntries',
    );
    if (itemQuantities.isEmpty) {
      throw Exception('Aucun article sélectionné');
    }

    // Load items for the order
    final allItems = await DatabaseService.getPosOrderItems(order.id);
    appLogger.i(
      '🔍 [PARTIAL PAYMENT] order=${order.id} loaded allItems=${allItems.length}',
    );
    final selectedItems = allItems
        .where((it) => itemQuantities.keys.contains(it.id))
        .toList();
    if (selectedItems.isEmpty) {
      throw Exception('Articles sélectionnés introuvables');
    }
    final totalSelected = selectedItems.fold<double>(0.0, (sum, it) {
      final qty = itemQuantities[it.id] ?? 0;
      return sum + (it.unitPrice * qty);
    });
    final paymentSum = paymentEntries.fold<double>(
      0.0,
      (s, e) => s + (e['amount'] as num).toDouble(),
    );
    appLogger.i(
      '🔍 [PARTIAL PAYMENT] order=${order.id} totalSelected=$totalSelected paymentSum=$paymentSum',
    );

    // Append payment entries to order.paymentSplit for history and traceability
    List<dynamic> existingOrderPayments = [];
    if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
      try {
        existingOrderPayments = jsonDecode(order.paymentSplit!);
      } catch (_) {
        existingOrderPayments = [];
      }
    }

    final timestamp = DateTime.now().toIso8601String();
    for (final entry in paymentEntries) {
      final map = {
        'payment_method': entry['method'],
        'amount': entry['amount'],
        'timestamp': timestamp,
        'applied_to_items': itemQuantities.entries
            .map((e) => {'item_id': e.key, 'quantity': e.value})
            .toList(),
      };
      existingOrderPayments.add(map);
    }
    order.paymentSplit = jsonEncode(existingOrderPayments);

    // Update each selected item: add partial payment entry, update paidAmount/status
    int getRemainingQuantity(PosOrderItem item) {
      if (item.unitPrice <= 0) {
        return item.quantity;
      }
      final paidQty = (item.paidAmount / item.unitPrice).round();
      return (item.quantity - paidQty).clamp(0, item.quantity);
    }

    for (final it in selectedItems) {
      final remainingQty = getRemainingQuantity(it);
      final qtyToMark = itemQuantities[it.id] ?? 0;
      appLogger.i(
        '🔍 [PARTIAL PAYMENT] order=${order.id} item=${it.id} remainingQty=$remainingQty qtyToMark=$qtyToMark paidAmount=${it.paidAmount} unitPrice=${it.unitPrice} totalQty=${it.quantity}',
      );
      if (qtyToMark <= 0) {
        throw Exception('Quantité invalide pour l\'article ${it.productName}');
      }
      if (qtyToMark > remainingQty) {
        throw Exception(
          'La quantité sélectionnée pour ${it.productName} dépasse le reste à payer.',
        );
      }
      final amountToMark = it.unitPrice * qtyToMark;

      // Build partial payment entry for the item
      final itemPayment = {
        'item_id': it.id,
        'product_id': it.productId,
        'product_name': it.productName,
        'quantity_paid': qtyToMark,
        'amount_paid': amountToMark,
        'payment_methods': paymentEntries
            .map((e) => {'method': e['method'], 'amount': e['amount']})
            .toList(),
        'timestamp': timestamp,
      };

      // Append to existing partialPaymentHistory JSON
      List<dynamic> history = [];
      if (it.partialPaymentHistory != null &&
          it.partialPaymentHistory!.isNotEmpty) {
        try {
          history = jsonDecode(it.partialPaymentHistory!);
        } catch (_) {
          history = [];
        }
      }
      history.add(itemPayment);
      it.partialPaymentHistory = jsonEncode(history);

      // Update paid amount and status
      it.paidAmount = it.paidAmount + amountToMark;
      final itemTotal = it.unitPrice * it.quantity;
      if (it.paidAmount >= itemTotal - 0.01) {
        it.paymentStatus = 'paid';
      } else if (it.paidAmount > 0) {
        it.paymentStatus = 'partially_paid';
      }

      await DatabaseService.updatePosOrderItem(it);
    }

    // If all items on the order are now paid, mark order as paid.
    // Otherwise preserve partial payment state on the order.
    final refreshedItems = await DatabaseService.getPosOrderItems(order.id);
    final allPaid = refreshedItems.every((it) => it.paymentStatus == 'paid');
    if (allPaid) {
      appLogger.i(
        '🔍 [PARTIAL PAYMENT] order=${order.id} all items paid, marking order as paid',
      );
      order.paymentStatus = 'paid';
      // If multiple payment methods used, mark as split
      final uniqueMethods = paymentEntries
          .map((e) => e['method'] as String)
          .toSet()
          .toList();
      if (uniqueMethods.length > 1) {
        order.paymentMethod = 'split';
      } else {
        order.paymentMethod = uniqueMethods.first;
      }
      order.paidByStaffId = activeStaffId;
      // Free table if on_site
      if (order.fulfillmentType == 'on_site' && order.tableNumber != null) {
        await markTableFree(order.tableNumber!);
      }
    } else {
      appLogger.i(
        '🔍 [PARTIAL PAYMENT] order=${order.id} still partially paid',
      );
      order.paymentStatus = 'partially_paid';
      // Preserve an accurate order payment method for partial payments.
      final allPayments = <String>{};
      if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
        try {
          final decoded = jsonDecode(order.paymentSplit!);
          for (final payment in decoded) {
            final method = payment['payment_method'] as String?;
            if (method != null && method.isNotEmpty) {
              allPayments.add(method);
            }
          }
        } catch (_) {
          // ignore malformed split; fallback to current paymentEntries
        }
      }
      for (final entry in paymentEntries) {
        final method = entry['method'] as String?;
        if (method != null && method.isNotEmpty) {
          allPayments.add(method);
        }
      }
      if (allPayments.length > 1) {
        order.paymentMethod = 'split';
      } else if (allPayments.length == 1) {
        order.paymentMethod = allPayments.first;
      }
    }

    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);
    appLogger.i(
      '🔍 [PARTIAL PAYMENT] order=${order.id} order updated paymentStatus=${order.paymentStatus} paymentMethod=${order.paymentMethod}',
    );

    // Update UI and reload orders
    update();
    await loadOrdersToday();

    appLogger.i(
      '✅ [PARTIAL PAYMENT] Order #${order.id} items marked as paid: ${selectedItems.length} items, expected_total: $totalSelected, recorded_amount: $paymentSum',
    );
  }

  Future<void> loadOrderForEdit(PosOrder order) async {
    _error = null;

    // ✅ Vérifier si l'utilisateur est admin/superadmin depuis AuthController
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final currentUser = authController?.currentUser;
    final isAdminOrSuperadmin =
        currentUser != null &&
        (currentUser.role.trim().toLowerCase() == 'admin' ||
            currentUser.role.trim().toLowerCase() == 'superadmin');

    // ✅ Admins/Superadmins peuvent éditer sans staff actif
    if (!canEditOrders && !isAdminOrSuperadmin) {
      _error = 'Modification non autorisée';
      update();
      return;
    }

    // ✅ Pour les admins, on définit temporairement le staff actif si nécessaire
    if (isAdminOrSuperadmin && _activeStaff == null) {
      _activeStaff = currentUser;
      _activeStaffId = currentUser.id;
      _restaurantId = currentUser.restaurantId;
      await _loadRestaurantName();
      appLogger.i(
        '✅ Admin ${currentUser.name} set as active staff for order editing',
      );
    }

    // ✅ Vérification de propriété
    if (!isAdminEditor && !canAccessOrder(order)) {
      _error = 'Vous ne pouvez modifier que vos propres commandes';
      update();
      return;
    }

    appLogger.i('✏️ [LOAD EDIT] Loading Order #${order.id} for edit');
    appLogger.i(
      '   └─ Original: staffId=${order.staffId}, restaurantId=${order.restaurantId}, '
      'channel=${order.channel}, sourceLocalId=${order.sourceLocalId}',
    );

    await DatabaseService.init();
    final currentOrder =
        await DatabaseService.getPosOrderById(order.id) ?? order;
    if (!canEditOrderContent(currentOrder)) {
      _error = _orderEditRestrictionReason(currentOrder, forContent: true);
      update();
      return;
    }
    _editingOrderId = currentOrder.id;
    _fulfillmentType = currentOrder.fulfillmentType;
    _tableNumber = currentOrder.tableNumber;
    _customerName = currentOrder.customerName;
    _customerPhone = currentOrder.customerPhone;
    _deliveryAddress = currentOrder.deliveryAddress;
    _note = currentOrder.note;
    _paymentMethod = currentOrder.paymentMethod;
    _isGlovoDelivery =
        currentOrder.isGlovoDelivery &&
        currentOrder.fulfillmentType.trim().toLowerCase() == 'delivery';

    _cart.clear();
    // Don't load existing items into cart - server can only ADD new items
    // Existing items will remain in the order unchanged
    final items = await DatabaseService.getPosOrderItems(currentOrder.id);
    appLogger.i(
      '📝 [EDIT MODE] Order #${currentOrder.id} loaded with ${items.length} existing items (read-only)',
    );
    _orderEditSnapshot = _OrderEditSnapshot(
      originalOrder: _copyPosOrder(currentOrder),
      originalItems: items.map(_copyPosOrderItem).toList(growable: false),
      originalUpdatedAt: currentOrder.updatedAt,
      originalTotal: currentOrder.originalTotal,
      canEditCustomerData: canEditOrderCustomerData(currentOrder),
      canEditConfiguration: canEditOrderConfiguration(currentOrder),
    );

    appLogger.i('✅ [LOAD EDIT] Order #${order.id} loaded successfully');
    appLogger.i(
      '   └─ Edit context: editingOrderId=$_editingOrderId, '
      'activeStaffId=$_activeStaffId, restaurantId=$_restaurantId',
    );
    update();
  }

  Future<bool> editOrderDetails(
    PosOrder order, {
    required String fulfillmentType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
  }) async {
    _error = null;
    if (!canEditOrders) {
      _error = 'Modification non autorisee';
      update();
      return false;
    }

    // Do not allow changing table number - only products can be edited
    final originalTable = order.tableNumber;
    if (originalTable != null && originalTable.isNotEmpty) {
      // Force tableNumber to remain the same as original
      tableNumber = originalTable;
    }

    final now = DateTime.now();
    final sameDay =
        order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
    if (order.status != 'pending' || !sameDay) {
      _error = 'Commande non modifiable';
      update();
      return false;
    }

    final normalizedTable = tableNumber?.trim();
    final normalizedName = customerName?.trim();
    final normalizedPhone = customerPhone?.trim();
    final normalizedAddress = deliveryAddress?.trim();

    if (fulfillmentType == 'on_site' &&
        (normalizedTable == null || normalizedTable.isEmpty)) {
      _error = 'Table obligatoire pour sur place';
      update();
      return false;
    }
    if ((fulfillmentType == 'pickup' || fulfillmentType == 'delivery') &&
        ((normalizedName == null || normalizedName.isEmpty) ||
            (normalizedPhone == null || normalizedPhone.isEmpty))) {
      _error = 'Nom et telephone obligatoires';
      update();
      return false;
    }
    if (fulfillmentType == 'delivery' &&
        (normalizedAddress == null || normalizedAddress.isEmpty)) {
      _error = 'Adresse obligatoire pour livraison';
      update();
      return false;
    }

    final oldTable = order.tableNumber;
    final oldType = order.fulfillmentType;
    final newTable = fulfillmentType == 'on_site' ? normalizedTable : null;

    order.fulfillmentType = fulfillmentType;
    order.tableNumber = (newTable == null || newTable.isEmpty)
        ? null
        : newTable;
    order.customerName = (normalizedName == null || normalizedName.isEmpty)
        ? null
        : normalizedName;
    order.customerPhone = (normalizedPhone == null || normalizedPhone.isEmpty)
        ? null
        : normalizedPhone;
    order.deliveryAddress =
        fulfillmentType == 'delivery' &&
            normalizedAddress != null &&
            normalizedAddress.isNotEmpty
        ? normalizedAddress
        : null;
    order.updatedAt = DateTime.now();

    await DatabaseService.updatePosOrder(order);
    await _enqueueOrderSyncById(order.id);

    if (oldType == 'on_site' &&
        oldTable != null &&
        oldTable.isNotEmpty &&
        (fulfillmentType != 'on_site' || oldTable != order.tableNumber)) {
      await markTableFree(oldTable);
    }
    if (fulfillmentType == 'on_site' &&
        order.tableNumber != null &&
        order.tableNumber!.isNotEmpty &&
        (oldType != 'on_site' || oldTable != order.tableNumber)) {
      await markTableOccupied(order.tableNumber!);
    }

    await loadOrdersToday();
    update();
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Order Delivery methods - LOCAL ONLY (no backend sync)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ✅ Assigner un livreur localement à une commande de livraison (TOUS CANAUX)
  /// Fonctionne pour les commandes POS, API, Web, etc.
  /// Accessible par les serveurs, livreurs et admins
  Future<OrderDelivery?> assignLivreurToDelivery({
    required PosOrder order,
    required int livreurId,
    String? livreurName,
    String? livreurPhone,
  }) async {
    try {
      // Check if order is delivery type
      if (order.fulfillmentType != 'delivery') {
        _error =
            'Commande n\'est pas une livraison (type: ${order.fulfillmentType})';
        return null;
      }

      // Can't assign livreur to cancelled orders (but CAN assign to pending orders)
      if (order.status == 'cancelled') {
        _error = 'Impossible d\'assigner un livreur à une commande annulée';
        return null;
      }

      // Utiliser la méthode DatabaseService pour assigner le livreur
      final delivery = await DatabaseService.assignLivreurToDelivery(
        order: order,
        livreurId: livreurId,
        livreurName: livreurName,
        livreurPhone: livreurPhone,
      );

      if (delivery == null) {
        _error = 'Échec de l\'assignation du livreur';
      }

      update();
      return delivery;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }

  /// ✅ Assigner un livreur localement SANS synchronisation backend
  /// Utilisé pour la comptabilité locale uniquement
  Future<OrderDelivery?> assignLivreurLocally({
    required PosOrder order,
    required int livreurId,
    String? livreurName,
    String? livreurPhone,
  }) async {
    try {
      // Check if order is delivery type
      if (order.fulfillmentType != 'delivery') {
        _error =
            'Commande n\'est pas une livraison (type: ${order.fulfillmentType})';
        return null;
      }

      // Can't assign livreur to pending or cancelled orders
      if (order.status == 'pending' || order.status == 'cancelled') {
        _error =
            'Impossible d\'assigner un livreur à une commande ${order.status}';
        return null;
      }

      // ✅ Créer l'assignation localement SANS appel backend
      final delivery = OrderDelivery(
        orderId: order.id,
        livreurId: livreurId,
        livreurName: livreurName,
        livreurPhone: livreurPhone,
        assignedAt: DateTime.now(),
        pickedUpAt: null,
        deliveredAt: null,
        status: 'assigned',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder localement
      await _saveOrderDeliveryLocally(delivery);

      return delivery;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }

  /// ✅ Compter les commandes par livreur (local)
  /// Retourne un map { livreurId: count }
  Future<Map<int, int>> countOrdersByLivreur({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await DatabaseService.init();

    // Récupérer toutes les livraisons
    final deliveries = await DatabaseService.getAllOrderDeliveries();

    // Filtrer par date si spécifié
    var filteredDeliveries = deliveries;
    if (fromDate != null) {
      filteredDeliveries = filteredDeliveries
          .where(
            (d) =>
                d.createdAt.isAtSameMomentAs(fromDate) ||
                d.createdAt.isAfter(fromDate),
          )
          .toList();
    }
    if (toDate != null) {
      filteredDeliveries = filteredDeliveries
          .where(
            (d) =>
                d.createdAt.isAtSameMomentAs(toDate) ||
                d.createdAt.isBefore(toDate),
          )
          .toList();
    }

    // Compter par livreur
    final counts = <int, int>{};
    for (final delivery in filteredDeliveries) {
      final livreurId = delivery.livreurId;
      if (livreurId != null && livreurId > 0) {
        counts[livreurId] = (counts[livreurId] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// ✅ Obtenir les détails des livraisons par livreur (local)
  Future<List<OrderDelivery>> getDeliveriesByLivreur({
    required int livreurId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await DatabaseService.init();

    // Récupérer toutes les livraisons
    final allDeliveries = await DatabaseService.getAllOrderDeliveries();

    // Filtrer par livreur
    var filteredDeliveries = allDeliveries
        .where((d) => d.livreurId == livreurId)
        .toList();

    // Filtrer par date si spécifié
    if (fromDate != null) {
      filteredDeliveries = filteredDeliveries
          .where(
            (d) =>
                d.createdAt.isAtSameMomentAs(fromDate) ||
                d.createdAt.isAfter(fromDate),
          )
          .toList();
    }
    if (toDate != null) {
      filteredDeliveries = filteredDeliveries
          .where(
            (d) =>
                d.createdAt.isAtSameMomentAs(toDate) ||
                d.createdAt.isBefore(toDate),
          )
          .toList();
    }

    return filteredDeliveries;
  }

  /// ✅ Get available livreurs (staff users with delivery role)
  Future<List<Map<String, dynamic>>> getAvailableLivreurs() async {
    try {
      await DatabaseService.init();
      final allUsers = await DatabaseService.getAllUsers();

      // Filter for staff/delivery users and map to simple format
      final staffUsers = allUsers.where((user) {
        final role = user.role.toLowerCase();
        return role == 'staff' || role == 'livreur' || role == 'delivery';
      }).toList();

      return staffUsers
          .map(
            (user) => {
              'id': user.id,
              'name': user.name,
              'phone': user.phone,
              'isActive': true, // Assume all staff are active by default
            },
          )
          .toList();
    } catch (e) {
      // appLogger.e('Error getting available livreurs: $e');
      return [];
    }
  }

  /// ✅ Set livreur info for current order (delivery only)
  void setLivreurInfo({
    required int livreurId,
    String? livreurName,
    String? livreurPhone,
  }) {
    if (_fulfillmentType != 'delivery') {
      _error = 'Livreur info can only be set for delivery orders';
      update();
      return;
    }

    // Store livreur info in the current order being created
    // This will be picked up when the order is saved
    _deliveryLivreurId = livreurId;
    _deliveryLivreurName = livreurName;
    _deliveryLivreurPhone = livreurPhone;

    update();
  }

  /// ✅ Annuler une commande LOCALEMENT (réservé aux admins)
  /// SANS synchronisation backend
  Future<bool> cancelOrderLocally(PosOrder order, {String? reason}) async {
    // ✅ Vérifier que c'est un admin
    if (!canModifyOrders) {
      _error = 'Annulation réservée aux admins';
      update();
      return false;
    }

    _error = null;

    // ✅ Modifier localement uniquement
    order.status = 'cancelled';
    order.cancelReason = reason;
    order.updatedAt = DateTime.now();

    // ✅ Sauvegarder localement SANS sync
    await DatabaseService.updatePosOrder(order);

    // ✅ Libérer la table si nécessaire
    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }

    // ✅ Recharger les commandes
    await loadOrdersToday();

    update();
    return true;
  }

  // Order Delivery methods
  Future<OrderDelivery?> assignLivreurToOrder({
    required PosOrder order,
    required int livreurId,
    String? livreurName,
    String? livreurPhone,
  }) async {
    try {
      // Check if order is delivery type
      if (order.fulfillmentType != 'delivery') {
        _error =
            'Commande n\'est pas une livraison (type: ${order.fulfillmentType})';
        // appLogger.i('❌ $_error');
        return null;
      }

      // Can't assign livreur to pending or cancelled orders
      if (order.status == 'pending' || order.status == 'cancelled') {
        _error =
            'Impossible d\'assigner un livreur à une commande ${order.status}';
        // appLogger.i('❌ $_error');
        return null;
      }

      // Call backend API
      final restaurantId = _resolveRestaurantIdForOrder(order);
      if (restaurantId == null) {
        _error = 'Restaurant introuvable pour cette commande';
        // appLogger.i('❌ $_error');
        return null;
      }

      final backendOrderId = await _resolveBackendOrderIdForDelivery(order);
      if (backendOrderId == null) {
        _error =
            'Commande non synchronisée côté backend. Lance une sync puis réessaie.';
        // appLogger.i('❌ $_error');
        return null;
      }

      final apiClient = Get.find<ApiClient>();

      // Debug: API Client token check
      // appLogger.i('🔑 Checking API Client token...');
      // appLogger.i('   - ApiClient registered: ${Get.isRegistered<ApiClient>() ? "YES" : "NO"}');
      // appLogger.i('   - ApiClient instance: ${apiClient.hashCode}');
      // appLogger.i('   - Token present: ${apiClient.token.isNotEmpty ? "YES" : "NO"}');
      // appLogger.i('   - Token preview: ${apiClient.token.isNotEmpty ? "${apiClient.token.substring(0, 10)}..." : "N/A"}');
      // appLogger.i('   - Token length: ${apiClient.token.length}');

      if (apiClient.token.isEmpty) {
        _error =
            'Token d\'authentification manquant. Veuillez vous reconnecter.';
        return null;
      }

      final apiService = OrderDeliveryApiService(
        apiClient: apiClient,
        restaurantId: restaurantId,
      );

      final result = await apiService.assignLivreur(
        orderId: backendOrderId,
        livreurId: livreurId,
      );

      if (result != null) {
        // Save to local database
        result.orderId = order.id;
        result.livreurName = livreurName;
        result.livreurPhone = livreurPhone;
        result.assignedAt = DateTime.now();
        result.updatedAt = DateTime.now();

        await _saveOrderDeliveryLocally(result);

        return result;
      }

      _error = 'Échec de l\'assignation du livreur';
      return null;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }

  Future<OrderDelivery?> markOrderPickedUp(PosOrder order) async {
    try {
      final restaurantId = _resolveRestaurantIdForOrder(order);
      if (restaurantId == null) {
        _error = 'Restaurant introuvable pour cette commande';
        return null;
      }

      final backendOrderId = await _resolveBackendOrderIdForDelivery(order);
      if (backendOrderId == null) {
        _error =
            'Commande non synchronisée côté backend. Lance une sync puis réessaie.';
        return null;
      }

      final apiService = OrderDeliveryApiService(
        apiClient: Get.find<ApiClient>(),
        restaurantId: restaurantId,
      );

      final result = await apiService.markPickup(backendOrderId);

      if (result != null) {
        result.orderId = order.id;
        result.updatedAt = DateTime.now();
        await _saveOrderDeliveryLocally(result);
        return result;
      }

      _error = 'Échec du marquage pickup';
      return null;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }

  Future<OrderDelivery?> markOrderDelivered(PosOrder order) async {
    try {
      final restaurantId = _resolveRestaurantIdForOrder(order);
      if (restaurantId == null) {
        _error = 'Restaurant introuvable pour cette commande';
        return null;
      }

      final backendOrderId = await _resolveBackendOrderIdForDelivery(order);
      if (backendOrderId == null) {
        _error =
            'Commande non synchronisée côté backend. Lance une sync puis réessaie.';
        return null;
      }

      final apiService = OrderDeliveryApiService(
        apiClient: Get.find<ApiClient>(),
        restaurantId: restaurantId,
      );

      final result = await apiService.markDelivered(backendOrderId);

      if (result != null) {
        result.orderId = order.id;
        result.updatedAt = DateTime.now();
        await _saveOrderDeliveryLocally(result);
        order.status = 'delivered';
        order.updatedAt = DateTime.now();
        await DatabaseService.updatePosOrder(order);
        await loadOrdersToday();
        update();
        return result;
      }

      _error = 'Échec du marquage delivered';
      return null;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }

  Future<OrderDelivery?> getOrderDelivery(int orderId) async {
    try {
      // First check local DB
      final local = await DatabaseService.getOrderDeliveryByOrderId(orderId);
      if (local != null) {
        return local;
      }

      final order = await DatabaseService.getPosOrderById(orderId);
      if (order == null) {
        return null;
      }

      // Then try backend
      final restaurantId = _resolveRestaurantIdForOrder(order);
      if (restaurantId == null) {
        return null;
      }

      final backendOrderId = await _resolveBackendOrderIdForDelivery(order);
      if (backendOrderId == null) {
        return null;
      }

      final apiService = OrderDeliveryApiService(
        apiClient: Get.find<ApiClient>(),
        restaurantId: restaurantId,
      );

      final remote = await apiService.getDeliveryDetails(backendOrderId);
      if (remote != null) {
        remote.orderId = orderId;
        await _saveOrderDeliveryLocally(remote);
        return remote;
      }

      return null;
    } catch (e) {
      _error = 'Erreur: $e';
      return null;
    }
  }
}
