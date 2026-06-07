import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/auth_controller.dart';
import '../models/cash_register_state.dart';
import '../services/database_service.dart';
import '../services/daily_report_service.dart';
import '../services/esc_pos_printer_service.dart';
import '../theme/sushi_design.dart';
import '../utils/pos_ticket_printer.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/admin_shell.dart';

class DailyReportsScreen extends StatefulWidget {
  const DailyReportsScreen({super.key});

  @override
  State<DailyReportsScreen> createState() => _DailyReportsScreenState();
}

class _DailyReportsScreenState extends State<DailyReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  List<CashRegisterState> _reports = [];
  bool _showAllReports = true;

  // ─────────────────────────────────────────────────────────────
  //  Toute la logique métier est IDENTIQUE à l'original
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    setState(() => _loading = true);
    try {
      final allReports = await DatabaseService.db.cashRegisterStates
          .where()
          .findAll();
      final validReports = <CashRegisterState>[];
      for (final report in allReports) {
        if (report.closingReport != null &&
            report.closingReport!.isNotEmpty &&
            report.date.isNotEmpty) {
          validReports.add(report);
        }
      }
      await _addTodayReportIfMissing(validReports);
      validReports.sort((a, b) {
        final dateA = DateTime.tryParse(a.date) ?? DateTime(2020);
        final dateB = DateTime.tryParse(b.date) ?? DateTime(2020);
        return dateB.compareTo(dateA);
      });
      _reports = validReports;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les rapports: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTodayReportIfMissing(List<CashRegisterState> reports) async {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final hasTodayReport = reports.any((r) => r.date == todayStr);
    if (!hasTodayReport) {
      try {
        final authController = Get.find<AuthController>();
        final staffId = authController.currentUser?.id ?? 0;
        final staffName = authController.currentUser?.name ?? 'Admin';
        final todayReportMap = await DailyReportService.generateDailyReport(
          date: today,
          staffId: staffId,
          staffName: staffName,
          openedAt: null,
          closedAt: null,
        );
        final todayReport = CashRegisterState()
          ..date = todayStr
          ..closingReport = jsonEncode(todayReportMap)
          ..isOpen = true;
        reports.add(todayReport);
      } catch (e) {
        print("Erreur lors de la génération du rapport d'aujourd'hui: $e");
      }
    }
  }

  Future<void> _loadReportsByDateRange() async {
    if (_startDate == null || _endDate == null) {
      _loadAllReports();
      return;
    }
    setState(() => _loading = true);
    try {
      final allReports = await DatabaseService.db.cashRegisterStates
          .where()
          .findAll();
      final startOfDay = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
      ).add(const Duration(days: 1));
      final validReports = <CashRegisterState>[];
      for (final report in allReports) {
        if (report.closingReport != null &&
            report.closingReport!.isNotEmpty &&
            report.date.isNotEmpty) {
          final reportDate = DateTime.tryParse(report.date) ?? DateTime(2020);
          if (reportDate.isAfter(startOfDay) && reportDate.isBefore(endOfDay)) {
            validReports.add(report);
          }
        }
      }
      final today = DateTime.now();
      if (today.isAfter(startOfDay) && today.isBefore(endOfDay)) {
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final hasTodayReport = validReports.any((r) => r.date == todayStr);
        if (!hasTodayReport) {
          try {
            final authController = Get.find<AuthController>();
            final staffId = authController.currentUser?.id ?? 0;
            final staffName = authController.currentUser?.name ?? 'Admin';
            final todayReportMap = await DailyReportService.generateDailyReport(
              date: today,
              staffId: staffId,
              staffName: staffName,
              openedAt: null,
              closedAt: null,
            );
            final todayReport = CashRegisterState()
              ..date = todayStr
              ..closingReport = jsonEncode(todayReportMap)
              ..isOpen = true;
            validReports.add(todayReport);
          } catch (e) {
            print("Erreur lors de la génération du rapport d'aujourd'hui: $e");
          }
        }
      }
      validReports.sort((a, b) {
        final dateA = DateTime.tryParse(a.date) ?? DateTime(2020);
        final dateB = DateTime.tryParse(b.date) ?? DateTime(2020);
        return dateB.compareTo(dateA);
      });
      _reports = validReports;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les rapports: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _parseReportData(String? closingReport) {
    if (closingReport == null || closingReport.isEmpty) return null;
    try {
      final rawData = jsonDecode(closingReport);
      if (rawData is Map<String, dynamic> &&
          rawData.containsKey('totalSales')) {
        return _convertOldReportToNewFormat(rawData);
      }
      return rawData as Map<String, dynamic>;
    } catch (e) {
      print("Erreur lors du parsing du rapport: $e");
      return null;
    }
  }

  Map<String, dynamic> _convertOldReportToNewFormat(
    Map<String, dynamic> oldReport,
  ) {
    final totalSales = oldReport['totalSales'] as num? ?? 0.0;
    final totalOrders = oldReport['totalOrders'] as int? ?? 0;
    final paymentMethods =
        oldReport['paymentMethods'] as Map<String, dynamic>? ?? {};
    final newSummary = {
      'total_revenue': totalSales.toDouble(),
      'total_orders': totalOrders,
      'payment_methods': {
        'cash': paymentMethods['cash'] ?? 0.0,
        'tpe': paymentMethods['tpe'] ?? 0.0,
        'en_compte': paymentMethods['en_compte'] ?? 0.0,
        'other': paymentMethods['other'] ?? (paymentMethods['unknown'] ?? 0.0),
      },
      'order_types': {'onsite': 0, 'pickup': 0, 'delivery': 0},
      'channels': {
        'pos': totalSales.toDouble(),
        'api': 0.0,
        'web': 0.0,
        'kiosk': 0.0,
      },
      'staff_breakdown': [],
      'delivery_breakdown': [],
    };
    return {
      'date': oldReport['sessionEnd']?.toString().split('T')[0] ?? '2026-01-01',
      'staff_name': oldReport['staffName']?.toString() ?? 'Inconnu',
      'summary': newSummary,
    };
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _showAllReports = false;
      });
      _loadReportsByDateRange();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _showAllReports = false;
      });
      _loadReportsByDateRange();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _showAllReports = true;
    });
    _loadAllReports();
  }

  DateTime _selectedReportDate() {
    if (_startDate != null) {
      return _startDate!;
    }
    if (_endDate != null) {
      return _endDate!;
    }
    return DateTime.now();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
  }

  Future<void> _generateAndSaveDailyReport() async {
    setState(() => _loading = true);
    try {
      final authController = Get.find<AuthController>();
      final staffId = authController.currentUser?.id ?? 0;
      final staffName = authController.currentUser?.name ?? 'Admin';
      final reportDate = _selectedReportDate();
      final reportData = await DailyReportService.generateDailyReport(
        date: reportDate,
        staffId: staffId,
        staffName: staffName,
        openedAt: null,
        closedAt: null,
      );

      final dateKey = _formatDateKey(reportDate);
      final existingReport = await DatabaseService.db.cashRegisterStates
          .filter()
          .dateEqualTo(dateKey)
          .findFirst();

      final report = existingReport ?? CashRegisterState()
        ..date = dateKey;
      report.closingReport = jsonEncode(reportData);
      report.isOpen = true;
      report.openedAt = reportDate;
      report.openedByStaffId = staffId;
      report.openedByStaffName = staffName;
      report.closedAt = null;
      report.closedByStaffId = null;
      report.closedByStaffName = null;

      await DatabaseService.db.writeTxn(() async {
        await DatabaseService.db.cashRegisterStates.put(report);
      });

      Get.snackbar(
        'Rapport enregistré',
        'Le rapport du $dateKey a été généré et enregistré.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _loadAllReports();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer ou d\'enregistrer le rapport : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewDetailedReport(Map<String, dynamic> report) {
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(Get.context!).size.width * 0.9,
          height: MediaQuery.of(Get.context!).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // ── En-tête ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Rapport Journalier Détaillé',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // ── Contenu scrollable ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Color(0xFF1A237E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              report['date']?.toString() ?? 'Date inconnue',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A237E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Staff',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6D7885),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    report['staff_name']?.toString() ??
                                        'Inconnu',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Commandes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6D7885),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(summary['total_orders'] as int? ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CA total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6D7885),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(summary['total_revenue'] as num? ?? 0).toDouble().toStringAsFixed(2)} Dhs',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Résumé financier
                      _buildDialogSection(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Résumé Financier',
                        color: const Color(0xFF1A237E),
                        children: [
                          _buildInfoRow(
                            'Chiffre d\'affaires',
                            '${(summary['total_revenue'] as num? ?? 0).toDouble().toStringAsFixed(2)} Dhs',
                            highlight: true,
                          ),
                          _buildInfoRow(
                            'Nombre de commandes',
                            (summary['total_orders'] as int? ?? 0).toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._buildOrderTypesSection(summary),
                      ..._buildChannelsSection(summary),
                      ..._buildPaymentMethodsSection(summary),
                      ..._buildStaffBreakdownSection(summary),
                      ..._buildDeliveryBreakdownSection(summary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers visuels pour le dialog ──────────────────────────────────────

  Widget _buildDialogSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Sections du dialog (logique identique, style amélioré)
  // ─────────────────────────────────────────────────────────────

  List<Widget> _buildOrderTypesSection(Map<String, dynamic> summary) {
    final orderTypesData =
        summary['order_types'] as Map<String, dynamic>? ?? {};
    Map<String, int> orderTypes = {
      'onsite': (orderTypesData['onsite'] as num?)?.toInt() ?? 0,
      'pickup': (orderTypesData['pickup'] as num?)?.toInt() ?? 0,
      'delivery': (orderTypesData['delivery'] as num?)?.toInt() ?? 0,
    };
    final hasData = orderTypes.values.any((v) => v > 0);

    return [
      _buildDialogSection(
        icon: Icons.restaurant_rounded,
        title: 'Répartition par Type de Commande',
        color: const Color(0xFF00897B),
        children: hasData
            ? [
                _buildInfoRow('Sur place', orderTypes['onsite'].toString()),
                _buildInfoRow('À emporter', orderTypes['pickup'].toString()),
                _buildInfoRow('Livraison', orderTypes['delivery'].toString()),
              ]
            : [
                const Text(
                  'Aucune donnée sur les types de commande',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildChannelsSection(Map<String, dynamic> summary) {
    final channelsData = summary['channels'] as Map<String, dynamic>? ?? {};
    Map<String, double> channels = {
      'pos': (channelsData['pos'] as num?)?.toDouble() ?? 0.0,
      'api': (channelsData['api'] as num?)?.toDouble() ?? 0.0,
      'web': (channelsData['web'] as num?)?.toDouble() ?? 0.0,
      'kiosk': (channelsData['kiosk'] as num?)?.toDouble() ?? 0.0,
    };
    final hasData = channels.values.any((v) => v > 0);

    return [
      _buildDialogSection(
        icon: Icons.device_hub_rounded,
        title: 'Répartition par Canal',
        color: const Color(0xFF6A1B9A),
        children: hasData
            ? [
                _buildInfoRow(
                  'POS',
                  '${channels['pos']!.toStringAsFixed(2)} Dhs',
                ),
                _buildInfoRow(
                  'API',
                  '${channels['api']!.toStringAsFixed(2)} Dhs',
                ),
                _buildInfoRow(
                  'Web',
                  '${channels['web']!.toStringAsFixed(2)} Dhs',
                ),
                _buildInfoRow(
                  'Kiosk',
                  '${channels['kiosk']!.toStringAsFixed(2)} Dhs',
                ),
              ]
            : [
                const Text(
                  'Aucune donnée sur les canaux',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPaymentMethodsSection(Map<String, dynamic> summary) {
    final pmData = summary['payment_methods'] as Map<String, dynamic>? ?? {};
    final visible = pmData.entries
        .where((e) => ((e.value as num?)?.toDouble() ?? 0.0) > 0.0)
        .toList();

    return [
      _buildDialogSection(
        icon: Icons.payments_rounded,
        title: 'Méthodes de Paiement',
        color: const Color(0xFFE65100),
        children: visible.isNotEmpty
            ? visible
                .map((e) => _buildInfoRow(
                      paymentMethodLabel(e.key.toString()),
                      '${(e.value as num).toDouble().toStringAsFixed(2)} Dhs',
                    ))
                .toList()
            : [
                const Text(
                  'Aucune donnée de paiement disponible',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildStaffBreakdownSection(Map<String, dynamic> summary) {
    final staffBreakdown = summary['staff_breakdown'] as List? ?? [];

    final children = <Widget>[];
    if (staffBreakdown.isEmpty) {
      children.add(
        const Text(
          'Aucun serveur trouvé',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    } else {
      for (final s in staffBreakdown) {
        if (s is Map<String, dynamic>) {
          final pm = s['payment_methods'] as Map<String, dynamic>? ?? {};
          final visiblePm = pm.entries
              .where((e) => ((e.value as num?)?.toDouble() ?? 0.0) > 0.0)
              .toList();
          final discounts = (s['discounts'] as num?)?.toDouble() ?? 0.0;
          final offeredQty = s['offered_quantity'] as int? ?? 0;
          final offeredValue = (s['offered_value'] as num?)?.toDouble() ?? 0.0;
          final compte = (s['compte_rendu'] as num?)?.toDouble() ?? ((s['total_revenue'] as num?)?.toDouble() ?? 0.0) - (discounts + offeredValue);
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s['staff_name'] != null && s['staff_name'].toString().isNotEmpty
                            ? 'Serveur ${s['staff_name']}'
                            : 'Serveur #${s['staff_id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow('Commandes', '${s['orders_count']}'),
                  _buildInfoRow(
                    'CA',
                    '${(s['total_revenue'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} Dhs',
                  ),
                  if (visiblePm.isNotEmpty) ...visiblePm.map((e) => _buildInfoRow(
                        paymentMethodLabel(e.key.toString()),
                        '${(e.value as num).toDouble().toStringAsFixed(2)} Dhs',
                      )),
                  if (discounts > 0) _buildInfoRow('Remises', '-${discounts.toStringAsFixed(2)} Dhs'),
                  if (offeredQty > 0) _buildInfoRow('Produits offerts', '$offeredQty'),
                  if (offeredValue > 0) _buildInfoRow('Valeur offerts', '${offeredValue.toStringAsFixed(2)} Dhs'),
                  _buildInfoRow('Compte rendu', '${compte.toStringAsFixed(2)} Dhs'),
                ],
              ),
            ),
          );
        }
      }
    }

    return [
      _buildDialogSection(
        icon: Icons.people_alt_rounded,
        title: 'Statistiques par Serveur',
        color: const Color(0xFF1A237E),
        children: children,
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildDeliveryBreakdownSection(Map<String, dynamic> summary) {
    final deliveryBreakdown = summary['delivery_breakdown'] as List? ?? [];

    final children = <Widget>[];
    if (deliveryBreakdown.isEmpty) {
      children.add(
        const Text(
          'Aucune livraison trouvée',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    } else {
      for (final d in deliveryBreakdown) {
        if (d is Map<String, dynamic>) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00838F).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00838F).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining_rounded,
                        size: 14,
                        color: Color(0xFF00838F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d['delivery_staff_name'] != null && d['delivery_staff_name'].toString().isNotEmpty
                            ? 'Livreur ${d['delivery_staff_name']}'
                            : 'Livreur #${d['delivery_staff_id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow('Livraisons', '${d['delivery_count']}'),
                  _buildInfoRow(
                    'CA',
                    '${(d['delivery_revenue'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} Dhs',
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return [
      _buildDialogSection(
        icon: Icons.delivery_dining_rounded,
        title: 'Statistiques par Livreur',
        color: const Color(0xFF00838F),
        children: children,
      ),
    ];
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? const Color(0xFF1A237E) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD PRINCIPAL
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Rapports Journaliers',
      activeRoute: '/daily-reports',
      child: Column(
        children: [
          // ── Barre de filtre ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_alt_rounded,
                        size: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Filtrer par période', style: SushiTypo.h4),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Date début
                    Expanded(
                      child: _buildDateButton(
                        label: _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Date début',
                        icon: Icons.calendar_month_rounded,
                        active: _startDate != null,
                        onTap: _selectStartDate,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    // Date fin
                    Expanded(
                      child: _buildDateButton(
                        label: _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Date fin',
                        icon: Icons.calendar_month_rounded,
                        active: _endDate != null,
                        onTap: _selectEndDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Générer'),
                        onPressed: _generateAndSaveDailyReport,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton reset
                    Tooltip(
                      message: 'Tout afficher',
                      child: InkWell(
                        onTap: _clearDateFilter,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _showAllReports
                                ? const Color(0xFF1A237E)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _showAllReports
                                  ? const Color(0xFF1A237E)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: _showAllReports
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Compteur de résultats ────────────────────────────────
          if (!_loading && _reports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_reports.length} rapport${_reports.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Liste ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A237E),
                      strokeWidth: 2.5,
                    ),
                  )
                : _reports.isEmpty
                ? _buildEmptyState()
                : _buildReportsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1A237E).withOpacity(0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF1A237E).withOpacity(0.35)
                : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? const Color(0xFF1A237E) : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? const Color(0xFF1A237E)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 52,
              color: const Color(0xFF1A237E).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text('Aucun rapport trouvé', style: SushiTypo.h3),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _showAllReports
                  ? 'Aucun rapport n\'a encore été généré.'
                  : 'Aucun rapport trouvé pour la période sélectionnée.',
              style: SushiTypo.bodyMd.copyWith(color: SushiColors.inkMid),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final reportData = _parseReportData(report.closingReport);
        if (reportData == null) return const SizedBox.shrink();

        final summary = reportData['summary'] as Map<String, dynamic>? ?? {};
        final totalRevenue =
            (summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
        final totalOrders = summary['total_orders'] as int? ?? 0;
        final dateStr = reportData['date'] as String? ?? 'Date inconnue';
        final staffName = reportData['staff_name'] as String?;
        final isToday = report.isOpen == true;
        final canDeleteReport =
            Get.find<AuthController>().canDeleteReports && report.id > 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Barre colorée latérale
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isToday
                            ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                            : [
                                const Color(0xFF1A237E),
                                const Color(0xFF3949AB),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Contenu
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // Icône
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF43A047).withOpacity(0.1)
                                  : const Color(0xFF1A237E).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isToday
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.receipt_long_rounded,
                              size: 22,
                              color: isToday
                                  ? const Color(0xFF43A047)
                                  : const Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Textes
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Rapport du $dateStr',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF43A047,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'EN COURS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF43A047),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildChip(
                                      Icons.monetization_on_outlined,
                                      '${totalRevenue.toStringAsFixed(2)} Dhs',
                                      const Color(0xFF1A237E),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildChip(
                                      Icons.shopping_bag_outlined,
                                      '$totalOrders cmd',
                                      const Color(0xFF00897B),
                                    ),
                                  ],
                                ),
                                if (staffName != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        staffName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Boutons d'action
                          Row(
                            children: [
                              // Bouton impression
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF43A047,
                                  ).withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.print_rounded,
                                    size: 18,
                                    color: Color(0xFF43A047),
                                  ),
                                  onPressed: () =>
                                      _printDailyReport(reportData),
                                  tooltip: 'Imprimer le rapport',
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Bouton détail
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                    color: Color(0xFF1A237E),
                                  ),
                                  onPressed: () =>
                                      _viewDetailedReport(reportData),
                                  tooltip: 'Voir le détail',
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              if (canDeleteReport) const SizedBox(width: 4),
                              if (canDeleteReport)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5252).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Color(0xFFFF5252),
                                    ),
                                    onPressed: () => _confirmDeleteReport(report),
                                    tooltip: 'Supprimer le rapport',
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteReport(CashRegisterState report) async {
    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rapport'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce rapport journalier ? Cette action est réservée aux admins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await DatabaseService.db.writeTxn(() async {
        await DatabaseService.db.cashRegisterStates.delete(report.id);
      });
      Get.snackbar(
        'Rapport supprimé',
        'Le rapport a été supprimé avec succès.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _loadAllReports();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le rapport : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _printDailyReport(Map<String, dynamic> reportData) async {
    final directPrinted = await EscPosPrinterService.instance
        .tryPrintDailyReport(reportData);
    if (directPrinted) {
      Get.snackbar(
        'Succès',
        'Rapport journalier envoyé directement à l\'imprimante',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
      );
      return;
    }

    await _printOrPreview(
      builder: (format) => buildDailyReportPdf(reportData),
      fallbackTitle: 'Rapport journalier (aperçu)',
      onFail: null,
    );
  }

  Future<void> _printOrPreview({
    required Future<Uint8List> Function(PdfPageFormat format) builder,
    required String fallbackTitle,
    Future<void> Function()? onFail,
  }) async {
    Future<Uint8List> safeBuilder(PdfPageFormat format) =>
        _safePdf(builder, format);
    if (!mounted) return;
    try {
      if (Platform.isMacOS) {
        await _showTicketPreview(safeBuilder, title: fallbackTitle);
        return;
      }
      try {
        await Printing.layoutPdf(
          onLayout: (format) => safeBuilder(format),
        ).timeout(const Duration(seconds: 6));
        return;
      } on Exception catch (e) {
        debugPrint('Printing.layoutPdf error/timeout: $e');
      } catch (e, st) {
        debugPrint('Printing.layoutPdf error: $e\n$st');
      }
      await _showTicketPreview(safeBuilder, title: fallbackTitle);
    } catch (e, st) {
      debugPrint('Print preview error: $e\n$st');
      if (onFail != null) {
        await onFail();
        return;
      }
      if (!mounted) return;
      await _showTicketPreview(
        (format) => _fallbackErrorPdf('Impossible d\'afficher le rapport : $e'),
        title: fallbackTitle,
      );
    }
  }

  Future<Uint8List> _safePdf(
    Future<Uint8List> Function(PdfPageFormat format) builder,
    PdfPageFormat format,
  ) async {
    try {
      return await builder(format);
    } catch (e) {
      return _fallbackErrorPdf('Erreur: $e', format: format);
    }
  }

  Future<Uint8List> _fallbackErrorPdf(
    String message, {
    PdfPageFormat format = PdfPageFormat.roll80,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rapport non imprimé',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(message, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _showTicketPreview(
    Future<Uint8List> Function(PdfPageFormat format) builder, {
    required String title,
  }) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () async {
                  try {
                    if (Platform.isMacOS) {
                      final bytes = await builder(PdfPageFormat.roll80);
                      final tmp = Directory.systemTemp;
                      final file = File('${tmp.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
                      await file.writeAsBytes(bytes);
                      try {
                        await Process.run('open', [file.path]);
                      } catch (_) {}
                      return;
                    }
                    await Printing.layoutPdf(
                      onLayout: (format) => builder(format),
                    ).timeout(const Duration(seconds: 6));
                  } catch (e) {
                    Get.snackbar(
                      'Erreur d\'impression',
                      'Impossible d\'imprimer: $e',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
            ],
          ),
          body: PdfPreview(build: builder, maxPageWidth: 700),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
