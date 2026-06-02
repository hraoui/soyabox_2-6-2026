import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '../models/app_settings.dart';
import '../services/app_settings_service.dart';

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  final Rx<AppSettings> _settings = AppSettings().obs;
  AppSettings get settings => _settings.value;

  @override
  void onInit() {
    super.onInit();
    // AppSettingsService is already initialized in dependencies.dart
    print('⚙️ [SETTINGS] SettingsController initialized');
    load();
  }

  Future<void> load() async {
    await AppSettingsService.instance.init();
    _settings.value = AppSettingsService.instance.settings;
    update();
  }

  Future<void> updateCurrency({
    required String code,
    required String symbol,
  }) async {
    final current = settings;
    final next = AppSettings(
      currencyCode: code.trim().isEmpty ? current.currencyCode : code.trim(),
      currencySymbol: symbol.trim().isEmpty
          ? current.currencySymbol
          : symbol.trim(),
      appLogoPath: current.appLogoPath,
      ticketLogoPath: current.ticketLogoPath,
      dayStartHour: current.dayStartHour,
      dayEndHour: current.dayEndHour,
    );
    await AppSettingsService.instance.save(next);
    _settings.value = next;
    update();
  }

  Future<void> updateDayHours({
    required int startHour,
    required int endHour,
  }) async {
    final current = settings;
    final next = AppSettings(
      currencyCode: current.currencyCode,
      currencySymbol: current.currencySymbol,
      appLogoPath: current.appLogoPath,
      ticketLogoPath: current.ticketLogoPath,
      dayStartHour: startHour.clamp(0, 23),
      dayEndHour: endHour.clamp(0, 23),
    );
    await AppSettingsService.instance.save(next);
    _settings.value = next;
    update();
  }

  Future<void> updateAppLogo(String? path) async {
    final current = settings;
    final normalizedPath = path?.trim();
    final nextPath = (normalizedPath == null || normalizedPath.isEmpty)
        ? null
        : normalizedPath;
    final previousPath = current.appLogoPath;
    final next = AppSettings(
      currencyCode: current.currencyCode,
      currencySymbol: current.currencySymbol,
      appLogoPath: nextPath,
      ticketLogoPath: current.ticketLogoPath,
    );
    await AppSettingsService.instance.save(next);
    if (previousPath != null && previousPath != nextPath) {
      await AppSettingsService.instance.deleteManagedLogo(previousPath);
    }
    _settings.value = next;
    update();
  }

  Future<void> updateTicketLogo(String? path) async {
    final current = settings;
    final normalizedPath = path?.trim();
    final nextPath = (normalizedPath == null || normalizedPath.isEmpty)
        ? null
        : normalizedPath;
    final previousPath = current.ticketLogoPath;
    final next = AppSettings(
      currencyCode: current.currencyCode,
      currencySymbol: current.currencySymbol,
      appLogoPath: current.appLogoPath,
      ticketLogoPath: nextPath,
    );
    await AppSettingsService.instance.save(next);
    if (previousPath != null && previousPath != nextPath) {
      await AppSettingsService.instance.deleteManagedLogo(previousPath);
    }
    _settings.value = next;
    update();
  }

  Future<bool> uploadAppLogo(PlatformFile file) async {
    final savedPath = await AppSettingsService.instance.persistSettingsLogo(
      targetBasename: 'app_logo',
      sourcePath: file.path,
      bytes: file.bytes,
      originalFileName: file.name,
    );
    if (savedPath == null) return false;
    await updateAppLogo(savedPath);
    return true;
  }

  Future<bool> uploadTicketLogo(PlatformFile file) async {
    final savedPath = await AppSettingsService.instance.persistSettingsLogo(
      targetBasename: 'ticket_logo',
      sourcePath: file.path,
      bytes: file.bytes,
      originalFileName: file.name,
    );
    if (savedPath == null) return false;
    await updateTicketLogo(savedPath);
    return true;
  }
}
