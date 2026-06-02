import 'package:isar/isar.dart';

part 'product_model.g.dart'; // This is required for Isar to generate code

@Collection()
class Product {
  Id id = Isar.autoIncrement; // You can also use id = Isar.autoIncrement;
  String name;
  String? description;
  double price;
  String? image;
  int categoryId;
  bool offer = false;
  bool isAvailable = true;
  int sortOrder = 0;

  DateTime createdAt;
  DateTime updatedAt;

  Product({
    this.id = Isar.autoIncrement,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.categoryId,
    this.offer = false,
    this.isAvailable = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}
