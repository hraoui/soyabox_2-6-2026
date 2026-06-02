// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/table_plan_layout.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_table.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/pos_ui.dart';
import '../widgets/sushi_cta_button.dart';

class PosTablePlanScreen extends StatefulWidget {
  const PosTablePlanScreen({super.key});

  @override
  State<PosTablePlanScreen> createState() => _PosTablePlanScreenState();
}

class _PosTablePlanScreenState extends State<PosTablePlanScreen> {
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    final current = normalizeTableName(Get.find<PosController>().tableNumber);
    if (kTablePlanSlotsByNumber.containsKey(current)) {
      _selectedTable = current;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: const Color.fromARGB(255, 1, 0, 7),
      appBar: AppBar(
        title: const Text('Plan des Tables', style: SushiTypo.h4),
        leading: AppBackButton(
          alwaysVisible: true,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
              return;
            }
            Get.offAllNamed('/pos-choice');
          },
        ),
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SushiBgPainter(),
          POSAdaptiveLayout(
            squareBuilder: (context, viewport) =>
                _buildPlanContent(pos, viewport, isSquare: true),
            wideBuilder: (context, viewport) =>
                _buildPlanContent(pos, viewport, isSquare: false),
          ),
        ],
      ),
    ); // ← fermeture POSPageScaffold
  }

  Widget _buildPlanContent(
    PosController pos,
    POSViewport viewport, {
    required bool isSquare,
  }) {
    final outerPadding = viewport.compactPadding;
    final innerPadding = isSquare ? 8.0 : 10.0;

    return GetBuilder<PosController>(
      builder: (_) {
        if (pos.tables.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final mapped = <_MappedTable>[];
        final seenNumbers = <String>{};
        var outOfPlanCount = 0;

        for (final table in pos.tables) {
          final normalized = normalizeTableName(table.number);
          final slot = kTablePlanSlotsByNumber[normalized];
          if (slot == null || seenNumbers.contains(normalized)) {
            outOfPlanCount += 1;
            continue;
          }
          seenNumbers.add(normalized);
          mapped.add(_MappedTable(slot: slot, table: table));
        }

        mapped.sort((a, b) {
          final rowCmp = a.slot.row.compareTo(b.slot.row);
          if (rowCmp != 0) return rowCmp;
          return a.slot.col.compareTo(b.slot.col);
        });

        final activeSelection = _resolveSelection(
          mappedNumbers: seenNumbers,
          currentFromController: normalizeTableName(pos.tableNumber),
        );

        return Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Container(
            decoration: SushiDeco.card(),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    innerPadding,
                    innerPadding,
                    innerPadding,
                    6,
                  ),
                  child: _header(
                    pos: pos,
                    selectedTable: activeSelection,
                    canContinue: activeSelection != null,
                    outOfPlanCount: outOfPlanCount,
                  ),
                ),
                const Divider(height: 1, color: SushiColors.divider),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(innerPadding),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FloorGridPainter(
                                  gridColor: SushiColors.divider,
                                ),
                              ),
                            ),
                            ...mapped.map(
                              (entry) => _positionedTable(
                                constraints: constraints,
                                entry: entry,
                                isSelected:
                                    activeSelection ==
                                    normalizeTableName(entry.table.number),
                                onTap: () => _onTableTap(pos, entry.table),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _resolveSelection({
    required Set<String> mappedNumbers,
    required String currentFromController,
  }) {
    if (_selectedTable != null && mappedNumbers.contains(_selectedTable)) {
      return _selectedTable;
    }
    if (mappedNumbers.contains(currentFromController)) {
      _selectedTable = currentFromController;
      return currentFromController;
    }
    return null;
  }

  Widget _header({
    required PosController pos,
    required String? selectedTable,
    required bool canContinue,
    required int outOfPlanCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        final actionPanel = Wrap(
          spacing: SushiSpace.sm,
          runSpacing: SushiSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _legend(),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: SushiButtonStyle.secondary(),
                onPressed: canContinue
                    ? () {
                        if (selectedTable == null) return;
                        final slot = kTablePlanSlotsByNumber[selectedTable];
                        if (slot == null) return;
                        Get.find<PosController>().setTableNumber(
                          slot.tableNumber,
                        );
                        Get.toNamed('/pos-order');
                      }
                    : null,
                child: const Text('Suivant', style: SushiTypo.bodySm),
              ),
            ),
          ],
        );

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan des Tables', style: SushiTypo.h1),
            const SizedBox(height: SushiSpace.xs),
            Text(pos.restaurantLabel, style: SushiTypo.bodyMd),
            if (outOfPlanCount > 0) ...[
              const SizedBox(height: SushiSpace.xs),
              Text(
                'Tables hors plan: $outOfPlanCount',
                style: SushiTypo.caption.copyWith(color: SushiColors.inkMid),
              ),
            ],
          ],
        );

        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: SushiSpace.sm),
                  actionPanel,
                ],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  actionPanel,
                ],
              );
      },
    );
  }

  Widget _legend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendItem(color: SushiColors.green, label: 'Disponible'),
        SizedBox(width: SushiSpace.sm),
        _LegendItem(color: SushiColors.yellow, label: 'Réservée'),
        SizedBox(width: SushiSpace.sm),
        _LegendItem(color: SushiColors.red, label: 'Occupée'),
      ],
    );
  }

  Widget _positionedTable({
    required BoxConstraints constraints,
    required _MappedTable entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const colGap = 14.0;
    const rowGap = 16.0;

    final rawCellW =
        (constraints.maxWidth - ((kPlanCols - 1) * colGap)) / kPlanCols;
    final rawCellH =
        (constraints.maxHeight - ((kPlanRows - 1) * rowGap)) / kPlanRows;

    final tileW = rawCellW.clamp(62.0, 124.0).toDouble();
    final tileH = rawCellH.clamp(48.0, 90.0).toDouble();

    final left =
        (entry.slot.col * (rawCellW + colGap)) + ((rawCellW - tileW) / 2);
    final top =
        (entry.slot.row * (rawCellH + rowGap)) + ((rawCellH - tileH) / 2);

    final status = entry.table.status;
    final isFree = status == 'available' || status == 'free';
    final isReserved = status == 'reserved';

    return Positioned(
      left: left,
      top: top,
      width: tileW,
      height: tileH,
      child: _TableTile(
        table: entry.table,
        isFree: isFree,
        isReserved: isReserved,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _onTableTap(PosController pos, PosTable table) {
    final status = table.status;
    final isAvailable = status == 'available' || status == 'free';
    if (!isAvailable) {
      final message = status == 'reserved'
          ? 'Cette table est réservée'
          : 'Cette table est occupée';
      showPOSSnack(
        context,
        message,
        title: 'Table indisponible',
        type: status == 'reserved' ? POSSnackType.warning : POSSnackType.error,
        duration: const Duration(milliseconds: 2200),
      );
      return;
    }

    final normalized = normalizeTableName(table.number);
    setState(() => _selectedTable = normalized);
    pos.setTableNumber(table.number);
    Get.toNamed('/pos-order');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TableTile extends StatefulWidget {
  const _TableTile({
    required this.table,
    required this.isFree,
    required this.isReserved,
    required this.isSelected,
    required this.onTap,
  });

  final PosTable table;
  final bool isFree;
  final bool isReserved;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TableTile> createState() => _TableTileState();
}

class _TableTileState extends State<_TableTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSelected
        ? SushiColors.red
        : widget.isReserved
        ? SushiColors.yellow
        : widget.isFree
        ? SushiColors.green
        : SushiColors.red;
    final fill = accent.withOpacity(widget.isSelected ? 0.56 : 0.1);
    final borderColor = widget.isSelected ? accent : accent.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _hovered || widget.isSelected ? 1.02 : 1,
        child: Material(
          color: SushiColors.white,
          borderRadius: BorderRadius.circular(SushiRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(SushiRadius.xl),
            splashColor: SushiColors.redPale,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: SushiDeco.card(selected: widget.isSelected).copyWith(
                color: fill,
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final base = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final fontSize = (base * 0.38).clamp(14.0, 28.0).toDouble();
                  return Text(
                    widget.table.number,
                    style: SushiTypo.h2.copyWith(
                      color: accent,
                      fontSize: fontSize,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      decoration: SushiDeco.badge(bg: SushiColors.redPale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: SushiDeco.badge(bg: color),
          ),
          const SizedBox(width: SushiSpace.xs),
          Text(
            label,
            style: SushiTypo.caption.copyWith(color: SushiColors.ink),
          ),
        ],
      ),
    );
  }
}

class _MappedTable {
  const _MappedTable({required this.slot, required this.table});
  final TablePlanSlot slot;
  final PosTable table;
}

class _FloorGridPainter extends CustomPainter {
  _FloorGridPainter({required this.gridColor});

  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int col = 1; col < kPlanCols; col++) {
      final x = (size.width / kPlanCols) * col;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int row = 1; row < kPlanRows; row++) {
      final y = (size.height / kPlanRows) * row;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SushiBgPainter extends StatelessWidget {
  const _SushiBgPainter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 179, 127, 127),
            Color.fromARGB(255, 239, 5, 5),
            Color(0xFFFCF5FF),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _BgPatternPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BgPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFFE14141).withOpacity(0.07)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }

    final diamondPaint = Paint()
      ..color = const Color(0xFFE14141).withOpacity(0.055)
      ..style = PaintingStyle.fill;

    void drawDiamond(Offset center, double r) {
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * 0.55, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r * 0.55, center.dy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }

    const dSpacing = 84.0;
    for (double x = dSpacing; x < size.width; x += dSpacing) {
      for (double y = dSpacing; y < size.height; y += dSpacing) {
        drawDiamond(Offset(x, y), 7.0);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFFD0A0A0).withOpacity(0.06)
      ..strokeWidth = 0.8;

    const lineStep = 56.0;
    for (double d = -size.height; d < size.width + size.height; d += lineStep) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
