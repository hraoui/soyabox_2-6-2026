// ignore_for_file: unused_import

import 'dart:convert';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/cash_register_state.dart';
import '../models/pos_order.dart';
import '../services/database_service.dart';
import '../services/daily_report_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';

class CashRegisterController extends GetxController {
  late final Isar _isar;

  final _currentState = <CashRegisterState>[].obs;
  CashRegisterState? get currentState =>
      _currentState.isEmpty ? null : _currentState.first;

  bool get isCashRegisterOpen => currentState?.isOpen ?? false;
  bool get isCashRegisterLocked => currentState?.isLockedByAdmin ?? false;

  @override
  void onInit() {
    super.onInit();
    // Utiliser la base de données directement car avec lazyPut,
    // elle devrait déjà être initialisée quand ce contrôleur est créé
    _isar = DatabaseService.db;
    loadCurrentState();
  }

  String _todayKey() {
    final today = DateTime.now();
    return "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  }

  CashRegisterState _buildClosedState(String dateStr) {
    return CashRegisterState()
      ..date = dateStr
      ..isOpen = false
      ..isLockedByAdmin = false
      ..openedAt = null
      ..closedAt = null
      ..openedByStaffId = null
      ..openedByStaffName = null
      ..closedByStaffId = null
      ..closedByStaffName = null
      ..closingReport = null
      ..isZeroDataActivated = false
      ..zeroDataActivatedAt = null;
  }

  Future<void> forceResetCashRegister() async {
    try {
      // Supprimer TOUTES les entrées existantes
      await _isar.writeTxn(() async {
        final allStates = await _isar.cashRegisterStates.where().findAll();
        for (final state in allStates) {
          await _isar.cashRegisterStates.delete(state.id);
        }
      });
    } catch (e) {
      // Si la suppression échoue (fichiers corrompus), ignorer et continuer
      print('⚠️ Failed to delete existing states: $e');
    }

    // Créer un nouvel état propre
    await loadCurrentState();
  }

  Future<void> loadCurrentState() async {
    final dateStr = _todayKey();

    final existingState = await _isar.cashRegisterStates
        .where()
        .dateEqualTo(dateStr)
        .findFirst();

    if (existingState != null) {
      _currentState.assignAll([existingState]);
    } else {
      final newState = _buildClosedState(dateStr);
      await _isar.writeTxn(() => _isar.cashRegisterStates.put(newState));
      _currentState.assignAll([newState]);
    }
  }

  Future<bool> closeCashRegister({
    required int staffId,
    required String staffName,
  }) async {
    try {
      // Utiliser DailyReportService pour générer le rapport avec la structure complète
      final today = DateTime.now();
      final closingReportMap = await DailyReportService.generateDailyReport(
        date: today,
        staffId: staffId,
        staffName: staffName,
        openedAt: currentState?.openedAt,
        closedAt: DateTime.now(),
      );

      // Mettre à jour l'état EXISTANT au lieu d'en créer un nouveau
      await _isar.writeTxn(() async {
        if (currentState != null) {
          // Mettre à jour l'état existant
          currentState!.isOpen = false;
          currentState!.closedAt = DateTime.now();
          currentState!.closedByStaffId = staffId;
          currentState!.closedByStaffName = staffName;
          currentState!.closingReport = jsonEncode(closingReportMap);
          currentState!.isLockedByAdmin = false;
          currentState!.isZeroDataActivated = false;
          currentState!.zeroDataActivatedAt = null;

          await _isar.cashRegisterStates.put(currentState!);
        } else {
          // Cas rare : créer un nouvel état si aucun n'existe
          final dateStr = _todayKey();

          final newState = CashRegisterState()
            ..date = dateStr
            ..isOpen = false
            ..closedAt = DateTime.now()
            ..closedByStaffId = staffId
            ..closedByStaffName = staffName
            ..openedAt =
                DateTime.now() // Fallback
            ..openedByStaffId = staffId
            ..openedByStaffName = staffName
            ..closingReport = jsonEncode(closingReportMap)
            ..isLockedByAdmin = false
            ..isZeroDataActivated = false
            ..zeroDataActivatedAt = null;

          await _isar.cashRegisterStates.put(newState);
        }
      });

      // Recharger l'état mis à jour
      await loadCurrentState();

      // Libérer toutes les tables actives avant de réinitialiser l'état POS
      if (Get.isRegistered<PosController>()) {
        final posController = Get.find<PosController>();
        await posController.freeAllTables();
        posController.resetAfterCashRegisterClose();
      }

      return true;
    } catch (e) {
      print("Erreur lors de la fermeture de caisse: $e");
      return false;
    }
  }

  Future<bool> openCashRegister({
    required int staffId,
    required String staffName,
    bool isAdminOverride = false,
  }) async {
    if (currentState == null) {
      await loadCurrentState();
    }
    if (currentState == null) {
      print("Erreur: currentState est null lors de l'ouverture de caisse");
      return false;
    }

    // Vérifier si l'utilisateur est admin ou si c'est un override admin
    if (isCashRegisterLocked && !isAdminOverride) {
      return false; // Ne peut pas ouvrir si verrouillé par admin
    }

    try {
      await _isar.writeTxn(() async {
        final state = CashRegisterState()
          ..date = currentState!.date
          ..id = currentState!.id
          ..isOpen = true
          ..isLockedByAdmin = false
          ..openedAt = DateTime.now()
          ..openedByStaffId = staffId
          ..openedByStaffName = staffName
          ..closedAt = null
          ..closedByStaffId = null
          ..closedByStaffName = null
          ..closingReport = null
          ..isZeroDataActivated = true
          ..zeroDataActivatedAt = DateTime.now();

        await _isar.cashRegisterStates.put(state);
      });

      final updatedState = await _loadCurrentState();
      if (updatedState != null) {
        _currentState.assignAll([updatedState]);
      }
      return true;
    } catch (e) {
      print("Erreur lors de l'ouverture de caisse: $e");
      return false;
    }
  }

  Future<bool> lockCashRegisterAsAdmin() async {
    if (currentState == null) return false;

    // Vérifier si l'utilisateur est admin ou superadmin
    final authController = Get.find<AuthController>();
    if (authController.currentRole != 'admin' &&
        authController.currentRole != 'superadmin') {
      return false;
    }

    try {
      await _isar.writeTxn(() async {
        final updatedState = CashRegisterState()
          ..id = currentState!.id
          ..date = currentState!.date
          ..isOpen = false
          ..isLockedByAdmin = true
          ..closedAt = currentState!.closedAt ?? DateTime.now()
          ..closedByStaffId = currentState!.closedByStaffId
          ..closedByStaffName = currentState!.closedByStaffName
          ..openedAt = currentState!.openedAt
          ..openedByStaffId = currentState!.openedByStaffId
          ..openedByStaffName = currentState!.openedByStaffName
          ..closingReport = currentState!.closingReport
          ..isZeroDataActivated = false
          ..zeroDataActivatedAt = null;

        await _isar.cashRegisterStates.put(updatedState);
      });

      final updatedState = await _loadCurrentState();
      if (updatedState != null) {
        _currentState.assignAll([updatedState]);
      }
      return true;
    } catch (e) {
      print("Erreur lors du verrouillage admin: $e");
      return false;
    }
  }

  Future<bool> unlockCashRegisterAsAdmin() async {
    // Vérifier si l'utilisateur est admin ou superadmin
    final authController = Get.find<AuthController>();
    if (authController.currentRole != 'admin' &&
        authController.currentRole != 'superadmin') {
      return false;
    }

    // Utiliser la méthode existante openCashRegister avec override admin
    final auth = Get.find<AuthController>();
    return await openCashRegister(
      staffId: auth.currentUser?.id ?? 0,
      staffName: auth.currentUser?.name ?? 'Admin',
      isAdminOverride: true,
    );
  }

  Future<CashRegisterState?> _loadCurrentState() async {
    final dateStr = _todayKey();

    final state = await _isar.cashRegisterStates
        .filter()
        .dateEqualTo(dateStr)
        .findFirst();

    if (state != null) {
      _currentState.assignAll([state]);
    } else {
      final newState = _buildClosedState(dateStr);
      await _isar.writeTxn(() => _isar.cashRegisterStates.put(newState));
      _currentState.assignAll([newState]);
    }
    return _currentState.isNotEmpty ? _currentState.first : null;
  }
}
