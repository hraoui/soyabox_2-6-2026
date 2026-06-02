import 'dart:convert';

import 'package:flutter/material.dart';

import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../services/database_service.dart';
import '../services/order_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import 'partial_payment_dialog.dart';
import '../widgets/pos_ui.dart';

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

  @override
  void initState() {
    super.initState();
    _applyOrderPaymentState(widget.order);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyOrderPaymentState(PosOrder order) {
    _paymentEntries.clear();

    double alreadyPaid = 0.0;
    if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
      try {
        final decoded = jsonDecode(order.paymentSplit!);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final rawAmount = e['amount'] ?? e['montant'] ?? 0;
              final amount = rawAmount is num
                  ? rawAmount.toDouble()
                  : double.tryParse(
                          rawAmount.toString().replaceAll(',', '.'),
                        ) ??
                        0.0;
              final method = (e['payment_method'] ?? e['method'] ?? 'unknown')
                  .toString();
              alreadyPaid += amount;
              _paymentEntries.add({
                'method': method,
                'amount': amount,
                'timestamp': e['timestamp'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
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

      setState(() {
        _applyOrderPaymentState(latestOrder);
      });
    } catch (e) {
      appLogger.e('❌ Impossible de rafraîchir le paiement: $e');
    }
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
      // Fermer le dialog
      if (mounted) {
        Navigator.of(context).pop(true);
      }

      // Enregistrer le paiement
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

      _showSuccess('Paiement enregistré avec succès');
    } catch (e) {
      appLogger.e('❌ Erreur lors du paiement: $e');
      _showError('Erreur lors de l\'enregistrement du paiement');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paiement'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montant total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SushiColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant total:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grisModerne,
                    ),
                  ),
                  Text(
                    '${widget.order.totalPrice.toStringAsFixed(2)} DH',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charbon,
                    ),
                  ),
                ],
              ),
            ),

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
                // Partial payment button
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

            const SizedBox(height: 16),

            // Option d'édition pour admin
            if (widget.showEditOption) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implémenter l'édition de paiement pour admin
                  _showInfo(
                    'Fonctionnalité d\'édition réservée aux administrateurs',
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier paiement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal.withOpacity(0.1),
                  foregroundColor: AppColors.deepTeal,
                ),
              ),
            ],
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

  void _showInfo(String message) {
    if (!mounted) return;
    showPOSSnack(context, message, type: POSSnackType.info);
  }
}
