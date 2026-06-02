import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/app_back_button.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tableau de bord serveur'),
        backgroundColor: AppColors.blancPur,
        foregroundColor: AppColors.charbon,
        elevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthController.instance.logout();
              Get.offAllNamed('/login');
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Déconnexion'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: AppWrapGrid(
            minChildWidth: 320,
            maxChildWidth: 420,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            maxColumns: 2,
            children: [
              _tile(
                icon: Icons.point_of_sale,
                title: 'Nouvelle Commande',
                description:
                    'Demarrer une prise de commande sur place, emporter ou livraison.',
                footerLabel: 'Encaissement',
                onTap: () => Get.toNamed('/pos'),
              ),
              _tile(
                icon: Icons.receipt_long,
                title: 'Mes Commandes',
                description:
                    'Retrouver les commandes du jour et suivre leur progression.',
                footerLabel: 'Suivi',
                onTap: () => Get.toNamed('/pos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String description,
    required String footerLabel,
    required VoidCallback onTap,
  }) {
    return AppFeatureCard(
      icon: icon,
      title: title,
      description: description,
      footerLabel: footerLabel,
      accent: GlassColors.redAccent,
      centered: true,
      onTap: onTap,
    );
  }
}
