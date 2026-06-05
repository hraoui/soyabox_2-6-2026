import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../models/delivery.dart';
import '../models/pos_order.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/order_sync_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/payment_method_utils.dart';
import '../utils/order_item_dedup.dart';
import '../utils/order_display_labels.dart';
import '../widgets/admin_shell.dart';
import '../widgets/unified_payment_dialog.dart';

// ─── Palette Rouge Tactile ──────────────────────────────────────────────────
class _R {
  static const primary = Color(0xFFD32F2F);
  static const dark = Color(0xFFB71C1C);
  static const light = Color(0xFFEF5350);
  static const surface = Color(0xFFF5F5F5);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0E0E0);
  static const text = Color(0xFF212121);
  static const muted = Color(0xFF757575);

  // Status colors
  static const all = Color(0xFF1976D2);
  static const pending = Color(0xFFFF9800);
  static const confirmed = Color(0xFF2196F3);
  static const preparing = Color(0xFF9C27B0);
  static const ready = Color(0xFF00BCD4);
  static const delivered = Color(0xFF4CAF50);
  static const cancelled = Color(0xFFF44336);
}
// ────────────────────────────────────────────────────────────────────────────

// ─── Dimensions optimisées pour Grid 3 colonnes (1024×768) ─────────────────
class _D {
  static const double filterHeight = 68.0;
  static const double buttonSize = 30.0; // ⬇️ Ajusté pour 3 colonnes
  static const double iconSize = 14.0; // ⬇️ Ajusté
  static const double radius = 8.0;
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 8, // ⬇️ Réduit pour plus d'espace contenu
    vertical: 8,
  );
}
// ────────────────────────────────────────────────────────────────────────────

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'all';
  String? _selectedServerFilter;
  int? _adminRestaurantId;
  DateTime _selectedDate = DateTime.now(); // ✅ Date sélectionnée
  bool _localesInitialized = false; // ✅ Suivi de l'initialisation des locales

  List<PosOrder> _allOrders = [];
  List<PosOrder> _filteredOrders = [];
  List<User> _servers = [];
  List<Delivery> _livreurs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // ✅ Initialiser les données de locale pour le formatage des dates
    initializeDateFormatting('fr_FR', null).then((_) {
      setState(() {
        _localesInitialized = true;
      });
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final auth = Get.find<AuthController>();
      _adminRestaurantId = auth.currentUser?.restaurantId;

      // ✅ Charger les commandes pour la date sélectionnée
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final allOrders = await DatabaseService.getPosOrdersByDateRange(
        startOfDay,
        endOfDay,
      );

      List<PosOrder> orders;
      if (_adminRestaurantId != null) {
        orders = allOrders.where((o) {
          if (o.restaurantId == null) return true;
          return o.restaurantId == _adminRestaurantId;
        }).toList();
      } else {
        orders = allOrders;
      }

      List<User> allUsers;
      if (_adminRestaurantId != null) {
        allUsers = await DatabaseService.getUsersByRestaurant(
          _adminRestaurantId,
        );
      } else {
        allUsers = await DatabaseService.getAllUsers();
      }

      List<Delivery> livreurs;
      if (_adminRestaurantId != null) {
        livreurs = await DatabaseService.getDeliveriesByRestaurant(
          _adminRestaurantId!,
        );
      } else {
        livreurs = await DatabaseService.getAllDeliveries();
      }

      setState(() {
        _allOrders = orders;
        _servers = allUsers.where((u) {
          final role = u.role.toLowerCase();
          return (role == 'staff' || role == 'admin') && u.isActive;
        }).toList();
        _livreurs = livreurs;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Get.snackbar('Erreur', 'Impossible de charger les commandes');
    }
  }

  void _applyFilters() {
    var filtered = _allOrders.where((o) => _matchesFilter(o, _selectedFilter));

    if (_selectedServerFilter != null && _selectedServerFilter!.isNotEmpty) {
      final serverId = int.tryParse(_selectedServerFilter!);
      if (serverId != null) {
        filtered = filtered.where((o) {
          final channel = o.channel.toLowerCase();
          return channel == 'pos' && o.staffId == serverId;
        });
      }
    }

    _filteredOrders = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _selectFilter(String value) {
    setState(() {
      _selectedFilter = value;
      _applyFilters();
    });
  }

  void _selectServerFilter(String? serverId) {
    setState(() {
      _selectedServerFilter = serverId;
      _applyFilters();
    });
  }

  bool _matchesFilter(PosOrder order, String filter) {
    final status = order.status.trim().toLowerCase();
    final channel = order.channel.trim().toLowerCase();
    switch (filter) {
      case 'pending':
        return status == 'pending';
      case 'confirmed':
        return status == 'confirmed';
      case 'preparing':
        return status == 'preparing';
      case 'ready':
        return status == 'ready';
      case 'delivered':
        return status == 'delivered' || status == 'paid';
      case 'cancelled':
        return status == 'cancelled' || status == 'canceled';
      case 'pos':
        return channel == 'pos';
      case 'remote':
        return channel != 'pos';
      default:
        return true;
    }
  }

  int _countFor(String f) =>
      _allOrders.where((o) => _matchesFilter(o, f)).length;

  // ✅ Sélecteur de date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadData(); // Recharger les données pour la nouvelle date
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ✅ Widget du sélecteur de date
  Widget _buildDateSelector() {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final displayDate = dateFormat.format(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final totalOrders = _allOrders.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _R.card,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: _R.primary),
          const SizedBox(width: 8),
          Text(
            isToday ? "Aujourd'hui" : displayDate,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _R.text,
            ),
          ),
          const SizedBox(width: 8),
          // ✅ Badge avec le nombre de commandes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _R.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _R.primary.withOpacity(0.3)),
            ),
            child: Text(
              '$totalOrders commande${totalOrders > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _R.primary,
              ),
            ),
          ),
          const Spacer(),
          // Bouton jour précédent
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
            tooltip: 'Jour précédent',
            color: _R.primary,
          ),
          // Bouton aujourd'hui
          if (!isToday)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
                _loadData();
              },
              icon: const Icon(Icons.today, size: 16),
              label: const Text("Aujourd'hui"),
              style: TextButton.styleFrom(
                foregroundColor: _R.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          // Bouton jour suivant
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _selectedDate.isBefore(DateTime.now())
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                    _loadData();
                  }
                : null,
            tooltip: 'Jour suivant',
            color: _R.primary,
          ),
          const SizedBox(width: 4),
          // Bouton calendrier
          OutlinedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.edit_calendar, size: 16),
            label: const Text('Choisir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _R.primary,
              side: BorderSide(color: _R.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Gestion des Commandes',
      activeRoute: '/admin-orders',
      child: Container(
        color: _R.surface,
        child: Column(
          children: [
            // ✅ N'afficher le sélecteur de date que si les locales sont initialisées
            if (_localesInitialized) _buildDateSelector(),
            _buildFilterBar(),
            _buildServerFilterBar(),
            const Divider(height: 1),
            Expanded(
              child: ClipRect(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _R.primary),
                      )
                    : _filteredOrders.isEmpty
                    ? _emptyState()
                    : _buildOrdersGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      _FilterItem('all', 'Toutes', _R.all, Icons.list),
      _FilterItem('pending', 'En attente', _R.pending, Icons.schedule),
      _FilterItem(
        'confirmed',
        'Confirmées',
        _R.confirmed,
        Icons.check_circle_outline,
      ),
      _FilterItem(
        'preparing',
        'En préparation',
        _R.preparing,
        Icons.restaurant,
      ),
      _FilterItem('ready', 'Prêtes', _R.ready, Icons.check_circle),
      _FilterItem('delivered', 'Livrées', _R.delivered, Icons.delivery_dining),
      _FilterItem('cancelled', 'Annulées', _R.cancelled, Icons.cancel),
      _FilterItem('pos', 'POS', _R.primary, Icons.point_of_sale),
      _FilterItem('remote', 'Web/Mobile', _R.light, Icons.smartphone),
    ];

    return Container(
      height: _D.filterHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _R.card,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f.id;
          return _FilterChip(
            label: f.label,
            count: _countFor(f.id),
            color: f.color,
            icon: f.icon,
            isSelected: isSelected,
            onTap: () => _selectFilter(f.id),
          );
        },
      ),
    );
  }

  Widget _buildServerFilterBar() {
    final posOrders = _allOrders
        .where((o) => o.channel.toLowerCase() == 'pos')
        .toList();
    final serverCounts = <int, int>{};
    for (var order in posOrders) {
      serverCounts[order.staffId] = (serverCounts[order.staffId] ?? 0) + 1;
    }

    if (posOrders.isEmpty || _servers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _R.card,
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18, color: _R.muted),
          const SizedBox(width: 8),
          const Text(
            'Filtrer par serveur:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _R.text,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedServerFilter?.isNotEmpty ?? false
                  ? _selectedServerFilter
                  : null,
              hint: const Text(
                'Tous les serveurs',
                style: TextStyle(fontSize: 12),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Tous', style: TextStyle(fontSize: 12)),
                ),
                ..._servers.map((server) {
                  final count = serverCounts[server.id] ?? 0;
                  return DropdownMenuItem<String>(
                    value: server.id.toString(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            server.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _R.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _R.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) => _selectServerFilter(value),
              underline: const SizedBox.shrink(),
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: _R.primary,
              ),
            ),
          ),
          if (_selectedServerFilter != null &&
              _selectedServerFilter!.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _selectServerFilter(null),
              tooltip: 'Effacer le filtre',
              color: _R.muted,
            ),
          ],
        ],
      ),
    );
  }

  // ✅ GRID FIXE : 3 colonnes toujours, aspect ratio optimisé
  Widget _buildOrdersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // ✅ Toujours 3 cartes par ligne
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0, // ✅ Ajusté pour éviter overflow vertical
      ),
      itemCount: _filteredOrders.length,
      itemBuilder: (_, i) => _OrderCard(
        order: _filteredOrders[i],
        onTapDetails: () => _showOrderDetails(_filteredOrders[i]),
        onTapStatus: () => _showStatusMenu(_filteredOrders[i]),
        onTapCancel: () => _cancelOrder(_filteredOrders[i]),
        onTapAssignLivreur: _filteredOrders[i].fulfillmentType == 'delivery'
            ? () => _showAssignLivreurDialog(_filteredOrders[i])
            : null,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _R.card,
          borderRadius: BorderRadius.circular(_D.radius),
          border: Border.all(color: _R.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: _R.muted),
            const SizedBox(height: 24),
            const Text(
              'Aucune commande',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _R.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune commande ne correspond au filtre sélectionné',
              style: TextStyle(fontSize: 14, color: _R.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getServerName(int staffId) {
    final s = _servers.firstWhere(
      (s) => s.id == staffId,
      orElse: () => User(
        id: staffId,
        name: 'Serveur #$staffId',
        email: '',
        role: 'staff',
        password: '',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
    );
    return s.name.isEmpty ? 'Serveur #$staffId' : s.name;
  }

  bool _isRemoteChannel(String rawChannel) {
    final channel = rawChannel.trim().toLowerCase();
    switch (channel) {
      case 'api':
      case 'web':
      case 'website':
      case 'site':
      case 'online':
      case 'mobile':
      case 'mobile_app':
      case 'app':
      case 'android':
      case 'ios':
      case 'kiosk':
      case 'borne':
        return true;
      default:
        return false;
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _updateOrderStatus(PosOrder order, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Text(
          'Voulez-vous vraiment passer la commande #${order.id} en "${_labelStatus(newStatus)}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      order.status = newStatus;
      if (newStatus == 'delivered' || newStatus == 'paid') {
        order.paymentStatus = 'paid';
      }
      order.updatedAt = DateTime.now();
      await DatabaseService.updatePosOrder(order);

      final isRemote = _isRemoteChannel(order.channel);
      if (isRemote) {
        OrderSyncService()
            .syncOrderStatusWithRetry(
              orderId: order.id,
              status: newStatus,
              paymentStatus: order.paymentStatus,
            )
            .then((success) {
              if (!success && mounted) {
                OrderSyncService().queueStatusSync(
                  orderId: order.id,
                  status: newStatus,
                  paymentStatus: order.paymentStatus,
                );
              }
            });
      } else {
        final items = await DatabaseService.getPosOrderItems(order.id);
        await SyncQueueService.instance.enqueueOrderUpsert(order, items);
      }

      setState(() => _applyFilters());

      Get.snackbar(
        'Succès',
        'Statut mis à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _cancelOrder(PosOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler la commande #${order.id} ?\n\nSeul un administrateur peut annuler une commande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    String? cancelReason;
    cancelReason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Raison de l\'annulation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Erreur, annulation client, etc.',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Sans raison'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                controller.text.isEmpty
                    ? 'Annulée par administrateur'
                    : controller.text,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    try {
      order.status = 'cancelled';
      order.cancelReason = cancelReason?.isEmpty ?? true
          ? 'Annulée par administrateur'
          : cancelReason;
      order.updatedAt = DateTime.now();
      await DatabaseService.updatePosOrder(order);

      final isRemote = _isRemoteChannel(order.channel);
      if (isRemote) {
        OrderSyncService()
            .syncOrderStatusWithRetry(
              orderId: order.id,
              status: 'cancelled',
              cancelReason: order.cancelReason,
            )
            .then((success) {
              if (!success && mounted) {
                OrderSyncService().queueStatusSync(
                  orderId: order.id,
                  status: 'cancelled',
                  cancelReason: order.cancelReason,
                );
              }
            });
      } else {
        final items = await DatabaseService.getPosOrderItems(order.id);
        await SyncQueueService.instance.enqueueOrderUpsert(order, items);
      }

      setState(() => _applyFilters());

      Get.snackbar(
        'Commande annulée',
        'La commande #${order.id} a été annulée',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Erreur', 'Erreur: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─── Assigner livreur ─────────────────────────────────────────────────────
  void _showAssignLivreurDialog(PosOrder order) async {
    if (_livreurs.isEmpty) {
      if (!mounted) return;
      Get.snackbar(
        'Aucun livreur',
        'Veuillez créer un livreur d\'abord',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final selectedLivreur = await showDialog<Delivery>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: _R.primary),
            SizedBox(width: 8),
            Text('Assigner un livreur'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commande #${order.id} — ${_moneyStatic(order.totalPrice)}',
                style: const TextStyle(fontSize: 13, color: _R.muted),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sélectionnez un livreur :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _R.text,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    border: Border.all(color: _R.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _livreurs.length,
                    itemBuilder: (ctx, index) {
                      final livreur = _livreurs[index];
                      final isCurrentlyAssigned =
                          order.deliveryLivreurId == livreur.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentlyAssigned
                              ? _R.primary.withOpacity(0.1)
                              : _R.surface,
                          child: Text(
                            livreur.name.isNotEmpty
                                ? livreur.name[0].toUpperCase()
                                : 'L',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentlyAssigned
                                  ? _R.primary
                                  : _R.muted,
                            ),
                          ),
                        ),
                        title: Text(livreur.name),
                        subtitle: Text(
                          livreur.phone.isNotEmpty
                              ? livreur.phone
                              : 'Pas de numéro',
                        ),
                        trailing: isCurrentlyAssigned
                            ? const Icon(
                                Icons.check_circle,
                                color: _R.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, livreur),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedLivreur == null || !mounted) return;

    await _assignLivreur(order, selectedLivreur);
  }

  Future<void> _assignLivreur(PosOrder order, Delivery livreur) async {
    try {
      if (Get.isRegistered<PosController>()) {
        final posCtrl = Get.find<PosController>();
        await posCtrl.assignLivreurToOrder(
          order: order,
          livreurId: livreur.id,
          livreurName: livreur.name,
          livreurPhone: livreur.phone,
        );
      } else {
        order.deliveryLivreurId = livreur.id;
        order.deliveryLivreurName = livreur.name;
        order.updatedAt = DateTime.now();
        await DatabaseService.updatePosOrder(order);
      }

      final isRemote = _isRemoteChannel(order.channel);
      if (isRemote) {
        OrderSyncService()
            .syncOrderStatusWithRetry(
              orderId: order.id,
              status: order.status,
              deliveryStatus: 'assigned',
            )
            .then((success) {
              if (!success && mounted) {
                OrderSyncService().queueStatusSync(
                  orderId: order.id,
                  status: order.status,
                  deliveryStatus: 'assigned',
                );
              }
            });
      }

      setState(() => _applyFilters());

      if (!mounted) return;
      Get.snackbar(
        'Livreur assigné',
        '${livreur.name} a été assigné à la commande #${order.id}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Erreur',
        'Impossible d\'assigner le livreur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _refreshOrderAfterPaymentChange(PosOrder order) async {
    final updatedOrder = await DatabaseService.getPosOrderById(order.id);
    if (updatedOrder != null) {
      order.paymentMethod = updatedOrder.paymentMethod;
      order.paymentStatus = updatedOrder.paymentStatus;
      order.discountAmount = updatedOrder.discountAmount;
      order.hasDiscount = updatedOrder.hasDiscount;
      order.totalPrice = updatedOrder.totalPrice;
      order.originalTotal = updatedOrder.originalTotal;
      if (mounted) setState(() {});
    }
  }

  bool _canModifyPayment(PosOrder order) {
    final status = order.paymentStatus.trim().toLowerCase();
    return status == 'paid' || status == 'partially_paid';
  }

  void _showStatusMenu(PosOrder order) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final relativeRect = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: relativeRect,
      items: [
        const PopupMenuItem(value: 'pending', child: Text('En attente')),
        const PopupMenuItem(value: 'confirmed', child: Text('Confirmée')),
        const PopupMenuItem(value: 'preparing', child: Text('En préparation')),
        const PopupMenuItem(value: 'ready', child: Text('Prête')),
        const PopupMenuItem(value: 'delivered', child: Text('Livrée')),
        const PopupMenuItem(value: 'paid', child: Text('Payée')),
        const PopupMenuItem(value: 'cancelled', child: Text('Annulée')),
      ],
    ).then((value) {
      if (value != null) _updateOrderStatus(order, value);
    });
  }

  Future<void> _showOrderDetails(PosOrder order) async {
    var items = await DatabaseService.getPosOrderItems(order.id);
    if (items.isEmpty) {
      final allItems = await DatabaseService.getAllPosOrderItems();
      items = allItems.where((item) => item.orderId == order.id).toList();
    }

    items = deduplicateOrderItems(items);

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
          child: Container(
            decoration: BoxDecoration(
              color: _R.card,
              borderRadius: BorderRadius.circular(_D.radius),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor(order.status),
                        _statusColor(order.status).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_D.radius),
                      topRight: Radius.circular(_D.radius),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #${order.id}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _statusBadge(
                            _labelStatus(order.status),
                            Colors.white,
                          ),
                          _statusBadge(
                            OrderDisplayLabels.channelLabel(order.channel),
                            Colors.white70,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                          title: 'Informations client',
                          children: [
                            _detailRow(
                              Icons.person_outline,
                              'Client',
                              order.customerName ?? 'Non renseigné',
                            ),
                            _detailRow(
                              Icons.call_outlined,
                              'Téléphone',
                              order.customerPhone ?? '-',
                            ),
                            _detailRow(
                              Icons.badge_outlined,
                              'Serveur',
                              _getServerName(order.staffId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          title: 'Détails de la commande',
                          children: [
                            _detailRow(
                              Icons.schedule_outlined,
                              'Date',
                              '${order.createdAt.toLocal()}',
                            ),
                            _detailRow(
                              Icons.location_on_outlined,
                              'Type',
                              OrderDisplayLabels.typeLabel(
                                order.fulfillmentType,
                              ),
                            ),
                            if (order.tableNumber?.isNotEmpty ?? false)
                              _detailRow(
                                Icons.table_restaurant_outlined,
                                'Table',
                                order.tableNumber!,
                              ),
                            if (order.deliveryAddress?.isNotEmpty ?? false)
                              _detailRow(
                                Icons.home_outlined,
                                'Adresse',
                                order.deliveryAddress!,
                              ),
                            if (order.note?.isNotEmpty ?? false)
                              _detailRow(
                                Icons.note_outlined,
                                'Note',
                                order.note!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          title: 'Articles (${items.length})',
                          children: items.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                      child: Text(
                                        'Aucun article',
                                        style: TextStyle(color: _R.muted),
                                      ),
                                    ),
                                  ),
                                ]
                              : items.map((item) {
                                  final serviceCourseLabel =
                                      _serviceCourseLabel(
                                        item.serviceCourseKey,
                                      );
                                  final groupLabel =
                                      item.groupLabel?.trim().isNotEmpty == true
                                      ? item.groupLabel!.trim()
                                      : (item.groupNumber != null &&
                                                item.groupNumber! > 0
                                            ? 'Ensemble ${item.groupNumber}'
                                            : null);
                                  final hasNote =
                                      item.itemNote?.trim().isNotEmpty ?? false;
                                  final hasMeta =
                                      serviceCourseLabel != null ||
                                      groupLabel != null ||
                                      hasNote;

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: _R.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _R.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _R.text,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (item
                                                          .priceType
                                                          ?.isNotEmpty ??
                                                      false)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        item.priceType!,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: _R.muted,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'x${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: _R.primary,
                                                  ),
                                                ),
                                                Text(
                                                  _money(
                                                    item.quantity *
                                                        item.unitPrice,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _R.dark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (hasMeta) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              if (serviceCourseLabel != null)
                                                _itemBadge(
                                                  Icons.restaurant_outlined,
                                                  serviceCourseLabel,
                                                  color: Colors.deepPurple,
                                                  background: Colors.deepPurple
                                                      .withOpacity(0.12),
                                                ),
                                              if (groupLabel != null)
                                                _itemBadge(
                                                  Icons.group_outlined,
                                                  groupLabel,
                                                  color: Colors.teal.shade700,
                                                  background:
                                                      Colors.teal.shade100,
                                                ),
                                              if (hasNote)
                                                _itemBadge(
                                                  Icons.note_outlined,
                                                  item.itemNote!,
                                                  color: Colors.orange.shade800,
                                                  background:
                                                      Colors.orange.shade50,
                                                  maxWidth: 240,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          title: 'Paiement',
                          children: [
                            _detailRow(
                              Icons.payment_outlined,
                              'Méthode',
                              paymentMethodLabel(order.paymentMethod),
                            ),
                            _detailRow(
                              Icons.check_circle_outline,
                              'Statut',
                              order.paymentStatus == 'paid'
                                  ? 'Payé'
                                  : 'Non payé',
                            ),
                            const Divider(height: 24),
                            if (order.hasDiscount && order.discountAmount > 0)
                              _detailRow(
                                Icons.discount_outlined,
                                'Remise',
                                '-${_money(order.discountAmount)}',
                                valueColor: Colors.green,
                              ),
                            _detailRow(
                              Icons.attach_money,
                              'Total',
                              _money(order.totalPrice),
                              valueColor: _R.dark,
                              valueWeight: FontWeight.bold,
                              valueSize: 20,
                            ),
                          ],
                        ),
                        if (order.cancelReason?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            title: 'Raison d\'annulation',
                            children: [
                              Text(
                                order.cancelReason!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _R.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _R.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(_D.radius),
                      bottomRight: Radius.circular(_D.radius),
                    ),
                    border: Border(top: BorderSide(color: _R.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_canModifyPayment(order)) ...[
                        TextButton(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: dialogContext,
                              builder: (_) => UnifiedPaymentDialog(
                                order: order,
                                pos: Get.find<PosController>(),
                                showEditOption: true,
                              ),
                            );
                            if (result == true) {
                              await _refreshOrderAfterPaymentChange(order);
                            } else {
                              await _refreshOrderAfterPaymentChange(order);
                            }
                          },
                          child: const Text('Modifier paiement'),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _R.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _R.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _R.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueWeight = FontWeight.normal,
    double valueSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _R.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _R.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    color: valueColor ?? _R.text,
                    fontWeight: valueWeight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _labelStatus(String v) {
    switch (v.trim().toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'Préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
      case 'paid':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return v;
    }
  }

  Color _statusColor(String v) {
    switch (v.trim().toLowerCase()) {
      case 'pending':
        return _R.pending;
      case 'confirmed':
        return _R.confirmed;
      case 'preparing':
        return _R.preparing;
      case 'ready':
        return _R.ready;
      case 'delivered':
      case 'paid':
        return _R.delivered;
      case 'cancelled':
        return _R.cancelled;
      default:
        return _R.primary;
    }
  }

  String? _serviceCourseLabel(String? serviceCourseKey) {
    if (serviceCourseKey == null || serviceCourseKey.trim().isEmpty)
      return null;
    switch (serviceCourseKey.trim().toLowerCase()) {
      case 'starter':
        return 'Entrée';
      case 'main':
        return 'Plat principal';
      case 'cheese':
        return 'Suite & sortie';
      case 'dessert':
        return 'Dessert';
      case 'drink':
        return 'Boisson';
      case 'other':
        return 'Autre';
      default:
        return serviceCourseKey.trim();
    }
  }

  Widget _itemBadge(
    IconData icon,
    String label, {
    required Color color,
    required Color background,
    double maxWidth = 180,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double amount) => '${amount.toStringAsFixed(2)} DH';
}

// ─── Filter Chip Widget ─────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_D.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                : null,
            color: isSelected ? null : _R.card,
            borderRadius: BorderRadius.circular(_D.radius),
            border: Border.all(
              color: isSelected ? color : _R.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.25)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : _R.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white24 : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Card Widget (CORRIGÉ - SANS OVERFLOW) ────────────────────────────
class _OrderCard extends StatelessWidget {
  final PosOrder order;
  final VoidCallback onTapDetails;
  final VoidCallback onTapStatus;
  final VoidCallback onTapCancel;
  final VoidCallback? onTapAssignLivreur;

  const _OrderCard({
    required this.order,
    required this.onTapDetails,
    required this.onTapStatus,
    required this.onTapCancel,
    this.onTapAssignLivreur,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorStatic(order.status);

    return Container(
      decoration: BoxDecoration(
        color: _R.card,
        borderRadius: BorderRadius.circular(_D.radius),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: _D.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ Évite overflow vertical
          children: [
            // ── Row 1: ID + Status badges ───────────────────────────────────
            Row(
              children: [
                Flexible(
                  // ✅ Flexible pour éviter overflow horizontal
                  child: Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _R.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChip(
                          _labelStatusStatic(order.status),
                          statusColor,
                        ),
                        const SizedBox(width: 3),
                        _statusChip(
                          OrderDisplayLabels.channelLabel(order.channel),
                          _R.muted,
                        ),
                        if (order.hasDiscount && order.discountAmount > 0) ...[
                          const SizedBox(width: 3),
                          _statusChip('Remise', Colors.green),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Row 2: Amount + Action buttons ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // ✅ Important pour Wrap
              children: [
                // ── Montant + Date (Flexible pour s'adapter) ───────────────
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        // ✅ Scale down si texte trop long
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _moneyStatic(order.totalPrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _R.dark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Flexible(
                        child: Text(
                          _formatCardDateStatic(order.createdAt),
                          style: const TextStyle(
                            fontSize: 9,
                            color: _R.muted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Boutons d'action (Wrap pour éviter overflow) ───────────
                Flexible(
                  child: Wrap(
                    // ✅ Wrap au lieu de Row : passe à la ligne si besoin
                    spacing: 2, // Espacement horizontal entre boutons
                    runSpacing: 2, // Espacement vertical si wrap
                    alignment: WrapAlignment.end,
                    children: [
                      _actionButton(
                        Icons.visibility,
                        'Détails',
                        onTapDetails,
                        _R.primary,
                      ),
                      _actionButton(
                        Icons.edit,
                        'Statut',
                        onTapStatus,
                        _R.primary,
                      ),
                      if (onTapAssignLivreur != null) ...[
                        _actionButton(
                          order.deliveryLivreurId != null
                              ? Icons.person_add
                              : Icons.person_add_outlined,
                          order.deliveryLivreurId != null
                              ? 'Changer'
                              : 'Livreur',
                          onTapAssignLivreur!,
                          order.deliveryLivreurId != null
                              ? Colors.teal.shade700
                              : Colors.orange.shade700,
                        ),
                      ],
                      if (order.status != 'cancelled') ...[
                        _actionButton(
                          Icons.cancel_outlined,
                          'Annuler',
                          onTapCancel,
                          Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8, // ⬇️ Police légèrement réduite pour 3 colonnes
          fontWeight: FontWeight.bold,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: _D.buttonSize,
          height: _D.buttonSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: _D.iconSize, color: color),
        ),
      ),
    );
  }
}

// ─── Helpers Static ─────────────────────────────────────────────────────────
String _labelStatusStatic(String v) {
  switch (v.trim().toLowerCase()) {
    case 'pending':
      return 'En attente';
    case 'confirmed':
      return 'Confirmée';
    case 'preparing':
      return 'Préparation';
    case 'ready':
      return 'Prête';
    case 'delivered':
    case 'paid':
      return 'Livrée';
    case 'cancelled':
      return 'Annulée';
    default:
      return v;
  }
}

Color _statusColorStatic(String v) {
  switch (v.trim().toLowerCase()) {
    case 'pending':
      return _R.pending;
    case 'confirmed':
      return _R.confirmed;
    case 'preparing':
      return _R.preparing;
    case 'ready':
      return _R.ready;
    case 'delivered':
    case 'paid':
      return _R.delivered;
    case 'cancelled':
      return _R.cancelled;
    default:
      return _R.primary;
  }
}

String _moneyStatic(double amount) => '${amount.toStringAsFixed(2)} DH';

String _formatCardDateStatic(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

class _FilterItem {
  final String id;
  final String label;
  final Color color;
  final IconData icon;

  const _FilterItem(this.id, this.label, this.color, this.icon);
}
