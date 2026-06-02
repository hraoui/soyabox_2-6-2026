// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/table_plan_layout.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/pos_table.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/order_item_grouping.dart';
import '../theme/sushi_design.dart';
import '../utils/order_display_labels.dart';
import '../utils/order_item_dedup.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/app_back_button.dart';
import '../widgets/pos_ui.dart';
import '../widgets/unified_payment_dialog.dart';

class PosTablesScreen extends StatefulWidget {
  const PosTablesScreen({super.key});

  @override
  State<PosTablesScreen> createState() => _PosTablesScreenState();
}

class _PosTablesScreenState extends State<PosTablesScreen> {
  String? _selectedTableNumber;

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: const Text('Mes Tables', style: SushiTypo.h4),
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
          if (pos.tables.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return POSAdaptiveLayout(
            squareBuilder: (context, viewport) =>
                _buildPlanContent(pos, viewport, isSquare: true),
            wideBuilder: (context, viewport) =>
                _buildPlanContent(pos, viewport, isSquare: false),
          );
        },
      ),
    );
  }

  Widget _buildPlanContent(
    PosController pos,
    POSViewport viewport, {
    required bool isSquare,
  }) {
    final outerPadding = viewport.compactPadding;
    final innerPadding = isSquare ? 8.0 : 10.0;

    if (pos.tables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final mapped = <_MappedTable>[];
    final seenNumbers = <String>{};
    var outOfPlanCount = 0;

    for (final table in pos.tables) {
      final normalized = normalizeTableName(table.number);
      final slot = kTablePlanSlotsByNumber[normalized];
      if (slot == null || seenNumbers.contains(normalized)) {
        outOfPlanCount += 1;
        continue;
      }
      seenNumbers.add(normalized);
      mapped.add(_MappedTable(slot: slot, table: table));
    }

    mapped.sort((a, b) {
      final rowCmp = a.slot.row.compareTo(b.slot.row);
      if (rowCmp != 0) return rowCmp;
      return a.slot.col.compareTo(b.slot.col);
    });

    return Padding(
      padding: EdgeInsets.all(outerPadding),
      child: Container(
        decoration: SushiDeco.card(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                innerPadding,
                innerPadding,
                innerPadding,
                6,
              ),
              child: _header(pos: pos, outOfPlanCount: outOfPlanCount),
            ),
            const Divider(height: 1, color: SushiColors.divider),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(innerPadding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FloorGridPainter(
                              gridColor: SushiColors.divider,
                            ),
                          ),
                        ),
                        ...mapped.map(
                          (entry) => _positionedTable(
                            constraints: constraints,
                            entry: entry,
                            isSelected:
                                _selectedTableNumber ==
                                normalizeTableName(entry.table.number),
                            onTap: () => _onTableTap(pos, entry.table),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required PosController pos, required int outOfPlanCount}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;

        final actionPanel = Wrap(
          spacing: SushiSpace.sm,
          runSpacing: SushiSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [_legend()],
        );

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan des Tables', style: SushiTypo.h1),
            const SizedBox(height: SushiSpace.xs),
            Text(pos.restaurantLabel, style: SushiTypo.bodyMd),
            if (outOfPlanCount > 0) ...[
              const SizedBox(height: SushiSpace.xs),
              Text(
                'Tables hors plan: $outOfPlanCount',
                style: SushiTypo.caption.copyWith(color: SushiColors.inkMid),
              ),
            ],
          ],
        );

        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: SushiSpace.sm),
                  actionPanel,
                ],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  actionPanel,
                ],
              );
      },
    );
  }

  Widget _legend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendItem(color: SushiColors.green, label: 'Disponible'),
        SizedBox(width: SushiSpace.sm),
        _LegendItem(color: SushiColors.yellow, label: 'Réservée'),
        SizedBox(width: SushiSpace.sm),
        _LegendItem(color: SushiColors.red, label: 'Occupée'),
      ],
    );
  }

  Widget _positionedTable({
    required BoxConstraints constraints,
    required _MappedTable entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const colGap = 14.0;
    const rowGap = 16.0;

    final rawCellW =
        (constraints.maxWidth - ((kPlanCols - 1) * colGap)) / kPlanCols;
    final rawCellH =
        (constraints.maxHeight - ((kPlanRows - 1) * rowGap)) / kPlanRows;

    final tileW = rawCellW.clamp(62.0, 124.0).toDouble();
    final tileH = rawCellH.clamp(48.0, 90.0).toDouble();

    final left =
        (entry.slot.col * (rawCellW + colGap)) + ((rawCellW - tileW) / 2);
    final top =
        (entry.slot.row * (rawCellH + rowGap)) + ((rawCellH - tileH) / 2);

    final status = entry.table.status;
    final isFree = status == 'available' || status == 'free';
    final isReserved = status == 'reserved';

    return Positioned(
      left: left,
      top: top,
      width: tileW,
      height: tileH,
      child: _TableTile(
        table: entry.table,
        isFree: isFree,
        isReserved: isReserved,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _onTableTap(PosController pos, PosTable table) async {
    final normalized = normalizeTableName(table.number);

    // DEBUG LOG
    print('🔍 [DEBUG] Table tap: ${table.number}, status: ${table.status}');

    // Vérifier si le serveur actuel peut accéder à cette table
    bool isOwner = false;
    PosOrder? activeOrder;
    List<PosOrderItem> orderItems = [];

    if (table.status == 'occupied') {
      // Utiliser le staff actif du PosController (PAS AuthController)
      final currentStaff = pos.activeStaff;

      print(
        '🔍 [DEBUG] currentStaff (from pos): ${currentStaff?.email}, id: ${currentStaff?.id}',
      );

      if (currentStaff != null) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final orders = await DatabaseService.getPosOrdersByDateRange(
          startOfDay,
          endOfDay,
        );

        print('🔍 [DEBUG] Total orders today: ${orders.length}');

        activeOrder = orders
            .where(
              (o) =>
                  o.tableNumber == table.number &&
                  o.fulfillmentType == 'on_site' &&
                  o.status != 'delivered' &&
                  o.status != 'cancelled',
            )
            .firstOrNull;

        print(
          '🔍 [DEBUG] activeOrder found: ${activeOrder?.id}, staffId: ${activeOrder?.staffId}',
        );

        if (activeOrder != null && activeOrder.staffId == currentStaff.id) {
          isOwner = true;
          print('✅ [DEBUG] isOwner = TRUE');
          // Récupérer les articles de la commande
          orderItems = await DatabaseService.getPosOrderItems(activeOrder.id);
          print('✅ [DEBUG] orderItems count: ${orderItems.length}');
        } else {
          print('❌ [DEBUG] isOwner = FALSE');
        }
      }
    }

    final statusMeta = _tableStatusMeta(table);
    setState(() {
      _selectedTableNumber = normalized;
    });

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Table options',
      barrierColor: const Color(0x7A0A0A0A),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 700),
              child: AppSurfaceCard(
                radius: 24,
                padding: EdgeInsets.zero,
                backgroundColor: SushiColors.white,
                shadow: const [
                  BoxShadow(
                    color: Color(0x290A0A0A),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusMeta.color.withOpacity(0.16),
                            SushiColors.white,
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: statusMeta.color.withOpacity(0.14),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: statusMeta.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: statusMeta.color.withOpacity(0.18),
                                  ),
                                ),
                                child: Icon(
                                  statusMeta.icon,
                                  color: statusMeta.color,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Table ${table.number}',
                                      style: SushiTypo.h1.copyWith(
                                        fontSize: 30,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusMeta.color.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          SushiRadius.full,
                                        ),
                                      ),
                                      child: Text(
                                        statusMeta.label,
                                        style: SushiTypo.caption.copyWith(
                                          color: statusMeta.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Get.back(),
                                borderRadius: BorderRadius.circular(
                                  SushiRadius.full,
                                ),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: SushiColors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: SushiColors.divider,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: SushiColors.inkMid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Message différent selon le statut et le propriétaire
                          if (table.status == 'occupied' && !isOwner)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SushiColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SushiColors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: SushiColors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cette table est occupée par un autre serveur. Veuillez attendre qu\'elle soit libérée.',
                                      style: SushiTypo.bodyMd.copyWith(
                                        color: SushiColors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (table.status == 'occupied' && isOwner)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SushiColors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SushiColors.teal.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: SushiColors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Vous avez une commande active sur cette table.',
                                      style: SushiTypo.bodyMd.copyWith(
                                        color: SushiColors.teal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Choisissez l\'action à lancer pour cette table.',
                              style: SushiTypo.bodyMd.copyWith(
                                color: SushiColors.inkMid,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Contenu principal : détails de la commande pour le propriétaire
                    if (table.status == 'occupied' &&
                        isOwner &&
                        activeOrder != null)
                      _buildOwnerDialogContent(
                        pos: pos,
                        table: table,
                        order: activeOrder,
                        items: orderItems,
                        normalized: normalized,
                      )
                    else
                      // Contenu pour table libre ou non-propriétaire
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Boutons si table disponible OU si le serveur est propriétaire
                            if (table.status == 'available' || isOwner) ...[
                              _dialogOptionCard(
                                icon: Icons.add_shopping_cart_rounded,
                                title: 'Nouvelle commande',
                                subtitle:
                                    'Ouvrir directement le POS pour prendre une commande.',
                                color: SushiColors.green,
                                badge: 'POS',
                                onTap: () {
                                  Get.back();
                                  // Ensure controller is in NEW order mode (clear any prior edit state)
                                  pos.startNewOrder();
                                  pos.setFulfillmentType('on_site');
                                  pos.setTableNumber(table.number);
                                  Get.toNamed('/pos-order');
                                },
                              ),
                              const SizedBox(height: 14),
                              _dialogOptionCard(
                                icon: Icons.receipt_long_rounded,
                                title: 'Commandes',
                                subtitle: 'Voir les commandes de cette table.',
                                color: SushiColors.teal,
                                badge: 'LIST',
                                onTap: () async {
                                  Get.back();
                                  await _showTableOrdersDialog(
                                    pos,
                                    table.number,
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Fermer'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  foregroundColor: SushiColors.inkMid,
                                  side: BorderSide(
                                    color: SushiColors.divider.withOpacity(
                                      0.95,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
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
      },
    );
  }

  Widget _buildOwnerDialogContent({
    required PosController pos,
    required PosTable table,
    required PosOrder order,
    required List<PosOrderItem> items,
    required String normalized,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layout en deux colonnes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne gauche : Détails de la commande
              Expanded(
                flex: 3,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: SushiColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SushiColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: SushiColors.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Commande #${order.id}',
                              style: SushiTypo.h3.copyWith(
                                color: SushiColors.teal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Liste des articles
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun article',
                                  style: TextStyle(color: SushiColors.inkMid),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.quantity}x ${item.productName}',
                                            style: SushiTypo.bodyMd,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${(item.unitPrice * item.quantity).toStringAsFixed(2)} DH',
                                          style: SushiTypo.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SushiColors.teal.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: SushiTypo.h3.copyWith(
                                color: SushiColors.teal,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${order.totalPrice.toStringAsFixed(2)} DH',
                              style: SushiTypo.h3.copyWith(
                                color: SushiColors.teal,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Colonne droite : Boutons d'action
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _dialogActionCard(
                      icon: Icons.edit_rounded,
                      title: 'Éditer',
                      subtitle: 'Modifier la commande',
                      color: SushiColors.teal,
                      onTap: () async {
                        Get.back(); // Fermer le popup
                        // Charger la commande existante pour édition
                        await pos.loadOrderForEdit(order);
                        // Naviguer vers le POS
                        Get.toNamed('/pos-order');
                      },
                    ),
                    const SizedBox(height: 10),
                    _dialogActionCard(
                      icon: Icons.payments_rounded,
                      title: 'Payer',
                      subtitle: 'Encaisser la commande',
                      color: SushiColors.green,
                      onTap: () {
                        Get.back();
                        _showPaymentDialog(pos, order);
                      },
                    ),
                    const SizedBox(height: 10),
                    _dialogActionCard(
                      icon: Icons.lock_open_rounded,
                      title: 'Libérer',
                      subtitle: 'Libérer la table',
                      color: SushiColors.orange,
                      onTap: () {
                        Get.back();
                        _confirmFreeTable(pos, table);
                      },
                    ),
                    const SizedBox(height: 10),
                    _dialogActionCard(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Transférer',
                      subtitle: 'Vers une autre table',
                      color: SushiColors.redDark,
                      onTap: () {
                        Get.back();
                        _showTransferDialog(pos, table, order);
                      },
                    ),
                    const SizedBox(height: 14),
                    _dialogActionCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Commandes',
                      subtitle: 'Voir les commandes de cette table',
                      color: SushiColors.teal,
                      onTap: () async {
                        Get.back();
                        await _showTableOrdersDialog(pos, table.number);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Bouton Fermer
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Fermer'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: SushiColors.inkMid,
                side: BorderSide(color: SushiColors.divider.withOpacity(0.95)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTableOrdersDialog(
    PosController pos,
    String tableNumber,
  ) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final orders = await DatabaseService.getPosOrdersByDateRange(
      startOfDay,
      endOfDay,
    );

    final tableOrders =
        orders.where((o) => o.tableNumber == tableNumber).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Commandes - Table $tableNumber'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: tableOrders.isEmpty
              ? const Center(child: Text('Aucune commande'))
              : ListView.builder(
                  itemCount: tableOrders.length,
                  itemBuilder: (context, index) {
                    final order = tableOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: order.status == 'paid'
                                ? SushiColors.green.withOpacity(0.1)
                                : SushiColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            order.status == 'paid'
                                ? Icons.check_circle
                                : Icons.pending,
                            color: order.status == 'paid'
                                ? SushiColors.green
                                : SushiColors.orange,
                          ),
                        ),
                        title: Text(
                          'Commande #${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${order.totalPrice.toStringAsFixed(2)} DH - ${_formatTime(order.createdAt)} - ${_paymentStatusFr(order.paymentStatus)}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _showOrderDetailDialog(order);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderDetailDialog(PosOrder order) async {
    var items = await DatabaseService.getPosOrderItems(order.id);
    // ✅ Dédupliquer les items avant affichage
    items = deduplicateOrderItems(items);
    final groupedItems = groupOrderItemsByGuest(items);
    final shouldGroupItems =
        groupedItems.length > 1 ||
        (groupedItems.length == 1 &&
            groupedItems.keys.first != 'Sans ensemble');

    User? staffUser;
    Restaurant? restaurant;
    try {
      staffUser = await DatabaseService.getUserById(order.staffId);
    } catch (_) {
      staffUser = null;
    }
    try {
      restaurant = order.restaurantId != null
          ? await DatabaseService.getRestaurantById(order.restaurantId!)
          : null;
    } catch (_) {
      restaurant = null;
    }

    final staffLabel = staffUser != null
        ? '${staffUser.name} (#${order.staffId})'
        : 'ID ${order.staffId}';
    final restaurantLabel = restaurant != null
        ? restaurant.name
        : (order.restaurantId != null ? 'ID ${order.restaurantId}' : '-');
    final createdLabel = '${order.createdAt.toLocal()}'.split('.').first;
    final updatedLabel = '${order.updatedAt.toLocal()}'.split('.').first;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Commande #${order.id}'),
        content: SizedBox(
          width: 500,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Infos commande
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SushiColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Statut', _statusFr(order.status)),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Canal',
                      OrderDisplayLabels.channelLabel(order.channel),
                    ),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Type',
                      OrderDisplayLabels.typeLabel(order.fulfillmentType),
                    ),
                    const SizedBox(height: 4),
                    _infoRow('Restaurant', restaurantLabel),
                    const SizedBox(height: 4),
                    _infoRow('Serveur', staffLabel),
                    const SizedBox(height: 4),
                    _infoRow('Paiement', _paymentStatusFr(order.paymentStatus)),
                    const SizedBox(height: 4),
                    if (order.paymentMethod != null &&
                        order.paymentMethod!.isNotEmpty) ...[
                      _infoRow(
                        'Méthode',
                        order.paymentMethod == 'split'
                            ? 'Paiement multiple'
                            : order.paymentMethod!,
                      ),
                      const SizedBox(height: 4),
                    ],
                    _infoRow('Table', order.tableNumber ?? '-'),
                    const SizedBox(height: 4),
                    _infoRow('Heure', _formatTime(order.createdAt)),
                    const SizedBox(height: 4),
                    _infoRow('Créée', createdLabel),
                    const SizedBox(height: 4),
                    _infoRow('Mise à jour', updatedLabel),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Total',
                      '${order.totalPrice.toStringAsFixed(2)} DH',
                    ),
                    if (order.note != null && order.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow('Note', order.note!),
                    ],
                    if (order.rewardId != null) ...[
                      const SizedBox(height: 4),
                      _infoRow('Récompense', '#${order.rewardId}'),
                    ],
                    if (order.cancelReason != null &&
                        order.cancelReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow('Annulation', order.cancelReason!),
                    ],
                    if (order.originalTotal > order.totalPrice) ...[
                      const SizedBox(height: 4),
                      _infoRow(
                        'Total initial',
                        '${order.originalTotal.toStringAsFixed(2)} DH',
                      ),
                    ],
                    if (order.hasDiscount && order.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      _infoRow(
                        'Remise',
                        '-${order.discountAmount.toStringAsFixed(2)} DH',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Détails des paiements
              if (order.paymentStatus == 'paid') ...[
                const Text(
                  'Paiements:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._buildPaymentDetails(order),
                const SizedBox(height: 12),
              ],

              const Text(
                'Articles:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Aucun article'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: shouldGroupItems
                            ? groupedItems.entries
                                  .map(
                                    (entry) => _buildProductGroup(
                                      entry.key,
                                      entry.value,
                                    ),
                                  )
                                  .toList()
                            : items.map((item) => _itemTile(item)).toList(),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentDetails(PosOrder order) {
    final List<Widget> widgets = [];

    // Vérifier s'il y a un paiement split
    final paymentSplit = order.paymentSplit;
    if (paymentSplit != null && paymentSplit.isNotEmpty) {
      try {
        // Parser le paymentSplit
        final payments = _parsePaymentSplit(paymentSplit);
        for (final payment in payments) {
          final method = payment['method'] as String;
          final amount = payment['amount'] as double;
          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _paymentMethodColor(method).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _paymentMethodColor(method).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _paymentMethodIcon(method),
                    size: 20,
                    color: _paymentMethodColor(method),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _paymentMethodName(method),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(2)} DH',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _paymentMethodColor(method),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        // Si erreur de parsing, afficher le méthode simple
        widgets.add(
          _simplePaymentRow(order.paymentMethod ?? 'N/A', order.totalPrice),
        );
      }
    } else if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) {
      // Paiement simple
      widgets.add(_simplePaymentRow(order.paymentMethod!, order.totalPrice));
    }

    return widgets;
  }

  List<Map<String, dynamic>> _parsePaymentSplit(String paymentSplit) {
    final List<Map<String, dynamic>> payments = [];
    final cleaned = paymentSplit.trim();
    if (cleaned.isEmpty) return payments;

    try {
      // Essayer de parser comme JSON valide (format jsonEncode)
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            payments.add({
              'method': item['method']?.toString() ?? '',
              'amount': double.tryParse(item['amount'].toString()) ?? 0.0,
            });
          }
        }
      }
    } catch (e) {
      // Fallback: format ancien style Dart toString()
      try {
        final regex = RegExp(r'\{method:\s*(\w+),\s*amount:\s*([\d.]+)\}');
        final matches = regex.allMatches(cleaned);
        for (final match in matches) {
          payments.add({
            'method': match.group(1),
            'amount': double.tryParse(match.group(2) ?? '0') ?? 0.0,
          });
        }
      } catch (e2) {
        print('❌ [PARSE] Erreur parsing paymentSplit: $e2');
      }
    }

    return payments;
  }

  Widget _simplePaymentRow(String method, double amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _paymentMethodColor(method).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _paymentMethodColor(method).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _paymentMethodIcon(method),
            size: 20,
            color: _paymentMethodColor(method),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _paymentMethodName(method),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} DH',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _paymentMethodColor(method),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: SushiColors.ink,
        ),
      ),
    );
  }

  Widget _buildProductGroup(String title, List<PosOrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) _groupHeader(title),
        ...items.map(_itemTile).toList(),
      ],
    );
  }

  Widget _itemTile(PosOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SushiColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity}× ${item.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(item.unitPrice * item.quantity).toStringAsFixed(2)} DH',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (item.serviceCourseLabel != null &&
                  item.serviceCourseLabel!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.teal.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.serviceCourseLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SushiColors.teal,
                    ),
                  ),
                ),
              if (item.groupLabel != null && item.groupLabel!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.groupLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SushiColors.orange,
                    ),
                  ),
                ),
              if (item.itemNote != null && item.itemNote!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.itemNote!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SushiColors.green,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _paymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF4CAF50); // Vert
      case 'tpe':
        return const Color(0xFF2196F3); // Bleu
      case 'en_compte':
        return const Color(0xFFFF9800); // Orange
      default:
        return SushiColors.ink;
    }
  }

  IconData _paymentMethodIcon(String method) {
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

  String _paymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'tpe':
        return 'Carte bancaire (TPE)';
      case 'en_compte':
        return 'En compte';
      default:
        return method;
    }
  }

  String _statusFr(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'paid':
        return 'Payée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _paymentStatusFr(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: SushiColors.inkMid)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _showPaymentDialog(PosController pos, PosOrder order) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => UnifiedPaymentDialog(
        order: order,
        pos: pos,
        showEditOption: false, // Pas d'édition pour POS tables
      ),
    );
  }

  void _confirmFreeTable(PosController pos, PosTable table) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Libérer la table'),
        content: Text(
          'Êtes-vous sûr de vouloir libérer la table ${table.number} ?\n'
          'La commande en cours sera conservée.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Fermer le dialog de confirmation
              Get.back(); // Fermer le popup principal
              await pos.markTableFree(table.number);
              if (!mounted) return;
              if (mounted) {
                showPOSSnack(
                  context,
                  'Table ${table.number} libérée',
                  type: POSSnackType.success,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SushiColors.orange,
            ),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(
    PosController pos,
    PosTable currentTable,
    PosOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TransferTableDialog(
        pos: pos,
        currentTable: currentTable,
        order: order,
      ),
    );
  }

  ({String label, Color color, IconData icon}) _tableStatusMeta(
    PosTable table,
  ) {
    final status = table.status.trim().toLowerCase();
    if (status == 'occupied') {
      return (
        label: 'Occupée',
        color: SushiColors.red,
        icon: Icons.dining_rounded,
      );
    }
    if (status == 'reserved') {
      return (
        label: 'Réservée',
        color: SushiColors.yellow,
        icon: Icons.event_seat_rounded,
      );
    }
    return (
      label: 'Disponible',
      color: SushiColors.green,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Widget _dialogOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return AppSurfaceCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.all(18),
      backgroundColor: SushiColors.white,
      borderColor: color.withOpacity(0.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.08), color.withOpacity(0.015)],
      ),
      shadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.84)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: SushiTypo.h3.copyWith(color: color),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(SushiRadius.full),
                      ),
                      child: Text(
                        badge,
                        style: SushiTypo.overline.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: SushiTypo.bodySm.copyWith(
                    color: SushiColors.inkMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: color),
          ),
        ],
      ),
    );
  }

  Widget _dialogActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.84)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SushiTypo.bodyMd.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: SushiTypo.caption.copyWith(
                          color: SushiColors.inkMid,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TableTile extends StatefulWidget {
  const _TableTile({
    required this.table,
    required this.isFree,
    required this.isReserved,
    required this.isSelected,
    required this.onTap,
  });

  final PosTable table;
  final bool isFree;
  final bool isReserved;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TableTile> createState() => _TableTileState();
}

class _TableTileState extends State<_TableTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSelected
        ? SushiColors.red
        : widget.isReserved
        ? SushiColors.yellow
        : widget.isFree
        ? SushiColors.green
        : SushiColors.red;
    final fill = accent.withOpacity(widget.isSelected ? 0.56 : 0.1);
    final borderColor = widget.isSelected ? accent : accent.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _hovered || widget.isSelected ? 1.02 : 1,
        child: Material(
          color: SushiColors.white,
          borderRadius: BorderRadius.circular(SushiRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(SushiRadius.xl),
            splashColor: SushiColors.redPale,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: SushiDeco.card(selected: widget.isSelected).copyWith(
                color: fill,
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final base = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final fontSize = (base * 0.38).clamp(14.0, 28.0).toDouble();
                  return Text(
                    widget.table.number,
                    style: SushiTypo.h2.copyWith(
                      color: accent,
                      fontSize: fontSize,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      decoration: SushiDeco.badge(bg: SushiColors.redPale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: SushiDeco.badge(bg: color),
          ),
          const SizedBox(width: SushiSpace.xs),
          Text(
            label,
            style: SushiTypo.caption.copyWith(color: SushiColors.ink),
          ),
        ],
      ),
    );
  }
}

class _MappedTable {
  const _MappedTable({required this.slot, required this.table});
  final TablePlanSlot slot;
  final PosTable table;
}

/// Dialog pour transférer une commande vers une autre table
class _TransferTableDialog extends StatefulWidget {
  final PosController pos;
  final PosTable currentTable;
  final PosOrder order;

  const _TransferTableDialog({
    required this.pos,
    required this.currentTable,
    required this.order,
  });

  @override
  State<_TransferTableDialog> createState() => _TransferTableDialogState();
}

class _TransferTableDialogState extends State<_TransferTableDialog> {
  String? _selectedTableNumber;

  @override
  Widget build(BuildContext context) {
    final availableTables = widget.pos.tables
        .where(
          (t) =>
              (t.status == 'available' || t.status == 'free') &&
              t.number != widget.currentTable.number,
        )
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: SushiColors.redDark, size: 24),
          const SizedBox(width: 8),
          Text('Transférer la table'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transférer la commande de la table ${widget.currentTable.number} vers :',
              style: SushiTypo.bodyMd,
            ),
            const SizedBox(height: 16),
            if (availableTables.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SushiColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: SushiColors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune table disponible pour le transfert',
                        style: SushiTypo.bodySm.copyWith(
                          color: SushiColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 250,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableTables.length,
                  itemBuilder: (context, index) {
                    final table = availableTables[index];
                    final isSelected = _selectedTableNumber == table.number;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTableNumber = table.number;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SushiColors.redDark.withOpacity(0.2)
                              : SushiColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? SushiColors.redDark
                                : SushiColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            table.number,
                            style: SushiTypo.bodyMd.copyWith(
                              color: isSelected
                                  ? SushiColors.redDark
                                  : SushiColors.ink,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _selectedTableNumber != null
              ? () async {
                  Get.back(); // Fermer le dialog de sélection
                  Get.back(); // Fermer le popup principal
                  try {
                    await widget.pos.transferTable(
                      fromTableNumber: widget.currentTable.number,
                      toTableNumber: _selectedTableNumber!,
                      order: widget.order,
                    );
                    Get.snackbar(
                      'Transfert réussi',
                      'Commande transférée de la table ${widget.currentTable.number} vers $_selectedTableNumber',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.redDark,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      'Erreur : $e',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: SushiColors.redDark,
            disabledBackgroundColor: SushiColors.redDark.withOpacity(0.3),
          ),
          child: const Text('Transférer'),
        ),
      ],
    );
  }
}

class _FloorGridPainter extends CustomPainter {
  _FloorGridPainter({required this.gridColor});

  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int col = 1; col < kPlanCols; col++) {
      final x = (size.width / kPlanCols) * col;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int row = 1; row < kPlanRows; row++) {
      final y = (size.height / kPlanRows) * row;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor;
  }
}
