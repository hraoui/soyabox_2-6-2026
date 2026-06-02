import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../models/user.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import '../utils/order_display_labels.dart';
import '../widgets/admin_shell.dart';

class AdminAccountingScreen extends StatefulWidget {
  const AdminAccountingScreen({super.key});

  @override
  State<AdminAccountingScreen> createState() => _AdminAccountingScreenState();
}

class _AdminAccountingScreenState extends State<AdminAccountingScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<_StaffSummary> _summaries = [];
  Map<int, List<PosOrder>> _ordersByStaff = {};
  double _totalRevenue = 0.0;
  double _totalCashRevenue = 0.0;
  double _totalTpeRevenue = 0.0;
  double _totalEnCompteRevenue = 0.0;

  // 📊 Stats par Canal
  double _posRevenue = 0.0;
  double _apiRevenue = 0.0;

  // 📊 Stats par Type
  int _onsiteCount = 0;
  int _pickupCount = 0;
  int _deliveryCount = 0;
  double _onsiteRevenue = 0.0;
  double _pickupRevenue = 0.0;
  double _deliveryRevenue = 0.0;

  int? _restaurantId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Récupérer le restaurant de l'admin connecté
      final auth = Get.find<AuthController>();
      _restaurantId = auth.currentUser?.restaurantId;

      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));

      // Charger les commandes du restaurant
      List<PosOrder> orders;
      if (_restaurantId != null) {
        orders = await DatabaseService.getPosOrdersByDateRange(start, end);
        // Filtrer par restaurant
        orders = orders.where((o) {
          if (o.restaurantId == null) return true; // Garder si null
          return o.restaurantId == _restaurantId;
        }).toList();
      } else {
        orders = await DatabaseService.getPosOrdersByDateRange(start, end);
      }

      final userById = await _loadUsersByStaffIds(
        orders.map((o) => o.staffId).toSet(),
      );

      final Map<int, _StaffSummary> byStaff = {};
      final Map<int, List<PosOrder>> ordersByStaff = {};
      double totalRevenue = 0.0;
      double totalCashRevenue = 0.0;
      double totalTpeRevenue = 0.0;
      double totalEnCompteRevenue = 0.0;

      // 📊 CA Total: Comptabiliser TOUTES les commandes (POS + Web/API, tous types)
      // pour le chiffre d'affaires total
      for (final order in orders) {
        final status = order.status.trim().toLowerCase();
        // Exclure uniquement les commandes annulées du CA total
        if (status == 'cancelled' || status == 'canceled') {
          continue;
        }
        totalRevenue += order.totalPrice;

        // ✅ Gérer les paiements split (multiples)
        if (order.paymentMethod == 'split' &&
            order.paymentSplit != null &&
            order.paymentSplit!.isNotEmpty) {
          try {
            final List<dynamic> payments = jsonDecode(order.paymentSplit!);
            for (final payment in payments) {
              final method = payment['payment_method'] as String?;
              final amount = (payment['amount'] as num).toDouble();

              if (isCashPaymentMethod(method)) {
                totalCashRevenue += amount;
              } else if (isTpePaymentMethod(method)) {
                totalTpeRevenue += amount;
              } else if (isEnComptePaymentMethod(method)) {
                totalEnCompteRevenue += amount;
              }
            }
          } catch (e) {
            appLogger.e('❌ Erreur parsing paymentSplit: $e');
          }
        } else if (isCashPaymentMethod(order.paymentMethod)) {
          totalCashRevenue += order.totalPrice;
        } else if (isTpePaymentMethod(order.paymentMethod)) {
          totalTpeRevenue += order.totalPrice;
        } else if (isEnComptePaymentMethod(order.paymentMethod)) {
          totalEnCompteRevenue += order.totalPrice;
        }
      }

      // 👨‍🍳 Comptabilité Serveurs: Uniquement Web/API Pickup (à emporter)
      // ❌ EXCLURE: Toutes les commandes delivery (attribuées au livreur, pas au serveur)
      // ❌ EXCLURE: POS (non concerné ici)
      for (final order in orders) {
        int staffId;
        double amount;
        String channel;
        String status;
        String? fulfillmentType;
        try {
          staffId = order.staffId;
          amount = order.totalPrice;
          channel = order.channel;
          status = order.status;
          fulfillmentType = order.fulfillmentType;
        } catch (_) {
          continue;
        }

        final isPosOrder = _isPosChannel(channel);
        final isApiOrder = !isPosOrder; // Web/API = api, web, kiosk
        final isPickup = fulfillmentType.trim().toLowerCase() == 'pickup';
        final isDelivery = fulfillmentType.trim().toLowerCase() == 'delivery';

        // ❌ EXCLURE les commandes delivery (tous channels) - comptabilité livreur
        if (isDelivery) {
          continue;
        }

        // ✅ Uniquement Web/API Pickup (à emporter)
        if (!isApiOrder || !isPickup) {
          continue;
        }

        // Vérifier le statut pour exclure les commandes annulées
        if (!_isCountedPosStatus(status)) {
          // POS: exclure les commandes annulées
          continue;
        }

        // 💰 Déterminer les types de paiement (gérer les paiements split)
        double cashAmount = 0;
        double tpeAmount = 0;
        double enCompteAmount = 0;

        if (order.paymentMethod == 'split' &&
            order.paymentSplit != null &&
            order.paymentSplit!.isNotEmpty) {
          try {
            final List<dynamic> payments = jsonDecode(order.paymentSplit!);
            for (final payment in payments) {
              final method = payment['payment_method'] as String?;
              final amt = (payment['amount'] as num).toDouble();

              if (isCashPaymentMethod(method)) {
                cashAmount += amt;
              } else if (isTpePaymentMethod(method)) {
                tpeAmount += amt;
              } else if (isEnComptePaymentMethod(method)) {
                enCompteAmount += amt;
              }
            }
          } catch (e) {
            appLogger.e('❌ Erreur parsing paymentSplit: $e');
          }
        } else {
          // Paiement simple
          if (isCashPaymentMethod(order.paymentMethod)) {
            cashAmount = order.totalPrice;
          } else if (isTpePaymentMethod(order.paymentMethod)) {
            tpeAmount = order.totalPrice;
          } else if (isEnComptePaymentMethod(order.paymentMethod)) {
            enCompteAmount = order.totalPrice;
          }
        }

        final isUnpaid = order.paymentStatus.trim().toLowerCase() != 'paid';

        final user = userById[staffId];
        final name = user?.name ?? 'Inconnu';
        final role = _roleLabel(user?.role);
        final key = staffId;

        if (!byStaff.containsKey(key)) {
          byStaff[key] = _StaffSummary(
            staffId: staffId,
            staffName: name,
            staffRole: role,
            ordersCount: 0,
            posOrdersCount: 0,
            mobileWebOrdersCount: 0,
            revenue: 0.0,
            posRevenue: 0.0,
            mobileWebRevenue: 0.0,
            cashRevenue: 0.0,
            tpeRevenue: 0.0,
            enCompteRevenue: 0.0,
            posCashRevenue: 0.0,
            posTpeRevenue: 0.0,
            mobileCashRevenue: 0.0,
            mobileTpeRevenue: 0.0,
            unpaidOrders: [],
          );
        }
        byStaff[key]!.ordersCount += 1;
        byStaff[key]!.revenue += amount;

        // 💰 Séparation Web/API
        if (isApiOrder && isPickup) {
          // ✅ Web/API Pickup (à emporter)
          byStaff[key]!.mobileWebOrdersCount += 1;
          byStaff[key]!.mobileWebRevenue += amount;

          // Paiement pour Web/API
          if (cashAmount > 0) {
            byStaff[key]!.mobileCashRevenue += cashAmount;
          }
          if (tpeAmount > 0) {
            byStaff[key]!.mobileTpeRevenue += tpeAmount;
          }
          if (enCompteAmount > 0) {
            byStaff[key]!.enCompteRevenue += enCompteAmount;
          }

          // 📌 Suivi des commandes non payées (pour bouton Payer)
          if (isUnpaid) {
            byStaff[key]!.unpaidOrders.add(order);
          }
        }

        ordersByStaff.putIfAbsent(key, () => <PosOrder>[]).add(order);
      }

      for (final list in ordersByStaff.values) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final summaries = byStaff.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      // 📊 Calculer les statistiques détaillées pour TOUTES les commandes
      double posRevenue = 0.0, apiRevenue = 0.0;
      int onsiteCount = 0, pickupCount = 0, deliveryCount = 0;
      double onsiteRevenue = 0.0, pickupRevenue = 0.0, deliveryRevenue = 0.0;

      for (final order in orders) {
        final status = order.status.trim().toLowerCase();
        if (status == 'cancelled' || status == 'canceled') {
          continue;
        }

        final channel = order.channel.trim().toLowerCase();
        final isPosOrder = channel.isEmpty || channel == 'pos';
        final isApiOrder =
            channel == 'api' || channel == 'web' || channel == 'kiosk';

        final fulfillmentType = order.fulfillmentType.trim().toLowerCase();
        final isOnsite =
            fulfillmentType == 'on_site' || fulfillmentType == 'onsite';
        final isPickup =
            fulfillmentType == 'pickup' || fulfillmentType == 'takeaway';
        final isDelivery = fulfillmentType == 'delivery';

        final amount = order.totalPrice;

        // Par canal
        if (isPosOrder) {
          posRevenue += amount;
        } else if (isApiOrder) {
          apiRevenue += amount;
        }

        // Par type
        if (isOnsite) {
          onsiteCount++;
          onsiteRevenue += amount;
        } else if (isPickup) {
          pickupCount++;
          pickupRevenue += amount;
        } else if (isDelivery) {
          deliveryCount++;
          deliveryRevenue += amount;
        }
      }

      setState(() {
        _summaries = summaries;
        _ordersByStaff = ordersByStaff;
        _totalRevenue = totalRevenue;
        _totalCashRevenue = totalCashRevenue;
        _totalTpeRevenue = totalTpeRevenue;
        _totalEnCompteRevenue = totalEnCompteRevenue;
        // 📊 Stats détaillées
        _posRevenue = posRevenue;
        _apiRevenue = apiRevenue;
        _onsiteCount = onsiteCount;
        _pickupCount = pickupCount;
        _deliveryCount = deliveryCount;
        _onsiteRevenue = onsiteRevenue;
        _pickupRevenue = pickupRevenue;
        _deliveryRevenue = deliveryRevenue;
      });
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Map<int, User?>> _loadUsersByStaffIds(Set<int> staffIds) async {
    final result = <int, User?>{};
    for (final staffId in staffIds) {
      try {
        result[staffId] = await DatabaseService.getUserById(staffId);
      } catch (_) {
        result[staffId] = null;
      }
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final auth = Get.find<AuthController>();
    final isSuperadmin = auth.currentUser?.isSuperadmin() ?? false;

    return AdminShell(
      title: 'Comptabilité',
      activeRoute: '/admin-accounting',
      child: Column(
        children: [
          // Header compact avec date et stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blancPur,
              border: Border(
                bottom: BorderSide(color: AppColors.grisLeger, width: 1),
              ),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppColors.deepTeal),
                  ),
                ),
                const Spacer(),
                // 🚚 Bouton Compta Livreurs
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/admin-delivery-accounting'),
                  icon: const Icon(Icons.local_shipping, size: 16),
                  label: const Text(
                    'Livreurs',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD5A8),
                    foregroundColor: const Color(0xFFCC8800),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // 📊 Grille de stats
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: AppColors.grisModerne,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune commande ce jour',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grisModerne,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne 1: CA Total, CA POS, CA Web/API
                        _buildCARow(),
                        const SizedBox(height: 16),
                        // Ligne 2: Total Onsite, Total Emporter, Total Livraison
                        _buildTypeRow(),
                        const SizedBox(height: 16),
                        // Ligne 3: TPE, Cash, En compte, Total Livraison
                        _buildPaymentRow(),
                        const SizedBox(height: 24),
                        // Section Serveurs (Superadmin uniquement)
                        if (isSuperadmin) _buildServeursSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Ligne 1: CA Total, CA POS, CA Web/API
  Widget _buildCARow() {
    return Row(
      children: [
        Expanded(
          child: _bigStatCard(
            title: 'CA Total',
            value: _formatAmount(_totalRevenue),
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'CA POS',
            value: _formatAmount(_posRevenue),
            icon: Icons.point_of_sale,
            color: const Color(0xFF1A9988),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'CA Web/API',
            value: _formatAmount(_apiRevenue),
            icon: Icons.api,
            color: const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  // Ligne 2: Total Onsite, Total Emporter, Total Livraison
  Widget _buildTypeRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Total Onsite',
            value: _onsiteCount.toString(),
            icon: Icons.restaurant,
            color: const Color(0xFF7CB342),
            subtitle: _formatAmount(_onsiteRevenue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Total Emporter',
            value: _pickupCount.toString(),
            icon: Icons.shopping_bag,
            color: const Color(0xFFFB8C00),
            subtitle: _formatAmount(_pickupRevenue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Total Livraison',
            value: _deliveryCount.toString(),
            icon: Icons.delivery_dining,
            color: const Color(0xFFE53935),
            subtitle: _formatAmount(_deliveryRevenue),
          ),
        ),
      ],
    );
  }

  // Ligne 3: TPE, Cash, En compte, Total Livraison (Livreurs)
  Widget _buildPaymentRow() {
    return Row(
      children: [
        Expanded(
          child: _paymentStatCard(
            title: 'TPE (Serveurs)',
            value: _formatAmount(_totalTpeRevenue),
            icon: Icons.credit_card,
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _paymentStatCard(
            title: 'Cash (Serveurs)',
            value: _formatAmount(_totalCashRevenue),
            icon: Icons.money,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _paymentStatCard(
            title: 'En compte',
            value: _formatAmount(_totalEnCompteRevenue),
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _paymentStatCard(
            title: 'Total Livraison (Livreurs)',
            value: _formatAmount(_deliveryRevenue),
            icon: Icons.local_shipping,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  // Section Serveurs
  Widget _buildServeursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serveurs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.charbon,
          ),
        ),
        const SizedBox(height: 12),
        _buildServeurGrid(),
      ],
    );
  }

  Widget _bigStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Build 4-column grid for serveurs
  Widget _buildServeurGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = 4;
        final spacing = 16.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _summaries.map((summary) {
            return SizedBox(
              width: cardWidth,
              child: _compactServeurCard(summary),
            );
          }).toList(),
        );
      },
    );
  }

  // 🎯 Compact Serveur Card - 4 per row
  Widget _compactServeurCard(_StaffSummary summary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStaffOrders(summary),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.blancPur,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grisLeger),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepTeal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and name
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.deepTeal.withOpacity(0.15),
                    child: Text(
                      summary.staffName.isNotEmpty
                          ? summary.staffName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.staffName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.charbon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            summary.staffRole,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Revenue and count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatAmount(summary.revenue),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${summary.ordersCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 💰 Payment breakdown (Cash / TPE / En compte)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.grisPale,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grisLeger),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Cash',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            _formatAmount(summary.cashRevenue),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 18, color: AppColors.grisLeger),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'TPE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          Text(
                            _formatAmount(summary.tpeRevenue),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 18, color: AppColors.grisLeger),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Compte',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          Text(
                            _formatAmount(summary.enCompteRevenue),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Order count by type (POS only for servers)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniStat(
                    label: 'POS',
                    value: summary.posOrdersCount.toString(),
                    color: const Color(0xFF1A9988),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 Mini stat for compact card
  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _showStaffOrders(_StaffSummary summary) async {
    final orders = _ordersByStaff[summary.staffId] ?? const <PosOrder>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.blancPur,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grisLeger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.deepTeal.withAlpha(18),
                          child: Text(
                            summary.staffName.isNotEmpty
                                ? summary.staffName
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.staffName,
                                style: AppTypography.headline2.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                summary.staffRole,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal.withAlpha(12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatAmount(summary.revenue),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Web/API Pickup: ${_formatAmount(summary.mobileWebRevenue)}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.grisLeger),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(
                            child: Text('Aucune commande pour ce profil'),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              // ✅ Afficher le bouton Payer pour Web/API Pickup
                              return _orderTile(order, showPayButton: true);
                            },
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 8),
                            itemCount: orders.length,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _orderTile(PosOrder order, {bool showPayButton = false}) {
    final orderId = _safeOrderId(order);
    final createdAt = _safeOrderCreatedAt(order);
    final status = _safeOrderStatus(order);
    final paymentStatus = _safeOrderPaymentStatus(order);
    final amount = _safeOrderAmount(order);
    final channel = order.channel.trim().toLowerCase();
    final fulfillmentType = order.fulfillmentType.trim().toLowerCase();
    final isApiOrder =
        channel == 'api' || channel == 'web' || channel == 'kiosk';
    final isPickup = fulfillmentType == 'pickup';
    final isUnpaid = paymentStatus != 'paid';

    // ✅ Afficher le bouton Payer pour Web/API Pickup non payées
    final canPay = showPayButton && isApiOrder && isPickup && isUnpaid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grisPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisLeger),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #$orderId',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatOrderTime(createdAt),
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _statusBadge(_statusLabel(status), status),
                    _paymentBadge(paymentStatus),
                    if (isApiOrder)
                      _channelBadge(OrderDisplayLabels.channelLabel(channel)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canPay)
            ElevatedButton(
              onPressed: () => _payOrder(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Payer',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            )
          else
            Text(
              _formatAmount(amount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.terraCotta,
              ),
            ),
        ],
      ),
    );
  }

  /// 💰 Payer une commande Web/API Pickup
  Future<void> _payOrder(PosOrder order) async {
    final orderId = order.id;
    final amount = order.totalPrice;

    // Afficher le dialog de paiement
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return; // Annulé

    try {
      // ✅ Utiliser le PosController standard au lieu d'une implémentation personnalisée
      final posController = Get.find<PosController>();
      await posController.markOrderAsPaid(order, paymentMethod);

      if (mounted) {
        final methodLabel = paymentMethodLabel(paymentMethod);
        Get.snackbar(
          'Succès',
          'Commande #$orderId payée ($amount dh) via $methodLabel',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Recharger les données
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Échec du paiement: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// 💰 Dialog pour choisir le mode de paiement
  Future<String?> _showPaymentMethodDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: AppColors.deepTeal),
              title: const Text('Cash'),
              onTap: () => Navigator.pop(context, paymentMethodCash),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: AppColors.deepTeal),
              title: const Text('TPE / Carte'),
              onTap: () => Navigator.pop(context, paymentMethodTpe),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('En compte'),
              onTap: () => Navigator.pop(context, paymentMethodEnCompte),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _channelBadge(String channel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF1976D2).withAlpha(80)),
      ),
      child: Text(
        channel,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _paymentBadge(String paymentStatus) {
    final paid = paymentStatus.trim().toLowerCase() == 'paid';
    final color = paid ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        paid ? 'Payée' : 'En attente',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  bool _isPosChannel(String rawChannel) {
    final normalized = rawChannel.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'pos';
  }

  bool _isCountedPosStatus(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    // Exclure les commandes annulées de la comptabilité
    if (status == 'cancelled' || status == 'canceled') {
      return false;
    }
    return true;
  }

  String _roleLabel(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'livreur':
        return 'Livreur';
      case 'staff':
        return 'Serveur';
      case 'admin':
        return 'Admin';
      case 'superadmin':
        return 'Super Admin';
      default:
        return 'Personnel';
    }
  }

  String _formatAmount(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  String _formatOrderTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
      case 'paid':
        return 'Livrée';
      case 'cancelled':
      case 'canceled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.deepPurple.shade400;
      case 'preparing':
        return Colors.blue.shade700;
      case 'ready':
        return Colors.green.shade700;
      case 'delivered':
      case 'paid':
        return AppColors.deepTeal;
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      default:
        return AppColors.grisModerne;
    }
  }

  int _safeOrderId(PosOrder order) {
    try {
      return order.id;
    } catch (_) {
      return 0;
    }
  }

  DateTime _safeOrderCreatedAt(PosOrder order) {
    try {
      return order.createdAt;
    } catch (_) {
      return _selectedDate;
    }
  }

  double _safeOrderAmount(PosOrder order) {
    try {
      return order.totalPrice;
    } catch (_) {
      return 0.0;
    }
  }

  String _safeOrderStatus(PosOrder order) {
    try {
      final status = order.status.trim();
      if (status.isEmpty) return 'pending';
      return status;
    } catch (_) {
      return 'pending';
    }
  }

  String _safeOrderPaymentStatus(PosOrder order) {
    try {
      final status = order.paymentStatus.trim();
      if (status.isEmpty) return 'pending';
      return status;
    } catch (_) {
      return 'pending';
    }
  }
}

class _StaffSummary {
  _StaffSummary({
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.ordersCount,
    required this.posOrdersCount,
    required this.mobileWebOrdersCount,
    required this.revenue,
    required this.posRevenue,
    required this.mobileWebRevenue,
    this.cashRevenue = 0.0,
    this.tpeRevenue = 0.0,
    this.enCompteRevenue = 0.0,
    this.posCashRevenue = 0.0,
    this.posTpeRevenue = 0.0,
    this.mobileCashRevenue = 0.0,
    this.mobileTpeRevenue = 0.0,
    this.unpaidOrders = const [],
  });

  final int staffId;
  final String staffName;
  final String staffRole;
  int ordersCount;
  int posOrdersCount;
  int mobileWebOrdersCount;
  double revenue;
  double posRevenue;
  double mobileWebRevenue;
  double cashRevenue;
  double tpeRevenue;
  double enCompteRevenue;
  double posCashRevenue;
  double posTpeRevenue;
  double mobileCashRevenue;
  double mobileTpeRevenue;
  final List<PosOrder> unpaidOrders;
}
