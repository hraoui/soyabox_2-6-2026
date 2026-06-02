import 'package:flutter/material.dart';
import 'image_resolver_shared.dart';

ImageProvider? resolveImageProviderImpl(String? path, {String? baseUrl}) {
  final normalized = normalizeImagePath(path, baseUrl: baseUrl);
  if (normalized == null) return null;

  if (normalized.startsWith('file://') || normalized.startsWith('/')) {
    return null;
  }

  return NetworkImage(normalized);
}
