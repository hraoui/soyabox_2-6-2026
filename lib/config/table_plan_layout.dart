import 'package:flutter/foundation.dart';

@immutable
class TablePlanSlot {
  final String tableNumber;
  final int row;
  final int col;

  const TablePlanSlot({
    required this.tableNumber,
    required this.row,
    required this.col,
  });
}

const int kPlanCols = 12;
const int kPlanRows = 6;

const List<TablePlanSlot> kTablePlanSlots = [
  TablePlanSlot(tableNumber: 'T1', row: 0, col: 0),
  TablePlanSlot(tableNumber: 'T2', row: 0, col: 1),
  TablePlanSlot(tableNumber: 'T3', row: 0, col: 2),
  TablePlanSlot(tableNumber: 'T4', row: 0, col: 3),
  TablePlanSlot(tableNumber: 'T5', row: 0, col: 4),
  TablePlanSlot(tableNumber: 'T6', row: 0, col: 5),
  TablePlanSlot(tableNumber: 'T7', row: 0, col: 6),
  TablePlanSlot(tableNumber: 'T8', row: 0, col: 7),
  TablePlanSlot(tableNumber: 'T9', row: 1, col: 0),
  TablePlanSlot(tableNumber: 'T10', row: 1, col: 1),
  TablePlanSlot(tableNumber: 'T11', row: 1, col: 2),
  TablePlanSlot(tableNumber: 'T12', row: 1, col: 3),
  TablePlanSlot(tableNumber: 'T13', row: 1, col: 4),
  TablePlanSlot(tableNumber: 'T14', row: 1, col: 5),
  TablePlanSlot(tableNumber: 'T15', row: 1, col: 6),
  TablePlanSlot(tableNumber: 'T16', row: 1, col: 7),
  TablePlanSlot(tableNumber: 'T17', row: 4, col: 0),
  TablePlanSlot(tableNumber: 'T18', row: 4, col: 1),
  TablePlanSlot(tableNumber: 'T19', row: 4, col: 2),
  TablePlanSlot(tableNumber: 'T20', row: 4, col: 3),
  TablePlanSlot(tableNumber: 'T21', row: 4, col: 4),
  TablePlanSlot(tableNumber: 'T22', row: 4, col: 5),
  TablePlanSlot(tableNumber: 'T23', row: 4, col: 6),
  TablePlanSlot(tableNumber: 'T24', row: 4, col: 7),
  TablePlanSlot(tableNumber: 'T25', row: 5, col: 0),
  TablePlanSlot(tableNumber: 'T26', row: 5, col: 1),
  TablePlanSlot(tableNumber: 'T27', row: 5, col: 2),
  TablePlanSlot(tableNumber: 'T28', row: 5, col: 3),
  TablePlanSlot(tableNumber: 'T29', row: 5, col: 4),
  TablePlanSlot(tableNumber: 'T30', row: 5, col: 5),
  TablePlanSlot(tableNumber: 'T31', row: 0, col: 9),
  TablePlanSlot(tableNumber: 'T32', row: 1, col: 9),
  TablePlanSlot(tableNumber: 'T33', row: 2, col: 9),
  TablePlanSlot(tableNumber: 'T34', row: 3, col: 9),
  TablePlanSlot(tableNumber: 'T35', row: 4, col: 9),
  TablePlanSlot(tableNumber: 'T36', row: 5, col: 9),
  TablePlanSlot(tableNumber: 'T37', row: 0, col: 10),
  TablePlanSlot(tableNumber: 'T38', row: 1, col: 10),
  TablePlanSlot(tableNumber: 'T39', row: 2, col: 10),
  TablePlanSlot(tableNumber: 'T40', row: 3, col: 10),
  TablePlanSlot(tableNumber: 'T41', row: 4, col: 10),
  TablePlanSlot(tableNumber: 'T42', row: 5, col: 10),
];

final Map<String, TablePlanSlot> kTablePlanSlotsByNumber = {
  for (final slot in kTablePlanSlots) slot.tableNumber: slot,
};

final RegExp _tableNamePattern = RegExp(r'^T(\d+)$');

String normalizeTableName(String? value) {
  if (value == null) return '';
  return value.trim().toUpperCase();
}

bool isValidPlanName(String? value) {
  final normalized = normalizeTableName(value);
  final match = _tableNamePattern.firstMatch(normalized);
  if (match == null) return false;
  final number = int.tryParse(match.group(1)!);
  if (number == null) return false;
  return number >= 1 && number <= 42;
}
