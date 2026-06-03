// ignore_for_file: unused_element, unused_local_variable

import 'dart:typed_data';
import 'package:caisse_1/utils/pos_ticket_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../controllers/cash_register_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/daily_report_service.dart';
import '../services/esc_pos_printer_service.dart';

class CashRegisterStatusScreen extends StatelessWidget {
  final CashRegisterController controller = Get.find<CashRegisterController>();

  CashRegisterStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isAdmin =
        authController.currentUser?.isSuperadmin() == true ||
        authController.currentUser?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'État de la caisse',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => SingleChildScrollView(
            child: Column(
              children: [
                // ── Carte état de la caisse ──────────────────────────
                _CompactCard(
                  child: Column(
                    children: [
                      // Icône état compacte
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (controller.isCashRegisterOpen
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.1),
                        ),
                        child: Icon(
                          controller.isCashRegisterOpen
                              ? Icons.check_circle_rounded
                              : Icons.highlight_off_rounded,
                          size: 36,
                          color: controller.isCashRegisterOpen
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.isCashRegisterOpen
                            ? 'Caisse Ouverte'
                            : (controller.isCashRegisterLocked
                                  ? 'Caisse Bloquée'
                                  : 'Caisse Fermée'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date : ${DateTime.now().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.isCashRegisterOpen
                            ? 'Session en cours depuis l\'ouverture de caisse.'
                            : 'La session commence uniquement à l\'activation manuelle.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bouton ouverture
                      if (!controller.isCashRegisterOpen &&
                          !controller.isCashRegisterLocked)
                        _CompactButton(
                          label: 'Activer la caisse',
                          icon: Icons.play_circle_fill_rounded,
                          color: const Color(0xFF22C55E),
                          onPressed: () async {
                            final authController = Get.find<AuthController>();
                            final staffId = authController.currentUser?.id ?? 0;
                            final staffName =
                                authController.currentUser?.name ?? 'Inconnu';
                            final success = await controller.openCashRegister(
                              staffId: staffId,
                              staffName: staffName,
                            );
                            if (success) {
                              Get.snackbar(
                                'Succès',
                                'Session de caisse démarrée',
                              );
                            } else {
                              Get.snackbar(
                                'Erreur',
                                'Impossible d\'activer la caisse',
                              );
                            }
                          },
                        ),

                      if (controller.isCashRegisterLocked && isAdmin)
                        _CompactButton(
                          label: 'Déverrouiller et activer',
                          icon: Icons.lock_open_rounded,
                          color: const Color(0xFF2563EB),
                          onPressed: _unlockCashRegisterAsAdmin,
                        ),

                      // Boutons fermeture / verrouillage
                      if (controller.isCashRegisterOpen &&
                          authController.canCloseCashRegister)
                        Column(
                          children: [
                            _CompactButton(
                              label: 'Fermer la session de caisse',
                              icon: Icons.lock_rounded,
                              color: const Color(0xFF22C55E),
                              onPressed: () =>
                                  Get.toNamed('/cash-register-closing-report'),
                            ),
                            const SizedBox(height: 10),
                            if (isAdmin)
                              _CompactButton(
                                label: 'Verrouiller Caisse (Admin)',
                                icon: Icons.admin_panel_settings_rounded,
                                color: const Color(0xFFEF4444),
                                onPressed: _confirmLockCashRegisterAsAdmin,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Carte rapport quotidien ──────────────────────────
                _CompactCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.print_rounded,
                          size: 24,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rapport Quotidien',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CompactIconButton(
                        icon: Icons.print_rounded,
                        color: const Color(0xFF7C3AED),
                        onPressed: () => _printDailyReport(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Carte dernière action ────────────────────────────
                _CompactCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Dernière action',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (controller.currentState != null) ...[
                        _CompactInfoRow(
                          icon: Icons.person_rounded,
                          label: 'Ouvert par',
                          value:
                              controller.currentState?.openedByStaffName ??
                              'N/A',
                        ),
                        _CompactInfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Heure d\'ouverture',
                          value:
                              controller.currentState?.openedAt?.toString() ??
                              'N/A',
                        ),
                        _CompactInfoRow(
                          icon: Icons.person_off_rounded,
                          label: 'Fermé par',
                          value:
                              controller.currentState?.closedByStaffName ??
                              'N/A',
                        ),
                        _CompactInfoRow(
                          icon: Icons.timer_off_rounded,
                          label: 'Heure de fermeture',
                          value:
                              controller.currentState?.closedAt?.toString() ??
                              'N/A',
                        ),
                        if (controller.currentState?.isLockedByAdmin == true)
                          _CompactInfoRow(
                            icon: Icons.lock_rounded,
                            label: 'Verrouillé par admin',
                            value: 'Oui',
                            valueColor: const Color(0xFFEF4444),
                          ),
                      ] else
                        Text(
                          'Aucune donnée disponible',
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF).withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLockCashRegisterAsAdmin() => _lockCashRegisterAsAdmin();

  void _lockCashRegisterAsAdmin() {
    Get.defaultDialog(
      title: "Verrouiller la caisse",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      middleText:
          "Êtes-vous sûr de vouloir verrouiller la caisse ? Seul un administrateur pourra la réouvrir.",
      middleTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      confirm: ElevatedButton(
        onPressed: () async {
          final success = await controller.lockCashRegisterAsAdmin();
          if (success) {
            Get.snackbar("Succès", "La caisse a été verrouillée");
            Get.back();
          } else {
            Get.snackbar("Erreur", "Impossible de verrouiller la caisse");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Confirmer"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Annuler",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  void _unlockCashRegisterAsAdmin() {
    Get.defaultDialog(
      title: "Déverrouiller la caisse",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      middleText: "Êtes-vous sûr de vouloir déverrouiller la caisse ?",
      middleTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      confirm: ElevatedButton(
        onPressed: () async {
          final success = await controller.unlockCashRegisterAsAdmin();
          if (success) {
            Get.snackbar("Succès", "La caisse a été déverrouillée");
            Get.back();
          } else {
            Get.snackbar("Erreur", "Impossible de déverrouiller la caisse");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Confirmer"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Annuler",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  void _printDailyReport() async {
    try {
      final authController = Get.find<AuthController>();
      final staffId = authController.currentUser?.id ?? 0;
      final staffName = authController.currentUser?.name ?? 'Inconnu';

      final report = await DailyReportService.generateDailyReport(
        date: DateTime.now(),
        staffId: staffId,
        staffName: staffName,
        openedAt: null,
        closedAt: null,
      );

      final directPrinted = await EscPosPrinterService.instance
          .tryPrintDailyReport(report);
      if (directPrinted) {
        Get.snackbar(
          'Succès',
          'Rapport journalier envoyé directement à l\'imprimante',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
        );
        return;
      }

      final bytes = await buildDailyReportPdf(report);
      try {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
        ).timeout(const Duration(seconds: 6));

        Get.snackbar(
          'Succès',
          'Rapport journalier généré avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
        );
      } catch (e, st) {
        debugPrint('Print failed for daily report: $e\n$st');
        Get.snackbar(
          'Imprimante absente',
          'Le rapport ne peut pas être imprimé. Un aperçu est affiché à la place.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
        await _showDailyReportPreview(bytes);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer le rapport: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showDailyReportPreview(Uint8List bytes) async {
    await Get.to(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('Rapport journalier (aperçu)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                try {
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                } catch (e) {
                  Get.snackbar(
                    'Erreur d\'impression',
                    'Impossible d\'imprimer : $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          ],
        ),
        body: PdfPreview(build: (_) async => bytes, maxPageWidth: 700),
      ),
    );
  }
}

// ── Widgets compacts modernes ────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final Widget child;

  const _CompactCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
