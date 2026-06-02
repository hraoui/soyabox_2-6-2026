// ignore_for_file: avoid_print

import 'package:get/get.dart';

class ApiClient extends GetConnect implements GetxService {
  late String token;
  final String appBaseUrl;
  late Map<String, String> _mainHeaders;
  ApiClient({required this.appBaseUrl, this.token = ''}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
    _mainHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void updateHeaders(String token) {
    print(
      '🔐 updateHeaders called with token: ${token.isNotEmpty ? "${token.substring(0, 10)}..." : "EMPTY"}',
    );
    this.token = token;
    _mainHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    print(
      '🔐 _mainHeaders has auth: ${_mainHeaders.containsKey('Authorization')}',
    );
  }

  Future<Response> getData(String uri, {Map<String, String>? headers}) async {
    try {
      // Ensure no double slashes in URL
      final cleanUri = uri.replaceAll(RegExp(r'^/+'), '');
      final response = await get(
        '/$cleanUri',
        headers: headers ?? _mainHeaders,
      );
      _logResponse('GET', uri, response);
      return _validateResponse(response);
    } catch (e) {
      return Response(statusCode: 1, statusText: 'Erreur API: $e');
    }
  }

  Future<Response> postData(String uri, dynamic body) async {
    // Ensure no double slashes in URL
    final cleanBase = baseUrl?.replaceAll(RegExp(r'/+$'), '') ?? baseUrl;
    final cleanUri = uri.replaceAll(RegExp(r'^/+'), '');
    final fullUrl = '$cleanBase/$cleanUri';

    print('🚀 Envoi vers: $fullUrl');
    print('📦 Body: $body');

    try {
      final response = await post(uri, body, headers: _mainHeaders);
      print('✅ Réponse: ${response.statusCode}');
      print('📄 Body: ${response.body}');
      return _validateResponse(response);
    } catch (e) {
      print('❌ Erreur réseau: $e');
      return Response(statusCode: 500, statusText: 'Erreur: $e');
    }
  }

  Response _validateResponse(Response response) {
    if (response.statusCode == 200 && response.body is Map) {
      return response;
    } else {
      // Retour HTML = non authentifié
      if (response.body is String &&
          response.body.toString().contains('<!doctype html>')) {
        return const Response(
          statusCode: 401,
          statusText: 'Non authentifié (HTML reçu)',
        );
      }
      return Response(
        statusCode: response.statusCode ?? 500,
        body: response.body,
      );
    }
  }

  void _logResponse(String method, String uri, Response response) {
    print('📡 [$method] $uri');
    print('   ↳ Status: ${response.statusCode}');
    print('   ↳ Body: ${response.body}');
  }

  /// Nouvelle fonction DELETE générique
  Future<Response> deleteData(
    String uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await delete(uri, headers: headers ?? _mainHeaders);
    } catch (e) {
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> removeAddress(
    String uri, {
    Map<String, String>? headers,
  }) async {
    try {
      Response response = await delete(uri, headers: headers ?? _mainHeaders);
      return response;
    } catch (e) {
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  @override
  String toString() =>
      'ApiClient(token: $token, appBaseUrl: $appBaseUrl, _mainHeaders: $_mainHeaders)';
}
