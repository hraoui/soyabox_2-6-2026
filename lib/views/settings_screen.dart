import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_update_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings.dart';
import '../models/app_update_info.dart';
import '../services/database_service.dart';
import '../services/fullscreen_service.dart';
import '../theme/sushi_design.dart';
import '../utils/image_resolver.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';
import '../widgets/sushi_cta_button.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _codeController;
  late final TextEditingController _symbolController;
  late final TextEditingController _dayStartController;
  late final TextEditingController _dayEndController;
  late final TextEditingController _printerHostController;
  late final TextEditingController _printerPortController;
  late final TextEditingController _kitchenPrinterHostController;
  late final TextEditingController _kitchenPrinterPortController;
  late bool _useEscPosPrinting;
  late ReceiptPrinterTransport _printerTransport;
  late ReceiptPrinterTransport _kitchenPrinterTransport;
  late final AppUpdateController _appUpdateController;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>().settings;
    _codeController = TextEditingController(text: settings.currencyCode);
    _symbolController = TextEditingController(text: settings.currencySymbol);
    _dayStartController = TextEditingController(
      text: settings.dayStartHour.toString(),
    );
    _dayEndController = TextEditingController(
      text: settings.dayEndHour.toString(),
    );
    _printerHostController = TextEditingController(
      text: settings.receiptPrinterHost ?? '',
    );
    _printerPortController = TextEditingController(
      text: settings.receiptPrinterPort.toString(),
    );
    _kitchenPrinterHostController = TextEditingController(
      text: settings.kitchenReceiptPrinterHost ?? '',
    );
    _kitchenPrinterPortController = TextEditingController(
      text: settings.kitchenReceiptPrinterPort.toString(),
    );
    _useEscPosPrinting = settings.useEscPosPrinting;
    _printerTransport = settings.receiptPrinterTransport;
    _kitchenPrinterTransport = settings.kitchenReceiptPrinterTransport;
    _appUpdateController = Get.isRegistered<AppUpdateController>()
        ? Get.find<AppUpdateController>()
        : Get.put(AppUpdateController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appUpdateController.initialize();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _symbolController.dispose();
    _dayStartController.dispose();
    _dayEndController.dispose();
    _printerHostController.dispose();
    _printerPortController.dispose();
    _kitchenPrinterHostController.dispose();
    _kitchenPrinterPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final auth = Get.find<AuthController>();
    final isSuperadmin = auth.currentRole == 'superadmin';

    return AdminShell(
      title: 'Paramètres',
      activeRoute: '/settings',
      child: GetBuilder<SettingsController>(
        builder: (_) {
          final settings = controller.settings;
          return LayoutBuilder(
            builder: (context, constraints) {
              final grid = AppWrapGrid(
                minChildWidth: constraints.maxWidth >= 1200 ? 420 : 300,
                maxChildWidth: 520,
                spacing: SushiSpace.md,
                runSpacing: SushiSpace.md,
                maxColumns: constraints.maxWidth >= 1200
                    ? 2
                    : 1,
                children: [
                  _settingCard(
                    icon: Icons.currency_exchange,
                    title: 'Devise',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _textField(
                          controller: _codeController,
                          label: 'Code devise',
                          hint: 'MAD',
                          icon: Icons.code,
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        _textField(
                          controller: _symbolController,
                          label: 'Symbole',
                          hint: 'DH',
                          icon: Icons.attach_money,
                        ),
                        const SizedBox(height: SushiSpace.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SushiCTAButton(
                            child: const Text('Enregistrer'),
                            onPressed: () async {
                              await controller.updateCurrency(
                                code: _codeController.text,
                                symbol: _symbolController.text,
                              );
                              if (!mounted) return;
                              _toast(true, 'Devise mise à jour');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Carte configuration heures de journée
                  _settingCard(
                    icon: Icons.schedule,
                    title: 'Heures de la journée de service',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Définissez les heures de début et fin de votre journée de service.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: SushiSpace.sm),

                        // ✅ Afficher le nombre d'heures de travail
                        Container(
                          padding: const EdgeInsets.all(SushiSpace.md),
                          decoration: BoxDecoration(
                            color: SushiColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SushiColors.teal.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: SushiColors.teal,
                                size: 24,
                              ),
                              const SizedBox(width: SushiSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${settings.dayStartHour.toString().padLeft(2, '0')}h00 → ${settings.dayEndHour.toString().padLeft(2, '0')}h59',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: SushiColors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Durée: ${_calculateWorkHours(settings.dayStartHour, settings.dayEndHour)} heures',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: SushiColors.inkMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: SushiSpace.md),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller: _dayStartController,
                                label: 'Heure début (0-23)',
                                hint: '0',
                                icon: Icons.wb_sunny,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: SushiSpace.md),
                            Expanded(
                              child: _textField(
                                controller: _dayEndController,
                                label: 'Heure fin (0-23)',
                                hint: '23',
                                icon: Icons.nights_stay,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SushiSpace.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SushiCTAButton(
                            child: const Text('Enregistrer'),
                            onPressed: () async {
                              final startHour = int.tryParse(
                                _dayStartController.text,
                              );
                              final endHour = int.tryParse(
                                _dayEndController.text,
                              );

                              if (startHour == null ||
                                  endHour == null ||
                                  startHour < 0 ||
                                  startHour > 23 ||
                                  endHour < 0 ||
                                  endHour > 23) {
                                _toast(false, 'Heures invalides (0-23)');
                                return;
                              }

                              await controller.updateDayHours(
                                startHour: startHour,
                                endHour: endHour,
                              );
                              if (!mounted) return;

                              // Mettre à jour les controllers
                              _dayStartController.text = startHour.toString();
                              _dayEndController.text = endHour.toString();

                              _toast(
                                true,
                                'Journée configurée: ${startHour.toString().padLeft(2, '0')}h00 → ${endHour.toString().padLeft(2, '0')}h59 (${_calculateWorkHours(startHour, endHour)}h)',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUpdateCard(),
                  // ✅ Clear Data Card (Superadmin only)
                  if (isSuperadmin)
                    _settingCard(
                      icon: Icons.delete_sweep,
                      title: 'Supprimer données locales',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Effacer toutes les données locales (users, commandes, etc.) sauf le superadmin.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: SushiSpace.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _showClearDataConfirm(),
                              icon: const Icon(Icons.delete_forever, size: 18),
                              label: const Text('Tout effacer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _settingCard(
                    icon: Icons.print,
                    title: 'Imprimante ESC/POS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Impression directe vers une imprimante thermique réseau ou USB. '
                          'En mode Auto, l\'app essaie d\'abord le réseau puis bascule vers l\'USB.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Activer l\'impression directe ESC/POS',
                          ),
                          subtitle: const Text(
                            'Désactivé, les tickets repassent par l\'aperçu PDF.',
                          ),
                          value: _useEscPosPrinting,
                          onChanged: (value) {
                            setState(() => _useEscPosPrinting = value);
                          },
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        DropdownButtonFormField<ReceiptPrinterTransport>(
                          value: _printerTransport,
                          decoration: const InputDecoration(
                            labelText: 'Mode de connexion',
                            prefixIcon: Icon(Icons.swap_horiz, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.auto,
                              child: Text('Auto (réseau puis USB)'),
                            ),
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.network,
                              child: Text('Réseau'),
                            ),
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.usb,
                              child: Text('USB'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _printerTransport = value);
                          },
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _textField(
                                controller: _printerHostController,
                                label: 'IP imprimante (réseau)',
                                hint: '192.168.1.50',
                                icon: Icons.router,
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            const SizedBox(width: SushiSpace.md),
                            SizedBox(
                              width: 140,
                              child: _textField(
                                controller: _printerPortController,
                                label: 'Port TCP/IP',
                                hint: '9100',
                                icon: Icons.settings_ethernet,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        if (_printerTransport ==
                            ReceiptPrinterTransport.usb) ...[
                          const SizedBox(height: SushiSpace.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(SushiSpace.md),
                            decoration: BoxDecoration(
                              color: SushiColors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: SushiColors.teal.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              'Mode USB actif: aucune adresse IP n\'est requise. '
                              'L\'app scanne l\'imprimante USB au moment de l\'impression.',
                              style: TextStyle(
                                fontSize: 12,
                                color: SushiColors.inkMid,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: SushiSpace.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SushiCTAButton(
                            child: const Text('Enregistrer'),
                            onPressed: () async {
                              final host = _printerHostController.text.trim();
                              final port =
                                  int.tryParse(
                                    _printerPortController.text.trim(),
                                  ) ??
                                  9100;

                              if (_useEscPosPrinting &&
                                  _printerTransport ==
                                      ReceiptPrinterTransport.network &&
                                  host.isEmpty) {
                                _toast(
                                  false,
                                  'Renseignez l\'IP de l\'imprimante ESC/POS',
                                );
                                return;
                              }

                              if (port <= 0 || port > 65535) {
                                _toast(false, 'Port imprimante invalide');
                                return;
                              }

                              await controller.updatePrinterSettings(
                                host: host,
                                port: port,
                                useEscPosPrinting: _useEscPosPrinting,
                                transport: _printerTransport,
                              );
                              if (!mounted) return;
                              _toast(
                                true,
                                'Paramètres d\'impression enregistrés',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fullscreen (desktop only)
                  _settingCard(
                    icon: Icons.fullscreen,
                    title: 'Plein écran (Desktop)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Le plein écran est activé par défaut sur desktop (Windows/macOS). La barre des tâches/dock est masquée. Appuyez sur F11 pour basculer.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        StatefulBuilder(builder: (context, setState) {
                          final enabled = FullscreenService.isFullscreen;
                          return SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Activer le plein écran'),
                            value: enabled,
                            onChanged: (value) async {
                              await FullscreenService.toggle(value);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  _settingCard(
                    icon: Icons.kitchen,
                    title: 'Imprimante cuisine',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurez une imprimante dédiée au ticket cuisine. '
                          'Laisser vide pour utiliser la même imprimante que le ticket client.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        DropdownButtonFormField<ReceiptPrinterTransport>(
                          value: _kitchenPrinterTransport,
                          decoration: const InputDecoration(
                            labelText: 'Mode de connexion',
                            prefixIcon: Icon(Icons.swap_horiz, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.auto,
                              child: Text('Auto (réseau puis USB)'),
                            ),
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.network,
                              child: Text('Réseau'),
                            ),
                            DropdownMenuItem(
                              value: ReceiptPrinterTransport.usb,
                              child: Text('USB'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _kitchenPrinterTransport = value);
                          },
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _textField(
                                controller: _kitchenPrinterHostController,
                                label: 'IP imprimante cuisine (réseau)',
                                hint: '192.168.1.51',
                                icon: Icons.router,
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            const SizedBox(width: SushiSpace.md),
                            SizedBox(
                              width: 140,
                              child: _textField(
                                controller: _kitchenPrinterPortController,
                                label: 'Port TCP/IP',
                                hint: '9100',
                                icon: Icons.settings_ethernet,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        if (_kitchenPrinterTransport ==
                            ReceiptPrinterTransport.usb) ...[
                          const SizedBox(height: SushiSpace.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(SushiSpace.md),
                            decoration: BoxDecoration(
                              color: SushiColors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: SushiColors.teal.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              'Mode USB actif: aucune adresse IP n\'est requise. '
                              'L\'app scanne l\'imprimante USB au moment de l\'impression.',
                              style: TextStyle(
                                fontSize: 12,
                                color: SushiColors.inkMid,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: SushiSpace.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SushiCTAButton(
                            child: const Text('Enregistrer imprimante cuisine'),
                            onPressed: () async {
                              final host = _kitchenPrinterHostController.text.trim();
                              final port =
                                  int.tryParse(
                                    _kitchenPrinterPortController.text.trim(),
                                  ) ??
                                  9100;

                              if (_useEscPosPrinting &&
                                  _kitchenPrinterTransport ==
                                      ReceiptPrinterTransport.network &&
                                  host.isEmpty) {
                                _toast(
                                  false,
                                  'Renseignez l\'IP de l\'imprimante cuisine',
                                );
                                return;
                              }

                              if (port <= 0 || port > 65535) {
                                _toast(false, 'Port imprimante invalide');
                                return;
                              }

                              await controller.updateKitchenPrinterSettings(
                                host: host,
                                port: port,
                                transport: _kitchenPrinterTransport,
                              );
                              if (!mounted) return;
                              _toast(
                                true,
                                'Paramètres imprimante cuisine enregistrés',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _settingCard(
                    icon: Icons.apps,
                    title: 'Logo Application',
                    child: _logoPickerCard(
                      path: settings.appLogoPath,
                      onPick: () => _handlePick(
                        pick: controller.uploadAppLogo,
                        label: 'logo application',
                      ),
                      onClear: () async {
                        await controller.updateAppLogo(null);
                        if (!mounted) return;
                        _toast(true, 'Logo application supprimé');
                      },
                    ),
                  ),
                  _settingCard(
                    icon: Icons.receipt_long,
                    title: 'Logo Ticket',
                    child: _logoPickerCard(
                      path: settings.ticketLogoPath,
                      onPick: () => _handlePick(
                        pick: controller.uploadTicketLogo,
                        label: 'logo ticket',
                      ),
                      onClear: () async {
                        await controller.updateTicketLogo(null);
                        if (!mounted) return;
                        _toast(true, 'Logo ticket supprimé');
                      },
                    ),
                  ),
                  // ✅ Carte gestion des tables (visible uniquement pour les admins)
                  if (isSuperadmin || auth.currentRole == 'admin')
                    _settingCard(
                      icon: Icons.table_restaurant,
                      title: 'Gestion des Tables',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurez et gérez les tables de votre restaurant.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: SushiSpace.md),
                          SushiCTAButton(
                            child: const Text('Configurer les Tables'),
                            onPressed: () {
                              Get.toNamed('/table-management');
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(SushiSpace.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        grid,
                        const SizedBox(height: SushiSpace.lg),
                        _infoPanel(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handlePick({
    required Future<bool> Function(PlatformFile file) pick,
    required String label,
  }) async {
    final selectedFile = await _pickImageFile();
    if (selectedFile == null) return;
    final ok = await pick(selectedFile);
    if (!mounted) return;
    _toast(ok, ok ? '$label mis à jour' : 'Impossible de traiter le fichier');
  }

  Future<PlatformFile?> _pickImageFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        lockParentWindow: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      if (file.path == null) return null;
      return file;
    } catch (e) {
      _toast(false, 'Sélection impossible: $e');
      return null;
    }
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppCardIconBadge(
                icon: icon,
                accent: SushiColors.red,
                background: SushiColors.redSurface,
                size: 46,
                iconSize: 22,
              ),
              const SizedBox(width: SushiSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style:
                      SushiTypo.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: SushiSpace.md),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: SushiColors.inkMid),
      ),
    );
  }

  Widget _logoPickerCard({
    required String? path,
    required Future<void> Function() onPick,
    required Future<void> Function() onClear,
  }) {
    final imageProvider = resolveImageProvider(path);
    final preview = imageProvider == null
        ? _logoPlaceholder()
        : Image(
            image: imageProvider,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _logoPlaceholder(),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: SushiDeco.card(),
          padding: const EdgeInsets.all(SushiSpace.sm),
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          child: preview,
        ),
        const SizedBox(height: SushiSpace.sm),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await onPick();
              },
              icon: const Icon(Icons.image, size: 18),
              label: const Text('Choisir'),
              style: SushiButtonStyle.secondary(),
            ),
            const SizedBox(width: SushiSpace.sm),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: ButtonStyle(
                foregroundColor: const WidgetStatePropertyAll(SushiColors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: SushiColors.inkLight,
        ),
        const SizedBox(height: SushiSpace.sm),
        const Text('Aucun logo', style: SushiTypo.caption),
      ],
    );
  }

  Widget _buildUpdateCard() {
    return GetBuilder<AppUpdateController>(
      init: _appUpdateController,
      builder: (controller) {
        final latestUpdate = controller.latestUpdate;
        return _settingCard(
          icon: Icons.system_update_alt,
          title: 'Mise a jour application',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusLine(
                label: 'Version actuelle',
                value: controller.currentVersion,
              ),
              const SizedBox(height: SushiSpace.sm),
              _statusLine(
                label: 'Etat',
                value: controller.statusMessage,
                highlighted: controller.hasUpdate,
              ),
              if (latestUpdate != null) ...[
                const SizedBox(height: SushiSpace.sm),
                _statusLine(
                  label: 'Disponible',
                  value: latestUpdate.displayVersion,
                  highlighted: true,
                ),
              ],
              const SizedBox(height: SushiSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SushiSpace.md),
                decoration: BoxDecoration(
                  color: SushiColors.surface,
                  borderRadius: BorderRadius.circular(SushiRadius.md),
                  border: Border.all(color: SushiColors.divider),
                ),
                child: Text(
                  latestUpdate?.message ??
                      'Verifiez la derniere version Windows disponible sur votre backend Laravel.',
                  style: SushiTypo.bodySm,
                ),
              ),
              const SizedBox(height: SushiSpace.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isChecking
                          ? null
                          : _checkForUpdates,
                      icon: controller.isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        controller.isChecking ? 'Verification...' : 'Verifier',
                      ),
                      style: SushiButtonStyle.secondary(),
                    ),
                  ),
                  if (controller.hasUpdate) ...[
                    const SizedBox(width: SushiSpace.sm),
                    Expanded(
                      child: SushiCTAButton(
                        fullWidth: true,
                        icon: Icons.download_rounded,
                        onPressed: controller.isOpeningDownload
                            ? () {}
                            : _openLatestUpdate,
                        child: Text(
                          controller.isOpeningDownload
                              ? 'Ouverture...'
                              : 'Mettre a jour',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusLine({
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: SushiTypo.caption.copyWith(color: SushiColors.inkMid),
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: SushiTypo.bodyMd.copyWith(
              color: highlighted ? SushiColors.red : SushiColors.ink,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPanel() {
    return Container(
      width: double.infinity,
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Astuces paramétrage', style: SushiTypo.h2),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.print,
            text:
                'Le logo ticket est utilisé sur les reçus imprimés (salle & livraison).',
          ),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.apps,
            text:
                'Le logo application apparaît dans le lanceur et l’écran de connexion.',
          ),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.currency_exchange,
            text: 'Mettez à jour code et symbole pour aligner prix et tickets.',
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final result = await _appUpdateController.checkForUpdates();
    if (!mounted) {
      return;
    }

    switch (result) {
      case AppUpdateCheckState.available:
        final latestUpdate = _appUpdateController.latestUpdate;
        if (latestUpdate != null) {
          _showUpdateDialog(latestUpdate);
        }
        break;
      case AppUpdateCheckState.upToDate:
        _toast(true, 'Application deja a jour');
        break;
      case AppUpdateCheckState.error:
        _toast(
          false,
          _appUpdateController.errorMessage ?? 'Verification impossible',
        );
        break;
    }
  }

  Future<void> _openLatestUpdate({bool closeDialogOnSuccess = false}) async {
    final opened = await _appUpdateController.openLatestUpdate();
    if (!mounted) {
      return;
    }

    if (opened) {
      if (closeDialogOnSuccess && Get.isDialogOpen == true) {
        Get.back();
      }
      _toast(
        true,
        'Telechargement lance. Fermez ensuite l application puis executez l installateur.',
      );
    } else {
      _toast(
        false,
        _appUpdateController.errorMessage ??
            'Impossible d ouvrir le lien de telechargement',
      );
    }
  }

  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    Get.dialog(
      GetBuilder<AppUpdateController>(
        init: _appUpdateController,
        builder: (controller) => UpdateDialog(
          currentVersion: controller.currentVersion,
          updateInfo: updateInfo,
          isBusy: controller.isOpeningDownload,
          onDownload: () async {
            await _openLatestUpdate(closeDialogOnSuccess: true);
          },
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _toast(bool success, String message) {
    Get.snackbar(
      success ? 'Succès' : 'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? SushiColors.green : SushiColors.error,
      colorText: SushiColors.white,
    );
  }

  // ✅ Show confirmation dialog before clearing data
  void _showClearDataConfirm() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('⚠️ Attention'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous allez supprimer :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _bulletPoint('Tous les utilisateurs (sauf superadmin)'),
            _bulletPoint('Tous les livreurs'),
            _bulletPoint('Toutes les commandes'),
            _bulletPoint('Tous les produits et catégories'),
            _bulletPoint('Toutes les tables'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les comptes superadmin seront conservés',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _clearAllData();
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.red.shade700)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // ✅ Clear all data except admins
  Future<void> _clearAllData() async {
    try {
      debugPrint('🗑️ Starting clear all data...');

      // Count users before
      final usersBefore = await DatabaseService.getAllUsers();
      debugPrint('📊 Users before clear: ${usersBefore.length}');

      await DatabaseService.clearAllDataExceptSuperadmins();

      // Count users after
      final usersAfter = await DatabaseService.getAllUsers();
      debugPrint('📊 Users after clear: ${usersAfter.length}');
      debugPrint('✅ Clear completed! Admins kept: ${usersAfter.length}');

      if (Get.isRegistered<RestaurantController>()) {
        Get.find<RestaurantController>().clearLocalRestaurants();
      }
      if (Get.isRegistered<CategoryController>()) {
        Get.find<CategoryController>().clearLocalCategories();
      }
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().clearLocalProducts();
      }
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().logout();
      }

      if (!mounted) return;

      _toast(true, 'Données locales supprimées (superadmin conservé)');

      // Show success dialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('✅ Succès'),
            ],
          ),
          content: const Text(
            'Toutes les données locales ont été supprimées.\n\nSeuls les comptes admin ont été conservés.\n\nReconnectez-vous pour recharger les données.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();
                // Redirect to login
                Get.offAllNamed('/login');
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(false, 'Erreur: ${e.toString()}');
    }
  }

  /// ✅ Calculer le nombre d'heures de travail entre l'heure de début et de fin
  /// Gère le cas où l'heure de fin est inférieure à l'heure de début (passe minuit)
  String _calculateWorkHours(int startHour, int endHour) {
    double hours;

    if (endHour >= startHour) {
      // Cas normal: ex. 9h → 17h = 8 heures
      hours = (endHour - startHour).toDouble();
    } else {
      // Cas avec passage à minuit: ex. 22h → 6h = 8 heures
      hours = (24 - startHour + endHour).toDouble();
    }

    // Formater: si entier, afficher sans décimale, sinon avec .5
    if (hours == hours.toInt()) {
      return '${hours.toInt()}';
    } else {
      return hours.toStringAsFixed(1);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: SushiDeco.badge(bg: SushiColors.redPale),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: SushiColors.red),
        ),
        const SizedBox(width: SushiSpace.sm),
        Expanded(child: Text(text, style: SushiTypo.bodyMd)),
      ],
    );
  }
}
