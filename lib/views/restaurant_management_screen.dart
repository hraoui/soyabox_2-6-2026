import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';

// Pantone Sushi Food Colors
class SushiColors {
  static const Color primaryGreen = Color(0xFF2D5016);
  static const Color accentGreen = Color(0xFF5FA834);
  static const Color coral = Color(0xFFE8886F);
  static const Color gingerOrange = Color(0xFFC1673D);
  static const Color cream = Color(0xFFFBF8F3);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightBorder = Color(0xFFE5DDD0);
}

class RestaurantManagementScreen extends StatelessWidget {
  const RestaurantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantController = Get.find<RestaurantController>();

    return AdminShell(
      title: 'Restaurants',
      activeRoute: '/restaurants',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, restaurantController),
        backgroundColor: SushiColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: Obx(
        () => restaurantController.restaurants.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 64,
                      color: SushiColors.accentGreen.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun restaurant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppWrapGrid.builder(
                      itemCount: restaurantController.restaurants.length,
                      minChildWidth: 320,
                      maxChildWidth: 380,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      itemBuilder: (context, index) {
                        final restaurant =
                            restaurantController.restaurants[index];
                        return _buildRestaurantCard(
                          context,
                          restaurant,
                          restaurantController,
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    dynamic restaurant,
    RestaurantController controller,
  ) {
    return AppSurfaceCard(
      onTap: () => _showEditDialog(context, controller, restaurant),
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, SushiColors.cream],
      ),
      borderColor: SushiColors.lightBorder,
      shadow: [
        BoxShadow(
          color: SushiColors.primaryGreen.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SushiColors.accentGreen, SushiColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SushiColors.accentGreen.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  restaurant.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: SushiColors.darkText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (restaurant.isActive
                                    ? SushiColors.accentGreen
                                    : SushiColors.coral)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        restaurant.isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: restaurant.isActive
                              ? SushiColors.accentGreen
                              : SushiColors.coral,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      restaurant.isActive ? Icons.check_circle : Icons.cancel,
                      color: restaurant.isActive
                          ? SushiColors.accentGreen
                          : SushiColors.coral,
                      size: 26,
                    ),
                    onPressed: () async {
                      try {
                        await controller.toggleRestaurantActivation(
                          restaurant.id,
                        );
                        if (context.mounted) {
                          Get.snackbar(
                            'Succès',
                            'Statut mis à jour',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: SushiColors.accentGreen,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Get.snackbar(
                            'Erreur',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: SushiColors.coral,
                            colorText: Colors.white,
                          );
                        }
                      }
                    },
                  ),
                  _buildPopupMenu(context, controller, restaurant),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _restaurantMetaRow(
            icon: Icons.phone_outlined,
            color: SushiColors.coral.withValues(alpha: 0.8),
            text: restaurant.phone,
          ),
          const SizedBox(height: 8),
          _restaurantMetaRow(
            icon: Icons.location_on_outlined,
            color: SushiColors.gingerOrange.withValues(alpha: 0.8),
            text: restaurant.address,
          ),
        ],
      ),
    );
  }

  Widget _restaurantMetaRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: SushiColors.darkText.withValues(alpha: 0.76),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        if (value == 'edit') {
          _showEditDialog(context, controller, restaurant);
        } else if (value == 'delete') {
          _showDeleteDialog(context, controller, restaurant);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: SushiColors.accentGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: SushiColors.coral, size: 18),
              const SizedBox(width: 8),
              const Text('Supprimer'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    RestaurantController controller,
  ) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SushiColors.accentGreen, SushiColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nouveau restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'Nom du restaurant',
                  icon: Icons.restaurant_menu_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: addressController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || address.isEmpty || phone.isEmpty) {
                  Get.snackbar(
                    'Erreur',
                    'Tous les champs sont obligatoires',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: SushiColors.coral,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  await controller.createRestaurant(
                    name: name,
                    address: address,
                    phone: phone,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) async {
    final nameController = TextEditingController(text: restaurant.name);
    final addressController = TextEditingController(text: restaurant.address);
    final phoneController = TextEditingController(text: restaurant.phone);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SushiColors.accentGreen, SushiColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Modifier restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'Nom du restaurant',
                  icon: Icons.restaurant_menu_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: addressController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || address.isEmpty || phone.isEmpty) {
                  Get.snackbar(
                    'Erreur',
                    'Tous les champs sont obligatoires',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: SushiColors.coral,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  await controller.updateRestaurant(
                    restaurantId: restaurant.id,
                    name: name,
                    address: address,
                    phone: phone,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SushiColors.coral.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: SushiColors.coral,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Supprimer restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${restaurant.name} ?',
            style: const TextStyle(color: SushiColors.darkText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await controller.deleteRestaurant(restaurant.id);
                  if (context.mounted) {
                    Get.snackbar(
                      'Succès',
                      'Restaurant supprimé',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.accentGreen,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SushiColors.darkText),
        prefixIcon: Icon(icon, color: SushiColors.accentGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SushiColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SushiColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: SushiColors.primaryGreen,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: SushiColors.darkText),
    );
  }
}
