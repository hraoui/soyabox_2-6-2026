import 'package:isar/isar.dart';

part 'product_price.g.dart';

@Collection()
class ProductPrice {
  Id id = Isar.autoIncrement;

  @Index()
  int productId;

  @Index()
  String type; // 'glovo', 'restaurant', 'retail', 'wholesale', etc.

  double price;

  DateTime createdAt;
  DateTime updatedAt;

  ProductPrice({
    this.id = Isar.autoIncrement,
    required this.productId,
    required this.type,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the price type display name
  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'glovo':
        return 'Glovo';
      case 'restaurant':
        return 'Restaurant';
      case 'retail':
        return 'Détail';
      case 'wholesale':
        return 'Gros';
      default:
        return type.capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
