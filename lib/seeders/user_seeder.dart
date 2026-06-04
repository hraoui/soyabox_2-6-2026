import 'dart:io';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/path_utils.dart';

/// UserSeeder - Equivalent to Laravel UserSeeder
/// Seeds ONLY admin users locally (staff/livreurs from backend only)
/// Executes ONLY on first installation
/// Uses a flag file for tracking (no SharedPreferences - desktop app)
class UserSeeder {
  static const String _seedFlagFileName = '.user_seeder_has_run_v2';

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Static method to seed the User collection
  /// ONLY runs once on first installation
  /// Does NOT delete backend users (staff/livreurs)
  static Future<void> seed(Isar isar) async {
    debugPrint('Starting UserSeeder...');

    // ✅ Vérifier si le seeder a déjà été exécuté en utilisant un fichier flag
    final hasSeeded = await _checkIfSeeded();

    final existingCount = await isar.users.count();
    debugPrint('Existing users count: $existingCount');

    // ✅ Define ONLY 3 users to seed locally (Superadmin + 2 Admins)
    final usersToSeed = [
      // 🔶 Superadmin user (no restaurantId, with PIN code)
      User(
        name: 'Super Admin',
        phone: '0600000000',
        email: 'superadmin@soyabox.com',
        password: User.hashPassword('superadmin123'),
        role: 'superadmin',
        restaurantId: null,
        pinCode: 'superadmin123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // 🟢 Admin Casablanca (restaurantId = 1)
      User(
        name: 'Admin Casablanca',
        phone: '0611111111',
        email: 'admin.casablanca@soyabox.com',
        password: User.hashPassword('casa123'),
        role: 'admin',
        restaurantId: 1,
        pinCode: 'casa123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // 🔵 Admin Mohammedia (restaurantId = 2)
      User(
        name: 'Admin Mohammedia',
        phone: '0622222222',
        email: 'admin.mohammedia@soyabox.com',
        password: User.hashPassword('moha123'),
        role: 'admin',
        restaurantId:2,
        pinCode: 'moha123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Clean up any duplicate seeded users by normalized email first
    await _cleanupDuplicateSeededUsers(isar, usersToSeed);

    if (hasSeeded) {
      debugPrint(
        '✅ UserSeeder already executed on previous installation, skipping new user creation.',
      );
      return;
    }

    // Create the 3 users ONLY if they don't exist (by normalized email)
    int createdCount = 0;
    for (final userData in usersToSeed) {
      final normalizedSeedEmail = _normalizeEmail(userData.email);
      final allUsers = await isar.users.where().findAll();
      final matchingUsers = allUsers
          .where((user) => _normalizeEmail(user.email) == normalizedSeedEmail)
          .toList();
      final existingUser = matchingUsers.isNotEmpty ? matchingUsers.first : null;

      if (existingUser == null) {
        final userToInsert = User(
          name: userData.name,
          phone: userData.phone,
          email: normalizedSeedEmail,
          password: userData.password,
          role: userData.role,
          restaurantId: userData.restaurantId,
          pinCode: userData.pinCode,
          isActive: userData.isActive,
          createdAt: userData.createdAt,
          updatedAt: userData.updatedAt,
        );

        await isar.writeTxn(() async {
          final userId = await isar.users.put(userToInsert);
          debugPrint(
            '✅ Created user: ${userToInsert.name} (${userToInsert.email}) with ID: $userId',
          );
          createdCount++;
        });
      } else {
        debugPrint(
          '⚠️ User already exists: ${userData.name} (${existingUser.email}), skipping creation...',
        );
      }
    }

    // ✅ Marquer le seeder comme exécuté en créant un fichier flag
    await _markAsSeeded();
    debugPrint('✅ UserSeeder marked as executed');

    final finalCount = await isar.users.count();
    debugPrint(
      'Final users count: $finalCount (created: $createdCount)',
    );
    debugPrint('✅ UserSeeder completed successfully!');
  }

  static Future<void> _cleanupDuplicateSeededUsers(
    Isar isar,
    List<User> usersToSeed,
  ) async {
    final allUsers = await isar.users.where().findAll();
    for (final userData in usersToSeed) {
      final normalizedSeedEmail = _normalizeEmail(userData.email);
      final matchingUsers = allUsers
          .where((user) => _normalizeEmail(user.email) == normalizedSeedEmail)
          .toList();
      if (matchingUsers.isEmpty) continue;

      final primaryUser = matchingUsers.first;

      if (primaryUser.email != normalizedSeedEmail) {
        primaryUser.email = normalizedSeedEmail;
      }
      if (primaryUser.role != userData.role) {
        primaryUser.role = userData.role;
      }
      if (primaryUser.pinCode != userData.pinCode) {
        primaryUser.pinCode = userData.pinCode;
      }
      if (primaryUser.restaurantId != userData.restaurantId) {
        primaryUser.restaurantId = userData.restaurantId;
      }
      if (primaryUser.password != userData.password) {
        primaryUser.password = userData.password;
      }
      if (primaryUser.isActive != userData.isActive) {
        primaryUser.isActive = userData.isActive;
      }

      primaryUser.updatedAt = DateTime.now();

      // Delete duplicate users that share the same normalized email
      if (matchingUsers.length > 1) {
        debugPrint(
          '⚠️ Found ${matchingUsers.length} duplicate seeded users for email $normalizedSeedEmail, keeping first and deleting the rest.',
        );
        for (var i = 1; i < matchingUsers.length; i++) {
          await isar.writeTxn(() async {
            await isar.users.delete(matchingUsers[i].id);
          });
        }
      }

      await isar.writeTxn(() async {
        await isar.users.put(primaryUser);
      });
    }
  }

  /// ✅ Check if seeder has already run (using flag file)
  static Future<bool> _checkIfSeeded() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final flagFile = File('${appDir.path}/$_seedFlagFileName');
      return await flagFile.exists();
    } catch (e) {
      // If error, assume not seeded
      debugPrint('⚠️ Could not check seed status: $e');
      return false;
    }
  }

  /// ✅ Mark seeder as executed (using flag file)
  static Future<void> _markAsSeeded() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final flagFile = File('${appDir.path}/$_seedFlagFileName');
      await flagFile.writeAsString(
        'seeded_at=${DateTime.now().toIso8601String()}',
      );
      debugPrint('✅ Seed flag file created at ${flagFile.path}');
    } catch (e) {
      debugPrint('⚠️ Could not mark as seeded: $e');
    }
  }
}


