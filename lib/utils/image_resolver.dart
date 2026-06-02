import 'package:flutter/material.dart';
import 'image_resolver_io.dart'
    if (dart.library.html) 'image_resolver_web.dart';

ImageProvider? resolveImageProvider(String? path, {String? baseUrl}) {
  return resolveImageProviderImpl(path, baseUrl: baseUrl);
}
