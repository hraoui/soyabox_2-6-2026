class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.force,
    required this.message,
    this.platform,
    this.channel,
    this.publishedAt,
    this.installerName,
    this.sha256,
  });

  final String version;
  final String downloadUrl;
  final bool force;
  final String message;
  final String? platform;
  final String? channel;
  final String? publishedAt;
  final String? installerName;
  final String? sha256;

  String get displayVersion => version.startsWith('v') ? version : 'v$version';

  factory AppUpdateInfo.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final rawDownloadUrl = _firstNonEmpty([
      json['download_url'],
      json['url'],
      json['downloadUrl'],
    ]);

    if (rawDownloadUrl == null) {
      throw const FormatException(
        'Le backend doit renvoyer download_url ou url pour la mise a jour.',
      );
    }

    return AppUpdateInfo(
      version: _firstNonEmpty([json['version']]) ?? '',
      downloadUrl: _resolveUrl(rawDownloadUrl, baseUrl),
      force: json['force'] == true || json['mandatory'] == true,
      message:
          _firstNonEmpty([json['message'], json['notes']]) ??
          'Nouvelle version disponible',
      platform: _firstNonEmpty([json['platform']]),
      channel: _firstNonEmpty([json['channel']]),
      publishedAt: _firstNonEmpty([json['published_at'], json['publishedAt']]),
      installerName: _firstNonEmpty([
        json['installer_name'],
        json['filename'],
        json['asset_name'],
      ]),
      sha256: _firstNonEmpty([json['sha256']]),
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    return null;
  }

  static String _resolveUrl(String rawValue, String baseUrl) {
    final normalizedBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedValue = rawValue.trim();

    final uri = Uri.tryParse(normalizedValue);
    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }

    final path = normalizedValue.startsWith('/')
        ? normalizedValue
        : '/$normalizedValue';
    return '$normalizedBase$path';
  }
}
