import 'package:isar/isar.dart';

part 'customer.g.dart';

@Collection()
class Customer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String phone;

  String name;
  String? address;
  String? email;

  int orderCount;
  double totalSpent;
  DateTime lastOrderDate;

  DateTime createdAt;
  DateTime updatedAt;

  Customer()
    : id = Isar.autoIncrement,
      phone = '',
      name = '',
      orderCount = 0,
      totalSpent = 0.0,
      lastOrderDate = DateTime.now(),
      createdAt = DateTime.now(),
      updatedAt = DateTime.now();

  Customer.create({
    required this.phone,
    required this.name,
    this.address,
    this.email,
    this.orderCount = 0,
    this.totalSpent = 0.0,
    DateTime? lastOrderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = Isar.autoIncrement,
       lastOrderDate = lastOrderDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Customer copyWith({
    Id? id,
    String? phone,
    String? name,
    String? address,
    String? email,
    int? orderCount,
    double? totalSpent,
    DateTime? lastOrderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer()
      ..id = id ?? this.id
      ..phone = phone ?? this.phone
      ..name = name ?? this.name
      ..address = address ?? this.address
      ..email = email ?? this.email
      ..orderCount = orderCount ?? this.orderCount
      ..totalSpent = totalSpent ?? this.totalSpent
      ..lastOrderDate = lastOrderDate ?? this.lastOrderDate
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? DateTime.now();
  }
}
