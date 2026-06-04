import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/app_logger.dart';

class FullscreenService {
  static const _prefKey = 'app_fullscreen_enabled';
  static bool _initialized = false;
  static bool _isFullscreen = true; // ✅ Default to fullscreen on desktop

  static bool get isFullscreen => _isFullscreen;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isFullscreen = prefs.getBool(_prefKey) ?? true; // ✅ Default to true on desktop
    } catch (e) {
      appLogger.w('⚠️ [Fullscreen] Could not read preferences: $e');
    }

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      appLogger.d('ℹ️ [Fullscreen] Non-desktop platform - skipping window_manager init');
      return;
    }

    try {
      await windowManager.ensureInitialized();
      final options = const WindowOptions();
      await windowManager.waitUntilReadyToShow(options);
      await windowManager.setFullScreen(_isFullscreen);
      if (_isFullscreen) {
        appLogger.i('✅ [Fullscreen] Fullscreen enabled - taskbar/dock hidden');
      }
      _setupKeyboardShortcuts();
      appLogger.i('✅ [Fullscreen] Initialized, fullscreen=$_isFullscreen');
    } catch (e) {
      appLogger.e('❌ [Fullscreen] Initialization failed: $e');
    }
  }

  static void _setupKeyboardShortcuts() {
    // F11 to toggle fullscreen
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  static void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        toggle();
      }
    }
  }

  static Future<void> setFullscreen(bool enabled) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      appLogger.d('ℹ️ [Fullscreen] setFullscreen ignored on non-desktop');
      return;
    }

    try {
      await windowManager.setFullScreen(enabled);
      _isFullscreen = enabled;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKey, _isFullscreen);
      } catch (e) {
        appLogger.w('⚠️ [Fullscreen] Could not save preference: $e');
      }
      appLogger.i('✅ [Fullscreen] setFullscreen=$enabled');
    } catch (e) {
      appLogger.e('❌ [Fullscreen] setFullscreen failed: $e');
    }
  }

  static Future<void> toggle([bool? enabled]) async {
    final target = enabled ?? !_isFullscreen;
    await setFullscreen(target);
  }
}
