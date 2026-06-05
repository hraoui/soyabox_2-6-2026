import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cash_register_controller.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../utils/pos_ticket_printer.dart';
import '../services/esc_pos_printer_service.dart';
import '../utils/payment_method_utils.dart';

class CashierSimpleFinancialScreen extends StatefulWidget {
  const CashierSimpleFinancialScreen({super.key});

  @override
  State<CashierSimpleFinancialScreen> createState() => _CashierSimpleFinancialScreenState();
}

class _CashierSimpleFinancialScreenState extends State<CashierSimpleFinancialScreen> {
  bool _isPrinting = false;

  Future<void> _printDailyReport(int restaurantId) async {
    setState(() => _isPrinting = true);
    try {
      final today = DateTime.now();

      // Build report data (reuse pos_ticket_printer helper)
      final pdfBytes = await buildDailyReportForRestaurantDate(restaurantId, today);

      // Try ESC/POS first
      final reportData = await DatabaseService.getPosOrders().then((allOrders) async {
        final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final filtered = allOrders.where((o) => o.restaurantId == restaurantId && o.createdAt.toIso8601String().split('T')[0] == dateStr).toList();
        double totalRevenue = 0.0;
        int totalOrders = filtered.length;
        double totalDiscounts = 0.0;
        final paymentMethods = <String, double>{};
        final orderTypes = <String, int>{};
        final staffBreakdown = <Map<String, dynamic>>[];
        final deliveryBreakdown = <Map<String, dynamic>>[];
        var totalOfferedQuantity = 0;
        var totalOfferedValue = 0.0;

        for (final order in filtered) {
          totalRevenue += order.totalPrice;
          totalDiscounts += order.discountAmount;
          final splitTotals = splitPaymentTotalsByMethod(order.paymentSplit, includeOffert: false);
          if (splitTotals.isNotEmpty) {
            splitTotals.forEach((method, amount) { paymentMethods[method] = (paymentMethods[method] ?? 0.0) + amount; });
          } else {
            final norm = normalizePaymentMethod(order.paymentMethod);
            final methodKey = norm.isEmpty ? 'other' : norm;
            paymentMethods[methodKey] = (paymentMethods[methodKey] ?? 0.0) + order.totalPrice;
          }
          final typeKey = order.fulfillmentType.trim().toLowerCase();
          orderTypes[typeKey] = (orderTypes[typeKey] ?? 0) + 1;
          final items = await DatabaseService.getPosOrderItems(order.id);
          // Compute offered quantities/values from partialPaymentHistory similar to ticket utils
          for (final it in items) {
            if (it.partialPaymentHistory != null && it.partialPaymentHistory!.isNotEmpty) {
              try {
                final decoded = jsonDecode(it.partialPaymentHistory!);
                if (decoded is List) {
                  for (final raw in decoded) {
                    if (raw is Map) {
                      final isOffered = raw['is_offered'] == true;
                      if (isOffered) {
                        final qty = raw['quantity_paid'];
                        if (qty is num) {
                          totalOfferedQuantity += qty.toInt();
                          totalOfferedValue += (qty.toInt() * it.unitPrice);
                        }
                      } else {
                        final methods = raw['payment_methods'];
                        if (methods is List) {
                          final hasOffert = methods.any((payment) {
                            if (payment is Map) {
                              return normalizePaymentMethod(payment['method']?.toString()) == paymentMethodOffert;
                            }
                            return false;
                          });
                          if (hasOffert) {
                            final qty = raw['quantity_paid'];
                            if (qty is num) {
                              totalOfferedQuantity += qty.toInt();
                              totalOfferedValue += (qty.toInt() * it.unitPrice);
                            }
                          }
                        }
                      }
                    }
                  }
                }
              } catch (_) {}
            }
          }
          // minimal staff/delivery summaries
          staffBreakdown.add({'staff_id': order.staffId, 'staff_name': null, 'orders_count': 1, 'total_revenue': order.totalPrice, 'payment_methods': paymentMethods});
          if (order.deliveryLivreurId != null && order.deliveryLivreurId! > 0) {
            deliveryBreakdown.add({'delivery_staff_id': order.deliveryLivreurId, 'delivery_staff_name': order.deliveryLivreurName, 'delivery_count': 1, 'delivery_revenue': order.totalPrice});
          }
        }

        return {
          'date': dateStr,
          'summary': {
            'total_revenue': totalRevenue,
            'total_orders': totalOrders,
            'total_discounts': totalDiscounts,
            'total_offered_quantity': totalOfferedQuantity,
            'total_offered_value': totalOfferedValue,
            'payment_methods': paymentMethods,
            'order_types': orderTypes,
            'staff_breakdown': staffBreakdown,
            'delivery_breakdown': deliveryBreakdown,
          }
        };
      });

      final printed = await EscPosPrinterService.instance.tryPrintDailyReport(reportData);
      if (printed) {
        if (mounted) Get.snackbar('Succès', 'Rapport journalier envoyé à l\'imprimante');
      } else {
        // fallback to PDF print
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Erreur', 'Impossible d\'imprimer le rapport: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

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
                            'État Financier',
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
                            'État Financier',
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
                          : 'Les données de la journée fermée ne sont pas accessibles.',
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
                            Get.off(() => const CashierSimpleFinancialScreen());
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPrinting ? null : () => _printDailyReport(authController.currentUser!.restaurantId!),
        label: _isPrinting ? const Text('Impression...') : const Text('Imprimer rapport'),
        icon: const Icon(Icons.print),
      ),
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
                          'État Financier',
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
          SliverToBoxAdapter(
            child: _buildFinancialSummary(
              authController.currentUser!.restaurantId!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(int restaurantId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateFinancialSummary(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Erreur de calcul',
              subtitle:
                  'Impossible de charger le résumé financier de la session.',
              iconColor: Colors.red.shade700,
            ),
          );
        }

        final summary = snapshot.data ?? {};
        final totalRevenue = summary['totalRevenue'] ?? 0.0;
        final totalOrders = summary['totalOrders'] ?? 0;
        final cashTotal = summary['cashTotal'] ?? 0.0;
        final tpeTotal = summary['tpeTotal'] ?? 0.0;
        final enCompteTotal = summary['enCompteTotal'] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 720
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCard(
                    totalRevenue: totalRevenue,
                    totalOrders: totalOrders,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Répartition des encaissements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          label: 'Paiements espèces',
                          value: _formatAmount(cashTotal),
                          color: const Color(0xFFE65100),
                          icon: Icons.payments_rounded,
                          subtitle: 'Encaissement cash de la session',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          label: 'Paiements TPE',
                          value: _formatAmount(tpeTotal),
                          color: const Color(0xFF6A1B9A),
                          icon: Icons.credit_card_rounded,
                          subtitle: 'Encaissement carte / terminal',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          label: 'Paiements en compte',
                          value: _formatAmount(enCompteTotal),
                          color: const Color(0xFFC62828),
                          icon: Icons.account_balance_wallet_rounded,
                          subtitle: 'Montants imputés au compte client',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required double totalRevenue,
    required int totalOrders,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé de la session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Suivi rapide des encaissements du jour',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatAmount(totalRevenue),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalOrders commande${totalOrders > 1 ? 's' : ''} enregistrée${totalOrders > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required String subtitle,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
      width: double.infinity,
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

  Future<Map<String, dynamic>> _calculateFinancialSummary(
    int restaurantId,
  ) async {
    try {
      // Utiliser directement DatabaseService au lieu de PosController
      final allOrders = await DatabaseService.getPosOrders();

      // Filtrer par restaurant et en tenant compte de l'activation zéro data
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
      }).toList();

      double totalRevenue = 0.0;
      int totalOrders = filteredOrders.length;
      double cashTotal = 0.0;
      double tpeTotal = 0.0;
      double enCompteTotal = 0.0;

      for (final order in filteredOrders) {
        final amount = order.totalPrice;
        totalRevenue += amount;

        switch (order.paymentMethod?.toLowerCase()) {
          case 'cash':
          case 'espèces':
          case 'especes':
            cashTotal += amount;
            break;
          case 'card':
          case 'tpe':
          case 'carte':
            tpeTotal += amount;
            break;
          case 'account':
          case 'en compte':
          case 'compte':
            enCompteTotal += amount;
            break;
          default:
            cashTotal += amount; // Par défaut aux espèces
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'cashTotal': cashTotal,
        'tpeTotal': tpeTotal,
        'enCompteTotal': enCompteTotal,
      };
    } catch (e) {
      debugPrint('Erreur lors du calcul du résumé financier: $e');
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'cashTotal': 0.0,
        'tpeTotal': 0.0,
        'enCompteTotal': 0.0,
      };
    }
  }

  String _formatAmount(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }
}
