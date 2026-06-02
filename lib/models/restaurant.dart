import 'package:isar/isar.dart';

part 'restaurant.g.dart'; // This is required for Isar to generate code

@Collection()
class Restaurant {
  Id id = Isar.autoIncrement; // You can also use id = Isar.autoIncrement;

  String name;
  String address;
  String phone;
  bool isActive;

  DateTime createdAt;
  DateTime updatedAt;

  Restaurant({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}