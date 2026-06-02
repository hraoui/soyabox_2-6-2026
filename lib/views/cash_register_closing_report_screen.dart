import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_register_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/database_service.dart';

class CashRegisterClosingReportScreen extends StatelessWidget {
  const CashRegisterClosingReportScreen({super.key});

  Future<void> _closeCashRegister(BuildContext context) async {
    final authController = Get.find<AuthController>();
    final staffId = authController.currentUser?.id ?? 0;
    final staffName = authController.currentUser?.name ?? 'Inconnu';
    final controller = Get.find<CashRegisterController>();

    final confirmed = await _confirmClose(context: context);
    if (!context.mounted || !confirmed) {
      return;
    }

    final success = await controller.closeCashRegister(
      staffId: staffId,
      staffName: staffName,
    );
    
    if (success) {
      Get.snackbar('Succès', 'Caisse fermée avec succès');
      // Rediriger selon le rôle de l'utilisateur
      if (authController.currentUser?.role == 'cashier') {
        Get.offAllNamed('/cashier-dashboard');
      } else {
        Get.offAllNamed('/dashboard');
      }
    } else {
      Get.snackbar('Erreur', 'Impossible de fermer la caisse', 
        snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> _confirmClose({
    required BuildContext context,
  }) async {
    final authController = Get.find<AuthController>();
    final restaurantId = authController.currentUser?.restaurantId;
    final navigator = Navigator.of(context);
    final allOrders = await DatabaseService.getPosOrders();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final todaysOrders = allOrders.where((order) {
      if (order.restaurantId != restaurantId) return false;
      final orderDate = order.createdAt.toIso8601String().split('T')[0];
      return orderDate == todayStr;
    }).toList();

    final paidCount = todaysOrders
        .where((order) => order.status.trim().toLowerCase() == 'paid')
        .length;
    final unpaidCount = todaysOrders
        .where((order) => order.status.trim().toLowerCase() != 'paid')
        .length;
    final totalCount = todaysOrders.length;

    if (!navigator.mounted) {
      return false;
    }

    return await showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Confirmer la fermeture'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vous êtes sur le point de fermer la caisse.'),
                  const SizedBox(height: 12),
                  Text('Commandes du jour: $totalCount'),
                  Text('Payées: $paidCount'),
                  Text('Non payées: $unpaidCount'),
                  const SizedBox(height: 12),
                  const Text(
                    'Toutes les tables seront libérées. ' 
                    'Après activation, les anciennes commandes seront cachées comme une nouvelle journée.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashRegisterController>();
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermeture de Caisse'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Prêt à fermer la caisse ?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      'Ouverte depuis: ${controller.currentState?.openedAt?.toString().split(' ')[1].split('.')[0] ?? 'Inconnu'}',
                      style: const TextStyle(fontSize: 16),
                    )),
                    const SizedBox(height: 8),
                    Text(
                      'Caissier: ${authController.currentUser?.name ?? 'Inconnu'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _closeCashRegister(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'FERMER LA CAISSE MAINTENANT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}