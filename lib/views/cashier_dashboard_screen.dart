import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cash_register_controller.dart';
import '../views/cash_register_status_screen.dart';
import '../views/cashier_simple_orders_screen.dart';
import '../views/cashier_simple_financial_screen.dart';
import '../services/daily_report_service.dart';

class CashierDashboardScreen extends StatelessWidget {
  const CashierDashboardScreen({super.key});

  Future<void> _showDailyReportDialog(BuildContext context) async {
    try {
      final authController = Get.find<AuthController>();
      final staffId = authController.currentUser?.id ?? 0;
      final staffName = authController.currentUser?.name ?? 'Inconnu';

      final reportMap = await DailyReportService.generateDailyReport(
        date: DateTime.now(),
        staffId: staffId,
        staffName: staffName,
        openedAt: null,
        closedAt: null,
      );

      _viewDetailedReport(reportMap);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger le rapport journalier: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _viewDetailedReport(Map<String, dynamic> report) {
    final summary = report['summary'] as Map<String, dynamic>;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(Get.context!).size.width * 0.9,
          height: MediaQuery.of(Get.context!).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // ── En-tête du rapport ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Rapport Journalier Détaillé',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // ── Contenu scrollable ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF1A237E)),
                            const SizedBox(width: 6),
                            Text(
                              report['date']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Résumé financier
                      _buildDialogSection(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Résumé Financier',
                        color: const Color(0xFF1A237E),
                        children: [
                          _buildInfoRow(
                            'Chiffre d\'affaires Total',
                            '${(summary['total_revenue'] as double).toStringAsFixed(2)} Dhs',
                            highlight: true,
                          ),
                          _buildInfoRow(
                            'Nombre de Commandes',
                            (summary['total_orders'] as int).toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._buildOrderTypesSection(summary),
                      ..._buildChannelsSection(summary),
                      ..._buildPaymentMethodsSection(summary),
                      ..._buildStaffBreakdownSection(summary),
                      ..._buildDeliveryBreakdownSection(summary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderTypesSection(Map<String, dynamic> summary) {
    final orderTypes =
        summary['order_types'] as Map<String, int>? ??
        {'onsite': 0, 'pickup': 0, 'delivery': 0};
    return [
      _buildDialogSection(
        icon: Icons.restaurant_rounded,
        title: 'Répartition par Type de Commande',
        color: const Color(0xFF00897B),
        children: [
          _buildInfoRow('Sur place', (orderTypes['onsite'] ?? 0).toString()),
          _buildInfoRow('À emporter', (orderTypes['pickup'] ?? 0).toString()),
          _buildInfoRow('Livraison', (orderTypes['delivery'] ?? 0).toString()),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildChannelsSection(Map<String, dynamic> summary) {
    final channels =
        summary['channels'] as Map<String, double>? ??
        {'pos': 0.0, 'api': 0.0, 'web': 0.0, 'kiosk': 0.0};
    return [
      _buildDialogSection(
        icon: Icons.device_hub_rounded,
        title: 'Répartition par Canal',
        color: const Color(0xFF6A1B9A),
        children: [
          _buildInfoRow('POS', '${(channels['pos'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('API', '${(channels['api'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('Web', '${(channels['web'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('Kiosk', '${(channels['kiosk'] ?? 0.0).toStringAsFixed(2)} Dhs'),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPaymentMethodsSection(Map<String, dynamic> summary) {
    final paymentMethods =
        summary['payment_methods'] as Map<String, double>? ??
        {'cash': 0.0, 'tpe': 0.0, 'en_compte': 0.0, 'other': 0.0};
    return [
      _buildDialogSection(
        icon: Icons.payments_rounded,
        title: 'Méthodes de Paiement',
        color: const Color(0xFFE65100),
        children: [
          _buildInfoRow('Espèces', '${(paymentMethods['cash'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('TPE', '${(paymentMethods['tpe'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('En compte', '${(paymentMethods['en_compte'] ?? 0.0).toStringAsFixed(2)} Dhs'),
          _buildInfoRow('Autre', '${(paymentMethods['other'] ?? 0.0).toStringAsFixed(2)} Dhs'),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildStaffBreakdownSection(Map<String, dynamic> summary) {
    final staffBreakdown = summary['staff_breakdown'] as List? ?? [];

    final children = <Widget>[];

    if (staffBreakdown.isEmpty) {
      children.add(
        const Text('Aucun serveur trouvé', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    } else {
      for (final staffStat in staffBreakdown) {
        if (staffStat is Map<String, dynamic>) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF1A237E)),
                      const SizedBox(width: 4),
                      Text(
                        'Serveur ID: ${staffStat['staff_id']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow('Commandes', '${staffStat['orders_count']}'),
                  _buildInfoRow(
                    'Chiffre d\'affaires',
                    '${(staffStat['total_revenue'] as double).toStringAsFixed(2)} Dhs',
                  ),
                  if (staffStat.containsKey('payment_methods')) ...[
                    _buildInfoRow(
                      'Espèces',
                      '${(staffStat['payment_methods']['cash'] ?? 0.0).toStringAsFixed(2)} Dhs',
                    ),
                    _buildInfoRow(
                      'TPE',
                      '${(staffStat['payment_methods']['tpe'] ?? 0.0).toStringAsFixed(2)} Dhs',
                    ),
                    _buildInfoRow(
                      'En compte',
                      '${(staffStat['payment_methods']['en_compte'] ?? 0.0).toStringAsFixed(2)} Dhs',
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      }
    }

    return [
      _buildDialogSection(
        icon: Icons.people_alt_rounded,
        title: 'Statistiques par Serveur',
        color: const Color(0xFF1A237E),
        children: children,
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildDeliveryBreakdownSection(Map<String, dynamic> summary) {
    final deliveryBreakdown = summary['delivery_breakdown'] as List? ?? [];

    final children = <Widget>[];

    if (deliveryBreakdown.isEmpty) {
      children.add(
        const Text('Aucune livraison trouvée', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    } else {
      for (final deliveryStat in deliveryBreakdown) {
        if (deliveryStat is Map<String, dynamic>) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00838F).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00838F).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded, size: 13, color: Color(0xFF00838F)),
                      const SizedBox(width: 4),
                      Text(
                        'Livreur ID: ${deliveryStat['delivery_staff_id']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow('Livraisons', '${deliveryStat['delivery_count']}'),
                  _buildInfoRow(
                    'Chiffre d\'affaires',
                    '${(deliveryStat['delivery_revenue'] as double).toStringAsFixed(2)} Dhs',
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return [
      _buildDialogSection(
        icon: Icons.delivery_dining_rounded,
        title: 'Statistiques par Livreur',
        color: const Color(0xFF00838F),
        children: children,
      ),
    ];
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? const Color(0xFF1A237E) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final cashRegisterController = Get.find<CashRegisterController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec dégradé ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.point_of_sale,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tableau de Bord',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  'Caissier',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    authController.logout();
                    Get.offAllNamed('/login');
                  },
                ),
              ),
            ],
          ),

          // ── Contenu principal ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Alerte compte non configuré ──────────────────────────
                if (authController.currentUser?.restaurantId == null ||
                    authController.currentUser?.restaurantId == 0) ...[
                  _buildWarningBanner(),
                  const SizedBox(height: 20),
                ],

                // ── Section "Mes Actions" ────────────────────────────────
                _buildSectionTitle('Mes Actions'),
                const SizedBox(height: 12),

                if (authController.currentRole == 'cashier' &&
                    authController.canViewOrders &&
                    authController.currentUser?.restaurantId != null &&
                    authController.currentUser?.restaurantId != 0) ...[
                  _buildFeatureCard(
                    title: 'Voir les commandes',
                    subtitle: 'Afficher toutes les commandes du jour',
                    icon: Icons.list_alt_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    onTap: () => Get.to(() => const CashierSimpleOrdersScreen()),
                  ),
                  const SizedBox(height: 12),
                ],

                if (authController.currentRole == 'cashier' &&
                    authController.canViewFinancialStatus &&
                    authController.currentUser?.restaurantId != null &&
                    authController.currentUser?.restaurantId != 0) ...[
                  _buildFeatureCard(
                    title: 'État financier',
                    subtitle: 'Voir les stats des serveurs et livreurs',
                    icon: Icons.bar_chart_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    ),
                    onTap: () => Get.to(() => const CashierSimpleFinancialScreen()),
                  ),
                  const SizedBox(height: 12),
                ],

                if (authController.currentRole == 'cashier' &&
                    authController.currentUser?.restaurantId != null &&
                    authController.currentUser?.restaurantId != 0) ...[
                  _buildFeatureCard(
                    title: 'Générer rapport journalier',
                    subtitle: 'Générer et consulter le rapport du jour',
                    icon: Icons.receipt_long_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
                    ),
                    onTap: () => _showDailyReportDialog(context),
                  ),
                  const SizedBox(height: 12),
                ],

                if (authController.currentRole == 'cashier') ...[
                  _buildFeatureCard(
                    title: 'Gestion de caisse',
                    subtitle: 'Ouvrir / Fermer la caisse',
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFFA726)],
                    ),
                    onTap: () => Get.to(() => CashRegisterStatusScreen()),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Statut de la caisse ──────────────────────────────────
                _buildSectionTitle('État de la caisse'),
                const SizedBox(height: 12),
                Obx(() => _buildCashRegisterStatusCard(cashRegisterController)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre de section ──────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF3949AB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── Bannière d'alerte ─────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte non configuré',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Votre compte caissier n\'est pas associé à un restaurant.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte d'action ────────────────────────────────────────────────────
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône avec dégradé
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
              // Flèche
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte statut caisse ───────────────────────────────────────────────
  Widget _buildCashRegisterStatusCard(CashRegisterController c) {
    final isOpen = c.isCashRegisterOpen;
    final isLocked = c.isCashRegisterLocked;

    final Color statusColor = isOpen
        ? const Color(0xFF2E7D32)
        : (isLocked ? const Color(0xFFC62828) : const Color(0xFFE65100));

    final Color bgColor = isOpen
        ? const Color(0xFFE8F5E9)
        : (isLocked ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0));

    final IconData statusIcon = isOpen
        ? Icons.lock_open_rounded
        : (isLocked ? Icons.lock_rounded : Icons.lock_clock_rounded);

    final String statusLabel = isOpen
        ? 'Caisse Ouverte'
        : (isLocked ? 'Caisse Bloquée' : 'Caisse Fermée');

    final String staffInfo;
    if (isOpen && c.currentState?.openedByStaffName != null) {
      staffInfo = 'Ouverte par ${c.currentState?.openedByStaffName}';
    } else if (!isOpen && c.currentState?.closedByStaffName != null) {
      staffInfo = 'Fermée par ${c.currentState?.closedByStaffName}';
    } else if (c.currentState?.openedByStaffName != null) {
      staffInfo = 'Dernière ouverture par ${c.currentState?.openedByStaffName}';
    } else {
      staffInfo = 'Aucune action enregistrée';
    }

    final authController = Get.find<AuthController>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dernière action : $staffInfo',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.35),
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isOpen && !isLocked) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final staffId = authController.currentUser?.id ?? 0;
                  final staffName = authController.currentUser?.name ?? 'Inconnu';
                  final success = await c.openCashRegister(
                    staffId: staffId,
                    staffName: staffName,
                  );

                  if (success) {
                    Get.snackbar('Succès', 'Caisse activée');
                  } else {
                    Get.snackbar(
                      'Erreur',
                      'Impossible d\'activer la caisse',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Activer la caisse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (isLocked) ...[
            const SizedBox(height: 12),
            const Text(
              'La caisse est verrouillée par un administrateur.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          ],
        ],
      ),
    );
  }
}