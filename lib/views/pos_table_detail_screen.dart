// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../config/table_plan_layout.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/pos_table.dart';
import '../services/database_service.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/order_item_dedup.dart';
import '../utils/order_item_grouping.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/pos_ui.dart';

class PosTableDetailScreen extends StatefulWidget {
  const PosTableDetailScreen({super.key});

  @override
  State<PosTableDetailScreen> createState() => _PosTableDetailScreenState();
}

class _PosTableDetailScreenState extends State<PosTableDetailScreen> {
  String? _tableNumber;
  String? _normalizedTableNumber;

  Future<List<PosOrderItem>> _loadOrderItems(int orderId) async {
    appLogger.i('🔍 [Table Detail] Loading items for Order #$orderId');
    var items = await DatabaseService.getPosOrderItems(orderId);

    // Debug: Check if items exist
    appLogger.i(
      '🔍 [Table Detail] Order #$orderId: ${items.length} items (direct query)',
    );

    // Fallback: If no items found, try to get all items and filter manually
    if (items.isEmpty) {
      final allItems = await DatabaseService.getAllPosOrderItems();
      appLogger.i('🔍 [Table Detail] Total items in DB: ${allItems.length}');
      if (allItems.isNotEmpty) {
        final orderIds = allItems.map((i) => i.orderId).toSet().toList()
          ..sort();
        appLogger.i('🔍 [Table Detail] Existing orderIds in DB: $orderIds');
      }
      items = allItems.where((item) => item.orderId == orderId).toList();
      appLogger.i(
        '🔍 [Table Detail] After manual filter: ${items.length} items',
      );
    }

    return items;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Get.arguments as Map<String, dynamic>?;
    _tableNumber = args?['tableNumber'];
    _normalizedTableNumber = args?['normalizedTableNumber'];

    // CRITICAL FIX: Load today's orders when entering table detail screen
    // This ensures we only see today's orders for this table
    final pos = Get.find<PosController>();
    pos.loadOrdersToday();
  }

  @override
  Widget build(BuildContext context) {
    final tableNumber = _tableNumber;
    if (tableNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: Text('Table $tableNumber', style: SushiTypo.h4),
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          alwaysVisible: true,
          iconColor: SushiColors.red,
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<PosController>(
        builder: (_) {
          final table = pos.tables
              .where(
                (t) => normalizeTableName(t.number) == _normalizedTableNumber,
              )
              .firstOrNull;

          if (table == null) {
            return const Center(
              child: Text('Table non trouvée', style: SushiTypo.bodyLg),
            );
          }

          final occupiedOrders = _getOccupiedOrders(pos, table.number);

          return POSAdaptiveLayout(
            squareBuilder: (context, viewport) => _buildContent(
              pos,
              table,
              occupiedOrders,
              viewport,
              isSquare: true,
            ),
            wideBuilder: (context, viewport) => _buildContent(
              pos,
              table,
              occupiedOrders,
              viewport,
              isSquare: false,
            ),
          );
        },
      ),
    );
  }

  List<PosOrder> _getOccupiedOrders(PosController pos, String tableNumber) {
    // ✅ Filtrer uniquement les commandes "Sur Place" (on_site) de cette table
    // Les commandes "À emporter" (pickup) et "Livraison" (delivery) n'ont PAS de table
    return pos.ordersToday
        .where(
          (order) =>
              order.tableNumber?.trim() == tableNumber.trim() &&
              order.fulfillmentType.toLowerCase() == 'on_site' &&
              order.status != 'cancelled' &&
              order.status != 'delivered',
        )
        .toList();
  }

  Widget _buildContent(
    PosController pos,
    PosTable table,
    List<PosOrder> occupiedOrders,
    POSViewport viewport, {
    required bool isSquare,
  }) {
    final gap = viewport.compactPadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSquare ? 760 : 1120),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: gap + 6, vertical: gap + 4),
          children: [
            _statusCard(table),
            SizedBox(height: gap + 8),
            if (occupiedOrders.isEmpty)
              _emptyOrdersCard()
            else
              _ordersList(pos, occupiedOrders),
            SizedBox(height: gap + 8),
            if (occupiedOrders.isNotEmpty)
              _actionCards(pos, table, occupiedOrders),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(PosTable table) {
    final isOccupied = table.status == 'occupied';
    final isReserved = table.status == 'reserved';

    final statusConfig = isOccupied
        ? (label: 'Occupée', color: SushiColors.red, icon: Icons.dining_rounded)
        : isReserved
        ? (
            label: 'Réservée',
            color: SushiColors.yellow,
            icon: Icons.event_available_outlined,
          )
        : (
            label: 'Disponible',
            color: SushiColors.green,
            icon: Icons.check_circle_outline_rounded,
          );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SushiSpace.lg),
            decoration: BoxDecoration(
              color: statusConfig.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SushiRadius.lg),
            ),
            child: Icon(statusConfig.icon, color: statusConfig.color, size: 32),
          ),
          const SizedBox(width: SushiSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Table ${table.number}', style: SushiTypo.h2),
                const SizedBox(height: SushiSpace.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SushiSpace.sm,
                    vertical: SushiSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(SushiRadius.sm),
                    border: Border.all(color: statusConfig.color, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusConfig.color),
                      const SizedBox(width: SushiSpace.xs),
                      Text(
                        statusConfig.label,
                        style: SushiTypo.bodyMd.copyWith(
                          color: statusConfig.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyOrdersCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SushiSpace.xl),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: SushiColors.inkMid,
            ),
            const SizedBox(height: SushiSpace.lg),
            Text(
              'Aucune commande en cours',
              style: SushiTypo.h3.copyWith(color: SushiColors.inkMid),
            ),
            const SizedBox(height: SushiSpace.xs),
            Text(
              'Cette table est libre et prête à accueillir des clients',
              style: SushiTypo.bodyMd.copyWith(color: SushiColors.inkMid),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ordersList(PosController pos, List<PosOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SushiSpace.sm),
          child: Text('Commandes en cours', style: SushiTypo.h3),
        ),
        const SizedBox(height: SushiSpace.md),
        ...orders.map((order) => _orderCard(order)),
      ],
    );
  }

  Widget _orderCard(PosOrder order) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SushiSpace.sm),
                decoration: BoxDecoration(
                  color: SushiColors.redPale,
                  borderRadius: BorderRadius.circular(SushiRadius.md),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: SushiColors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: SushiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commande #${order.id}', style: SushiTypo.h4),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: SushiTypo.caption.copyWith(
                        color: SushiColors.inkMid,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SushiSpace.sm,
                  vertical: SushiSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SushiRadius.sm),
                  border: Border.all(
                    color: _getStatusColor(order.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusLabel(order.status),
                  style: SushiTypo.tag.copyWith(
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          FutureBuilder<List<PosOrderItem>>(
            future: _loadOrderItems(order.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: SushiSpace.md),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                appLogger.e('Error loading order items', error: snapshot.error);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SushiSpace.md),
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: SushiTypo.bodyMd.copyWith(color: SushiColors.red),
                  ),
                );
              }
              final items = deduplicateOrderItems(snapshot.data ?? []);
              appLogger.i('📦 Order #${order.id}: ${items.length} article(s)');
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: SushiSpace.md),
                  child: Text(
                    'Aucun article',
                    style: SushiTypo.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(children: _buildGroupedOrderItems(items));
            },
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: SushiTypo.h4),
              Text(
                _formatPrice(order.totalPrice),
                style: SushiTypo.h3.copyWith(
                  color: SushiColors.red,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
          if (order.paymentStatus == 'paid') ...[
            const SizedBox(height: SushiSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SushiSpace.sm,
                vertical: SushiSpace.xs,
              ),
              decoration: BoxDecoration(
                color: SushiColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(SushiRadius.sm),
                border: Border.all(color: SushiColors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: SushiColors.green),
                  const SizedBox(width: SushiSpace.xs),
                  Text(
                    'Payée - ${paymentMethodLabel(order.paymentMethod)}',
                    style: SushiTypo.caption.copyWith(color: SushiColors.green),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderItemRow(PosOrderItem item) {
    final quantity = item.quantity;
    final price = item.unitPrice * quantity;
    final itemNote = item.itemNote?.trim();
    final course = serviceCourseDescriptorForItem(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SushiSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: SushiColors.redPale,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'x$quantity',
                    style: SushiTypo.caption.copyWith(
                      color: SushiColors.red,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SushiSpace.sm),
              Expanded(
                child: Text(
                  cleanOrderItemProductName(item.productName),
                  style: SushiTypo.bodyMd,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatPrice(price),
                style: SushiTypo.bodyMd.copyWith(
                  color: SushiColors.inkMid,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _detailChip(course.label, SushiColors.teal),
              if (itemNote != null && itemNote.isNotEmpty)
                _detailChip(itemNote, SushiColors.redDark),
            ],
          ),
          if (itemNote != null && itemNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Note: $itemNote',
                style: SushiTypo.caption.copyWith(color: SushiColors.redDark),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedOrderItems(List<PosOrderItem> items) {
    final widgets = <Widget>[];
    final byGroup = groupOrderItemsByGuest(items);

    byGroup.forEach((groupLabel, groupItems) {
      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: SushiSpace.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: SushiSpace.sm,
            vertical: SushiSpace.xs,
          ),
          decoration: BoxDecoration(
            color: SushiColors.redPale,
            borderRadius: BorderRadius.circular(SushiRadius.md),
          ),
          child: Text(
            groupLabel,
            style: SushiTypo.h4.copyWith(color: SushiColors.red),
          ),
        ),
      );

      final byCourse = groupOrderItemsByCourse(groupItems);
      byCourse.forEach((course, courseItems) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: SushiSpace.xs, left: 2),
            child: Text(
              '=== ${course.label} ===',
              style: SushiTypo.caption.copyWith(
                color: SushiColors.inkMid,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
        widgets.addAll(courseItems.map(_orderItemRow));
      });
    });

    return widgets;
  }

  Widget _detailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: SushiTypo.caption.copyWith(color: color)),
    );
  }

  Widget _actionCards(
    PosController pos,
    PosTable table,
    List<PosOrder> orders,
  ) {
    // ✅ Afficher les actions s'il y a des commandes actives
    // Ne pas se fier uniquement au statut de la table (peut être désynchronisé)
    final hasActiveOrders = orders.isNotEmpty;
    final allPaid = orders.every((o) => o.paymentStatus == 'paid');
    final allDelivered = orders.every((o) => o.status == 'delivered');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SushiSpace.sm),
          child: Text('Actions', style: SushiTypo.h3),
        ),
        const SizedBox(height: SushiSpace.md),
        AppWrapGrid(
          minChildWidth: 260,
          maxChildWidth: 340,
          spacing: SushiSpace.lg,
          runSpacing: SushiSpace.lg,
          children: [
            // ✅ Bouton Libérer - affiché s'il y a des commandes actives ET toutes payées
            if (hasActiveOrders && allPaid && !allDelivered)
              _FreeTableActionCard(table: table, orders: orders, pos: pos),
            // ✅ Bouton Payer - affiché s'il reste des commandes non payées
            if (hasActiveOrders && !allPaid)
              _PayActionCard(table: table, orders: orders, pos: pos),
            // ✅ Bouton Modifier - affiché s'il y a des commandes en attente ET non payées
            if (orders.any(
              (o) => o.status == 'pending' && o.paymentStatus != 'paid',
            ))
              _EditProductsActionCard(table: table, orders: orders, pos: pos),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Use pattern-only format to avoid locale initialization requirement
    final format = DateFormat('dd/MM/yyyy \'à\' HH:mm');
    return format.format(date);
  }

  String _formatPrice(double price) {
    return NumberFormat('#,##0 DA', 'fr_DZ').format(price);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return SushiColors.yellow;
      case 'confirmed':
        return SushiColors.teal;
      case 'preparing':
        return SushiColors.orange;
      case 'ready':
        return SushiColors.green;
      case 'delivered':
        return SushiColors.inkMid;
      case 'cancelled':
        return SushiColors.red;
      default:
        return SushiColors.inkMid;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Servie';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FreeTableActionCard extends StatefulWidget {
  const _FreeTableActionCard({
    required this.table,
    required this.orders,
    required this.pos,
  });

  final PosTable table;
  final List<PosOrder> orders;
  final PosController pos;

  @override
  State<_FreeTableActionCard> createState() => _FreeTableActionCardState();
}

class _FreeTableActionCardState extends State<_FreeTableActionCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: _isProcessing ? null : _confirmFreeTable,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(Icons.lock_open_outlined, SushiColors.orange),
          const SizedBox(height: 8),
          const Text(
            'Libérer la table',
            style: SushiTypo.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Marquer la table comme disponible',
            style: SushiTypo.bodySm,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          if (_isProcessing) ...[
            const SizedBox(height: SushiSpace.sm),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmFreeTable() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Libérer la table'),
        content: Text(
          'Voulez-vous vraiment libérer la table ${widget.table.number} ?\n\n'
          'Cela marquera la table comme disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SushiColors.red,
              foregroundColor: SushiColors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      for (final order in widget.orders) {
        await widget.pos.updateOrderStatus(order, 'confirmed');
      }

      await widget.pos.markTableFree(widget.table.number);

      if (mounted) {
        showPOSSnack(
          context,
          'Table ${widget.table.number} libérée avec succès',
          title: 'Succès',
          type: POSSnackType.success,
          duration: const Duration(milliseconds: 2000),
        );
        Get.back();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PayActionCard extends StatefulWidget {
  const _PayActionCard({
    required this.table,
    required this.orders,
    required this.pos,
  });

  final PosTable table;
  final List<PosOrder> orders;
  final PosController pos;

  @override
  State<_PayActionCard> createState() => _PayActionCardState();
}

class _PayActionCardState extends State<_PayActionCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: _isProcessing ? null : _showPaymentOptions,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(Icons.payment_outlined, SushiColors.green),
          const SizedBox(height: 8),
          const Text('Payer', style: SushiTypo.h4, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Choisir le mode de paiement',
            style: SushiTypo.bodySm,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          if (_isProcessing) ...[
            const SizedBox(height: SushiSpace.sm),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPaymentOptions() async {
    final paymentMethod = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Mode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PaymentOptionCard(
              icon: Icons.credit_card,
              label: 'TPE',
              description: 'Paiement par carte bancaire',
              onTap: () => Get.back(result: 'tpe'),
            ),
            const SizedBox(height: SushiSpace.md),
            _PaymentOptionCard(
              icon: Icons.money,
              label: 'Espèces',
              description: 'Paiement en espèces',
              onTap: () => Get.back(result: 'cash'),
            ),
            const SizedBox(height: SushiSpace.md),
            _PaymentOptionCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'En compte',
              description: 'Paiement enregistré sur le compte client',
              onTap: () => Get.back(result: paymentMethodEnCompte),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (paymentMethod != null && mounted) {
      await _processPayment(paymentMethod);
    }
  }

  Future<void> _processPayment(String method) async {
    setState(() => _isProcessing = true);

    final methodName = paymentMethodLabel(method);

    for (final order in widget.orders) {
      if (order.paymentStatus != 'paid') {
        await widget.pos.markOrderAsPaid(order, method);
      }
    }

    if (mounted) {
      showPOSSnack(
        context,
        'Paiement $methodName enregistré avec succès',
        title: 'Paiement validé',
        type: POSSnackType.success,
        duration: const Duration(milliseconds: 2000),
      );

      final freeTable = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Table payée'),
          content: Text(
            'Le paiement de la table ${widget.table.number} a été enregistré.\n\n'
            'Voulez-vous libérer la table maintenant ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Rester sur place'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.red,
                foregroundColor: SushiColors.white,
              ),
              onPressed: () => Get.back(result: true),
              child: const Text('Libérer'),
            ),
          ],
        ),
      );

      if (freeTable == true && mounted) {
        for (final order in widget.orders) {
          await widget.pos.updateOrderStatus(order, 'confirmed');
        }

        await widget.pos.markTableFree(widget.table.number);

        if (mounted) {
          showPOSSnack(
            context,
            'Table ${widget.table.number} libérée avec succès',
            title: 'Succès',
            type: POSSnackType.success,
            duration: const Duration(milliseconds: 2000),
          );
          Get.back();
        }
      } else if (mounted) {
        Get.back();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EditProductsActionCard extends StatefulWidget {
  const _EditProductsActionCard({
    required this.table,
    required this.orders,
    required this.pos,
  });

  final PosTable table;
  final List<PosOrder> orders;
  final PosController pos;

  @override
  State<_EditProductsActionCard> createState() =>
      _EditProductsActionCardState();
}

class _EditProductsActionCardState extends State<_EditProductsActionCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final pendingOrders = widget.orders
        .where((o) => o.status == 'pending')
        .toList();

    return AppSurfaceCard(
      onTap: _isProcessing ? null : _onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(Icons.edit_document, SushiColors.orange),
          const SizedBox(height: 8),
          const Text(
            'Modifier les produits',
            style: SushiTypo.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${pendingOrders.length} commande(s)',
            style: SushiTypo.bodySm.copyWith(color: SushiColors.inkMid),
            textAlign: TextAlign.center,
          ),
          if (_isProcessing) ...[
            const SizedBox(height: SushiSpace.sm),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onTap() async {
    setState(() => _isProcessing = true);
    try {
      // Load the first pending order for edit
      final pendingOrders = widget.orders
          .where((o) => o.status == 'pending')
          .toList();
      if (pendingOrders.isNotEmpty) {
        final order = pendingOrders.first;

        // Vérifier si la commande appartient à ce serveur
        final auth = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : null;
        final currentStaff = auth?.currentUser;

        if (currentStaff != null && order.staffId != currentStaff.id) {
          if (!mounted) return;
          showPOSSnack(
            context,
            'Cette table est assignée à un autre serveur',
            title: 'Accès refusé',
            type: POSSnackType.error,
          );
          return;
        }

        // Check if order is already being edited
        if (widget.pos.editingOrderId != null &&
            widget.pos.editingOrderId != order.id) {
          if (!mounted) return;
          showPOSSnack(
            context,
            'Une autre commande est déjà en cours de modification',
            title: 'Attention',
            type: POSSnackType.warning,
          );
          return;
        }

        // Warn if order has already been synced with backend
        if (order.sourceLocalId != null && order.sourceLocalId! > 0) {
          if (!mounted) return;
          final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Modification de commande'),
              content: const Text(
                'Cette commande a déjà été synchronisée avec le backend.\n\n'
                'Toute modification sera synchronisée et peut créer des '
                'incohérences si le backend ne gère pas correctement les '
                'mises à jour.\n\n'
                'Voulez-vous continuer ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
        }

        await widget.pos.loadOrderForEdit(order);
        if (widget.pos.error != null) {
          if (!mounted) return;
          showPOSSnack(
            context,
            widget.pos.error!,
            title: 'Erreur',
            type: POSSnackType.error,
          );
          return;
        }
        // Navigate to POS screen to edit products
        Get.toNamed('/pos-order');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SushiRadius.md),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(SushiSpace.lg),
        decoration: BoxDecoration(
          color: SushiColors.bg,
          borderRadius: BorderRadius.circular(SushiRadius.lg),
          border: Border.all(color: SushiColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SushiSpace.md),
              decoration: BoxDecoration(
                color: SushiColors.redPale,
                borderRadius: BorderRadius.circular(SushiRadius.md),
              ),
              child: Icon(icon, color: SushiColors.red, size: 24),
            ),
            const SizedBox(width: SushiSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SushiTypo.h4),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: SushiTypo.bodySm.copyWith(color: SushiColors.inkMid),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: SushiColors.inkMid,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Widget _iconBadge(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(SushiSpace.lg),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(SushiRadius.lg),
    ),
    child: Icon(icon, color: color, size: 28),
  );
}
