import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/admin_shell.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<User> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadAdmins();
  }

  void _checkPermission() {
    final auth = Get.find<AuthController>();
    if (!(auth.currentUser?.isSuperadmin() ?? false)) {
      Get.snackbar(
        'Accès refusé',
        'Seul le superadministrateur peut accéder à cette page',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Future.microtask(() => Get.back());
    }
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final allUsers = await DatabaseService.getAllUsers();
      final admins = allUsers.where((u) => u.role == 'admin').toList();
      if (!mounted) return;
      setState(() {
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger les admins: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Gestion des Admins',
      activeRoute: '/admin-management',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateAdmin(),
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.admin_panel_settings),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(),
    );
  }

  Widget _buildList() {
    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: AppColors.grisModerne,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun administrateur',
              style: TextStyle(fontSize: 18, color: AppColors.grisModerne),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur + pour ajouter un admin',
              style: TextStyle(fontSize: 14, color: AppColors.grisModerne),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _admins.length,
      itemBuilder: (context, index) {
        final admin = _admins[index];
        return _AdminCard(admin: admin, onRefresh: _loadAdmins);
      },
    );
  }

  void _navigateToCreateAdmin() {
    Get.toNamed('/create-admin')?.then((_) => _loadAdmins());
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.admin, required this.onRefresh});

  final User admin;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final initial = admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?';
    final statusColor = admin.isActive ? Colors.green : Colors.red;
    final statusLabel = admin.isActive ? 'Actif' : 'Inactif';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A9988).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF1A9988),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grisModerne,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tél: ${admin.phone.isEmpty ? '—' : admin.phone}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grisModerne,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  icon: Icons.pin_outlined,
                  label: admin.pinCode?.isNotEmpty == true
                      ? 'PIN: ${_maskPin(admin.pinCode!)}'
                      : 'PIN: —',
                ),
                if (admin.restaurantId != null)
                  _Chip(
                    icon: Icons.store,
                    label: 'Restaurant #${admin.restaurantId}',
                  ),
                _Chip(icon: Icons.fingerprint, label: 'ID: ${admin.id}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPinDialog(context),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir PIN'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEdit(context),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _toggleActivation(),
                  icon: Icon(
                    admin.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: admin.isActive ? Colors.green : Colors.grey,
                  ),
                  tooltip: admin.isActive ? 'Désactiver' : 'Activer',
                ),
                IconButton(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _maskPin(String pin) {
    if (pin.length <= 2) return '**';
    return '${pin.substring(0, 2)}${'*' * (pin.length - 2)}';
  }

  void _showPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pin_outlined, color: Color(0xFF1A9988)),
            SizedBox(width: 8),
            Text('Code PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Admin: ${admin.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A9988).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                admin.pinCode?.isNotEmpty == true ? admin.pinCode! : '—',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: Color(0xFF1A9988),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Get.toNamed('/edit-admin', arguments: admin)?.then((_) => onRefresh());
  }

  void _toggleActivation() async {
    try {
      final userController = Get.find<UserController>();
      await userController.toggleUserActivation(admin.id);
      onRefresh();
      Get.snackbar(
        'Succès',
        'Statut admin mis à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'admin'),
        content: Text('Voulez-vous vraiment supprimer ${admin.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final userController = Get.find<UserController>();
                await userController.deleteUser(admin.id);
                onRefresh();
                Get.snackbar(
                  'Succès',
                  'Admin supprimé',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Erreur',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

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
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
