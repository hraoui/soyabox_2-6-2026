import 'dart:io';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

/// UserSeeder - Equivalent to Laravel UserSeeder
/// Seeds ONLY admin users locally (staff/livreurs from backend only)
/// Executes ONLY on first installation
/// Uses a flag file for tracking (no SharedPreferences - desktop app)
class UserSeeder {
  static const String _seedFlagFileName = '.user_seeder_has_run_v2';

  /// Static method to seed the User collection
  /// ONLY runs once on first installation
  /// Does NOT delete backend users (staff/livreurs)
  static Future<void> seed(Isar isar) async {
    debugPrint('Starting UserSeeder...');

    // ✅ Vérifier si le seeder a déjà été exécuté en utilisant un fichier flag
    final hasSeeded = await _checkIfSeeded();

    if (hasSeeded) {
      debugPrint(
        '✅ UserSeeder already executed on previous installation, skipping...',
      );
      return;
    }

    final existingCount = await isar.users.count();
    debugPrint('Existing users count: $existingCount');

    // ✅ NE PAS supprimer les utilisateurs existants (peut venir du backend sync)
    // On va juste ajouter les 3 admins s'ils n'existent pas déjà

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
        restaurantId: 2,
        pinCode: 'moha123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Create the 3 users ONLY if they don't exist (by email)
    int createdCount = 0;
    for (final userData in usersToSeed) {
      // Check if user already exists by email
      final existingUser = await isar.users
          .where()
          .filter()
          .emailEqualTo(userData.email)
          .findFirst();

      if (existingUser == null) {
        // User doesn't exist, create it
        await isar.writeTxn(() async {
          final userId = await isar.users.put(userData);
          debugPrint(
            '✅ Created user: ${userData.name} (${userData.email}) with ID: $userId',
          );
          createdCount++;
        });
      } else {
        debugPrint(
          '⚠️ User already exists: ${userData.name} (${userData.email}), skipping...',
        );
      }
    }

    // ✅ Marquer le seeder comme exécuté en créant un fichier flag
    await _markAsSeeded();
    debugPrint('✅ UserSeeder marked as executed');

    final finalCount = await isar.users.count();
    debugPrint(
      'Final users count: $finalCount (created: $createdCount, existing: ${existingCount - createdCount})',
    );
    debugPrint('✅ UserSeeder completed successfully!');
  }

  /// ✅ Check if seeder has already run (using flag file)
  static Future<bool> _checkIfSeeded() async {
    try {
      final appDir = await getApplicationSupportDirectory();
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
      final appDir = await getApplicationSupportDirectory();
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


