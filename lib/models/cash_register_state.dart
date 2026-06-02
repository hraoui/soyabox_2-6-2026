import 'package:isar/isar.dart';

part 'cash_register_state.g.dart';

@Collection()
class CashRegisterState {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String date; // Format YYYY-MM-DD

  bool isOpen = false;
  DateTime? openedAt;
  DateTime? closedAt;
  int? openedByStaffId;
  String? openedByStaffName;
  int? closedByStaffId;
  String? closedByStaffName;
  String? closingReport; // JSON string with daily summary data
  bool isLockedByAdmin = false; // Pour indiquer si bloqué par admin
  bool isZeroDataActivated =
      false; // Indique si les anciennes commandes sont cachées
  DateTime? zeroDataActivatedAt; // Timestamp de l'activation zéro data
}
