// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously
import 'dart:async';
import 'package:caisse_1/utils/order_item_grouping.dart';
import 'package:caisse_1/widgets/item_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:math' as math;
import '../utils/app_logger.dart';
import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/pos_controller.dart';
import '../controllers/delivery_controller.dart';
import '../data/app_constants.dart';
import '../models/product_model.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/customer.dart';
import '../models/order_delivery.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';
import '../utils/image_resolver_shared.dart';
import '../utils/image_resolver.dart';
import '../services/database_service.dart';
import '../services/order_sync_service.dart';
import '../services/image_cache_service.dart';
import '../services/app_settings_service.dart';
import '../services/esc_pos_printer_service.dart';
import '../utils/badge_code_utils.dart';
import '../utils/pos_ticket_printer.dart';
import '../utils/payment_method_utils.dart';
import '../utils/order_item_dedup.dart';
import '../widgets/app_back_button.dart';
import '../widgets/pos_ui.dart';
import '../widgets/sushi_cta_button.dart' hide SushiButtonStyle;

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.title});
  final String title;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _OrderPrintContext {
  const _OrderPrintContext({
    required this.order,
    required this.items,
    required this.staffName,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
  });

  final PosOrder order;
  final List<PosOrderItem> items;
  final String? staffName;
  final String? restaurantName;
  final String? restaurantAddress;
  final String? restaurantPhone;
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.imageBuilder,
    this.onLongPress,
  });

  final Product product;
  final VoidCallback onTap;
  final Widget Function(String? path) imageBuilder;
  final VoidCallback? onLongPress;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;
  double? _glovoPrice;

  @override
  void initState() {
    super.initState();
    _loadGlovoPrice();
  }

  Future<void> _loadGlovoPrice() async {
    final price = await DatabaseService.getProductPriceByType(
      widget.product.id,
      'glovo',
    );
    setState(() {
      _glovoPrice = price?.price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFFFFFFF).withAlpha(215),
            border: Border.all(
              color: _hovered ? SushiColors.red : const Color(0xFFE0E0E0),
              width: _hovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: _hovered ? 12 : 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: SushiColors.red.withAlpha(70),
              highlightColor: SushiColors.red.withAlpha(24),
              onLongPress: widget.onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.imageBuilder(product.image),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name.startsWith('[LOCAL] ')
                          ? product.name.substring(8)
                          : product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SushiColors.ink,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppSettingsService.instance.formatAmount(
                              product.price,
                            ),
                            style: const TextStyle(
                              color: SushiColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        _glovoPrice != null
                            ? Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [
                                        SushiColors.red.withAlpha(22),
                                        SushiColors.redLight.withAlpha(18),
                                      ],
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '+${AppSettingsService.instance.formatAmount(_glovoPrice!)} Glovo',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: SushiColors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: SushiColors.green.withAlpha(25),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Dispo',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: SushiColors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientSpinner extends StatefulWidget {
  const _GradientSpinner({required this.size, required this.strokeWidth});
  final double size;
  final double strokeWidth;

  @override
  State<_GradientSpinner> createState() => _GradientSpinnerState();
}

class _GradientSpinnerState extends State<_GradientSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SushiColors.red, SushiColors.redDark],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcIn,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.strokeWidth,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PulseSkeleton extends StatefulWidget {
  const _PulseSkeleton({required this.borderRadius});
  final double borderRadius;

  @override
  State<_PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<_PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final color = Color.lerp(
          const Color(0xFFE0E0E0).withAlpha(190),
          const Color(0xFF9E9E9E).withAlpha(245),
          t,
        );
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class _SushiPatternPainter extends CustomPainter {
  _SushiPatternPainter({required this.lineColor});
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (double y = 40; y < size.height; y += 110) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        final wave = math.sin((x / 60) + (y / 90)) * 5;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, linePaint);
    }
    final dotPaint = Paint()..color = lineColor.withAlpha(85);
    for (double x = 36; x < size.width; x += 140) {
      for (double y = 28; y < size.height; y += 140) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SushiPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _PosScreenState extends State<PosScreen> {
  final categoryController = Get.find<CategoryController>();
  final posController = Get.find<PosController>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final FocusNode _badgeListenerFocusNode = FocusNode(
    debugLabel: 'inline_pos_badge_listener',
  );
  Timer? _badgeCommitTimer;
  String _badgeBuffer = '';
  DateTime? _lastBadgeKeyAt;
  String _badgeStatus = 'Lecture badge active';
  bool _isBadgeUnlocking = false;
  bool _isSaving = false;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    posController.loadOrdersToday();
  }

  String _money(double amount) =>
      AppSettingsService.instance.formatAmount(amount);

  void _notify(
    String message, {
    String? title,
    POSSnackType type = POSSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    showPOSSnack(
      context,
      message,
      title: title,
      type: type,
      duration: duration,
    );
  }

  Future<void> _saveOrder(PosController pos) async {
    if (_isSaving || pos.isCreatingOrder) return;
    final wasEditing = pos.editingOrderId != null;
    final cartSnapshot = List<CartItem>.from(pos.cart);
    if (wasEditing && cartSnapshot.isEmpty) {
      _notify(
        'Aucun nouveau produit à enregistrer',
        title: 'Edition',
        type: POSSnackType.warning,
      );
      return;
    }

    _isSaving = true;
    try {
      if (!wasEditing &&
          (pos.fulfillmentType == 'pickup' ||
              pos.fulfillmentType == 'delivery')) {
        final customerConfirmed = await _showCustomerSelectionDialog(pos);
        if (!customerConfirmed) {
          _isSaving = false;
          return;
        }
      }
      if (pos.fulfillmentType == 'on_site' &&
          (pos.tableNumber == null || pos.tableNumber!.isEmpty)) {
        _isSaving = false;
        await _promptTableNumber(pos);
        if (pos.tableNumber == null || pos.tableNumber!.isEmpty) {
          return;
        }
      }
      final orderId = await pos.createOrder();
      if (orderId != null && pos.fulfillmentType == 'on_site') {
        final table = pos.tableNumber;
        if (table != null && table.isNotEmpty) {
          final auth = Get.isRegistered<AuthController>()
              ? Get.find<AuthController>()
              : null;
          final currentStaff = auth?.currentUser;
          final staffId = currentStaff?.id;
          try {
            await pos.markTableOccupied(table, requestingStaffId: staffId);
          } catch (e) {
            if (mounted) {
              _notify(
                'Table déjà assignée à un autre serveur: $e',
                title: 'Erreur',
                type: POSSnackType.error,
              );
            }
            return;
          }
        }
      }
      if (orderId != null) {
        setState(() => _lastOrderId = orderId);
        await _showPostOrderSuccessFlow(
          pos: pos,
          orderId: orderId,
          wasEditing: wasEditing,
          autoLock: true,
          beforeAutoLock: wasEditing
              ? () =>
                    _printEditedOrderAddedItemsByOrderId(orderId, cartSnapshot)
              : () => _printKitchenAndCustomerTicketsByOrderId(
                  orderId,
                  fallbackCartItems: cartSnapshot,
                ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _notify(
        'Erreur enregistrement/print : $e',
        title: 'Erreur',
        type: POSSnackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return POSPageScaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF212121),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: (_isSaving || _isNavigatingAway)
                ? null
                : () => _scheduleExitAfterAction(immediate: true),
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('Quitter'),
            style: TextButton.styleFrom(foregroundColor: SushiColors.red),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: GetBuilder<PosController>(
          builder: (pos) {
            if (pos.isLocked) {
              return _buildLockScreen(pos);
            }
            return GetBuilder<CategoryController>(
              builder: (category) {
                if (!category.isLoaded.value) {
                  return const Center(
                    child: _GradientSpinner(size: 38, strokeWidth: 3),
                  );
                }
                var selectedCategory = category.selectedCategory.value;
                if (selectedCategory == null &&
                    category.categories.isNotEmpty) {
                  selectedCategory = category.categories.first;
                }
                var products = selectedCategory != null
                    ? category.products
                    : <Product>[];
                return POSAdaptiveLayout(
                  squareBuilder: (context, viewport) => _buildSquareOrderLayout(
                    pos,
                    category,
                    products,
                    viewport,
                  ),
                  wideBuilder: (context, viewport) =>
                      _buildWideOrderLayout(pos, category, products, viewport),
                );
              },
            );
          },
        ),
      ),
    );
  }

  //wideorderlayout
  Widget _buildWideOrderLayout(
    PosController pos,
    CategoryController category,
    List<Product> products,
    POSViewport viewport,
  ) {
    final gap = viewport.compactPadding + 2;
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ COLONNE GAUCHE : Menu produits (~70% largeur)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _topMenu(
                  title: 'POS - ${pos.activeStaff?.name ?? 'Serveur'}',
                  subTitle:
                      '${DateTime.now().toString().split(' ')[0]} • ${_labelForFulfillment(pos.fulfillmentType)}',
                  action: _topRightStats(pos),
                ),
                _orderInfoBar(pos),
                SizedBox(height: gap),
                _buildCatalogToolbar(
                  pos,
                  category,
                  isSquare: false,
                  spacing: gap,
                ),
                SizedBox(height: gap),
                Expanded(
                  child: _buildProductGrid(
                    pos,
                    products,
                    isSquare: false,
                    spacing: gap,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: gap),
          // ✅ COLONNE DROITE : Panier (~30% largeur)
          Expanded(flex: 3, child: _buildCartPane(pos)),
        ],
      ),
    );
  }

  //squareorderlayout
  Widget _buildSquareOrderLayout(
    PosController pos,
    CategoryController category,
    List<Product> products,
    POSViewport viewport,
  ) {
    final gap = viewport.compactPadding + 2;
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Column(
        children: [
          _topMenu(
            title: 'POS - ${pos.activeStaff?.name ?? 'Serveur'}',
            subTitle:
                '${DateTime.now().toString().split(' ')[0]} • ${_labelForFulfillment(pos.fulfillmentType)}',
            action: _topRightStats(pos),
          ),
          _orderInfoBar(pos),
          SizedBox(height: gap),
          _buildCatalogToolbar(pos, category, isSquare: true, spacing: gap),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              // ✅ Changed from Column to Row for side-by-side
              children: [
                // ✅ COLONNE GAUCHE : Produits (~70% largeur)
                Expanded(
                  flex: 7,
                  child: _buildProductGrid(
                    pos,
                    products,
                    isSquare: true,
                    spacing: gap,
                  ),
                ),
                SizedBox(width: gap),
                // ✅ COLONNE DROITE : Panier (~30% largeur)
                Expanded(flex: 3, child: _buildCartPane(pos)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogToolbar(
    PosController pos,
    CategoryController category, {
    required bool isSquare,
    required double spacing,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final categories = ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
              scrollbars: false,
            ),
            child: ListView.builder(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: category.categories.length,
              itemBuilder: (context, index) {
                final cat = category.categories[index];
                if (cat.isDeleted) {
                  return const SizedBox.shrink();
                }
                final isActive = category.selectedCategory.value?.id == cat.id;
                final displayName = cat.name.startsWith('[LOCAL] ')
                    ? cat.name.substring(8)
                    : cat.name;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => category.selectCategory(cat),
                    child: _itemTab(
                      icon: Icons.lunch_dining_outlined,
                      title: displayName,
                      isActive: isActive,
                      imagePath: cat.image,
                    ),
                  ),
                );
              },
            ),
          );
          return SizedBox(
            height: 48,
            child: Row(children: [Expanded(child: categories)]),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
    PosController pos,
    List<Product> products, {
    required bool isSquare,
    required double spacing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 5;
        return GridView.builder(
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isSquare ? 0.94 : 0.98,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 220 + (index % 8) * 50),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: Opacity(opacity: value.clamp(0, 1), child: child),
                );
              },
              child: _dynamicItem(
                product: product,
                // Simple tap adds item to active group with course detection
                onTap: () =>
                    pos.addToCart(product, groupNumber: pos.activeGroupNumber),
                // Long press opens the note dialog
                onLongPress: () => _showItemOptions(context, pos, product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _existingOrderItemsPanel(PosController pos) {
    return FutureBuilder<List<PosOrderItem>>(
      future: _getExistingOrderItems(pos),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final existingItems = snapshot.data!;
        if (existingItems.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SushiColors.bluePale,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SushiColors.teal, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: SushiColors.teal),
                  const SizedBox(width: 6),
                  const Text(
                    'Produits existants:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SushiColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...existingItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SushiColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: SushiColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<List<PosOrderItem>> _getExistingOrderItems(PosController pos) async {
    if (!pos.isEditingExistingOrder || pos.editingOrderId == null) {
      return [];
    }
    try {
      final items = await DatabaseService.getPosOrderItems(pos.editingOrderId!);
      return deduplicateOrderItems(items);
    } catch (e) {
      return [];
    }
  }

  Widget _buildCartPane(PosController pos) {
    return Container(
      decoration: SushiDeco.card(),
      child: Column(
        children: [
          _topMenu(
            title: '',
            subTitle: pos.tableNumber == null
                ? ''
                : 'Table : ${pos.tableNumber}',
            action: _orderActions(pos),
          ),
          if (pos.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                pos.error!,
                style: const TextStyle(
                  color: SushiColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (pos.isEditingExistingOrder) _existingOrderItemsPanel(pos),
          _buildGroupTabsBar(pos),
          Expanded(flex: 1, child: _cartList(pos)),
          GetBuilder<PosController>(builder: (_) => _summaryPanel(pos)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _badgeCommitTimer?.cancel();
    _badgeListenerFocusNode.dispose();
    _pinController.dispose();
    _tableController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  int? _lastOrderId;

  Widget _buildLockScreen(PosController pos) {
    return Center(
      child: KeyboardListener(
        focusNode: _badgeListenerFocusNode,
        autofocus: true,
        onKeyEvent: (event) => _handleBadgeKeyEvent(event, pos),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(SushiSpace.xl),
          decoration: SushiDeco.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: SushiDeco.badge(bg: SushiColors.redPale),
                child: const Icon(Icons.lock, size: 28, color: SushiColors.red),
              ),
              const SizedBox(height: SushiSpace.md),
              const Text('PIN ou badge serveur', style: SushiTypo.h2),
              const SizedBox(height: SushiSpace.md),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SushiSpace.sm),
              GestureDetector(
                onTap: () => _badgeListenerFocusNode.requestFocus(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SushiSpace.md),
                  decoration: BoxDecoration(
                    color: SushiColors.surface,
                    borderRadius: BorderRadius.circular(SushiRadius.md),
                    border: Border.all(color: SushiColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isBadgeUnlocking
                            ? Icons.sync_rounded
                            : Icons.badge_outlined,
                        size: 18,
                        color: SushiColors.teal,
                      ),
                      const SizedBox(width: SushiSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lecteur badge', style: SushiTypo.h4),
                            const SizedBox(height: 4),
                            Text(_badgeStatus, style: SushiTypo.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pos.error != null) ...[
                const SizedBox(height: SushiSpace.sm),
                Text(
                  pos.error!,
                  style: SushiTypo.h4.copyWith(color: SushiColors.error),
                ),
              ],
              const SizedBox(height: SushiSpace.md),
              SushiCTAButton(
                child: const Text('Déverrouiller'),
                onPressed: () async {
                  final pin = _pinController.text.trim();
                  await _submitInlinePin(pos, pin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitInlinePin(PosController pos, String pin) async {
    final ok = await pos.unlockWithPin(pin);
    _pinController.clear();
    if (!ok || !mounted) return;
  }

  void _handleBadgeKeyEvent(KeyEvent event, PosController pos) {
    if (event is! KeyDownEvent || _isBadgeUnlocking) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      unawaited(_commitBadgeScan(pos));
      return;
    }
    final char = event.character;
    if (char == null || char.isEmpty) return;
    if (char.codeUnitAt(0) < 32) return;
    final now = DateTime.now();
    if (_lastBadgeKeyAt != null &&
        now.difference(_lastBadgeKeyAt!) > const Duration(milliseconds: 350)) {
      _badgeBuffer = '';
    }
    _lastBadgeKeyAt = now;
    _badgeBuffer += char;
    final preview = normalizeBadgeCode(_badgeBuffer);
    if (preview.isNotEmpty && mounted) {
      setState(() {
        _badgeStatus = 'Badge détecté: ${_badgePreview(preview)}';
      });
    }
    _badgeCommitTimer?.cancel();
    _badgeCommitTimer = Timer(
      const Duration(milliseconds: 180),
      () => unawaited(_commitBadgeScan(pos)),
    );
  }

  Future<void> _commitBadgeScan(PosController pos) async {
    _badgeCommitTimer?.cancel();
    final badgeCode = normalizeBadgeCode(_badgeBuffer);
    _badgeBuffer = '';
    _lastBadgeKeyAt = null;
    if (badgeCode.isEmpty || _isBadgeUnlocking) return;
    if (mounted) {
      setState(() {
        _isBadgeUnlocking = true;
        _badgeStatus = 'Lecture du badge en cours...';
      });
    }
    final ok = await pos.unlockWithBadge(badgeCode);
    if (!mounted) return;
    setState(() {
      _isBadgeUnlocking = false;
      _badgeStatus = ok
          ? 'Badge accepté'
          : 'Badge refusé: ${_badgePreview(badgeCode)}';
    });
  }

  String _badgePreview(String badgeCode) {
    if (badgeCode.length <= 18) return badgeCode;
    return '${badgeCode.substring(0, 18)}...';
  }

  /// ✅ Afficher le dialogue des options d'article (notes, cours) - SANS gestion de groupes
  Future<void> _showItemOptions(
    BuildContext context,
    PosController pos,
    Product product, {
    CartItem? cartItem, // Optional: if editing an existing cart item
  }) async {
    final result = await showItemOptionsDialog(
      context: context,
      product: product,
      currentGroupNumber: null, // Ne pas afficher les options de groupe
      availableGroups: const [], // Pas de groupes disponibles dans le dialogue
    );

    if (result != null && context.mounted) {
      // Helper pour obtenir le label correspondant à une clé de service course
      String? getServiceCourseLabel(String? serviceCourseKey) {
        if (serviceCourseKey == null) return null;
        switch (serviceCourseKey) {
          case 'starter':
            return 'Entrée';
          case 'main':
            return 'Plat Principal';
          case 'cheese':
            return 'Suite & Sortie';
          case 'dessert':
            return 'Dessert';
          case 'drink':
            return 'Boissons';
          case 'other':
            return 'Autres';
          default:
            return 'Autres';
        }
      }

      if (cartItem != null) {
        // Modifier l'élément existant du panier (préserver le groupe existant)
        cartItem.itemNote = result.itemNote;
        cartItem.serviceCourseKey = result.serviceCourseKey;
        cartItem.serviceCourseLabel = getServiceCourseLabel(
          result.serviceCourseKey,
        );
        // Rafraîchir l'UI
        pos.update();
      } else {
        // Ajouter un nouvel élément au panier (utiliser le groupe actif)
        await pos.addToCart(
          product,
          itemNote: result.itemNote,
          groupNumber: null, // Utiliser le groupe actif par défaut
          serviceCourseKey: result.serviceCourseKey,
          serviceCourseLabel: getServiceCourseLabel(result.serviceCourseKey),
        );
      }
    }
  }

  Widget _dynamicItem({
    required Product product,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return _ProductCard(
      product: product,
      onTap: onTap,
      onLongPress: onLongPress,
      imageBuilder: _buildProductImage,
    );
  }

  Widget _buildGroupTabsBar(PosController pos) {
    // ✅ Afficher les onglets des groupes seulement en mode on_site
    if (pos.fulfillmentType != 'on_site') {
      return const SizedBox.shrink();
    }

    final cartGroups = pos.cartGroups;
    if (cartGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return GetBuilder<PosController>(
      builder: (_) {
        final activeGroup = pos.activeGroupNumber;
        final groupItems = <int?, List<CartItem>>{};

        for (final item in pos.cart) {
          final groupKey = item.groupNumber;
          if (!groupItems.containsKey(groupKey)) {
            groupItems[groupKey] = [];
          }
          groupItems[groupKey]!.add(item);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ...cartGroups.map((groupNumber) {
                final itemCount = groupItems[groupNumber]?.length ?? 0;
                final isActive = activeGroup == groupNumber;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => pos.setActiveCartGroup(groupNumber),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? SushiColors.orange
                            : SushiColors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? SushiColors.orange
                              : SushiColors.orange.withAlpha(60),
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: SushiColors.orange.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ensemble $groupNumber',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : SushiColors.orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withAlpha(200)
                                  : SushiColors.orange.withAlpha(100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$itemCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? SushiColors.orange
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => pos.createNewCartGroup(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SushiColors.green.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: SushiColors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nouveau',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SushiColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cartList(PosController pos) {
    if (pos.cart.isEmpty) {
      return Center(child: Text('Panier vide', style: AppTypography.bodyLarge));
    }

    // ✅ Regrouper les articles par groupNumber
    final groupedItems = <int?, List<CartItem>>{};
    for (final item in pos.cart) {
      final groupKey = item.groupNumber;
      if (!groupedItems.containsKey(groupKey)) {
        groupedItems[groupKey] = [];
      }
      groupedItems[groupKey]!.add(item);
    }

    // ✅ Créer une liste plate avec des headers de groupe
    final flatItems = <dynamic>[];
    final sortedGroups = groupedItems.keys.toList()
      ..sort((a, b) => (a ?? -1).compareTo(b ?? -1));

    for (final groupKey in sortedGroups) {
      final items = groupedItems[groupKey]!;
      // Ajouter le header du groupe
      flatItems.add({'type': 'header', 'groupNumber': groupKey});
      // Ajouter les articles du groupe
      for (final item in items) {
        flatItems.add({'type': 'item', 'item': item});
      }
      // Ajouter un séparateur après chaque groupe (sauf le dernier)
      if (groupKey != sortedGroups.last) {
        flatItems.add({'type': 'separator'});
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          shrinkWrap: false,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: flatItems.length,
          itemBuilder: (context, index) {
            final entry = flatItems[index];

            if (entry['type'] == 'header') {
              final groupNumber = entry['groupNumber'] as int?;
              final groupName = groupNumber != null
                  ? 'Ensemble'
                  : 'Articles sans groupe';
              return GestureDetector(
                onTap: groupNumber != null
                    ? () => pos.setActiveCartGroup(groupNumber)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SushiColors.orange.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SushiColors.orange.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: SushiColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: SushiColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (entry['type'] == 'separator') {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: const Color(0xFFE0E0E0).withAlpha(120),
              );
            }

            if (entry['type'] == 'item') {
              final item = entry['item'] as CartItem;
              return Dismissible(
                key: ValueKey(
                  'cart-${item.product.id}-${item.groupNumber ?? 0}',
                ),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _promptQuantity(pos, item);
                    return false;
                  }
                  pos.setCartItemQuantity(
                    item.product,
                    0,
                    groupNumber: item.groupNumber,
                  );
                  return true;
                },
                background: _swipeAction(
                  icon: Icons.edit_outlined,
                  label: 'Modifier',
                  color: SushiColors.red,
                  alignLeft: true,
                ),
                secondaryBackground: _swipeAction(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  color: SushiColors.redDark,
                  alignLeft: false,
                ),
                child: _cartLineItem(pos, item),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _summaryPanel(PosController pos) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F5F5).withAlpha(242),
            SushiColors.red.withAlpha(12),
          ],
        ),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryRow(label: 'total', value: _money(pos.total)),
          if (pos.fulfillmentType == 'delivery') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pin_drop_outlined,
                      size: 18,
                      color: pos.isGlovoDelivery
                          ? const Color.fromARGB(255, 14, 137, 0)
                          : const Color.fromARGB(255, 240, 169, 1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Livraison Glovo',
                      style: SushiTypo.bodySm.copyWith(
                        color: pos.isGlovoDelivery
                            ? const Color.fromARGB(255, 34, 156, 17)
                            : const Color.fromARGB(255, 254, 155, 5),
                        fontWeight: pos.isGlovoDelivery
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: pos.isGlovoDelivery,
                  onChanged: (value) async {
                    await pos.setGlovoDelivery(value);
                  },
                  activeColor: SushiColors.green,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _actionButton(
            icon: Icons.check,
            label: pos.editingOrderId == null
                ? 'Enregistrer la commande'
                : 'Modifier la commande',
            onPressed: _isSaving || pos.isCreatingOrder
                ? null
                : () => _saveOrder(pos),
          ),
          const SizedBox(height: 2),
          _actionButton(
            icon: Icons.print_outlined,
            label: pos.editingOrderId != null && !pos.isAdminEditor
                ? 'Impression verrouillée'
                : 'Imprimer l\'addition',
            onPressed: pos.editingOrderId != null && !pos.isAdminEditor
                ? null
                : () async {
                    final currentOrderId =
                        pos.editingOrderId ??
                        (pos.cart.isEmpty ? _lastOrderId : null);
                    try {
                      await _saveAndPrintCustomerTicket(pos, currentOrderId);
                    } catch (e, st) {
                      debugPrint('Print button error: $e\n$st');
                      if (!mounted) return;
                      _notify(
                        'Erreur impression : $e',
                        title: 'Impression',
                        type: POSSnackType.error,
                      );
                    }
                  },
          ),
          const SizedBox(height: 2),
          _actionButton(
            icon: Icons.exit_to_app_rounded,
            label: 'Sortir',
            onPressed: _isSaving || pos.isCreatingOrder || _isNavigatingAway
                ? null
                : () => _scheduleExitAfterAction(immediate: true),
          ),
        ],
      ),
    );
  }

  Widget _orderActions(PosController pos) {
    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _selectFulfillment(pos),
              icon: const Icon(Icons.local_dining_outlined, size: 16),
              label: const Text('Type'),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => pos.createNewCartGroup(),
              icon: const Icon(Icons.group_add_outlined, size: 16),
              label: const Text('Ensemble +'),
            ),
            if (pos.fulfillmentType == 'on_site') ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                onPressed: () => _promptTableNumber(pos),
                icon: const Icon(Icons.table_restaurant_outlined, size: 16),
                label: const Text('Table'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _lockButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: SushiColors.red,
      backgroundColor: SushiColors.redPale.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Future<void> _selectFulfillment(PosController pos) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Type de commande'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'on_site'),
              child: const Text('Sur place'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'pickup'),
              child: const Text('À emporter'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'delivery'),
              child: const Text('Livraison'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      pos.setFulfillmentType(selected);
    }
  }

  Future<void> _promptTableNumber(PosController pos) async {
    _tableController.text = pos.tableNumber ?? '';
    final table = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Numéro de table'),
          content: TextField(
            controller: _tableController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(labelText: 'Table'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _tableController.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (table != null && table.isNotEmpty) {
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      final currentStaff = auth?.currentUser;
      final tables = await DatabaseService.getPosTables();
      final foundTable = tables.where((t) => t.number == table).firstOrNull;
      if (foundTable != null && foundTable.status == 'occupied') {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final orders = await DatabaseService.getPosOrdersByDateRange(
          startOfDay,
          endOfDay,
        );
        final tableOrder = orders
            .where(
              (o) =>
                  o.tableNumber == table &&
                  o.fulfillmentType == 'on_site' &&
                  o.status != 'delivered' &&
                  o.status != 'cancelled',
            )
            .firstOrNull;
        if (tableOrder != null &&
            currentStaff != null &&
            tableOrder.staffId != currentStaff.id) {
          if (mounted) {
            _notify(
              'Cette table est assignée à un autre serveur',
              title: 'Table occupée',
              type: POSSnackType.error,
            );
          }
          pos.setTableNumber('');
          return;
        }
      }
      pos.setTableNumber(table);
    } else {
      pos.setTableNumber('');
    }
  }

  Future<void> _showOrdersDialog(PosController pos) async {
    await pos.loadOrdersToday();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Commandes du jour'),
          content: SizedBox(
            width: 520,
            child: pos.ordersToday.isEmpty
                ? const Text('Aucune commande')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _filterChip(pos, 'all', 'Toutes'),
                          _filterChip(pos, 'pending', 'En attente'),
                          _filterChip(pos, 'confirmed', 'Confirmée'),
                          _filterChip(pos, 'cancelled', 'Annulée'),
                          ActionChip(
                            label: const Text('Historique'),
                            onPressed: () async {
                              await _showHistoryDialog(pos);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final order in pos.ordersToday)
                        ListTile(
                          title: Text(
                            'Commande #${order.id} • ${_labelForFulfillment(order.fulfillmentType)}',
                          ),
                          subtitle: Text(
                            'Total: ${_money(order.totalPrice)} • Statut: ${_labelForOrderStatus(order.status)}',
                          ),
                          trailing: order.paymentStatus == 'paid'
                              ? const Text('Payée')
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        await _showOrderDetails(pos, order);
                                      },
                                      child: const Text('Détails'),
                                    ),
                                    if (pos.canEditOrders &&
                                        order.status == 'pending')
                                      TextButton(
                                        onPressed: () async {
                                          await _showEditOrderDialog(
                                            pos,
                                            order,
                                          );
                                          if (mounted) Get.back();
                                        },
                                        child: const Text('Edit order'),
                                      ),
                                    if (pos.canEditOrders &&
                                        order.status == 'pending')
                                      TextButton(
                                        onPressed: () async {
                                          if (order.fulfillmentType ==
                                                  'on_site' &&
                                              order.tableNumber != null &&
                                              order.tableNumber!.isNotEmpty) {
                                            if (pos.editingOrderId != null &&
                                                pos.editingOrderId !=
                                                    order.id) {
                                              if (mounted) {
                                                _notify(
                                                  'Une autre commande est déjà en cours de modification',
                                                  title: 'Table occupée',
                                                  type: POSSnackType.warning,
                                                );
                                              }
                                              return;
                                            }
                                            final auth =
                                                Get.isRegistered<
                                                  AuthController
                                                >()
                                                ? Get.find<AuthController>()
                                                : null;
                                            final currentStaff =
                                                auth?.currentUser;
                                            if (currentStaff != null &&
                                                order.staffId !=
                                                    currentStaff.id) {
                                              if (mounted) {
                                                _notify(
                                                  'Cette table est assignée à un autre serveur',
                                                  title: 'Accès refusé',
                                                  type: POSSnackType.error,
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          await pos.loadOrderForEdit(order);
                                          if (mounted) Get.back();
                                        },
                                        child: const Text('Modifier'),
                                      ),
                                    TextButton(
                                      onPressed: () async {
                                        final paymentConfirmed =
                                            await _showPaymentDialog(
                                              pos,
                                              order,
                                            );
                                        if (!paymentConfirmed && mounted) {
                                          return;
                                        }
                                        if (mounted) Get.back();
                                      },
                                      child: const Text('Payer'),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(PosController pos, String value, String label) {
    final selected = pos.ordersFilter == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      selectedColor: SushiColors.red.withAlpha(24),
      checkmarkColor: SushiColors.red,
      side: BorderSide(color: selected ? SushiColors.red : AppColors.grisLeger),
      onSelected: (_) => pos.setOrdersFilter(value),
    );
  }

  Future<void> _promptQuantity(PosController pos, CartItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quantité'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final qty = int.tryParse(controller.text.trim());
                Navigator.pop(context, qty);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      pos.setCartItemQuantity(
        item.product,
        result,
        groupNumber: item.groupNumber,
      );
    }
  }

  Future<void> _showOrderDetails(PosController pos, PosOrder order) async {
    appLogger.i('🔍 [POS] Loading items for Order #${order.id}');
    var items = await DatabaseService.getPosOrderItems(order.id);
    if (!mounted) return;
    appLogger.i(
      '🔍 [POS] Order #${order.id}: ${items.length} items (direct query)',
    );
    if (items.isEmpty) {
      final allItems = await DatabaseService.getAllPosOrderItems();
      appLogger.i('🔍 [POS] Total items in DB: ${allItems.length}');
      if (allItems.isNotEmpty) {
        final orderIds = allItems.map((i) => i.orderId).toSet().toList()
          ..sort();
        appLogger.i('🔍 [POS] Existing orderIds in DB: $orderIds');
      }
      items = allItems.where((item) => item.orderId == order.id).toList();
      appLogger.i('🔍 [POS] After manual filter: ${items.length} items');
    }
    items = deduplicateOrderItems(items);
    if (items.isEmpty) {
      appLogger.e('❌ [POS] NO ITEMS FOUND for Order #${order.id}!');
    } else {
      appLogger.i('✅ [POS] Found ${items.length} items for Order #${order.id}');
      for (final item in items) {
        appLogger.i('   └─ Item: ${item.productName} x${item.quantity}');
      }
    }
    final statusColor = _orderStatusColor(order.status);
    final locationLabel = order.fulfillmentType == 'on_site'
        ? 'Table'
        : 'Adresse';
    final locationValue = order.fulfillmentType == 'on_site'
        ? (order.tableNumber?.trim().isEmpty ?? true
              ? '-'
              : order.tableNumber!.trim())
        : (order.deliveryAddress?.trim().isEmpty ?? true
              ? '-'
              : order.deliveryAddress!.trim());
    final cancelReason = order.cancelReason?.trim().isEmpty ?? true
        ? '-'
        : order.cancelReason!;
    final note = order.note?.trim().isEmpty ?? true ? '-' : order.note!;
    final isSplitPayment =
        order.paymentMethod == 'split' &&
        order.paymentSplit != null &&
        order.paymentSplit!.isNotEmpty;
    final paymentMethod = isSplitPayment
        ? 'Paiement multiple'
        : paymentMethodLabel(order.paymentMethod);
    final splitPaymentDetails = isSplitPayment
        ? formatSplitPaymentDetails(order.paymentSplit)
        : '';
    final reward = order.rewardId != null ? '#${order.rewardId}' : '-';
    final discountLabel = order.hasDiscount && order.discountAmount > 0
        ? '-${_money(order.discountAmount)}'
        : 'Aucune';
    final originalTotalLabel = order.originalTotal > 0
        ? _money(order.originalTotal)
        : _money(order.totalPrice);
    final createdLabel = '${order.createdAt.toLocal()}'.split('.').first;
    final updatedLabel = '${order.updatedAt.toLocal()}'.split('.').first;
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: SushiColors.ink,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: SushiSpace.lg,
            vertical: SushiSpace.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
            child: Container(
              decoration: SushiDeco.card(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SushiSpace.xl,
                      vertical: SushiSpace.md,
                    ),
                    decoration: SushiDeco.featured(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande #${order.id}',
                                style: SushiTypo.h1,
                              ),
                              const SizedBox(height: SushiSpace.sm),
                              Wrap(
                                spacing: SushiSpace.sm,
                                runSpacing: SushiSpace.sm,
                                children: [
                                  _statusBadge(
                                    _labelForOrderStatus(order.status),
                                    statusColor,
                                  ),
                                  _statusBadge(
                                    _labelForChannel(order.channel),
                                    SushiColors.teal,
                                  ),
                                  _statusBadge(
                                    _labelForFulfillment(order.fulfillmentType),
                                    SushiColors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: SushiSpace.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SushiSpace.lg,
                            vertical: SushiSpace.sm,
                          ),
                          decoration: SushiDeco.tinted(
                            color: SushiColors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Total', style: SushiTypo.caption),
                              Text(
                                _money(order.totalPrice),
                                style: SushiTypo.priceLg,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        SushiSpace.xl,
                        SushiSpace.md,
                        SushiSpace.xl,
                        SushiSpace.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: SushiSpace.md,
                            runSpacing: SushiSpace.md,
                            children: [
                              _orderDetailsInfoCard(
                                icon: Icons.person_outline,
                                label: 'Client',
                                value: order.customerName ?? '-',
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.call_outlined,
                                label: 'Téléphone',
                                value: order.customerPhone ?? '-',
                              ),
                              _orderDetailsInfoCard(
                                icon: order.fulfillmentType == 'on_site'
                                    ? Icons.table_bar_outlined
                                    : Icons.location_on_outlined,
                                label: locationLabel,
                                value: locationValue,
                              ),
                              if (order.fulfillmentType == 'delivery' &&
                                  order.glovoOrderNumber != null &&
                                  order.glovoOrderNumber!.trim().isNotEmpty)
                                _orderDetailsInfoCard(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'Numéro Glovo',
                                  value: order.glovoOrderNumber!,
                                ),
                              if (order.fulfillmentType == 'delivery' &&
                                  order.status == 'confirmed')
                                _buildDeliveryAssignmentCard(
                                  context,
                                  pos,
                                  order,
                                ),
                              _orderDetailsInfoCard(
                                icon: Icons.event_note_outlined,
                                label: 'Annulation',
                                value: cancelReason,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.sticky_note_2_outlined,
                                label: 'Note commande',
                                value: note,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.badge_outlined,
                                label: 'Staff ID',
                                value: order.staffId.toString(),
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.store_mall_directory_outlined,
                                label: 'Restaurant',
                                value: order.restaurantId?.toString() ?? '-',
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Récompense',
                                value: reward,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.payment_outlined,
                                label: 'Paiement',
                                value: paymentMethod,
                              ),
                              if (isSplitPayment &&
                                  splitPaymentDetails.isNotEmpty)
                                _orderDetailsInfoCard(
                                  icon: Icons.splitscreen_outlined,
                                  label: 'Détail paiements',
                                  value: splitPaymentDetails,
                                ),
                              _orderDetailsInfoCard(
                                icon: Icons.receipt_long_outlined,
                                label: 'Statut paiement',
                                value: _labelForPaymentStatus(
                                  order.paymentStatus,
                                ),
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.percent_outlined,
                                label: 'Remise',
                                value: discountLabel,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.calculate_outlined,
                                label: 'Total initial',
                                value: originalTotalLabel,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.schedule_outlined,
                                label: 'Créée',
                                value: createdLabel,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.update_outlined,
                                label: 'MAJ',
                                value: updatedLabel,
                              ),
                            ],
                          ),
                          const SizedBox(height: SushiSpace.md),
                          Text(
                            'Articles (${items.length})',
                            style: SushiTypo.h3,
                          ),
                          const SizedBox(height: SushiSpace.sm),
                          if (items.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(SushiSpace.md),
                              decoration: SushiDeco.card(),
                              child: Text(
                                'Aucun article trouvé pour cette commande.',
                                style: SushiTypo.bodyMd,
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final it in items)
                                  _orderDetailsItemCard(it),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      SushiSpace.lg,
                      SushiSpace.sm,
                      SushiSpace.lg,
                      SushiSpace.lg,
                    ),
                    decoration: SushiDeco.tinted(color: SushiColors.surface),
                    child: Wrap(
                      spacing: SushiSpace.sm,
                      runSpacing: SushiSpace.sm,
                      alignment: WrapAlignment.end,
                      children: [
                        if (order.status == 'pending')
                          ElevatedButton.icon(
                            style: SushiButtonStyle.secondary(),
                            onPressed: () async {
                              final ok = await pos.updateOrderStatus(
                                order,
                                'confirmed',
                              );
                              if (!ok && mounted) {
                                _notify(
                                  pos.error ??
                                      'Commande locale mise à jour, notification backend échouée.',
                                  title: 'Erreur backend',
                                  type: POSSnackType.error,
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: Text('Confirmer', style: SushiTypo.h4),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Fermer', style: SushiTypo.h4),
                        ),
                      ],
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

  Future<void> _showPrintTicket(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('=== TICKET CAISSE ===');
    buffer.writeln('Commande #${order.id}');
    buffer.writeln('Type : ${_labelForFulfillment(order.fulfillmentType)}');
    buffer.writeln('Table : ${order.tableNumber ?? '-'}');
    buffer.writeln('Client : ${order.customerName ?? '-'}');
    buffer.writeln('Téléphone : ${order.customerPhone ?? '-'}');
    if (order.glovoOrderNumber != null &&
        order.glovoOrderNumber!.trim().isNotEmpty) {
      buffer.writeln('Numéro Glovo : ${order.glovoOrderNumber}');
    }
    if (order.deliveryAddress != null) {
      buffer.writeln('Adresse: ${order.deliveryAddress}');
    }
    buffer.writeln('------------------');
    for (final it in items) {
      buffer.writeln(
        '${it.quantity} x ${it.productName} @ ${_money(it.unitPrice)}',
      );
    }
    buffer.writeln('------------------');
    buffer.writeln('Total: ${_money(order.totalPrice)}');
    final ticketText = buffer.toString();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ticket (local)'),
          content: SizedBox(width: 520, child: SelectableText(ticketText)),
          actions: [
            TextButton(
              onPressed: () async {
                if (!mounted) return;
                await Clipboard.setData(ClipboardData(text: ticketText));
                if (!mounted) return;
                Get.back();
              },
              child: const Text('Copier'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<_OrderPrintContext?> _loadOrderPrintContext(
    int orderId, {
    List<CartItem>? fallbackCartItems,
  }) async {
    final order = await DatabaseService.getPosOrderById(orderId);
    if (order == null) {
      return null;
    }
    var items = await DatabaseService.getPosOrderItems(orderId);
    if (items.isEmpty &&
        fallbackCartItems != null &&
        fallbackCartItems.isNotEmpty) {
      // If the DB rows are not visible yet, rebuild the preview from the cart snapshot.
      items = _buildPrintedItemsFromCart(orderId, fallbackCartItems);
    }
    if (items.isEmpty) {
      return null;
    }

    String? staffName;
    try {
      final staff = await DatabaseService.getUserById(order.staffId);
      staffName = staff?.name;
    } catch (_) {}

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final restaurantId = order.restaurantId ?? auth?.currentUser?.restaurantId;
    String? restaurantName;
    String? restaurantAddress;
    String? restaurantPhone;
    if (restaurantId != null) {
      try {
        final restaurant = await DatabaseService.getRestaurantById(
          restaurantId,
        );
        restaurantName = restaurant?.name;
        restaurantAddress = restaurant?.address;
        restaurantPhone = restaurant?.phone ?? auth?.currentUser?.phone;
      } catch (_) {
        restaurantPhone = auth?.currentUser?.phone;
      }
    } else {
      restaurantPhone = auth?.currentUser?.phone;
    }

    return _OrderPrintContext(
      order: order,
      items: items,
      staffName: staffName,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantPhone: restaurantPhone,
    );
  }

  Future<void> _printKitchenTicket(
    PosOrder order,
    List<PosOrderItem> items, {
    String? staffName,
    String? restaurantAddress,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    debugPrint(
      '[_printKitchenTicket] order=${order.id} items=${items.length} totalQty=$totalQuantity paymentStatus=${order.paymentStatus} channel=${order.channel}',
    );
    final hasKitchenPrinter = await EscPosPrinterService.instance
        .hasConfiguredPrinter(kitchen: true);
    final directPrinted = hasKitchenPrinter
        ? await EscPosPrinterService.instance.tryPrintKitchenTicket(
            order,
            items,
            staffName: staffName,
            restaurantAddress: restaurantAddress,
            restaurantName: restaurantName,
            restaurantPhone: restaurantPhone,
          )
        : false;
    debugPrint(
      '[_printKitchenTicket] directPrinted=$directPrinted order=${order.id}',
    );
    if (directPrinted) {
      if (mounted) {
        _notify(
          'Ticket cuisine envoyé directement à l\'imprimante',
          title: 'Impression',
          type: POSSnackType.success,
        );
      }
      return;
    }
    debugPrint(
      '[_printKitchenTicket] launching preview fallback for order=${order.id}',
    );
    await _printOrPreview(
      forcePreview: true,
      builder: (format) => buildKitchenTicketPdf(
        order,
        items,
        format: format,
        staffName: staffName,
        restaurantAddress: restaurantAddress,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      ),
      fallbackTitle: 'Ticket cuisine (aperçu)',
      onFail: () =>
          _showTextTicket(order, items, title: 'Ticket cuisine (texte)'),
    );
  }

  Future<void> _printKitchenTicketByOrderId(int orderId) async {
    final context = await _loadOrderPrintContext(orderId);
    if (context == null) {
      throw 'Commande ou lignes introuvables';
    }

    await _printKitchenTicket(
      context.order,
      context.items,
      staffName: context.staffName,
      restaurantAddress: context.restaurantAddress,
      restaurantName: context.restaurantName,
      restaurantPhone: context.restaurantPhone,
    );
  }

  List<PosOrderItem> _buildPrintedItemsFromCart(
    int orderId,
    List<CartItem> cartItems,
  ) {
    final now = DateTime.now();
    return cartItems
        .map((item) {
          return PosOrderItem(
            orderId: orderId,
            productId: item.product.id,
            productName: item.product.name,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            priceType: item.priceType,
            glovoBasePrice: item.basePrice,
            groupNumber: item.groupNumber,
            groupLabel: item.groupNumber != null
                ? formatGuestGroupLabel(groupNumber: item.groupNumber)
                : null,
            itemNote: item.itemNote,
            serviceCourseKey: item.serviceCourseKey,
            serviceCourseLabel: item.serviceCourseLabel,
            createdAt: now,
          );
        })
        .toList(growable: false);
  }

  Future<void> _printKitchenAndCustomerTicketsByOrderId(
    int orderId, {
    List<CartItem>? fallbackCartItems,
  }) async {
    final context = await _loadOrderPrintContext(
      orderId,
      fallbackCartItems: fallbackCartItems,
    );
    if (context == null) {
      throw 'Commande ou lignes introuvables';
    }

    await _printKitchenAndCustomerTickets(
      context.order,
      context.items,
      staffName: context.staffName,
      restaurantAddress: context.restaurantAddress,
      restaurantName: context.restaurantName,
      restaurantPhone: context.restaurantPhone,
    );
  }

  Future<void> _printEditedOrderAddedItemsByOrderId(
    int orderId,
    List<CartItem> addedCartItems,
  ) async {
    final context = await _loadOrderPrintContext(orderId);
    if (context == null) {
      throw 'Commande ou lignes introuvables';
    }

    final itemsToPrint = _buildPrintedItemsFromCart(orderId, addedCartItems);
    if (itemsToPrint.isEmpty) {
      return;
    }

    await _printKitchenTicket(
      context.order,
      itemsToPrint,
      staffName: context.staffName,
      restaurantAddress: context.restaurantAddress,
      restaurantName: context.restaurantName,
      restaurantPhone: context.restaurantPhone,
    );
  }



  Future<void> _printCustomerBillByOrderId(
    int orderId, {
    List<CartItem>? fallbackCartItems,
  }) async {
    final context = await _loadOrderPrintContext(
      orderId,
      fallbackCartItems: fallbackCartItems,
    );
    if (context == null) {
      throw 'Commande ou lignes introuvables';
    }

    await _printCustomerBill(
      context.order,
      context.items,
      staffName: context.staffName,
      restaurantAddress: context.restaurantAddress,
      restaurantName: context.restaurantName,
      restaurantPhone: context.restaurantPhone,
    );
  }

  Future<void> _saveAndPrintCustomerTicket(
    PosController pos,
    int? currentOrderId,
  ) async {
    if (_isSaving || pos.isCreatingOrder) return;
    _isSaving = true;
    try {
      final cartSnapshot = List<CartItem>.from(pos.cart);
      var orderId = currentOrderId;
      if (orderId == null) {
        if (pos.cart.isEmpty) {
          if (mounted) {
            _notify(
              'Aucune commande en cours à imprimer',
              title: 'Impression',
              type: POSSnackType.warning,
            );
          }
          return;
        }
        if (pos.fulfillmentType == 'pickup' ||
            pos.fulfillmentType == 'delivery') {
          final customerConfirmed = await _showCustomerSelectionDialog(pos);
          if (!customerConfirmed) {
            return;
          }
        }
        if (pos.fulfillmentType == 'on_site' &&
            (pos.tableNumber == null || pos.tableNumber!.isEmpty)) {
          await _promptTableNumber(pos);
          if (pos.tableNumber == null || pos.tableNumber!.isEmpty) {
            return;
          }
        }
        orderId = await pos.createOrder();
        if (orderId == null) {
          return;
        }
        if (pos.fulfillmentType == 'on_site') {
          final table = pos.tableNumber;
          if (table != null && table.isNotEmpty) {
            final auth = Get.isRegistered<AuthController>()
                ? Get.find<AuthController>()
                : null;
            final currentStaff = auth?.currentUser;
            final staffId = currentStaff?.id;
            try {
              await pos.markTableOccupied(table, requestingStaffId: staffId);
            } catch (e) {
              if (mounted) {
                _notify(
                  'Table déjà assignée à un autre serveur: $e',
                  title: 'Erreur',
                  type: POSSnackType.error,
                );
              }
              return;
            }
          }
        }
      }

      final int savedOrderId = orderId;
      setState(() => _lastOrderId = savedOrderId);

      await _printCustomerBillByOrderId(
        savedOrderId,
        fallbackCartItems: currentOrderId == null ? cartSnapshot : null,
      );
      if (!mounted) return;
      _notify(
        'Addition client imprimée avec succès',
        title: 'Impression',
        type: POSSnackType.success,
      );
      _isNavigatingAway = true;
      pos.lock();
      Get.offAllNamed('/pos-lock');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _printKitchenAndCustomerTickets(
    PosOrder order,
    List<PosOrderItem> items, {
    String? staffName,
    String? restaurantAddress,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    debugPrint(
      '[_printKitchenAndCustomerTickets] order=${order.id} items=${items.length} totalQty=$totalQuantity paymentStatus=${order.paymentStatus} channel=${order.channel}',
    );
    final hasKitchenPrinter = await EscPosPrinterService.instance
        .hasConfiguredPrinter(kitchen: true);
    final hasCustomerPrinter = await EscPosPrinterService.instance
        .hasConfiguredPrinter(kitchen: false);
    final hasAnyPrinter = hasKitchenPrinter || hasCustomerPrinter;
    final directPrinted = hasAnyPrinter
        ? await EscPosPrinterService.instance.tryPrintKitchenAndCustomerTickets(
            order,
            items,
            staffName: staffName,
            restaurantAddress: restaurantAddress,
            restaurantName: restaurantName,
            restaurantPhone: restaurantPhone,
          )
        : false;
    if (directPrinted) {
      if (mounted) {
        _notify(
          'Tickets cuisine et client envoyés directement à l\'imprimante',
          title: 'Impression',
          type: POSSnackType.success,
        );
      }
      return;
    }
    await _printOrPreview(
      forcePreview: true,
      builder: (format) => buildKitchenAndCustomerTicketsPdf(
        order,
        items,
        format: format,
        staffName: staffName,
        restaurantAddress: restaurantAddress,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      ),
      fallbackTitle: 'Tickets cuisine et addition client (aperçu)',
      onFail: () => _showTextTicket(
        order,
        items,
        title: 'Tickets cuisine et addition client (texte)',
      ),
    );
  }

  Future<void> _printCustomerBill(
    PosOrder order,
    List<PosOrderItem> items, {
    String? staffName,
    String? restaurantAddress,
    String? restaurantName,
    String? restaurantPhone,
  }) async {
    final directPrinted = await EscPosPrinterService.instance
        .tryPrintCustomerTicket(
          order,
          items,
          staffName: staffName,
          restaurantAddress: restaurantAddress,
          restaurantName: restaurantName,
          restaurantPhone: restaurantPhone,
        );
    if (directPrinted) {
      if (mounted) {
        _notify(
          'Addition client envoyée directement à l\'imprimante',
          title: 'Impression',
          type: POSSnackType.success,
        );
      }
      return;
    }
    await _printOrPreview(
      forcePreview: true,
      builder: (format) => buildCustomerBillPdf(
        order,
        items,
        format: format,
        staffName: staffName,
        restaurantAddress: restaurantAddress,
        restaurantName: restaurantName,
        restaurantPhone: restaurantPhone,
      ),
      fallbackTitle: 'Addition client (aperçu)',
      onFail: () =>
          _showTextTicket(order, items, title: 'Addition client (texte)'),
    );
  }

  Future<void> _autoPrintKitchenByOrderId(int orderId) async {
    final context = await _loadOrderPrintContext(orderId);
    if (context == null) return;

    await _printKitchenTicket(
      context.order,
      context.items,
      staffName: context.staffName,
      restaurantAddress: context.restaurantAddress,
      restaurantName: context.restaurantName,
      restaurantPhone: context.restaurantPhone,
    );
  }

  bool _isMobileApi(PosOrder order) {
    return order.channel.trim().toLowerCase() == 'api';
  }

  void _scheduleExitAfterAction({bool immediate = false}) {
    if (_isSaving || _isNavigatingAway) return;
    _isNavigatingAway = true;
    final delay = immediate ? Duration.zero : const Duration(seconds: 5);
    Future.delayed(delay, () {
      if (!mounted || _isSaving) return;
      final pos = Get.find<PosController>();
      pos.lock();
      Get.offAllNamed('/pos-lock');
    });
  }

  Future<bool> _showPaymentDialog(PosController pos, PosOrder order) async {
    final dialogContext = context;
    double cashAmount = 0.0;
    double tpeAmount = 0.0;
    double accountAmount = 0.0;
    return await showDialog<bool>(
          context: dialogContext,
          barrierDismissible: false,
          builder: (alertContext) => StatefulBuilder(
            builder: (alertContext, setDialogState) {
              final totalGiven = cashAmount + tpeAmount + accountAmount;
              final isComplete = totalGiven >= order.totalPrice;
              final change = totalGiven - order.totalPrice;
              final remainingAmount = order.totalPrice - totalGiven;
              return AlertDialog(
                title: const Text('Paiement'),
                content: SizedBox(
                  width: 600,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SushiColors.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${order.totalPrice.toStringAsFixed(2)} DA',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: SushiColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Modes de paiement:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SushiColors.inkMid,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TPE:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.credit_card,
                                      size: 18,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    setDialogState(() {
                                      tpeAmount = parsed ?? 0.0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cash:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.payments,
                                      size: 18,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    setDialogState(() {
                                      cashAmount = parsed ?? 0.0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'En compte:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.account_balance_wallet,
                                      size: 18,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    setDialogState(() {
                                      accountAmount = parsed ?? 0.0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (totalGiven > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? SushiColors.greenPale
                                : SushiColors.orangePale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isComplete ? 'Monnaie à rendre:' : 'Reste:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isComplete
                                      ? SushiColors.green
                                      : SushiColors.orange,
                                ),
                              ),
                              Text(
                                isComplete
                                    ? '${change.toStringAsFixed(2)} DA'
                                    : '${remainingAmount.toStringAsFixed(2)} DA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isComplete
                                      ? SushiColors.green
                                      : SushiColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(alertContext).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton.icon(
                    onPressed: totalGiven <= 0
                        ? null
                        : () async {
                            try {
                              final payments = <Map<String, dynamic>>[];
                              if (cashAmount > 0) {
                                payments.add({
                                  'method': 'cash',
                                  'amount': cashAmount,
                                });
                              }
                              if (tpeAmount > 0) {
                                payments.add({
                                  'method': 'tpe',
                                  'amount': tpeAmount,
                                });
                              }
                              if (accountAmount > 0) {
                                payments.add({
                                  'method': paymentMethodEnCompte,
                                  'amount': accountAmount,
                                });
                              }
                              appLogger.d(
                                '💳 Paiement: ${payments.length} méthodes, total: $totalGiven',
                              );
                              if (payments.length == 1) {
                                await pos.markOrderAsPaid(
                                  order,
                                  payments.first['method'] as String,
                                );
                              } else if (payments.length > 1) {
                                await pos.markOrderAsPaidWithSplit(
                                  order,
                                  payments,
                                );
                              }
                              OrderSyncService().syncOrderStatus(
                                orderId: order.id,
                                status: order.status,
                                paymentStatus: 'paid',
                              );
                              if (order.fulfillmentType == 'on_site' &&
                                  order.tableNumber != null &&
                                  order.tableNumber!.isNotEmpty) {
                                await pos.markTableFree(order.tableNumber!);
                              }

                              try {
                                final items =
                                    await DatabaseService.getPosOrderItems(
                                      order.id,
                                    );
                                if (items.isNotEmpty) {
                                  await _printKitchenTicket(order, items);
                                }
                              } catch (e, st) {
                                appLogger.e(
                                  '❌ Erreur impression ticket après paiement: $e',
                                );
                                debugPrint('Print error: $e\n$st');
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Paiement enregistré, mais le ticket n\'a pas pu être imprimé.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }

                              if (alertContext.mounted) {
                                Navigator.of(alertContext).pop(true);
                              }
                            } catch (e) {
                              appLogger.e('❌ Erreur paiement: $e');
                              if (!mounted) return;
                              if (mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SushiColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;
  }

  Future<void> _showPostOrderSuccessFlow({
    required PosController pos,
    required int orderId,
    required bool wasEditing,
    bool autoLock = false,
    Future<void> Function()? beforeAutoLock,
  }) async {
    if (!mounted) return;
    final label = wasEditing
        ? 'Commande modifiée (#$orderId)'
        : 'Commande enregistrée (#$orderId)';
    showPOSSnack(
      context,
      label,
      type: POSSnackType.success,
      duration: const Duration(seconds: 2),
    );
    if (autoLock) {
      if (beforeAutoLock != null) {
        try {
          await beforeAutoLock();
        } catch (e) {
          debugPrint('Post-order action failed: $e');
          if (mounted) {
            _notify(
              'Commande enregistrée, mais l\'impression a échoué.',
              title: 'Impression',
              type: POSSnackType.warning,
            );
          }
        }
      }

      // Lock immediately after the post-action when requested.
      _isNavigatingAway = true;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      pos.lock();
      Get.offAllNamed('/pos-lock');
      return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            wasEditing ? 'Modification enregistrée' : 'Commande validée',
          ),
          content: Text(
            wasEditing
                ? 'Voulez-vous continuer sur la caisse ou fermer et revenir à l\'écran PIN ?'
                : 'Voulez-vous continuer pour passer une autre commande ou fermer et revenir à l\'écran PIN ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (shouldContinue == true) {
      return;
    }
    pos.lock();
    Get.offAllNamed('/pos-lock');
  }

  Future<void> _printOrPreview({
    required Future<Uint8List> Function(PdfPageFormat format) builder,
    required String fallbackTitle,
    Future<void> Function()? onFail,
    bool forcePreview = false,
  }) async {
    Future<Uint8List> safeBuilder(PdfPageFormat format) =>
        _safePdf(builder, format);
    if (!mounted) return;
    try {
      if (Platform.isMacOS || forcePreview) {
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
        (format) => _fallbackErrorPdf('Impossible d\'afficher le ticket : $e'),
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
              'Ticket non imprimé',
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

  Future<void> _showTextTicket(
    PosOrder order,
    List<PosOrderItem> items, {
    required String title,
  }) async {
    final text = _buildTicketText(order, items);
    if (!mounted) return;
    final ctx = context;
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title, style: SushiTypo.h3),
        content: SizedBox(
          width: 480,
          child: SelectableText(text, style: SushiTypo.bodyMd),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _buildTicketText(PosOrder order, List<PosOrderItem> items) {
    final money = AppSettingsService.instance.formatAmount;
    final buf = StringBuffer()
      ..writeln('Commande #${order.id}')
      ..writeln('Type: ${order.fulfillmentType}')
      ..writeln('Table: ${order.tableNumber ?? '-'}')
      ..writeln('Client: ${order.customerName ?? '-'}');
    if (order.glovoOrderNumber != null &&
        order.glovoOrderNumber!.trim().isNotEmpty) {
      buf.writeln('Numéro Glovo: ${order.glovoOrderNumber}');
    }
    buf.writeln('-----------------------------');
    for (final it in items) {
      buf.writeln(
        '${it.quantity} x ${it.productName}  ${money(it.unitPrice * it.quantity)}',
      );
    }
    buf
      ..writeln('-----------------------------')
      ..writeln('Total: ${money(order.totalPrice)}');
    return buf.toString();
  }

  Future<void> _showTicketPreview(
    Future<Uint8List> Function(PdfPageFormat format) builder, {
    required String title,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) {
        // Wrap builder to add lightweight debug logging about preview build
        Future<Uint8List> wrappedBuilder(PdfPageFormat format) async {
          try {
            debugPrint('[_showTicketPreview] building PDF preview: $title');
            final data = await builder(format);
            debugPrint(
              '[_showTicketPreview] PDF built (${data.length} bytes): $title',
            );
            return data;
          } catch (e, st) {
            debugPrint('[_showTicketPreview] PDF build failed: $e\n$st');
            rethrow;
          }
        }

        return Dialog(
          child: SizedBox(
            width: 460,
            height: 620,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SushiSpace.lg,
                    vertical: SushiSpace.sm,
                  ),
                  decoration: SushiDeco.card(),
                  child: Row(
                    children: [
                      Text(title, style: SushiTypo.h3),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: SushiColors.divider),
                Expanded(
                  child: PdfPreview(
                    build: wrappedBuilder,
                    allowSharing: true,
                    allowPrinting: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: 'ticket-preview.pdf',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptCancelReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Motif annulation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Motif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return null;
    return reason;
  }

  Future<void> _showEditOrderDialog(PosController pos, PosOrder order) async {
    String selectedType = order.fulfillmentType;
    final tableController = TextEditingController(
      text: order.tableNumber ?? '',
    );
    final nameController = TextEditingController(
      text: order.customerName ?? '',
    );
    final phoneController = TextEditingController(
      text: order.customerPhone ?? '',
    );
    final addressController = TextEditingController(
      text: order.deliveryAddress ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Modifier commande #${order.id}'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'on_site',
                            child: Text('Sur place'),
                          ),
                          DropdownMenuItem(
                            value: 'pickup',
                            child: Text('A emporter'),
                          ),
                          DropdownMenuItem(
                            value: 'delivery',
                            child: Text('Livraison'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedType = value);
                        },
                      ),
                      if (selectedType == 'on_site')
                        TextField(
                          controller: tableController,
                          decoration: const InputDecoration(
                            labelText: 'Table',
                            helperText: 'La table ne peut pas être modifiée',
                          ),
                          enabled: false,
                        ),
                      if (selectedType == 'pickup' ||
                          selectedType == 'delivery')
                        TextField(
                          controller: nameController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Nom client',
                            helperText: 'Optionnel',
                          ),
                        ),
                      if (selectedType == 'pickup' ||
                          selectedType == 'delivery')
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Telephone',
                            helperText: 'Optionnel',
                          ),
                        ),
                      if (selectedType == 'delivery')
                        TextField(
                          controller: addressController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Adresse livraison (optionnel)',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await pos.editOrderDetails(
                      order,
                      fulfillmentType: selectedType,
                      tableNumber: tableController.text,
                      customerName: nameController.text,
                      customerPhone: phoneController.text,
                      deliveryAddress: addressController.text,
                    );
                    if (!mounted) return;
                    if (!ok) {
                      _notify(
                        pos.error ?? 'Modification impossible',
                        title: 'Erreur',
                        type: POSSnackType.error,
                      );
                      return;
                    }
                    if (!mounted) return;
                    Get.back();
                    _notify(
                      'Commande mise a jour',
                      title: 'Succès',
                      type: POSSnackType.success,
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHistoryDialog(PosController pos) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month, picked.day);
    final end = start.add(const Duration(days: 1));
    final auth = Get.find<AuthController>();
    final restaurantId = auth.currentUser?.restaurantId;
    final allOrders = await DatabaseService.getPosOrdersByDateRange(start, end);
    final orders = restaurantId != null
        ? allOrders.where((o) {
            if (o.restaurantId == null) return true;
            return o.restaurantId == restaurantId;
          }).toList()
        : allOrders;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Historique ${picked.toString().split(' ')[0]}'),
          content: SizedBox(
            width: 520,
            child: orders.isEmpty
                ? const Text('Aucune commande')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final order in orders)
                        ListTile(
                          title: Text('Commande #${order.id}'),
                          subtitle: Text(
                            'Total: ${_money(order.totalPrice)} • Statut: ${_labelForOrderStatus(order.status)}',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              await _showOrderDetails(pos, order);
                            },
                            child: const Text('Détails'),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _orderDetailsInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
      padding: const EdgeInsets.all(SushiSpace.md),
      decoration: SushiDeco.card(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SushiColors.red),
          const SizedBox(width: SushiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SushiTypo.caption),
                const SizedBox(height: SushiSpace.xs),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SushiTypo.h4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderDetailsItemCard(PosOrderItem item) {
    final isGlovo = item.priceType == 'glovo';
    final hasGlovoBasePrice =
        item.glovoBasePrice != null && item.glovoBasePrice! > 0;
    final displayName = item.productName.startsWith('[LOCAL] ')
        ? item.productName.substring(8)
        : item.productName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGlovo ? const Color(0xFF00897B) : const Color(0xFFE0E0E0),
          width: isGlovo ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: SushiTypo.h4),
                if (isGlovo && hasGlovoBasePrice) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.motorcycle,
                              size: 12,
                              color: Color(0xFF00897B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Glovo: ${_money(item.glovoBasePrice!)} + ${_money(item.unitPrice - item.glovoBasePrice!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00897B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (isGlovo) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withAlpha(35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Glovo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x ${_money(item.isOffered() ? 0.0 : item.unitPrice)}',
                style: SushiTypo.bodySm,
              ),
              Text(
                _money(item.isOffered() ? 0.0 : item.quantity * item.unitPrice),
                style: SushiTypo.price.copyWith(
                  color: isGlovo ? const Color(0xFF00897B) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForOrderStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      default:
        return value;
    }
  }

  String _labelForPaymentStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'paid':
        return 'Payée';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  Color _orderStatusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return SushiColors.orange;
      case 'confirmed':
        return const Color(0xFF7E57C2);
      case 'cancelled':
        return SushiColors.error;
      default:
        return SushiColors.red;
    }
  }

  String _labelForChannel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'api':
        return 'Mobile API';
      case 'web':
        return 'Web';
      case 'kiosk':
        return 'Kiosk';
      case 'pos':
      default:
        return 'POS';
    }
  }

  Widget _topRightStats(PosController pos) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusBadge(
          'CA ${_money(pos.ordersToday.fold<double>(0.0, (s, o) => s + o.totalPrice))}',
          SushiColors.red,
        ),
        const SizedBox(width: SushiSpace.md),
        TextButton.icon(
          onPressed: _isSaving || _isNavigatingAway
              ? null
              : () {
                  pos.lock();
                  Get.offAllNamed('/pos');
                },
          icon: const Icon(Icons.lock, size: 16, color: SushiColors.red),
          label: Text('Verrouiller', style: SushiTypo.h4),
          style: _lockButtonStyle(),
        ),
      ],
    );
  }

  Widget _orderInfoBar(PosController pos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: SushiDeco.card(),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statusBadge(
            _labelForFulfillment(pos.fulfillmentType),
            SushiColors.red,
          ),
          Text(
            'Table : ${pos.tableNumber ?? '-'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SushiColors.ink,
            ),
          ),
          Text(
            'Client : ${(pos.customerName?.trim().isEmpty ?? true) ? '-' : pos.customerName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SushiColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      decoration: SushiDeco.badge(bg: color),
      child: Text(
        text,
        style: SushiTypo.tag.copyWith(color: SushiColors.white),
      ),
    );
  }

  Widget _swipeAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool alignLeft,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withAlpha(46),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment: alignLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartLineItem(PosController pos, CartItem item) {
    // ✅ FIX: Envelopper avec GestureDetector pour ajouter long press
    return GestureDetector(
      onLongPress: () =>
          _showItemOptions(context, pos, item.product, cartItem: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.blancPur.withAlpha(220),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grisLeger),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.priceType == 'glovo') ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SushiColors.red.withAlpha(18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: SushiColors.red.withAlpha(65),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'GLOVO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: SushiColors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.serviceCourseLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.purple.withAlpha(65),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        item.serviceCourseLabel!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                  if (item.priceType == 'glovo' && item.basePrice != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _money(item.basePrice!),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkFaint,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '+ ${_money(item.unitPrice - item.basePrice!)} (Glovo)',
                          style: AppTypography.bodySmall.copyWith(
                            color: SushiColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _money(item.unitPrice),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkFaint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  // ✅ Afficher la note et le type de service
                  if (item.itemNote != null && item.itemNote!.isNotEmpty ||
                      item.serviceCourseLabel != null &&
                          item.serviceCourseLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.itemNote != null &&
                              item.itemNote!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SushiColors.orange.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: SushiColors.orange.withAlpha(70),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.note_outlined,
                                    size: 12,
                                    color: SushiColors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.itemNote!,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: SushiColors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.serviceCourseLabel != null &&
                              item.serviceCourseLabel!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SushiColors.redLight.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: SushiColors.redLight.withAlpha(70),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.restaurant_outlined,
                                    size: 12,
                                    color: SushiColors.redLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.serviceCourseLabel!,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: SushiColors.redLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => pos.removeFromCart(
                item.product,
                groupNumber: item.groupNumber,
              ),
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            SizedBox(
              width: 22,
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () =>
                  pos.addToCart(item.product, groupNumber: item.groupNumber),
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _money(item.lineTotal),
              style: const TextStyle(
                color: SushiColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCustomerInfo(PosController pos) async {
    final nameController = TextEditingController(text: pos.customerName ?? '');
    final phoneController = TextEditingController(
      text: pos.customerPhone ?? '',
    );
    final addressController = TextEditingController(
      text: pos.deliveryAddress ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Infos client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                if (pos.fulfillmentType == 'delivery')
                  TextField(
                    controller: addressController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                pos.setCustomerInfo(
                  name: nameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectPaymentMethod(PosController pos) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Mode de paiement'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cash'),
              child: const Text('Espèces'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'tpe'),
              child: const Text('TPE'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'en_compte'),
              child: const Text('En compte'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      pos.setPaymentMethod(selected);
    }
  }

  String _labelForFulfillment(String value) {
    switch (value) {
      case 'delivery':
        return 'Livraison';
      case 'pickup':
        return 'À emporter';
      case 'on_site':
      default:
        return 'Sur place';
    }
  }

  Widget _itemTab({
    required IconData icon,
    required String title,
    required bool isActive,
    String? imagePath,
  }) {
    const accentColor = SushiColors.red;
    const accentLight = Color(0x1FE8003D);
    const blackMedium = SushiColors.inkMid;
    const white = Color(0xFFFFFFFF);
    const grayLight = Color(0xFFE0E0E0);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive ? accentLight : white.withAlpha(170),
        border: Border.all(
          color: isActive ? accentColor : grayLight,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imagePath != null && imagePath.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildCategoryImage(imagePath, icon),
              ),
            )
          else
            Icon(icon, color: isActive ? accentColor : blackMedium, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? accentColor : blackMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    return _imageFromPath(
      imagePath,
      placeholder: _imagePlaceholder(),
      loadingWidget: _imageSkeleton(),
    );
  }

  Widget _buildCategoryImage(String imagePath, IconData fallbackIcon) {
    return _imageFromPath(
      imagePath,
      placeholder: Icon(fallbackIcon, color: SushiColors.red, size: 30),
      errorWidget: Icon(fallbackIcon, color: SushiColors.red, size: 30),
      loadingWidget: _imageSkeleton(),
    );
  }

  String? _networkUrl(String? path) {
    final normalized = normalizeImagePath(path, baseUrl: AppConstant.baseUrl);
    if (normalized == null) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return null;
  }

  Widget _imageFromPath(
    String? path, {
    required Widget placeholder,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    final url = _networkUrl(path);
    if (url != null) {
      final cachedPath = ImageCacheService.instance.cachedFilePathForUrlSync(
        url,
      );
      if (cachedPath != null) {
        return Image.file(
          File(cachedPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? placeholder;
          },
        );
      }
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, progress) => loadingWidget ?? _imageLoader(),
        errorWidget: (context, error, stackTrace) => errorWidget ?? placeholder,
      );
    }
    final imageProvider = resolveImageProvider(
      path,
      baseUrl: AppConstant.baseUrl,
    );
    if (imageProvider == null) {
      return placeholder;
    }
    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? placeholder;
      },
    );
  }

  Widget _imageLoader() {
    return const Center(child: _GradientSpinner(size: 24, strokeWidth: 2));
  }

  Widget _imageSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: _PulseSkeleton(borderRadius: 10),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloudDancer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.grisModerne.withAlpha(180),
        size: 40,
      ),
    );
  }

  Widget _topMenu({
    required String title,
    required String subTitle,
    required Widget action,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.blancPur.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisLeger),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: SushiColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SushiColors.inkMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: SushiColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SushiColors.inkMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: action),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charbon,
                  fontSize: 12,
                )
              : AppTypography.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SushiColors.green,
                  fontSize: 14,
                )
              : const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SushiColors.ink,
                  fontSize: 14,
                ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final pos = Get.find<PosController>();
    final busy = pos.isCreatingOrder && icon == Icons.check;
    final isDisabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [SushiColors.red, SushiColors.redDark],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: isDisabled
                ? Colors.transparent
                : SushiColors.redLight.withAlpha(77),
            highlightColor: isDisabled
                ? Colors.transparent
                : SushiColors.red.withAlpha(45),
            onTap: busy || isDisabled ? null : onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enregistrement...',
                    style: AppTypography.button,
                    maxLines: 1,
                  ),
                ] else ...[
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.button,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAssignmentCard(
    BuildContext context,
    PosController pos,
    PosOrder order,
  ) {
    return FutureBuilder<OrderDelivery?>(
      future: pos.getOrderDelivery(order.id),
      builder: (context, snapshot) {
        final delivery = snapshot.data;
        final hasLivreur = delivery?.livreurId != null;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: hasLivreur
                ? AppColors.burntOrange.withAlpha(25)
                : AppColors.grisPale,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLivreur ? AppColors.burntOrange : AppColors.grisLeger,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasLivreur
                        ? Icons.local_shipping
                        : Icons.local_shipping_outlined,
                    color: hasLivreur
                        ? AppColors.burntOrange
                        : AppColors.charbon,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasLivreur ? 'Livreur assigné' : 'Assigner un livreur',
                      style: SushiTypo.h4.copyWith(
                        color: hasLivreur
                            ? AppColors.burntOrange
                            : AppColors.charbon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (hasLivreur) ...[
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.burntOrange,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    delivery!.livreurName ?? 'Livreur',
                    style: SushiTypo.bodyLg,
                  ),
                  subtitle: Text(
                    delivery.livreurPhone ?? '',
                    style: SushiTypo.bodySm,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusBadge(
                        _labelForDeliveryStatus(delivery.status),
                        AppColors.burntOrange,
                      ),
                      if (delivery.assignedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Assigné le ${_formatDate(delivery.assignedAt!)}',
                          style: SushiTypo.bodySm,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (delivery.status == 'assigned')
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await pos.markOrderPickedUp(order);
                          if (result != null && mounted) {
                            OrderSyncService().syncOrderStatus(
                              orderId: order.id,
                              status: order.status,
                              deliveryStatus: 'picked_up',
                            );
                            _notify(
                              'Le livreur a pris en charge la commande',
                              title: 'Pris en charge',
                              type: POSSnackType.success,
                            );
                          }
                        },
                        icon: const Icon(Icons.touch_app_outlined, size: 16),
                        label: const Text('Pris en charge'),
                      ),
                    if (delivery.status == 'picked_up')
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await pos.markOrderDelivered(order);
                          if (result != null && mounted) {
                            OrderSyncService().syncOrderStatus(
                              orderId: order.id,
                              status: 'delivered',
                              deliveryStatus: 'delivered',
                            );
                            _notify(
                              'Commande marquée comme livrée',
                              title: 'Livrée',
                              type: POSSnackType.success,
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Livrée'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _showAssignLivreurDialog(
                        context,
                        pos,
                        order,
                        delivery,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
              ] else ...[
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.grisLeger,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.charbon,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Aucun livreur assigné',
                    style: SushiTypo.bodyMd.copyWith(
                      color: AppColors.grisModerne,
                    ),
                  ),
                  subtitle: Text(
                    'Assignez un livreur pour cette commande',
                    style: SushiTypo.bodySm,
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () =>
                        _showAssignLivreurDialog(context, pos, order, null),
                    icon: const Icon(Icons.add_outlined, size: 16),
                    label: const Text('Assigner'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAssignLivreurDialog(
    BuildContext context,
    PosController pos,
    PosOrder order,
    OrderDelivery? existingDelivery,
  ) {
    final deliveryController = Get.find<DeliveryController>();
    int? selectedLivreurId;
    String? selectedLivreurName;
    String? selectedLivreurPhone;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assigner un livreur'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${order.id}', style: SushiTypo.bodyMd),
                const SizedBox(height: AppSpacing.md),
                Text('Sélectionnez un livreur :', style: SushiTypo.bodySm),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 300,
                  child: Obx(() {
                    final deliveries = deliveryController.deliveries;
                    if (deliveries.isEmpty) {
                      return const Center(
                        child: Text('Aucun livreur disponible'),
                      );
                    }
                    return ListView.builder(
                      itemCount: deliveries.length,
                      itemBuilder: (context, index) {
                        final livreur = deliveries[index];
                        final isSelected = selectedLivreurId == livreur.id;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          leading: CircleAvatar(
                            backgroundColor: livreur.isActive
                                ? AppColors.burntOrange
                                : AppColors.grisLeger,
                            child: Icon(
                              Icons.person,
                              color: livreur.isActive
                                  ? Colors.white
                                  : AppColors.grisModerne,
                            ),
                          ),
                          title: Text(
                            livreur.name,
                            style: TextStyle(
                              color: livreur.isActive
                                  ? null
                                  : AppColors.grisModerne,
                              decoration: livreur.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(livreur.phone),
                          onTap: () {
                            setDialogState(() {
                              selectedLivreurId = livreur.id;
                              selectedLivreurName = livreur.name;
                              selectedLivreurPhone = livreur.phone;
                            });
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedLivreurId == null
                  ? null
                  : () async {
                      final result = await pos.assignLivreurToOrder(
                        order: order,
                        livreurId: selectedLivreurId!,
                        livreurName: selectedLivreurName,
                        livreurPhone: selectedLivreurPhone,
                      );
                      if (!mounted || !dialogContext.mounted) return;
                      if (result != null) {
                        Navigator.pop(dialogContext);
                        _notify(
                          '$selectedLivreurName a été assigné à la commande',
                          title: 'Livreur assigné',
                          type: POSSnackType.success,
                        );
                      } else {
                        _notify(
                          pos.error ?? 'Échec de l\'assignation',
                          title: 'Erreur',
                          type: POSSnackType.error,
                        );
                      }
                    },
              child: const Text('Assigner'),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForDeliveryStatus(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigné';
      case 'picked_up':
        return 'Pris en charge';
      case 'delivered':
        return 'Livrée';
      default:
        return 'En attente';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _showCustomerSelectionDialog(PosController pos) async {
    final phoneController = TextEditingController();
    final nameController = TextEditingController(text: pos.customerName ?? '');
    final addressController = TextEditingController(
      text: pos.deliveryAddress ?? '',
    );
    final glovoOrderNumberController = TextEditingController(
      text: pos.glovoOrderNumber ?? '',
    );
    List<Customer> searchResults = [];
    Customer? selectedCustomer;
    try {
      final result =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, setDialogState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: EdgeInsets.zero,
                content: Container(
                  width: 500,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SushiColors.bg,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: SushiColors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations Client',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: SushiColors.ink,
                                    ),
                                  ),
                                  Text(
                                    pos.fulfillmentType == 'delivery'
                                        ? 'Livraison'
                                        : 'À emporter',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: SushiColors.inkMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: SushiColors.ink,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Téléphone (optionnel)',
                                  labelStyle: const TextStyle(
                                    fontSize: 13,
                                    color: SushiColors.inkMid,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                    color: SushiColors.inkMid,
                                  ),
                                  suffixIcon: phoneController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            phoneController.clear();
                                            setDialogState(() {
                                              searchResults = [];
                                              selectedCustomer = null;
                                              nameController.clear();
                                              addressController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: selectedCustomer != null
                                      ? SushiColors.greenPale
                                      : SushiColors.white,
                                  contentPadding: const EdgeInsets.all(12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: selectedCustomer != null
                                          ? SushiColors.green
                                          : SushiColors.divider,
                                    ),
                                  ),
                                ),
                                onChanged: (value) async {
                                  if (value.trim().isEmpty) {
                                    setDialogState(() {
                                      searchResults = [];
                                      selectedCustomer = null;
                                    });
                                    return;
                                  }
                                  final results =
                                      await DatabaseService.searchCustomers(
                                        value,
                                      );
                                  setDialogState(() {
                                    searchResults = results.take(5).toList();
                                  });
                                },
                              ),
                              if (searchResults.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: SushiColors.divider,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final customer = searchResults[index];
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          backgroundColor: SushiColors.redPale,
                                          child: Icon(
                                            Icons.person,
                                            size: 18,
                                            color: SushiColors.red,
                                          ),
                                        ),
                                        title: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${customer.phone}${customer.address != null && customer.address!.isNotEmpty ? ' • ${customer.address}' : ''}',
                                          style: const TextStyle(fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          '${customer.orderCount} cmd',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: SushiColors.inkMid,
                                          ),
                                        ),
                                        onTap: () {
                                          setDialogState(() {
                                            selectedCustomer = customer;
                                            phoneController.text =
                                                customer.phone;
                                            nameController.text = customer.name;
                                            addressController.text =
                                                customer.address ?? '';
                                            searchResults = [];
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                              if (selectedCustomer != null &&
                                  searchResults.isEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: SushiColors.greenPale,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: SushiColors.green,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: SushiColors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Client sélectionné',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: SushiColors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        selectedCustomer!.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        selectedCustomer!.phone,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (selectedCustomer!.address != null &&
                                          selectedCustomer!.address!.isNotEmpty)
                                        Text(
                                          selectedCustomer!.address!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: nameController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: SushiColors.ink,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Nom complet (optionnel)',
                                  labelStyle: const TextStyle(
                                    fontSize: 13,
                                    color: SushiColors.inkMid,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: SushiColors.inkMid,
                                  ),
                                  filled: true,
                                  fillColor: SushiColors.white,
                                  contentPadding: const EdgeInsets.all(12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: SushiColors.divider,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (pos.fulfillmentType == 'delivery')
                                TextField(
                                  controller: addressController,
                                  keyboardType: TextInputType.streetAddress,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: SushiColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Adresse de livraison (optionnel)',
                                    labelStyle: const TextStyle(
                                      fontSize: 13,
                                      color: SushiColors.inkMid,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: SushiColors.inkMid,
                                    ),
                                    filled: true,
                                    fillColor: SushiColors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: SushiColors.divider,
                                      ),
                                    ),
                                  ),
                                ),
                              if (pos.fulfillmentType == 'delivery' &&
                                  pos.isGlovoDelivery) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: glovoOrderNumberController,
                                  keyboardType: TextInputType.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: SushiColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Numéro commande Glovo (optionnel)',
                                    labelStyle: const TextStyle(
                                      fontSize: 13,
                                      color: SushiColors.inkMid,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 20,
                                      color: SushiColors.inkMid,
                                    ),
                                    filled: true,
                                    fillColor: SushiColors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: SushiColors.divider,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SushiColors.bg,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                pos.setCustomerInfo(
                                  name: nameController.text,
                                  phone: phoneController.text,
                                  address: addressController.text,
                                );
                                if (pos.fulfillmentType == 'delivery' &&
                                    pos.isGlovoDelivery) {
                                  pos.setGlovoOrderNumber(
                                    glovoOrderNumberController.text,
                                  );
                                } else {
                                  pos.setGlovoOrderNumber(null);
                                }
                                Navigator.pop(dialogContext, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SushiColors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Valider'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ) ??
          false;
      return result;
    } finally {
      phoneController.dispose();
      nameController.dispose();
      addressController.dispose();
      glovoOrderNumberController.dispose();
    }
  }
}

// ignore_for_file: unused_element
