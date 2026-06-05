import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:caisse_1/models/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../controllers/pos_controller.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../models/pos_order.dart';
import '../utils/order_display_labels.dart';
import '../theme/sushi_design.dart';
import '../utils/payment_method_utils.dart';
import '../utils/app_logger.dart';
import '../widgets/order_details_dialog.dart';

// ── Palette locale ────────────────────────────────────────────────────────────
class _Palette {
  static const bg         = Color(0xFFF4F6FA);
  static const surface    = Colors.white;
  static const navy       = Color(0xFF1A237E);
  static const indigo     = Color(0xFF3949AB);
  static const teal       = Color(0xFF00897B);
  static const amber      = Color(0xFFF57C00);
  static const purple     = Color(0xFF7B1FA2);
  static const green      = Color(0xFF2E7D32);
  static const red        = Color(0xFFC62828);
  static const textPrimary   = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const divider       = Color(0xFFEEEEEE);
}

class CashierFinancialDashboard extends StatefulWidget {
  const CashierFinancialDashboard({super.key});

  @override
  State<CashierFinancialDashboard> createState() =>
      _CashierFinancialDashboardState();
}

class _CashierFinancialDashboardState extends State<CashierFinancialDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isLoadingReport = false; // Pour indiquer la génération du rapport

  DateTime? _lastLoadedDate;
  bool _hasCache = false;

  double _totalRevenue = 0;
  double _posRevenue = 0;
  double _webApiRevenue = 0;
  int _totalOrders = 0;
  int _posOrdersCount = 0;
  int _webApiOrdersCount = 0;

  final Map<String, int>    _ordersByTypeCount    = {};
  final Map<String, double> _ordersByTypeRevenue  = {};
  final Map<String, int>    _ordersByChannelCount   = {};
  final Map<String, double> _ordersByChannelRevenue = {};

  final Map<int, _ServerStats>  _serverStats  = {};
  final Map<int, _LivreurStats> _livreurStats = {};

  int    _deliveryOrdersCount = 0;
  double _deliveryRevenue     = 0;

  List<PosOrder> _allOrders = [];
  List<User>     _servers   = [];

  final int _ordersPageSize = 50;
  int _displayedOrdersCount = 0;
  final ScrollController _ordersScrollController = ScrollController();
  StreamSubscription<int>? _ordersSub;

  // ── Tab labels ──────────────────────────────────────────────────────────────
  static const _tabs = [
    _TabItem(Icons.dashboard_rounded,    'Global'),
    _TabItem(Icons.people_alt_rounded,   'Serveurs'),
    _TabItem(Icons.moped_rounded,        'Livreurs'),
    _TabItem(Icons.receipt_long_rounded, 'Commandes'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ordersScrollController.addListener(_onOrdersScroll);
    _loadData();
    // Listen for global orders changes (soft-deletes, updates)
    try {
      final pos = Get.find<PosController>();
      _ordersSub = pos.ordersRevision.listen((_) {
        if (!mounted) return;
        _hasCache = false; // force reload
        _loadData(forceRefresh: true);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _tabController.dispose();
    _ordersScrollController.dispose();
    super.dispose();
  }

  // ── Data loading (unchanged) ────────────────────────────────────────────────
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _hasCache &&
        _lastLoadedDate != null &&
        isSameDate(_lastLoadedDate!, _selectedDate)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));

      final auth         = Get.find<AuthController>();
      final restaurantId = auth.currentUser?.restaurantId;

      List<PosOrder> allOrders = await DatabaseService.getPosOrdersByDateRange(startOfDay, endOfDay);

      if (restaurantId != null) {
        allOrders = allOrders.where((o) => o.restaurantId == null || o.restaurantId == restaurantId).toList();
        appLogger.d('🏪 Cashier Dashboard - Filtered by restaurant $restaurantId: ${allOrders.length} orders');
      } else {
        appLogger.w('⚠️ Cashier Dashboard - No restaurant ID found for user, showing ALL orders');
      }

      final servers         = await DatabaseService.getUsersByRole('staff');
      final validServerIds  = servers.map((s) => s.id).toSet();
      final allOrderDeliveries = await DatabaseService.getAllOrderDeliveries();

      double totalRevenue = 0, posRevenue = 0, webApiRevenue = 0;
      int posOrdersCount = 0, webApiOrdersCount = 0, deliveryOrdersCount = 0;
      double deliveryRevenue = 0;

      final Map<int, _ServerStats>  serverStatsMap  = {};
      final Map<int, _LivreurStats> livreurStatsMap = {};
      final ordersById = <int, PosOrder>{for (final o in allOrders) o.id: o};

      _ordersByChannelCount.clear();
      _ordersByChannelRevenue.clear();
      _ordersByTypeCount.clear();
      _ordersByTypeRevenue.clear();

      for (final order in allOrders) {
        final status = order.status.trim().toLowerCase();
        if (status == 'cancelled' || status == 'canceled') continue;

        totalRevenue += order.totalPrice;

        final channel         = order.channel.toLowerCase();
        final fulfillmentType = order.fulfillmentType.toLowerCase();

        _ordersByChannelCount[channel]   = (_ordersByChannelCount[channel]   ?? 0) + 1;
        _ordersByChannelRevenue[channel] = (_ordersByChannelRevenue[channel] ?? 0) + order.totalPrice;

        if (channel == 'pos') { posRevenue += order.totalPrice; posOrdersCount++; }
        else                  { webApiRevenue += order.totalPrice; webApiOrdersCount++; }

        _ordersByTypeCount[fulfillmentType]   = (_ordersByTypeCount[fulfillmentType]   ?? 0) + 1;
        _ordersByTypeRevenue[fulfillmentType] = (_ordersByTypeRevenue[fulfillmentType] ?? 0) + order.totalPrice;

        if (order.staffId > 0 && fulfillmentType != 'delivery' && validServerIds.contains(order.staffId)) {
          serverStatsMap.putIfAbsent(order.staffId, () => _ServerStats(staffId: order.staffId));
          final stats = serverStatsMap[order.staffId]!;
          stats.orderCount++;
          stats.totalRevenue += order.totalPrice;
          if (channel == 'pos') { stats.posRevenue += order.totalPrice; stats.posOrders++; }
          else                  { stats.webApiRevenue += order.totalPrice; stats.webApiOrders++; }
          _updatePaymentMethodStats(stats, order);
        }
      }

      final filteredDeliveries = allOrderDeliveries.where((d) {
        if (d.assignedAt == null) return false;
        return !d.assignedAt!.isBefore(startOfDay) && d.assignedAt!.isBefore(endOfDay);
      }).toList();

      for (final delivery in filteredDeliveries) {
        final order = ordersById[delivery.orderId];
        if (order != null) {
          final status = order.status.trim().toLowerCase();
          if (status == 'cancelled' || status == 'canceled') continue;
        }
        final livreurId = delivery.livreurId;
        if (livreurId == null || livreurId <= 0) continue;

        livreurStatsMap.putIfAbsent(
          livreurId,
          () => _LivreurStats(livreurId: livreurId, livreurName: delivery.livreurName ?? order?.deliveryLivreurName ?? 'Inconnu'),
        );
        final stats = livreurStatsMap[livreurId]!;
        stats.deliveryCount++;
        if (order != null) {
          stats.totalRevenue += order.totalPrice;
          deliveryOrdersCount++;
          deliveryRevenue += order.totalPrice;
        }
        if (delivery.status == 'delivered') stats.completedDeliveries++;
      }

      setState(() {
        _allOrders           = allOrders;
        _servers             = servers;
        _totalRevenue        = totalRevenue;
        _posRevenue          = posRevenue;
        _webApiRevenue       = webApiRevenue;
        _totalOrders         = allOrders.length;
        _posOrdersCount      = posOrdersCount;
        _webApiOrdersCount   = webApiOrdersCount;
        _deliveryOrdersCount = deliveryOrdersCount;
        _deliveryRevenue     = deliveryRevenue;
        _serverStats.clear();  _serverStats.addAll(serverStatsMap);
        _livreurStats.clear(); _livreurStats.addAll(livreurStatsMap);
        _isLoading           = false;
        _hasCache            = true;
        _lastLoadedDate      = _selectedDate;
        _displayedOrdersCount = _ordersPageSize.clamp(0, _allOrders.length);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Get.snackbar('Erreur', 'Échec du chargement: $e', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _updatePaymentMethodStats(_ServerStats stats, PosOrder order) {
    final payments = parseSplitPaymentEntries(order.paymentSplit);
    if (payments.isNotEmpty) {
      for (final payment in payments) {
        final method = payment['payment_method'] as String?;
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        if (isOfferedPaymentMethod(method)) {
          continue;
        }
        if (isTpePaymentMethod(method)) {
          stats.tpeTotal += amount;
        } else if (isCashPaymentMethod(method)) {
          stats.cashTotal += amount;
        } else if (isEnComptePaymentMethod(method)) {
          stats.enCompteTotal += amount;
        }
      }
    } else {
      if (isTpePaymentMethod(order.paymentMethod)) {
        stats.tpeTotal += order.totalPrice;
      } else if (isCashPaymentMethod(order.paymentMethod)) {
        stats.cashTotal += order.totalPrice;
      } else if (isEnComptePaymentMethod(order.paymentMethod)) {
        stats.enCompteTotal += order.totalPrice;
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _Palette.indigo),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; _hasCache = false; });
      await _loadData(forceRefresh: true);
    }
  }

  void _onOrdersScroll() {
    if (_ordersScrollController.position.extentAfter < 500 && _displayedOrdersCount < _allOrders.length) {
      setState(() {
        _displayedOrdersCount = (_displayedOrdersCount + _ordersPageSize).clamp(_ordersPageSize, _allOrders.length);
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final restaurantId = Get.find<AuthController>().currentUser?.restaurantId;

    if (restaurantId == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: _Palette.bg,
        body: const Center(child: Text('Restaurant non configuré')),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Column(
        children: [
          // ── Header gradient ────────────────────────────────────────────
          _buildHeader(),

          // ── Loading ────────────────────────────────────────────────────
          if (_isLoading) ...[
            const SizedBox(height: 40),
            _buildLoadingIndicator(),
          ] else ...[
            // ── Tab bar ────────────────────────────────────────────────
            _buildTabBar(),

            // ── Tab content ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGlobalView(),
                  _buildServersView(),
                  _buildLivreursView(),
                  _buildOrdersView(),
                ],
              ),
            ),
          ],

          // ── Bottom action bar ──────────────────────────────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── AppBar fallback (non-configured) ───────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Tableau de bord financier'),
      backgroundColor: _Palette.indigo,
    );
  }

  // ── Gradient header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_Palette.navy, _Palette.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 4),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Tableau de bord financier',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Lecture seule',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Date picker button
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              // Generate report button - TEMPORARILY DISABLED
              // if (!_isLoadingReport)
              //   IconButton(
              //     icon: Container(
              //       padding: const EdgeInsets.all(6),
              //       decoration: BoxDecoration(
              //         color: Colors.white.withOpacity(0.15),
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       child: const Icon(Icons.description_outlined, color: Colors.white, size: 18),
              //     ),
              //     onPressed: _generateDailyReport,
              //     tooltip: 'Générer rapport journalier',
              //   )
              // else
              //   const Padding(
              //     padding: EdgeInsets.all(8.0),
              //     child: SizedBox(
              //       width: 20,
              //       height: 20,
              //       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              //     ),
              //   ),
              // Refresh
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () => _loadData(forceRefresh: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _Palette.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _Palette.indigo,
        indicatorWeight: 3,
        labelColor: _Palette.indigo,
        unselectedLabelColor: _Palette.textSecondary,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: _tabs.map((t) => Tab(
          icon: Icon(t.icon, size: 18),
          text: t.label,
          iconMargin: const EdgeInsets.only(bottom: 2),
        )).toList(),
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────────
  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(color: _Palette.indigo),
        const SizedBox(height: 16),
        Text('Chargement des données...', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _Palette.surface,
        border: const Border(top: BorderSide(color: _Palette.divider)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: _Palette.indigo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 1 — Vue globale
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildGlobalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              Expanded(child: _kpiCard('Commandes', '$_totalOrders', Icons.receipt_long_rounded, _Palette.amber)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Chiffre d\'affaires', AppSettingsService.instance.formatAmount(_totalRevenue), Icons.payments_rounded, _Palette.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpiCard('Panier moyen',
                _totalOrders > 0 ? AppSettingsService.instance.formatAmount(_totalRevenue / _totalOrders) : '0.00',
                Icons.shopping_cart_rounded, _Palette.teal)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Journée', DateFormat('dd/MM/yy').format(_selectedDate), Icons.today_rounded, _Palette.indigo)),
            ],
          ),
          const SizedBox(height: 24),

          // By type
          if (_ordersByTypeCount.isNotEmpty) ...[
            _sectionTitle('Par type de commande', Icons.category_rounded),
            const SizedBox(height: 10),
            ..._ordersByTypeCount.entries.map((e) => _breakdownTile(
              OrderDisplayLabels.typeLabel(e.key),
              e.value,
              _ordersByTypeRevenue[e.key] ?? 0,
              _Palette.indigo,
            )),
            const SizedBox(height: 20),
          ],

          // By channel
          if (_ordersByChannelCount.isNotEmpty) ...[
            _sectionTitle('Par canal de vente', Icons.devices_rounded),
            const SizedBox(height: 10),
            ..._ordersByChannelCount.entries.map((e) => _breakdownTile(
              OrderDisplayLabels.channelLabel(e.key),
              e.value,
              _ordersByChannelRevenue[e.key] ?? 0,
              _Palette.teal,
            )),
            const SizedBox(height: 20),
          ],

          // Delivery
          if (_deliveryOrdersCount > 0) ...[
            _sectionTitle('Statistiques Livraisons', Icons.local_shipping_rounded),
            const SizedBox(height: 10),
            _breakdownTile('Total Livraisons', _deliveryOrdersCount, _deliveryRevenue, _Palette.purple),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 2 — Serveurs
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildServersView() {
    if (_serverStats.isEmpty) return _emptyState(Icons.people_alt_rounded, 'Aucun serveur trouvé');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _serverStats.length,
      itemBuilder: (_, i) {
        final sid    = _serverStats.keys.elementAt(i);
        final stats  = _serverStats[sid]!;
        final server = _servers.firstWhere(
          (s) => s.id == sid,
          orElse: () => User(id: sid, name: 'Inconnu', phone: '', email: '', password: '', role: 'staff', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        );
        return _serverCard(server, stats);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 3 — Livreurs
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildLivreursView() {
    if (_livreurStats.isEmpty) return _emptyState(Icons.moped_rounded, 'Aucun livreur trouvé');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _livreurStats.length,
      itemBuilder: (_, i) {
        final lid   = _livreurStats.keys.elementAt(i);
        final stats = _livreurStats[lid]!;
        return _livreurCard(stats);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 4 — Commandes
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersView() {
    if (_allOrders.isEmpty) return _emptyState(Icons.receipt_rounded, 'Aucune commande trouvée');

    return ListView.builder(
      controller: _ordersScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedOrdersCount.clamp(0, _allOrders.length),
      itemBuilder: (_, i) => _orderCard(_allOrders[i]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // WIDGETS PARTAGÉS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _Palette.textSecondary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: _Palette.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, color: _Palette.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── KPI card ────────────────────────────────────────────────────────────────
  Widget _kpiCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: _Palette.textSecondary)),
        ],
      ),
    );
  }

  // ── Section title ───────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _Palette.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _Palette.indigo, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.textPrimary)),
      ],
    );
  }

  // ── Breakdown tile ──────────────────────────────────────────────────────────
  Widget _breakdownTile(String label, int count, double revenue, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Palette.textPrimary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count cmd${count > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: _Palette.textSecondary)),
              Text(AppSettingsService.instance.formatAmount(revenue), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Server card ─────────────────────────────────────────────────────────────
  Widget _serverCard(User server, _ServerStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _Palette.teal.withOpacity(0.12),
                  child: Text(
                    server.name[0].toUpperCase(),
                    style: const TextStyle(color: _Palette.teal, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.textPrimary), overflow: TextOverflow.ellipsis),
                      Text('${stats.orderCount} commandes', style: const TextStyle(fontSize: 12, color: _Palette.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _Palette.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppSettingsService.instance.formatAmount(stats.totalRevenue),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _Palette.teal),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: _Palette.divider),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(child: _chip(OrderDisplayLabels.channelLabel('pos'), stats.posOrders, stats.posRevenue, _Palette.indigo)),
                Expanded(child: _chip(OrderDisplayLabels.channelLabel('web'), stats.webApiOrders, stats.webApiRevenue, _Palette.teal)),
                Expanded(child: _chipAmount('TPE', stats.tpeTotal, _Palette.amber)),
                Expanded(child: _chipAmount('Cash', stats.cashTotal, _Palette.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Livreur card ─────────────────────────────────────────────────────────────
  Widget _livreurCard(_LivreurStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _Palette.purple.withOpacity(0.12),
                  child: const Icon(Icons.moped_rounded, color: _Palette.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.livreurName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.textPrimary)),
                      Text('${stats.deliveryCount} livraisons assignées', style: const TextStyle(fontSize: 12, color: _Palette.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _Palette.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppSettingsService.instance.formatAmount(stats.totalRevenue),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _Palette.purple),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _Palette.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(child: _chip('Livraisons', stats.deliveryCount, stats.totalRevenue, _Palette.purple)),
                Expanded(child: _chip('Complétées', stats.completedDeliveries, 0, _Palette.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Order card ───────────────────────────────────────────────────────────────
  Widget _orderCard(PosOrder order) {
    final statusColor = _getStatusColor(order.status);
    final ftLower     = order.fulfillmentType.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _Palette.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ftLower == 'delivery' ? Icons.local_shipping_rounded
                  : ftLower == 'pickup' ? Icons.shopping_bag_rounded
                  : Icons.restaurant_rounded,
              color: _Palette.teal, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.id} — ${order.tableNumber ?? 'À emporter'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Palette.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${order.channel.toUpperCase()} • ${order.fulfillmentType}',
                  style: const TextStyle(fontSize: 11, color: _Palette.textSecondary),
                ),
                Text(
                  order.staffId > 0 ? 'Serveur #${order.staffId}' : 'Non attribué',
                  style: const TextStyle(fontSize: 11, color: _Palette.textSecondary),
                ),
              ],
            ),
          ),
          // Right side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.totalPrice.toStringAsFixed(2)} MAD',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _Palette.textPrimary),
              ),
              Text(
                DateFormat.Hm().format(order.createdAt),
                style: const TextStyle(fontSize: 11, color: _Palette.textSecondary),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => showOrderDetailsDialog(context, order),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Voir', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _Palette.teal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mini chip (count + amount) ───────────────────────────────────────────────
  Widget _chip(String label, int count, double amount, Color accent) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _Palette.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
        if (amount > 0) ...[
          const SizedBox(height: 2),
          Text(AppSettingsService.instance.formatAmount(amount), style: const TextStyle(fontSize: 10, color: _Palette.textSecondary), textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _chipAmount(String label, double amount, Color accent) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _Palette.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(AppSettingsService.instance.formatAmount(amount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent), textAlign: TextAlign.center),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivered': return _Palette.green;
      case 'cancelled':
      case 'canceled':  return _Palette.red;
      default:          return _Palette.textSecondary;
    }
  }

  bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

}

// ── Helper record ─────────────────────────────────────────────────────────────
class _TabItem {
  final IconData icon;
  final String   label;
  const _TabItem(this.icon, this.label);
}

// ── Stats models (unchanged) ──────────────────────────────────────────────────
class _ServerStats {
  final int staffId;
  String staffName = 'Inconnu';
  int orderCount = 0;
  double totalRevenue = 0;
  double posRevenue = 0;
  int posOrders = 0;
  double webApiRevenue = 0;
  int webApiOrders = 0;
  double tpeTotal = 0;
  double cashTotal = 0;
  double enCompteTotal = 0;
  _ServerStats({required this.staffId});
}

class _LivreurStats {
  final int    livreurId;
  final String livreurName;
  int    deliveryCount       = 0;
  int    completedDeliveries = 0;
  double totalRevenue        = 0;
  _LivreurStats({required this.livreurId, required this.livreurName});
}
