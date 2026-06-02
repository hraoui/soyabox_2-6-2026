import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/delivery_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/delivery.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';

class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch deliveries after the frame is built to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restId = Get.find<AuthController>().currentUser?.restaurantId;
      Get.find<DeliveryController>().fetchDeliveriesByRestaurant(restId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryController = Get.find<DeliveryController>();

    return AdminShell(
      title: 'Livreurs',
      activeRoute: '/deliveries',
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sync button
          FloatingActionButton.small(
            heroTag: 'syncDeliveries',
            backgroundColor: AppColors.bleuGris,
            tooltip: 'Sync local vers backend',
            onPressed: () async {
              await deliveryController.syncLocalDeliveriesToBackend();
              // Refresh the list after sync
              final restId =
                  Get.find<AuthController>().currentUser?.restaurantId;
              await deliveryController.fetchDeliveriesByRestaurant(restId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Synchronisation terminée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Icon(Icons.sync),
          ),
          const SizedBox(height: 8),
          // Create button
          FloatingActionButton(
            heroTag: 'createDelivery',
            onPressed: () => Get.toNamed('/create-delivery'),
            backgroundColor: AppColors.terraCotta,
            child: const Icon(Icons.local_shipping),
          ),
        ],
      ),
      child: Obx(() {
        if (deliveryController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (deliveryController.deliveries.isEmpty) {
          return const Center(
            child: Text('Aucun livreur', style: TextStyle(fontSize: 18)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppWrapGrid.builder(
            itemCount: deliveryController.deliveries.length,
            minChildWidth: 320,
            maxChildWidth: 420,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            itemBuilder: (context, index) {
              final delivery = deliveryController.deliveries[index];
              return _DeliveryCard(
                delivery: delivery,
                deliveryController: deliveryController,
              );
            },
          ),
        );
      }),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.delivery,
    required this.deliveryController,
  });

  final Delivery delivery;
  final DeliveryController deliveryController;

  @override
  Widget build(BuildContext context) {
    final initial = delivery.name.isNotEmpty
        ? delivery.name[0].toUpperCase()
        : '?';
    final statusColor = delivery.isActive ? Colors.green : Colors.red;
    final statusLabel = delivery.isActive ? 'Actif' : 'Inactif';

    return AppSurfaceCard(
      onTap: () => Get.toNamed('/edit-delivery', arguments: delivery),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grisPale,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.email.trim().isEmpty
                          ? 'Sans email'
                          : delivery.email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(icon: Icons.local_shipping_outlined, label: 'Livreur'),
              _InfoChip(
                icon: Icons.phone_outlined,
                label: delivery.phone.trim().isEmpty
                    ? 'Sans telephone'
                    : delivery.phone,
              ),
              _InfoChip(icon: Icons.fingerprint, label: 'ID ${delivery.id}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.toNamed('/delivery-detail', arguments: delivery);
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Voir'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await deliveryController.toggleDeliveryActivation(
                        delivery.id,
                      );
                      if (context.mounted) {
                        Get.snackbar(
                          'Succès',
                          'Statut livreur mis à jour',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Get.snackbar(
                          'Erreur',
                          e.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                  icon: Icon(
                    delivery.isActive ? Icons.toggle_on : Icons.toggle_off,
                  ),
                  label: const Text('Statut'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) {
                  if (value == 'edit') {
                    Get.toNamed('/edit-delivery', arguments: delivery);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, delivery);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Delivery delivery) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GlassColors.glassWhite.withAlpha(228),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text('Supprimer livreur'),
          content: Text(
            'Voulez-vous vraiment supprimer ${delivery.name} ?',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassColors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await deliveryController.deleteDelivery(delivery.id);
                  if (context.mounted) {
                    Get.snackbar(
                      'Succès',
                      'Livreur supprimé avec succès',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grisPale,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grisModerne),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
