import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/delivery_controller.dart';
import '../controllers/pos_controller.dart';
import '../models/delivery.dart';
import '../models/pos_order.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../utils/order_display_labels.dart';
import '../widgets/admin_shell.dart';

class AdminDeliveryAccountingScreen extends StatefulWidget {
  const AdminDeliveryAccountingScreen({super.key});

  @override
  State<AdminDeliveryAccountingScreen> createState() =>
      _AdminDeliveryAccountingScreenState();
}

class _AdminDeliveryAccountingScreenState
    extends State<AdminDeliveryAccountingScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<_DeliverySummary> _summaries = [];
  double _totalDeliveries = 0;
  double _totalRevenue = 0;

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
      // Vérifier si l'utilisateur est connecté
      if (!Get.isRegistered<AuthController>()) {
        debugPrint('❌ AuthController not registered');
        if (mounted) {
          Get.snackbar(
            'Non connecté',
            'Veuillez vous connecter d\'abord',
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAllNamed('/login');
        }
        return;
      }

      final auth = Get.find<AuthController>();
      final user = auth.currentUser;

      if (user == null) {
        debugPrint('❌ User not logged in');
        if (mounted) {
          Get.snackbar(
            'Non connecté',
            'Veuillez vous connecter d\'abord',
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAllNamed('/login');
        }
        return;
      }

      // Vérifier que c'est un admin
      if (user.role != 'admin' && user.role != 'superadmin') {
        debugPrint('❌ User role ${user.role} not allowed');
        if (mounted) {
          Get.snackbar(
            'Accès refusé',
            'Seuls les admins peuvent accéder à cette page',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        setState(() {
          _loading = false;
        });
        return;
      }

      debugPrint('✅ User authenticated: ${user.name} (${user.role})');

      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));

      // Charger les livraisons du restaurant
      final deliveries = await DatabaseService.getAllOrderDeliveries();

      debugPrint('📊 Total OrderDeliveries in DB: ${deliveries.length}');

      // Filtrer par date et restaurant
      final filteredDeliveries = deliveries.where((d) {
        if (d.assignedAt == null) {
          debugPrint('⚠️ Delivery ${d.id} has no assignedAt');
          return false;
        }
        if (d.assignedAt!.isBefore(start) || d.assignedAt!.isAfter(end)) {
          return false;
        }
        debugPrint(
          '✅ Delivery ${d.id} assigned at ${d.assignedAt} (livreur: ${d.livreurId})',
        );
        return true;
      }).toList();

      debugPrint(
        '📊 Filtered deliveries for ${_selectedDate.day}/${_selectedDate.month}: ${filteredDeliveries.length}',
      );

      // Charger les livreurs
      final deliveryPersons = await DatabaseService.getAllDeliveries();
      final deliveryById = <int, Delivery>{
        for (final d in deliveryPersons) d.id: d,
      };

      // Charger les commandes associées
      final orderIds = filteredDeliveries.map((d) => d.orderId).toSet();
      final orders = await DatabaseService.getPosOrders();
      final ordersById = <int, PosOrder>{
        for (final o in orders.where((o) => orderIds.contains(o.id))) o.id: o,
      };

      // Grouper par livreur
      final Map<int, _DeliverySummary> byLivreur = {};
      double totalDeliveries = 0;
      double totalRevenue = 0;

      for (final delivery in filteredDeliveries) {
        final livreurId = delivery.livreurId;
        if (livreurId == null) continue;

        final order = ordersById[delivery.orderId];

        // Exclure les commandes annulées de la comptabilité
        if (order != null) {
          final status = order.status.trim().toLowerCase();
          if (status == 'cancelled' || status == 'canceled') {
            debugPrint(
              '⚠️ Excluding cancelled order ${order.id} from delivery accounting',
            );
            continue;
          }
        }

        final revenue = order?.totalPrice ?? 0.0;

        if (!byLivreur.containsKey(livreurId)) {
          final livreur = deliveryById[livreurId];
          byLivreur[livreurId] = _DeliverySummary(
            livreurId: livreurId,
            livreurName: livreur?.name ?? 'Inconnu',
            livreurPhone: livreur?.phone ?? '',
            deliveriesCount: 0,
            revenue: 0,
            completedCount: 0,
            pendingCount: 0,
          );
        }

        byLivreur[livreurId]!.deliveriesCount++;
        byLivreur[livreurId]!.revenue += revenue;

        if (delivery.status == 'delivered') {
          byLivreur[livreurId]!.completedCount++;
        } else {
          byLivreur[livreurId]!.pendingCount++;
        }

        totalDeliveries++;
        totalRevenue += revenue;
      }

      setState(() {
        _summaries = byLivreur.values.toList();
        _totalDeliveries = totalDeliveries;
        _totalRevenue = totalRevenue;
        _loading = false;
      });
    } catch (e) {
      debugPrint('💥 Error loading delivery accounting: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  /// ✅ Créer un nouveau livreur
  void _createLivreur() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Créer un livreur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (name.isEmpty ||
                    phone.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty) {
                  Get.snackbar(
                    'Champs requis',
                    'Tous les champs sont obligatoires',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                  return;
                }

                final deliveryController = Get.find<DeliveryController>();
                final auth = Get.find<AuthController>();
                final restaurantId = auth.currentUser?.restaurantId ?? 1;

                final newDelivery = await deliveryController.createDelivery(
                  name: name,
                  phone: phone,
                  email: email,
                  password: password,
                  restaurantId: restaurantId,
                  isActive: true,
                );

                if (!mounted) return;

                if (newDelivery != null) {
                  Get.snackbar(
                    'Succès',
                    'Livreur $name créé avec succès',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                  _loadData();
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext, true);
                  }
                }
              } catch (e) {
                Get.snackbar(
                  'Erreur',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  /// Afficher toutes les commandes de livraison et permettre d'assigner un livreur
  Future<void> _showAllDeliveryOrders() async {
    // Charger toutes les commandes de livraison du jour
    final deliveryOrders = await DatabaseService.getAllDeliveryOrders(
      date: _selectedDate,
    );

    // Charger les livreurs disponibles
    final livreurs = await DatabaseService.getAllDeliveries();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: AppColors.burntOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigner un livreur',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charbon,
                                ),
                              ),
                              Text(
                                '${deliveryOrders.length} commande(s) de livraison',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grisModerne,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.grisLeger),
                  Expanded(
                    child: deliveryOrders.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune commande de livraison',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.grisModerne,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: deliveryOrders.length,
                            itemBuilder: (context, index) {
                              final order = deliveryOrders[index];
                              return _deliveryOrderTile(order, livreurs);
                            },
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

  /// Widget pour afficher une commande de livraison avec option d'assigner un livreur
  Widget _deliveryOrderTile(PosOrder order, List<Delivery> livreurs) {
    final hasLivreur = order.deliveryLivreurId != null;
    final auth = Get.find<AuthController>();
    final defaultRestaurantId = auth.currentUser?.restaurantId ?? 1;

    final assignedLivreur = livreurs.firstWhere(
      (l) => l.id == order.deliveryLivreurId,
      orElse: () => Delivery(
        name: order.deliveryLivreurName ?? 'Inconnu',
        phone: order.deliveryLivreurPhone ?? '',
        email: '',
        password: '',
        restaurantId: defaultRestaurantId,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasLivreur ? AppColors.grisPale : AppColors.blancPur,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasLivreur ? AppColors.grisLeger : AppColors.burntOrange,
          width: hasLivreur ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.burntOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.customerName ?? 'Client inconnu',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charbon,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${order.totalPrice.toStringAsFixed(0)}dh',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.burntOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer info
          if (order.customerPhone != null || order.deliveryAddress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.customerPhone != null &&
                    order.customerPhone!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 14,
                        color: AppColors.grisModerne,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.customerPhone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.charbon,
                        ),
                      ),
                    ],
                  ),
                if (order.deliveryAddress != null &&
                    order.deliveryAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.grisModerne,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.charbon,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          // Livreur assigné ou bouton d'assignation
          if (hasLivreur) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.grisLeger.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.grisModerne,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Livreur assigné',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.grisModerne,
                          ),
                        ),
                        Text(
                          assignedLivreur.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charbon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _changeLivreur(order, livreurs),
                    child: const Text('Changer'),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _assignLivreur(order, livreurs),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Assigner un livreur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Assigner un livreur à une commande
  Future<void> _assignLivreur(PosOrder order, List<Delivery> livreurs) async {
    if (livreurs.isEmpty) {
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
                  backgroundColor: AppColors.burntOrange.withOpacity(0.15),
                  child: Text(
                    livreur.name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.burntOrange),
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
      _loadData();
    } else {
      Get.snackbar(
        'Erreur',
        posController.error ?? 'Échec de l\'assignation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Changer le livreur d'une commande
  Future<void> _changeLivreur(PosOrder order, List<Delivery> livreurs) async {
    await _assignLivreur(order, livreurs);
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Comptabilité Livreurs',
      activeRoute: '/admin-delivery-accounting',
      child: Column(
        children: [
          // Header avec date et bouton
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
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                const SizedBox(width: 12),
                // ✅ Bouton Créer un livreur (Admin)
                ElevatedButton.icon(
                  onPressed: () => _createLivreur(),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text(
                    'Créer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ Bouton Assigner un livreur (pour toutes les commandes de livraison)
                OutlinedButton.icon(
                  onPressed: () => _showAllDeliveryOrders(),
                  icon: const Icon(Icons.delivery_dining, size: 16),
                  label: const Text(
                    'Assigner',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.burntOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: AppColors.burntOrange),
                  ),
                ),
                const Spacer(),
                // 📊 Stats
                _buildHeaderStat(
                  label: 'Livraisons',
                  value: _totalDeliveries.toString(),
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF1A9988),
                ),
                const SizedBox(width: 12),
                _buildHeaderStat(
                  label: 'CA Total',
                  value: '${_totalRevenue.toStringAsFixed(0)}dh',
                  icon: Icons.attach_money,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
          // 🎯 Grille des livreurs - 4 par ligne
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 48,
                          color: AppColors.grisModerne,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune livraison ce jour',
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
                        const Text(
                          'Livreurs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charbon,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLivreurGrid(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 Build 4-column grid for livreurs
  Widget _buildLivreurGrid() {
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
              child: _compactLivreurCard(summary),
            );
          }).toList(),
        );
      },
    );
  }

  // 🎯 Compact Livreur Card - 4 per row
  Widget _compactLivreurCard(_DeliverySummary summary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDeliveryDetails(summary),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.blancPur,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grisLeger),
            boxShadow: [
              BoxShadow(
                color: AppColors.burntOrange.withOpacity(0.1),
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
                    backgroundColor: AppColors.burntOrange.withOpacity(0.15),
                    child: Text(
                      summary.livreurName.isNotEmpty
                          ? summary.livreurName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.burntOrange,
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
                          summary.livreurName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.charbon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (summary.livreurPhone.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.burntOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              summary.livreurPhone,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.burntOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats: Nombre de commandes + Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigStat(
                    label: 'Commandes',
                    value: summary.deliveriesCount.toString(),
                    color: AppColors.burntOrange,
                  ),
                  Container(width: 1, height: 30, color: AppColors.grisLeger),
                  _bigStat(
                    label: 'Total',
                    value: '${summary.revenue.toStringAsFixed(0)}dh',
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 Big stat for compact card
  Widget _bigStat({
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeliveryDetails(_DeliverySummary summary) async {
    // Charger les commandes de livraison pour ce livreur
    final deliveries = await DatabaseService.getAllOrderDeliveries();
    final orderIds = deliveries
        .where((d) => d.livreurId == summary.livreurId)
        .map((d) => d.orderId)
        .toSet();
    final orders = await DatabaseService.getPosOrders();
    final livreurOrders = orders
        .where(
          (o) => orderIds.contains(o.id) && o.fulfillmentType == 'delivery',
        )
        .toList();

    // Trier par date décroissante
    livreurOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (!mounted) return;

    showModalBottomSheet(
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
                          backgroundColor: AppColors.burntOrange.withOpacity(
                            0.15,
                          ),
                          child: Text(
                            summary.livreurName.isNotEmpty
                                ? summary.livreurName
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.burntOrange,
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
                                summary.livreurName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charbon,
                                ),
                              ),
                              if (summary.livreurPhone.isNotEmpty)
                                Text(
                                  summary.livreurPhone,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grisModerne,
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
                            color: AppColors.burntOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${summary.revenue.toStringAsFixed(0)}dh',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.burntOrange,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${summary.deliveriesCount} livraisons',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.burntOrange.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.grisLeger),
                  // En-tête de la liste des commandes
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Commandes assignées',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charbon,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.burntOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${livreurOrders.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.burntOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: livreurOrders.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune commande assignée',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.grisModerne,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                            itemCount: livreurOrders.length,
                            itemBuilder: (context, index) {
                              final order = livreurOrders[index];
                              return _orderTile(order);
                            },
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

  // Widget pour afficher une commande dans la liste
  Widget _orderTile(PosOrder order) {
    final isCancelled = order.status.toLowerCase().contains('cancel');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.grisPale : AppColors.blancPur,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCancelled
              ? AppColors.grisLeger
              : AppColors.burntOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.grisLeger
                      : AppColors.burntOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  OrderDisplayLabels.typeLabel(order.fulfillmentType),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCancelled
                        ? AppColors.grisModerne
                        : AppColors.burntOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${order.totalPrice.toStringAsFixed(0)}dh',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCancelled
                      ? AppColors.grisModerne
                      : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.customerName != null || order.customerPhone != null)
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.grisModerne,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      order.customerName,
                      order.customerPhone,
                    ].where((e) => e != null && e.isNotEmpty).join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.charbon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (order.deliveryAddress != null &&
              order.deliveryAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.grisModerne,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.charbon,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                order.status == 'paid' ? Icons.check_circle : Icons.access_time,
                size: 14,
                color: order.status == 'paid'
                    ? const Color(0xFF2E7D32)
                    : AppColors.burntOrange,
              ),
              const SizedBox(width: 4),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: order.status == 'paid'
                      ? const Color(0xFF2E7D32)
                      : AppColors.burntOrange,
                ),
              ),
              const Spacer(),
              Text(
                '${order.createdAt.day}/${order.createdAt.month} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grisModerne,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliverySummary {
  _DeliverySummary({
    required this.livreurId,
    required this.livreurName,
    required this.livreurPhone,
    required this.deliveriesCount,
    required this.revenue,
    required this.completedCount,
    required this.pendingCount,
  });

  final int livreurId;
  final String livreurName;
  final String livreurPhone;
  int deliveriesCount;
  double revenue;
  int completedCount;
  int pendingCount;
}
