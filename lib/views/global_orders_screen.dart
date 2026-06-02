import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/admin_dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/admin_shell.dart';

class GlobalOrdersScreen extends StatefulWidget {
  const GlobalOrdersScreen({super.key});

  @override
  State<GlobalOrdersScreen> createState() => _GlobalOrdersScreenState();
}

class _GlobalOrdersScreenState extends State<GlobalOrdersScreen> {
  late AdminDashboardController _controller;

  @override
  void initState() {
    super.initState();
    // Initialiser le controller s'il n'existe pas déjà
    if (!Get.isRegistered<AdminDashboardController>()) {
      Get.put(AdminDashboardController());
    }
    _controller = Get.find<AdminDashboardController>();
    
    // ✅ Charger les données quand la page s'ouvre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDashboardData();
      // ✅ Démarrer l'auto-refresh seulement quand la page est visible
      _controller.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // ✅ Arrêter l'auto-refresh quand on quitte la page
    _controller.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Commandes Globales',
      activeRoute: '/global-orders',
      child: Obx(() {
        final stats = _controller.stats;
        final isLoading = _controller.isLoading;
        final error = _controller.error;
        final apiResponse = _controller.apiResponse;

        // ✅ Afficher un état de chargement si stats est null
        if (isLoading && stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: SushiSpace.md),
                Text('Chargement des données...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: SushiSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de date + Rafraîchissement
              _buildDateSelector(),
              const SizedBox(height: SushiSpace.lg),

              // ⚠️ Message d'erreur
              if (error.isNotEmpty)
                _buildErrorCard(error),

              // ⚠️ Avertissement si données partielles
              if (stats != null && stats.apiTotalCount < (apiResponse?['total_in_db'] as int? ?? 0))
                _buildLimitWarning(stats.apiTotalCount, apiResponse),

              // 📊 Statistiques principales
              _buildMainStatsCards(stats),

              const SizedBox(height: SushiSpace.md),

              // ℹ️ Informations sur les données
              if (stats != null)
                _buildDataInfoCard(stats, _controller.apiResponse),

              const SizedBox(height: SushiSpace.md),

              // 📊 Par type de commande
              if (stats != null && stats.ordersByType.isNotEmpty)
                _buildSectionByType(stats),

              const SizedBox(height: SushiSpace.lg),

              // 🌐 Par canal de vente
              if (stats != null && stats.ordersByChannel.isNotEmpty)
                _buildSectionByChannel(stats),
            ],
          ),
        );
      }),
    );
  }

  /// Sélecteur de date avec bouton de rafraîchissement
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: SushiColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: SushiShadow.card,
      ),
      child: Row(
        children: [
          // Sélecteur de date
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _controller.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  _controller.changeSelectedDate(picked);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: SushiColors.red, size: 20),
                  const SizedBox(width: SushiSpace.sm),
                  Text(
                    DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                        .format(_controller.selectedDate),
                    style: SushiTypo.bodyMd.copyWith(fontWeight: FontWeight.bold, color: SushiColors.ink),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SushiSpace.md),
          
          // Bouton de rafraîchissement manuel
          IconButton(
            onPressed: _controller.isLoading
                ? null
                : () => _controller.manualRefresh(),
            icon: Icon(
              Icons.refresh,
              color: SushiColors.red,
            ),
            tooltip: 'Rafraîchir (auto: 60s)',
          ),
        ],
      ),
    );
  }

  /// Carte d'avertissement si limite API atteinte
  Widget _buildLimitWarning(int apiCount, Map<String, dynamic>? apiResponse) {
    final totalInDb = apiResponse?['total_in_db'] as int? ?? 0;
    final limitApplied = apiResponse?['limit_applied'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: SushiSpace.md),
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: SushiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Données partielles',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Affichage de $apiCount sur $totalInDb commandes totales. '
                  '${limitApplied != null && limitApplied != 'none' ? 'Limite: $limitApplied commandes.' : ''}',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte d'erreur
  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: SushiSpace.md),
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: SushiSpace.sm),
          Expanded(
            child: Text(
              'Erreur: $error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Cartes de statistiques principales
  Widget _buildMainStatsCards(DashboardOrderStats? stats) {
    // ✅ Si stats est null, afficher des valeurs par défaut
    if (stats == null) {
      return Column(
        children: [
          Wrap(
            spacing: SushiSpace.md,
            runSpacing: SushiSpace.md,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
                child: _compactStatCard(
                  label: 'Total Commandes',
                  value: '0',
                  accent: SushiColors.orange,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
                child: _compactStatCard(
                  label: 'Chiffre d\'Affaires',
                  value: '0.00 MAD',
                  accent: SushiColors.green,
                  icon: Icons.attach_money,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
                child: _compactStatCard(
                  label: 'Panier Moyen',
                  value: '0.00 MAD',
                  accent: SushiColors.teal,
                  icon: Icons.shopping_cart_outlined,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
                child: _compactStatCard(
                  label: 'Période',
                  value: 'Aujourd\'hui',
                  accent: SushiColors.orange,
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        // Ligne 1: Total commandes et CA
        Wrap(
          spacing: SushiSpace.md,
          runSpacing: SushiSpace.md,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
              child: _compactStatCard(
                label: 'Total Commandes',
                value: '${stats.totalOrders}',
                accent: SushiColors.orange,
                icon: Icons.receipt_long_outlined,
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
              child: _compactStatCard(
                label: 'Chiffre d\'affaires',
                value: _controller.formatMoney(stats.totalRevenue),
                accent: SushiColors.green,
                icon: Icons.payments_outlined,
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
              child: _compactStatCard(
                label: 'Panier moyen',
                value: stats.totalOrders > 0
                    ? _controller.formatMoney(stats.totalRevenue / stats.totalOrders)
                    : '0.00 MAD',
                accent: SushiColors.teal,
                icon: Icons.shopping_cart_outlined,
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - SushiSpace.md * 3) / 4,
              child: _compactStatCard(
                label: 'Période',
                value: DateFormat('dd/MM/yyyy').format(stats.dateFrom),
                accent: SushiColors.teal,
                icon: Icons.today_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section statistiques par type de commande
  Widget _buildSectionByType(dynamic stats) {
    return _buildStatsSection(
      title: 'Par type de commande',
      icon: Icons.category_outlined,
      ordersMap: stats.ordersByType,
      revenueMap: stats.revenueByType,
      getLabel: _controller.getFulfillmentTypeLabel,
      totalOrders: stats.totalOrders,
      totalRevenue: stats.totalRevenue,
    );
  }

  /// Section statistiques par channel
  Widget _buildSectionByChannel(dynamic stats) {
    return _buildStatsSection(
      title: 'Par canal de vente',
      icon: Icons.devices_outlined,
      ordersMap: stats.ordersByChannel,
      revenueMap: stats.revenueByChannel,
      getLabel: _controller.getChannelLabel,
      totalOrders: stats.totalOrders,
      totalRevenue: stats.totalRevenue,
    );
  }

  /// Widget générique pour une section de statistiques
  Widget _buildStatsSection({
    required String title,
    required IconData icon,
    required Map<String, int> ordersMap,
    required Map<String, double> revenueMap,
    required String Function(String) getLabel,
    required int totalOrders,
    required double totalRevenue,
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
          // Titre de la section
          Row(
            children: [
              Icon(icon, color: SushiColors.red, size: 24),
              const SizedBox(width: SushiSpace.sm),
              Text(title, style: SushiTypo.h4),
            ],
          ),
          const SizedBox(height: SushiSpace.md),

          // Liste des items
          ...ordersMap.entries.map((entry) {
            final type = entry.key;
            final count = entry.value;
            final revenue = revenueMap[type] ?? 0.0;
            final orderPercentage = totalOrders > 0 
                ? (count / totalOrders * 100).toStringAsFixed(1)
                : '0.0';
            final revenuePercentage = totalRevenue > 0
                ? (revenue / totalRevenue * 100).toStringAsFixed(1)
                : '0.0';

            return Padding(
              padding: const EdgeInsets.only(bottom: SushiSpace.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      getLabel(type),
                      style: SushiTypo.bodyMd.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$count cmdes ($orderPercentage%)',
                      style: SushiTypo.caption,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _controller.formatMoney(revenue),
                      style: SushiTypo.bodyMd.copyWith(
                        color: SushiColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '($revenuePercentage%)',
                      style: SushiTypo.caption,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Carte de statistique compacte
  Widget _compactStatCard({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
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
        ],
      ),
    );
  }

  /// Carte d'informations sur les données API
  Widget _buildDataInfoCard(
    DashboardOrderStats stats,
    Map<String, dynamic>? apiResponse,
  ) {
    final totalInDb = apiResponse?['total_in_db'] as int? ?? 0;
    final limitApplied = apiResponse?['limit_applied'];
    final filters = apiResponse?['filters'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: SushiSpace.sm),
              Text(
                'Informations sur les données',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: SushiSpace.sm),
          _buildInfoRow('Commandes affichées:', '${stats.apiTotalCount}'),
          if (totalInDb > 0)
            _buildInfoRow(
              'Total en base de données:',
              '$totalInDb commandes',
            ),
          if (limitApplied != null)
            _buildInfoRow(
              'Limite appliquée:',
              limitApplied == 'none'
                  ? 'Aucune (toutes les commandes)'
                  : '$limitApplied commandes',
            ),
          if (filters != null && filters['start_date'] != null)
            _buildInfoRow(
              'Période:',
              '${filters['start_date']} → ${filters['end_date']}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
