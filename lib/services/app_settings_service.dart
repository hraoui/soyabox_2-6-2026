import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../utils/path_utils.dart';

import '../models/app_settings.dart';

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  bool _initialized = false;
  File? _file;
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  String get displayCurrencySymbol {
    final rawSymbol = _settings.currencySymbol.trim();
    final normalized = rawSymbol.toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'da' ||
        normalized == 'dh' ||
        normalized == 'dhs') {
      return 'Dhs';
    }
    return rawSymbol;
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getAppDocumentsDirectory();
    _file = File('${dir.path}/app_settings.json');
    await _load();
    _initialized = true;
  }

  Future<void> save(AppSettings settings) async {
    await init();
    _settings = settings;
    final file = _file;
    if (file == null) return;
    await file.writeAsString(json.encode(settings.toJson()));
  }

  Future<String?> persistSettingsLogo({
    required String targetBasename,
    String? sourcePath,
    Uint8List? bytes,
    String? originalFileName,
  }) async {
    try {
      final imagesDir = await _settingsImagesDir();
      final extension = _resolveImageExtension(
        sourcePath: sourcePath,
        originalFileName: originalFileName,
      );
      final destination = File('${imagesDir.path}/$targetBasename.$extension');

      if (bytes != null && bytes.isNotEmpty) {
        await destination.writeAsBytes(bytes, flush: true);
        return destination.path;
      }

      final trimmedPath = sourcePath?.trim();
      if (trimmedPath == null || trimmedPath.isEmpty) return null;

      final sourceFile = File(trimmedPath);
      if (!await sourceFile.exists()) return null;
      if (sourceFile.absolute.path == destination.absolute.path) {
        return destination.path;
      }

      await sourceFile.copy(destination.path);
      return destination.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteManagedLogo(String? path) async {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) return;

    final imagesDir = await _settingsImagesDir();
    final logoFile = File(trimmedPath);
    if (logoFile.parent.absolute.path != imagesDir.absolute.path) {
      return;
    }

    if (!await logoFile.exists()) return;
    try {
      await logoFile.delete();
    } catch (_) {}
  }

  String formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} $displayCurrencySymbol';
  }

  Future<void> _load() async {
    final file = _file;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        _settings = AppSettings.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<Directory> _settingsImagesDir() async {
    await init();
    final settingsFile = _file;
    final basePath = settingsFile?.parent.path;
    if (basePath == null || basePath.isEmpty) {
      final docs = await getAppDocumentsDirectory();
      final fallbackDir = Directory('${docs.path}/settings_images');
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }

    final imagesDir = Directory('$basePath/settings_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  String _resolveImageExtension({
    String? sourcePath,
    String? originalFileName,
  }) {
    final ext =
        _extractExtension(originalFileName) ?? _extractExtension(sourcePath);
    final normalized = ext?.toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'png';
    if (normalized == 'jpeg') return 'jpg';

    const allowed = {
      'png',
      'jpg',
      'webp',
      'gif',
      'bmp',
      'heic',
      'heif',
      'tif',
      'tiff',
      'avif',
    };
    if (!allowed.contains(normalized)) {
      return 'png';
    }
    return normalized;
  }

  String? _extractExtension(String? value) {
    if (value == null) return null;
    final normalized = value
        .trim()
        .split('?')
        .first
        .split('#')
        .first
        .replaceAll('\\', '/');
    final lastDot = normalized.lastIndexOf('.');
    if (lastDot < 0 || lastDot == normalized.length - 1) {
      return null;
    }
    final rawExt = normalized.substring(lastDot + 1);
    final cleaned = rawExt.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}
