import '../data/app_constants.dart';

String? normalizeImagePath(String? path, {String? baseUrl}) {
  if (path == null) return null;
  final trimmed = path.trim().replaceAll('\\', '/');
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('data:image/')) {
    return trimmed;
  }

  final base = (baseUrl ?? AppConstant.baseUrl).replaceAll(RegExp(r'/+$'), '');

  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('file://')) {
    return _replaceLoopbackHost(trimmed, base);
  }

  if (trimmed.startsWith('/')) {
    if (_isLikelyLocalAbsolutePath(trimmed)) {
      return trimmed;
    }
    final rel = trimmed.replaceAll(RegExp(r'^/+'), '');
    return '$base/$rel';
  }

  if (_isLikelyServerRelativePath(trimmed)) {
    final rel = trimmed.replaceAll(RegExp(r'^/+'), '');
    return '$base/$rel';
  }

  if (_isLikelyLocalAbsolutePath(trimmed)) {
    return trimmed;
  }

  final rel = trimmed.replaceAll(RegExp(r'^/+'), '');
  return '$base/$rel';
}

bool _isLikelyServerRelativePath(String value) {
  final v = value.toLowerCase();
  return v.startsWith('storage/') ||
      v.startsWith('uploads/') ||
      v.startsWith('upload/') ||
      v.startsWith('media/') ||
      v.startsWith('images/') ||
      v.startsWith('img/');
}

bool _isLikelyLocalAbsolutePath(String value) {
  // Common absolute prefixes on macOS/Linux/Android and Windows drive paths.
  return value.startsWith('/Users/') ||
      value.startsWith('/home/') ||
      value.startsWith('/var/') ||
      value.startsWith('/private/') ||
      value.startsWith('/data/') ||
      value.startsWith('/storage/emulated/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(value);
}

String _replaceLoopbackHost(String url, String base) {
  final imageUri = Uri.tryParse(url);
  final baseUri = Uri.tryParse(base);
  if (imageUri == null || baseUri == null) return url;

  final host = imageUri.host.toLowerCase();
  final isLoopback =
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '::1';
  final baseHost = baseUri.host.toLowerCase();

  if (!isLoopback || baseHost.isEmpty || baseHost == host) {
    return url;
  }

  final replaced = imageUri.replace(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : imageUri.port,
  );
  return replaced.toString();
}
