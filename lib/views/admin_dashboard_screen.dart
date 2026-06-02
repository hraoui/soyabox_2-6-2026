// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/sync_controller.dart'; // ✅ Pour Daily Sync
import '../controllers/cash_register_controller.dart'; // Added for cash register functionality
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';
import '../widgets/daily_sync_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final Future<_DashboardStats> _statsFuture = _loadStats();

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final cashRegisterController = Get.find<CashRegisterController>();

    return AdminShell(
      title: 'Tableau de bord admin',
      activeRoute: '/admin-dashboard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // 📊 Fixed 4 columns for stat cards
          final statColumns = 4;
          final statSpacing = SushiSpace.md;
          final statItemWidth =
              (width - (statSpacing * (statColumns - 1))) / statColumns;
          final paymentStatWidth = (width - (statSpacing * 2)) / 3;

          // 🎯 Fixed 4 columns for feature tiles
          final tileSpacing = SushiSpace.md;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: SushiSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cash Register Status Section for Admin
                if (authController.canOpenCashRegister ||
                    authController.canCloseCashRegister) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion de caisse',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Obx(() {
                              final isOpen =
                                  cashRegisterController.isCashRegisterOpen;
                              final isLocked =
                                  cashRegisterController.isCashRegisterLocked;
                              final lastAction =
                                  cashRegisterController
                                          .currentState
                                          ?.closedByStaffName !=
                                      null
                                  ? 'Fermée par ${cashRegisterController.currentState?.closedByStaffName}'
                                  : (cashRegisterController
                                                .currentState
                                                ?.openedByStaffName !=
                                            null
                                        ? 'Ouverte par ${cashRegisterController.currentState?.openedByStaffName}'
                                        : 'Aucune action enregistrée');

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isOpen
                                                ? 'Caisse: Ouverte'
                                                : (isLocked
                                                      ? 'Caisse: Bloquée'
                                                      : 'Caisse: Fermée'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isOpen
                                                  ? Colors.green
                                                  : (isLocked
                                                        ? Colors.red
                                                        : Colors.orange),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dernière action: $lastAction',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => Get.toNamed(
                                          '/cash-register-status',
                                        ),
                                        icon: const Icon(
                                          Icons.account_balance_wallet,
                                        ),
                                        label: const Text('Gérer la caisse'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isOpen || isLocked) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          if (!isOpen && !isLocked)
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final staffId =
                                                    authController
                                                        .currentUser
                                                        ?.id ??
                                                    0;
                                                final staffName =
                                                    authController
                                                        .currentUser
                                                        ?.name ??
                                                    'Inconnu';
                                                final success =
                                                    await cashRegisterController
                                                        .openCashRegister(
                                                          staffId: staffId,
                                                          staffName: staffName,
                                                        );
                                                if (success) {
                                                  Get.snackbar(
                                                    'Succès',
                                                    'Caisse activée',
                                                  );
                                                } else {
                                                  Get.snackbar(
                                                    'Erreur',
                                                    'Impossible d\'activer la caisse',
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.play_circle_fill_rounded,
                                              ),
                                              label: const Text(
                                                'Activer la caisse',
                                              ),
                                            ),
                                          if (isLocked)
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final success =
                                                    await cashRegisterController
                                                        .unlockCashRegisterAsAdmin();
                                                if (success) {
                                                  Get.snackbar(
                                                    'Succès',
                                                    'Caisse déverrouillée et activée',
                                                  );
                                                } else {
                                                  Get.snackbar(
                                                    'Erreur',
                                                    'Impossible de déverrouiller la caisse',
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.lock_open_rounded,
                                              ),
                                              label: const Text(
                                                'Déverrouiller la caisse',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // 📊 Stats Row - 4 cards
                FutureBuilder<_DashboardStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final loading = !snapshot.hasData;
                    final stats = snapshot.data;
                    return Wrap(
                      spacing: statSpacing,
                      runSpacing: statSpacing,
                      children: [
                        SizedBox(
                          width: statItemWidth,
                          child: _compactStatCard(
                            label: 'Tables',
                            value: loading ? '…' : '${stats!.tableOrders}',
                            accent: SushiColors.red,
                            icon: Icons.table_restaurant_outlined,
                          ),
                        ),
                        SizedBox(
                          width: statItemWidth,
                          child: _compactStatCard(
                            label: 'Web/Mobile',
                            value: loading ? '…' : '${stats!.remoteOrders}',
                            accent: SushiColors.teal,
                            icon: Icons.phone_iphone_outlined,
                          ),
                        ),
                        SizedBox(
                          width: statItemWidth,
                          child: _compactStatCard(
                            label: 'CA Serveurs',
                            value: loading ? '…' : _money(stats!.totalCA),
                            accent: SushiColors.green,
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        SizedBox(
                          width: statItemWidth,
                          child: _compactStatCard(
                            label: 'Total CMD',
                            value: loading
                                ? '…'
                                : '${stats!.tableOrders + stats.remoteOrders}',
                            accent: SushiColors.orange,
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: SushiSpace.lg),
                // 💳 Payment Stats Row - 3 cards (TPE / Cash / En compte)
                FutureBuilder<_DashboardStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final loading = !snapshot.hasData;
                    final stats = snapshot.data;
                    return Wrap(
                      spacing: statSpacing,
                      runSpacing: statSpacing,
                      children: [
                        SizedBox(
                          width: paymentStatWidth,
                          child: _compactStatCard(
                            label: 'Paiements TPE',
                            value: loading ? '…' : _money(stats!.tpeTotal),
                            accent: const Color(0xFF2196F3), // Blue
                            icon: Icons.credit_card,
                            subtitle: loading
                                ? ''
                                : (stats!.tpeTotal > 0 && stats.totalCA > 0
                                      ? '${((stats.tpeTotal / stats.totalCA) * 100).toStringAsFixed(1)}% du CA'
                                      : 'Aucun paiement'),
                          ),
                        ),
                        SizedBox(
                          width: paymentStatWidth,
                          child: _compactStatCard(
                            label: 'Paiements Espèces',
                            value: loading ? '…' : _money(stats!.cashTotal),
                            accent: const Color(0xFFFF9800), // Orange
                            icon: Icons.money,
                            subtitle: loading
                                ? ''
                                : (stats!.cashTotal > 0 && stats.totalCA > 0
                                      ? '${((stats.cashTotal / stats.totalCA) * 100).toStringAsFixed(1)}% du CA'
                                      : 'Aucun paiement'),
                          ),
                        ),
                        SizedBox(
                          width: paymentStatWidth,
                          child: _compactStatCard(
                            label: 'Paiements En Compte',
                            value: loading ? '…' : _money(stats!.enCompteTotal),
                            accent: const Color(0xFFFF7043),
                            icon: Icons.account_balance_wallet_outlined,
                            subtitle: loading
                                ? ''
                                : (stats!.enCompteTotal > 0 && stats.totalCA > 0
                                      ? '${((stats.enCompteTotal / stats.totalCA) * 100).toStringAsFixed(1)}% du CA'
                                      : 'Aucun paiement'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: SushiSpace.xl),
                // 🎯 Feature Grid - 4 columns
                Wrap(
                  spacing: tileSpacing,
                  runSpacing: tileSpacing,
                  children: [
                    _compactTile(
                      icon: Icons.people,
                      title: 'Utilisateurs',
                      subtitle: 'Équipe',
                      onTap: () => Get.toNamed('/users'),
                    ),
                    _compactTile(
                      icon: Icons.store,
                      title: 'Restaurants',
                      subtitle: 'Structure',
                      onTap: () => Get.toNamed('/restaurants'),
                    ),
                    _compactTile(
                      icon: Icons.category,
                      title: 'Catégories',
                      subtitle: 'Familles',
                      onTap: () => Get.toNamed('/catalog'),
                    ),
                    _compactTile(
                      icon: Icons.inventory,
                      title: 'Produits',
                      subtitle: 'Catalogue',
                      onTap: () => Get.toNamed('/catalog'),
                    ),
                    // ✅ Tables supprimées - Gestion disponible uniquement dans POS
                    // _compactTile(
                    //   icon: Icons.table_bar,
                    //   title: 'Tables',
                    //   subtitle: 'Salle',
                    //   onTap: () => Get.toNamed('/tables'),
                    // ),
                    _compactTile(
                      icon: Icons.local_shipping,
                      title: 'Livreurs',
                      subtitle: 'Livraison',
                      onTap: () => Get.toNamed('/deliveries'),
                    ),
                    _compactTile(
                      icon: Icons.bar_chart,
                      title: 'Compta',
                      subtitle: 'Analyse',
                      onTap: () => Get.toNamed('/admin-accounting'),
                    ),
                    _compactTile(
                      icon: Icons.attach_money_rounded,
                      title: 'Dashboard Financier',
                      subtitle: 'Analytics',
                      onTap: () => Get.toNamed('/financial-dashboard'),
                    ),
                    _compactTile(
                      icon: Icons.receipt_long,
                      title: 'Commandes',
                      subtitle: 'Suivi',
                      onTap: () => Get.toNamed('/admin-orders'),
                    ),
                    _compactTile(
                      icon: Icons.folder,
                      title: 'Local Orders',
                      subtitle: 'Stockées',
                      onTap: () => Get.toNamed('/local-orders'),
                    ),
                    _compactTile(
                      icon: Icons.sync,
                      title: 'Importer',
                      subtitle: 'Sync',
                      onTap: () => Get.toNamed('/import-data'),
                    ),
                    // 📅 Daily Sync Button
                    _compactTile(
                      icon: Icons.cloud_upload,
                      title: 'Daily Sync',
                      subtitle: 'Syncronisation',
                      onTap: () {
                        _showDailySyncDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_DashboardStats> _loadStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // Récupérer le restaurant de l'admin connecté
    final auth = Get.find<AuthController>();
    final restaurantId = auth.currentUser?.restaurantId;

    final allOrders = await DatabaseService.getPosOrdersByDateRange(start, end);

    // Filtrer par restaurant
    final orders = restaurantId != null
        ? allOrders.where((o) {
            if (o.restaurantId == null) return true;
            return o.restaurantId == restaurantId;
          }).toList()
        : allOrders;

    int tableOrders = 0;
    int remoteOrders = 0;
    double totalCA = 0;
    double tpeTotal = 0;
    double cashTotal = 0;
    double enCompteTotal = 0;

    for (final o in orders) {
      // Compter les commandes payées uniquement
      if (o.paymentStatus == 'paid') {
        totalCA += o.totalPrice;

        // 💰 Calculer les totaux par méthode de paiement (gérer les paiements split)
        if (o.paymentMethod == 'split' &&
            o.paymentSplit != null &&
            o.paymentSplit!.isNotEmpty) {
          try {
            final List<dynamic> payments = jsonDecode(o.paymentSplit!);
            for (final payment in payments) {
              final method = payment['payment_method'] as String?;
              final amount = (payment['amount'] as num).toDouble();

              if (isTpePaymentMethod(method)) {
                tpeTotal += amount;
              } else if (isCashPaymentMethod(method)) {
                cashTotal += amount;
              } else if (isEnComptePaymentMethod(method)) {
                enCompteTotal += amount;
              }
            }
          } catch (e) {
            appLogger.w('⚠️ Error parsing payment split: $e');
          }
        } else {
          // Paiement simple (non-split)
          final method = o.paymentMethod;
          if (isTpePaymentMethod(method)) {
            tpeTotal += o.totalPrice;
          } else if (isCashPaymentMethod(method)) {
            cashTotal += o.totalPrice;
          } else if (isEnComptePaymentMethod(method)) {
            enCompteTotal += o.totalPrice;
          }
        }
      }

      // Compter par type de commande
      if (o.fulfillmentType == 'on_site') {
        tableOrders++;
      } else {
        remoteOrders++;
      }
    }

    return _DashboardStats(
      tableOrders: tableOrders,
      remoteOrders: remoteOrders,
      totalCA: totalCA,
      tpeTotal: tpeTotal,
      cashTotal: cashTotal,
      enCompteTotal: enCompteTotal,
    );
  }

  void _showDailySyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Sync'),
        content: const Text(
          'Cette action va synchroniser toutes les données locales avec le serveur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger daily sync via SyncController
              final syncController = Get.find<SyncController>();
              syncController
                  .triggerDailyBatchSync()
                  .then((_) {
                    if (mounted) {
                      Get.snackbar(
                        'Succès',
                        'Synchronisation terminée',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      Get.snackbar(
                        'Erreur',
                        'Échec de la synchronisation: $error',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  });
            },
            child: const Text('Synchroniser'),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    return '${value.toStringAsFixed(2)} MAD';
  }

  Widget _compactStatCard({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: SushiColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: SushiShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: SushiTypo.bodySm.copyWith(color: SushiColors.inkLight),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: SushiTypo.h3.copyWith(color: accent),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: SushiTypo.caption.copyWith(color: SushiColors.inkLight),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final spacing = SushiSpace.md;
    final columns = 4;
    final tileWidth = (width - (spacing * (columns - 1))) / columns;

    return SizedBox(
      width: tileWidth,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(SushiSpace.md),
          decoration: BoxDecoration(
            color: SushiColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: SushiShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: SushiColors.red, size: 32),
              const SizedBox(height: SushiSpace.sm),
              Text(
                title,
                style: SushiTypo.bodyMd.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: SushiTypo.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStats {
  _DashboardStats({
    required this.tableOrders,
    required this.remoteOrders,
    required this.totalCA,
    required this.tpeTotal,
    required this.cashTotal,
    required this.enCompteTotal,
  });
  final int tableOrders;
  final int remoteOrders;
  final double totalCA;
  final double tpeTotal; // Total paiements TPE
  final double cashTotal; // Total paiements Cash
  final double enCompteTotal; // Total paiements en compte
}
