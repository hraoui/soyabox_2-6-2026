import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'user_seeder.dart';

/// DatabaseSeeder - Main seeder class to run all seeders
/// Similar to Laravel's DatabaseSeeder
class DatabaseSeeder {
  /// Run all seeders
  static Future<void> seed(Isar isar) async {
    debugPrint('Running DatabaseSeeder...');
    final usersBefore = await isar.users.count();
    debugPrint('Users before seeding: $usersBefore');
    
    // Run individual seeders
    await UserSeeder.seed(isar);
    
    final usersAfter = await isar.users.count();
    debugPrint('Users after seeding: $usersAfter');
    debugPrint('DatabaseSeeder completed!');
  }
}
