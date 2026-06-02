import 'package:isar/isar.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

part 'delivery.g.dart';

@Collection()
class Delivery {
  Id id = Isar.autoIncrement;

  String name;
  String phone;
  String email;
  String password;
  int restaurantId;
  bool isActive;
  String? pinCode; // ✅ PIN pour connexion POS
  String? fcmToken;

  DateTime createdAt;
  DateTime updatedAt;

  Delivery({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.restaurantId,
    this.isActive = true,
    this.pinCode,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isActif() => isActive;

  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password) {
    return hashPassword(password) == this.password;
  }
}
