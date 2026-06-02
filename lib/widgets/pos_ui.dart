import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sushi_design.dart';

/// Global key for ScaffoldMessenger to allow showing snacks from any context
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum POSSnackType { success, error, warning, info }

class POSViewport {
  const POSViewport._({required this.size, required this.isSquare});

  factory POSViewport.fromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
    );
    final usableHeight = math
        .max(1, constraints.maxHeight - safeBottom)
        .toDouble();

    return POSViewport._(
      size: Size(constraints.maxWidth, usableHeight),
      isSquare: constraints.maxWidth / usableHeight < 1.4,
    );
  }

  final Size size;
  final bool isSquare;

  double get compactPadding =>
      (size.shortestSide * 0.012).clamp(6.0, 8.0).toDouble();

  double get sectionTitleSize => isSquare ? 15 : 16;

  double get bodyFontSize => isSquare ? 13 : 14;

  double get itemExtent => isSquare ? 40 : 44;
}

class POSAdaptiveLayout extends StatelessWidget {
  const POSAdaptiveLayout({
    super.key,
    required this.squareBuilder,
    required this.wideBuilder,
  });

  final Widget Function(BuildContext context, POSViewport viewport)
  squareBuilder;
  final Widget Function(BuildContext context, POSViewport viewport) wideBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = POSViewport.fromConstraints(context, constraints);
        return viewport.isSquare
            ? POSSquareLayout(
                builder: (context) => squareBuilder(context, viewport),
              )
            : POSWideLayout(
                builder: (context) => wideBuilder(context, viewport),
              );
      },
    );
  }
}

class POSSquareLayout extends StatelessWidget {
  const POSSquareLayout({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

class POSWideLayout extends StatelessWidget {
  const POSWideLayout({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

class POSPageScaffold extends StatefulWidget {
  const POSPageScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.safeTop = false,
    this.resizeToAvoidBottomInset = false, // 🎹 Clavier flottant par défaut
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool safeTop;
  final bool resizeToAvoidBottomInset; // 🎹 Paramètre pour contrôler le clavier

  @override
  State<POSPageScaffold> createState() => _POSPageScaffoldState();
}

class _POSPageScaffoldState extends State<POSPageScaffold> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final bottomBar = widget.bottomNavigationBar;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? SushiColors.bg,
        appBar: widget.appBar,
        resizeToAvoidBottomInset:
            widget.resizeToAvoidBottomInset, // 🎹 Clavier flottant
        body: SafeArea(top: widget.safeTop, bottom: true, child: widget.body),
        bottomNavigationBar: bottomBar == null
            ? null
            : SafeArea(top: false, bottom: true, child: bottomBar),
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showPOSSnack(
  BuildContext context,
  String message, {
  String? title,
  POSSnackType type = POSSnackType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = <POSSnackType, Color>{
    POSSnackType.success: const Color(0xFF2E7D32),
    POSSnackType.error: const Color(0xFFC62828),
    POSSnackType.warning: const Color(0xFFE65100),
    POSSnackType.info: const Color(0xFFE8003D),
  };
  final icons = <POSSnackType, IconData>{
    POSSnackType.success: Icons.check_circle_outline,
    POSSnackType.error: Icons.error_outline,
    POSSnackType.warning: Icons.warning_amber_outlined,
    POSSnackType.info: Icons.info_outline,
  };

  ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);

  // Fallback to global key if context doesn't have a ScaffoldMessenger
  messenger ??= globalScaffoldMessengerKey.currentState;

  if (messenger == null) {
    // Silently fail if no messenger is available
    return null;
  }

  final mediaQuery = MediaQuery.of(context);
  final screenHeight = mediaQuery.size.height;
  final keyboardHeight = mediaQuery.viewInsets.bottom;
  final safeBottom = math.max(
    mediaQuery.padding.bottom,
    mediaQuery.viewPadding.bottom,
  );
  final bottomMargin = math
      .max(screenHeight * 0.12, keyboardHeight + safeBottom + 64)
      .clamp(72.0, 180.0);
  final displayMessage = title == null || title.trim().isEmpty
      ? message
      : '$title: $message';

  try {
    messenger.hideCurrentSnackBar();
  } catch (e) {
    // Ignore hideCurrentSnackBar errors
  }

  try {
    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: colors[type],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomMargin.toDouble(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Icon(icons[type], color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                textColor: Colors.white,
                label: actionLabel,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  } catch (e) {
    // Silently ignore snackbar errors
    return null;
  }
}
