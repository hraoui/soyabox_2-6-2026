// ignore_for_file: avoid_print

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'lib/models/user.dart';

void main() async {
  print('🔍 Checking Isar database for users...');
  
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );
  
  final count = await isar.users.count();
  print('📊 Total users in database: $count');
  
  final users = await isar.users.where().findAll();
  for (final user in users) {
    print('   - ID:${user.id} | ${user.name} | ${user.email} | Role: ${user.role} | PIN: ${user.pinCode != null ? "SET" : "NULL"}');
  }
  
  await isar.close();
  print('✅ Check complete');
}
