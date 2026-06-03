import 'package:flutter/foundation.dart';
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
    debugPrint('⚙️ [SETTINGS] SettingsController initialized');
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
    final next = current.copyWith(
      currencyCode: code.trim().isEmpty ? current.currencyCode : code.trim(),
      currencySymbol: symbol.trim().isEmpty
          ? current.currencySymbol
          : symbol.trim(),
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
    final next = current.copyWith(
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
    final next = current.copyWith(appLogoPath: nextPath);
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
    final next = current.copyWith(ticketLogoPath: nextPath);
    await AppSettingsService.instance.save(next);
    if (previousPath != null && previousPath != nextPath) {
      await AppSettingsService.instance.deleteManagedLogo(previousPath);
    }
    _settings.value = next;
    update();
  }

  Future<void> updatePrinterSettings({
    String? host,
    int? port,
    bool? useEscPosPrinting,
    ReceiptPrinterTransport? transport,
  }) async {
    final current = settings;
    final normalizedHost = host?.trim();
    final next = current.copyWith(
      receiptPrinterHost: normalizedHost == null || normalizedHost.isEmpty
          ? null
          : normalizedHost,
      receiptPrinterPort: port ?? current.receiptPrinterPort,
      useEscPosPrinting: useEscPosPrinting ?? current.useEscPosPrinting,
      receiptPrinterTransport: transport ?? current.receiptPrinterTransport,
    );
    await AppSettingsService.instance.save(next);
    _settings.value = next;
    update();
  }

  Future<void> updateKitchenPrinterSettings({
    String? host,
    int? port,
    ReceiptPrinterTransport? transport,
  }) async {
    final current = settings;
    final normalizedHost = host?.trim();
    final next = current.copyWith(
      kitchenReceiptPrinterHost: normalizedHost == null || normalizedHost.isEmpty
          ? null
          : normalizedHost,
      kitchenReceiptPrinterPort: port ?? current.kitchenReceiptPrinterPort,
      kitchenReceiptPrinterTransport:
          transport ?? current.kitchenReceiptPrinterTransport,
    );
    await AppSettingsService.instance.save(next);
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
