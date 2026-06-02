import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/table_controller.dart';
import '../models/pos_table.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/admin_shell.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TableController>()) {
      Get.put(TableController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantController = Get.find<RestaurantController>();
      final restaurants = restaurantController.getActiveRestaurants();
      final auth = Get.find<AuthController>();
      final role = auth.currentRole ?? '';
      if (role == 'superadmin') {
        if (restaurantController.selectedRestaurantId == null &&
            restaurants.isNotEmpty) {
          restaurantController.setSelectedRestaurantId(restaurants.first.id);
        }
        Get.find<TableController>().loadTables(
          restaurantId: restaurantController.selectedRestaurantId,
        );
      } else {
        final restId = auth.currentUser?.restaurantId;
        Get.find<TableController>().loadTables(restaurantId: restId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final restaurantController = Get.find<RestaurantController>();

    final role = auth.currentRole ?? '';
    final isAllowed = role == 'admin' || role == 'superadmin';

    return AdminShell(
      title: 'Tables',
      activeRoute: '/tables',
      floatingActionButton: isAllowed
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context),
              backgroundColor: AppColors.terraCotta,
              child: const Icon(Icons.add),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAllowed)
            const Center(
              child: Text(
                'Accès réservé aux administrateurs.',
                style: TextStyle(fontSize: 16),
              ),
            )
          else ...[
            if (role == 'superadmin')
              Row(
                children: [
                  Expanded(child: _restaurantPicker(restaurantController)),
                  const SizedBox(width: AppSpacing.md),
                  GetBuilder<TableController>(
                    builder: (tableController) {
                      return ElevatedButton.icon(
                        onPressed: tableController.isLoading
                            ? null
                            : () async {
                                try {
                                  await tableController.importTables(
                                    restaurantId: restaurantController
                                        .selectedRestaurantId,
                                  );
                                  if (mounted) {
                                    Get.snackbar(
                                      'Succès',
                                      'Tables importées avec succès !',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Get.snackbar(
                                      'Erreur',
                                      'Échec de l\'import des tables : $e',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Importer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terraCotta,
                          foregroundColor: AppColors.blancPur,
                        ),
                      );
                    },
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: GetBuilder<TableController>(
                builder: (tableController) {
                  if (tableController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (tableController.tables.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune table pour ce restaurant',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppWrapGrid.builder(
                      itemCount: tableController.tables.length,
                      minChildWidth: 300,
                      maxChildWidth: 360,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      itemBuilder: (context, index) {
                        final table = tableController.tables[index];
                        return _tableCard(table);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _restaurantPicker(RestaurantController controller) {
    return GetBuilder<RestaurantController>(
      builder: (restaurantController) {
        final restaurants = restaurantController.getActiveRestaurants();
        if (restaurants.isEmpty) {
          return const Text('Aucun restaurant', style: AppTypography.caption);
        }
        final selectedId =
            restaurantController.selectedRestaurantId ?? restaurants.first.id;
        return DropdownButtonFormField<int>(
          initialValue: selectedId,
          decoration: const InputDecoration(
            labelText: 'Restaurant',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final r in restaurants)
              DropdownMenuItem<int>(value: r.id, child: Text(r.name)),
          ],
          onChanged: (value) async {
            restaurantController.setSelectedRestaurantId(value);
            await Get.find<TableController>().loadTables(restaurantId: value);
          },
        );
      },
    );
  }

  Widget _tableCard(PosTable table) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _statusColor(table.status),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  table.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table.number}',
                      style: AppTypography.headline2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(table.status),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grisModerne,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditDialog(context, table);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, table);
                  } else {
                    await Get.find<TableController>().changeStatus(
                      table,
                      value,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'available',
                    child: Text('Disponible'),
                  ),
                  const PopupMenuItem(
                    value: 'reserved',
                    child: Text('Reservee'),
                  ),
                  const PopupMenuItem(
                    value: 'occupied',
                    child: Text('Occupee'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _tableInfoChip(
                Icons.grid_4x4_rounded,
                'Colonnes ${table.gridColumnStart}-${table.gridColumnEnd}',
              ),
              _tableInfoChip(
                Icons.view_agenda_outlined,
                'Lignes ${table.gridRowStart}-${table.gridRowEnd}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grisPale,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.terraCotta),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'free':
        return const Color(0xFF00FF3C);
      case 'reserved':
        return const Color(0xFFFFBB00);
      case 'occupied':
        return const Color(0xFFFF0033);
      case 'available':
      default:
        return const Color(0xFF00FF3C);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'free':
        return 'Disponible';
      case 'reserved':
        return 'Réservée';
      case 'occupied':
        return 'Occupée';
      case 'available':
      default:
        return 'Disponible';
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = Get.find<TableController>();
    final numberController = TextEditingController();
    final colStartController = TextEditingController(text: '1');
    final colEndController = TextEditingController(text: '2');
    final rowStartController = TextEditingController(text: '1');
    final rowEndController = TextEditingController(text: '2');
    String status = 'available';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Numéro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Disponible'),
                    ),
                    DropdownMenuItem(
                      value: 'reserved',
                      child: Text('Réservée'),
                    ),
                    DropdownMenuItem(value: 'occupied', child: Text('Occupée')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    status = value;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: colStartController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Colonne début'),
                ),
                TextField(
                  controller: colEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Colonne fin'),
                ),
                TextField(
                  controller: rowStartController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ligne début'),
                ),
                TextField(
                  controller: rowEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ligne fin'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final number = numberController.text.trim();
                final restaurantId =
                    Get.find<RestaurantController>().selectedRestaurantId;
                if (number.isEmpty || restaurantId == null) return;

                await controller.createTable(
                  number: number,
                  status: status,
                  restaurantId: restaurantId,
                  gridColumnStart: int.tryParse(colStartController.text) ?? 1,
                  gridColumnEnd: int.tryParse(colEndController.text) ?? 2,
                  gridRowStart: int.tryParse(rowStartController.text) ?? 1,
                  gridRowEnd: int.tryParse(rowEndController.text) ?? 2,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, PosTable table) async {
    final controller = Get.find<TableController>();
    final numberController = TextEditingController(text: table.number);
    final colStartController = TextEditingController(
      text: table.gridColumnStart.toString(),
    );
    final colEndController = TextEditingController(
      text: table.gridColumnEnd.toString(),
    );
    final rowStartController = TextEditingController(
      text: table.gridRowStart.toString(),
    );
    final rowEndController = TextEditingController(
      text: table.gridRowEnd.toString(),
    );
    String status = table.status;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Numéro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Disponible'),
                    ),
                    DropdownMenuItem(
                      value: 'reserved',
                      child: Text('Réservée'),
                    ),
                    DropdownMenuItem(value: 'occupied', child: Text('Occupée')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    status = value;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: colStartController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Colonne début'),
                ),
                TextField(
                  controller: colEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Colonne fin'),
                ),
                TextField(
                  controller: rowStartController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ligne début'),
                ),
                TextField(
                  controller: rowEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ligne fin'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final number = numberController.text.trim();
                if (number.isEmpty) return;

                await controller.updateTable(
                  table: table,
                  number: number,
                  status: status,
                  gridColumnStart: int.tryParse(colStartController.text) ?? 1,
                  gridColumnEnd: int.tryParse(colEndController.text) ?? 2,
                  gridRowStart: int.tryParse(rowStartController.text) ?? 1,
                  gridRowEnd: int.tryParse(rowEndController.text) ?? 2,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, PosTable table) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer table'),
          content: Text('Supprimer ${table.number} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Get.find<TableController>().deleteTable(table);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
