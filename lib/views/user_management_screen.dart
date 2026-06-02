import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../models/user.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return AdminShell(
      title: 'Utilisateurs',
      activeRoute: '/users',
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/create-user'),
        backgroundColor: AppColors.terraCotta,
        child: const Icon(Icons.add),
      ),
      child: Obx(() {
        if (userController.users.isEmpty) {
          return const Center(
            child: Text('Aucun utilisateur', style: TextStyle(fontSize: 18)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppWrapGrid.builder(
            itemCount: userController.users.length,
            minChildWidth: 320,
            maxChildWidth: 420,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            itemBuilder: (context, index) {
              final user = userController.users[index];
              return _UserCard(user: user, userController: userController);
            },
          ),
        );
      }),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.userController});

  final User user;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final statusColor = user.isActive ? Colors.green : Colors.red;
    final statusLabel = user.isActive ? 'Actif' : 'Inactif';

    return AppSurfaceCard(
      onTap: () => Get.toNamed('/edit-user', arguments: user),
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
                      user.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.trim().isEmpty ? 'Sans email' : user.email,
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
              _InfoChip(
                icon: Icons.badge_outlined,
                label: 'Role ${user.role.toUpperCase()}',
              ),
              _InfoChip(
                icon: Icons.phone_outlined,
                label: user.phone.trim().isEmpty
                    ? 'Sans telephone'
                    : user.phone,
              ),
              _InfoChip(icon: Icons.fingerprint, label: 'ID ${user.id}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.toNamed('/user-detail', arguments: user);
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
                      await userController.toggleUserActivation(user.id);
                      if (context.mounted) {
                        Get.snackbar(
                          'Succès',
                          'Statut utilisateur mis à jour',
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
                    user.isActive ? Icons.toggle_on : Icons.toggle_off,
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
                    Get.toNamed('/edit-user', arguments: user);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, user);
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

  void _showDeleteDialog(BuildContext context, User user) {
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
          title: const Text('Supprimer utilisateur'),
          content: Text(
            'Voulez-vous vraiment supprimer ${user.name} ?',
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
                  await userController.deleteUser(user.id);
                  if (context.mounted) {
                    Get.snackbar(
                      'Succès',
                      'Utilisateur supprimé avec succès',
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
