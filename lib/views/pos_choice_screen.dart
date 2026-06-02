import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/pos_ui.dart';

class PosChoiceScreen extends StatefulWidget {
  const PosChoiceScreen({super.key});

  @override
  State<PosChoiceScreen> createState() => _PosChoiceScreenState();
}

class _PosChoiceScreenState extends State<PosChoiceScreen> {
  String _type = 'on_site';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return POSPageScaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Type de commande',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: SushiColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: SushiColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFECECF0)),
        ),
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
          // ── Lock button — more refined pill shape ──
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: SushiColors.red,
                backgroundColor: SushiColors.redPale,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              onPressed: () {
                pos.lock();
                Get.offAllNamed('/pos');
              },
              icon: const Icon(Icons.lock_outline, size: 14),
              label: const Text('Verrouiller'),
            ),
          ),
        ],
      ),
      body: POSAdaptiveLayout(
        squareBuilder: (context, viewport) =>
            _buildContent(pos, viewport, isSquare: true),
        wideBuilder: (context, viewport) =>
            _buildContent(pos, viewport, isSquare: false),
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
        constraints: BoxConstraints(maxWidth: isSquare ? 720 : 960),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: gap + 10,
            vertical: gap + 16,
          ),
          children: [
            // ── Header block ──────────────────────────────
            _buildHeader(viewport),
            SizedBox(height: gap + 12),

            // ── Type cards ────────────────────────────────
            _buildTypeCards(isSquare: isSquare, gap: gap),
            SizedBox(height: gap + 16),

            // ── Continue button ───────────────────────────
            _buildContinueButton(pos),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(POSViewport viewport) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: SushiColors.redPale,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: SushiColors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir le type de commande',
                  style: TextStyle(
                    fontSize: viewport.sectionTitleSize,
                    fontWeight: FontWeight.w700,
                    color: SushiColors.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sélectionnez le canal de prise en charge avant de continuer.',
                  style: TextStyle(
                    fontSize: viewport.bodyFontSize,
                    color: SushiColors.inkMid,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Type Cards ────────────────────────────────────────────────────────────

  Widget _buildTypeCards({required bool isSquare, required double gap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isSquare
            ? constraints.maxWidth
            : ((constraints.maxWidth - (gap * 2)) / 3)
                  .clamp(180.0, 300.0)
                  .toDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _typeCard(
                value: 'on_site',
                icon: Icons.table_restaurant_outlined,
                label: 'Sur place',
                description: 'Service en salle avec numéro de table',
                accentColor: SushiColors.red,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _typeCard(
                value: 'pickup',
                icon: Icons.takeout_dining_outlined,
                label: 'À emporter',
                description: 'Commande préparée puis remise au client',
                accentColor: const Color(0xFFE67E22),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _typeCard(
                value: 'delivery',
                icon: Icons.local_shipping_outlined,
                label: 'Livraison',
                description: 'Commande expédiée à l\'adresse du client',
                accentColor: SushiColors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _typeCard({
    required String value,
    required IconData icon,
    required String label,
    required String description,
    required Color accentColor,
  }) {
    final selected = _type == value;

    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? accentColor.withAlpha(12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : const Color(0xFFECECF0),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accentColor.withAlpha(28)
                  : Colors.black.withAlpha(6),
              blurRadius: selected ? 16 : 8,
              spreadRadius: selected ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: icon + check badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withAlpha(28)
                        : const Color(0xFFF0F0F3),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? accentColor : SushiColors.inkMid,
                  ),
                ),
                // ── Selection indicator ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Container(
                          key: const ValueKey('check'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 15,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          key: const ValueKey('empty'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD0D0D8),
                              width: 2,
                            ),
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Label ──
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? accentColor : SushiColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),

            // ── Description ──
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: SushiColors.inkMid,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 14),

            // ── Bottom status strip ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: selected ? accentColor : const Color(0xFFECECF0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Continue Button ───────────────────────────────────────────────────────

  Widget _buildContinueButton(PosController pos) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _continue(pos),
        style: ElevatedButton.styleFrom(
          backgroundColor: SushiColors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: SushiColors.red.withAlpha(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 3;
          }),
          shadowColor: WidgetStatePropertyAll(SushiColors.red.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Continuer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Navigation logic (unchanged) ─────────────────────────────────────────

  void _continue(PosController pos) {
    pos.setFulfillmentType(_type);
    pos.setCustomerInfo(name: null, phone: null, address: null);

    if (_type == 'on_site') {
      Get.toNamed('/pos-tables');
    } else {
      Get.toNamed('/pos-order');
    }
  }
}