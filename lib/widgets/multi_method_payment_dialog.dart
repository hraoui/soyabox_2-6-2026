import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../services/order_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/pos_ui.dart';

/// Dialog de paiement multi-méthodes avec logique séquentielle
/// Supporte les paiements uniques et multiples avec gestion du reste
class MultiMethodPaymentDialog extends StatefulWidget {
  final PosOrder order;
  final PosController pos;

  const MultiMethodPaymentDialog({
    super.key,
    required this.order,
    required this.pos,
  });

  @override
  State<MultiMethodPaymentDialog> createState() =>
      _MultiMethodPaymentDialogState();
}

class _MultiMethodPaymentDialogState extends State<MultiMethodPaymentDialog> {
  double _remainingAmount = 0.0;
  final List<Map<String, dynamic>> _paymentEntries = [];
  String? _manualAmountInput = '';
  bool _showManualInput = false;
  String? _selectedMethodForManualInput;

  // Backup: Garder référence au système actuel
  final bool _useBackupSystem = false;

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.order.totalPrice;
    _manualAmountInput = _remainingAmount.toStringAsFixed(2);
  }

  /// Gère le paiement unique (clic direct sur méthode sans montant)
  void _handleSinglePayment(String method) {
    if (_remainingAmount <= 0) return;

    final paymentEntry = {
      'method': method,
      'amount': _remainingAmount,
      'timestamp': DateTime.now(),
    };
    _paymentEntries.add(paymentEntry);
    _remainingAmount = 0;
    _showManualInput = false;
    _manualAmountInput = '';

    // Paiement complet - procéder à l'enregistrement
    _processPayment();
  }

  /// Affiche le champ de saisie manuelle pour un montant partiel
  void _showManualAmountInput(String method) {
    _selectedMethodForManualInput = method;
    _showManualInput = true;
    _manualAmountInput = _remainingAmount.toStringAsFixed(2);
  }

  /// Valide et ajoute un paiement partiel
  void _addPartialPayment() {
    if (_selectedMethodForManualInput == null || _manualAmountInput == null) {
      return;
    }

    final amountText = _manualAmountInput!.trim();
    if (amountText.isEmpty) {
      _notify('Veuillez entrer un montant', type: POSSnackType.warning);
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _notify('Montant invalide', type: POSSnackType.error);
      return;
    }

    if (amount > _remainingAmount) {
      _notify(
        'Le montant ne peut pas dépasser ${_remainingAmount.toStringAsFixed(2)} DA',
        type: POSSnackType.warning,
      );
      return;
    }

    final paymentEntry = {
      'method': _selectedMethodForManualInput!,
      'amount': amount,
      'timestamp': DateTime.now(),
    };
    _paymentEntries.add(paymentEntry);
    _remainingAmount -= amount;
    _showManualInput = false;
    _manualAmountInput = '';
    _selectedMethodForManualInput = null;

    // Si le reste est 0, procéder au paiement
    if (_remainingAmount <= 0.01) {
      _remainingAmount = 0;
      _processPayment();
    }
  }

  /// Procède à l'enregistrement du paiement
  Future<void> _processPayment() async {
    try {
      if (_paymentEntries.isEmpty) {
        _notify('Aucun paiement effectué', type: POSSnackType.error);
        return;
      }

      // Fermer le dialog avant le traitement
      if (mounted) {
        Navigator.of(context).pop(true);
      }

      // Logique d'enregistrement
      if (_paymentEntries.length == 1) {
        // Paiement simple
        await widget.pos.markOrderAsPaid(
          widget.order,
          _paymentEntries.first['method'] as String,
        );
      } else {
        // Paiement multiple (split)
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

      _notify(
        'Paiement enregistré avec succès',
        title: 'Succès',
        type: POSSnackType.success,
      );
    } catch (e) {
      appLogger.e('❌ Erreur lors du paiement: $e');

      // ⚠️ BACKUP STRATEGY: Réessayer avec l'ancien système
      await _fallbackToLegacyPayment();
    }
  }

  /// Stratégie de backup: Utiliser l'ancien système de paiement
  Future<void> _fallbackToLegacyPayment() async {
    try {
      _notify(
        'Tentative de backup avec l\'ancien système...',
        type: POSSnackType.info,
      );

      // Utiliser le système existant comme backup
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ancien système de paiement'),
          content: Text(
            'Total: ${widget.order.totalPrice.toStringAsFixed(2)} DA',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
                // Ici on pourrait appeler l'ancienne logique
                // Mais pour l'instant, on notifie juste l'utilisateur
                _notify(
                  'Veuillez utiliser l\'option de paiement existante',
                  type: POSSnackType.warning,
                );
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (result == true) {
        // L'utilisateur devra utiliser le système existant
        // C'est un backup minimal mais fonctionnel
      }
    } catch (backupError) {
      appLogger.e('❌ Backup également échoué: $backupError');
      _notify(
        'Erreur critique: Impossible de traiter le paiement',
        title: 'Erreur',
        type: POSSnackType.error,
      );
    }
  }

  void _notify(
    String message, {
    String? title,
    POSSnackType type = POSSnackType.info,
  }) {
    if (!mounted) return;
    showPOSSnack(context, message, title: title, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paiement Multi-Méthodes'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montant total et reste
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SushiColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total commande:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grisModerne,
                        ),
                      ),
                      Text(
                        '${widget.order.totalPrice.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charbon,
                        ),
                      ),
                    ],
                  ),
                  if (_paymentEntries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reste à payer:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grisModerne,
                          ),
                        ),
                        Text(
                          '${_remainingAmount.toStringAsFixed(2)} DA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remainingAmount > 0
                                ? AppColors.deepTeal
                                : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Entrée manuelle du montant (si affichée)
            if (_showManualInput) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SushiColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant pour ${_getPaymentMethodLabel(_selectedMethodForManualInput!)}:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(
                        text: _manualAmountInput,
                      ),
                      onChanged: (value) =>
                          setState(() => _manualAmountInput = value),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Entrez le montant',
                        suffixText: 'DA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _showManualInput = false;
                            _manualAmountInput = '';
                            _selectedMethodForManualInput = null;
                          }),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: _addPartialPayment,
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Historique des paiements
            if (_paymentEntries.isNotEmpty) ...[
              const Text(
                'Paiements effectués:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grisModerne,
                ),
              ),
              const SizedBox(height: 8),
              ..._paymentEntries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getPaymentMethodLabel(entry['method'] as String)),
                      Text(
                        '${(entry['amount'] as double).toStringAsFixed(2)} DA',
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Boutons de méthode de paiement
            const Text(
              'Choisissez une méthode de paiement:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grisModerne,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPaymentMethodButton(
                  icon: Icons.credit_card,
                  label: 'TPE',
                  method: 'tpe',
                ),
                _buildPaymentMethodButton(
                  icon: Icons.money,
                  label: 'Espèces',
                  method: 'cash',
                ),
                _buildPaymentMethodButton(
                  icon: Icons.account_balance_wallet,
                  label: 'En compte',
                  method: 'en_compte',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_paymentEntries.isNotEmpty && _remainingAmount > 0)
          TextButton(
            onPressed: () {
              // Option pour compléter automatiquement avec la dernière méthode
              if (_paymentEntries.isNotEmpty) {
                final lastMethod = _paymentEntries.last['method'] as String;
                _handleSinglePayment(lastMethod);
              }
            },
            child: const Text('Compléter'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton({
    required IconData icon,
    required String label,
    required String method,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        if (_remainingAmount <= 0) return;

        // Si c'est le premier paiement ou si on veut payer le reste complet
        if (_paymentEntries.isEmpty || !_showManualInput) {
          // Proposer les deux options: paiement complet ou partiel
          _showPaymentOptionDialog(method);
        } else {
          // Ajouter directement comme paiement partiel
          _showManualAmountInput(method);
        }
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SushiColors.surface,
        foregroundColor: AppColors.charbon,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showPaymentOptionDialog(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paiement ${_getPaymentMethodLabel(method)}'),
        content: const Text('Comment souhaitez-vous procéder?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSinglePayment(method);
            },
            child: const Text('Payer le total'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualAmountInput(method);
            },
            child: const Text('Entrer un montant'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'tpe':
        return 'TPE';
      case 'en_compte':
        return 'En compte';
      default:
        return method;
    }
  }
}
