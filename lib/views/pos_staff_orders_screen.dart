// ignore_for_file: unused_element

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../controllers/pos_controller.dart';
import '../controllers/sync_controller.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../services/esc_pos_printer_service.dart';
import '../services/order_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import '../utils/pos_ticket_printer.dart';
// ✅ FIX: deduplicateOrderItems retiré — causait la suppression de tous les articles
import '../utils/order_item_grouping.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/pos_ui.dart';
import '../widgets/unified_payment_dialog.dart';

class PosStaffOrdersScreen extends StatefulWidget {
  const PosStaffOrdersScreen({super.key});

  @override
  State<PosStaffOrdersScreen> createState() => _PosStaffOrdersScreenState();
}

class _PosStaffOrdersScreenState extends State<PosStaffOrdersScreen> {
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  // ✅ FIX: suppression de _filteredOrders comme état persistant.
  // Les commandes sont maintenant calculées à la volée depuis pos.ordersToday
  // dans chaque build, ce qui garantit la synchronisation avec GetX.

  @override
  void initState() {
    super.initState();
    final pos = Get.find<PosController>();
    pos.loadOrdersToday();

    Future.microtask(() async {
      if (Get.isRegistered<SyncController>()) {
        final sync = Get.find<SyncController>();
        final last = sync.lastSyncAt;
        final shouldSyncNow =
            last == null || DateTime.now().difference(last).inSeconds >= 8;
        if (shouldSyncNow) {
          unawaited(sync.syncNow());
        }
      }
      if (mounted) {
        await pos.loadOrdersToday();
      }
    });

    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      if (mounted) {
        appLogger.d('🔄 [STAFF ORDERS] Auto-refreshing orders...');
        await pos.loadOrdersToday();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ✅ FIX: calcul en ligne des commandes filtrées par date, sans état intermédiaire.
  // Appelé dans chaque build depuis pos.ordersToday (toujours à jour via GetX).
  List<PosOrder> _computeOrdersForDate(PosController pos) {
    final orders = pos.ordersToday.toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            AppCardIconBadge(
              icon: Icons.restaurant_menu,
              accent: AppColors.deepTeal,
              background: AppColors.grisPale,
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: SushiSpace.md),
            const Text(
              'Mes Commandes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charbon,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charbon,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leading: AppBackButton(
          alwaysVisible: true,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
              return;
            }
            Get.offAllNamed('/pos-menu');
          },
        ),
        actions: [
          GetBuilder<PosController>(
            builder: (_) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.grisPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: pos.isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.deepTeal,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 22),
                  tooltip: 'Actualiser',
                  onPressed: pos.isRefreshing
                      ? null
                      : () => pos.refreshOrders(),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.deepTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton.icon(
              onPressed: () => Get.offAllNamed('/pos-menu'),
              icon: const Icon(Icons.arrow_left, size: 18),
              label: const Text(
                'Retour',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GetBuilder<PosController>(
        builder: (posCtrl) {
          // ✅ FIX: on recalcule les commandes à chaque rebuild GetX,
          // garantissant que la liste est toujours synchronisée.
          final ordersForDate = _computeOrdersForDate(posCtrl);
          return POSAdaptiveLayout(
            squareBuilder: (context, viewport) => _buildOrdersContent(
              posCtrl,
              viewport,
              ordersForDate,
              isSquare: true,
            ),
            wideBuilder: (context, viewport) => _buildOrdersContent(
              posCtrl,
              viewport,
              ordersForDate,
              isSquare: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersContent(
    PosController pos,
    POSViewport viewport,
    List<PosOrder> ordersForDate, {
    required bool isSquare,
  }) {
    final gap = viewport.compactPadding + 2;

    return Padding(
      padding: EdgeInsets.all(gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ordersForDate.isEmpty
                ? _emptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxColumns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 650
                          ? 2
                          : constraints.maxWidth >= 420
                          ? 2
                          : 1;
                      final minChildWidth = constraints.maxWidth >= 900
                          ? 200.0
                          : constraints.maxWidth >= 650
                          ? 180.0
                          : constraints.maxWidth >= 420
                          ? 180.0
                          : constraints.maxWidth;
                      final maxChildWidth = constraints.maxWidth >= 900
                          ? 380.0
                          : constraints.maxWidth >= 650
                          ? 320.0
                          : constraints.maxWidth >= 420
                          ? 300.0
                          : constraints.maxWidth;

                      // ✅ FIX: filtrage appliqué sur ordersForDate (déjà synchronisé)
                      final displayOrders = ordersForDate
                          .where((order) => order.paymentStatus != 'paid')
                          .toList();

                      if (displayOrders.isEmpty) {
                        return _emptyState();
                      }

                      return ListView(
                        padding: EdgeInsets.only(bottom: gap),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${displayOrders.length} commande(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grisModerne,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          AppWrapGrid.builder(
                            itemCount: displayOrders.length,
                            minChildWidth: minChildWidth,
                            maxChildWidth: maxChildWidth,
                            spacing: gap,
                            runSpacing: gap,
                            maxColumns: maxColumns,
                            itemBuilder: (context, index) {
                              final order = displayOrders[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 220 + ((index % 8) * 50),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, (1 - value) * 10),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _orderCard(pos, order),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: _filters reçoit ordersForDate en paramètre (calculé en ligne)

  Widget _orderCard(PosController pos, PosOrder order) {
    final statusColor = _statusColor(order.status);
    final canEditOrder = pos.canEditOrderContent(order);
    final isOwner = pos.canAccessOrder(order);
    final placeLabel = order.fulfillmentType == 'on_site'
        ? (order.tableNumber == null || order.tableNumber!.trim().isEmpty
              ? 'Table non définie'
              : 'Table ${order.tableNumber!}')
        : (order.deliveryAddress == null ||
                  order.deliveryAddress!.trim().isEmpty
              ? 'Adresse non définie'
              : order.deliveryAddress!);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      radius: SushiRadius.lg,
      borderColor: statusColor.withAlpha(70),
      backgroundColor: SushiColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SushiSpace.md),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SushiRadius.lg),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCardIconBadge(
                  icon: order.fulfillmentType == 'delivery'
                      ? Icons.local_shipping_outlined
                      : order.fulfillmentType == 'pickup'
                      ? Icons.shopping_bag_outlined
                      : Icons.table_restaurant_outlined,
                  accent: statusColor,
                  background: statusColor.withAlpha(20),
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: SushiSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: SushiSpace.xs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '#${order.id}',
                            style: SushiTypo.h3.copyWith(fontSize: 16),
                          ),
                          _channelBadge(order.channel),
                          _fulfillmentTypeBadge(order.fulfillmentType),
                          _statusBadge(
                            _labelForStatus(order.status),
                            color: statusColor,
                          ),
                          if (order.isGlovoDelivery)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF00897B),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Glovo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: SushiSpace.sm,
                        runSpacing: 4,
                        children: [
                          _metaInfo(
                            Icons.person_outline,
                            order.customerName ?? 'Client',
                            fontSize: 11,
                          ),
                          _metaInfo(
                            Icons.call_outlined,
                            order.customerPhone ?? '-',
                            fontSize: 11,
                          ),
                          _metaInfo(
                            order.fulfillmentType == 'on_site'
                                ? Icons.table_bar_outlined
                                : Icons.location_on_outlined,
                            placeLabel,
                            fontSize: 11,
                          ),
                          _metaInfo(
                            Icons.schedule_outlined,
                            _formatOrderTime(order.createdAt),
                            fontSize: 11,
                          ),
                        ],
                      ),
                      if (order.fulfillmentType == 'delivery' &&
                          order.deliveryLivreurId != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withAlpha(100),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.teal.shade700,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_ind,
                                size: 10,
                                color: Colors.teal.shade700,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  order.deliveryLivreurName ??
                                      'Livreur assigné',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.fulfillmentType == 'delivery' &&
                          order.status == 'confirmed') ...[
                        const SizedBox(height: 6),
                        if (order.deliveryLivreurId == null)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showAssignLivreurDialog(pos, order),
                            icon: const Icon(Icons.person_add, size: 14),
                            label: const Text('Assigner livreur'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.burntOrange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () =>
                                _showChangeLivreurDialog(pos, order),
                            icon: const Icon(Icons.swap_horiz, size: 14),
                            label: const Text('Changer'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.burntOrange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SushiSpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _money(order.totalPrice),
                      style: SushiTypo.price.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    if (order.paymentStatus == 'paid')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Payée',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SushiSpace.sm),
            child: Wrap(
              spacing: SushiSpace.xs,
              runSpacing: SushiSpace.xs,
              children: [
                _actionButtonCompact(
                  icon: Icons.receipt_long,
                  label: 'Détails',
                  onTap: () async => _showOrderDetails(pos, order),
                ),
                _actionButtonCompact(
                  icon: Icons.print_outlined,
                  label: 'Imprimer',
                  onTap: () => _previewOrder(order),
                ),
                if (pos.isAdminEditor)
                  _actionButtonCompact(
                    icon: Icons.cancel_outlined,
                    label: 'Annuler',
                    color: Colors.red.shade700,
                    onTap: () => _confirmCancelOrder(pos, order),
                  ),
                if (order.paymentStatus != 'paid' &&
                    isOwner &&
                    (order.channel.trim().toLowerCase() == 'pos' ||
                        [
                          'web',
                          'api',
                          'mobile',
                        ].contains(order.channel.trim().toLowerCase())) &&
                    order.status == 'pending')
                  _actionButtonCompact(
                    icon: Icons.play_arrow,
                    label: 'Confirmer',
                    color: Colors.deepPurple.shade400,
                    onTap: () async {
                      final ok = await pos.updateOrderStatus(
                        order,
                        'confirmed',
                      );
                      if (!mounted) return;
                      if (ok) {
                        _notify(
                          'Statut mis à confirmée',
                          title: 'Commande confirmée',
                          type: POSSnackType.success,
                        );
                      } else {
                        _notify(
                          pos.error ??
                              'Commande locale mise à jour, notification backend échouée.',
                          title: 'Erreur backend',
                          type: POSSnackType.error,
                        );
                      }
                    },
                  ),
                if (canEditOrder && order.paymentStatus != 'paid' && isOwner)
                  _actionButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Éditer',
                    color: SushiColors.teal,
                    onTap: () async => await _openOrderEditor(pos, order),
                  ),
                if (order.paymentStatus != 'paid' &&
                    isOwner &&
                    order.status != 'delivered' &&
                    ((order.channel.trim().toLowerCase() == 'pos' &&
                            (order.fulfillmentType.trim().toLowerCase() ==
                                    'on_site' ||
                                order.fulfillmentType.trim().toLowerCase() ==
                                    'pickup')) ||
                        ([
                              'web',
                              'api',
                              'mobile',
                            ].contains(order.channel.trim().toLowerCase()) &&
                            order.fulfillmentType.trim().toLowerCase() ==
                                'pickup' &&
                            order.status.trim().toLowerCase() != 'cancelled')))
                  _actionButton(
                    icon: Icons.payment_outlined,
                    label: 'Payer',
                    color: AppColors.terraCotta,
                    onTap: () => _showSimplePaymentDialog(pos, order),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderEditor(PosController pos, PosOrder order) async {
    await pos.loadOrderForEdit(order);
    if (pos.error != null) {
      _notify(pos.error!, title: 'Erreur', type: POSSnackType.error);
      return;
    }
    if (mounted) Get.toNamed('/pos-order');
  }

  Future<void> _showSimplePaymentDialog(
    PosController pos,
    PosOrder order,
  ) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) =>
            UnifiedPaymentDialog(order: order, pos: pos, showEditOption: false),
      );
      if (result == true && mounted) {
        _notify(
          'Paiement enregistré avec succès',
          title: 'Succès',
          type: POSSnackType.success,
        );
        await pos.loadOrdersToday();
      }
    } catch (e, st) {
      appLogger.e('❌ Erreur ouverture paiement: $e\n$st');
      if (mounted) {
        _notify(
          'Impossible d\'ouvrir le paiement. Veuillez réessayer.',
          title: 'Erreur',
          type: POSSnackType.error,
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _showPaymentOptions(PosController pos, PosOrder order) async {
    final scaffoldContext = context;
    double remainingAmount = order.totalPrice;
    final List<Map<String, dynamic>> paymentEntries = [];
    String? currentAmountInput = '';

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Paiement'),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(scaffoldContext).size.height * 0.8,
          ),
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SushiColors.bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${order.totalPrice.toStringAsFixed(2)} DA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SushiColors.ink,
                              ),
                            ),
                          ],
                        ),
                        if (paymentEntries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reste:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: SushiColors.inkMid,
                                ),
                              ),
                              Text(
                                '${remainingAmount.toStringAsFixed(2)} DA',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: remainingAmount > 0
                                      ? SushiColors.orange
                                      : SushiColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (paymentEntries.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paiements effectués:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SushiColors.inkMid,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...paymentEntries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SushiColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _paymentIcon(entry['method'] as String),
                                        size: 16,
                                        color: AppColors.charbon,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _paymentLabel(
                                          entry['method'] as String,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(entry['amount'] as double).toStringAsFixed(2)} DA',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.charbon,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (remainingAmount > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SushiColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Montant à payer:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: SushiColors.inkMid,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: TextEditingController(
                                      text: currentAmountInput ?? '',
                                    ),
                                    onChanged: (value) => setDialogState(
                                      () => currentAmountInput = value,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Laisser vide pour payer le total',
                                      suffixText: 'DA',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Choisissez la méthode de paiement:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SushiColors.inkMid,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPaymentButton(
                                  icon: Icons.credit_card,
                                  label: 'TPE',
                                  method: 'tpe',
                                  onPressed: () => _handlePaymentMethod(
                                    'tpe',
                                    currentAmountInput,
                                    remainingAmount,
                                    paymentEntries,
                                    setDialogState,
                                    () => currentAmountInput = '',
                                  ),
                                ),
                                _buildPaymentButton(
                                  icon: Icons.money,
                                  label: 'Espèces',
                                  method: 'cash',
                                  onPressed: () => _handlePaymentMethod(
                                    'cash',
                                    currentAmountInput,
                                    remainingAmount,
                                    paymentEntries,
                                    setDialogState,
                                    () => currentAmountInput = '',
                                  ),
                                ),
                                _buildPaymentButton(
                                  icon: Icons.account_balance_wallet,
                                  label: 'En compte',
                                  method: 'en_compte',
                                  onPressed: () => _handlePaymentMethod(
                                    'en_compte',
                                    currentAmountInput,
                                    remainingAmount,
                                    paymentEntries,
                                    setDialogState,
                                    () => currentAmountInput = '',
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SushiColors.greenPale,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: SushiColors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Paiement complet !',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: SushiColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          if (remainingAmount > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          if (remainingAmount <= 0)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terminer'),
            ),
        ],
      ),
    );

    if (result == true && paymentEntries.isNotEmpty) {
      try {
        if (paymentEntries.length == 1) {
          await pos.markOrderAsPaid(
            order,
            paymentEntries.first['method'] as String,
          );
        } else {
          await pos.markOrderAsPaidWithSplit(order, paymentEntries);
        }
        OrderSyncService().syncOrderStatus(
          orderId: order.id,
          status: order.status,
          paymentStatus: 'paid',
        );
        _notify(
          'Paiement enregistré avec succès',
          title: 'Succès',
          type: POSSnackType.success,
        );
      } catch (e) {
        appLogger.e('❌ Erreur paiement: $e');
        _notify(
          'Erreur lors du paiement: $e',
          title: 'Erreur',
          type: POSSnackType.error,
        );
      }
    }
  }

  void _handlePaymentMethod(
    String method,
    String? amountInput,
    double remainingAmount,
    List<Map<String, dynamic>> paymentEntries,
    void Function(void Function()) setDialogState,
    void Function() clearAmountInput,
  ) {
    double amountToPay;
    if (amountInput == null || amountInput.trim().isEmpty) {
      amountToPay = remainingAmount;
    } else {
      final parsedAmount = double.tryParse(
        amountInput.trim().replaceAll(',', '.'),
      );
      if (parsedAmount == null || parsedAmount <= 0) {
        _notify('Montant invalide', type: POSSnackType.error);
        return;
      }
      if (parsedAmount > remainingAmount) {
        _notify(
          'Le montant ne peut pas dépasser ${remainingAmount.toStringAsFixed(2)} DA',
          type: POSSnackType.warning,
        );
        return;
      }
      amountToPay = parsedAmount;
    }
    setDialogState(() {
      paymentEntries.add({
        'method': method,
        'amount': amountToPay,
        'timestamp': DateTime.now(),
      });
      remainingAmount -= amountToPay;
      clearAmountInput();
    });
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required String method,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SushiColors.surface,
        foregroundColor: AppColors.charbon,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ignore: unused_element
  Future<double?> _showCashPaymentDialog(
    double totalPrice, {
    double? remainingAmount,
  }) async {
    final dialogContext = context;
    final amountController = TextEditingController();
    double? amountGiven;
    final amountToPay = remainingAmount ?? totalPrice;

    final enteredAmount = await showDialog<double>(
      context: dialogContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Paiement en espèces'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.burntOrange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remainingAmount != null && remainingAmount < totalPrice
                          ? 'Reste à payer'
                          : 'Montant total à payer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grisModerne,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${amountToPay.toStringAsFixed(2)} DA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.burntOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant donné par le client (DA)',
                  hintText: 'Ex: ${amountToPay.toStringAsFixed(0)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.money,
                    color: AppColors.burntOrange,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setDialogState(
                  () => amountGiven = double.tryParse(value) ?? 0,
                ),
              ),
              if (amountGiven != null && amountGiven! >= amountToPay) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.change_circle,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reste à retourner',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(amountGiven! - amountToPay).toStringAsFixed(2)} DA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (amountGiven != null && amountGiven! < amountToPay) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Montant insuffisant (${amountGiven!.toStringAsFixed(2)} dh)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: amountGiven == null || amountGiven! < amountToPay
                  ? null
                  : () => Navigator.pop(dialogContext, amountGiven),
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (enteredAmount == null) return null;

    final change = enteredAmount - totalPrice;
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: dialogContext,
      builder: (confirmContext) => AlertDialog(
        title: const Text('📋 Récapitulatif du paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant total :', style: TextStyle(fontSize: 14)),
                Text(
                  '${totalPrice.toStringAsFixed(2)} dh',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant donné :', style: TextStyle(fontSize: 14)),
                Text(
                  '${enteredAmount.toStringAsFixed(2)} dh',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.burntOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'À retourner au client :',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${change.toStringAsFixed(2)} dh',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(confirmContext, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmer le paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
    return confirmed == true ? enteredAmount : null;
  }

  // ignore: unused_element
  Future<double?> _showAmountInputDialog(double maxAmount, String title) async {
    final dialogContext = context;
    final amountController = TextEditingController();
    double? amountValue;

    final result = await showDialog<double>(
      context: dialogContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.burntOrange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Montant maximum',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grisModerne,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${maxAmount.toStringAsFixed(2)} DA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.burntOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant (DA)',
                  hintText: 'Ex: ${maxAmount.toStringAsFixed(0)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.burntOrange,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) =>
                    setDialogState(() => amountValue = double.tryParse(value)),
              ),
              if (amountValue != null && amountValue! > maxAmount) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le montant dépasse le reste à payer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed:
                  amountValue == null ||
                      amountValue! <= 0 ||
                      amountValue! > maxAmount
                  ? null
                  : () => Navigator.pop(dialogContext, amountValue),
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  // ignore: unused_element
  Future<bool> _showPaymentConfirmationDialog(
    PosOrder order,
    String paymentMethod,
    double? amountGiven,
  ) async {
    final methodName = paymentMethodLabel(paymentMethod);
    double? change;
    if (amountGiven != null) change = amountGiven - order.totalPrice;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmer le paiement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      paymentMethod == 'cash'
                          ? Icons.money
                          : paymentMethod == 'tpe'
                          ? Icons.credit_card
                          : Icons.account_balance_wallet,
                      color: AppColors.burntOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement par $methodName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _confirmationRow('Commande', '#${order.id}'),
                _confirmationRow(
                  'Type',
                  order.fulfillmentType == 'on_site'
                      ? 'Sur place'
                      : order.fulfillmentType == 'pickup'
                      ? 'À emporter'
                      : 'Livraison',
                ),
                _confirmationRow(
                  'Total',
                  '${order.totalPrice.toStringAsFixed(2)} dh',
                ),
                if (amountGiven != null) ...[
                  _confirmationRow(
                    'Montant donné',
                    '${amountGiven.toStringAsFixed(2)} dh',
                  ),
                  _confirmationRow(
                    'Reste à retourner',
                    '${change!.toStringAsFixed(2)} dh',
                    valueColor: Colors.green,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _confirmationRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.grisModerne),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.charbon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.charbon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: btnColor.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: btnColor.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: btnColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: btnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtonCompact({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.charbon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: btnColor.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: btnColor.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: btnColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: btnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewOrder(PosOrder order) async {
    try {
      final items = await DatabaseService.getPosOrderItems(order.id);
      if (items.isEmpty) {
        _notify(
          'Aucun article sur cette commande',
          title: 'Impression',
          type: POSSnackType.warning,
        );
        return;
      }
      final directPrinted = await EscPosPrinterService.instance
          .tryPrintCustomerTicket(order, items);
      if (directPrinted) {
        _notify(
          'Ticket client envoyé directement à l\'imprimante',
          title: 'Impression',
          type: POSSnackType.success,
        );
        return;
      }
      await Printing.layoutPdf(
        onLayout: (format) =>
            buildCustomerBillPdf(order, items, format: format),
        usePrinterSettings: false,
        dynamicLayout: false,
      );
    } catch (e) {
      _notify(
        'Impossible d\'imprimer: $e',
        title: 'Impression',
        type: POSSnackType.error,
      );
    }
  }

  Widget _channelBadge(String channel) {
    final normalizedChannel = channel.trim().toLowerCase();
    final Map<String, ({Color color, String label, IconData icon})>
    channelConfig = {
      'api': (color: Colors.purple.shade600, label: 'API', icon: Icons.api),
      'web': (color: Colors.blue.shade600, label: 'Web', icon: Icons.web),
      'kiosk': (
        color: Colors.orange.shade600,
        label: 'Kiosk',
        icon: Icons.computer,
      ),
      'mobile': (
        color: Colors.teal.shade600,
        label: 'Mobile',
        icon: Icons.phone_android,
      ),
      'pos': (
        color: Colors.green.shade600,
        label: 'POS',
        icon: Icons.point_of_sale,
      ),
    };
    final config = channelConfig[normalizedChannel];
    if (config == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: config.color.withAlpha(30),
        border: Border.all(color: config.color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 10, color: config.color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              config.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: config.color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fulfillmentTypeBadge(String fulfillmentType) {
    final Map<String, ({Color color, String label, IconData icon})> typeConfig =
        {
          'on_site': (
            color: Colors.indigo.shade600,
            label: 'Sur place',
            icon: Icons.table_restaurant,
          ),
          'pickup': (
            color: Colors.amber.shade700,
            label: 'À emporter',
            icon: Icons.shopping_bag,
          ),
          'delivery': (
            color: Colors.red.shade600,
            label: 'Livraison',
            icon: Icons.local_shipping,
          ),
        };
    final config = typeConfig[fulfillmentType];
    if (config == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: config.color.withAlpha(30),
        border: Border.all(color: config.color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 10, color: config.color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              config.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: config.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, {Color? color}) {
    final badgeColor = color ?? AppColors.deepTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: badgeColor.withAlpha(22),
        border: Border.all(color: badgeColor.withAlpha(65)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SizedBox(
        width: 360,
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(SushiSpace.xl),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.grisModerne,
              ),
              SizedBox(height: SushiSpace.md),
              Text('Aucune commande', style: SushiTypo.h3),
              SizedBox(height: SushiSpace.sm),
              Text(
                'Les nouvelles commandes apparaîtront ici.',
                style: SushiTypo.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaInfo(IconData icon, String value, {double fontSize = 12}) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.grisModerne),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                color: AppColors.charbon,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForStatus(String value) {
    switch (value.trim().toLowerCase()) {
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
        return value;
    }
  }

  Color _statusColor(String value) {
    switch (value.trim().toLowerCase()) {
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
        return Colors.teal.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return AppColors.deepTeal;
    }
  }

  String _formatOrderTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatFullDate(DateTime value) {
    final d =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
    final t =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  String _money(double amount) =>
      AppSettingsService.instance.formatAmount(amount);

  void _notify(
    String message, {
    String? title,
    POSSnackType type = POSSnackType.info,
  }) {
    if (!mounted) return;
    showPOSSnack(context, message, title: title, type: type);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 DÉTAILS COMMANDE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _showOrderDetails(PosController pos, PosOrder order) async {
    // ✅ FIX 1: Chargement des articles directement depuis la DB
    List<PosOrderItem> items = await DatabaseService.getPosOrderItems(order.id);

    // ✅ FIX 2: Fallback si getPosOrderItems retourne vide (ex: index non synchronisé)
    if (items.isEmpty) {
      final allItems = await DatabaseService.getAllPosOrderItems();
      items = allItems.where((item) => item.orderId == order.id).toList();
    }

    // ✅ FIX 3: deduplicateOrderItems SUPPRIMÉ — il pouvait fusionner/supprimer
    // des articles légitimes ayant le même productId mais des notes/groupes différents.
    // Les articles sont affichés tels quels depuis la base de données.

    appLogger.d(
      '📋 [DETAILS] Order #${order.id} — ${items.length} articles chargés',
    );

    final groupedItems = groupOrderItemsByGuest(items);
    final shouldShowGroupedItems =
        groupedItems.length > 1 ||
        (groupedItems.length == 1 &&
            groupedItems.keys.first != 'Sans ensemble');

    final statusColor = _statusColor(order.status);
    final hasOffertPayment =
        isOfferedPaymentMethod(order.paymentMethod) ||
        hasOfferedSplitPayment(order.paymentSplit);

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
            child: Container(
              decoration: BoxDecoration(
                color: SushiColors.bg,
                borderRadius: BorderRadius.circular(SushiRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SushiSpace.lg),
                    decoration: BoxDecoration(
                      color: SushiColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(SushiRadius.xl),
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppColors.grisPale),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(SushiRadius.md),
                          ),
                          child: Icon(
                            order.fulfillmentType == 'delivery'
                                ? Icons.local_shipping_outlined
                                : Icons.restaurant_menu_outlined,
                            color: statusColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: SushiSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande #${order.id}',
                                style: SushiTypo.h2.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _statusBadge(
                                    _labelForStatus(order.status),
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatFullDate(order.createdAt),
                                    style: SushiTypo.bodySm.copyWith(
                                      color: AppColors.grisModerne,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _money(order.totalPrice),
                              style: SushiTypo.price.copyWith(
                                fontSize: 24,
                                color: AppColors.deepTeal,
                              ),
                            ),
                            if (order.hasDiscount)
                              Text(
                                'Dont ${_money(order.discountAmount)} de remise',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (hasOffertPayment)
                              Text(
                                'Offerts inclus',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: SushiSpace.sm),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.grisPale,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ───────────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(SushiSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    _buildInfoSection(
                                      title: 'Client & Lieu',
                                      icon: Icons.person_outline,
                                      content: Column(
                                        children: [
                                          _detailInfoRow(
                                            Icons.person,
                                            'Nom',
                                            order.customerName ?? '-',
                                          ),
                                          _detailInfoRow(
                                            Icons.phone,
                                            'Téléphone',
                                            order.customerPhone ?? '-',
                                          ),
                                          if (order.fulfillmentType ==
                                              'on_site')
                                            _detailInfoRow(
                                              Icons.table_bar,
                                              'Table',
                                              order.tableNumber ?? '-',
                                            )
                                          else
                                            _detailInfoRow(
                                              Icons.place,
                                              'Adresse',
                                              order.deliveryAddress ?? '-',
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (order.fulfillmentType ==
                                        'delivery') ...[
                                      const SizedBox(height: SushiSpace.md),
                                      _buildInfoSection(
                                        title: 'Livraison',
                                        icon: Icons.local_shipping_outlined,
                                        content: Column(
                                          children: [
                                            _detailInfoRow(
                                              Icons.delivery_dining,
                                              'Livreur',
                                              order.deliveryLivreurName ??
                                                  'Non assigné',
                                            ),
                                            if (order.isGlovoDelivery)
                                              _detailInfoRow(
                                                Icons.bolt,
                                                'Partenaire',
                                                'Glovo',
                                                valueColor: const Color(
                                                  0xFF00897B,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: SushiSpace.md),
                              Expanded(
                                flex: 2,
                                child: _buildInfoSection(
                                  title: 'Paiement',
                                  icon: Icons.payments_outlined,
                                  content: Column(
                                    children: [
                                      _detailInfoRow(
                                        Icons.check_circle_outline,
                                        'Statut',
                                        order.paymentStatus == 'paid'
                                            ? 'Payée'
                                            : 'À régler',
                                        valueColor:
                                            order.paymentStatus == 'paid'
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                      if (order.paymentMethod != null &&
                                          order.paymentMethod!.isNotEmpty)
                                        _detailInfoRow(
                                          Icons.credit_card,
                                          'Méthode',
                                          _paymentLabel(order.paymentMethod!),
                                        ),
                                      const Divider(height: 20),
                                      if (order.paymentStatus == 'paid')
                                        ..._buildPaymentDetailWidgets(order),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: SushiSpace.lg),

                          // Notes
                          if ((order.note?.trim().isNotEmpty ?? false) ||
                              (order.cancelReason?.trim().isNotEmpty ??
                                  false)) ...[
                            _sectionTitle(
                              Icons.notes_outlined,
                              'Notes & Commentaires',
                            ),
                            const SizedBox(height: 8),
                            if (order.note?.trim().isNotEmpty ?? false)
                              _noteCard(
                                label: 'Note client / cuisine',
                                value: order.note!,
                                color: Colors.blue.shade50,
                                borderColor: Colors.blue.shade100,
                                iconColor: Colors.blue.shade700,
                              ),
                            if (order.cancelReason?.trim().isNotEmpty ??
                                false) ...[
                              const SizedBox(height: 8),
                              _noteCard(
                                label: 'Raison d\'annulation',
                                value: order.cancelReason!,
                                color: Colors.red.shade50,
                                borderColor: Colors.red.shade100,
                                iconColor: Colors.red.shade700,
                              ),
                            ],
                            const SizedBox(height: SushiSpace.lg),
                          ],

                          // ✅ ARTICLES — section corrigée
                          _sectionTitle(
                            Icons.restaurant_menu_outlined,
                            'Détail des articles (${items.length})',
                          ),
                          const SizedBox(height: 12),

                          // ✅ FIX: affichage conditionnel robuste avec message d'état
                          if (items.isEmpty)
                            _emptyItemsState()
                          else if (shouldShowGroupedItems)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: groupedItems.entries
                                  .map(
                                    (entry) => _dialogOrderItemGroup(
                                      entry.key,
                                      entry.value,
                                    ),
                                  )
                                  .toList(),
                            )
                          else
                            // ✅ FIX: ListView → Column pour éviter conflit
                            // avec SingleChildScrollView parent
                            Column(
                              children: List.generate(
                                items.length,
                                (i) => _dialogOrderItemCard(items[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Footer ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SushiSpace.lg,
                      vertical: SushiSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: SushiColors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(SushiRadius.xl),
                      ),
                      border: Border(
                        top: BorderSide(color: AppColors.grisPale),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Source: ${order.channel.toUpperCase()}',
                          style: SushiTypo.caption.copyWith(
                            color: AppColors.grisModerne,
                          ),
                        ),
                        const Spacer(),
                        // Ticket partiel (articles déjà payés)
                        Builder(
                          builder: (ctx) {
                            List<PosOrderItem> paidItemsForPrint = [];
                            for (final it in items) {
                              final paidQty = it.paymentStatus == 'paid'
                                  ? it.quantity
                                  : it.getCoveredQuantity();

                              if (paidQty > 0) {
                                paidItemsForPrint.add(
                                  PosOrderItem(
                                    orderId: it.orderId,
                                    productId: it.productId,
                                    productName: it.productName,
                                    unitPrice: it.unitPrice,
                                    quantity: paidQty,
                                    createdAt: it.createdAt,
                                  ),
                                );
                              }
                            }

                            return ElevatedButton.icon(
                              onPressed: paidItemsForPrint.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        final directPrinted =
                                            await EscPosPrinterService.instance
                                                .tryPrintCustomerTicket(
                                                  order,
                                                  paidItemsForPrint,
                                                );
                                        if (directPrinted) {
                                          _notify(
                                            'Ticket partiel envoyé directement à l\'imprimante',
                                            title: 'Impression',
                                            type: POSSnackType.success,
                                          );
                                          return;
                                        }
                                        await Printing.layoutPdf(
                                          onLayout: (format) =>
                                              buildCustomerBillPdf(
                                                order,
                                                paidItemsForPrint,
                                                format: format,
                                              ),
                                          usePrinterSettings: false,
                                          dynamicLayout: false,
                                        );
                                      } catch (e) {
                                        _notify(
                                          'Impossible d\'imprimer: $e',
                                          title: 'Impression',
                                          type: POSSnackType.error,
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.receipt_long, size: 18),
                              label: const Text('Ticket partiel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.grisPale,
                                foregroundColor: AppColors.charbon,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SushiRadius.md,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _previewOrder(order),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('Réimprimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.grisPale,
                            foregroundColor: AppColors.charbon,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                SushiRadius.md,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                SushiRadius.md,
                              ),
                            ),
                          ),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: BoxDecoration(
        color: SushiColors.white,
        borderRadius: BorderRadius.circular(SushiRadius.lg),
        border: Border.all(color: AppColors.grisPale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.deepTeal),
              const SizedBox(width: 8),
              Text(title, style: SushiTypo.h4.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _detailInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grisModerne),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: SushiTypo.bodySm.copyWith(color: AppColors.grisModerne),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: SushiTypo.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.charbon,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItemsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SushiColors.white,
        borderRadius: BorderRadius.circular(SushiRadius.lg),
        border: Border.all(color: AppColors.grisPale),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 32,
            color: AppColors.grisModerne.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun article trouvé',
            style: TextStyle(color: AppColors.grisModerne),
          ),
          const SizedBox(height: 4),
          Text(
            'Les articles de cette commande sont introuvables dans la base locale.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grisModerne.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.deepTeal),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charbon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.grisLeger, height: 1)),
      ],
    );
  }

  Widget _noteCard({
    required String label,
    required String value,
    required Color color,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.charbon),
          ),
        ],
      ),
    );
  }

  Widget _dialogOrderItemCard(PosOrderItem item) {
    String? getServiceCourseLabel(String? key) {
      if (key == null || key.isEmpty) return null;
      switch (key) {
        case 'starter':
          return 'Entrée';
        case 'main':
          return 'Plat Principal';
        case 'cheese':
          return 'Suite & Sortie';
        case 'dessert':
          return 'Dessert';
        case 'drink':
          return 'Boissons';
        case 'other':
          return 'Autres';
        default:
          return key;
      }
    }

    final serviceCourseLabel = getServiceCourseLabel(item.serviceCourseKey);
    final itemNote = item.itemNote?.trim();
    final groupLabel = item.groupLabel?.trim().isNotEmpty == true
        ? item.groupLabel!.trim()
        : (item.groupNumber != null && item.groupNumber! > 0
              ? 'Ensemble ${item.groupNumber}'
              : null);
    final hasNote = itemNote?.isNotEmpty ?? false;
    final hasServiceCourse = serviceCourseLabel != null;
    final hasGroup = groupLabel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(18, 0, 0, 0),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charbon,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Payment status badge
              Builder(
                builder: (context) {
                  final status = item.paymentStatus;
                  Color badgeColor;
                  String label;
                  if (status == 'paid') {
                    badgeColor = Colors.green.shade700;
                    label = 'Payé';
                  } else if (status == 'partially_paid') {
                    badgeColor = Colors.orange.shade700;
                    // compute remaining
                    final remaining =
                        (item.unitPrice * item.quantity) - item.paidAmount;
                    label = 'Partiel (${remaining.toStringAsFixed(2)} DA)';
                  } else {
                    badgeColor = AppColors.grisModerne;
                    label = 'Non payé';
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
              Text(
                '${item.quantity} x ${_money(item.unitPrice)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grisModerne,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _money(item.quantity * item.unitPrice),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepTeal,
                ),
              ),
            ],
          ),
          if (hasServiceCourse || hasNote || hasGroup) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasServiceCourse)
                  _itemMetaBadge(
                    icon: Icons.restaurant_menu_outlined,
                    label: serviceCourseLabel,
                    color: const Color(0xFF7B1FA2),
                    background: const Color(0xFFF3E5F5),
                  ),
                if (hasGroup)
                  _itemMetaBadge(
                    icon: Icons.group_outlined,
                    label: groupLabel,
                    color: const Color(0xFF00796B),
                    background: const Color(0xFFE0F2F1),
                  ),
                if (hasNote)
                  _itemMetaBadge(
                    icon: Icons.note_alt_outlined,
                    label: itemNote!,
                    color: SushiColors.orange,
                    background: SushiColors.orange.withOpacity(0.12),
                    maxWidth: 210,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dialogOrderItemGroup(String title, List<PosOrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charbon,
              ),
            ),
          ),
        ...items.map(_dialogOrderItemCard).toList(),
      ],
    );
  }

  Widget _itemMetaBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    double maxWidth = 170,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
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
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentDetailWidgets(PosOrder order) {
    final List<Widget> widgets = [];
    final paymentSplit = order.paymentSplit;
    if (paymentSplit != null && paymentSplit.isNotEmpty) {
      try {
        final payments = _parsePaymentSplitForDisplay(paymentSplit);
        if (payments.isNotEmpty) {
          for (final payment in payments) {
            widgets.add(
              _paymentDetailCard(
                payment['method'] as String,
                payment['amount'] as double,
              ),
            );
          }
          return widgets;
        }
      } catch (e) {
        // fallback
      }
    }
    if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) {
      widgets.add(_paymentDetailCard(order.paymentMethod!, order.totalPrice));
    }
    return widgets;
  }

  List<Map<String, dynamic>> _parsePaymentSplitForDisplay(String paymentSplit) {
    return parseSplitPaymentEntries(paymentSplit)
        .map(
          (entry) => {
            'method': entry['payment_method']?.toString() ?? '',
            'amount': (entry['amount'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList();
  }

  Widget _paymentDetailCard(String method, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _paymentColor(method).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _paymentColor(method).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_paymentIcon(method), size: 18, color: _paymentColor(method)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _paymentLabel(method),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} DH',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _paymentColor(method),
            ),
          ),
        ],
      ),
    );
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF4CAF50);
      case 'tpe':
        return const Color(0xFF2196F3);
      case 'en_compte':
        return const Color(0xFFFF9800);
      default:
        return AppColors.deepTeal;
    }
  }

  IconData _paymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'tpe':
        return Icons.credit_card;
      case 'en_compte':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'tpe':
        return 'Carte bancaire (TPE)';
      case 'en_compte':
        return 'En compte';
      default:
        return paymentMethodLabel(method);
    }
  }

  // ignore: unused_element
  Widget _detailInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.deepTeal),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grisModerne,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.charbon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _labelForChannel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'api':
        return 'Mobile APP';
      case 'web':
        return 'Site-Web';
      case 'kiosk':
        return 'Kiosk';
      default:
        return 'POS';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  void _confirmCancelOrder(PosController pos, PosOrder order) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande #${order.id}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Raison de l\'annulation (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => order.cancelReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await pos.cancelOrderLocally(
      order,
      reason: order.cancelReason,
    );
    if (!mounted) return;
    if (success) {
      OrderSyncService().syncOrderStatus(
        orderId: order.id,
        status: 'cancelled',
        cancelReason: order.cancelReason,
      );
      _notify(
        'Commande #${order.id} annulée',
        title: 'Commande annulée',
        type: POSSnackType.success,
      );
    } else {
      _notify(
        pos.error ?? 'Échec de l\'annulation',
        title: 'Erreur',
        type: POSSnackType.error,
      );
    }
  }

  void _showAssignLivreurDialog(PosController pos, PosOrder order) async {
    final restaurantId = pos.restaurantId ?? 1;
    final deliveries = await DatabaseService.getDeliveriesByRestaurant(
      restaurantId,
    );
    if (!mounted) return;
    if (deliveries.isEmpty) {
      _notify(
        'Veuillez contacter un admin pour créer des livreurs',
        title: 'Aucun livreur disponible',
        type: POSSnackType.warning,
      );
      return;
    }
    int? selectedLivreurId;
    String? selectedLivreurName;
    String? selectedLivreurPhone;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.burntOrange),
              SizedBox(width: 8),
              Text('Assigner un livreur'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${order.id}'),
                const SizedBox(height: 16),
                const Text('Sélectionnez un livreur :'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      final livreur = deliveries[index];
                      final isSelected = selectedLivreurId == livreur.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: CircleAvatar(
                          backgroundColor: livreur.isActive
                              ? AppColors.burntOrange
                              : AppColors.grisLeger,
                          child: Icon(
                            Icons.person,
                            color: livreur.isActive
                                ? Colors.white
                                : AppColors.grisModerne,
                          ),
                        ),
                        title: Text(livreur.name),
                        subtitle: Text(livreur.phone),
                        onTap: () => setDialogState(() {
                          selectedLivreurId = livreur.id;
                          selectedLivreurName = livreur.name;
                          selectedLivreurPhone = livreur.phone;
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedLivreurId == null
                  ? null
                  : () async {
                      final result = await pos.assignLivreurToDelivery(
                        order: order,
                        livreurId: selectedLivreurId!,
                        livreurName: selectedLivreurName,
                        livreurPhone: selectedLivreurPhone,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (mounted) {
                        if (result != null) {
                          _notify(
                            '$selectedLivreurName assigné à la commande #${order.id}',
                            title: '✓ Livreur assigné',
                            type: POSSnackType.success,
                          );
                        } else {
                          _notify(
                            pos.error ?? 'Échec de l\'assignation',
                            title: 'Erreur',
                            type: POSSnackType.error,
                          );
                        }
                      }
                    },
              child: const Text('Assigner'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeLivreurDialog(PosController pos, PosOrder order) =>
      _showAssignLivreurDialog(pos, order);
}

// ─────────────────────────────────────────────────────────────────────────────
// 💳 Payment Option Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    // ignore: unused_element_parameter
    this.amount,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SushiRadius.md),
      child: Container(
        padding: const EdgeInsets.all(SushiSpace.md),
        decoration: BoxDecoration(
          color: AppColors.cloudDancer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(SushiRadius.md),
          border: Border.all(color: AppColors.grisLeger),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.terraCotta.withOpacity(0.1),
                borderRadius: BorderRadius.circular(SushiRadius.sm),
              ),
              child: Icon(icon, color: AppColors.terraCotta, size: 20),
            ),
            const SizedBox(width: SushiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SushiTypo.h4.copyWith(fontSize: 14)),
                  Text(
                    description,
                    style: SushiTypo.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: SushiSpace.sm),
              Text(
                '${amount!.toStringAsFixed(2)} DA',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.burntOrange,
                ),
              ),
              const SizedBox(width: SushiSpace.sm),
            ],
            Icon(Icons.chevron_right, color: AppColors.grisModerne),
          ],
        ),
      ),
    );
  }
}
