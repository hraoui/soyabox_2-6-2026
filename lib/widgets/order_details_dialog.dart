import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/order_display_labels.dart';
import '../utils/order_item_dedup.dart';
import '../utils/order_item_grouping.dart';
import '../utils/payment_method_utils.dart';
import '../theme/sushi_design.dart';
import '../services/app_settings_service.dart';

Future<void> showOrderDetailsDialog(BuildContext context, PosOrder order) async {
  var items = await DatabaseService.getPosOrderItems(order.id);
  if (items.isEmpty) {
    final allItems = await DatabaseService.getAllPosOrderItems();
    items = allItems.where((it) => it.orderId == order.id).toList();
  }
  items = deduplicateOrderItems(items);
  final groupedItems = groupOrderItemsByGuest(items);
  final shouldShowGroupedItems = groupedItems.length > 1 || (groupedItems.length == 1 && groupedItems.keys.first != 'Sans ensemble');

  User? staffUser;
  Restaurant? restaurant;

  try {
    staffUser = await DatabaseService.getUserById(order.staffId);
  } catch (_) {
    staffUser = null;
  }

  try {
    restaurant = order.restaurantId != null ? await DatabaseService.getRestaurantById(order.restaurantId!) : null;
  } catch (_) {
    restaurant = null;
  }

  final staffLabel = staffUser != null ? '${staffUser.name} (#${order.staffId})' : 'ID ${order.staffId}';
  final restaurantLabel = restaurant != null
      ? restaurant.name
      : (order.restaurantId != null ? 'Resto #${order.restaurantId}' : '-');
  final paymentDetails = order.getParsedPaymentDetails();
  final paymentMethodLabel = paymentDetails.isNotEmpty
      ? paymentDetails.map((entry) => '${entry.paymentMethod}: ${AppSettingsService.instance.formatAmount(entry.amount)}').join(' • ')
      : (order.paymentMethod?.trim().isNotEmpty == true ? order.paymentMethod! : '-');
  final discountLabel = order.hasDiscount && order.discountAmount > 0
      ? '-${AppSettingsService.instance.formatAmount(order.discountAmount)}'
      : 'Aucune';
  final originalTotalLabel = order.originalTotal > 0
      ? AppSettingsService.instance.formatAmount(order.originalTotal)
      : '-';
  final rewardLabel = order.rewardId != null ? '#${order.rewardId}' : '-';
  final sourceLabel = order.sourceLocalId != null ? 'Src #${order.sourceLocalId}' : '-';
  final createdLabel = '${order.createdAt.toLocal()}'.split('.').first;
  final updatedLabel = '${order.updatedAt.toLocal()}'.split('.').first;

  if (!context.mounted) return;

  final statusColor = _statusColor(order.status);

  await showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withAlpha(70)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(14),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border(bottom: BorderSide(color: statusColor.withAlpha(40))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Commande #${order.id}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: SushiColors.ink)),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Text(order.channel.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blueGrey.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Text(order.fulfillmentType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: SushiSpace.lg, vertical: SushiSpace.sm),
                        decoration: BoxDecoration(
                          color: SushiColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Total', style: TextStyle(fontSize: 12, color: SushiColors.inkMid)),
                            const SizedBox(height: 6),
                            Text(AppSettingsService.instance.formatAmount(order.totalPrice), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SushiColors.teal)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(SushiSpace.xl, SushiSpace.md, SushiSpace.xl, SushiSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: SushiSpace.md,
                          runSpacing: SushiSpace.md,
                          children: [
                            _meta(context, Icons.person_outline, order.customerName ?? '-'),
                            _meta(context, Icons.call_outlined, order.customerPhone ?? '-'),
                            _meta(
                              context,
                              order.fulfillmentType == 'on_site' ? Icons.table_bar_outlined : Icons.location_on_outlined,
                              order.fulfillmentType == 'on_site'
                                  ? (order.tableNumber ?? '-')
                                  : (order.deliveryAddress ?? '-'),
                            ),
                            _meta(context, Icons.room_service_outlined, OrderDisplayLabels.typeLabel(order.fulfillmentType)),
                            _meta(context, Icons.point_of_sale_outlined, OrderDisplayLabels.channelLabel(order.channel)),
                            _meta(context, Icons.badge_outlined, staffLabel),
                            if (order.note != null && order.note!.isNotEmpty) _meta(context, Icons.note_outlined, order.note!),
                            _meta(context, Icons.payment_outlined, _paymentStatusLabel(order.paymentStatus)),
                            _meta(context, Icons.credit_card_outlined, paymentMethodLabel),
                            _meta(context, Icons.percent_outlined, discountLabel),
                            if (order.originalTotal > 0) _meta(context, Icons.calculate_outlined, originalTotalLabel),
                            _meta(context, Icons.card_giftcard_outlined, rewardLabel),
                            if (order.cancelReason != null && order.cancelReason!.isNotEmpty) _meta(context, Icons.cancel_outlined, order.cancelReason!),
                            _meta(context, Icons.cloud_done_outlined, order.isDailySynced ? 'Sync ✓' : 'Non synchronisé'),
                            if (order.isGlovoDelivery) _meta(context, Icons.local_shipping_outlined, 'Glovo'),
                            _meta(context, Icons.restaurant_outlined, restaurantLabel),
                            if (order.sourceLocalId != null) _meta(context, Icons.link_outlined, sourceLabel),
                            _meta(context, Icons.schedule_outlined, createdLabel),
                            _meta(context, Icons.update_outlined, updatedLabel),
                          ],
                        ),
                        const SizedBox(height: SushiSpace.md),
                        Text('Articles (${items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: SushiSpace.sm),
                        if (items.isEmpty)
                          Container(width: double.infinity, padding: const EdgeInsets.all(SushiSpace.md), decoration: BoxDecoration(color: SushiColors.surface, borderRadius: BorderRadius.circular(8)), child: const Text('Aucun article trouvé pour cette commande.'))
                        else if (shouldShowGroupedItems)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedItems.entries
                                .map((entry) => _buildItemGroup(entry.key, entry.value))
                                .toList(),
                          )
                        else
                          Column(children: items.map((it) => _itemTile(it)).toList()),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(SushiSpace.lg, SushiSpace.sm, SushiSpace.lg, SushiSpace.lg),
                  decoration: BoxDecoration(color: SushiColors.surface, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))]),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _meta(BuildContext context, IconData icon, String value) {
  final text = value.trim().isEmpty ? '-' : value.trim();
  return Container(
    constraints: const BoxConstraints(maxWidth: 260),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: SushiColors.inkMid), const SizedBox(width: 5), Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: SushiColors.ink, fontWeight: FontWeight.w500)))]),
  );
}

List<String> _getItemPaymentTags(PosOrderItem item) {
  final tags = <String>[];
  final money = AppSettingsService.instance.formatAmount;

  if (item.isFullyPaid()) {
    tags.add('Payé');
  } else if (item.isPartiallyPaid()) {
    tags.add('Partiel');
  } else if (item.isOffered()) {
    tags.add('Gratuit');
  }

  if (item.partialPaymentHistory != null && item.partialPaymentHistory!.isNotEmpty) {
    try {
      final decoded = jsonDecode(item.partialPaymentHistory!);
      if (decoded is List) {
        var offertQty = 0;
        double offertAmount = 0.0;
        String? offeredByName;
        
        for (final raw in decoded) {
          if (raw is Map) {
            // Check new format: is_offered flag
            final isOffered = raw['is_offered'] == true;
            if (isOffered) {
              final quantityPaid = raw['quantity_paid'];
              final qty = quantityPaid is num ? quantityPaid.toInt() : 0;
              offertQty += qty;
              
              final amountPaid = raw['amount_paid'];
              if (amountPaid is num) {
                offertAmount += amountPaid.toDouble();
              }
              
              offeredByName = raw['offered_by_staff_name']?.toString();
            } else {
              // Fallback to old format: check payment_methods
              final methods = raw['payment_methods'];
              if (methods is List) {
                final hasOffert = methods.any((payment) {
                  if (payment is Map) {
                    return normalizePaymentMethod(payment['method']?.toString()) == paymentMethodOffert;
                  }
                  return false;
                });
                if (hasOffert) {
                  final quantityPaid = raw['quantity_paid'];
                  final qty = quantityPaid is num ? quantityPaid.toInt() : 0;
                  offertQty += qty;
                  
                  final amountPaid = raw['amount_paid'];
                  if (amountPaid is num) {
                    offertAmount += amountPaid.toDouble();
                  }
                }
              }
            }
          }
        }
        
        if (offertQty > 0) {
          final offertTag = offeredByName != null 
            ? 'Offert par $offeredByName' 
            : 'Offert x$offertQty';
          tags.add(offertTag);
          if (offertAmount > 0) {
            tags.add('- ${money(offertAmount)}');
          }
        }
      }
    } catch (_) {
      // Ignore malformed history
    }
  }

  return tags;
}

Widget _itemTile(PosOrderItem it) {
  String? serviceCourseLabel = it.serviceCourseLabel?.trim().isNotEmpty == true
      ? it.serviceCourseLabel!.trim()
      : null;
  if (serviceCourseLabel == null && it.serviceCourseKey != null && it.serviceCourseKey!.isNotEmpty) {
    switch (it.serviceCourseKey) {
      case 'starter':
        serviceCourseLabel = 'Entrée';
        break;
      case 'main':
        serviceCourseLabel = 'Plat Principal';
        break;
      case 'cheese':
        serviceCourseLabel = 'Suite & Sortie';
        break;
      case 'dessert':
        serviceCourseLabel = 'Dessert';
        break;
      case 'drink':
        serviceCourseLabel = 'Boissons';
        break;
      case 'other':
        serviceCourseLabel = 'Autres';
        break;
      default:
        serviceCourseLabel = it.serviceCourseKey!.trim();
    }
  }

  final itemNote = it.itemNote?.trim();
  final groupLabel = it.groupLabel?.trim().isNotEmpty == true
      ? it.groupLabel!.trim()
      : (it.groupNumber != null && it.groupNumber! > 0
          ? 'Ensemble ${it.groupNumber}'
          : null);
  final hasNote = itemNote?.isNotEmpty ?? false;
  final hasServiceCourse = serviceCourseLabel != null;
  final hasGroup = groupLabel != null;
  final paymentTags = _getItemPaymentTags(it);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: SushiColors.surface, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${it.quantity}× ${it.productName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              AppSettingsService.instance.formatAmount(
                it.isOffered() ? 0.0 : it.unitPrice * it.quantity,
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (hasServiceCourse)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: SushiColors.teal.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  serviceCourseLabel,
                  style: const TextStyle(fontSize: 11, color: SushiColors.teal),
                ),
              ),
            if (hasGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: SushiColors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  groupLabel,
                  style: const TextStyle(fontSize: 11, color: SushiColors.orange),
                ),
              ),
            if (hasNote)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: SushiColors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  itemNote!,
                  style: const TextStyle(fontSize: 11, color: SushiColors.green),
                ),
              ),
            ...paymentTags.map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildItemGroup(String title, List<PosOrderItem> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title.trim().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SushiColors.ink),
          ),
        ),
      ...items.map(_itemTile),
    ],
  );
}

String _paymentStatusLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'paid':
      return 'Payé';
    case 'pending':
      return 'En attente';
    case 'cancelled':
      return 'Annulé';
    default:
      return value.isEmpty ? '-' : value;
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
      return SushiColors.ink;
  }
}
