import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_order.dart';
import '../services/esc_pos_printer_service.dart';
import '../utils/pos_ticket_printer.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await pos.loadOrdersToday();
    } catch (_) {}
    final all = pos.ordersToday;
    _filteredOrders = all
        .where(
          (o) =>
              o.paymentStatus == 'paid' || o.paymentStatus == 'partially_paid',
        )
        .where(
          (o) =>
              o.createdAt.year == _selectedDate.year &&
              o.createdAt.month == _selectedDate.month &&
              o.createdAt.day == _selectedDate.day,
        )
        .toList();
    setState(() => _loading = false);
  }

  String _formatPaidAmount(PosOrder order) {
    if (order.paymentSplit == null || order.paymentSplit!.isEmpty) {
      return order.totalPrice.toStringAsFixed(2);
    }
    try {
      final parts = jsonDecode(order.paymentSplit!) as List<dynamic>;
      double sum = 0;
      for (final p in parts) {
        if (p is Map && p['amount'] != null) {
          sum += (p['amount'] as num).toDouble();
        }
      }
      return sum.toStringAsFixed(2);
    } catch (_) {
      return order.totalPrice.toStringAsFixed(2);
    }
  }

  String _paymentMethodLabel(String? method) => switch (method) {
    'cash' => 'Espèces',
    'card' => 'Carte',
    'split' => 'Split',
    null => '—',
    _ => method,
  };

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
      final directPrinted = await EscPosPrinterService.instance
          .tryPrintCustomerTicket(order, items);
      if (directPrinted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket envoye directement a l\'imprimante'),
            ),
          );
        }
        return;
      }
      final pdfData = await buildCustomerBillPdf(order, items);
      await Printing.layoutPdf(onLayout: (_) async => pdfData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur impression: $e')));
      }
    }
  }

  // ── card ─────────────────────────────────────────────────────────────────
  Widget _orderCard(PosOrder order) {
    final isPartial = order.paymentStatus == 'partially_paid';
    final ff = _fulfillmentInfo(order.fulfillmentType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: _black,
            child: Row(
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
                // payment status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPartial ? Colors.white12 : _red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPartial ? 'Partiel' : 'Payé',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              children: [
                _infoRow('Total', '${order.totalPrice.toStringAsFixed(2)} Dhs'),
                const SizedBox(height: 3),
                _infoRow('Payé', '${_formatPaidAmount(order)} Dhs'),
                const SizedBox(height: 3),
                _infoRow('Méthode', _paymentMethodLabel(order.paymentMethod)),
                const SizedBox(height: 3),
                _infoRow(
                  'Heure',
                  '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${order.createdAt.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.6, color: _border),

          // ── footer ───────────────────────────────────────────────────────
          InkWell(
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
        ],
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
                          borderSide: const BorderSide(
                            color: _border,
                            width: 0.8,
                          ),
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
            const SizedBox(height: 12),

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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.05,
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
