import 'dart:convert';
import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:caisse_1/controllers/pos_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../models/pos_order.dart';
import '../models/user.dart';
import '../models/delivery.dart';
import '../utils/order_display_labels.dart';
import '../theme/sushi_design.dart';
import '../widgets/order_details_dialog.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/admin_shell.dart';
import '../widgets/edit_order_dialog.dart';
import '../utils/app_logger.dart';
import '../widgets/unified_payment_dialog.dart';

class FinancialAdminDashboard extends StatefulWidget {
  const FinancialAdminDashboard({super.key});

  @override
  State<FinancialAdminDashboard> createState() =>
      _FinancialAdminDashboardState();
}

class _FinancialAdminDashboardState extends State<FinancialAdminDashboard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _searchQuery = ''; // ✅ Ajout de l'état de recherche

  // Cache mechanism
  DateTime? _lastLoadedDate;
  bool _hasCache = false;

  // Financial data
  double _totalRevenue = 0;
  double _posRevenue = 0;
  double _webApiRevenue = 0;
  int _totalOrders = 0;
  int _posOrdersCount = 0;
  int _webApiOrdersCount = 0;

  // Orders by type breakdown
  final Map<String, int> _ordersByTypeCount = {};
  final Map<String, double> _ordersByTypeRevenue = {};

  // Orders by channel breakdown
  final Map<String, int> _ordersByChannelCount = {};
  final Map<String, double> _ordersByChannelRevenue = {};

  // Per server data
  final Map<int, _ServerStats> _serverStats = {};

  // Per livreur data
  final Map<int, _LivreurStats> _livreurStats = {};

  // Delivery stats
  int _deliveryOrdersCount = 0;
  double _deliveryRevenue = 0;

  // Glovo stats
  int _glovoOrdersCount = 0;
  double _glovoRevenue = 0;

  // All orders for management (with pagination)
  List<PosOrder> _allOrders = [];
  List<User> _servers = [];

  // Filter state
  String _selectedFilter = 'Toutes'; // 'Toutes', 'POS', 'Web/API', 'En attente', 'Payées', 'Annulées'

  // Pagination for orders
  final int _ordersPageSize = 50;
  int _displayedOrdersCount = 50;
  final ScrollController _ordersScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ordersScrollController.addListener(_onOrdersScroll);
    _loadData();
  }

  Widget _simpleMeta(IconData icon, String value, {double fontSize = 12}) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SushiColors.inkMid),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, color: SushiColors.ink, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }


  Future<void> _showOrderDetails(PosOrder order) async {
    // Use shared dialog widget
    await showOrderDetailsDialog(context, order);
  }

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating back

  @override
  void dispose() {
    _tabController.dispose();
    _ordersScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Use cache if same date and not forced refresh
    if (!forceRefresh &&
        _hasCache &&
        _lastLoadedDate != null &&
        isSameDate(_lastLoadedDate!, _selectedDate)) {
      return; // Already cached, skip reload
    }

    setState(() => _isLoading = true);

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // ✅ Récupérer le restaurant de l'admin connecté
      final auth = Get.find<AuthController>();
      final restaurantId = auth.currentUser?.restaurantId;

      // Get all orders for the selected date
      List<PosOrder> allOrders = await DatabaseService.getPosOrdersByDateRange(
        startOfDay,
        endOfDay,
      );

      // ✅ Filtrer par restaurant si un restaurant est défini
      if (restaurantId != null) {
        allOrders = allOrders.where((order) {
          // Garder les commandes sans restaurantId (legacy) OU du bon restaurant
          if (order.restaurantId == null) return true;
          return order.restaurantId == restaurantId;
        }).toList();
        
        appLogger.d(
          '🏪 Financial Dashboard - Filtered by restaurant $restaurantId: '
          '${allOrders.length} orders',
        );
      } else {
        appLogger.w(
          '⚠️ Financial Dashboard - No restaurant ID found for user, '
          'showing ALL orders',
        );
      }

      // Get all servers (cache this separately as it changes rarely)
      final servers = await DatabaseService.getUsersByRole('staff');

      // Create a set of valid server IDs for fast lookup
      final validServerIds = servers.map((s) => s.id).toSet();

      // Get all delivery assignments from OrderDelivery table
      final allOrderDeliveries = await DatabaseService.getAllOrderDeliveries();

      // Calculate financials
      double totalRevenue = 0;
      double posRevenue = 0;
      double webApiRevenue = 0;
      int posOrdersCount = 0;
      int webApiOrdersCount = 0;
      int deliveryOrdersCount = 0;
      double deliveryRevenue = 0;
      int glovoOrdersCount = 0;
      double glovoRevenue = 0;

      final Map<int, _ServerStats> serverStatsMap = {};
      final Map<int, _LivreurStats> livreurStatsMap = {};

      // Build order lookup by ID for delivery stats
      final ordersById = <int, PosOrder>{};
      for (final order in allOrders) {
        ordersById[order.id] = order;
      }

      // Clear breakdown maps before repopulating
      _ordersByChannelCount.clear();
      _ordersByChannelRevenue.clear();
      _ordersByTypeCount.clear();
      _ordersByTypeRevenue.clear();

      // ===== 1. CALCULATE FINANCIALS (All non-cancelled orders) =====
      for (final order in allOrders) {
        // EXCLUDE cancelled orders from all calculations
        final status = order.status.trim().toLowerCase();
        if (status == 'cancelled' || status == 'canceled') {
          continue;
        }

        // Count ALL non-cancelled orders for CA (paid and unpaid)
        totalRevenue += order.totalPrice;

        final channel = order.channel.toLowerCase();
        final fulfillmentType = order.fulfillmentType.toLowerCase();

        // Channel breakdown (count and revenue for ALL non-cancelled orders)
        _ordersByChannelCount[channel] =
            (_ordersByChannelCount[channel] ?? 0) + 1;
        _ordersByChannelRevenue[channel] =
            (_ordersByChannelRevenue[channel] ?? 0) + order.totalPrice;

        if (channel == 'pos') {
          posRevenue += order.totalPrice;
          posOrdersCount++;
        } else {
          webApiRevenue += order.totalPrice;
          webApiOrdersCount++;
        }

        // Type breakdown (by fulfillment type) - ALL non-cancelled orders
        _ordersByTypeCount[fulfillmentType] =
            (_ordersByTypeCount[fulfillmentType] ?? 0) + 1;
        _ordersByTypeRevenue[fulfillmentType] =
            (_ordersByTypeRevenue[fulfillmentType] ?? 0) + order.totalPrice;

        // Per-server stats: EXCLUDE delivery orders (counted for livreurs only)
        // ✅ Only count orders that have a valid staffId AND are NOT delivery type
        if (order.staffId > 0 && fulfillmentType != 'delivery') {
          // ✅ Fast lookup using Set instead of iterating through list
          if (validServerIds.contains(order.staffId)) {
            serverStatsMap.putIfAbsent(
              order.staffId,
              () => _ServerStats(staffId: order.staffId),
            );
            final stats = serverStatsMap[order.staffId]!;

            // Count ALL non-cancelled, non-delivery orders for servers
            stats.orderCount++;
            stats.totalRevenue += order.totalPrice;

            // Separate by channel (already lowercased above)
            if (channel == 'pos') {
              stats.posRevenue += order.totalPrice;
              stats.posOrders++;
            } else {
              stats.webApiRevenue += order.totalPrice;
              stats.webApiOrders++;
            }

            // Payment method breakdown
            _updatePaymentMethodStats(stats, order);
          }
        }

        // ===== GLOVO ORDERS CALCULATION (Option 3: Combination) =====
        // A command is Glovo if:
        // 1. order.isGlovoDelivery == true OR
        // 2. At least one item has priceType == 'glovo'
        bool isGlovoOrder = order.isGlovoDelivery;
        
        // If not marked as Glovo at order level, check items
        if (!isGlovoOrder) {
          try {
            final items = await DatabaseService.getPosOrderItems(order.id);
            isGlovoOrder = items.any((item) => 
              item.priceType?.toLowerCase() == 'glovo'
            );
          } catch (e) {
            // If we can't fetch items, skip this check
            appLogger.w('⚠️ Failed to fetch items for order ${order.id}: $e');
          }
        }

        // Count Glovo orders and revenue
        if (isGlovoOrder) {
          glovoOrdersCount++;
          glovoRevenue += order.totalPrice;
        }
      }

      // ===== 2. CALCULATE DELIVERY & LIVREUR STATS =====
      // Filter deliveries by date ONCE (startOfDay and endOfDay already defined above)
      final filteredDeliveries = allOrderDeliveries.where((d) {
        if (d.assignedAt == null) return false;
        return !d.assignedAt!.isBefore(startOfDay) &&
            d.assignedAt!.isBefore(endOfDay);
      }).toList();

      for (final delivery in filteredDeliveries) {
        final order = ordersById[delivery.orderId];

        // Exclude cancelled orders
        if (order != null) {
          final status = order.status.trim().toLowerCase();
          if (status == 'cancelled' || status == 'canceled') {
            continue;
          }
        }

        final livreurId = delivery.livreurId;
        if (livreurId == null || livreurId <= 0) continue;

        livreurStatsMap.putIfAbsent(
          livreurId,
          () => _LivreurStats(
            livreurId: livreurId,
            livreurName:
                delivery.livreurName ?? order?.deliveryLivreurName ?? 'Inconnu',
          ),
        );
        final stats = livreurStatsMap[livreurId]!;
        stats.deliveryCount++;

        // Count ALL non-cancelled delivery orders for livreur stats
        if (order != null) {
          stats.totalRevenue += order.totalPrice;
          deliveryOrdersCount++;
          deliveryRevenue += order.totalPrice;
        }

        if (delivery.status == 'delivered') {
          stats.completedDeliveries++;
        }
      }

      setState(() {
        _allOrders = allOrders;
        _servers = servers;
        _totalRevenue = totalRevenue;
        _posRevenue = posRevenue;
        _webApiRevenue = webApiRevenue;
        _totalOrders = allOrders.length;
        _posOrdersCount = posOrdersCount;
        _webApiOrdersCount = webApiOrdersCount;
        _deliveryOrdersCount = deliveryOrdersCount;
        _deliveryRevenue = deliveryRevenue;
        _glovoOrdersCount = glovoOrdersCount;
        _glovoRevenue = glovoRevenue;
        _serverStats.clear();
        _serverStats.addAll(serverStatsMap);
        _livreurStats.clear();
        _livreurStats.addAll(livreurStatsMap);
        _isLoading = false;
        _hasCache = true;
        _lastLoadedDate = _selectedDate;
        _displayedOrdersCount = _ordersPageSize; // Reset pagination
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Échec du chargement: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _updatePaymentMethodStats(_ServerStats stats, PosOrder order) {
    if (order.paymentMethod == 'split' &&
        order.paymentSplit != null &&
        order.paymentSplit!.isNotEmpty) {
      try {
        final List<dynamic> payments = jsonDecode(order.paymentSplit!);
        for (final payment in payments) {
          final method = payment['payment_method'] as String?;
          final amount = (payment['amount'] as num).toDouble();

          if (isTpePaymentMethod(method)) {
            stats.tpeTotal += amount;
          } else if (isCashPaymentMethod(method)) {
            stats.cashTotal += amount;
          } else if (isEnComptePaymentMethod(method)) {
            stats.enCompteTotal += amount;
          }
        }
      } catch (e) {
        // Ignore parsing errors
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = 'Toutes'; // Reset filter when date changes
      });
      _hasCache = false; // Clear cache when date changes
      await _loadData(forceRefresh: true);
    }
  }

  void _onOrdersScroll() {
    if (_ordersScrollController.position.pixels >=
        _ordersScrollController.position.maxScrollExtent - 200) {
      if (_displayedOrdersCount < _allOrders.length) {
        setState(() {
          _displayedOrdersCount = (_displayedOrdersCount + _ordersPageSize)
              .clamp(0, _allOrders.length);
        });
      }
    }
  }

  /// Get filtered orders based on selected filter
  List<PosOrder> _getFilteredOrders() {
    // ✅ Appliquer d'abord le filtre par statut/canal
    List<PosOrder> filteredOrders;
    if (_selectedFilter == 'Toutes') {
      filteredOrders = _allOrders;
    } else {
      filteredOrders = _allOrders.where((order) {
        final channel = order.channel.toLowerCase();
        final status = order.status.trim().toLowerCase();
        final paymentStatus = order.paymentStatus.trim().toLowerCase();

        switch (_selectedFilter) {
          case 'POS':
            return channel == 'pos';
          case 'Web/API':
            return channel != 'pos';
          case 'En attente':
            return paymentStatus != 'paid' && paymentStatus != 'cancelled' && paymentStatus != 'canceled';
          case 'Payées':
            return paymentStatus == 'paid';
          case 'Annulées':
            return status == 'cancelled' || status == 'canceled';
          default:
            return true;
        }
      }).toList();
    }

    // ✅ Appliquer ensuite la recherche par numéro de commande
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filteredOrders = filteredOrders.where((order) {
        final orderIdStr = order.id.toString();
        return orderIdStr.contains(searchLower);
      }).toList();
    }

    return filteredOrders;
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return AdminShell(
      title: 'Tableau de bord financier',
      activeRoute: '/financial-dashboard',
      child: Column(
        children: [
          // Header with date selector
          _buildHeader(),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Vue globale'),
              Tab(icon: Icon(Icons.people), text: 'Serveurs'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Livreurs'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Commandes'),
            ],
          ),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGlobalOverviewTab(),
                      _buildServersTab(),
                      _buildLivreursTab(),
                      _buildOrdersTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: SushiColors.teal),
          const SizedBox(width: SushiSpace.sm),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: SushiSpace.md),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.edit_calendar, size: 18),
            label: const Text('Changer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SushiColors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              _hasCache = false; // Clear cache on manual refresh
              _loadData(forceRefresh: true);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SushiColors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Card
          _buildRevenueCard(),
          const SizedBox(height: SushiSpace.lg),
          // Revenue by Channel
          _buildChannelBreakdown(),
          const SizedBox(height: SushiSpace.lg),
          // Orders by Channel
          _buildOrdersBreakdown(),
          const SizedBox(height: SushiSpace.lg),
          // Orders by Fulfillment Type
          _buildTypeBreakdown(),
          const SizedBox(height: SushiSpace.lg),
          // Delivery Stats
          _buildDeliveryBreakdown(),
          const SizedBox(height: SushiSpace.lg),
          // Glovo Orders Stats
          _buildGlovoBreakdown(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SushiColors.teal, const Color(0xFF0D7A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(SushiRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chiffre d\'Affaires Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: SushiSpace.sm),
          Text(
            AppSettingsService.instance.formatAmount(_totalRevenue),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelBreakdown() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'POS',
            AppSettingsService.instance.formatAmount(_posRevenue),
            Icons.point_of_sale,
            SushiColors.orange,
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Expanded(
          child: _statCard(
            'Web/API',
            AppSettingsService.instance.formatAmount(_webApiRevenue),
            Icons.language,
            const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersBreakdown() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Commandes POS',
            '$_posOrdersCount',
            Icons.store,
            SushiColors.green,
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Expanded(
          child: _statCard(
            'Commandes Web/API',
            '$_webApiOrdersCount',
            Icons.cloud,
            const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Expanded(
          child: _statCard(
            'Total Commandes',
            '$_totalOrders',
            Icons.receipt_long,
            SushiColors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBreakdown() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Sur place',
            '${_ordersByTypeCount['onsite'] ?? 0}',
            Icons.restaurant,
            const Color(0xFF5D6D7E),
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Expanded(
          child: _statCard(
            'À emporter',
            '${_ordersByTypeCount['pickup'] ?? 0}',
            Icons.shopping_bag,
            SushiColors.orange,
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Expanded(
          child: _statCard(
            'Livraison',
            '${_ordersByTypeCount['delivery'] ?? 0}',
            Icons.local_shipping,
            SushiColors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics, size: 18, color: SushiColors.teal),
            SizedBox(width: SushiSpace.xs),
            Text(
              'Livraisons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: SushiSpace.md),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Livraisons',
                '$_deliveryOrdersCount',
                Icons.local_shipping,
                SushiColors.orange,
              ),
            ),
            const SizedBox(width: SushiSpace.md),
            Expanded(
              child: _statCard(
                'CA Livraisons',
                AppSettingsService.instance.formatAmount(_deliveryRevenue),
                Icons.payments,
                SushiColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlovoBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.delivery_dining, size: 18, color: SushiColors.orange),
            SizedBox(width: SushiSpace.xs),
            Text(
              'Glovo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: SushiSpace.md),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Commandes Glovo',
                '$_glovoOrdersCount',
                Icons.delivery_dining,
                SushiColors.orange,
              ),
            ),
            const SizedBox(width: SushiSpace.md),
            Expanded(
              child: _statCard(
                'CA Glovo',
                AppSettingsService.instance.formatAmount(_glovoRevenue),
                Icons.payments,
                SushiColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SushiRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SushiSpace.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SushiRadius.sm),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: SushiSpace.xs),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance par Serveur',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: SushiSpace.md),
          if (_serverStats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(SushiSpace.xl),
                child: Text('Aucune donnée serveur pour cette date'),
              ),
            )
          else
            ..._serverStats.values.map((stats) => _buildServerCard(stats)),
        ],
      ),
    );
  }

  Widget _buildServerCard(_ServerStats stats) {
    final server = _servers.firstWhere(
      (s) => s.id == stats.staffId,
      orElse: () => User(
        name: 'Serveur #${stats.staffId}',
        phone: '',
        email: '',
        password: '',
        role: 'staff',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: SushiSpace.md),
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SushiRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: SushiColors.teal.withOpacity(0.1),
                child: Text(
                  server.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: SushiColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: SushiSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${stats.orderCount} commandes',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                AppSettingsService.instance.formatAmount(stats.totalRevenue),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: SushiColors.teal,
                ),
              ),
            ],
          ),
          const Divider(height: SushiSpace.lg),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  OrderDisplayLabels.channelLabel('pos'),
                  stats.posOrders,
                  stats.posRevenue,
                ),
              ),
              Expanded(
                child: _miniStat(
                  OrderDisplayLabels.channelLabel('web'),
                  stats.webApiOrders,
                  stats.webApiRevenue,
                ),
              ),
              Expanded(child: _miniPaymentStat('TPE', stats.tpeTotal)),
              Expanded(child: _miniPaymentStat('Cash', stats.cashTotal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: SushiSpace.xs),
        Text(
          '$count',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          AppSettingsService.instance.formatAmount(amount),
          style: const TextStyle(fontSize: 11, color: SushiColors.teal),
        ),
      ],
    );
  }

  Widget _miniPaymentStat(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: SushiSpace.xs),
        Text(
          AppSettingsService.instance.formatAmount(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildLivreursTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance par Livreur',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: SushiSpace.md),
          if (_livreurStats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(SushiSpace.xl),
                child: Text('Aucune donnée livreur pour cette date'),
              ),
            )
          else
            ..._livreurStats.values.map((stats) => _buildLivreurCard(stats)),
        ],
      ),
    );
  }

  Widget _buildLivreurCard(_LivreurStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: SushiSpace.md),
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SushiRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SushiColors.orange.withOpacity(0.1),
            child: Text(
              stats.livreurName[0].toUpperCase(),
              style: const TextStyle(
                color: SushiColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: SushiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.livreurName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${stats.deliveryCount} livraisons (${stats.completedDeliveries} terminées)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            AppSettingsService.instance.formatAmount(stats.totalRevenue),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: SushiColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 💳 Afficher le dialogue de paiement unifié (identique à staff orders et tables)
  Future<void> _showPaymentDialog(PosOrder order) async {
    final posController = Get.find<PosController>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UnifiedPaymentDialog(
        order: order,
        pos: posController,
        showEditOption: true, // Admin can edit payments
      ),
    );

    if (result == true && mounted) {
      Get.snackbar(
        'Paiement enregistré avec succès',
        '✅ Succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Rafraîchir les données
      _hasCache = false;
      await _loadData(forceRefresh: true);
    }
  }

  /// ✅ Assigner un livreur à une commande de livraison
  Future<void> _assignLivreurToOrder(PosOrder order) async {
    // Vérifier que c'est une commande de livraison
    if (order.fulfillmentType != 'delivery') {
      Get.snackbar(
        'Non applicable',
        'Cette commande n\'est pas une livraison',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Charger les livreurs disponibles
    final livreurs = await DatabaseService.getAllDeliveries();

    if (livreurs.isEmpty) {
      Get.snackbar(
        'Aucun livreur',
        'Veuillez créer un livreur d\'abord',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!mounted) return;

    final selectedLivreur = await showDialog<Delivery>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sélectionner un livreur'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: livreurs.length,
            itemBuilder: (context, index) {
              final livreur = livreurs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: SushiColors.orange.withOpacity(0.15),
                  child: Text(
                    livreur.name[0].toUpperCase(),
                    style: const TextStyle(color: SushiColors.orange),
                  ),
                ),
                title: Text(livreur.name),
                subtitle: Text(livreur.phone),
                onTap: () => Navigator.pop(dialogContext, livreur),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedLivreur == null || !mounted) return;

    // Assigner le livreur
    try {
      final posController = Get.find<PosController>();
      final result = await posController.assignLivreurToDelivery(
        order: order,
        livreurId: selectedLivreur.id,
        livreurName: selectedLivreur.name,
        livreurPhone: selectedLivreur.phone,
      );

      if (!mounted) return;

      if (result != null) {
        Get.snackbar(
          'Succès',
          'Livreur ${selectedLivreur.name} assigné à la commande #${order.id}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Rafraîchir les données
        _hasCache = false;
        await _loadData(forceRefresh: true);
      } else {
        Get.snackbar(
          'Erreur',
          posController.error ?? 'Échec de l\'assignation',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// ✅ Changer le livreur d'une commande
  Future<void> _changeLivreurForOrder(PosOrder order) async {
    await _assignLivreurToOrder(order);
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // ✅ Champ de recherche par numéro de commande
        Container(
          padding: const EdgeInsets.all(SushiSpace.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: SushiColors.teal),
              hintText: 'Rechercher par numéro de commande...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SushiRadius.sm),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SushiRadius.sm),
                borderSide: const BorderSide(color: SushiColors.teal, width: 2),
              ),
            ),
          ),
        ),
        // Filter bar
        Container(
          padding: const EdgeInsets.all(SushiSpace.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: SushiColors.teal),
              const SizedBox(width: SushiSpace.sm),
              const Text('Filtres: '),
              const SizedBox(width: SushiSpace.sm),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Toutes', Icons.list),
                      _filterChip(
                        OrderDisplayLabels.channelLabel('pos'),
                        Icons.store,
                      ),
                      _filterChip(
                        OrderDisplayLabels.channelLabel('web'),
                        Icons.cloud,
                      ),
                      _filterChip('En attente', Icons.pending),
                      _filterChip('Payées', Icons.payment),
                      _filterChip('Annulées', Icons.cancel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Orders list
        Expanded(
          child: _getFilteredOrders().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: SushiSpace.sm),
                      Text(
                        'Aucune commande pour ce filtre',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      if (_selectedFilter != 'Toutes') ...[
                        const SizedBox(height: SushiSpace.xs),
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedFilter = 'Toutes'),
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Réinitialiser le filtre'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _ordersScrollController,
                  itemCount: _getFilteredOrders().length < _displayedOrdersCount 
                      ? _getFilteredOrders().length 
                      : _displayedOrdersCount,
                  itemBuilder: (context, index) {
                    final filteredOrders = _getFilteredOrders();
                    if (index >= filteredOrders.length) {
                      return const SizedBox.shrink();
                    }
                    final order = filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: SushiSpace.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: SushiSpace.xs),
            Text(label),
          ],
        ),
        selected: _selectedFilter == label,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'Toutes';
          });
        },
      ),
    );
  }

  Widget _buildOrderCard(PosOrder order) {
    final channelColor = order.channel.toLowerCase() == 'pos'
        ? SushiColors.green
        : const Color(0xFF2196F3);

    final statusColor = order.status == 'paid'
        ? SushiColors.green
        : order.status == 'cancelled'
        ? SushiColors.red
        : SushiColors.orange;

    final auth = Get.find<AuthController>();
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      padding: const EdgeInsets.all(SushiSpace.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SushiRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SushiSpace.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: channelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  OrderDisplayLabels.channelLabel(order.channel),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: channelColor,
                  ),
                ),
              ),
              const SizedBox(width: SushiSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SushiSpace.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppSettingsService.instance.formatAmount(order.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SushiColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: SushiSpace.xs),
          // ✅ Numéro de commande
          Text(
            'Commande #${order.id}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: SushiSpace.xs),
          Text(
            'Client: ${order.customerName ?? 'N/A'} | Tél: ${order.customerPhone ?? 'N/A'}',
            style: const TextStyle(fontSize: 12),
          ),
          // ✅ Afficher les infos de livraison si c'est une commande de livraison
          if (order.fulfillmentType == 'delivery') ...[
            const SizedBox(height: SushiSpace.xs),
            Container(
              padding: const EdgeInsets.all(SushiSpace.sm),
              decoration: BoxDecoration(
                color: order.deliveryLivreurId != null
                    ? SushiColors.green.withOpacity(0.05)
                    : SushiColors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(SushiRadius.sm),
                border: Border.all(
                  color: order.deliveryLivreurId != null
                      ? SushiColors.green.withOpacity(0.3)
                      : SushiColors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    order.deliveryLivreurId != null
                        ? Icons.check_circle
                        : Icons.delivery_dining,
                    size: 16,
                    color: order.deliveryLivreurId != null
                        ? SushiColors.green
                        : SushiColors.orange,
                  ),
                  const SizedBox(width: SushiSpace.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryLivreurId != null
                              ? 'Livreur assigné'
                              : 'Aucun livreur assigné',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: order.deliveryLivreurId != null
                                ? SushiColors.green
                                : SushiColors.orange,
                          ),
                        ),
                        if (order.deliveryLivreurName != null &&
                            order.deliveryLivreurName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${order.deliveryLivreurName}${order.deliveryLivreurPhone != null && order.deliveryLivreurPhone!.isNotEmpty ? ' • ${order.deliveryLivreurPhone}' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ Bouton pour assigner/changer le livreur
                  TextButton.icon(
                    onPressed: () => order.status != 'cancelled'
                        ? (order.deliveryLivreurId != null
                              ? _changeLivreurForOrder(order)
                              : _assignLivreurToOrder(order))
                        : null,
                    icon: Icon(
                      order.deliveryLivreurId != null
                          ? Icons.swap_horiz
                          : Icons.person_add,
                      size: 14,
                    ),
                    label: Text(
                      order.deliveryLivreurId != null ? 'Changer' : 'Assigner',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (order.deliveryLivreurName != null) ...[
            const SizedBox(height: SushiSpace.xs),
            Text(
              'Livreur: ${order.deliveryLivreurName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: SushiSpace.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status != 'cancelled') ...[
                // ✅ Bouton Payer - Seulement si non payé
                if (order.paymentStatus != 'paid')
                  TextButton.icon(
                    onPressed: () => _showPaymentDialog(order),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Payer'),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.green,
                    ),
                  ),
                // ✅ Bouton Modifier Paiement - Seulement si déjà payé (pour admin)
                if (order.paymentStatus == 'paid')
                  TextButton.icon(
                    onPressed: () => _showPaymentDialog(order),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier Paiement'),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.orange,
                    ),
                  ),
                // ✅ Bouton Assigner un livreur visible uniquement pour les commandes de livraison sans livreur
                if (order.fulfillmentType == 'delivery' &&
                    order.deliveryLivreurId == null)
                  TextButton.icon(
                    onPressed: () => _assignLivreurToOrder(order),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Assigner livreur'),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.orange,
                    ),
                  ),
                // ✅ Voir commande (détails)
                TextButton.icon(
                  onPressed: () => _showOrderDetails(order),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Voir'),
                  style: TextButton.styleFrom(
                    foregroundColor: SushiColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editOrder(order),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                ),
                if (auth.canDeleteOrders)
                  TextButton.icon(
                    onPressed: () => _confirmDeleteOrder(order),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.red,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _cancelOrder(order),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Annuler'),
                  style: TextButton.styleFrom(foregroundColor: SushiColors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editOrder(PosOrder order) async {
    try {
      final posController = Get.find<PosController>();
      
      // ✅ Charger la commande pour édition (admin check is now in loadOrderForEdit)
      await posController.loadOrderForEdit(order);
      
      if (posController.error != null) {
        Get.snackbar(
          'Erreur',
          posController.error!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // Rediriger vers l'écran POS pour édition
      Get.toNamed('/pos-order');
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

  Future<void> _cancelOrder(PosOrder order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CancelOrderDialog(order: order),
    );

    if (result == true) {
      _hasCache = false;
      await _loadData(forceRefresh: true);
    }
  }

  Future<void> _confirmDeleteOrder(PosOrder order) async {
    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la commande'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette commande ? Cette action est réservée aux administrateurs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final posController = Get.find<PosController>();
    await posController.deleteOrder(order);
    if (posController.error != null) {
      Get.snackbar(
        'Erreur',
        posController.error!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.snackbar(
      'Commande supprimée',
      'La commande a été supprimée avec succès.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    _hasCache = false;
    await _loadData(forceRefresh: true);
  }
}

class _ServerStats {
  final int staffId;
  int orderCount = 0;
  int posOrders = 0;
  int webApiOrders = 0;
  double totalRevenue = 0;
  double posRevenue = 0;
  double webApiRevenue = 0;
  double tpeTotal = 0;
  double cashTotal = 0;
  double enCompteTotal = 0;

  _ServerStats({required this.staffId});
}

class _LivreurStats {
  final int livreurId;
  final String livreurName;
  int deliveryCount = 0;
  int completedDeliveries = 0;
  double totalRevenue = 0;

  _LivreurStats({required this.livreurId, required this.livreurName});
}
