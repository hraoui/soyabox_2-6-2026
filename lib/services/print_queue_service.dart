import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../services/database_service.dart';
import '../models/print_job.dart';

class PrintQueueService {
  PrintQueueService._();
  static final PrintQueueService instance = PrintQueueService._();

  final Map<String, bool> _inProgress = {};
  Timer? _timer;
  bool _running = false;

  final List<int> _retryDelays = [5, 15, 30, 60]; // seconds
  final Random _rand = Random();

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _processPending());
    debugPrint('PrintQueueService started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    debugPrint('PrintQueueService stopped');
  }

  Future<int> enqueueAndStart({
    required String ticketType,
    required String printerHost,
    required int printerPort,
    required List<int> payload,
    String? orderRef,
  }) async {
    final job = PrintJob(
      ticketType: ticketType,
      printerHost: printerHost,
      printerPort: printerPort,
      payloadBase64: base64Encode(payload),
      orderRef: orderRef,
    );

    final id = await DatabaseService.db.writeTxn<int>(() async {
      return await DatabaseService.db.printJobs.put(job);
    });

    // ensure worker is running
    start();
    return id;
  }

  Future<void> _processPending() async {
    try {
      final now = DateTime.now();
      final pending = await DatabaseService.db.printJobs.filter().statusEqualTo('pending').findAll();
      for (final job in pending) {
        final next = job.nextAttemptAt;
        if (next != null && next.isAfter(now)) continue;

        final key = '${job.printerHost}:${job.printerPort}';
        if (_inProgress[key] == true) continue;
        _inProgress[key] = true;
        _processJob(job).whenComplete(() => _inProgress.remove(key));
      }
    } catch (e, st) {
      debugPrint('PrintQueueService _processPending error: $e\n$st');
    }
  }

  Future<void> _processJob(PrintJob job) async {
    try {
      await DatabaseService.db.writeTxn(() async {
        job.status = 'printing';
        await DatabaseService.db.printJobs.put(job);
      });

      debugPrint('Printing job ${job.id} to ${job.printerHost}:${job.printerPort}');

      final socket = await Socket.connect(
        job.printerHost,
        job.printerPort,
        timeout: const Duration(seconds: 6),
      );
      try {
        socket.add(job.payloadBytes);
        await socket.flush();
        debugPrint('PrintQueueService: job ${job.id} sent successfully');
        await DatabaseService.db.writeTxn(() async {
          job.status = 'printed';
          job.printedAt = DateTime.now();
          job.errorMessage = null;
          await DatabaseService.db.printJobs.put(job);
        });
      } finally {
        try {
          await socket.close();
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('PrintQueueService: job ${job.id} failed: $e\n$st');
      await DatabaseService.db.writeTxn(() async {
        job.retryCount = job.retryCount + 1;
        final idx = job.retryCount - 1;
        if (idx < _retryDelays.length) {
          final base = _retryDelays[idx];
          final jitter = _rand.nextInt(1000); // ms
          job.nextAttemptAt = DateTime.now().add(Duration(seconds: base, milliseconds: jitter));
          job.status = 'pending';
          job.errorMessage = e.toString();
        } else {
          job.status = 'failed';
          job.errorMessage = e.toString();
        }
        await DatabaseService.db.printJobs.put(job);
      });
    }
  }
}
