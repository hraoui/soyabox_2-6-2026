import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart'
    as unified_printer;
import '../models/app_settings.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/app_settings_service.dart';
import '../utils/order_item_grouping.dart';
import '../utils/payment_method_utils.dart';

class EscPosPrinterService {
  EscPosPrinterService._();

  static final EscPosPrinterService instance = EscPosPrinterService._();

  Future<CapabilityProfile> loadProfile() {
    return CapabilityProfile.load();
  }

  Future<bool> hasConfiguredPrinter({bool kitchen = false}) async {
    await AppSettingsService.instance.init();
    final settings = AppSettingsService.instance.settings;
    return kitchen
        ? settings.hasConfiguredKitchenReceiptPrinter
        : settings.hasConfiguredCustomerReceiptPrinter;
  }

  Future<bool> tryPrintDailyReport(
    Map<String, dynamic> reportData, {
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    if (!await hasConfiguredPrinter()) {
      return false;
    }
    try {
      final bytes = await buildDailyReportEscPos(
        reportData,
        paperSize: paperSize,
      );
      await _sendBytes(bytes, useKitchenPrinter: false);
      return true;
    } catch (e, st) {
      debugPrint('ESC/POS daily report failed: $e\n$st');
      return false;
    }
  }

  Future<bool> tryPrintKitchenTicket(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    if (!await hasConfiguredPrinter(kitchen: true)) {
      return false;
    }
    try {
      final bytes = await buildKitchenTicketEscPos(
        order,
        items,
        paperSize: paperSize,
        staffName: staffName,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      );
      await _sendBytes(bytes, useKitchenPrinter: true);
      return true;
    } catch (e, st) {
      debugPrint('ESC/POS kitchen ticket failed: $e\n$st');
      return false;
    }
  }

  Future<bool> tryPrintCustomerTicket(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    if (!await hasConfiguredPrinter(kitchen: false)) {
      return false;
    }
    try {
      final bytes = await buildCustomerTicketEscPos(
        order,
        items,
        paperSize: paperSize,
        staffName: staffName,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      );
      await _sendBytes(bytes, useKitchenPrinter: false);
      return true;
    } catch (e, st) {
      debugPrint('ESC/POS customer ticket failed: $e\n$st');
      return false;
    }
  }

  Future<bool> tryPrintKitchenAndCustomerTickets(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    await AppSettingsService.instance.init();
    final settings = AppSettingsService.instance.settings;
    final hasKitchen = settings.hasConfiguredKitchenReceiptPrinter;
    final hasCustomer = settings.hasConfiguredCustomerReceiptPrinter;
    if (!hasKitchen && !hasCustomer) {
      return false;
    }
    try {
      if (hasKitchen && hasCustomer) {
        final kitchen = await buildKitchenTicketEscPos(
          order,
          items,
          paperSize: paperSize,
          staffName: staffName,
          restaurantName: restaurantName,
          restaurantPhone: restaurantPhone,
        );
        final customer = await buildCustomerTicketEscPos(
          order,
          items,
          paperSize: paperSize,
          staffName: staffName,
          restaurantName: restaurantName,
          restaurantPhone: restaurantPhone,
        );
        await _sendBytes(kitchen, useKitchenPrinter: true);
        await _sendBytes(customer, useKitchenPrinter: false);
        return true;
      }
      final bytes = await buildKitchenAndCustomerTicketsEscPos(
        order,
        items,
        paperSize: paperSize,
        staffName: staffName,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      );
      await _sendBytes(bytes, useKitchenPrinter: hasKitchen);
      return true;
    } catch (e, st) {
      debugPrint('ESC/POS kitchen+customer tickets failed: $e\n$st');
      return false;
    }
  }

  Future<List<int>> buildDailyReportEscPos(
    Map<String, dynamic> reportData, {
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    final profile = await loadProfile();
    final generator = Generator(paperSize, profile);
    final summary = reportData['summary'] as Map<String, dynamic>? ?? {};
    final totalRevenue = (summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = summary['total_orders']?.toString() ?? '0';
    final paymentMethods =
        summary['payment_methods'] as Map<String, dynamic>? ?? {};
    final orderTypes = summary['order_types'] as Map<String, dynamic>? ?? {};
    final cashAmount = (paymentMethods['cash'] as num?)?.toDouble() ?? 0.0;
    final tpeAmount = (paymentMethods['tpe'] as num?)?.toDouble() ?? 0.0;
    final enCompteAmount =
        (paymentMethods['en_compte'] as num?)?.toDouble() ?? 0.0;
    final otherAmount = (paymentMethods['other'] as num?)?.toDouble() ?? 0.0;
    final onsiteCount = orderTypes['onsite']?.toString() ?? '0';
    final pickupCount = orderTypes['pickup']?.toString() ?? '0';
    final deliveryCount = orderTypes['delivery']?.toString() ?? '0';

    final dateStr = reportData['date']?.toString() ?? '';
    final staffName = reportData['staff_name']?.toString() ?? '';
    final staffBreakdown = summary['staff_breakdown'] as List<dynamic>? ?? [];
    final deliveryBreakdown =
        summary['delivery_breakdown'] as List<dynamic>? ?? [];

    List<int> bytes = [];
    bytes += generator.text(
      'RAPPORT JOURNALIER',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        underline: true,
      ),
      linesAfter: 1,
    );
    bytes += _divider(generator);
    if (dateStr.isNotEmpty) {
      bytes += generator.text(
        _escPosText('Date : $dateStr'),
        styles: const PosStyles(align: PosAlign.center),
      );
      if (staffName.trim().isNotEmpty) {
        bytes += generator.text(
          _escPosText('Serveur : $staffName'),
          styles: const PosStyles(align: PosAlign.center),
          linesAfter: 1,
        );
      } else {
        bytes += generator.feed(1);
      }
    }

    bytes += _divider(generator);
    bytes += generator.text(
      'Resume',
      styles: const PosStyles(align: PosAlign.left, bold: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      _escPosText('Chiffre d\'affaires : ${_money(totalRevenue)}'),
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      _escPosText('Commandes : $totalOrders'),
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 1,
    );

    if (cashAmount > 0) {
      bytes += generator.text(
        _escPosText('Cash : ${_money(cashAmount)}'),
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    if (tpeAmount > 0) {
      bytes += generator.text(
        _escPosText('TPE : ${_money(tpeAmount)}'),
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    if (enCompteAmount > 0) {
      bytes += generator.text(
        _escPosText('En compte : ${_money(enCompteAmount)}'),
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    if (otherAmount > 0) {
      bytes += generator.text(
        _escPosText('Autre : ${_money(otherAmount)}'),
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 1,
      );
    }

    bytes += _divider(generator);
    bytes += generator.text(
      'Types de commande',
      styles: const PosStyles(align: PosAlign.left, bold: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      _escPosText('Sur place : $onsiteCount'),
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      _escPosText('A emporter : $pickupCount'),
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      _escPosText('Livraison : $deliveryCount'),
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 1,
    );

    if (staffBreakdown.isNotEmpty) {
      bytes += _divider(generator);
      bytes += _divider(generator);
      bytes += generator.text(
        'Par serveur',
        styles: const PosStyles(bold: true),
        linesAfter: 1,
      );
      for (final staffRow in staffBreakdown.cast<Map<String, dynamic>>()) {
        final staffId = staffRow['staff_id']?.toString() ?? 'N/A';
        final rawStaffName = staffRow['staff_name']?.toString().trim();
        final staffNameLine = rawStaffName != null && rawStaffName.isNotEmpty
            ? rawStaffName
            : 'Serveur $staffId';
        final ordersCount = staffRow['orders_count']?.toString() ?? '0';
        final staffRevenue =
            (staffRow['total_revenue'] as num?)?.toDouble() ?? 0.0;
        bytes += generator.text(
          _escPosText('Serveur $staffNameLine'),
          styles: const PosStyles(bold: true),
        );
        bytes += generator.text(_escPosText('  Commandes : $ordersCount'));
        bytes += generator.text(
          _escPosText('  CA : ${_money(staffRevenue)}'),
          linesAfter: 1,
        );
      }
    }

    if (deliveryBreakdown.isNotEmpty) {
      bytes += _divider(generator);
      bytes += generator.text(
        'Par livreur',
        styles: const PosStyles(bold: true),
        linesAfter: 1,
      );
      for (final deliveryRow
          in deliveryBreakdown.cast<Map<String, dynamic>>()) {
        final deliveryStaffId =
            deliveryRow['delivery_staff_id']?.toString() ?? 'N/A';
        final rawDeliveryStaffName =
            deliveryRow['delivery_staff_name']?.toString().trim();
        final deliveryStaffName =
            rawDeliveryStaffName != null && rawDeliveryStaffName.isNotEmpty
            ? rawDeliveryStaffName
            : 'Livreur $deliveryStaffId';
        final deliveryCount =
            deliveryRow['delivery_count']?.toString() ?? '0';
        final deliveryRevenue =
            (deliveryRow['delivery_revenue'] as num?)?.toDouble() ?? 0.0;

        bytes += generator.text(
          _escPosText('Livreur $deliveryStaffName'),
          styles: const PosStyles(bold: true),
        );
        bytes += generator.text(_escPosText('  Livraisons : $deliveryCount'));
        bytes += generator.text(
          _escPosText('  CA : ${_money(deliveryRevenue)}'),
          linesAfter: 1,
        );
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> buildKitchenTicketEscPos(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final profile = await loadProfile();
    final generator = Generator(paperSize, profile);
    var bytes = <int>[];
    final orderTime = _formatOrderTime(order.createdAt);

    bytes += _buildRestaurantHeader(
      generator,
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
    );
    bytes += generator.text(
      'BON CUISINE',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    bytes += _divider(generator);
    bytes += generator.text(
      _escPosText('Commande: #${order.id}'),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(_escPosText('Date/Heure: $orderTime'));
    bytes += generator.text(
      _escPosText('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
    );
    if (order.tableNumber != null && order.tableNumber!.isNotEmpty) {
      bytes += generator.text(_escPosText('Table: ${order.tableNumber}'));
    }
    if (staffName != null && staffName.trim().isNotEmpty) {
      bytes += generator.text(_escPosText('Serveur: $staffName'));
    }
    if (order.note != null && order.note!.trim().isNotEmpty) {
      bytes += generator.text(
        _escPosText('Note: ${order.note!.trim()}'),
        styles: const PosStyles(bold: true),
      );
    }
    bytes += _divider(generator);
    bytes += _buildItemsBytes(generator, items, includePrices: false);
    bytes += _divider(generator);
    bytes += generator.text(
      _escPosText(
        'Total articles: ${items.fold<int>(0, (sum, item) => sum + item.quantity)}',
      ),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> buildCustomerTicketEscPos(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final profile = await loadProfile();
    final generator = Generator(paperSize, profile);
    var bytes = <int>[];
    final orderTime = _formatOrderTime(order.createdAt);
    final subtotal = order.originalTotal > 0
        ? order.originalTotal
        : order.totalPrice;
    final discount = order.discountAmount;
    final total = order.totalPrice;
    final paymentEntries = _extractPaymentEntries(order);
    final paidAmount = _calculatePaymentTotal(paymentEntries);
    final remainingAmount = (total - paidAmount).clamp(0.0, total);
    final paymentStatus = order.paymentStatus.trim().toLowerCase();
    final hasPaymentEntries = paymentEntries.isNotEmpty;
    final isPartialPayment =
        paymentStatus == 'partially_paid' ||
        (hasPaymentEntries && remainingAmount > 0.01);
    final isPaidPayment =
        paymentStatus == 'paid' ||
        (hasPaymentEntries && remainingAmount <= 0.01);
    final paymentTitle = isPartialPayment
        ? 'RECU PAIEMENT PARTIEL'
        : isPaidPayment
        ? 'RECU PAIEMENT'
        : 'ADDITION CLIENT';
    final paymentMethodsLabel = paymentEntries.isNotEmpty
        ? paymentEntries
              .map(
                (entry) => paymentMethodLabel(
                  (entry['payment_method'] ?? '').toString(),
                ),
              )
              .join(' / ')
        : paymentMethodLabel(order.paymentMethod);

    bytes += _buildRestaurantHeader(
      generator,
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
    );
    bytes += generator.text(
      paymentTitle,
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    bytes += _divider(generator);
    bytes += generator.text(
      _escPosText('Commande: #${order.id}'),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(_escPosText('Date/Heure: $orderTime'));
    bytes += generator.text(
      _escPosText('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
    );
    if (order.tableNumber != null && order.tableNumber!.isNotEmpty) {
      bytes += generator.text(_escPosText('Table: ${order.tableNumber}'));
    }
    if (staffName != null && staffName.trim().isNotEmpty) {
      bytes += generator.text(_escPosText('Serveur: $staffName'));
    }
    bytes += generator.text(_escPosText('Canal: ${order.channel}'));
    if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
      bytes += generator.text(
        _escPosText('Tel client: ${order.customerPhone}'),
      );
    }
    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) {
      bytes += generator.text(_escPosText('Adresse: ${order.deliveryAddress}'));
    }
    bytes += _divider(generator);
    bytes += _buildItemsBytes(generator, items, includePrices: true);
    bytes += _divider(generator);
    bytes += generator.row([
      PosColumn(
        text: 'Sous-total:',
        width: 8,
        styles: const PosStyles(bold: false),
      ),
      PosColumn(
        text: _money(subtotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Remise:', width: 8, styles: PosStyles(bold: false)),
        PosColumn(
          text: '-${_money(discount)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _money(total),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    if (paymentEntries.isNotEmpty || paymentStatus != 'pending') {
      bytes += generator.text(
        'PAIEMENT',
        styles: const PosStyles(bold: true),
        linesAfter: 1,
      );
      bytes += generator.text(
        _escPosText('Etat: ${_paymentStatusLabel(order)}'),
      );
      bytes += generator.text(_escPosText('Methode: $paymentMethodsLabel'));
      if (paymentEntries.isNotEmpty) {
        bytes += generator.text(
          'Details des paiements:',
          styles: const PosStyles(bold: true),
        );
        for (final entry in paymentEntries) {
          final method = paymentMethodLabel(
            (entry['payment_method'] ?? '').toString(),
          );
          final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
          final timestamp = _formatTicketTimestamp(
            entry['timestamp'] as String?,
          );
          final detail = timestamp.isNotEmpty
              ? '$method: ${_money(amount)} ($timestamp)'
              : '$method: ${_money(amount)}';
          bytes += generator.text(_escPosText('  $detail'));
        }
      }
      if (remainingAmount > 0.01) {
        bytes += generator.text(
          _escPosText('Reste a payer: ${_money(remainingAmount)}'),
          styles: const PosStyles(bold: true),
          linesAfter: 1,
        );
      } else {
        bytes += generator.feed(1);
      }
    }
    bytes += generator.feed(1);
    bytes += generator.text(
      'Merci pour votre visite',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'A bientot!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> buildKitchenAndCustomerTicketsEscPos(
    PosOrder order,
    List<PosOrderItem> items, {
    PaperSize paperSize = PaperSize.mm80,
    String? staffName,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final kitchen = await buildKitchenTicketEscPos(
      order,
      items,
      paperSize: paperSize,
      staffName: staffName,
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
    );
    final customer = await buildCustomerTicketEscPos(
      order,
      items,
      paperSize: paperSize,
      staffName: staffName,
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
    );
    return [...kitchen, ...customer];
  }

  Future<void> _sendBytes(
    List<int> bytes, {
    bool useKitchenPrinter = false,
  }) async {
    await AppSettingsService.instance.init();
    final settings = AppSettingsService.instance.settings;
    if (!settings.useEscPosPrinting) {
      throw StateError('Impression ESC/POS desactivee');
    }

    final type = useKitchenPrinter
        ? ReceiptPrinterType.kitchen
        : ReceiptPrinterType.customer;
    final configs = settings.printerConfigsFor(type);

    if (configs.isNotEmpty) {
      var successCount = 0;
      final errors = <String>[];

      for (final config in configs) {
        try {
          await _sendBytesToConfig(bytes, config);
          successCount += 1;
        } catch (e, st) {
          final message =
              'ESC/POS failed for printer ${config.displayName} (${config.host}:${config.port}): $e';
          debugPrint('$message\n$st');
          errors.add(message);
        }
      }

      if (successCount > 0) {
        return;
      }

      throw StateError(
        'Aucune imprimante ${type.label.toLowerCase()} n\'a pu imprimer.\n${errors.join('\n')}',
      );
    }

    final host =
        (useKitchenPrinter
                ? settings.kitchenReceiptPrinterHost
                : settings.receiptPrinterHost)
            ?.trim() ??
        '';
    final port = useKitchenPrinter
        ? settings.kitchenReceiptPrinterPort
        : settings.receiptPrinterPort;
    final transport = useKitchenPrinter
        ? settings.kitchenReceiptPrinterTransport
        : settings.receiptPrinterTransport;

    debugPrint(
      'ESC/POS _sendBytes: transport=$transport host=$host port=$port kitchen=$useKitchenPrinter',
    );

    switch (transport) {
      case ReceiptPrinterTransport.network:
        if (host.isEmpty) {
          throw StateError('Aucune imprimante reseau configuree');
        }
        await _sendBytesOverNetwork(bytes, host: host, port: port);
        return;
      case ReceiptPrinterTransport.usb:
        await _sendBytesOverUsb(bytes);
        return;
      case ReceiptPrinterTransport.auto:
        if (host.isNotEmpty) {
          try {
            await _sendBytesOverNetwork(bytes, host: host, port: port);
            return;
          } catch (e, st) {
            debugPrint(
              'ESC/POS network transport failed, trying USB fallback: $e\n$st',
            );
          }
        }
        await _sendBytesOverUsb(bytes);
        return;
    }
  }

  Future<void> _sendBytesToConfig(
    List<int> bytes,
    ReceiptPrinterConfig config,
  ) async {
    final host = config.host.trim();
    switch (config.transport) {
      case ReceiptPrinterTransport.network:
        if (host.isEmpty) {
          throw StateError('Aucune adresse IP pour l\'imprimante ${config.displayName}');
        }
        await _sendBytesOverNetwork(bytes, host: host, port: config.port);
        return;
      case ReceiptPrinterTransport.usb:
        await _sendBytesOverUsb(bytes);
        return;
      case ReceiptPrinterTransport.auto:
        if (host.isNotEmpty) {
          try {
            await _sendBytesOverNetwork(bytes, host: host, port: config.port);
            return;
          } catch (e, st) {
            debugPrint(
              'ESC/POS auto network fallback failed for printer ${config.displayName}: $e\n$st',
            );
          }
        }
        await _sendBytesOverUsb(bytes);
        return;
    }
  }

  Future<void> _sendBytesOverNetwork(
    List<int> bytes, {
    required String host,
    required int port,
  }) async {
    debugPrint('ESC/POS connecting to network printer $host:$port');
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 4),
    );
    try {
      socket.add(bytes);
      await socket.flush();
      debugPrint('ESC/POS network print done');
    } finally {
      await socket.close();
    }
  }

  Future<void> _sendBytesOverUsb(List<int> bytes) async {
    debugPrint('ESC/POS scanning for USB printers...');
    final manager = unified_printer.PrinterManager();
    bool connected = false;
    try {
      final devices = await manager.scanPrinters(
        timeout: const Duration(seconds: 5),
        types: {unified_printer.PrinterConnectionType.usb},
      );
      final usbDevices = devices
          .whereType<unified_printer.UsbPrinterDevice>()
          .toList();

      debugPrint(
        'ESC/POS USB devices found: ${usbDevices.map((d) => '${d.name} [${d.toString()}]').join(', ')}',
      );

      if (usbDevices.isEmpty) {
        throw StateError('Aucune imprimante USB detectee');
      }

      // On prend la premiere imprimante USB disponible.
      // Si vous avez deux imprimantes de meme marque branchees en meme temps,
      // assurez-vous que seule l'imprimante USB est branchee lors de l'impression USB.
      final device = usbDevices.first;
      debugPrint('ESC/POS connecting to USB device: ${device.name}');

      await manager.connect(device);
      connected = true;
      debugPrint('ESC/POS USB connected, sending ${bytes.length} bytes...');

      await manager.printBytes(bytes);
      debugPrint('ESC/POS USB print done');

      await manager.disconnect();
      connected = false;
      debugPrint('ESC/POS USB disconnected');
    } catch (e, st) {
      debugPrint('ESC/POS USB transport failed: $e\n$st');
      if (connected) {
        try {
          await manager.disconnect();
          debugPrint('ESC/POS USB disconnected after error');
        } catch (disconnectError) {
          debugPrint('ESC/POS USB disconnect after error failed: $disconnectError');
        }
      }
      rethrow;
    } finally {
      manager.dispose();
    }
  }

  List<int> _buildItemsBytes(
    Generator generator,
    List<PosOrderItem> items, {
    required bool includePrices,
  }) {
    var bytes = <int>[];
    final byGroup = groupOrderItemsByGuest(items);
    final firstGroupLabel = byGroup.isNotEmpty ? byGroup.keys.first : '';
    final showGroupHeader =
        byGroup.length > 1 || firstGroupLabel != 'Sans ensemble';

    byGroup.forEach((groupLabel, groupItems) {
      if (showGroupHeader) {
        bytes += generator.text(
          _escPosText(groupLabel),
          styles: const PosStyles(align: PosAlign.center, bold: true),
          linesAfter: 1,
        );
      }

      final byCourse = groupOrderItemsByCourse(groupItems);
      byCourse.forEach((course, courseItems) {
        bytes += generator.text(
          _escPosText('=== ${course.label} ==='),
          styles: const PosStyles(bold: true),
          linesAfter: 1,
        );

        for (final item in courseItems) {
          final note = item.itemNote?.trim();
          final productName = _escPosText(
            cleanOrderItemProductName(item.productName),
          );
          if (includePrices) {
            bytes += generator.row([
              PosColumn(text: '${item.quantity} x $productName', width: 9),
              PosColumn(
                text: _money(item.unitPrice * item.quantity),
                width: 3,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]);
          } else {
            bytes += generator.row([
              PosColumn(
                text: '${item.quantity}x',
                width: 2,
                styles: const PosStyles(bold: true),
              ),
              PosColumn(text: productName, width: 10),
            ]);
          }
          if (note != null && note.isNotEmpty) {
            bytes += generator.text(
              _escPosText('  Note: $note'),
              styles: const PosStyles(bold: true),
              linesAfter: 1,
            );
          }
        }
      });
    });

    return bytes;
  }

  List<int> _buildRestaurantHeader(
    Generator generator, {
    String? restaurantName,
    String? restaurantPhone,
  }) {
    var bytes = <int>[];
    if (restaurantName != null && restaurantName.trim().isNotEmpty) {
      bytes += generator.text(
        _escPosText(restaurantName),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (restaurantPhone != null && restaurantPhone.trim().isNotEmpty) {
      bytes += generator.text(
        _escPosText('Tel: $restaurantPhone'),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (bytes.isNotEmpty) {
      bytes += generator.feed(1);
    }
    return bytes;
  }

  List<int> _divider(Generator generator) {
    return generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
  }

  List<Map<String, dynamic>> _extractPaymentEntries(PosOrder order) {
    final entries = <Map<String, dynamic>>[];
    final rawSplit = order.paymentSplit;
    if (rawSplit != null && rawSplit.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSplit);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is! Map) continue;
            final rawAmount = raw['amount'] ?? raw['montant'] ?? 0;
            final amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse(
                        rawAmount.toString().replaceAll(',', '.'),
                      ) ??
                      0.0;
            final method = (raw['payment_method'] ?? raw['method'] ?? '')
                .toString()
                .trim();
            if (amount <= 0 && method.isEmpty) continue;
            entries.add({
              'payment_method': normalizePaymentMethod(method),
              'amount': amount,
              'timestamp': (raw['timestamp'] ?? '').toString(),
            });
          }
        }
      } catch (_) {
        // Ignore malformed payloads and fall back below when possible.
      }
    }

    if (entries.isEmpty &&
        order.paymentStatus.trim().toLowerCase() == 'paid' &&
        normalizePaymentMethod(order.paymentMethod).isNotEmpty) {
      entries.add({
        'payment_method': normalizePaymentMethod(order.paymentMethod),
        'amount': order.totalPrice,
        'timestamp': order.updatedAt.toIso8601String(),
      });
    }

    return entries;
  }

  double _calculatePaymentTotal(List<Map<String, dynamic>> entries) {
    return entries.fold<double>(0.0, (sum, entry) {
      final amount = entry['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      if (amount is String) {
        return sum + (double.tryParse(amount.replaceAll(',', '.')) ?? 0.0);
      }
      return sum;
    });
  }

  String _paymentStatusLabel(PosOrder order) {
    final status = order.paymentStatus.trim().toLowerCase();
    switch (status) {
      case 'paid':
        return 'Paye';
      case 'partially_paid':
        return 'Partiellement paye';
      case 'pending':
      default:
        return status.isEmpty ? 'Non renseigne' : status;
    }
  }

  String _formatTicketTimestamp(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.trim().isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(rawTimestamp);
    if (parsed == null) {
      return rawTimestamp;
    }
    return _formatOrderTime(parsed.toLocal());
  }

  String _formatOrderTime(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _fulfillmentLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'delivery':
        return 'Livraison';
      case 'pickup':
        return 'A emporter';
      case 'on_site':
      default:
        return 'Sur place';
    }
  }

  String _money(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  String _escPosText(String value) {
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Ã': 'A',
      'Å': 'A',
      'Ç': 'C',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'Õ': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ý': 'Y',
      '\u2018': "'",
      '\u2013': '-',
      '\u2014': '-',
      '\u00ab': '"',
      '\u00bb': '"',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}