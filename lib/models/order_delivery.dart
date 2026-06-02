import 'package:isar/isar.dart';

part 'order_delivery.g.dart';

@Collection()
class OrderDelivery {
  Id id = Isar.autoIncrement;

  /// ID de la commande PosOrder
  @Index()
  int orderId;

  /// ID du livreur assigné
  int? livreurId;

  /// Nom du livreur (copie pour affichage)
  String? livreurName;

  /// Phone du livreur (copie pour affichage)
  String? livreurPhone;

  /// Statut de la livraison
  /// pending | assigned | picked_up | delivered
  @Index()
  String status;

  /// Date d'assignation
  DateTime? assignedAt;

  /// Date de pickup
  DateTime? pickedUpAt;

  /// Date de livraison
  DateTime? deliveredAt;

  /// Notes de livraison
  String? note;

  DateTime createdAt;
  DateTime updatedAt;

  OrderDelivery({
    this.id = Isar.autoIncrement,
    required this.orderId,
    this.livreurId,
    this.livreurName,
    this.livreurPhone,
    this.status = 'pending',
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}
