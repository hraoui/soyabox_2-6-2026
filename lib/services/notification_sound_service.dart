import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class NotificationSoundService {
  NotificationSoundService._();
  static final NotificationSoundService instance = NotificationSoundService._();

  bool _initialized = false;
  DateTime? _lastPlayedAt;
  Set<String>? _assetManifestKeys;
  AudioPlayer? _audioPlayer;
  bool _audioConfigured = false;

  Future<void> init() async {
    if (_initialized && _audioConfigured) {
      appLogger.d('🔔 [NOTIF] NotificationSoundService already initialized');
      return;
    }
    appLogger.d('🔔 [NOTIF] Initializing NotificationSoundService...');
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      _audioConfigured = true;
      appLogger.d('✅ [NOTIF] Audio player configured');
    } catch (e) {
      appLogger.d('Audio init failed: $e');
      appLogger.e('❌ [NOTIF] Audio init failed: $e');
      _audioConfigured = false;
    }
    _initialized = true;
    appLogger.d('✅ [NOTIF] NotificationSoundService initialized');
  }

  Future<void> playNewOrderAlarm({
    Duration minInterval = const Duration(seconds: 2),
  }) async {
    await init();

    final now = DateTime.now();
    final last = _lastPlayedAt;
    if (last != null && now.difference(last) < minInterval) {
      appLogger.d('⚠️ Notification sound skipped (too soon)');
      return;
    }

    appLogger.d('🔔 Playing new order notification...');

    // Essaye les assets si dispo (mobile), sinon passe à l'alerte système.
    final played = await _playAssetFallbackChain();
    if (!played) {
      appLogger.d('⚠️ No asset found, trying system sound');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        appLogger.d('System sound failed: $e');
      }
    }
    _lastPlayedAt = now;
  }

  Future<bool> _playAssetFallbackChain() async {
    // Priorité au son principal fourni dans assets/audio/order-notification.mp3
    const candidates = [
      'audio/order-notification.mp3',
      'audio/order_alarm.mp3',
      'audio/alert.mp3',
    ];

    for (final assetPath in candidates) {
      final exists = await _assetExists(assetPath);
      if (!exists) {
        appLogger.d('⚠️ Asset not found: $assetPath');
        continue;
      }
      appLogger.d('▶️ Trying to play: $assetPath');
      try {
        if (_audioConfigured && _audioPlayer != null) {
          await _audioPlayer!.stop();
          await _audioPlayer!.setVolume(1.0);
          await _audioPlayer!.play(AssetSource(assetPath));
          appLogger.d('✅ Playing: $assetPath');
          return true;
        } else {
          appLogger.d('⚠️ Audio player not configured');
        }
      } catch (e) {
        appLogger.d('❌ Order alarm asset playback failed for $assetPath: $e');
      }
    }
    return false;
  }

  Future<bool> _assetExists(String relativeAssetPath) async {
    final key = 'assets/$relativeAssetPath';
    final keys = await _manifestKeys();
    if (keys != null) {
      return keys.contains(key);
    }

    try {
      await rootBundle.load(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>?> _manifestKeys() async {
    final cached = _assetManifestKeys;
    if (cached != null) return cached;

    try {
      final jsonText = await rootBundle.loadString('AssetManifest.json');
      if (jsonText.trim().isEmpty) return null;
      final decoded = json.decode(jsonText);
      if (decoded is! Map) return null;
      final keys = decoded.keys
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toSet();
      _assetManifestKeys = keys;
      return keys;
    } catch (_) {
      return null;
    }
  }
}
