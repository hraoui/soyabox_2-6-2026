import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/pos_controller.dart';
import '../theme/sushi_design.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import '../utils/payment_method_utils.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/pos_ui.dart';

class PosStaffPaymentsScreen extends StatefulWidget {
  const PosStaffPaymentsScreen({super.key});

  @override
  State<PosStaffPaymentsScreen> createState() => _PosStaffPaymentsScreenState();
}

class _PosStaffPaymentsScreenState extends State<PosStaffPaymentsScreen> {
  DateTime _selectedDate = DateTime.now();
  double _totalCash = 0.0;
  double _totalTpe = 0.0;
  double _totalEnCompte = 0.0;
  double _totalOther = 0.0;
  double _grandTotal = 0.0;
  int _totalOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentStats();
  }

  Future<void> _loadPaymentStats() async {
    setState(() => _isLoading = true);
    try {
      final pos = Get.find<PosController>();
      final orders = await DatabaseService.getPosOrdersByStaffAndDate(
        pos.activeStaffId ?? 0,
        _selectedDate,
      );

        final paidOrders = orders
          .where((o) =>
            (o.paymentStatus == 'paid' || o.paymentStatus == 'partially_paid') &&
            o.status != 'cancelled')
          .toList();

      double cash = 0.0;
      double tpe = 0.0;
      double enCompte = 0.0;
      double other = 0.0;

      for (final order in paidOrders) {
        // ✅ Gérer les paiements split ou partiels enregistrés via paymentSplit
        if (order.paymentSplit != null && order.paymentSplit!.isNotEmpty) {
          try {
            final List<dynamic> payments = jsonDecode(order.paymentSplit!);
            for (final payment in payments) {
              final method = payment['payment_method'] as String?;
              final amount = (payment['amount'] as num).toDouble();

              if (isCashPaymentMethod(method)) {
                cash += amount;
              } else if (isTpePaymentMethod(method)) {
                tpe += amount;
              } else if (isEnComptePaymentMethod(method)) {
                enCompte += amount;
              } else {
                other += amount;
              }
            }
          } catch (e) {
            appLogger.e('❌ Erreur parsing paymentSplit: $e');
            other += order.totalPrice;
          }
        } else if (isCashPaymentMethod(order.paymentMethod)) {
          cash += order.totalPrice;
        } else if (isTpePaymentMethod(order.paymentMethod)) {
          tpe += order.totalPrice;
        } else if (isEnComptePaymentMethod(order.paymentMethod)) {
          enCompte += order.totalPrice;
        } else {
          other += order.totalPrice;
        }
      }

      setState(() {
        _totalCash = cash;
        _totalTpe = tpe;
        _totalEnCompte = enCompte;
        _totalOther = other;
        _grandTotal = cash + tpe + enCompte + other;
        _totalOrders = paidOrders.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showPOSSnack(
          context,
          'Erreur: ${e.toString()}',
          title: 'Erreur',
          type: POSSnackType.error,
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SushiColors.red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: SushiColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadPaymentStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: const Text(
          'Mes Paiements',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: SushiColors.ink,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          alwaysVisible: true,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
              return;
            }
            Get.offAllNamed('/pos-menu');
          },
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: SushiColors.red,
              backgroundColor: SushiColors.redPale,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              pos.lock();
              Get.offAllNamed('/pos');
            },
            icon: const Icon(Icons.lock_outline, size: 14),
            label: const Text('Verrouiller'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GetBuilder<PosController>(
        builder: (_) {
          return POSAdaptiveLayout(
            squareBuilder: (context, viewport) =>
                _buildContent(pos, viewport, isSquare: true),
            wideBuilder: (context, viewport) =>
                _buildContent(pos, viewport, isSquare: false),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    PosController pos,
    POSViewport viewport, {
    required bool isSquare,
  }) {
    final gap = viewport.compactPadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSquare ? 760 : 900),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: gap + 6, vertical: gap + 4),
          children: [
            // Header with date selector
            _headerCard(pos, viewport),
            SizedBox(height: gap + 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  // Summary cards
                  _summaryCards(viewport, isSquare: isSquare),
                  SizedBox(height: gap + 8),

                  // Detailed breakdown
                  _detailedBreakdown(viewport),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(PosController pos, POSViewport viewport) {
    return Center(
      child: AppSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: SushiSpace.sm,
          runSpacing: SushiSpace.xs,
          children: [
            _badge(Icons.person_outline, pos.activeStaff?.name ?? 'Serveur -'),
            _badge(Icons.storefront_outlined, pos.restaurantLabel),
            _badge(
              Icons.calendar_today_outlined,
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SushiSpace.sm,
          vertical: SushiSpace.xs,
        ),
        decoration: SushiDeco.badge(bg: SushiColors.redPale),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: SushiColors.red),
            const SizedBox(width: SushiSpace.xs),
            Text(text, style: SushiTypo.tag.copyWith(color: SushiColors.ink)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 14, color: SushiColors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCards(POSViewport viewport, {required bool isSquare}) {
    return AppWrapGrid(
      minChildWidth: isSquare ? 280 : 200,
      maxChildWidth: isSquare ? 720 : 280,
      spacing: 8,
      runSpacing: 8,
      maxColumns: isSquare ? 1 : 4,
      children: [
        _StatCard(
          title: 'Total Général',
          amount: _grandTotal,
          icon: Icons.account_balance_wallet_outlined,
          color: SushiColors.ink,
          bgColor: SushiColors.surface,
          subtitle: '$_totalOrders commandes',
        ),
        _StatCard(
          title: 'Espèces',
          amount: _totalCash,
          icon: Icons.money_outlined,
          color: SushiColors.green,
          bgColor: SushiColors.greenPale,
          subtitle: 'Cash',
        ),
        _StatCard(
          title: 'TPE / CB',
          amount: _totalTpe,
          icon: Icons.credit_card_outlined,
          color: SushiColors.teal,
          bgColor: SushiColors.bluePale,
          subtitle: 'Carte bancaire',
        ),
        _StatCard(
          title: 'En compte',
          amount: _totalEnCompte,
          icon: Icons.account_balance_wallet_outlined,
          color: SushiColors.orange,
          bgColor: SushiColors.orangePale,
          subtitle: 'Compte client',
        ),
      ],
    );
  }

  Widget _detailedBreakdown(POSViewport viewport) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline_outlined,
                size: 18,
                color: SushiColors.inkMid,
              ),
              const SizedBox(width: 8),
              Text(
                'Détail des paiements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SushiColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _breakdownRow('Total commandes payées', _grandTotal),
          const Divider(height: 24),
          _breakdownRow('Paiements en espèces', _totalCash, isPositive: true),
          _breakdownRow('Paiements par carte', _totalTpe, isPositive: true),
          _breakdownRow(
            'Paiements en compte',
            _totalEnCompte,
            isPositive: true,
          ),
          if (_totalOther > 0) ...[
            _breakdownRow('Autres paiements', _totalOther),
          ],
          const Divider(height: 24),
          _breakdownRow(
            'Nombre de commandes',
            _totalOrders.toDouble(),
            isCount: true,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SushiColors.redPale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SushiColors.red.withAlpha(51)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: SushiColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ces totaux représentent les commandes payées et non annulées pour la date sélectionnée.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: SushiColors.inkMid,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    String label,
    double amount, {
    bool isPositive = false,
    bool isCount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: SushiColors.inkMid),
            ),
          ),
          Text(
            isCount ? '${amount.toInt()}' : _formatMoney(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isPositive ? SushiColors.green : SushiColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(amount)} dh';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.subtitle,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SushiColors.inkMid,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: SushiColors.inkMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(amount)} dh';
  }
}
