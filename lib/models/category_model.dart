import 'package:isar/isar.dart';

part 'category_model.g.dart'; // This is required for Isar to generate code

@Collection()
class Category {
  Id id = Isar.autoIncrement; // You can also use id = Isar.autoIncrement;
  String name;
  String? image;
  bool isDeleted = false;

  DateTime createdAt;
  DateTime updatedAt;

  Category({
    this.id = Isar.autoIncrement,
    required this.name,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });
}