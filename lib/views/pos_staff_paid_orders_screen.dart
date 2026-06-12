import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:async';
import 'package:printing/printing.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../services/esc_pos_printer_service.dart';
import '../services/print_queue_service.dart';
import '../services/app_settings_service.dart';
import '../utils/payment_method_utils.dart';
import '../utils/pos_ticket_printer.dart';
import '../widgets/order_details_dialog.dart';
import '../services/database_service.dart';

class PosStaffPaidOrdersScreen extends StatefulWidget {
  const PosStaffPaidOrdersScreen({super.key});

  @override
  State<PosStaffPaidOrdersScreen> createState() =>
      _PosStaffPaidOrdersScreenState();
}

class _PosStaffPaidOrdersScreenState extends State<PosStaffPaidOrdersScreen> {
  // ── palette ──────────────────────────────────────────────────────────────
  static const _red = Color(0xFFD32F2F);
  static const _black = Color(0xFF1A1A1A);
  static const _grey = Color(0xFF757575);
  static const _border = Color(0xFFE0E0E0);
  static const _bg = Color(0xFFF5F5F5);

  final PosController pos = Get.find<PosController>();
  DateTime _selectedDate = DateTime.now();
  List<PosOrder> _filteredOrders = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<int>? _ordersSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Reload when orders change elsewhere
    _ordersSub = pos.ordersRevision.listen((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    // Mark loading state early. Guard subsequent updates to avoid
    // calling setState after dispose when async work completes.
    setState(() => _loading = true);
    try {
      await pos.loadOrdersToday();
    } catch (_) {}

    if (!mounted) return;

    final all = pos.ordersToday;
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      0,
      0,
      0,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
      999,
    );

    final filtered = all
        .where(
          (o) =>
              o.paymentStatus == 'paid' || o.paymentStatus == 'partially_paid',
        )
        .where((o) {
          final created = o.createdAt.toLocal();
          return !created.isBefore(startOfDay) && !created.isAfter(endOfDay);
        })
        .toList();

    if (!mounted) return;
    setState(() {
      _filteredOrders = filtered;
      _loading = false;
    });
  }

  String _formatPaidAmount(PosOrder order) {
    return pos.paidAmountForOrder(order).toStringAsFixed(2);
  }

  String _paymentMethodLabel(String? method) => switch (method) {
    'cash' => 'Espèces',
    'card' => 'Carte',
    'split' => 'Split',
    'offert' => 'Offert',
    null => '—',
    _ => paymentMethodLabel(method),
  };

  bool _hasOffertPayment(PosOrder order) =>
      isOfferedPaymentMethod(order.paymentMethod) ||
      hasOfferedSplitPayment(order.paymentSplit);

  Widget _statusBadge({
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── channel badge ────────────────────────────────────────────────────────
  Widget _channelBadge(String? channel) {
    final c = channel?.trim().toLowerCase() ?? 'pos';
    final label = switch (c) {
      'pos' => 'POS',
      'web' => 'Web',
      'api' => 'API',
      'mobile' => 'Mobile',
      _ => c.toUpperCase(),
    };
    final icon = switch (c) {
      'web' => Icons.language,
      'api' => Icons.code,
      'mobile' => Icons.smartphone,
      _ => Icons.point_of_sale, // pos
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _border, width: 0.8),
        borderRadius: BorderRadius.circular(4),
        color: _bg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _grey),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _grey,
            ),
          ),
        ],
      ),
    );
  }

  // ── fulfillment helpers ───────────────────────────────────────────────────
  ({String label, IconData icon}) _fulfillmentInfo(String? type) =>
      switch (type) {
        'on_site' => (label: 'Sur place', icon: Icons.table_restaurant),
        'pickup' => (label: 'À emporter', icon: Icons.shopping_bag_outlined),
        'delivery' => (label: 'Livraison', icon: Icons.delivery_dining),
        _ => (label: 'Sur place', icon: Icons.table_restaurant),
      };

  Future<void> _printCustomerTicket(PosOrder order) async {
    try {
      final items = await DatabaseService.getPosOrderItems(order.id);
      debugPrint(
        'Printing: retrieved ${items.length} items for order ${order.id}',
      );
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun article trouvé pour cette commande'),
            ),
          );
        }
        return;
      }

      final restaurant = order.restaurantId != null
          ? await DatabaseService.getRestaurantById(order.restaurantId!)
          : null;

      await AppSettingsService.instance.init();
      final settings = AppSettingsService.instance.settings;
      if (settings.useEscPosPrinting) {
        final bytes = await EscPosPrinterService.instance.buildCustomerTicketEscPos(
          order,
          items,
          restaurantAddress: restaurant?.address,
          restaurantName: restaurant?.name,
          restaurantPhone: restaurant?.phone,
        );

        final host = settings.receiptPrinterHost?.trim() ?? '';
        final port = settings.receiptPrinterPort;

        await PrintQueueService.instance.enqueueAndStart(
          ticketType: 'customer',
          printerHost: host,
          printerPort: port,
          payload: bytes,
          orderRef: order.id.toString(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket mis en file d\'impression')),
          );
        }
        return;
      }

      debugPrint(
        'Impression indisponible, ouverture de l\'aperçu PDF pour la commande ${order.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impression indisponible, ouverture de l\'aperçu PDF...',
            ),
          ),
        );
      }
      final pdfData = await buildCustomerBillPdf(
        order,
        items,
        restaurantAddress: restaurant?.address,
        restaurantName: restaurant?.name,
        restaurantPhone: restaurant?.phone,
      );
      // Sur macOS, `Printing.layoutPdf` peut provoquer des comportements
      // natifs inattendus si aucune imprimante n'est configurée. Pour éviter
      // un plantage, on évite d'appeler `layoutPdf` sur macOS et on ouvre
      // directement le fichier PDF en fallback.
      if (Platform.isMacOS) {
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          debugPrint('Saved PDF ticket to ${file.path} (macOS fallback)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF sauvegardé: ${file.path}'),
              ),
            );
          }
          try {
            await Process.run('open', [file.path]);
          } catch (_) {
            // ignore
          }
          return;
        } catch (e) {
          debugPrint('macOS fallback save/open failed: $e');
          // continuer vers la tentative d'aperçu standard
        }
      }

      try {
        // Essayer l'aperçu via printing avec timeout pour éviter blocage
        await Printing.layoutPdf(onLayout: (_) async => pdfData)
            .timeout(const Duration(seconds: 6));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Aperçu PDF ouvert.')));
        }
      } on Exception catch (e) {
        debugPrint('Printing.layoutPdf error/timeout: $e');
        // fallback: sauvegarder et ouvrir le fichier
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          debugPrint('Saved PDF ticket to ${file.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Échec impression PDF: $e. PDF sauvegardé: ${file.path}',
                ),
              ),
            );
          }
          try {
            if (Platform.isMacOS) {
              await Process.run('open', [file.path]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [file.path]);
            } else if (Platform.isWindows) {
              await Process.run('start', [file.path], runInShell: true);
            }
          } catch (_) {}
        } catch (saveErr) {
          debugPrint('Saving PDF fallback failed: $saveErr');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Échec impression PDF: $e. Erreur sauvegarde PDF: $saveErr',
                ),
              ),
            );
          }
        }
      } catch (e, st) {
        debugPrint('Printing.layoutPdf error: $e\n$st');
        // Même fallback en cas d'erreur inattendue
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF sauvegardé: ${file.path}'),
              ),
            );
          }
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('Unexpected error printing ticket: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression inattendue: $e')),
        );
      }
    }
  }

  Future<void> _printKitchenTicket(PosOrder order) async {
    try {
      final items = await DatabaseService.getPosOrderItems(order.id);
      debugPrint(
        'Printing kitchen: retrieved ${items.length} items for order ${order.id}',
      );
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun article trouvé pour cette commande'),
            ),
          );
        }
        return;
      }

      final restaurant = order.restaurantId != null
          ? await DatabaseService.getRestaurantById(order.restaurantId!)
          : null;

      final directPrinted = await EscPosPrinterService.instance
          .tryPrintKitchenTicket(
            order,
            items,
            restaurantAddress: restaurant?.address,
            restaurantName: restaurant?.name,
            restaurantPhone: restaurant?.phone,
          );
      if (directPrinted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket cuisine imprimé directement')),
          );
        }
        return;
      }

      debugPrint(
        'Impression cuisine indisponible, ouverture de l\'aperçu PDF pour la commande ${order.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impression cuisine indisponible, ouverture de l\'aperçu PDF...',
            ),
          ),
        );
      }

      final pdfData = await buildKitchenTicketPdf(
        order,
        items,
        restaurantAddress: restaurant?.address,
        restaurantName: restaurant?.name,
        restaurantPhone: restaurant?.phone,
      );

      if (Platform.isMacOS) {
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_kitchen_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          debugPrint('Saved kitchen PDF ticket to ${file.path} (macOS fallback)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF sauvegardé: ${file.path}'),
              ),
            );
          }
          try {
            await Process.run('open', [file.path]);
          } catch (_) {}
          return;
        } catch (e) {
          debugPrint('macOS fallback save/open failed: $e');
        }
      }

      try {
        await Printing.layoutPdf(onLayout: (_) async => pdfData)
            .timeout(const Duration(seconds: 6));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aperçu PDF ouvert.')),
          );
        }
      } on Exception catch (e) {
        debugPrint('Printing.layoutPdf error/timeout (kitchen): $e');
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_kitchen_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          debugPrint('Saved kitchen PDF ticket to ${file.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Échec impression PDF: $e. PDF sauvegardé: ${file.path}',
                ),
              ),
            );
          }
          try {
            if (Platform.isMacOS) {
              await Process.run('open', [file.path]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [file.path]);
            } else if (Platform.isWindows) {
              await Process.run('start', [file.path], runInShell: true);
            }
          } catch (_) {}
        } catch (saveErr) {
          debugPrint('Saving kitchen PDF fallback failed: $saveErr');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Échec impression PDF: $e. Erreur sauvegarde PDF: $saveErr',
                ),
              ),
            );
          }
        }
      } catch (e, st) {
        debugPrint('Printing.layoutPdf error (kitchen): $e\n$st');
        try {
          final tmp = Directory.systemTemp;
          final file = File('${tmp.path}/ticket_kitchen_order_${order.id}.pdf');
          await file.writeAsBytes(pdfData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF sauvegardé: ${file.path}'),
              ),
            );
          }
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('Unexpected error printing kitchen ticket: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression inattendue: $e')),
        );
      }
    }
  }

  // ── card ─────────────────────────────────────────────────────────────────
  Widget _orderCard(PosOrder order) {
    final isPartial = order.paymentStatus == 'partially_paid';
    final ff = _fulfillmentInfo(order.fulfillmentType);
    final hasOffert = _hasOffertPayment(order);

    return InkWell(
      onTap: () => showOrderDetailsDialog(context, order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              color: _black,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '#${order.id} · ${order.customerName ?? 'Client'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _statusBadge(
                          label: isPartial ? 'Partiel' : 'Payé',
                          textColor: Colors.white,
                          backgroundColor: isPartial ? Colors.white12 : _red,
                        ),
                        if (order.hasDiscount && order.discountAmount > 0)
                          _statusBadge(
                            label: 'Remise',
                            textColor: Colors.green,
                            backgroundColor: Colors.green.withOpacity(0.18),
                          ),
                        if (hasOffert)
                          _statusBadge(
                            label: 'Offerts',
                            textColor: Colors.teal.shade700,
                            backgroundColor: Colors.teal.withOpacity(0.18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── fulfillment type banner ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              color: _bg,
              child: Row(
                children: [
                  Icon(ff.icon, size: 12, color: _red),
                  const SizedBox(width: 5),
                  Text(
                    ff.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _red,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  _channelBadge(order.channel),
                  const SizedBox(width: 5),
                  Text(
                    order.customerPhone ?? '',
                    style: TextStyle(fontSize: 10, color: _grey),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 0.6, color: _border),

            // ── body ─────────────────────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _infoRow(
                        'Total',
                        '${order.totalPrice.toStringAsFixed(2)} Dhs',
                      ),
                      const SizedBox(height: 3),
                      _infoRow('Payé', '${_formatPaidAmount(order)} Dhs'),
                      const SizedBox(height: 3),
                      if (order.hasDiscount && order.discountAmount > 0) ...[
                        _infoRow(
                          'Remise',
                          '-${order.discountAmount.toStringAsFixed(2)} Dhs',
                        ),
                        const SizedBox(height: 3),
                      ],
                      if (hasOffert) ...[
                        _infoRow('Offerts', 'Oui'),
                        const SizedBox(height: 3),
                      ],
                      _infoRow(
                        'Méthode',
                        _paymentMethodLabel(order.paymentMethod),
                      ),
                      const SizedBox(height: 3),
                      _infoRow(
                        'Heure',
                        '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${order.createdAt.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(height: 1, thickness: 0.6, color: _border),

            // ── footer ───────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _printCustomerTicket(order),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.print, size: 13, color: _red),
                          SizedBox(width: 5),
                          Text(
                            'Imprimer ticket',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _printKitchenTicket(order),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.kitchen_outlined, size: 13, color: _red),
                          SizedBox(width: 5),
                          Text(
                            'Ticket cuisine',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: _grey)),
      Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _black,
        ),
      ),
    ],
  );

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _load();
      return;
    }
    setState(() {
      _filteredOrders = _filteredOrders.where((o) {
        final s = '${o.id} ${o.customerName ?? ''} ${o.customerPhone ?? ''}'
            .toLowerCase();
        return s.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 96, 96),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Commandes payées',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── toolbar ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: _grey,
                        ),
                        hintText: 'Recherche…',
                        hintStyle: const TextStyle(fontSize: 13, color: _grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: _border,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _red, width: 1.2),
                        ),
                      ),
                      onChanged: (_) => _onSearchChanged(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      setState(() => _selectedDate = d);
                      await _load();
                    }
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: _red),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedDate.year}-'
                          '${_selectedDate.month.toString().padLeft(2, '0')}-'
                          '${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── grid ─────────────────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _red)),
              )
            else if (_filteredOrders.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Aucune commande trouvée',
                    style: TextStyle(color: _grey, fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: _red,
                  onRefresh: _load,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      // lower aspect ratio => taller tiles to avoid vertical overflow
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (_, i) => _orderCard(_filteredOrders[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
