// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../services/database_service.dart';
import '../models/pos_order.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_card_kit.dart';
import '../widgets/app_back_button.dart';
import '../widgets/pos_ui.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg      = Color(0xFFF4F5F7);
const _kCardBg  = Colors.white;
const _kDivider = Color(0xFFECECF0);
const _kRadius  = 16.0;

// Helper: détecte si un channel est considéré comme 'remote' (API / Web / Kiosk)
bool _isRemoteChannelLocal(String rawChannel) {
  final channel = rawChannel.trim().toLowerCase();
  switch (channel) {
    case 'api':
    case 'web':
    case 'website':
    case 'site':
    case 'online':
    case 'mobile':
    case 'mobile_app':
    case 'app':
    case 'android':
    case 'ios':
    case 'kiosk':
    case 'borne':
      return true;
    default:
      return false;
  }
}

Future<int> _getPendingRemoteOrdersCount(PosController pos) async {
  try {
    // Ensure DB initialized (no-op if already initialized)
    await DatabaseService.init();
  } catch (_) {}

  try {
    final all = await DatabaseService.getPosOrders();
    final restId = pos.restaurantId;
    final count = all.where((o) {
      final channel = (o.channel ?? 'pos').trim();
      if (!_isRemoteChannelLocal(channel)) return false;
      final status = (o.status ?? 'pending').trim().toLowerCase();
      if (status != 'pending') return false;
      if (restId != null && (o.restaurantId ?? 0) != restId) return false;
      return true;
    }).length;
    return count;
  } catch (e) {
    return 0;
  }
}

class PosStaffMenuScreen extends StatelessWidget {
  const PosStaffMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    // ── Locked guard (logic unchanged) ────────────────────────────────────
    if (pos.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != '/pos') Get.offAllNamed('/pos');
      });
      return POSPageScaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(pos, locked: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return POSPageScaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(pos, locked: false),
      body: GetBuilder<PosController>(
        builder: (_) => POSAdaptiveLayout(
          squareBuilder: (context, viewport) =>
              _buildContent(pos, viewport, isSquare: true),
          wideBuilder: (context, viewport) =>
              _buildContent(pos, viewport, isSquare: false),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(PosController pos, {required bool locked}) {
    return AppBar(
      title: const Text(
        'Menu Serveur',
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: SushiColors.ink,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: _kCardBg,
      foregroundColor: SushiColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kDivider),
      ),
      leading: AppBackButton(
        alwaysVisible: true,
        iconColor: SushiColors.red,
        onPressed: () {
          pos.lock();
          Get.offAllNamed('/pos');
        },
      ),
      actions: locked
          ? null
          : [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: SushiColors.red,
                    backgroundColor: SushiColors.redPale,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                  icon: const Icon(Icons.lock_outline, size: 15),
                  label: const Text('Verrouiller'),
                ),
              ),
            ],
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(
    PosController pos,
    POSViewport viewport, {
    required bool isSquare,
  }) {
    final gap = viewport.compactPadding + 4;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSquare ? 760 : 1140),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: gap + 4,
            vertical: gap + 8,
          ),
          children: [
            // ── Staff header card ──────────────────────────────────────────
            _buildHeaderCard(pos),
            SizedBox(height: gap + 8),

            // ── Section label ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: SushiColors.red,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Actions disponibles',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: SushiColors.inkMid,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu cards grid ────────────────────────────────────────────
            AppWrapGrid(
              minChildWidth: isSquare ? 220 : 260,
              maxChildWidth: isSquare ? 720 : 340,
              spacing: gap,
              runSpacing: gap,
              maxColumns: isSquare ? 1 : 3,
              children: [
                _MenuActionCard(
                  icon: Icons.point_of_sale_outlined,
                  title: 'Nouvelle Commande',
                  description:
                      'Créer une commande sur place, emporter ou livraison.',
                  emojiIcon: Icons.local_dining_outlined,
                  emojiLabel: 'POS',
                  accentColor: SushiColors.red,
                  onTap: () => Get.toNamed('/pos-choice'),
                ),
                _MenuActionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Mes Commandes',
                  description:
                      'Consulter, éditer et encaisser les commandes du jour.',
                  emojiIcon: Icons.receipt_long_outlined,
                  emojiLabel: 'Jour',
                  accentColor: const Color(0xFF7C3AED),
                  onTap: () {
                    pos.setOrdersFilter('all');
                    pos.setOrdersChannelFilter('all');
                    pos.loadOrdersToday();
                    Get.toNamed('/pos-orders');
                  },
                ),
                _MenuActionCard(
                  icon: Icons.check_circle_outline,
                  title: 'Mes Commandes Payées',
                  description:
                      'Consulter l\'historique des commandes déjà payées.',
                  emojiIcon: Icons.check_circle_outline,
                  emojiLabel: '✓',
                  accentColor: SushiColors.green,
                  onTap: () {
                    pos.setOrdersFilter('all');
                    pos.setOrdersChannelFilter('all');
                    pos.loadOrdersToday();
                    Get.toNamed('/pos-paid-orders');
                  },
                ),
                _MenuActionCard(
                  icon: Icons.payments_outlined,
                  title: 'Mes Paiements',
                  description:
                      'Voir les totaux des paiements par type (TPE, Cash, En compte).',
                  emojiIcon: Icons.account_balance_wallet_outlined,
                  emojiLabel: 'dh',
                  accentColor: SushiColors.green,
                  onTap: () => Get.toNamed('/pos-payments'),
                ),
                _MenuActionCard(
                  icon: Icons.table_bar_outlined,
                  title: 'Mes Tables',
                  description:
                      'Gérer les tables : consulter, libérer et encaisser.',
                  emojiIcon: Icons.meeting_room_outlined,
                  emojiLabel: 'Tables',
                  accentColor: const Color(0xFFE67E22),
                  onTap: () {
                    pos.loadTables();
                    Get.toNamed('/pos-tables');
                  },
                ),
                // Remote orders card: compute pending remote orders count
                FutureBuilder<int>(
                  future: _getPendingRemoteOrdersCount(pos),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    final highlight = count > 0;
                    return _MenuActionCard(
                      icon: Icons.phone_iphone_outlined,
                      title: 'API / Web',
                      description: 'Traiter les commandes reçues en ligne.',
                      emojiIcon: Icons.wifi_tethering_outlined,
                      emojiLabel: 'Remote',
                      accentColor: highlight ? Colors.amber : SushiColors.teal,
                      badgeCount: count > 0 ? count : null,
                      highlight: highlight,
                      onTap: () {
                        pos.setOrdersFilter('all');
                        pos.setOrdersChannelFilter('remote');
                        pos.loadOrdersToday();
                        Get.toNamed('/pos-orders');
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Card ───────────────────────────────────────────────────────────

  Widget _buildHeaderCard(PosController pos) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kDivider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SushiColors.red.withAlpha(20),
                  SushiColors.redDark.withAlpha(35),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SushiColors.red.withAlpha(50),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 24,
              color: SushiColors.red,
            ),
          ),
          const SizedBox(width: 14),

          // ── Staff info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos.activeStaff?.name ?? 'Serveur',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SushiColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _infoBadge(
                      Icons.storefront_outlined,
                      pos.restaurantLabel,
                      const Color(0xFF7C3AED),
                    ),
                    _infoBadge(
                      Icons.today_outlined,
                      DateTime.now().toString().split(' ').first,
                      SushiColors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status dot ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: SushiColors.green.withAlpha(18),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: SushiColors.green.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: SushiColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Connecté',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SushiColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Action Card ──────────────────────────────────────────────────────────

class _MenuActionCard extends StatefulWidget {
  const _MenuActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.emojiIcon,
    required this.emojiLabel,
    required this.accentColor,
    required this.onTap,
    this.badgeCount,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final IconData emojiIcon;
  final String emojiLabel;
  final Color accentColor;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool highlight;

  @override
  State<_MenuActionCard> createState() => _MenuActionCardState();
}

class _MenuActionCardState extends State<_MenuActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.highlight ? Colors.amber : widget.accentColor;
    final color = baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        scale: _hovered ? 1.025 : 1,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _hovered ? color.withAlpha(10) : (widget.highlight ? const Color(0xFFFFF7E0) : _kCardBg),
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(
                    color: _hovered ? color.withAlpha(120) : (widget.highlight ? Colors.amber.withAlpha(120) : _kDivider),
                    width: _hovered ? 1.8 : 1,
                  ),
                  boxShadow: [
                    if (_hovered)
                      BoxShadow(
                        color: color.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    else
                      const BoxShadow(
                        color: Color(0x09000000),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top row: icon badge + arrow ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _hovered
                            ? color.withAlpha(22)
                            : color.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hovered
                              ? color.withAlpha(80)
                              : color.withAlpha(30),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(widget.icon, size: 24, color: color),
                    ),

                    // Arrow indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _hovered ? color : const Color(0xFFF0F0F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: _hovered ? Colors.white : SushiColors.inkMid,
                      ),
                    ),
                  ],
                ),
                // Badge overlay (top-right)
                if (widget.badgeCount != null && widget.badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'Nouvelles +${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _hovered ? color : SushiColors.ink,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // ── Description ───────────────────────────────────────────
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: SushiColors.inkMid,
                    height: 1.45,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // ── Bottom accent strip + label ───────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(14),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: color.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.emojiIcon, color: color, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            widget.emojiLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom color bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: _hovered ? 48 : 24,
                      decoration: BoxDecoration(
                        color: color.withAlpha(_hovered ? 200 : 60),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    ));
  }
}