import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cash_register_controller.dart';
import '../models/pos_order.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../utils/order_display_labels.dart';
import '../widgets/order_details_dialog.dart';

class CashierSimpleOrdersScreen extends StatelessWidget {
  const CashierSimpleOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Vérifier que le caissier a un restaurant_id
    if (authController.currentUser?.restaurantId == null ||
        authController.currentUser?.restaurantId == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1A237E),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => Get.back(),
              ),
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
                          Text(
                            'Commandes du Jour',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Accès refusé',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Votre compte caissier n\'est pas associé à un restaurant.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Vérifier l'état de la caisse - si fermée, bloquer l'accès aux données
    final cashRegisterController = Get.find<CashRegisterController>();
    if (!cashRegisterController.isCashRegisterOpen &&
        authController.currentRole != 'admin' &&
        authController.currentRole != 'superadmin') {
      final isLocked = cashRegisterController.isCashRegisterLocked;
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1A237E),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => Get.back(),
              ),
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
                          Text(
                            'Commandes du Jour',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLocked ? Icons.admin_panel_settings : Icons.lock,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLocked ? 'Caisse Bloquée' : 'Caisse Fermée',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocked
                          ? 'La caisse est verrouillée par un administrateur.'
                          : 'Les commandes de la journée fermée ne sont pas accessibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    if (!isLocked) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final staffId = authController.currentUser?.id ?? 0;
                          final staffName =
                              authController.currentUser?.name ?? 'Inconnu';
                          final success = await cashRegisterController
                              .openCashRegister(
                                staffId: staffId,
                                staffName: staffName,
                              );

                          if (success) {
                            Get.snackbar('Succès', 'Caisse activée');
                            Get.off(() => const CashierSimpleOrdersScreen());
                          } else {
                            Get.snackbar(
                              'Erreur',
                              'Impossible d\'activer la caisse',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('Activer la caisse'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A237E),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: () => Get.back(),
            ),
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
                        Text(
                          'Commandes du Jour',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildOrdersList(authController.currentUser!.restaurantId!),
        ],
      ),
    );
  }

  Widget _buildOrdersList(int restaurantId) {
    return FutureBuilder<List<PosOrder>>(
      future: _fetchOrders(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: _buildStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Erreur lors du chargement',
                subtitle: 'Impossible de récupérer les commandes du jour.',
                iconColor: Colors.red.shade700,
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: _buildStateCard(
                icon: Icons.receipt_long_outlined,
                title: 'Aucune commande aujourd\'hui',
                subtitle:
                    'Les nouvelles commandes apparaîtront ici pendant la session de caisse.',
                iconColor: const Color(0xFF3949AB),
              ),
            ),
          );
        }

        final totalRevenue = orders.fold<double>(
          0.0,
          (sum, order) => sum + order.totalPrice,
        );

        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildOverviewCard(
                totalOrders: orders.length,
                totalRevenue: totalRevenue,
              ),
            ),
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildOrderCard(context: context, order: order),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required int totalOrders,
    required double totalRevenue,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commandes de la session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalOrders commande${totalOrders > 1 ? 's' : ''} • ${_formatAmount(totalRevenue)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required PosOrder order,
  }) {
    final statusColor = _statusColor(order.status);
    final surfaceColor = statusColor.withOpacity(0.12);
    final locationLabel = order.fulfillmentType == 'on_site'
        ? 'Table ${order.tableNumber ?? '-'}'
        : (order.tableNumber?.trim().isNotEmpty == true
              ? order.tableNumber!
              : OrderDisplayLabels.typeLabel(order.fulfillmentType));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => showOrderDetailsDialog(context, order),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTime(order.createdAt)} • $locationLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOrderPill(
                    label: _statusLabel(order.status),
                    backgroundColor: surfaceColor,
                    textColor: statusColor,
                  ),
                  _buildOrderPill(
                    label: OrderDisplayLabels.channelLabel(order.channel),
                    backgroundColor: const Color(0xFFE3F2FD),
                    textColor: const Color(0xFF1565C0),
                  ),
                  _buildOrderPill(
                    label: OrderDisplayLabels.typeLabel(order.fulfillmentType),
                    backgroundColor: const Color(0xFFE8F5E9),
                    textColor: const Color(0xFF2E7D32),
                  ),
                  _buildOrderPill(
                    label: order.paymentStatus.trim().toLowerCase() == 'paid'
                        ? 'Payée'
                        : 'En attente',
                    backgroundColor: const Color(0xFFFFF3E0),
                    textColor: const Color(0xFFE65100),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Color(0xFF3949AB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Voir le détail de la commande',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderPill({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: iconColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Future<List<PosOrder>> _fetchOrders(int restaurantId) async {
    try {
      // Utiliser directement DatabaseService au lieu de PosController
      final allOrders = await DatabaseService.getPosOrders();

      // Filtrer par restaurant et date du jour
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final cashRegister = Get.find<CashRegisterController>();
      final zeroDataActivatedAt =
          cashRegister.currentState?.zeroDataActivatedAt;

      final filteredOrders = allOrders.where((order) {
        // Vérifier que la commande appartient au restaurant du caissier
        if (order.restaurantId != restaurantId) {
          return false;
        }

        // Vérifier que la commande est d'aujourd'hui
        final orderDate = order.createdAt.toIso8601String().split('T')[0];
        if (orderDate != todayStr) {
          return false;
        }

        if (zeroDataActivatedAt != null &&
            order.createdAt.isBefore(zeroDataActivatedAt)) {
          return false;
        }

        return true;
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredOrders;
    } catch (e) {
      debugPrint('Erreur lors du chargement des commandes: $e');
      return [];
    }
  }

  String _formatAmount(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  String _formatTime(DateTime createdAt) {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return 'Payée';
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
      case 'canceled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFE65100);
      case 'confirmed':
        return const Color(0xFF3949AB);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF1A237E);
    }
  }
}
