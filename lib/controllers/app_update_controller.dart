import 'package:get/get.dart';

import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

enum AppUpdateCheckState { available, upToDate, error }

class AppUpdateController extends GetxController {
  AppUpdateController({AppUpdateService? service})
    : _service = service ?? AppUpdateService();

  final AppUpdateService _service;

  bool _initialized = false;
  bool _isChecking = false;
  bool _isOpeningDownload = false;
  String _currentVersion = '...';
  String _statusMessage = 'Pret a verifier';
  String? _errorMessage;
  AppUpdateInfo? _latestUpdate;

  bool get isChecking => _isChecking;
  bool get isOpeningDownload => _isOpeningDownload;
  String get currentVersion => _currentVersion;
  String get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  AppUpdateInfo? get latestUpdate => _latestUpdate;
  bool get hasUpdate => _latestUpdate != null;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final localVersion = await _service.getLocalVersion();
      _currentVersion = localVersion.fullLabel;
      _statusMessage = 'Version locale detectee';
    } catch (_) {
      _currentVersion = 'Indisponible';
      _statusMessage = 'Impossible de lire la version locale';
    }

    update();
  }

  Future<AppUpdateCheckState> checkForUpdates() async {
    await initialize();
    _isChecking = true;
    _errorMessage = null;
    update();

    try {
      final remoteUpdate = await _service.fetchLatestWindowsUpdate();
      final updateAvailable = _service.isRemoteNewer(
        localVersion: _currentVersion.trim(),
        remoteVersion: remoteUpdate.version,
      );

      if (updateAvailable) {
        _latestUpdate = remoteUpdate;
        _statusMessage = '${remoteUpdate.displayVersion} disponible';
        return AppUpdateCheckState.available;
      }

      _latestUpdate = null;
      _statusMessage = 'Application deja a jour';
      return AppUpdateCheckState.upToDate;
    } catch (e) {
      _latestUpdate = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _statusMessage = 'Verification impossible';
      return AppUpdateCheckState.error;
    } finally {
      _isChecking = false;
      update();
    }
  }

  Future<bool> openLatestUpdate() async {
    final updateInfo = _latestUpdate;
    if (updateInfo == null) {
      _errorMessage = 'Aucune mise a jour disponible.';
      update();
      return false;
    }

    _isOpeningDownload = true;
    _errorMessage = null;
    update();

    try {
      final opened = await _service.openDownloadUrl(updateInfo.downloadUrl);
      if (!opened) {
        _errorMessage = 'Impossible d ouvrir le telechargement.';
      }
      return opened;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isOpeningDownload = false;
      update();
    }
  }
}
