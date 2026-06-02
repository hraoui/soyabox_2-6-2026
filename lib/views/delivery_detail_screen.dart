import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/delivery_controller.dart';
import '../models/delivery.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../widgets/admin_shell.dart';

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final delivery = Get.arguments as Delivery?;

    if (delivery == null) {
      return const Scaffold(body: Center(child: Text('Livreur non trouvé')));
    }

    final deliveryController = Get.find<DeliveryController>();

    return AdminShell(
      title: 'Détails du livreur',
      activeRoute: '/deliveries',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                // Header Card
                _headerCard(delivery),
                const SizedBox(height: SushiSpace.md),

                // Info Card
                _infoCard(delivery),
                const SizedBox(height: SushiSpace.md),

                // Actions
                _actionButtons(context, delivery, deliveryController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(Delivery delivery) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.burntOrange,
            radius: 30,
            child: Text(
              delivery.name.isNotEmpty ? delivery.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: SushiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery.name, style: SushiTypo.h2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 14,
                      color: AppColors.grisModerne,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Livreur',
                      style: SushiTypo.bodySm.copyWith(
                        color: AppColors.grisModerne,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _statusBadge(delivery.isActive),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Delivery delivery) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Informations', style: SushiTypo.h3),
          const SizedBox(height: SushiSpace.md),
          _infoRow(Icons.phone, 'Téléphone', delivery.phone),
          const Divider(height: 20),
          _infoRow(Icons.email, 'Email', delivery.email),
          const Divider(height: 20),
          if (delivery.pinCode != null && delivery.pinCode!.isNotEmpty) ...[
            _infoRow(
              Icons.lock,
              'Code PIN',
              delivery.pinCode!,
              isSensitive: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isSensitive = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.grisPale,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppColors.deepTeal),
        ),
        const SizedBox(width: SushiSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SushiTypo.caption.copyWith(color: AppColors.grisModerne),
              ),
              const SizedBox(height: 2),
              Text(isSensitive ? '••••' : value, style: SushiTypo.bodyMd),
            ],
          ),
        ),
        if (isSensitive)
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            onPressed: () {
              Get.snackbar(
                'PIN',
                'Code PIN: $value',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _actionButtons(
    BuildContext context,
    Delivery delivery,
    DeliveryController controller,
  ) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/edit-delivery', arguments: delivery),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Modifier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: SushiSpace.sm),
          OutlinedButton.icon(
            onPressed: () => _showDeleteConfirm(context, delivery, controller),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    Delivery delivery,
    DeliveryController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le livreur ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${delivery.name} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await controller.deleteDelivery(delivery.id);
              if (success && context.mounted) {
                Get.back();
                Get.snackbar(
                  '✅ Succès',
                  'Livreur supprimé avec succès',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
