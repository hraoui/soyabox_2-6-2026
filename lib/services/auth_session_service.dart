import 'dart:convert';
import 'dart:io';

import '../utils/path_utils.dart';

class AuthSessionService {
  // ✅ 18h covers full service shift: 09h00 → 02h00 next day + 1h margin
  static const Duration _defaultTokenLifetime = Duration(hours: 18);

  AuthSessionService._();
  static final AuthSessionService instance = AuthSessionService._();

  File? _sessionFile;
  bool _initialized = false;

  String _token = '';
  String get token => _token;

  // Permet de définir un token par défaut (ex: depuis AppConstant)
  String? _fallbackToken;
  void setFallbackToken(String token) {
    _fallbackToken = token.trim().isEmpty ? null : token.trim();
  }

  String get tokenOrFallback =>
      _token.isNotEmpty ? _token : (_fallbackToken ?? '');

  String _email = '';
  String get email => _email;

  String _authMethod = '';
  String get authMethod => _authMethod;

  String _credentialIdentifier = '';
  String get credentialIdentifier => _credentialIdentifier;

  String _credentialSecret = '';
  String get credentialSecret => _credentialSecret;

  String _savedPasswordIdentifier = '';
  String get savedPasswordIdentifier => _savedPasswordIdentifier;

  String _savedPasswordSecret = '';
  String get savedPasswordSecret => _savedPasswordSecret;

  DateTime? _tokenIssuedAt;
  DateTime? get tokenIssuedAt => _tokenIssuedAt;

  bool get hasSavedCredentials =>
      _credentialIdentifier.trim().isNotEmpty &&
      _credentialSecret.trim().isNotEmpty;
  bool get hasSavedPasswordCredentials =>
      _savedPasswordIdentifier.trim().isNotEmpty &&
      _savedPasswordSecret.trim().isNotEmpty;
  bool get isPinSession => _authMethod == 'pin' && _credentialSecret.isNotEmpty;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getAppDocumentsDirectory();
    _sessionFile = File('${dir.path}/auth_session.json');
    await _load();
    _initialized = true;
  }

  Future<void> refresh() async {
    await init();
    await _load();
  }

  Future<void> saveSession({
    required String token,
    required String email,
    String? authMethod,
    String? credentialIdentifier,
    String? credentialSecret,
  }) async {
    await init();
    final normalizedAuthMethod = authMethod?.trim().toLowerCase();
    final normalizedCredentialIdentifier = credentialIdentifier
        ?.trim()
        .toLowerCase();
    final normalizedCredentialSecret = credentialSecret?.trim();

    _token = token.trim();
    _email = email.trim().toLowerCase();
    _authMethod = normalizedAuthMethod ?? _authMethod;
    _credentialIdentifier =
        normalizedCredentialIdentifier ?? _credentialIdentifier;
    _credentialSecret = normalizedCredentialSecret ?? _credentialSecret;
    if (_authMethod == 'password') {
      _savedPasswordIdentifier =
          normalizedCredentialIdentifier ?? _savedPasswordIdentifier;
      _savedPasswordSecret = normalizedCredentialSecret ?? _savedPasswordSecret;
    }
    _tokenIssuedAt = _token.isEmpty ? null : DateTime.now();
    await _persist();
  }

  Future<void> clearSession() async {
    await init();
    _token = '';
    _email = '';
    _authMethod = '';
    _credentialIdentifier = '';
    _credentialSecret = '';
    _savedPasswordIdentifier = '';
    _savedPasswordSecret = '';
    _tokenIssuedAt = null;
    await _persist();
  }

  bool isTokenExpired({Duration maxAge = _defaultTokenLifetime}) {
    if (_token.trim().isEmpty) return true;
    final issuedAt = _tokenIssuedAt;
    if (issuedAt == null) return true;
    return DateTime.now().difference(issuedAt) >= maxAge;
  }

  Future<String> refreshTokenIfNeeded({
    Future<String?> Function(String pin)? refreshWithPin,
    Future<String?> Function(String identifier, String secret)?
    refreshWithCredentials,
    Duration maxAge = _defaultTokenLifetime,
  }) async {
    await refresh();
    if (!isTokenExpired(maxAge: maxAge)) {
      return _token;
    }

    String refreshedToken = '';
    if (_authMethod == 'pin' &&
        _credentialSecret.trim().isNotEmpty &&
        refreshWithPin != null) {
      refreshedToken = (await refreshWithPin(_credentialSecret.trim()) ?? '')
          .trim();
    }
    if (refreshedToken.isEmpty && refreshWithCredentials != null) {
      final credentialIdentifier = _authMethod == 'password'
          ? _credentialIdentifier.trim()
          : _savedPasswordIdentifier.trim();
      final credentialSecret = _authMethod == 'password'
          ? _credentialSecret.trim()
          : _savedPasswordSecret.trim();
      if (credentialIdentifier.isNotEmpty && credentialSecret.isNotEmpty) {
        refreshedToken =
            (await refreshWithCredentials(
                      credentialIdentifier,
                      credentialSecret,
                    ) ??
                    '')
                .trim();
      }
    }

    if (refreshedToken.isNotEmpty) {
      await saveSession(
        token: refreshedToken,
        email: _email,
        authMethod: _authMethod,
        credentialIdentifier: _credentialIdentifier,
        credentialSecret: _credentialSecret,
      );
      return _token;
    }

    _token = '';
    _tokenIssuedAt = null;
    await _persist();
    return '';
  }

  Future<void> _load() async {
    final file = _sessionFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        _token = (decoded['token'] ?? '').toString();
        _email = (decoded['email'] ?? '').toString();
        _authMethod = (decoded['auth_method'] ?? '').toString().trim();
        _credentialIdentifier = (decoded['credential_identifier'] ?? '')
            .toString();
        _credentialSecret = (decoded['credential_secret'] ?? '').toString();
        _savedPasswordIdentifier = (decoded['saved_password_identifier'] ?? '')
            .toString();
        _savedPasswordSecret = (decoded['saved_password_secret'] ?? '')
            .toString();
        final issuedAtRaw = (decoded['token_issued_at'] ?? '')
            .toString()
            .trim();
        _tokenIssuedAt = issuedAtRaw.isEmpty
            ? null
            : DateTime.tryParse(issuedAtRaw);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final file = _sessionFile;
    if (file == null) return;
    await file.writeAsString(
      json.encode({
        'token': _token,
        'email': _email,
        'auth_method': _authMethod,
        'credential_identifier': _credentialIdentifier,
        'credential_secret': _credentialSecret,
        'saved_password_identifier': _savedPasswordIdentifier,
        'saved_password_secret': _savedPasswordSecret,
        'token_issued_at': _tokenIssuedAt?.toIso8601String(),
      }),
    );
  }
}
