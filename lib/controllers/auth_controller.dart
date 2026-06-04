import 'package:get/get.dart';
import '../api/api_client.dart';
import '../controllers/restaurant_controller.dart';
import '../data/app_constants.dart';
import '../models/user.dart';
import '../services/api_order_pull_service.dart';
import '../services/auth_session_service.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/app_logger.dart';
import 'delivery_controller.dart';
import 'import_controller.dart';
import 'sync_controller.dart';
import 'user_controller.dart';
import 'dart:async';

class _PinLoginResult {
  const _PinLoginResult({required this.user, required this.token});
  final User user;
  final String token;
}

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final Rx<User?> _currentUser = Rx<User?>(null);
  User? get currentUser => _currentUser.value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  late final ApiClient _apiClient;

  @override
  void onReady() {
    super.onReady();
    _apiClient = Get.find<ApiClient>();
    _initSessionToken();
  }

  Future<void> _initSessionToken() async {
    try {
      appLogger.d('🔑 [AUTH] Initializing session token...');
      final savedToken = AuthSessionService.instance.token;
      final token = savedToken.isNotEmpty ? savedToken : AppConstant.apiToken;
      appLogger.d('🔑 [AUTH] Token available: ${token.isNotEmpty ? "YES" : "NO"}');
      _apiClient.updateHeaders(token);
      SyncQueueService.instance.updateAuthToken(token);
      ApiOrderPullService.instance.updateAuthToken(token);
      if (Get.isRegistered<ImportController>()) {
        Get.find<ImportController>().updateApiToken(token);
      }
      appLogger.d('✅ [AUTH] Session token initialized');
    } catch (e, stackTrace) {
      appLogger.e('❌ [AUTH] Session token initialization failed: $e');
      appLogger.e('Session token init failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<bool> registerUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    int? restaurantId,
    String? pinCode,
  }) async {
    try {
      final existingUser = await DatabaseService.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }
      if (role == 'staff' && (pinCode == null || !isValidPin(pinCode))) {
        throw Exception('Un code PIN valide est requis pour les comptes du personnel');
      }
      final newUser = User(
        name: name,
        phone: phone,
        email: email,
        password: User.hashPassword(password),
        role: role,
        restaurantId: restaurantId,
        pinCode: pinCode,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final userId = await DatabaseService.createUser(newUser);
      if (userId != 0) {
        _currentUser.value = newUser;
        if (Get.isRegistered<UserController>()) {
          await Get.find<UserController>().fetchAllUsers(restaurantId: newUser.restaurantId);
        }
        await SyncQueueService.instance.enqueueUserUpsert(newUser);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      appLogger.e('Registration error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> loginUser(String identifier, String password) async {
    _isLoading.value = true;
    try {
      final normalizedIdentifier = identifier.trim();
      final onlineUser = await _tryOnlineLogin(identifier: normalizedIdentifier, password: password);
      if (onlineUser != null) {
        if (!_isUserAllowedForCurrentRestaurant(onlineUser)) {
          throw Exception('Accès refusé : Cet utilisateur appartient à un autre restaurant.');
        }
        _currentUser.value = onlineUser;
        if (Get.isRegistered<UserController>()) {
          await Get.find<UserController>().fetchAllUsers(restaurantId: onlineUser.restaurantId);
        }
        if (Get.isRegistered<SyncController>()) Get.find<SyncController>().startSyncAfterLogin();
        if (Get.isRegistered<UserController>()) Get.find<UserController>().initAfterLogin();
        if (Get.isRegistered<DeliveryController>()) Get.find<DeliveryController>().initAfterLogin();
        if (onlineUser.role == 'cashier') Get.offAllNamed('/cashier-dashboard');
        return true;
      }
      final localUser = await _loginLocal(identifier: normalizedIdentifier, password: password);
      if (!_isUserAllowedForCurrentRestaurant(localUser)) {
        throw Exception('Accès refusé : Cet utilisateur appartient à un autre restaurant.');
      }
      _currentUser.value = localUser;
      if (Get.isRegistered<UserController>()) {
        await Get.find<UserController>().fetchAllUsers(restaurantId: localUser.restaurantId);
      }
      if (Get.isRegistered<SyncController>()) Get.find<SyncController>().startSyncAfterLogin();
      if (Get.isRegistered<UserController>()) Get.find<UserController>().initAfterLogin();
      if (Get.isRegistered<DeliveryController>()) Get.find<DeliveryController>().initAfterLogin();
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Login error', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  bool _isUserAllowedForCurrentRestaurant(User user) {
    if (user.role.trim().toLowerCase() == 'superadmin') {
      appLogger.d('✅ [AUTH] Superadmin autorisé: ${user.email}');
      return true;
    }
    int? importedRestaurantId;
    if (Get.isRegistered<RestaurantController>()) {
      importedRestaurantId = Get.find<RestaurantController>().getImportedRestaurantId();
    }
    if (importedRestaurantId == null) {
      appLogger.w('⚠️ [AUTH] Aucun restaurant importé, connexion autorisée');
      return true;
    }
    final userRestaurantId = user.restaurantId;
    if (userRestaurantId == null || userRestaurantId <= 0) {
      appLogger.w('⚠️ [AUTH] Utilisateur sans restaurant ID: ${user.email}');
      return false;
    }
    if (userRestaurantId != importedRestaurantId) {
      appLogger.e('❌ [AUTH] Accès refusé: utilisateur restaurant=$userRestaurantId, importé=$importedRestaurantId');
      return false;
    }
    appLogger.d('✅ [AUTH] Accès autorisé: utilisateur restaurant=$userRestaurantId');
    return true;
  }

  Future<User?> _tryOnlineLogin({required String identifier, required String password}) async {
    try {
      appLogger.i('🌐 Attempting online login for: $identifier');
      String? phoneForApi = _normalizePhone(identifier);
      if (phoneForApi == null) {
        final localByEmail = await DatabaseService.getUserByEmail(identifier.toLowerCase());
        phoneForApi = _normalizePhone(localByEmail?.phone ?? '');
      }
      if (phoneForApi == null) {
        appLogger.w('No phone number found for login', context: {'identifier': identifier});
        return null;
      }
      appLogger.i('📞 Calling API with phone: $phoneForApi');
      final response = await _apiClient.postData('/api/login', {'phone': phoneForApi, 'password': password});
      appLogger.i('📥 API Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        appLogger.e('API login failed', context: {'statusCode': response.statusCode, 'identifier': identifier});
        return null;
      }
      final body = response.body;
      if (body is! Map) return null;
      final token = _extractToken(body);
      if (token.isEmpty) return null;
      final remoteUserData = _extractUserMap(body, identifier: identifier);
      final resolvedEmail = _resolveEmailForLocalUser(
        identifier: identifier, remoteUserData: remoteUserData, phoneForApi: phoneForApi,
      );
      final localUser = await _upsertUserFromRemote(
        email: resolvedEmail, enteredPassword: password, data: remoteUserData,
      );
      _apiClient.updateHeaders(token);
      SyncQueueService.instance.updateAuthToken(token);
      ApiOrderPullService.instance.updateAuthToken(token);
      if (Get.isRegistered<ImportController>()) Get.find<ImportController>().updateApiToken(token);
      if (Get.isRegistered<DeliveryController>()) Get.find<DeliveryController>().updateApiToken(token);
      await AuthSessionService.instance.saveSession(
        token: token, email: resolvedEmail, authMethod: 'password',
        credentialIdentifier: identifier.trim().toLowerCase(), credentialSecret: password,
      );
      return localUser;
    } catch (_) {
      return null;
    }
  }

  static String extractAuthTokenFromApiBody(dynamic body) {
    if (body is! Map) return '';
    String tokenFromMap(Map<dynamic, dynamic> source) {
      final direct = source['token'] ?? source['access_token'];
      if (direct is String && direct.trim().isNotEmpty) return direct.trim();
      return '';
    }
    final rootToken = tokenFromMap(body);
    if (rootToken.isNotEmpty) return rootToken;
    final data = body['data'];
    if (data is Map) return tokenFromMap(data);
    return '';
  }

  static Map<String, dynamic> extractAuthUserFromApiBody(dynamic body) {
    if (body is! Map) return const {};
    final user = body['user'];
    if (user is Map) return Map<String, dynamic>.from(user);
    final data = body['data'];
    if (data is Map) {
      final nestedUser = data['user'];
      if (nestedUser is Map) return Map<String, dynamic>.from(nestedUser);
      if (data.containsKey('id') || data.containsKey('email') ||
          data.containsKey('phone') || data.containsKey('role')) {
        return Map<String, dynamic>.from(data);
      }
    }
    return const {};
  }

  String _extractToken(Map body) => extractAuthTokenFromApiBody(body);

  Map<String, dynamic> _extractUserMap(Map body, {required String identifier}) {
    final extracted = extractAuthUserFromApiBody(body);
    if (extracted.isNotEmpty) return extracted;
    return {'email': identifier};
  }

  String _resolveEmailForLocalUser({
    required String identifier,
    required Map<String, dynamic> remoteUserData,
    String? phoneForApi,
  }) {
    final remoteEmail = (remoteUserData['email'] ?? '').toString().trim();
    if (remoteEmail.isNotEmpty) return remoteEmail.toLowerCase();
    if (GetUtils.isEmail(identifier)) return identifier.toLowerCase();
    final phonePart = phoneForApi ?? 'unknown';
    return 'phone_$phonePart@local.pos';
  }

  String? _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 8) return null;
    return digits;
  }

  Future<User> _upsertUserFromRemote({
    required String email,
    required String enteredPassword,
    required Map<String, dynamic> data,
  }) async {
    final existing = await DatabaseService.getUserByEmail(email);
    final role = (data['role'] ?? existing?.role ?? 'staff').toString();
    final localPasswordHash = User.hashPassword(enteredPassword);
    final now = DateTime.now();
    final isActive = data['is_active'] == null
        ? (existing?.isActive ?? true)
        : (data['is_active'] == true || data['is_active'] == 1);
    if (existing == null) {
      final user = User(
        name: (data['name'] ?? email).toString(),
        phone: (data['phone'] ?? '').toString(),
        email: email,
        password: localPasswordHash,
        role: role,
        restaurantId: _asInt(data['restaurant_id']),
        pinCode: (data['pin_code'] ?? '').toString().trim().isEmpty ? null : data['pin_code'].toString(),
        badgeCode: (data['badge_code'] ?? '').toString().trim().isEmpty
            ? existing?.badgeCode
            : (data['badge_code'] ?? '').toString().trim(),
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );
      final remoteId = _asInt(data['id']);
      if (remoteId != null && remoteId > 0) user.id = remoteId;
      await DatabaseService.createUser(user);
      return user;
    }
    existing.name = (data['name'] ?? existing.name).toString();
    existing.phone = (data['phone'] ?? existing.phone).toString();
    existing.password = localPasswordHash;
    existing.role = role;
    existing.restaurantId = _asInt(data['restaurant_id']) ?? existing.restaurantId;
    existing.pinCode = (data['pin_code'] ?? existing.pinCode)?.toString();
    existing.badgeCode = (data['badge_code'] ?? existing.badgeCode)?.toString();
    existing.isActive = isActive;
    existing.updatedAt = now;
    await DatabaseService.updateUser(existing);
    return existing;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _resolvePinUserEmail(Map<String, dynamic> data, String pin) {
    final email = (data['email'] ?? '').toString().trim().toLowerCase();
    if (email.isNotEmpty) return email;
    final remoteId = _asInt(data['id']);
    if (remoteId != null && remoteId > 0) return 'pin_$remoteId@local.pos';
    return 'pin_$pin@local.pos';
  }

  Future<User> _upsertUserFromRemotePin({
    required String pin,
    required Map<String, dynamic> data,
  }) async {
    final email = _resolvePinUserEmail(data, pin);
    final existing = await DatabaseService.getUserByEmail(email);
    final role = (data['role'] ?? existing?.role ?? 'staff').toString();
    final now = DateTime.now();
    final isActive = data['is_active'] == null
        ? (existing?.isActive ?? true)
        : (data['is_active'] == true || data['is_active'] == 1);
    final resolvedPinCode = (data['pin_code'] ?? '').toString().trim().isEmpty
        ? pin
        : data['pin_code'].toString().trim();
    if (existing == null) {
      final user = User(
        name: (data['name'] ?? email).toString(),
        phone: (data['phone'] ?? '').toString(),
        email: email,
        password: User.hashPassword('123456'),
        role: role,
        restaurantId: _asInt(data['restaurant_id']),
        pinCode: resolvedPinCode,
        badgeCode: (data['badge_code'] ?? '').toString().trim().isEmpty
            ? null
            : (data['badge_code'] ?? '').toString().trim(),
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );
      final remoteId = _asInt(data['id']);
      if (remoteId != null && remoteId > 0) user.id = remoteId;
      await DatabaseService.createUser(user);
      return user;
    }
    existing.name = (data['name'] ?? existing.name).toString();
    existing.phone = (data['phone'] ?? existing.phone).toString();
    existing.role = role;
    existing.restaurantId = _asInt(data['restaurant_id']) ?? existing.restaurantId;
    existing.pinCode = resolvedPinCode;
    existing.badgeCode = (data['badge_code'] ?? existing.badgeCode)?.toString();
    existing.isActive = isActive;
    existing.updatedAt = now;
    await DatabaseService.updateUser(existing);
    return existing;
  }

  Future<_PinLoginResult?> _tryOnlinePinLogin(String pin) async {
    try {
      final response = await Get.find<ApiClient>().postData('/api/login-pin', {'pin_code': pin});
      if (response.statusCode != 200 && response.statusCode != 201) return null;
      final body = response.body;
      if (body is! Map) return null;
      final remoteUserData = _extractUserMap(body, identifier: pin);
      if (remoteUserData.isEmpty) return null;
      final user = await _upsertUserFromRemotePin(pin: pin, data: remoteUserData);
      return _PinLoginResult(user: user, token: _extractToken(body));
    } catch (_) {
      return null;
    }
  }

  bool _isSameUser(User first, User second) {
    if (first.id > 0 && second.id > 0 && first.id == second.id) return true;
    final firstEmail = first.email.trim().toLowerCase();
    final secondEmail = second.email.trim().toLowerCase();
    return firstEmail.isNotEmpty && firstEmail == secondEmail;
  }

  void _applyAuthenticatedServices(String token) {
    Get.find<ApiClient>().updateHeaders(token);
    SyncQueueService.instance.updateAuthToken(token);
    ApiOrderPullService.instance.updateAuthToken(token);
    if (Get.isRegistered<ImportController>()) Get.find<ImportController>().updateApiToken(token);
    if (Get.isRegistered<DeliveryController>()) Get.find<DeliveryController>().updateApiToken(token);
  }

  Future<void> _completePinLogin({required User user, required String pin, String? token}) async {
    _currentUser.value = user;
    final sessionToken = token != null && token.trim().isNotEmpty
        ? token.trim()
        : 'local_pin_${DateTime.now().millisecondsSinceEpoch}';
    _applyAuthenticatedServices(sessionToken);
    await AuthSessionService.instance.saveSession(
      token: sessionToken,
      email: user.email.trim().toLowerCase(),
      authMethod: 'pin',
      credentialIdentifier: user.email.trim().toLowerCase(),
      credentialSecret: pin,
    );
    if (Get.isRegistered<RestaurantController>() && user.restaurantId != null) {
      Get.find<RestaurantController>().setRestaurantId(user.restaurantId);
    }
    if (Get.isRegistered<UserController>()) {
      await Get.find<UserController>().fetchAllUsers(restaurantId: user.restaurantId);
    }
    if (Get.isRegistered<SyncController>()) Get.find<SyncController>().startSyncAfterLogin();
    if (Get.isRegistered<UserController>()) await Get.find<UserController>().initAfterLogin();
    if (Get.isRegistered<DeliveryController>()) await Get.find<DeliveryController>().initAfterLogin();
  }

  Future<User> _loginWithPin({
    required String pin,
    required Set<String> allowedRoles,
    required String roleErrorMessage,
  }) async {
    final normalizedPin = pin.trim();
    if (normalizedPin.isEmpty) throw Exception('Code PIN requis');
    User? user = await DatabaseService.getUserByPin(normalizedPin, allowedRoles: allowedRoles);
    final onlineResult = await _tryOnlinePinLogin(normalizedPin);
    if (onlineResult != null) {
      final onlineRole = onlineResult.user.role.trim().toLowerCase();
      if (allowedRoles.contains(onlineRole) || user == null) user = onlineResult.user;
    }
    if (user == null) throw Exception('Code PIN incorrect');
    final normalizedRole = user.role.trim().toLowerCase();
    if (!allowedRoles.contains(normalizedRole)) throw Exception(roleErrorMessage);
    if (!user.isActive) throw Exception('Compte désactivé');
    if (!_isUserAllowedForCurrentRestaurant(user)) {
      throw Exception('Accès refusé : Cet utilisateur appartient à un autre restaurant.');
    }
    final token = onlineResult != null && _isSameUser(user, onlineResult.user) ? onlineResult.token : null;
    await _completePinLogin(user: user, pin: normalizedPin, token: token);
    return user;
  }

  Future<User> _loginLocal({required String identifier, required String password}) async {
    final normalized = identifier.trim();
    User? user;
    if (GetUtils.isEmail(normalized)) {
      user = await DatabaseService.getUserByEmail(normalized.toLowerCase());
    } else {
      user = await _findLocalByPhoneVariants(normalized);
      user ??= await DatabaseService.getUserByEmail(normalized.toLowerCase());
    }
    if (user == null) throw Exception('Utilisateur introuvable (hors ligne)');
    if (!user.isActive) throw Exception('Le compte est désactivé');
    if (!user.verifyPassword(password)) throw Exception('Mot de passe incorrect');
    return user;
  }

  Future<User?> _findLocalByPhoneVariants(String input) async {
    final variants = <String>{input.trim(), input.replaceAll(RegExp(r'[^0-9]'), '')};
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) variants.add('+$digits');
    for (final candidate in variants) {
      if (candidate.isEmpty) continue;
      final found = await DatabaseService.getUserByPhone(candidate);
      if (found != null) return found;
    }
    return null;
  }

  Future<void> logout() async {
    if (Get.isRegistered<SyncController>()) Get.find<SyncController>().stopSync();
    _apiClient.updateHeaders('');
    SyncQueueService.instance.updateAuthToken('');
    ApiOrderPullService.instance.updateAuthToken('');
    await AuthSessionService.instance.clearSession();
    _currentUser.value = null;
    if (Get.isRegistered<UserController>()) {
      await Get.find<UserController>().fetchAllUsers(restaurantId: null);
    }
  }

  bool get isLoggedIn => _currentUser.value != null;
  String? get currentRole => _currentUser.value?.role;

  bool get canViewOrders => currentRole == 'admin' || currentRole == 'superadmin' || currentRole == 'cashier';
  bool get canViewFinancialStatus => currentRole == 'admin' || currentRole == 'superadmin' || currentRole == 'cashier';
  bool get canCloseCashRegister => currentRole == 'admin' || currentRole == 'superadmin' || currentRole == 'cashier';
  bool get canOpenCashRegister => currentRole == 'admin' || currentRole == 'superadmin' || currentRole == 'cashier';
  bool get canPrintDailyReport => currentRole == 'admin' || currentRole == 'superadmin' || currentRole == 'cashier';
  bool get canDeleteOrders => currentRole == 'admin' || currentRole == 'superadmin';
  bool get canDeleteReports => currentRole == 'admin' || currentRole == 'superadmin';

  bool isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!isLoggedIn || _currentUser.value == null) throw Exception('Aucun utilisateur connecté');
    final user = _currentUser.value!;
    if (!user.verifyPassword(oldPassword)) throw Exception('L\'ancien mot de passe est incorrect');
    user.password = User.hashPassword(newPassword);
    user.updatedAt = DateTime.now();
    final result = await DatabaseService.updateUser(user);
    if (result != 0) {
      _currentUser.value = user;
      await SyncQueueService.instance.enqueueUserUpsert(user);
      return true;
    }
    return false;
  }

  Future<bool> updateUserProfile({String? name, String? phone, String? email, String? pinCode}) async {
    if (!isLoggedIn || _currentUser.value == null) throw Exception('Aucun utilisateur connecté');
    final user = _currentUser.value!;
    if (name != null) user.name = name;
    if (phone != null) user.phone = phone;
    if (email != null) user.email = email;
    if (pinCode != null) {
      if (user.isStaff() && !isValidPin(pinCode)) throw Exception('Format de PIN invalide');
      user.pinCode = pinCode;
    }
    user.updatedAt = DateTime.now();
    final result = await DatabaseService.updateUser(user);
    if (result != 0) {
      _currentUser.value = user;
      await SyncQueueService.instance.enqueueUserUpsert(user);
      return true;
    }
    return false;
  }

  Future<bool> loginAdminWithPin(String email, String pin) async {
    _isLoading.value = true;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final user = await DatabaseService.getUserByEmail(normalizedEmail);
      if (user == null) throw Exception('Utilisateur introuvable');
      if (!user.isAdmin() && !user.isSuperadmin()) throw Exception('Accès réservé aux administrateurs');
      if (!user.isActive) throw Exception('Compte désactivé');
      if (user.pinCode == null || user.pinCode != pin) throw Exception('Code PIN incorrect');
      if (!_isUserAllowedForCurrentRestaurant(user)) {
        throw Exception('Accès refusé : Cet utilisateur appartient à un autre restaurant.');
      }
      await _completePinLogin(user: user, pin: pin);
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Admin PIN login error', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> loginSuperAdminWithPin(String pin) async {
    _isLoading.value = true;
    try {
      await _loginWithPin(
        pin: pin,
        allowedRoles: const {'admin', 'superadmin'},
        roleErrorMessage: 'Accès réservé aux administrateurs',
      );
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Admin/Superadmin PIN login error', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // ✅ NOUVEAU — authentification par badge pour admin/superadmin
  Future<bool> loginSuperAdminWithBadge(String badgeCode) async {
    _isLoading.value = true;
    try {
      final normalizedBadge = badgeCode.trim();
      if (normalizedBadge.isEmpty) throw Exception('Code badge vide');

      // 1. Chercher par badge en local
      User? user = await DatabaseService.getUserByBadgeCode(normalizedBadge);

      // 2. Si pas trouvé localement, essayer en ligne
      if (user == null) {
        final onlineResult = await _tryOnlinePinLogin(normalizedBadge);
        if (onlineResult != null) user = onlineResult.user;
      }

      if (user == null) throw Exception('Badge non reconnu');

      final role = user.role.trim().toLowerCase();
      if (role != 'admin' && role != 'superadmin') {
        throw Exception('Accès réservé aux administrateurs');
      }
      if (!user.isActive) throw Exception('Compte désactivé');
      if (!_isUserAllowedForCurrentRestaurant(user)) {
        throw Exception('Accès refusé : Cet utilisateur appartient à un autre restaurant.');
      }

      await _completePinLogin(user: user, pin: normalizedBadge);
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Badge admin login error', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> loginCashierWithPin(String pin) async {
    _isLoading.value = true;
    try {
      await _loginWithPin(
        pin: pin,
        allowedRoles: const {'cashier'},
        roleErrorMessage: 'Accès réservé aux caissiers',
      );
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Cashier PIN login error', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }
}