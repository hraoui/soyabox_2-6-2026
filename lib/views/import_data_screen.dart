import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';
import '../widgets/sushi_cta_button.dart';

class ImportDataScreen extends StatelessWidget {
  const ImportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final importController = Get.find<ImportController>();

    return AdminShell(
      title: 'Importer',
      activeRoute: '/import-data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Synchroniser les données', style: SushiTypo.h1),
            const SizedBox(height: SushiSpace.sm),
            Text(
              'Importez vos restaurants, produits, catégories, utilisateurs, tables et livreurs en une seule action.',
              style: SushiTypo.bodyMd,
            ),
            const SizedBox(height: SushiSpace.lg),
            AppSurfaceCard(
              padding: const EdgeInsets.all(SushiSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progression', style: SushiTypo.h2),
                      Obx(
                        () => Text(
                          '${(importController.importProgress * 100).round()}%',
                          style: SushiTypo.caption.copyWith(
                            color: SushiColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SushiSpace.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SushiRadius.lg),
                    child: Obx(
                      () => LinearProgressIndicator(
                        value: importController.importProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: SushiColors.surface,
                        color: SushiColors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: SushiSpace.sm),
                  Obx(
                    () => AnimatedOpacity(
                      opacity: importController.importStatus.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        importController.importStatus.isEmpty
                            ? 'Prêt à importer'
                            : importController.importStatus,
                        style: SushiTypo.bodySm,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SushiSpace.md),
            AppSurfaceCard(
              padding: const EdgeInsets.all(SushiSpace.xl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;
                  final columns = isCompact ? 2 : 3;
                  final itemWidth =
                      (constraints.maxWidth - SushiSpace.sm * (columns - 1)) /
                      columns;

                  final buttons = [
                    _actionButton(
                      label: 'Importer tout',
                      primary: true,
                      importController: importController,
                      onTap: () => importController.importAllData(),
                    ),
                    _actionButton(
                      label: 'Restaurants',
                      importController: importController,
                      onTap: () => importController.importRestaurants(),
                    ),
                    _actionButton(
                      label: 'Catégories',
                      importController: importController,
                      onTap: () => importController.importCategories(),
                    ),
                    _actionButton(
                      label: 'Produits',
                      importController: importController,
                      onTap: () => importController.importProducts(),
                    ),
                    _actionButton(
                      label: 'Utilisateurs',
                      importController: importController,
                      onTap: () => importController.importUsers(),
                    ),
                    _actionButton(
                      label: 'Tables',
                      importController: importController,
                      onTap: () => importController.importTables(),
                    ),
                    _actionButton(
                      label: 'Livreurs',
                      importController: importController,
                      onTap: () => importController.importDeliveries(),
                    ),
                  ];

                  return Wrap(
                    spacing: SushiSpace.md,
                    runSpacing: SushiSpace.md,
                    children: buttons
                        .map((btn) => SizedBox(width: itemWidth, child: btn))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required ImportController importController,
    required Future<void> Function() onTap,
    bool primary = false,
  }) {
    return Obx(() {
      final isBusy = importController.isImporting;
      return SizedBox(
        height: 50,
        child: primary
            ? SushiCTAButton(
                child: Text(isBusy ? 'Import en cours...' : label),
                onPressed: () async {
                  if (isBusy) return;
                  try {
                    await onTap();
                  } catch (e) {
                    ScaffoldMessenger.of(Get.context!).showSnackBar(
                      SnackBar(
                        backgroundColor: SushiColors.inkSoft,
                        content: Text(
                          'Échec : $e',
                          style: SushiTypo.bodySm.copyWith(
                            color: SushiColors.white,
                          ),
                        ),
                      ),
                    );
                  }
                },
              )
            : OutlinedButton(
                style: SushiButtonStyle.secondary(),
                onPressed: isBusy
                    ? null
                    : () async {
                        try {
                          await onTap();
                        } catch (e) {
                          ScaffoldMessenger.of(Get.context!).showSnackBar(
                            SnackBar(
                              backgroundColor: SushiColors.inkSoft,
                              content: Text(
                                'Échec : $e',
                                style: SushiTypo.bodySm.copyWith(
                                  color: SushiColors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                child: Text(label, style: TextStyle(color: Colors.redAccent)),
              ),
      );
    });
  }
}
