import 'package:get/get.dart';
import '../data/app_constants.dart';
import '../models/pos_table.dart';
import '../services/api_import_service.dart';
import '../services/database_service.dart';

class TableController extends GetxController {
  static TableController get instance => Get.find();

  final List<PosTable> _tables = [];
  bool _loading = false;
  String _error = '';

  List<PosTable> get tables => List<PosTable>.unmodifiable(_tables);
  bool get isLoading => _loading;
  String get error => _error;

  late ApiImportService _apiService;

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    // ❌ DO NOT auto-fetch tables - wait for manual import via Import Data screen
    // ✅ Tables are manual import only
    print('🪑 [TABLE] TableController initialized (waiting for manual import)');
    _apiService = ApiImportService(baseUrl: AppConstant.baseUrl);
  }

  void setBaseUrl(String baseUrl) {
    _apiService = ApiImportService(baseUrl: baseUrl);
  }

  Future<void> loadTables({int? restaurantId}) async {
    _loading = true;
    _error = '';
    update();
    try {
      final list = restaurantId == null
          ? await DatabaseService.getPosTables()
          : await DatabaseService.getPosTablesByRestaurant(restaurantId);
      _tables
        ..clear()
        ..addAll(list);
      update();
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }

  Future<void> importTables({int? restaurantId}) async {
    _loading = true;
    _error = '';
    update();
    try {
      await _apiService.importTables(restaurantId: restaurantId);
      await loadTables(restaurantId: restaurantId);
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }

  Future<void> createTable({
    required String number,
    required String status,
    required int restaurantId,
    required int gridColumnStart,
    required int gridColumnEnd,
    required int gridRowStart,
    required int gridRowEnd,
  }) async {
    _loading = true;
    _error = '';
    update();
    try {
      final created = await _apiService.createTable(
        number: number,
        status: status,
        restaurantId: restaurantId,
        gridColumnStart: gridColumnStart,
        gridColumnEnd: gridColumnEnd,
        gridRowStart: gridRowStart,
        gridRowEnd: gridRowEnd,
      );
      if (created != null) {
        await DatabaseService.createPosTable(created);
      }
      await loadTables(restaurantId: restaurantId);
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }

  Future<void> updateTable({
    required PosTable table,
    required String number,
    required String status,
    required int gridColumnStart,
    required int gridColumnEnd,
    required int gridRowStart,
    required int gridRowEnd,
  }) async {
    _loading = true;
    _error = '';
    update();
    try {
      if (table.remoteId != null) {
        final updated = await _apiService.updateTable(
          remoteId: table.remoteId!,
          number: number,
          status: status,
          gridColumnStart: gridColumnStart,
          gridColumnEnd: gridColumnEnd,
          gridRowStart: gridRowStart,
          gridRowEnd: gridRowEnd,
        );
        if (updated != null) {
          updated.id = table.id;
          await DatabaseService.updatePosTable(updated);
        }
      } else {
        table.number = number;
        table.status = status;
        table.gridColumnStart = gridColumnStart;
        table.gridColumnEnd = gridColumnEnd;
        table.gridRowStart = gridRowStart;
        table.gridRowEnd = gridRowEnd;
        await DatabaseService.updatePosTable(table);
      }
      await loadTables(restaurantId: table.restaurantId);
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }

  Future<void> deleteTable(PosTable table) async {
    _loading = true;
    _error = '';
    update();
    try {
      if (table.remoteId != null) {
        await _apiService.deleteTable(remoteId: table.remoteId!);
      }
      await DatabaseService.deletePosTable(table.id);
      await loadTables(restaurantId: table.restaurantId);
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }

  Future<void> changeStatus(PosTable table, String status) async {
    _loading = true;
    _error = '';
    update();
    try {
      if (table.remoteId != null) {
        final updated = await _apiService.changeTableStatus(
          remoteId: table.remoteId!,
          status: status,
        );
        if (updated != null) {
          updated.id = table.id;
          await DatabaseService.updatePosTable(updated);
        }
      } else {
        table.status = status;
        await DatabaseService.updatePosTable(table);
      }
      await loadTables(restaurantId: table.restaurantId);
    } catch (e) {
      _error = e.toString();
      update();
      rethrow;
    } finally {
      _loading = false;
      update();
    }
  }
}
