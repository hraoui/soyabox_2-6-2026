import 'dart:convert';

import 'package:flutter/material.dart';

import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/database_service.dart';
import '../services/app_settings_service.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/pos_ui.dart';

class PartialPaymentDialog extends StatefulWidget {
  final PosOrder order;
  final PosController pos;

  const PartialPaymentDialog({
    super.key,
    required this.order,
    required this.pos,
  });

  @override
  State<PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<PartialPaymentDialog> {
  List<PosOrderItem> _items = [];
  final Map<int, int> _selectedQuantities = {}; // itemId -> quantity to pay
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    debugPrint('PartialPaymentDialog: _loadItems order=${widget.order.id}');
    final items = await DatabaseService.getPosOrderItems(widget.order.id);
    debugPrint('PartialPaymentDialog: raw items=${items.length}');
    if (!mounted) return;
    setState(() {
      _items = items.where((it) {
        final remainingQty = _getRemainingQuantity(it);
        return remainingQty > 0;
      }).toList();
      _loading = false;
    });
    debugPrint('PartialPaymentDialog: filtered items=${_items.length}');
  }

  int _getAlreadyPaidQuantity(PosOrderItem item) {
    if (item.partialPaymentHistory == null ||
        item.partialPaymentHistory!.isEmpty) {
      return 0;
    }
    try {
      final decoded = jsonDecode(item.partialPaymentHistory!);
      if (decoded is List) {
        return decoded.fold<int>(0, (sum, entry) {
          if (entry is Map && entry['quantity_paid'] is num) {
            return sum + (entry['quantity_paid'] as num).toInt();
          }
          return sum;
        });
      }
    } catch (_) {
      // Fallback to paidAmount if history is malformed.
    }
    if (item.unitPrice > 0) {
      return (item.paidAmount / item.unitPrice).round().clamp(0, item.quantity);
    }
    return 0;
  }

  int _getRemainingQuantity(PosOrderItem item) {
    final paidQty = _getAlreadyPaidQuantity(item);
    return (item.quantity - paidQty).clamp(0, item.quantity);
  }

  double get _selectedTotal {
    return _items.fold(0.0, (s, it) {
      final qty = _selectedQuantities[it.id] ?? 0;
      return s + (it.unitPrice * qty);
    });
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedQuantities.containsKey(id)) {
        _selectedQuantities.remove(id);
      } else {
        final it = _items.firstWhere((e) => e.id == id);
        _selectedQuantities[id] = _getRemainingQuantity(it);
      }
    });
  }

  void _setQuantity(int id, int qty) {
    setState(() {
      final it = _items.firstWhere((e) => e.id == id);
      final remainingQty = _getRemainingQuantity(it);
      if (qty <= 0) {
        _selectedQuantities.remove(id);
      } else {
        final clamped = qty.clamp(0, remainingQty);
        _selectedQuantities[id] = clamped;
      }
    });
  }

  Future<void> _pay(String method) async {
    if (_selectedQuantities.isEmpty) {
      showPOSSnack(
        context,
        'Veuillez sélectionner au moins un article',
        type: POSSnackType.warning,
      );
      return;
    }

    final amount = _selectedTotal;
    debugPrint(
      'PartialPaymentDialog: _pay order=${widget.order.id} method=$method amount=$amount selected=$_selectedQuantities',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer paiement partiel'),
        content: Text(
          'Payer ${amount.toStringAsFixed(2)} DH par ${paymentMethodLabel(method)} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    final paymentEntry = {'method': method, 'amount': amount};
    setState(() {
      _processing = true;
    });

    try {
      await widget.pos.markOrderItemsAsPartiallyPaid(
        widget.order,
        _selectedQuantities,
        [paymentEntry],
      );

      if (!mounted) return;
      _showSuccess('Paiement partiel enregistré');
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint(
        'PartialPaymentDialog: _pay failed order=${widget.order.id} error=$e\n$st',
      );
      if (!mounted) return;
      showPOSSnack(context, 'Erreur: $e', type: POSSnackType.error);
    } finally {
      debugPrint(
        'PartialPaymentDialog: _pay complete order=${widget.order.id}',
      );
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showPOSSnack(context, message, title: 'Succès', type: POSSnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payer partiellement'),
      content: SizedBox(
        width: 640,
        child: Stack(
          children: [
            _loading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_items.isEmpty) const Text('Aucun article à payer'),
                      if (_items.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final it = _items[i];
                              final total = (it.unitPrice * it.quantity)
                                  .toStringAsFixed(2);
                              final money =
                                  AppSettingsService.instance.formatAmount;
                              final selectedQty =
                                  _selectedQuantities[it.id] ?? 0;
                              final remainingQty = _getRemainingQuantity(it);
                              final remainingText = remainingQty > 0
                                  ? 'Reste: $remainingQty'
                                  : 'Déjà payé';
                              return Column(
                                children: [
                                  CheckboxListTile(
                                    value: selectedQty > 0,
                                    onChanged: (_) => _toggle(it.id),
                                    title: Text(it.productName),
                                    subtitle: Text(
                                      'Unit: ${money(it.unitPrice)} • Total: $total DH • $remainingText',
                                    ),
                                  ),
                                  if (selectedQty > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          const Text('Quantité:'),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _setQuantity(
                                              it.id,
                                              selectedQty - 1,
                                            ),
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '$selectedQty',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _setQuantity(
                                              it.id,
                                              selectedQty + 1,
                                            ),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Sous-total: ${(it.unitPrice * selectedQty).toStringAsFixed(2)} DH',
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Divider(),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total sélection: ${_selectedTotal.toStringAsFixed(2)} DH',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _selectedQuantities.isEmpty
                                    ? null
                                    : () => _pay('cash'),
                                icon: const Icon(Icons.money),
                                label: const Text('Cash'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _selectedQuantities.isEmpty
                                    ? null
                                    : () => _pay('tpe'),
                                icon: const Icon(Icons.credit_card),
                                label: const Text('TPE'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _selectedQuantities.isEmpty
                                    ? null
                                    : () => _pay('en_compte'),
                                icon: const Icon(Icons.account_balance_wallet),
                                label: const Text('En compte'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
            if (_processing)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
