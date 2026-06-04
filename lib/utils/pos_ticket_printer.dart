import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/app_settings_service.dart';
import 'order_item_grouping.dart';
import 'payment_method_utils.dart';

List<pw.Widget> _buildTicketItemWidgets(
  List<PosOrderItem> items, {
  required bool includePrices,
  String Function(double)? money,
}) {
  final widgets = <pw.Widget>[];
  final byGroup = groupOrderItemsByGuest(items);
  final showGroupHeader =
      byGroup.length > 1 || byGroup.keys.firstOrNull != 'Sans ensemble';

  byGroup.forEach((groupLabel, groupItems) {
    if (showGroupHeader) {
      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: pw.EdgeInsets.only(bottom: 6),
          padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.red300, width: 0.7),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            groupLabel,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ),
      );
    }

    final byCourse = groupOrderItemsByCourse(groupItems);
    byCourse.forEach((course, courseItems) {
      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            '=== ${course.label} ===',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );

      for (final it in courseItems) {
        final note = it.itemNote?.trim();
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (includePrices)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${it.quantity} x ${cleanOrderItemProductName(it.productName)}',
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(money!(it.unitPrice * it.quantity)),
                    ],
                  )
                else
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 32,
                        child: pw.Text(
                          '${it.quantity}x',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          cleanOrderItemProductName(it.productName),
                        ),
                      ),
                    ],
                  ),
                if (note != null && note.isNotEmpty)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      'Note: $note',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    });
  });

  return widgets;
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
              : double.tryParse(rawAmount.toString().replaceAll(',', '.')) ??
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

String _paymentStatusLabel(PosOrder order) {
  final status = order.paymentStatus.trim().toLowerCase();
  switch (status) {
    case 'paid':
      return 'Payé';
    case 'partially_paid':
      return 'Partiellement payé';
    case 'pending':
    default:
      return status.isEmpty ? 'Non renseigné' : status;
  }
}

List<pw.Widget> _buildPaymentSummaryWidgets(
  PosOrder order, {
  required String Function(double) money,
}) {
  final entries = _extractPaymentEntries(order);
  final paidAmount = _calculatePaymentTotal(entries);
  final remainingAmount = (order.totalPrice - paidAmount).clamp(
    0.0,
    order.totalPrice,
  );
  final hasPaymentHistory =
      entries.isNotEmpty ||
      order.paymentStatus.trim().toLowerCase() != 'pending';
  if (!hasPaymentHistory) {
    return const [];
  }

  final isPartial =
      order.paymentStatus.trim().toLowerCase() == 'partially_paid' ||
      remainingAmount > 0.01;

  final widgets = <pw.Widget>[];
  widgets.add(
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isPartial ? 'REÇU PAIEMENT PARTIEL' : 'PAIEMENT',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'État: ${_paymentStatusLabel(order)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Méthode: ${entries.isNotEmpty ? entries.map((entry) => paymentMethodLabel((entry['payment_method'] ?? '').toString())).join(' / ') : paymentMethodLabel(order.paymentMethod)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (entries.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Détails des paiements:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            ...entries.map((entry) {
              final method = paymentMethodLabel(
                (entry['payment_method'] ?? '').toString(),
              );
              final rawAmount = entry['amount'];
              final amount = rawAmount is num
                  ? rawAmount.toDouble()
                  : double.tryParse(
                          rawAmount.toString().replaceAll(',', '.'),
                        ) ??
                        0.0;
              final timestamp = _formatTicketTimestamp(
                entry['timestamp'] as String?,
              );
              final detail = StringBuffer()
                ..write('- $method: ${money(amount)} Dhs');
              if (timestamp.isNotEmpty) {
                detail.write(' ($timestamp)');
              }
              return pw.Text(
                detail.toString(),
                style: const pw.TextStyle(fontSize: 8.5),
              );
            }),
          ],
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Réglé:', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                money(paidAmount),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          if (remainingAmount > 0.01)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Reste à payer:',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  money(remainingAmount),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  return widgets;
}

Future<Uint8List> buildTicketPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
}) async {
  return buildCustomerBillPdf(order, items, format: format);
}

Future<Uint8List> buildKitchenTicketPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final doc = pw.Document();
  final pageFormat = format ?? PdfPageFormat.roll80.copyWith(
    marginTop: 6,
    marginBottom: 6,
    marginLeft: 6,
    marginRight: 6,
  );
  final logoImage = await _loadLogoImage();
  final orderTime = _formatOrderTime(order.createdAt);

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête restaurant
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null || restaurantName != null)
              pw.SizedBox(height: 6),
            if (restaurantName != null)
              pw.Center(
                child: pw.Text(
                  restaurantName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            if (restaurantPhone != null)
              pw.Center(
                child: pw.Text(
                  'Tél: $restaurantPhone',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            if (restaurantName != null || restaurantPhone != null)
              pw.SizedBox(height: 6),
            // Titre ticket
            pw.Center(
              child: pw.Text(
                'BON CUISINE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            // Informations commande
            pw.Text(
              'Commande: #${order.id}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date/Heure: $orderTime',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Type: ${_fulfillmentLabel(order.fulfillmentType)}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
              pw.Text(
                'Table: ${order.tableNumber}',
                style: pw.TextStyle(fontSize: 10),
              ),
            if (staffName != null)
              pw.Text('Serveur: $staffName', style: pw.TextStyle(fontSize: 10)),
            if (order.note != null && order.note!.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  'Note: ${order.note!.trim()}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Divider(color: PdfColors.grey500),
            // Détails produits
            ..._buildTicketItemWidgets(items, includePrices: false),
            pw.Divider(color: PdfColors.grey500),
            pw.Center(
              child: pw.Text(
                'Total articles: ${items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<Uint8List> buildCustomerBillPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final doc = pw.Document();
  final pageFormat = format ?? PdfPageFormat.roll80.copyWith(
    marginTop: 6,
    marginBottom: 6,
    marginLeft: 6,
    marginRight: 6,
  );
  final logoImage = await _loadLogoImage();
  final money = AppSettingsService.instance.formatAmount;
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
      paymentStatus == 'paid' || (hasPaymentEntries && remainingAmount <= 0.01);
  final paymentTitle = isPartialPayment
      ? 'REÇU PAIEMENT PARTIEL'
      : isPaidPayment
      ? 'REÇU PAIEMENT'
      : 'ADDITION CLIENT';
  final paymentSummaryWidgets = _buildPaymentSummaryWidgets(
    order,
    money: money,
  );

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête restaurant
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null || restaurantName != null)
              pw.SizedBox(height: 6),
            if (restaurantName != null)
              pw.Center(
                child: pw.Text(
                  restaurantName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            if (restaurantPhone != null)
              pw.Center(
                child: pw.Text(
                  'Tél: $restaurantPhone',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            if (restaurantName != null || restaurantPhone != null)
              pw.SizedBox(height: 6),
            // Titre ticket
            pw.Center(
              child: pw.Text(
                paymentTitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            // Informations commande
            pw.Text(
              'Commande: #${order.id}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date/Heure: $orderTime',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Type: ${_fulfillmentLabel(order.fulfillmentType)}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
              pw.Text(
                'Table: ${order.tableNumber}',
                style: pw.TextStyle(fontSize: 10),
              ),
            if (staffName != null)
              pw.Text('Serveur: $staffName', style: pw.TextStyle(fontSize: 10)),
            pw.Text(
              'Canal: ${order.channel}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              pw.Text(
                'Tel client: ${order.customerPhone}',
                style: pw.TextStyle(fontSize: 9),
              ),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty)
              pw.Text(
                'Adresse: ${order.deliveryAddress}',
                style: pw.TextStyle(fontSize: 9),
              ),
            pw.Divider(color: PdfColors.grey500),
            // Détails produits
            ..._buildTicketItemWidgets(
              items,
              includePrices: true,
              money: money,
            ),
            pw.Divider(color: PdfColors.grey500),
            // Totaux
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sous-total:', style: pw.TextStyle(fontSize: 10)),
                pw.Text(money(subtotal), style: pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Remise:',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
                  ),
                  pw.Text(
                    '-${money(discount)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  money(total),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.green,
                  ),
                ),
              ],
            ),
            if (paymentSummaryWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...paymentSummaryWidgets,
            ],
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            // Message de remerciement
            pw.Center(
              child: pw.Text(
                'Merci pour votre visite',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text('À bientôt!', style: pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 4),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<Uint8List> buildKitchenAndCustomerTicketsPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final pageFormat = format ?? PdfPageFormat.roll80.copyWith(
    marginTop: 6,
    marginBottom: 6,
    marginLeft: 6,
    marginRight: 6,
  );
  final doc = pw.Document();
  final logoImage = await _loadLogoImage();
  final money = AppSettingsService.instance.formatAmount;
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
      paymentStatus == 'paid' || (hasPaymentEntries && remainingAmount <= 0.01);
  final paymentTitle = isPartialPayment
      ? 'REÇU PAIEMENT PARTIEL'
      : isPaidPayment
      ? 'REÇU PAIEMENT'
      : 'ADDITION CLIENT';
  final paymentSummaryWidgets = _buildPaymentSummaryWidgets(
    order,
    money: money,
  );

  // Fonction helper pour le header restaurant
  List<pw.Widget> buildRestaurantHeaderWidgets() {
    final widgets = <pw.Widget>[];
    if (logoImage != null) {
      widgets.add(
        pw.Center(
          child: pw.SizedBox(
            height: 56,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    if (logoImage != null || restaurantName != null) {
      widgets.add(pw.SizedBox(height: 6));
    }
    if (restaurantName != null) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            restaurantName,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }
    if (restaurantPhone != null) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            'Tél: $restaurantPhone',
            style: pw.TextStyle(fontSize: 9),
          ),
        ),
      );
    }
    if (restaurantName != null || restaurantPhone != null) {
      widgets.add(pw.SizedBox(height: 6));
    }
    return widgets;
  }

  // Page 1: kitchen ticket
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ...buildRestaurantHeaderWidgets(),
            pw.Center(
              child: pw.Text(
                'BON CUISINE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            pw.Text(
              'Commande: #${order.id}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date/Heure: $orderTime',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Type: ${_fulfillmentLabel(order.fulfillmentType)}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
              pw.Text(
                'Table: ${order.tableNumber}',
                style: pw.TextStyle(fontSize: 10),
              ),
            if (staffName != null)
              pw.Text('Serveur: $staffName', style: pw.TextStyle(fontSize: 10)),
            if (order.note != null && order.note!.trim().isNotEmpty)
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  'Note: ${order.note!.trim()}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Divider(color: PdfColors.grey500),
            ..._buildTicketItemWidgets(items, includePrices: false),
            pw.Divider(color: PdfColors.grey500),
            pw.Center(
              child: pw.Text(
                'Total articles: ${items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // Page 2: customer bill
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ...buildRestaurantHeaderWidgets(),
            pw.Center(
              child: pw.Text(
                paymentTitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            pw.Text(
              'Commande: #${order.id}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date/Heure: $orderTime',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Type: ${_fulfillmentLabel(order.fulfillmentType)}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
              pw.Text(
                'Table: ${order.tableNumber}',
                style: pw.TextStyle(fontSize: 10),
              ),
            if (staffName != null)
              pw.Text('Serveur: $staffName', style: pw.TextStyle(fontSize: 10)),
            pw.Text(
              'Canal: ${order.channel}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              pw.Text(
                'Tel client: ${order.customerPhone}',
                style: pw.TextStyle(fontSize: 9),
              ),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty)
              pw.Text(
                'Adresse: ${order.deliveryAddress}',
                style: pw.TextStyle(fontSize: 9),
              ),
            pw.Divider(color: PdfColors.grey500),
            ..._buildTicketItemWidgets(
              items,
              includePrices: true,
              money: money,
            ),
            pw.Divider(color: PdfColors.grey500),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sous-total:', style: pw.TextStyle(fontSize: 10)),
                pw.Text(money(subtotal), style: pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Remise:',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
                  ),
                  pw.Text(
                    '-${money(discount)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  money(total),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.green,
                  ),
                ),
              ],
            ),
            if (paymentSummaryWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...paymentSummaryWidgets,
            ],
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey500),
            pw.Center(
              child: pw.Text(
                'Merci pour votre visite',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text('À bientôt!', style: pw.TextStyle(fontSize: 10)),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<pw.MemoryImage?> _loadLogoImage() async {
  await AppSettingsService.instance.init();
  final settings = AppSettingsService.instance.settings;
  final logoPath = settings.ticketLogoPath;
  if (logoPath == null || logoPath.trim().isEmpty) {
    return null;
  }
  try {
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      final response = await http.get(Uri.parse(logoPath));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
      return null;
    }

    final file = File(logoPath);
    if (await file.exists()) {
      return pw.MemoryImage(await file.readAsBytes());
    }
  } catch (_) {}
  return null;
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

String _formatOrderTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

/// Génère un PDF pour un rapport journalier
Future<Uint8List> buildDailyReportPdf(Map<String, dynamic> reportData) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final doc = pw.Document();
  final pageFormat = PdfPageFormat.roll80.copyWith(
    marginTop: 6,
    marginBottom: 6,
    marginLeft: 6,
    marginRight: 6,
  );

  // Extraire les données du rapport
  final dateStr = reportData['date'] as String? ?? 'Date inconnue';
  final summary = reportData['summary'] as Map<String, dynamic>? ?? {};
  final totalRevenue = (summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
  final totalOrders = summary['total_orders'] as int? ?? 0;

  // Modes de paiement
  final paymentMethods =
      summary['payment_methods'] as Map<String, dynamic>? ?? {};
  final cashAmount = (paymentMethods['cash'] as num?)?.toDouble() ?? 0.0;
  final tpeAmount = (paymentMethods['tpe'] as num?)?.toDouble() ?? 0.0;
  final enCompteAmount =
      (paymentMethods['en_compte'] as num?)?.toDouble() ?? 0.0;
  final otherAmount = (paymentMethods['other'] as num?)?.toDouble() ?? 0.0;

  // Types de commande
  final orderTypes = summary['order_types'] as Map<String, dynamic>? ?? {};
  final onsiteCount = orderTypes['onsite'] as int? ?? 0;
  final pickupCount = orderTypes['pickup'] as int? ?? 0;
  final deliveryCount = orderTypes['delivery'] as int? ?? 0;

  // Statistiques par serveur et livreur
  final staffBreakdown = summary['staff_breakdown'] as List<dynamic>? ?? [];
  final deliveryBreakdown = summary['delivery_breakdown'] as List<dynamic>? ?? [];

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500, width: 0.9),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'RAPPORT JOURNALIER',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date : $dateStr',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Résumé principal
            _buildReportRow(
              'Chiffre d\'affaires total:',
              '${totalRevenue.toStringAsFixed(2)} Dhs',
            ),
            _buildReportRow('Nombre total de commandes:', '$totalOrders'),
            pw.SizedBox(height: 8),

            // Modes de paiement
            pw.Text(
              'Modes de paiement:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (cashAmount > 0)
              _buildReportRow(
                '   Cash:',
                '${cashAmount.toStringAsFixed(2)} Dhs',
              ),
            if (tpeAmount > 0)
              _buildReportRow('   TPE:', '${tpeAmount.toStringAsFixed(2)} Dhs'),
            if (enCompteAmount > 0)
              _buildReportRow(
                '   En compte:',
                '${enCompteAmount.toStringAsFixed(2)} Dhs',
              ),
            if (otherAmount > 0)
              _buildReportRow(
                '   Autre:',
                '${otherAmount.toStringAsFixed(2)} Dhs',
              ),
            pw.SizedBox(height: 8),

            // Types de commande
            pw.Text(
              'Types de commande:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (onsiteCount > 0)
              _buildReportRow('   Sur place:', '$onsiteCount'),
            if (pickupCount > 0)
              _buildReportRow('   À emporter:', '$pickupCount'),
            if (deliveryCount > 0)
              _buildReportRow('   Livraison:', '$deliveryCount'),
            pw.SizedBox(height: 8),

            // Statistiques par serveur
            if (staffBreakdown.isNotEmpty) ...[
              pw.Text(
                'Statistiques par serveur:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...staffBreakdown.map((staff) {
                final staffMap = staff as Map<String, dynamic>;
                final staffId = staffMap['staff_id'] as int? ?? 0;
                final staffNameRaw = (staffMap['staff_name'] as String?)?.trim();
                final staffName = staffNameRaw != null && staffNameRaw.isNotEmpty
                    ? staffNameRaw
                    : 'Serveur #$staffId';
                final ordersCount = staffMap['orders_count'] as int? ?? 0;
                final totalRevenueStaff =
                    (staffMap['total_revenue'] as num?)?.toDouble() ?? 0.0;
                final paymentMethodsStaff =
                    staffMap['payment_methods'] as Map<String, dynamic>? ?? {};

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '   Serveur: $staffName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    _buildReportRow('      Commandes:', '$ordersCount'),
                    _buildReportRow(
                      '      Chiffre d\'affaires:',
                      '${totalRevenueStaff.toStringAsFixed(2)} Dhs',
                    ),
                    if (((paymentMethodsStaff['cash'] as num?)?.toDouble() ??
                            0) >
                        0)
                      _buildReportRow(
                        '      Cash:',
                        '${(paymentMethodsStaff['cash'] as num?)?.toDouble().toStringAsFixed(2)} Dhs',
                      ),
                    if (((paymentMethodsStaff['tpe'] as num?)?.toDouble() ??
                            0) >
                        0)
                      _buildReportRow(
                        '      TPE:',
                        '${(paymentMethodsStaff['tpe'] as num?)?.toDouble().toStringAsFixed(2)} Dhs',
                      ),
                    if (((paymentMethodsStaff['en_compte'] as num?)
                                ?.toDouble() ??
                            0) >
                        0)
                      _buildReportRow(
                        '      En compte:',
                        '${(paymentMethodsStaff['en_compte'] as num?)?.toDouble().toStringAsFixed(2)} Dhs',
                      ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
            ],
            if (deliveryBreakdown.isNotEmpty) ...[
              pw.Text(
                'Statistiques par livreur:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...deliveryBreakdown.map((delivery) {
                final deliveryMap = delivery as Map<String, dynamic>;
                final deliveryStaffId = deliveryMap['delivery_staff_id'] as int? ?? 0;
                final deliveryStaffNameRaw = (deliveryMap['delivery_staff_name'] as String?)?.trim();
                final deliveryStaffName = deliveryStaffNameRaw != null && deliveryStaffNameRaw.isNotEmpty
                    ? deliveryStaffNameRaw
                    : 'Livreur #$deliveryStaffId';
                final deliveryCount = deliveryMap['delivery_count'] as int? ?? 0;
                final deliveryRevenue =
                    (deliveryMap['delivery_revenue'] as num?)?.toDouble() ?? 0.0;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '   Livreur: $deliveryStaffName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    _buildReportRow('      Livraisons:', '$deliveryCount'),
                    _buildReportRow(
                      '      Chiffre d\'affaires:',
                      '${deliveryRevenue.toStringAsFixed(2)} Dhs',
                    ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
            ],

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Fin du rapport',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _buildReportRow(String label, String value) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 11)),
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}
