import 'package:isar/isar.dart';

part 'pos_table.g.dart';

@Collection()
class PosTable {
  Id id = Isar.autoIncrement;
  int? remoteId;
  int? restaurantId;
  String number;
  String status; // available | reserved | occupied
  int gridColumnStart;
  int gridColumnEnd;
  int gridRowStart;
  int gridRowEnd;

  PosTable({
    this.id = Isar.autoIncrement,
    this.remoteId,
    this.restaurantId,
    required this.number,
    this.status = 'available',
    this.gridColumnStart = 1,
    this.gridColumnEnd = 2,
    this.gridRowStart = 1,
    this.gridRowEnd = 2,
  });
}
