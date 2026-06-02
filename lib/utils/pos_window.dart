import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

class PosWindow {
  static Future<void> open({bool reuseExisting = false}) async {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (!isDesktop) {
      Get.toNamed('/pos');
      return;
    }

    try {
      final existingWindows = await WindowController.getAll();
      if (reuseExisting && existingWindows.isNotEmpty) {
        await existingWindows.first.show();
        return;
      }

      final config = WindowConfiguration(arguments: '/pos');
      final window = await WindowController.create(config);
      await window.show();
    } on MissingPluginException {
      Get.toNamed('/pos');
    } catch (e) {
      Get.toNamed('/pos');
    }
  }
}
