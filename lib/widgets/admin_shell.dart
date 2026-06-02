import 'dart:io';

import 'package:caisse_1/data/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/sync_controller.dart';
import '../theme/sushi_design.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.activeRoute,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final String? activeRoute;
  final Widget? floatingActionButton;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantController = Get.find<RestaurantController>();
      final restaurants = restaurantController.getActiveRestaurants();
      if (restaurantController.selectedRestaurantId == null &&
          restaurants.isNotEmpty) {
        restaurantController.setSelectedRestaurantId(restaurants.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: SushiColors.bg,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Row(
          children: [
            _sidebar(context, canPop),
            Expanded(
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(SushiSpace.lg),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER : contient uniquement le bouton de synchronisation
  Widget _header() {
    final syncController = Get.find<SyncController>();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: SushiSpace.lg),
      decoration: BoxDecoration(
        color: SushiColors.white,
        border: const Border(
          bottom: BorderSide(color: SushiColors.divider, width: 1),
        ),
        boxShadow: SushiShadow.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncController.canManualSync)
            Obx(
              () => OutlinedButton.icon(
                onPressed: syncController.isSyncing
                    ? null
                    : () async => syncController.manualSync(),
                icon: Icon(
                  syncController.isOnline
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  size: 16,
                  color: SushiColors.ink,
                ),
                label: Text(
                  syncController.isSyncing ? 'Sync...' : 'Synchroniser',
                  style: SushiTypo.bodySm,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                style: SushiButtonStyle.secondary(),
              ),
            ),
        ],
      ),
    );
  }

  // SIDEBAR : layout vertical simple et fiable
  Widget _sidebar(BuildContext context, bool canPop) {
    final auth = Get.find<AuthController>();
    final isSuperadmin = auth.currentUser?.isSuperadmin() ?? false;
    final width = _collapsed ? 80.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: SushiColors.white,
        border: const Border(
          right: BorderSide(color: SushiColors.divider, width: 1),
        ),
        boxShadow: SushiShadow.card,
      ),
      child: Column(
        children: [
          // Barre supérieure
          SizedBox(
            height: 56,
            child: Row(
              children: [
                if (canPop)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (!_collapsed) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        widget.title,
                        style: SushiTypo.h3,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                GetBuilder<SettingsController>(
                  builder: (settingsCtrl) {
                    final logoPath = settingsCtrl.settings.appLogoPath;
                    if (logoPath != null &&
                        logoPath.trim().isNotEmpty &&
                        File(logoPath).existsSync()) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(logoPath),
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Icon(
                      Icons.point_of_sale,
                      size: 20,
                      color: SushiColors.red,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _collapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: SushiSpace.sm),

          // Sélecteur de restaurant
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GetBuilder<RestaurantController>(
              builder: (controller) {
                final restaurants = controller.getActiveRestaurants();
                if (restaurants.isEmpty) {
                  return _collapsed
                      ? const SizedBox.shrink()
                      : const Text(
                          'Aucun restaurant',
                          style: SushiTypo.caption,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                }
                final userRestId =
                    auth.currentUser?.restaurantId ?? restaurants.first.id;
                final restaurant = restaurants.firstWhere(
                  (r) => r.id == userRestId,
                  orElse: () => restaurants.first,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SushiColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SushiColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_mall_directory, size: 16, color: SushiColors.ink),
                      if (!_collapsed) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            restaurant.name,
                            style: SushiTypo.bodySm,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: SushiSpace.sm),

          // Navigation (occupe tout l'espace restant)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _navItem(Icons.dashboard_outlined, 'Tableau de bord', '/admin-dashboard'),
                _navItem(Icons.store_outlined, 'Restaurants', '/restaurants'),
                _navItem(Icons.receipt_long, 'Rapports', '/daily-reports'),
                // _navItem(Icons.bar_chart, 'Comptabilité', '/admin-accounting'), // ✅ Supprimé
                _navItem(Icons.people, 'Utilisateurs', '/users'),
                if (isSuperadmin)
                  _navItem(Icons.admin_panel_settings_outlined, 'Gestion Admins', '/admin-management'),
                _navItem(Icons.account_balance_wallet_outlined, 'Dashboard Financier', '/financial-dashboard'),
                if (!_collapsed)
                  _navItem(Icons.local_shipping_outlined, 'Livreurs', '/deliveries'),
                _navItem(Icons.receipt_long, 'Commandes', '/admin-orders'),
                _navItem(Icons.analytics_outlined, 'Commandes Globales', '/global-orders'), // ✅ Nouvelle entrée
                _navItem(Icons.description, 'Rapports Journaliers', '/daily-reports'),
                _navItem(Icons.inventory_2_outlined, 'Catalogue', '/catalog'),
                _navItem(Icons.sync, 'Importer', '/import-data'),
                _navItem(Icons.settings, 'Settings', '/settings'),
              ],
            ),
          ),

          // Bloc bas : Info utilisateur + Déconnexion (empilés verticalement)
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: SushiSpace.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info utilisateur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SushiColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SushiColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: SushiColors.ink),
                      if (!_collapsed) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            auth.currentUser?.name ?? 'Admin',
                            style: SushiTypo.bodySm,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton Déconnexion
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      Get.offAllNamed('/login');
                    },
                    icon: const Icon(Icons.logout, size: 16, color: SushiColors.red),
                    label: _collapsed
                        ? const SizedBox.shrink()
                        : const Text('Déconnexion', style: SushiTypo.bodySm),
                    style: ButtonStyle(
                      foregroundColor: const WidgetStatePropertyAll(SushiColors.redDark),
                      padding: WidgetStatePropertyAll(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      minimumSize: WidgetStatePropertyAll(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String route) {
    final isActive = widget.activeRoute == route || Get.currentRoute == route;
    return InkWell(
      onTap: () {
        if (Get.currentRoute != route) Get.toNamed(route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? SushiColors.redPale : SushiColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? SushiColors.red : SushiColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? SushiColors.red : SushiColors.inkMid),
            if (!_collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: SushiTypo.bodySm.copyWith(
                    color: isActive ? SushiColors.red : SushiColors.inkMid,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}