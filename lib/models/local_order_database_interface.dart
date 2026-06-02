// ============================================================
// 5️⃣ INTERFACES POUR LA BASE DE DONNÉES LOCALE
// ============================================================

/// Interface pour votre DB locale (Hive/Drift/SQLite)
abstract class OrderLocalDatabase {
  /// Récupérer les commandes dans une plage de dates
  ///
  /// Parameters:
  /// - [restaurantId] : ID du restaurant (obligatoire)
  /// - [staffId] : ID du staff (optionnel)
  /// - [startDate] : Date de début de la plage
  /// - [endDate] : Date de fin de la plage
  /// - [excludeDeleted] : Exclure les commandes supprimées
  /// - [excludeAlreadySynced] : Exclure les commandes déjà synchronisées
  ///
  /// Returns: Liste de commandes locales
  Future<List<LocalOrder>> getOrdersByDateRange({
    required int restaurantId,
    int? staffId,
    required DateTime startDate,
    required DateTime endDate,
    bool excludeDeleted = false,
    bool excludeAlreadySynced = false,
  });

  /// Mettre à jour le flag de synchronisation daily
  ///
  /// Parameters:
  /// - [localIds] : Liste des IDs locales des commandes
  /// - [isDailySynced] : Flag indiquant que les commandes ont été synced
  ///
  /// Remarque: NE PAS supprimer les commandes, juste mettre à jour le flag
  Future<void> updateOrdersSyncFlag({
    required List<String> localIds,
    required bool isDailySynced,
  });

  /// Récupérer une commande par son ID local
  Future<LocalOrder?> getOrderByLocalId(String localId);

  /// Récupérer toutes les commandes non synchronisées
  Future<List<LocalOrder>> getUnsyncedOrders({required int restaurantId});
}

/// Modèle local d'une commande
class LocalOrder {
  final String localId;
  final int staffId;
  final int restaurantId;
  final String channel;
  final String fulfillmentType;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final double totalPrice;
  final double originalTotal;
  final double? discountAmount;
  final bool? hasDiscount;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? tableNumber;
  final String? note;
  final int? rewardId;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LocalOrderItem> items;
  final bool isDailySynced;
  final bool isDeleted;

  LocalOrder({
    required this.localId,
    required this.staffId,
    required this.restaurantId,
    required this.channel,
    required this.fulfillmentType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.totalPrice,
    required this.originalTotal,
    this.discountAmount,
    this.hasDiscount,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.tableNumber,
    this.note,
    this.rewardId,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.isDailySynced = false,
    this.isDeleted = false,
  });

  /// Helper: vérifier si la commande est prête pour le daily sync
  bool get readyForDailySync => !isDeleted && !isDailySynced;

  /// Helper: afficher un résumé
  @override
  String toString() =>
      'LocalOrder('
      'localId: $localId, '
      'channel: $channel, '
      'status: $status, '
      'paymentStatus: $paymentStatus, '
      'items: ${items.length}'
      ')';
}

/// Item local d'une commande
class LocalOrderItem {
  final String localId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final int? groupNumber;
  final String? groupLabel;
  final String? itemNote;
  final String? serviceCourseKey;
  final String? serviceCourseLabel;

  LocalOrderItem({
    required this.localId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.groupNumber,
    this.groupLabel,
    this.itemNote,
    this.serviceCourseKey,
    this.serviceCourseLabel,
  });

  /// Helper: calculer le total line
  double get lineTotal => unitPrice * quantity;

  @override
  String toString() =>
      'LocalOrderItem('
      'localId: $localId, '
      'productId: $productId, '
      'quantity: $quantity, '
      'lineTotal: $lineTotal'
      ')';
}
