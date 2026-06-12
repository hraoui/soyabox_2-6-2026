import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/database_service.dart';
import '../services/app_settings_service.dart';
import 'order_item_grouping.dart';
import 'payment_method_utils.dart';

// Cache fonts and logo to speed up repeated PDF generation
pw.Font? _cachedRegularFont;
pw.Font? _cachedBoldFont;
pw.MemoryImage? _cachedLogoImage;
String? _cachedLogoPath;

Future<pw.Font> _getRegularFont() async {
  if (_cachedRegularFont != null) return _cachedRegularFont!;
  _cachedRegularFont = await PdfGoogleFonts.notoSansRegular();
  return _cachedRegularFont!;
}

Future<pw.Font> _getBoldFont() async {
  if (_cachedBoldFont != null) return _cachedBoldFont!;
  _cachedBoldFont = await PdfGoogleFonts.notoSansBold();
  return _cachedBoldFont!;
}

const double _ticketLogoHeight = 44;
const double _ticketLogoWidth = 140;
const double _ticketLogoSpacing = 4;

class _TicketProductLine {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final bool offered;
  final String? note;

  _TicketProductLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.offered = false,
    this.note,
  });
}

class _OfferedTicketSummary {
  final int quantity;
  final double value;

  const _OfferedTicketSummary({required this.quantity, required this.value});
}

List<_TicketProductLine> _resolveTicketProductLines(PosOrderItem item) {
  var offeredQty = 0;
  String? offeredByName;

  if (item.partialPaymentHistory != null &&
      item.partialPaymentHistory!.isNotEmpty) {
    try {
      final decoded = jsonDecode(item.partialPaymentHistory!);
      if (decoded is List) {
        for (final raw in decoded) {
          if (raw is Map) {
            // Check new format: is_offered flag
            final isOffered = raw['is_offered'] == true;
            if (isOffered) {
              final qty = raw['quantity_paid'];
              if (qty is num) {
                offeredQty += qty.toInt();
              }
              // Get the name of who offered it
              final staffName = raw['offered_by_staff_name']?.toString();
              if (staffName != null && offeredByName == null) {
                offeredByName = staffName;
              }
            } else {
              // Fallback to old format: check payment_methods
              final paymentMethods = raw['payment_methods'];
              if (paymentMethods is List) {
                final hasOffer = paymentMethods.any((payment) {
                  if (payment is Map) {
                    final method = payment['method']?.toString();
                    return normalizePaymentMethod(method) ==
                        paymentMethodOffert;
                  }
                  return false;
                });
                if (hasOffer) {
                  final qty = raw['quantity_paid'];
                  if (qty is num) {
                    offeredQty += qty.toInt();
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {
      offeredQty = 0;
    }
  }

  offeredQty = offeredQty.clamp(0, item.quantity);
  final remainingQty = item.quantity - offeredQty;
  final rows = <_TicketProductLine>[];

  if (remainingQty > 0) {
    rows.add(
      _TicketProductLine(
        name: item.productName,
        quantity: remainingQty,
        unitPrice: item.unitPrice,
        lineTotal: item.unitPrice * remainingQty,
        offered: false,
        note: item.itemNote,
      ),
    );
  }

  if (offeredQty > 0) {
    rows.add(
      _TicketProductLine(
        name: item.productName,
        quantity: offeredQty,
        unitPrice: item.unitPrice,
        lineTotal: 0.0,
        offered: true,
        note: 'Offert${offeredByName != null ? ' par $offeredByName' : ''}',
      ),
    );
  }

  if (rows.isEmpty) {
    rows.add(
      _TicketProductLine(
        name: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        lineTotal: item.unitPrice * item.quantity,
        offered: false,
        note: item.itemNote,
      ),
    );
  }

  return rows;
}

_OfferedTicketSummary _summarizeOfferedProducts(List<PosOrderItem> items) {
  var quantity = 0;
  var value = 0.0;

  for (final item in items) {
    for (final line in _resolveTicketProductLines(item)) {
      if (!line.offered) {
        continue;
      }
      quantity += line.quantity;
      value += line.quantity * line.unitPrice;
    }
  }

  return _OfferedTicketSummary(quantity: quantity, value: value);
}

pw.Widget _buildOfferedBadgeWidget({String? label}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 0.7),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(
      (label ?? 'OFFERT').toUpperCase(),
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    ),
  );
}

List<pw.Widget> _buildOfferedSummaryWidgets(
  List<PosOrderItem> items, {
  required String Function(double) money,
}) {
  final summary = _summarizeOfferedProducts(items);
  if (summary.quantity <= 0) {
    return const [];
  }

  return [
    pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OFFERT',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Produits offerts:',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                summary.quantity.toString(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Valeur offerte:',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                money(summary.value),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ];
}

List<pw.Widget> _buildSimpleCustomerTicketItems(
  List<PosOrderItem> items, {
  required String Function(double) money,
}) {
  final widgets = <pw.Widget>[];

  for (final it in items) {
    final lines = _resolveTicketProductLines(it);
    for (final line in lines) {
      final displayQty = line.offered
          ? '${line.quantity} GRATUIT'
          : '${line.quantity} x';
      final displayPrice = line.offered ? 'OFFERT' : money(line.lineTotal);

      widgets.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                '$displayQty ${cleanOrderItemProductName(line.name)}',
                style: line.offered
                    ? pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      )
                    : pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              displayPrice,
              style: line.offered
                  ? pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    )
                  : pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
      );
      if (line.offered) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, top: 2),
            child: _buildOfferedBadgeWidget(),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 3));
    }
  }

  return widgets;
}

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
            border: pw.Border.all(color: PdfColors.black, width: 0.7),
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
        final lines = _resolveTicketProductLines(it);
        for (final line in lines) {
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
                            '${line.quantity} x ${cleanOrderItemProductName(line.name)}',
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(money!(line.lineTotal)),
                      ],
                    )
                  else
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 32,
                          child: pw.Text(
                            '${line.quantity}x',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(cleanOrderItemProductName(line.name)),
                        ),
                      ],
                    ),
                  if (line.offered)
                    pw.Padding(
                      padding: pw.EdgeInsets.only(left: 12, top: 2),
                      child: _buildOfferedBadgeWidget(),
                    ),
                  if (line.note != null && line.note!.isNotEmpty)
                    pw.Padding(
                      padding: pw.EdgeInsets.only(left: 12, top: 2),
                      child: pw.Text(
                        line.note!,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      }
    });
  });

  return widgets;
}

List<Map<String, dynamic>> _extractPaymentEntries(PosOrder order) {
  final entries = parseSplitPaymentEntries(order.paymentSplit);

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
    final method = normalizePaymentMethod(entry['payment_method']?.toString());
    if (method == paymentMethodOffert) {
      return sum;
    }
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
  final diff = order.totalPrice - paidAmount;
  final remainingAmount = diff > 0.0 ? diff : 0.0;
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
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
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
                      color: PdfColors.black,
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
  String? restaurantAddress,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  return buildCustomerBillPdf(
    order,
    items,
    format: format,
    restaurantAddress: restaurantAddress,
    restaurantName: restaurantName,
    restaurantPhone: restaurantPhone,
  );
}

Future<Uint8List> buildKitchenTicketPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantAddress,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await _getRegularFont();
  final boldFont = await _getBoldFont();
  final sw = Stopwatch()..start();
  final doc = pw.Document();
  final pageFormat =
      format ??
      PdfPageFormat.roll80.copyWith(
        marginTop: 6,
        marginBottom: 6,
        marginLeft: 6,
        marginRight: 6,
      );
  final orderTime = _formatOrderTime(order.createdAt);

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
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
            pw.Divider(color: PdfColors.black),
            // Informations commande: uniquement numéro et date en gras
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Commande: #${order.id}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date/Heure: $orderTime',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Divider(color: PdfColors.black),
            // Détails produits
            ..._buildTicketItemWidgets(items, includePrices: false),
            ..._buildOfferedSummaryWidgets(
              items,
              money: AppSettingsService.instance.formatAmount,
            ),
            pw.Divider(color: PdfColors.black),
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

  final bytes = await doc.save();
  sw.stop();
  try {
    debugPrint(
      'PDF: buildKitchenTicketPdf order=${order.id} time=${sw.elapsedMilliseconds}ms size=${bytes.length} bytes',
    );
  } catch (_) {}
  return bytes;
}

Future<Uint8List> buildCustomerBillPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantAddress,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await _getRegularFont();
  final boldFont = await _getBoldFont();
  final sw = Stopwatch()..start();
  final doc = pw.Document();
  final pageFormat =
      format ??
      PdfPageFormat.roll80.copyWith(
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
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ..._buildRestaurantHeaderWidgets(
              logoImage,
              includeLogo: true,
              restaurantName: restaurantName,
              restaurantAddress: restaurantAddress,
              restaurantPhone: restaurantPhone,
            ),
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
            pw.Divider(color: PdfColors.black),
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
            if (order.glovoOrderNumber != null &&
                order.glovoOrderNumber!.trim().isNotEmpty)
              pw.Text(
                'Numéro Glovo: ${order.glovoOrderNumber}',
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
            pw.Divider(color: PdfColors.black),
            // Détails produits - version simplifiée pour client
            ..._buildSimpleCustomerTicketItems(items, money: money),
            ..._buildOfferedSummaryWidgets(items, money: money),
            pw.Divider(color: PdfColors.black),
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
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  ),
                  pw.Text(
                    '-${money(discount)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isPaidPayment ? 'TOTAL PAYÉ' : 'TOTAL À PAYER',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  isPaidPayment ? money(paidAmount) : money(total),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            if (paymentSummaryWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...paymentSummaryWidgets,
            ],
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.black),
            // Message de remerciement
            pw.Center(
              child: pw.Text(
                'Merci pour votre visite',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
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

  final bytes = await doc.save();
  sw.stop();
  try {
    debugPrint(
      'PDF: buildCustomerBillPdf order=${order.id} time=${sw.elapsedMilliseconds}ms size=${bytes.length} bytes',
    );
  } catch (_) {}
  return bytes;
}

Future<Uint8List> buildKitchenAndCustomerTicketsPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
  String? staffName,
  String? restaurantAddress,
  String? restaurantName,
  String? restaurantPhone,
}) async {
  final regularFont = await _getRegularFont();
  final boldFont = await _getBoldFont();
  final pageFormat =
      format ??
      PdfPageFormat.roll80.copyWith(
        marginTop: 6,
        marginBottom: 6,
        marginLeft: 6,
        marginRight: 6,
      );
  final sw = Stopwatch()..start();
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

  // Page 1: kitchen ticket
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ..._buildRestaurantHeaderWidgets(
              null,
              includeLogo: false,
              restaurantName: restaurantName,
              restaurantAddress: restaurantAddress,
              restaurantPhone: restaurantPhone,
            ),
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
            if (order.glovoOrderNumber != null &&
                order.glovoOrderNumber!.trim().isNotEmpty)
              pw.Text(
                'Numéro Glovo: ${order.glovoOrderNumber}',
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
            ..._buildOfferedSummaryWidgets(items, money: money),
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
            ..._buildRestaurantHeaderWidgets(
              logoImage,
              includeLogo: true,
              restaurantName: restaurantName,
              restaurantAddress: restaurantAddress,
              restaurantPhone: restaurantPhone,
            ),
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
            if (order.glovoOrderNumber != null &&
                order.glovoOrderNumber!.trim().isNotEmpty)
              pw.Text(
                'Numéro Glovo: ${order.glovoOrderNumber}',
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
            // Détails produits - version simplifiée pour client
            ..._buildSimpleCustomerTicketItems(items, money: money),
            ..._buildOfferedSummaryWidgets(items, money: money),
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
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  ),
                  pw.Text(
                    '-${money(discount)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isPaidPayment ? 'TOTAL PAYÉ' : 'TOTAL À PAYER',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  isPaidPayment ? money(paidAmount) : money(total),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            if (paymentSummaryWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...paymentSummaryWidgets,
            ],
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.black),
            pw.Center(
              child: pw.Text(
                'Merci pour votre visite',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
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

  final bytes = await doc.save();
  sw.stop();
  try {
    debugPrint(
      'PDF: buildKitchenAndCustomerTicketsPdf order=${order.id} time=${sw.elapsedMilliseconds}ms size=${bytes.length} bytes',
    );
  } catch (_) {}
  return bytes;
}

List<pw.Widget> _buildRestaurantHeaderWidgets(
  pw.MemoryImage? logoImage, {
  required bool includeLogo,
  String? restaurantName,
  String? restaurantAddress,
  String? restaurantPhone,
}) {
  final widgets = <pw.Widget>[];
  final hasRestaurantName = restaurantName?.trim().isNotEmpty == true;
  final hasRestaurantAddress = restaurantAddress?.trim().isNotEmpty == true;
  final hasRestaurantPhone = restaurantPhone?.trim().isNotEmpty == true;
  final hasRestaurantInfo =
      hasRestaurantName || hasRestaurantAddress || hasRestaurantPhone;

  if (includeLogo && logoImage != null) {
    widgets.add(
      pw.Center(
        child: pw.SizedBox(
          width: _ticketLogoWidth,
          height: _ticketLogoHeight,
          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  if (includeLogo && logoImage != null) {
    widgets.add(pw.SizedBox(height: _ticketLogoSpacing));
  }

  if (hasRestaurantName) {
    widgets.add(
      pw.Center(
        child: pw.Text(
          restaurantName!.trim(),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }
  if (hasRestaurantAddress) {
    widgets.add(
      pw.Center(
        child: pw.Text(
          'Adresse: ${restaurantAddress!.trim()}',
          style: pw.TextStyle(fontSize: 8),
        ),
      ),
    );
  }
  if (hasRestaurantPhone) {
    widgets.add(
      pw.Center(
        child: pw.Text(
          'Tél: ${restaurantPhone!.trim()}',
          style: pw.TextStyle(fontSize: 9),
        ),
      ),
    );
  }

  if (hasRestaurantInfo || (includeLogo && logoImage != null)) {
    widgets.add(pw.SizedBox(height: _ticketLogoSpacing));
  }

  return widgets;
}

Future<pw.MemoryImage?> _loadLogoImage() async {
  await AppSettingsService.instance.init();
  final settings = AppSettingsService.instance.settings;
  final logoPath = settings.ticketLogoPath;
  if (logoPath == null || logoPath.trim().isEmpty) {
    _cachedLogoPath = null;
    _cachedLogoImage = null;
    return null;
  }

  // Return cached image if path unchanged
  if (_cachedLogoPath == logoPath && _cachedLogoImage != null) {
    return _cachedLogoImage;
  }

  pw.MemoryImage? result;
  try {
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      final response = await http.get(Uri.parse(logoPath));
      if (response.statusCode == 200) {
        final decoded = img.decodeImage(response.bodyBytes);
        if (decoded != null) {
          result = pw.MemoryImage(response.bodyBytes);
        }
      }
    } else {
      var resolvedPath = logoPath.trim();
      if (resolvedPath.startsWith('file://')) {
        resolvedPath = resolvedPath.replaceFirst('file://', '');
      }
      final file = File(resolvedPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          result = pw.MemoryImage(bytes);
        }
      }
    }
  } catch (_) {}

  _cachedLogoPath = logoPath;
  _cachedLogoImage = result;
  return result;
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
  final regularFont = await _getRegularFont();
  final boldFont = await _getBoldFont();
  final sw = Stopwatch()..start();
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

  // Modes de paiement (cartographie dynamique)
  final paymentMethods =
      summary['payment_methods'] as Map<String, dynamic>? ?? {};

  // Types de commande
  final orderTypes = summary['order_types'] as Map<String, dynamic>? ?? {};
  final onsiteCount = orderTypes['onsite'] as int? ?? 0;
  final pickupCount = orderTypes['pickup'] as int? ?? 0;
  final deliveryCount = orderTypes['delivery'] as int? ?? 0;

  // Statistiques par serveur et livreur
  final staffBreakdown = summary['staff_breakdown'] as List<dynamic>? ?? [];
  final deliveryBreakdown =
      summary['delivery_breakdown'] as List<dynamic>? ?? [];
  final totalDiscounts =
      (summary['total_discounts'] as num?)?.toDouble() ?? 0.0;
  final totalOfferedQuantity = summary['total_offered_quantity'] as int? ?? 0;
  final totalOfferedValue =
      (summary['total_offered_value'] as num?)?.toDouble() ?? 0.0;
  final compteRendu =
      (summary['compte_rendu'] as num?)?.toDouble() ??
      (totalRevenue - (totalDiscounts + totalOfferedValue));

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (context) {
        final visiblePayments = paymentMethods.entries.where((e) {
          final amount = (e.value as num?)?.toDouble() ?? 0.0;
          return amount > 0.0;
        }).toList();

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
                  pw.Text('Date : $dateStr', style: pw.TextStyle(fontSize: 11)),
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
            _buildReportRow(
              'Total remises:',
              '${totalDiscounts.toStringAsFixed(2)} Dhs',
            ),
            _buildReportRow('Total produits offerts:', '$totalOfferedQuantity'),
            _buildReportRow(
              'Valeur offerts:',
              '${totalOfferedValue.toStringAsFixed(2)} Dhs',
            ),
            _buildReportRow(
              'Compte rendu:',
              '${compteRendu.toStringAsFixed(2)} Dhs',
            ),
            pw.SizedBox(height: 8),

            // Modes de paiement (affiche seulement ceux avec montant > 0)
            if (visiblePayments.isNotEmpty) ...[
              pw.Text(
                'Modes de paiement:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              ...visiblePayments.map((entry) {
                final methodKey = entry.key.toString();
                final amount = (entry.value as num?)?.toDouble() ?? 0.0;
                return _buildReportRow(
                  '   ${paymentMethodLabel(methodKey)}:',
                  '${amount.toStringAsFixed(2)} Dhs',
                );
              }),
            ] else ...[
              pw.Text(
                'Modes de paiement: Aucun enregistrement',
                style: pw.TextStyle(color: PdfColors.grey700),
              ),
            ],
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
                final staffNameRaw = (staffMap['staff_name'] as String?)
                    ?.trim();
                final staffName =
                    staffNameRaw != null && staffNameRaw.isNotEmpty
                    ? staffNameRaw
                    : 'Serveur #$staffId';
                final ordersCount = staffMap['orders_count'] as int? ?? 0;
                final totalRevenueStaff =
                    (staffMap['total_revenue'] as num?)?.toDouble() ?? 0.0;
                final paymentMethodsStaff =
                    staffMap['payment_methods'] as Map<String, dynamic>? ?? {};
                final staffDiscounts =
                    (staffMap['discounts'] as num?)?.toDouble() ?? 0.0;
                final staffOfferedQty =
                    staffMap['offered_quantity'] as int? ?? 0;
                final staffOfferedValue =
                    (staffMap['offered_value'] as num?)?.toDouble() ?? 0.0;
                final staffCompte =
                    (staffMap['compte_rendu'] as num?)?.toDouble() ??
                    (totalRevenueStaff - (staffDiscounts + staffOfferedValue));

                final visibleStaffPayments = paymentMethodsStaff.entries.where((
                  e,
                ) {
                  final amount = (e.value as num?)?.toDouble() ?? 0.0;
                  return amount > 0.0;
                }).toList();

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
                    if (visibleStaffPayments.isNotEmpty) ...[
                      ...visibleStaffPayments.map((entry) {
                        final key = entry.key.toString();
                        final amount = (entry.value as num?)?.toDouble() ?? 0.0;
                        return _buildReportRow(
                          '      ${paymentMethodLabel(key)}:',
                          '${amount.toStringAsFixed(2)} Dhs',
                        );
                      }),
                    ],
                    if (staffDiscounts > 0)
                      _buildReportRow(
                        '      Remises:',
                        '-${staffDiscounts.toStringAsFixed(2)} Dhs',
                      ),
                    if (staffOfferedQty > 0)
                      _buildReportRow(
                        '      Produits offerts:',
                        '$staffOfferedQty',
                      ),
                    if (staffOfferedValue > 0)
                      _buildReportRow(
                        '      Valeur offerts:',
                        '${staffOfferedValue.toStringAsFixed(2)} Dhs',
                      ),
                    _buildReportRow(
                      '      Compte rendu:',
                      '${staffCompte.toStringAsFixed(2)} Dhs',
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
                final deliveryStaffId =
                    deliveryMap['delivery_staff_id'] as int? ?? 0;
                final deliveryStaffNameRaw =
                    (deliveryMap['delivery_staff_name'] as String?)?.trim();
                final deliveryStaffName =
                    deliveryStaffNameRaw != null &&
                        deliveryStaffNameRaw.isNotEmpty
                    ? deliveryStaffNameRaw
                    : 'Livreur #$deliveryStaffId';
                final deliveryCount =
                    deliveryMap['delivery_count'] as int? ?? 0;
                final deliveryRevenue =
                    (deliveryMap['delivery_revenue'] as num?)?.toDouble() ??
                    0.0;

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

  final bytes = await doc.save();
  sw.stop();
  try {
    debugPrint(
      'PDF: buildDailyReportPdf time=${sw.elapsedMilliseconds}ms size=${bytes.length} bytes',
    );
  } catch (_) {}
  return bytes;
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

/// Build a daily report PDF for a given restaurant and date by fetching
/// orders and items from the database and aggregating metrics.
Future<Uint8List> buildDailyReportForRestaurantDate(
  int restaurantId,
  DateTime date,
) async {
  // Load orders and filter by exact restaurant + day range
  final allOrders = await DatabaseService.getPosOrders();
  final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  final filtered = allOrders.where((order) {
    if (order.restaurantId != restaurantId) return false;
    final created = order.createdAt.toLocal();
    return !created.isBefore(startOfDay) && !created.isAfter(endOfDay);
  }).toList();

  final dateStr =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  double totalRevenue = 0.0;
  int totalOrders = filtered.length;
  double totalDiscounts = 0.0;

  final paymentMethods = <String, double>{};
  final orderTypes = <String, int>{};
  final staffMap = <int, Map<String, dynamic>>{};
  final deliveryMap = <int, Map<String, dynamic>>{};

  var totalOfferedQuantity = 0;
  var totalOfferedValue = 0.0;

  for (final order in filtered) {
    // Sum totals
    totalRevenue += order.totalPrice;
    totalDiscounts += order.discountAmount;

    // Payment breakdown (respect split payments). Include all methods (offert included)
    final splitTotals = splitPaymentTotalsByMethod(
      order.paymentSplit,
      includeOffert: true,
    );
    if (splitTotals.isNotEmpty) {
      splitTotals.forEach((method, amount) {
        final key = method.isEmpty ? 'other' : method;
        paymentMethods[key] = (paymentMethods[key] ?? 0.0) + amount;
      });
    } else {
      final norm = normalizePaymentMethod(order.paymentMethod);
      final methodKey = norm.isEmpty ? 'other' : norm;
      paymentMethods[methodKey] =
          (paymentMethods[methodKey] ?? 0.0) + order.totalPrice;
    }

    // Order types
    final typeKey = order.fulfillmentType.trim().toLowerCase();
    orderTypes[typeKey] = (orderTypes[typeKey] ?? 0) + 1;

    // Server / staff breakdown
    final staffKey = order.staffId;
    final staffEntry =
        staffMap[staffKey] ??
        {
          'staff_id': staffKey,
          'staff_name': null,
          'orders_count': 0,
          'total_revenue': 0.0,
          'payment_methods': <String, double>{},
        };
    staffEntry['orders_count'] = (staffEntry['orders_count'] as int) + 1;
    staffEntry['total_revenue'] =
        (staffEntry['total_revenue'] as double) + order.totalPrice;
    // Add staff-level payment split totals
    if (splitTotals.isNotEmpty) {
      splitTotals.forEach((method, amount) {
        final pm = staffEntry['payment_methods'] as Map<String, double>;
        final key = method.isEmpty ? 'other' : method;
        pm[key] = (pm[key] ?? 0.0) + amount;
      });
    } else {
      final norm = normalizePaymentMethod(order.paymentMethod);
      final methodKey = norm.isEmpty ? 'other' : norm;
      final pm = staffEntry['payment_methods'] as Map<String, double>;
      pm[methodKey] = (pm[methodKey] ?? 0.0) + order.totalPrice;
    }
    staffMap[staffKey] = staffEntry;

    // Delivery breakdown
    if (order.deliveryLivreurId != null && order.deliveryLivreurId! > 0) {
      final dId = order.deliveryLivreurId!;
      final dEntry =
          deliveryMap[dId] ??
          {
            'delivery_staff_id': dId,
            'delivery_staff_name': order.deliveryLivreurName,
            'delivery_count': 0,
            'delivery_revenue': 0.0,
          };
      dEntry['delivery_count'] = (dEntry['delivery_count'] as int) + 1;
      dEntry['delivery_revenue'] =
          (dEntry['delivery_revenue'] as double) + order.totalPrice;
      deliveryMap[dId] = dEntry;
    }

    // Offered items summary (per order)
    final items = await DatabaseService.getPosOrderItems(order.id);
    final offeredSummary = _summarizeOfferedProducts(items);
    totalOfferedQuantity += offeredSummary.quantity;
    totalOfferedValue += offeredSummary.value;
  }

  // Build summary map
  final summary = <String, dynamic>{
    'total_revenue': totalRevenue,
    'total_orders': totalOrders,
    'total_discounts': totalDiscounts,
    'total_offered_quantity': totalOfferedQuantity,
    'total_offered_value': totalOfferedValue,
    'payment_methods': paymentMethods,
    'order_types': orderTypes,
    'staff_breakdown': staffMap.values.toList(),
    'delivery_breakdown': deliveryMap.values.toList(),
  };

  final reportData = {'date': dateStr, 'summary': summary};

  return buildDailyReportPdf(reportData);
}
