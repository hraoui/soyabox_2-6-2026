import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<Directory> getAppDocumentsDirectory() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    if (directory.path.isNotEmpty) {
      return directory;
    }
  } catch (_) {
    // Fallback to a manual path on desktop platforms when the plugin fails.
  }

  return _fallbackAppDocumentsDirectory();
}

Directory _fallbackAppDocumentsDirectory() {
  final String basePath;
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '.';
    basePath = path.join(home, 'Library', 'Application Support', 'caisse_1');
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        '.';
    basePath = path.join(appData, 'caisse_1');
  } else if (Platform.isLinux) {
    final home = Platform.environment['HOME'] ?? '.';
    basePath = path.join(home, '.config', 'caisse_1');
  } else {
    basePath = path.join(Directory.current.path, 'caisse_1');
  }

  final directory = Directory(basePath);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  return directory;
}
