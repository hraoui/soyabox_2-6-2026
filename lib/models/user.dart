import 'package:isar/isar.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

part 'user.g.dart'; // This is required for Isar to generate code

@Collection()
class User {
  Id id = Isar.autoIncrement; // You can also use id = Isar.autoIncrement;

  String name;
  String phone;
  String email;
  String password; // Hashé (bcrypt/sha256)
  String role; // 'staff'|'admin'|'livreur'|'superadmin'|'client'|'cashier'
  int? restaurantId; // Null pour superadmin
  String? pinCode; // ✅ OBLIGATOIRE pour staff (4-6 chiffres)
  String? badgeCode; // Optionnel: identifiant badge/carte pour ouvrir le POS
  bool isActive;

  DateTime createdAt;
  DateTime updatedAt;

  User({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
    this.restaurantId,
    this.pinCode,
    this.badgeCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isClient() => role == 'client';
  bool isStaff() => role == 'staff';
  bool isAdmin() => role == 'admin';
  bool isLivreur() => role == 'livreur';
  bool isSuperadmin() => role == 'superadmin';
  bool isCashier() => role == 'cashier'; // Ajout de la méthode pour le rôle caissier

  bool isValidPin() {
    if (pinCode == null || pinCode!.isEmpty) return false;
    if (pinCode!.length < 4 || pinCode!.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pinCode!);
  }

  bool hasValidBadgeCode() {
    return badgeCode != null && badgeCode!.trim().isNotEmpty;
  }

  // Method to hash password
  static String hashPassword(String password) {
    var bytes = utf8.encode(password); // encode the password to bytes
    var digest = sha256.convert(bytes); // hash the password
    return digest.toString(); // return the hashed password as string
  }

  // Method to verify password
  bool verifyPassword(String password) {
    return hashPassword(password) == this.password;
  }
}