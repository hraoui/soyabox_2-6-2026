import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/pos_order.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/order_display_labels.dart';
import '../widgets/admin_shell.dart';
import 'package:intl/intl.dart';

// ============================================================
// LOCAL ORDERS SCREEN
// ============================================================

/// Écran affichant toutes les commandes locales avec filtres et sync
class LocalOrdersScreen extends StatefulWidget {
  const LocalOrdersScreen({super.key});

  @override
  State<LocalOrdersScreen> createState() => _LocalOrdersScreenState();
}

class _LocalOrdersScreenState extends State<LocalOrdersScreen> {
  String _filter = 'all'; // all, today, synced, not_synced
  List<PosOrder> _allOrders = [];
  List<PosOrder> _filteredOrders = [];
  bool _loading = true;
  int? _restaurantId;
  Map<int, String> _staffNames = {};
  Map<int, String> _restaurantNames = {};

  // 📅 Date filter
  DateTime? _startDate;
  DateTime? _endDate;

  // 🔍 Channel & Type filters
  String? _selectedChannel; // null = all
  String? _selectedType; // null = all

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure all dependencies are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);

    try {
      // Check if AuthController is registered
      if (!Get.isRegistered<AuthController>()) {
        appLogger.w('[LocalOrders] AuthController not registered');
        if (mounted) {
          Get.snackbar(
            'Erreur',
            'Session non trouvée. Veuillez vous reconnecter.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      final auth = Get.find<AuthController>();
      _restaurantId = auth.currentUser?.restaurantId;

      if (_restaurantId == null) {
        appLogger.w('[LocalOrders] No restaurant ID for current user');
      }

      // 📅 Get ALL orders from database (not just today)
      List<PosOrder> allOrders;

      if (_startDate != null && _endDate != null) {
        // Custom date range
        final end = _endDate!.add(const Duration(days: 1));
        allOrders = await DatabaseService.getPosOrdersByDateRange(
          _startDate!,
          end,
        );
      } else {
        // No filter - get all orders
        allOrders = await DatabaseService.getPosOrders();
      }

      // Filter by restaurant if needed
      if (_restaurantId != null) {
        _allOrders = allOrders.where((o) {
          if (o.restaurantId == null) return true;
          return o.restaurantId == _restaurantId;
        }).toList();
      } else {
        _allOrders = allOrders;
      }

      // Sort by createdAt desc
      _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Load display names for restaurants and staff
      final staffIds = _allOrders.map((o) => o.staffId).toSet().toList();
      final restaurantIds = _allOrders.where((o) => o.restaurantId != null).map((o) => o.restaurantId!).toSet().toList();

      final users = await Future.wait(staffIds.map(DatabaseService.getUserById));
      final restaurants = await Future.wait(restaurantIds.map(DatabaseService.getRestaurantById));

      _staffNames = {for (var user in users.whereType<User>()) user.id: user.name};
      _restaurantNames = {for (var restaurant in restaurants.whereType<Restaurant>()) restaurant.id: restaurant.name};

      _applyFilter();
    } catch (e, stackTrace) {
      appLogger.e(
        '[LocalOrders] Error loading orders',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les commandes: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    List<PosOrder> filtered = _allOrders;

    // Apply type filter
    switch (_filter) {
      case 'today':
        filtered = filtered
            .where((o) => o.createdAt.isAfter(todayStart))
            .toList();
        break;
      case 'synced':
        filtered = filtered.where((o) => o.isDailySynced).toList();
        break;
      case 'not_synced':
        filtered = filtered.where((o) => !o.isDailySynced).toList();
        break;
      default:
        filtered = _allOrders;
    }

    // Apply channel filter
    if (_selectedChannel != null && _selectedChannel!.isNotEmpty) {
      filtered = filtered
          .where(
            (o) => o.channel.toLowerCase() == _selectedChannel!.toLowerCase(),
          )
          .toList();
    }

    // Apply fulfillment type filter
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filtered = filtered
          .where(
            (o) =>
                o.fulfillmentType.toLowerCase() == _selectedType!.toLowerCase(),
          )
          .toList();
    }

    _filteredOrders = filtered;
    if (mounted) {
      setState(() {});
    }
  }

  void _setFilter(String newFilter) {
    setState(() => _filter = newFilter);
    _applyFilter();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      // Auto-set end date to start date if not set
      if (_endDate == null || _endDate!.isBefore(_startDate!)) {
        setState(() => _endDate = picked);
      }
      _applyFilter();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _applyFilter();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadOrders();
  }

  Future<void> _onSyncComplete() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Commandes Locales',
      activeRoute: '/local-orders',
      child: Column(
        children: [
          // 📊 Stats & Actions Bar
          _buildStatsBar(),

          // 🔍 Filter Bar
          _buildFilterBar(),

          // 📋 Orders List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS BAR
  // ============================================================

  Widget _buildStatsBar() {
    final totalOrders = _allOrders.length;
    final syncedOrders = _allOrders.where((o) => o.isDailySynced).length;
    final notSyncedOrders = totalOrders - syncedOrders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Stats cards row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$totalOrders',
                  Icons.receipt_long,
                  SushiColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Synchronisées',
                  '$syncedOrders',
                  Icons.cloud_done,
                  SushiColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  '$notSyncedOrders',
                  Icons.cloud_upload,
                  SushiColors.orange,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _onSyncComplete,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Rafraîchir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SushiColors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          // Date range indicator
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SushiColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SushiColors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: SushiColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    _getDateRangeLabel(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SushiColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_startDate != null && _endDate != null) {
      if (_startDate == _endDate) {
        return 'Période : ${DateFormat('dd/MM/yyyy').format(_startDate!)}';
      }
      return 'Période : ${DateFormat('dd/MM/yyyy').format(_startDate!)} → ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'À partir du : ${DateFormat('dd/MM/yyyy').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Jusqu\'au : ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
    return '';
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filters
          Row(
            children: [
              const Text(
                'Filtres :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              _filterChip('Toutes', 'all', Icons.list),
              const SizedBox(width: 8),
              _filterChip("Aujourd'hui", 'today', Icons.today),
              const SizedBox(width: 8),
              _filterChip('Synchronisées', 'synced', Icons.cloud_done),
              const SizedBox(width: 8),
              _filterChip('Non synchronisées', 'not_synced', Icons.cloud_off),
            ],
          ),
          const SizedBox(height: 12),
          // Date range picker
          Row(
            children: [
              const Text(
                'Période :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : 'Date début',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _startDate != null
                        ? SushiColors.teal
                        : Colors.grey.shade600,
                    side: BorderSide(
                      color: _startDate != null
                          ? SushiColors.teal
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '→',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : 'Date fin',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _endDate != null
                        ? SushiColors.teal
                        : Colors.grey.shade600,
                    side: BorderSide(
                      color: _endDate != null
                          ? SushiColors.teal
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Effacer la période',
                  color: Colors.red,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Channel & Type filters
          Row(
            children: [
              const Text(
                'Canal :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter(
                  value: _selectedChannel ?? 'all',
                  items: {
                    'all': 'Tous',
                    'pos': OrderDisplayLabels.channelLabel('pos'),
                    'api': OrderDisplayLabels.channelLabel('api'),
                    'web': OrderDisplayLabels.channelLabel('web'),
                    'kiosk': OrderDisplayLabels.channelLabel('kiosk'),
                  },
                  onChanged: (val) {
                    setState(
                      () => _selectedChannel = val == 'all' ? null : val,
                    );
                    _applyFilter();
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Type :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter(
                  value: _selectedType ?? 'all',
                  items: {
                    'all': 'Tous',
                    'on_site': OrderDisplayLabels.typeLabel('on_site'),
                    'pickup': OrderDisplayLabels.typeLabel('pickup'),
                    'delivery': OrderDisplayLabels.typeLabel('delivery'),
                  },
                  onChanged: (val) {
                    setState(() => _selectedType = val == 'all' ? null : val);
                    _applyFilter();
                  },
                ),
              ),
              if (_selectedChannel != null || _selectedType != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearChannelAndTypeFilters,
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Effacer les filtres',
                  color: Colors.red,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  void _clearChannelAndTypeFilters() {
    setState(() {
      _selectedChannel = null;
      _selectedType = null;
    });
    _applyFilter();
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final isSelected = _filter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      onSelected: (_) => _setFilter(value),
      selectedColor: SushiColors.teal.withOpacity(0.2),
      checkmarkColor: SushiColors.teal,
      labelStyle: TextStyle(
        color: isSelected ? SushiColors.teal : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Filtre actif : ${_getFilterLabel()}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_filter) {
      case 'synced':
        return 'Synchronisées';
      case 'not_synced':
        return 'Non synchronisées';
      case 'today':
        return "Aujourd'hui";
      default:
        return 'Toutes';
    }
  }

  // ============================================================
  // ORDERS LIST
  // ============================================================

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(PosOrder order) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CMD #${order.sourceLocalId ?? order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      _buildTypeChip(order.fulfillmentType),
                      const SizedBox(width: 6),
                      _buildChannelChip(order.channel),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${order.totalPrice.toStringAsFixed(2)} DH',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: SushiColors.teal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                timeFormat.format(order.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(order.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              _buildSyncBadge(order.isDailySynced),
            ],
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [_buildOrderDetails(order)],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    IconData icon;
    Color color;
    String label;

    switch (type.toLowerCase()) {
      case 'on_site':
        icon = Icons.restaurant;
        color = Colors.blue;
        label = OrderDisplayLabels.typeLabel('on_site');
        break;
      case 'pickup':
        icon = Icons.shopping_bag;
        color = Colors.orange;
        label = OrderDisplayLabels.typeLabel('pickup');
        break;
      case 'delivery':
        icon = Icons.local_shipping;
        color = Colors.purple;
        label = 'Livraison';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelChip(String channel) {
    IconData icon;
    Color color;
    String label;

    switch (channel.toLowerCase()) {
      case 'pos':
        icon = Icons.point_of_sale;
        color = Colors.teal;
        label = OrderDisplayLabels.channelLabel('pos');
        break;
      case 'web':
        icon = Icons.web;
        color = Colors.blue;
        label = OrderDisplayLabels.channelLabel('web');
        break;
      case 'api':
        icon = Icons.api;
        color = Colors.indigo;
        label = OrderDisplayLabels.channelLabel('api');
        break;
      case 'kiosk':
        icon = Icons.desktop_windows;
        color = Colors.deepOrange;
        label = OrderDisplayLabels.channelLabel('kiosk');
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        label = channel.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBadge(bool isSynced) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced
            ? Colors.green.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.check_circle : Icons.pending,
            size: 12,
            color: isSynced ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Sync' : 'En attente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSynced ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(PosOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _detailRow('Statut', _getStatusLabel(order.status)),
        _detailRow('Type', OrderDisplayLabels.typeLabel(order.fulfillmentType)),
        _detailRow('Canal', OrderDisplayLabels.channelLabel(order.channel)),
        _detailRow('Statut paiement', _paymentStatusLabel(order.paymentStatus)),
        if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
          _detailRow('Méthode paiement', _paymentMethodLabel(order.paymentMethod)),
        _detailRow('Total', '${order.totalPrice.toStringAsFixed(2)} DH'),
        if (order.originalTotal > 0)
          _detailRow('Total initial', '${order.originalTotal.toStringAsFixed(2)} DH'),
        if (order.hasDiscount && order.discountAmount > 0)
          _detailRow('Remise', '-${order.discountAmount.toStringAsFixed(2)} DH'),
        if (order.rewardId != null)
          _detailRow('Récompense', '#${order.rewardId}'),
        _detailRow('Serveur', _staffNames[order.staffId] ?? 'ID ${order.staffId}'),
        if (order.customerName != null)
          _detailRow('Client', order.customerName!),
        if (order.customerPhone != null)
          _detailRow('Téléphone', order.customerPhone!),
        if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
          _detailRow('Adresse', order.deliveryAddress!),
        if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
          _detailRow('Table', order.tableNumber!),
        if (order.note != null && order.note!.isNotEmpty)
          _detailRow('Note', order.note!),
        if (order.cancelReason != null && order.cancelReason!.isNotEmpty)
          _detailRow('Annulation', order.cancelReason!),
        if (order.restaurantId != null)
          _detailRow('Restaurant', _restaurantNames[order.restaurantId] ?? 'ID ${order.restaurantId}'),
        if (order.sourceLocalId != null)
          _detailRow('Source commande', order.sourceLocalId!.toString()),
        _detailRow('Créée', DateFormat.yMd().add_Hm().format(order.createdAt)),
        _detailRow('Mise à jour', DateFormat.yMd().add_Hm().format(order.updatedAt)),
        const SizedBox(height: 8),
        if (order.isDailySynced)
          Row(
            children: [
              Icon(Icons.check, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Synchronisé',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _paymentStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return 'Payée';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulée';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _paymentMethodLabel(String? method) {
    if (method == null || method.trim().isEmpty) return '-';
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'card':
      case 'credit_card':
      case 'credit card':
        return 'Carte';
      case 'split':
        return 'Paiement multiple';
      default:
        return method;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.cyan;
      case 'paid':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check;
      case 'paid':
        return Icons.payment;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'paid':
        return 'Payée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
