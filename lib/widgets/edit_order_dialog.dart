import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';
import '../models/pos_order.dart';
import '../services/app_settings_service.dart';
import '../theme/sushi_design.dart';

class EditOrderDialog extends StatefulWidget {
  final PosOrder order;

  const EditOrderDialog({super.key, required this.order});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  late TextEditingController _totalPriceController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _noteController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _totalPriceController = TextEditingController(
      text: widget.order.totalPrice.toStringAsFixed(2),
    );
    _customerNameController = TextEditingController(
      text: widget.order.customerName ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: widget.order.customerPhone ?? '',
    );
    _noteController = TextEditingController(text: widget.order.note ?? '');
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final newTotal = double.tryParse(_totalPriceController.text);
      if (newTotal == null || newTotal < 0) {
        throw Exception('Montant total invalide');
      }

      widget.order.totalPrice = newTotal;
      widget.order.customerName = _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim();
      widget.order.customerPhone = _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim();
      widget.order.note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      widget.order.updatedAt = DateTime.now();

      final result = await DatabaseService.updatePosOrder(widget.order);

      if (result != 0) {
        // Enqueue for sync to backend
        await SyncQueueService.instance.enqueueOrderUpsert(widget.order, []);

        if (mounted) {
          Get.back(result: true);
          Get.snackbar(
            'Succès',
            'Commande #${widget.order.id} modifiée avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
          );
        }
      } else {
        throw Exception('Échec de la modification de la commande');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: SushiColors.teal),
                const SizedBox(width: SushiSpace.sm),
                const Text(
                  'Modifier la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '#${widget.order.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: SushiSpace.xl),
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildField(
                    label: 'Montant total',
                    controller: _totalPriceController,
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildField(
                    label: 'Nom du client',
                    controller: _customerNameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildField(
                    label: 'Téléphone du client',
                    controller: _customerPhoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildField(
                    label: 'Note',
                    controller: _noteController,
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildReadOnlyField(
                    label: 'Canal',
                    value: widget.order.channel.toUpperCase(),
                    icon: Icons.device_hub,
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildReadOnlyField(
                    label: 'Statut',
                    value: widget.order.status.toUpperCase(),
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: SushiSpace.md),
                  _buildReadOnlyField(
                    label: 'Méthode de paiement',
                    value: widget.order.paymentMethod?.toUpperCase() ?? 'N/A',
                    icon: Icons.payment,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SushiSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: SushiSpace.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SushiColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: SushiColors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SushiRadius.sm),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SushiRadius.sm),
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
      ),
    );
  }
}

class CancelOrderDialog extends StatefulWidget {
  final PosOrder order;

  const CancelOrderDialog({super.key, required this.order});

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    setState(() => _isLoading = true);

    try {
      widget.order.status = 'cancelled';
      widget.order.cancelReason = _reasonController.text.trim().isEmpty
          ? 'Annulé par administrateur'
          : _reasonController.text.trim();
      widget.order.updatedAt = DateTime.now();

      final result = await DatabaseService.updatePosOrder(widget.order);

      if (result != 0) {
        // Enqueue for sync to backend
        await SyncQueueService.instance.enqueueOrderUpsert(widget.order, []);

        if (mounted) {
          Get.back(result: true);
          Get.snackbar(
            'Succès',
            'Commande #${widget.order.id} annulée',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFD32F2F),
            colorText: Colors.white,
          );
        }
      } else {
        throw Exception('Échec de l\'annulation de la commande');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFD32F2F)),
                const SizedBox(width: SushiSpace.sm),
                const Text(
                  'Annuler la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: SushiSpace.xl),
            Text(
              'Commande #${widget.order.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: SushiSpace.sm),
            Text(
              'Montant: ${AppSettingsService.instance.formatAmount(widget.order.totalPrice)}',
              style: const TextStyle(
                fontSize: 14,
                color: SushiColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SushiSpace.md),
            const Text(
              'Raison de l\'annulation (optionnel):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: SushiSpace.sm),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Erreur de saisie, client parti, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SushiRadius.sm),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: SushiSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: SushiSpace.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Confirmer l\'annulation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
