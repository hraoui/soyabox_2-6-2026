import 'package:get/get.dart';
import '../api/api_client.dart';
import '../data/app_constants.dart';
import '../models/user.dart';
import '../services/api_import_service.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/app_logger.dart';
import '../utils/badge_code_utils.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final RxList<User> _users = <User>[].obs;
  List<User> get users => _users.toList();

  // ✅ Flag to track if users have been synced to backend (in-memory only)
  bool _hasSyncedUsersToBackend = false;

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    // Don't fetch users or sync on init - wait for login instead
   
  }

  // ✅ Initialize users after login (call this from AuthController after successful login)
  Future<void> initAfterLogin() async {
    try {
     
      final restId = Get.find<AuthController>().currentUser?.restaurantId;
      final isSuperAdmin =
          Get.find<AuthController>().currentRole == 'superadmin';
      await fetchAllUsers(restaurantId: isSuperAdmin ? null : restId);

      // ✅ Auto-sync local users to backend (send local users to backend)
      await syncLocalUsersToBackend();
   
    } catch (e, stackTrace) {
     
      appLogger.e('User init failed', error: e, stackTrace: stackTrace);
    }
  }

  // ✅ Sync local users to backend (send unsynced local users to backend)
  // Called only ONCE per session to avoid duplications
  Future<void> syncLocalUsersToBackend() async {
    // ✅ Check if already synced in this session
    if (_hasSyncedUsersToBackend) {
      appLogger.i(
        '✅ Users already synced to backend in this session, skipping',
      );
      return;
    }

    try {
      appLogger.i('🔄 Syncing local users to backend...');
      final auth = Get.find<AuthController>();
      final currentUser = auth.currentUser;
      final role = auth.currentRole?.trim().toLowerCase();

      // ✅ SUPERADMIN: Can sync all users (no restaurant restriction)
      // Other users: Must have restaurantId
      final restId = currentUser?.restaurantId;
      final isSuperAdmin = role == 'superadmin';

      if (!isSuperAdmin && restId == null) {
        appLogger.w(
          '⚠️ No restaurant ID and not superadmin, skipping user sync',
        );
        return;
      }

      final apiService = ApiImportService(
        baseUrl: AppConstant.baseUrl,
        authToken: Get.find<ApiClient>().token,
      );

      // Get all local users
      final localUsers = await DatabaseService.getAllUsers();
      final unsyncedUsers = localUsers
          .where((u) => u.id < 1000 || u.id == 0)
          .toList();

      if (unsyncedUsers.isEmpty) {
        appLogger.i('✅ No unsynced local users');
        _hasSyncedUsersToBackend = true; // Mark as done
        return;
      }

      appLogger.i('📊 Found ${unsyncedUsers.length} unsynced local users');

      for (final user in unsyncedUsers) {
        try {
          appLogger.i('📤 Syncing user: ${user.name} (${user.email})...');

          // Try to create on backend
          final apiUser = await apiService.createUser(
            name: user.name,
            phone: user.phone,
            email: user.email,
            password: '123456', // Default password for existing users
            role: user.role,
            restaurantId: isSuperAdmin ? null : user.restaurantId,
            pinCode: user.pinCode,
            badgeCode: user.badgeCode,
            isActive: user.isActive,
          );

          if (apiUser != null && apiUser.id > 0) {
            // Update local user with API ID and PIN
            user.id = apiUser.id;
            if (apiUser.pinCode != null) {
              user.pinCode = apiUser.pinCode;
              appLogger.i('🔄 PIN backend reçu: ${apiUser.pinCode}');
            }
            await DatabaseService.updateUser(user);

            // Update local list
            final index = _users.indexWhere((u) => u.email == user.email);
            if (index != -1) {
              _users[index] = user;
            }

            appLogger.i('✅ Synced: ${user.name} -> API ID: ${apiUser.id}');
          } else {
            appLogger.i('⚠️ Backend returned null for ${user.name}');
          }
        } catch (e) {
          appLogger.i('⚠️ Failed to sync ${user.name}: $e');
          // Check if it's a duplicate email error
          if (e.toString().contains('déjà') ||
              e.toString().contains('already')) {
            appLogger.i('💡 This email is already registered in backend');
          }
        }
      }

      appLogger.i('🎉 Local users sync completed!');
      _hasSyncedUsersToBackend = true; // ✅ Mark as done
    } catch (e) {
      appLogger.i('💥 Error in syncLocalUsersToBackend: $e');
    }
  }

  Future<void> fetchAllUsers({int? restaurantId}) async {
    try {
      final auth = Get.find<AuthController>();
      final role = auth.currentRole ?? '';

      if (role == 'superadmin') {
        _users.assignAll(await DatabaseService.getAllUsers());
        return;
      }

      final restId = restaurantId ?? auth.currentUser?.restaurantId;
      if (restId == null || restId <= 0) {
        _users.clear();
        return;
      }
      final scoped = await DatabaseService.getUsersByRestaurant(restId);
      final filtered = scoped
          .where((u) => u.role == 'admin' || u.role == 'staff' || u.role == 'cashier' || u.role == 'livreur')
          .toList();
      _users.assignAll(filtered);
    } catch (e) {
      appLogger.i('Error fetching users: $e');
      rethrow;
    }
  }

  // Create a new user (for admin use)
  // ✅ Create locally first, then sync to backend (non-blocking)
  Future<User?> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    int? restaurantId,
    String? pinCode,
    String? badgeCode,
    bool isActive = true,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await DatabaseService.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      final normalizedBadgeCode = normalizeBadgeCode(badgeCode);
      if (normalizedBadgeCode.isNotEmpty) {
        final existingBadgeUser = await DatabaseService.getUserByBadgeCode(
          normalizedBadgeCode,
        );
        if (existingBadgeUser != null) {
          throw Exception('Ce code badge est déjà utilisé');
        }
      }

      // ✅ Step 1: Create user locally FIRST (always succeeds)
      final newUser = User(
        name: name,
        phone: phone,
        email: email,
        password: User.hashPassword(password),
        role: role,
        restaurantId: restaurantId,
        pinCode: pinCode,
        badgeCode: normalizedBadgeCode.isEmpty ? null : normalizedBadgeCode,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final localId = await DatabaseService.createUser(newUser);
      if (localId == 0) {
        throw Exception('Échec de la création locale de l\'utilisateur');
      }

      _users.add(newUser);
      appLogger.i('✅ User created locally with ID: $localId');

      // ✅ Step 2: Sync with backend (non-blocking, retry later if fails)
      try {
        final apiService = ApiImportService(
          baseUrl: AppConstant.baseUrl,
          authToken: Get.find<ApiClient>().token,
        );

        final apiUser = await apiService.createUser(
          name: name,
          phone: phone,
          email: email,
          password: password,
          role: role,
          restaurantId: restaurantId,
          pinCode: pinCode,
          badgeCode: normalizedBadgeCode.isEmpty ? null : normalizedBadgeCode,
          isActive: isActive,
        );

        if (apiUser != null && apiUser.id > 0) {
          // Update local user with backend ID and PIN
          newUser.id = apiUser.id;
          if (apiUser.pinCode != null) {
            newUser.pinCode = apiUser.pinCode;
            appLogger.i('🔄 PIN backend reçu: ${apiUser.pinCode}');
          }
          await DatabaseService.updateUser(newUser);

          // Update in observable list
          final index = _users.indexWhere((u) => u.id == localId);
          if (index != -1) {
            _users[index] = newUser;
          }

          appLogger.i('✅ User synced with backend: API ID ${apiUser.id}');
        }
      } catch (e) {
        appLogger.i('⚠️ Backend sync failed for user (will retry later): $e');
        appLogger.i('💡 User created locally - ID: $localId');
        // User is still valid locally, will sync later via SyncQueueService
      }

      return newUser;
    } catch (e) {
      appLogger.i('Error creating user: $e');
      rethrow;
    }
  }

  // Update user (for admin use)
  Future<bool> updateUser({
    required int userId,
    String? name,
    String? phone,
    String? email,
    String? role,
    int? restaurantId,
    String? pinCode,
    String? badgeCode,
    bool? isActive,
  }) async {
    try {
      appLogger.i('🔧 UpdateUser called for id=$userId');
      // Get the user from database
      final user = await DatabaseService.getUserById(userId);
      if (user == null) {
        appLogger.i('❌ User not found for id=$userId');
        throw Exception('Utilisateur introuvable');
      }

      // Update fields if provided
      if (name != null) user.name = name;
      if (phone != null) user.phone = phone;
      if (email != null) user.email = email;
      if (role != null) user.role = role;
      if (restaurantId != null) user.restaurantId = restaurantId;
      if (pinCode != null) {
        if (user.isStaff() && !isValidPin(pinCode)) {
          appLogger.i('❌ Invalid PIN for staff user id=$userId');
          throw Exception('Format de PIN invalide');
        }
        user.pinCode = pinCode;
      }
      if (badgeCode != null) {
        final normalizedBadgeCode = normalizeBadgeCode(badgeCode);
        if (normalizedBadgeCode.isNotEmpty) {
          final existingBadgeUser = await DatabaseService.getUserByBadgeCode(
            normalizedBadgeCode,
            excludeUserId: userId,
          );
          if (existingBadgeUser != null) {
            throw Exception('Ce code badge est déjà utilisé');
          }
        }
        user.badgeCode = normalizedBadgeCode.isEmpty
            ? null
            : normalizedBadgeCode;
      }
      if (isActive != null) user.isActive = isActive;

      user.updatedAt = DateTime.now();

      // Update user in database
      appLogger.i(
        '🧾 Updating user id=$userId name=${user.name} email=${user.email} role=${user.role} active=${user.isActive}',
      );
      final result = await DatabaseService.updateUser(user);
      appLogger.i('✅ DatabaseService.updateUser result=$result');

      if (result != 0) {
        // Update the user in the observable list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = user;
        } else {
          // If not in the list, add it
          _users.add(user);
        }
        update();
        await SyncQueueService.instance.enqueueUserUpsert(user);
        return true;
      }

      throw Exception(
        'Échec de la mise à jour de l’utilisateur (la base a renvoyé 0)',
      );
    } catch (e) {
      appLogger.i('Error updating user: $e');
      rethrow;
    }
  }

  // Toggle user activation status
  Future<bool> toggleUserActivation(int userId) async {
    try {
      final user = await DatabaseService.getUserById(userId);
      if (user == null) {
        throw Exception('Utilisateur introuvable');
      }

      // Toggle the active status
      user.isActive = !user.isActive;
      user.updatedAt = DateTime.now();

      final result = await DatabaseService.updateUser(user);

      if (result != 0) {
        // Update the user in the observable list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = user;
        }
        await SyncQueueService.instance.enqueueUserUpsert(user);
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error toggling user activation: $e');
      rethrow;
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final existing = await DatabaseService.getUserById(userId);
      final result = await DatabaseService.deleteUser(userId);

      if (result) {
        // Remove from the observable list
        _users.removeWhere((user) => user.id == userId);
        await SyncQueueService.instance.enqueueUserDelete(
          userId,
          email: existing?.email,
        );
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error deleting user: $e');
      rethrow;
    }
  }

  // Validate PIN code format
  bool isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  // Get users by role
  List<User> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Get active users only
  List<User> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Get inactive users only
  List<User> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }
}
