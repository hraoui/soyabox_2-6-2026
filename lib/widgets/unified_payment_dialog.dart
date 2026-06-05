import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../services/database_service.dart';
import '../services/order_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import 'partial_payment_dialog.dart';
import '../widgets/pos_ui.dart';

enum _DiscountInputMode { percentage, amount }

/// Dialog de paiement unifié avec logique exacte demandée:
/// - Montant total affiché
/// - Un seul champ input pour montant (optionnel)
/// - Trois boutons: TPE, Cash, En compte
/// - Clic direct = paiement total
/// - Montant + clic = paiement partiel
/// - Confirmation obligatoire avant enregistrement
class UnifiedPaymentDialog extends StatefulWidget {
  final PosOrder order;
  final PosController pos;
  final bool showEditOption;

  const UnifiedPaymentDialog({
    super.key,
    required this.order,
    required this.pos,
    this.showEditOption = false,
  });

  @override
  State<UnifiedPaymentDialog> createState() => _UnifiedPaymentDialogState();
}

class _UnifiedPaymentDialogState extends State<UnifiedPaymentDialog> {
  double _remainingAmount = 0.0;
  final List<Map<String, dynamic>> _paymentEntries = [];
  String _amountInput = '';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  _DiscountInputMode _discountMode = _DiscountInputMode.percentage;
  bool _savingDiscount = false;

  @override
  void initState() {
    super.initState();
    _applyOrderPaymentState(widget.order);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _applyOrderPaymentState(PosOrder order) {
    _paymentEntries.clear();

    double alreadyPaid = 0.0;
    if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
      try {
        final decoded = parseSplitPaymentEntries(order.paymentSplit);
        for (final e in decoded) {
          final method = (e['payment_method'] ?? 'unknown').toString();
          final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
          if (!isOfferedPaymentMethod(method)) {
            alreadyPaid += amount;
          }
          _paymentEntries.add({
            'method': method,
            'amount': amount,
            'timestamp': e['timestamp'] ?? DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {
        // ignore malformed JSON
      }
    }

    _remainingAmount = (order.totalPrice - alreadyPaid).clamp(
      0.0,
      order.totalPrice,
    );
    _amountInput = '';
    _amountController.text = '';
  }

  Future<void> _refreshPaymentStateFromDatabase() async {
    try {
      final latestOrder = await DatabaseService.getPosOrderById(
        widget.order.id,
      );
      if (!mounted || latestOrder == null) return;

      widget.order.paymentMethod = latestOrder.paymentMethod;
      widget.order.paymentSplit = latestOrder.paymentSplit;
      widget.order.paymentStatus = latestOrder.paymentStatus;
      widget.order.totalPrice = latestOrder.totalPrice;
      widget.order.originalTotal = latestOrder.originalTotal;
      widget.order.discountAmount = latestOrder.discountAmount;
      widget.order.hasDiscount = latestOrder.hasDiscount;
      widget.order.status = latestOrder.status;
      widget.order.updatedAt = latestOrder.updatedAt;

      setState(() {
        _applyOrderPaymentState(latestOrder);
      });
    } catch (e) {
      appLogger.e('❌ Impossible de rafraîchir le paiement: $e');
    }
  }

  double get _discountBaseTotal {
    return widget.pos.discountBaseTotalForOrder(widget.order);
  }

  bool get _canEditDiscount {
    final status = widget.order.status.trim().toLowerCase();
    final paymentStatus = widget.order.paymentStatus.trim().toLowerCase();
    return widget.showEditOption &&
        status != 'cancelled' &&
        status != 'canceled' &&
        paymentStatus != 'paid';
  }

  double _parseDecimalInput(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? double.nan;
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} DH';
  }

  Future<void> _applyDiscountFromInput() async {
    if (_savingDiscount) return;

    final rawValue = _discountController.text;
    final parsed = _parseDecimalInput(rawValue);
    if (parsed.isNaN || parsed < 0) {
      _showError('Remise invalide');
      return;
    }

    final baseTotal = _discountBaseTotal;
    if (baseTotal <= 0) {
      _showError('Total de commande invalide');
      return;
    }

    if (_discountMode == _DiscountInputMode.percentage && parsed >= 100) {
      _showError('Le pourcentage doit être inférieur à 100%');
      return;
    }

    final discountAmount = _discountMode == _DiscountInputMode.percentage
        ? baseTotal * parsed / 100
        : parsed;

    if (discountAmount >= baseTotal) {
      _showError('La remise doit être inférieure au sous-total');
      return;
    }

    setState(() => _savingDiscount = true);
    try {
      final success = await widget.pos.applyOrderDiscount(
        widget.order,
        discountAmount: discountAmount,
      );

      if (!mounted) return;
      if (!success) {
        _showError(widget.pos.error ?? 'Impossible d\'appliquer la remise');
        return;
      }

      await _refreshPaymentStateFromDatabase();
      _discountController.clear();
      if (!mounted) return;
      _showSuccess(
        discountAmount > 0
            ? 'Remise appliquée avec succès'
            : 'Remise supprimée',
      );
    } catch (e) {
      appLogger.e('❌ Erreur remise commande: $e');
      if (!mounted) return;
      _showError('Erreur lors de l\'application de la remise');
    } finally {
      if (mounted) {
        setState(() => _savingDiscount = false);
      }
    }
  }

  Future<void> _clearDiscount() async {
    if (_savingDiscount) return;
    _discountController.text = '0';
    await _applyDiscountFromInput();
  }

  /// Prépare un paiement (avec ou sans montant)
  void _preparePayment(String method) {
    if (_remainingAmount <= 0) return;

    double amountToPay;
    if (_amountInput.isEmpty) {
      // Paiement total direct
      amountToPay = _remainingAmount;
    } else {
      // Paiement partiel
      final amountText = _amountInput.trim().replaceAll(',', '.');
      final parsedAmount = double.tryParse(amountText);
      if (parsedAmount == null || parsedAmount <= 0) {
        _showError('Montant invalide');
        return;
      }
      if (parsedAmount > _remainingAmount) {
        _showError(
          'Le montant ne peut pas dépasser ${_remainingAmount.toStringAsFixed(2)} DH',
        );
        return;
      }
      amountToPay = parsedAmount;
    }

    // Afficher la confirmation
    _showConfirmationDialog(method, amountToPay);
  }

  /// Affiche la popup de confirmation
  void _showConfirmationDialog(String method, double amount) {
    final methodLabel = _getPaymentMethodLabel(method);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer le paiement'),
        content: Text(
          'Payer ${amount.toStringAsFixed(2)} DH par $methodLabel ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmPayment(method, amount);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  /// Confirme et enregistre le paiement
  void _confirmPayment(String method, double amount) {
    final paymentEntry = {
      'method': method,
      'amount': amount,
      'timestamp': DateTime.now(),
    };
    _paymentEntries.add(paymentEntry);
    _remainingAmount -= amount;
    _amountInput = ''; // Réinitialiser le champ
    _amountController.clear();

    // Si le reste est très proche de 0, considérer comme complet
    if (_remainingAmount <= 0.01) {
      _remainingAmount = 0;
      _processFinalPayment();
    } else {
      // Mettre à jour l'interface - utiliser addPostFrameCallback pour éviter setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Traite le paiement final (solde = 0)
  Future<void> _processFinalPayment() async {
    try {
      // Enregistrer le paiement avant de fermer la boîte de dialogue.
      if (_paymentEntries.length == 1) {
        await widget.pos.markOrderAsPaid(
          widget.order,
          _paymentEntries.first['method'] as String,
        );
      } else {
        await widget.pos.markOrderAsPaidWithSplit(
          widget.order,
          _paymentEntries,
        );
      }

      // Synchronisation
      OrderSyncService().syncOrderStatus(
        orderId: widget.order.id,
        status: widget.order.status,
        paymentStatus: 'paid',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccess('Paiement enregistré avec succès');
      }
    } catch (e) {
      appLogger.e('❌ Erreur lors du paiement: $e');
      _showError('Erreur lors de l\'enregistrement du paiement');
    }
  }

  /// Admin: Offer entire order (mark all remaining quantities as offered)
  Future<void> _offerEntireOrder() async {
    try {
      // Build map of itemId -> remainingQty
      final items = await DatabaseService.getPosOrderItems(widget.order.id);
      final Map<int, int> itemQuantities = {};
      for (final it in items) {
        final coveredQty = it.getCoveredQuantity();
        final remaining = (it.quantity - coveredQty).clamp(0, it.quantity);
        if (remaining > 0) itemQuantities[it.id] = remaining;
      }
      if (itemQuantities.isEmpty) {
        _showError('Aucun article restant à offrir');
        return;
      }

      final paymentEntry = {'method': 'offert', 'amount': _remainingAmount};
      appLogger.i('🔍 [OFFERT] order=${widget.order.id} itemQuantities=$itemQuantities paymentEntry=$paymentEntry');

      await widget.pos.markOrderItemsAsPartiallyPaid(
        widget.order,
        itemQuantities,
        [paymentEntry],
      );
      // Vérification post-enregistrement : lire l'état persistant et logger
      try {
        final persistedOrder = await DatabaseService.getPosOrderById(widget.order.id);
        final persistedItems = await DatabaseService.getPosOrderItems(widget.order.id);
        appLogger.i('🔎 [OFFERT] après enregistrement order.paymentSplit=${persistedOrder?.paymentSplit}');
        appLogger.i('🔎 [OFFERT] après enregistrement order.discount=${persistedOrder?.discountAmount} total=${persistedOrder?.totalPrice}');
        for (final it in persistedItems) {
          appLogger.i('🔎 [OFFERT] item=${it.id} partialHistory=${it.partialPaymentHistory} paymentStatus=${it.paymentStatus}');
        }
      } catch (e, st) {
        appLogger.e('❌ [OFFERT] erreur en vérifiant la BD: $e', error: e, stackTrace: st);
      }

      // Refresh and close
      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccess('Offre appliquée et enregistrée');
      }
    } catch (e, st) {
      appLogger.e('❌ Erreur lors de l\'offre: $e\n$st');
      _showError('Erreur lors de l\'application de l\'offre');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showPOSSnack(context, message, title: 'Succès', type: POSSnackType.success);
  }

  void _showError(String message) {
    if (!mounted) return;
    showPOSSnack(context, message, title: 'Erreur', type: POSSnackType.error);
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'tpe':
        return 'TPE';
      case 'en_compte':
        return 'En compte';
      default:
        return method;
    }
  }

  Widget _totalLine(
    String label,
    String value, {
    bool emphasis = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasis ? 15 : 13,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.grisModerne,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 17 : 13,
              fontWeight: emphasis ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.charbon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSummary() {
    final subtotal = _discountBaseTotal;
    final discount = widget.order.hasDiscount ? widget.order.discountAmount : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SushiColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (discount > 0) ...[
            _totalLine('Sous-total:', _formatAmount(subtotal)),
            _totalLine(
              'Remise:',
              '-${_formatAmount(discount.toDouble())}',
              valueColor: SushiColors.green,
            ),
            const Divider(height: 14),
          ],
          _totalLine(
            'Total à payer:',
            _formatAmount(widget.order.totalPrice),
            emphasis: true,
            valueColor: SushiColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountEditor() {
    if (!widget.showEditOption) {
      return const SizedBox.shrink();
    }

    final subtotal = _discountBaseTotal;
    final discount = widget.order.hasDiscount ? widget.order.discountAmount : 0;
    final rate = subtotal > 0 ? (discount / subtotal) * 100 : 0.0;
    final paymentStatus = widget.order.paymentStatus.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SushiColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.percent, size: 18, color: SushiColors.teal),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Remise admin',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (discount > 0)
                Text(
                  '-${_formatAmount(discount.toDouble())} (${rate.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: SushiColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_canEditDiscount)
            Text(
              paymentStatus == 'paid'
                  ? 'Remise verrouillée après paiement.'
                  : 'Remise indisponible pour cette commande.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grisModerne,
              ),
            )
          else ...[
            Row(
              children: [
                ToggleButtons(
                  isSelected: [
                    _discountMode == _DiscountInputMode.percentage,
                    _discountMode == _DiscountInputMode.amount,
                  ],
                  onPressed: _savingDiscount
                      ? null
                      : (index) {
                          setState(() {
                            _discountMode = index == 0
                                ? _DiscountInputMode.percentage
                                : _DiscountInputMode.amount;
                          });
                        },
                  borderRadius: BorderRadius.circular(6),
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 50,
                  ),
                  children: const [Text('%'), Text('DH')],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    enabled: !_savingDiscount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: _discountMode == _DiscountInputMode.percentage
                          ? 'Pourcentage'
                          : 'Montant',
                      suffixText: _discountMode == _DiscountInputMode.percentage
                          ? '%'
                          : 'DH',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onSubmitted: (_) => _applyDiscountFromInput(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _savingDiscount ? null : _applyDiscountFromInput,
                  icon: _savingDiscount
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Appliquer remise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SushiColors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (discount > 0)
                  TextButton.icon(
                    onPressed: _savingDiscount ? null : _clearDiscount,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Supprimer remise'),
                    style: TextButton.styleFrom(
                      foregroundColor: SushiColors.red,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paiement'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Montant total
              _buildTotalsSummary(),

              if (widget.showEditOption) ...[
                const SizedBox(height: 16),
                _buildDiscountEditor(),
              ],

              const SizedBox(height: 16),

              // Champ de saisie du montant
              TextField(
                controller: _amountController,
                onChanged: (value) => setState(() => _amountInput = value),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Montant (optionnel)',
                  suffixText: 'DH',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Historique des paiements
              if (_paymentEntries.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SushiColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paiements effectués:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grisModerne,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._paymentEntries.map((entry) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getPaymentMethodLabel(entry['method'] as String),
                            ),
                            Text(
                              '${(entry['amount'] as double).toStringAsFixed(2)} DH',
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reste à payer
              if (_remainingAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SushiColors.orangePale,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reste à payer:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                      Text(
                        '${_remainingAmount.toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Boutons de méthode de paiement
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentButton(
                    icon: Icons.credit_card,
                    label: 'TPE',
                    method: 'tpe',
                  ),
                  _buildPaymentButton(
                    icon: Icons.money,
                    label: 'Cash',
                    method: 'cash',
                  ),
                  _buildPaymentButton(
                    icon: Icons.account_balance_wallet,
                    label: 'En compte',
                    method: 'en_compte',
                  ),
                  // Offert (admin only)
                  if (Get.find<AuthController>().currentRole == 'admin' ||
                      Get.find<AuthController>().currentRole == 'superadmin')
                    ElevatedButton.icon(
                      onPressed: _remainingAmount <= 0
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Confirmer offre totale'),
                                  content: Text(
                                    'Offrir cette commande pour un montant de ${_remainingAmount.toStringAsFixed(2)} DH ? Cela marquera les articles comme offerts.',
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
                              if (confirmed != true) return;
                              await _offerEntireOrder();
                            },
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Offert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SushiColors.surface,
                        foregroundColor: AppColors.charbon,
                      ),
                    ),
                  // Partial payment button (available to all staff)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final showContext = context;
                        final result = await showDialog<bool>(
                          context: showContext,
                          builder: (c) => PartialPaymentDialog(
                            order: widget.order,
                            pos: widget.pos,
                          ),
                        );
                        if (!mounted) return;
                        final currentContext = context;
                        if (result == true) {
                          _showSuccess('Paiement enregistré avec succès');
                          // ignore: use_build_context_synchronously
                          Navigator.of(currentContext).pop(true);
                          return;
                        }

                        await _refreshPaymentStateFromDatabase();
                      } catch (e, st) {
                        appLogger.e('❌ Erreur paiement partiel: $e\n$st');
                        if (!mounted) return;
                        _showError('Erreur pendant le paiement partiel.');
                      }
                    },
                    icon: const Icon(Icons.splitscreen),
                    label: const Text('Payer partiellement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SushiColors.surface,
                      foregroundColor: AppColors.charbon,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required String method,
  }) {
    final isEnabled = _remainingAmount > 0;
    return ElevatedButton.icon(
      onPressed: isEnabled ? () => _preparePayment(method) : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? SushiColors.surface : Colors.grey.shade300,
        foregroundColor: isEnabled ? AppColors.charbon : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
