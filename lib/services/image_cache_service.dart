import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../utils/path_utils.dart';
import '../utils/image_resolver_shared.dart';

class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService instance = ImageCacheService._();
  String? _cacheDirPath;

  Future<Directory> _imagesDir() async {
    final dir = await getAppDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/cached_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<void> init() async {
    if (_cacheDirPath != null) return;
    final dir = await _imagesDir();
    _cacheDirPath = dir.path;
  }

  String _fileNameForUrl(String url) {
    final hash = sha1.convert(url.codeUnits).toString();
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    final ext = path.contains('.') ? path.split('.').last : 'img';
    return '$hash.$ext';
  }

  String? cachedFilePathForUrlSync(String url) {
    if (_cacheDirPath == null) return null;
    final fileName = _fileNameForUrl(url);
    final file = File('$_cacheDirPath/$fileName');
    if (file.existsSync() && file.lengthSync() > 0) {
      return file.path;
    }
    return null;
  }

  Future<String?> cacheImage(String? path, {String? baseUrl}) async {
    await init();
    final normalized = normalizeImagePath(path, baseUrl: baseUrl);
    if (normalized == null || normalized.isEmpty) return null;

    if (normalized.startsWith('file://')) {
      return Uri.parse(normalized).toFilePath();
    }
    if (normalized.startsWith('/')) {
      return normalized;
    }

    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      return null;
    }

    final imagesDir = await _imagesDir();
    final fileName = _fileNameForUrl(normalized);
    final file = File('${imagesDir.path}/$fileName');

    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }

    try {
      final response = await http.get(Uri.parse(normalized));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file.path;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
