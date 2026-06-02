import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../widgets/admin_shell.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.arguments as User?;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non trouvé')),
      );
    }

    final userController = Get.find<UserController>();

    return AdminShell(
      title: 'Détails de l\'utilisateur',
      activeRoute: '/users',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                // Header Card
                _headerCard(user),
                const SizedBox(height: SushiSpace.md),

                // Info Card
                _infoCard(user),
                const SizedBox(height: SushiSpace.md),

                // Actions
                _actionButtons(context, user, userController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(User user) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.role == 'livreur'
                ? Colors.blue
                : AppColors.burntOrange,
            radius: 30,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                Text(user.name, style: SushiTypo.h2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      user.role == 'livreur'
                          ? Icons.local_shipping
                          : Icons.restaurant,
                      size: 14,
                      color: AppColors.grisModerne,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.role == 'livreur' ? 'Livreur' : 'Serveur',
                      style: SushiTypo.bodySm.copyWith(
                        color: AppColors.grisModerne,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _statusBadge(user.isActive),
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

  Widget _infoCard(User user) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Informations', style: SushiTypo.h3),
          const SizedBox(height: SushiSpace.md),
          _infoRow(Icons.phone, 'Téléphone', user.phone),
          const Divider(height: 20),
          _infoRow(Icons.email, 'Email', user.email),
          if (user.pinCode != null && user.pinCode!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(Icons.lock, 'Code PIN', user.pinCode!, isSensitive: true),
          ],
          if (user.badgeCode != null && user.badgeCode!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              Icons.badge_outlined,
              'Badge POS',
              user.badgeCode!,
              isSensitive: true,
              sensitiveLabel: 'Badge',
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
    String? sensitiveLabel,
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
                sensitiveLabel ?? label,
                '$label: $value',
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
    User user,
    UserController controller,
  ) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/edit-user', arguments: user),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Modifier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: SushiSpace.sm),
          if (user.role != 'superadmin')
            OutlinedButton.icon(
              onPressed: () => _showDeleteConfirm(context, user, controller),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    User user,
    UserController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.name} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              Get.snackbar(
                'ℹ️ Info',
                'Suppression non implémentée pour les utilisateurs',
                snackPosition: SnackPosition.BOTTOM,
              );
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
