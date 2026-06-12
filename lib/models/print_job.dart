import 'dart:convert';

import 'package:isar/isar.dart';

part 'print_job.g.dart';

@Collection()
class PrintJob {
  Id id = Isar.autoIncrement;

  String ticketType; // 'customer','kitchen','report',...

  String printerHost;

  int printerPort;

  /// Payload ESC/POS stored as base64 to keep Isar schema simple
  String payloadBase64;

  DateTime? nextAttemptAt;

  String status; // 'pending','printing','printed','failed'

  int retryCount;

  DateTime? createdAt;

  DateTime? printedAt;

  String? errorMessage;

  String? orderRef;

  PrintJob({
    this.id = Isar.autoIncrement,
    required this.ticketType,
    required this.printerHost,
    required this.printerPort,
    required this.payloadBase64,
    this.status = 'pending',
    this.retryCount = 0,
    DateTime? createdAt,
    this.printedAt,
    this.errorMessage,
    this.orderRef,
  })  : createdAt = createdAt ?? DateTime.now(),
        nextAttemptAt = createdAt ?? DateTime.now();

  List<int> get payloadBytes => base64Decode(payloadBase64);
}
