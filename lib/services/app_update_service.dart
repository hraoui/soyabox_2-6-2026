import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../data/app_constants.dart';
import '../models/app_update_info.dart';

class LocalAppVersion {
  const LocalAppVersion({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get fullLabel =>
      buildNumber.trim().isEmpty ? version : '$version+$buildNumber';
}

class AppUpdateService {
  AppUpdateService({ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;

  ApiClient get apiClient => _apiClient ?? Get.find<ApiClient>();

  Future<LocalAppVersion> getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return LocalAppVersion(
      version: info.version.trim(),
      buildNumber: info.buildNumber.trim(),
    );
  }

  Future<AppUpdateInfo> fetchLatestWindowsUpdate() async {
    final response = await apiClient.getData(
      AppConstant.windowsUpdateLatestPath,
    );

    if (response.statusCode != 200 || response.body is! Map) {
      throw Exception(
        'Impossible de verifier la mise a jour (code ${response.statusCode ?? "inconnu"}).',
      );
    }

    return AppUpdateInfo.fromJson(
      Map<String, dynamic>.from(response.body as Map),
      baseUrl: AppConstant.baseUrl,
    );
  }

  bool isRemoteNewer({
    required String localVersion,
    required String remoteVersion,
  }) {
    final localParts = _parseVersion(localVersion);
    final remoteParts = _parseVersion(remoteVersion);
    final maxLength = localParts.length > remoteParts.length
        ? localParts.length
        : remoteParts.length;

    for (var index = 0; index < maxLength; index++) {
      final localPart = index < localParts.length ? localParts[index] : 0;
      final remotePart = index < remoteParts.length ? remoteParts[index] : 0;
      if (remotePart > localPart) {
        return true;
      }
      if (remotePart < localPart) {
        return false;
      }
    }

    return false;
  }

  Future<bool> openDownloadUrl(String downloadUrl) async {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null) {
      throw const FormatException('Lien de telechargement invalide.');
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<int> _parseVersion(String value) {
    final normalized = value.trim().toLowerCase();
    final noPrefix = normalized.startsWith('v')
        ? normalized.substring(1)
        : normalized;
    final segments = noPrefix.split('+');
    final core = segments.first;
    final parts = core
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
    final build = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
    return [...parts, build];
  }
}
