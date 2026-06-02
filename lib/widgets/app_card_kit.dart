import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sushi_design.dart';

class AppCardGrid {
  const AppCardGrid._();

  static int columnsForWidth(
    double width, {
    int compact = 1,
    int tablet = 2,
    int desktop = 3,
    int wide = 4,
  }) {
    if (width >= 1500) return wide;
    if (width >= 1100) return desktop;
    if (width >= 760) return tablet;
    return compact;
  }

  static SliverGridDelegateWithMaxCrossAxisExtent entityDelegate({
    required double width,
    double compactMaxExtent = 560,
    double regularMaxExtent = 420,
    double wideMaxExtent = 360,
    double compactRatio = 1.18,
    double regularRatio = 1.0,
    double wideRatio = 0.92,
    double spacing = SushiSpace.lg,
  }) {
    if (width < 900) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compactMaxExtent,
        childAspectRatio: compactRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      );
    }
    if (width < 1320) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: regularMaxExtent,
        childAspectRatio: regularRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      );
    }
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: wideMaxExtent,
      childAspectRatio: wideRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(SushiSpace.xl),
    this.minHeight,
    this.selected = false,
    this.radius = SushiRadius.xl,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.shadow,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? minHeight;
  final bool selected;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? SushiColors.white) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            borderColor ?? (selected ? SushiColors.red : SushiColors.divider),
        width: selected ? 1.8 : 1,
      ),
      boxShadow: shadow ?? (selected ? SushiShadow.elevated : SushiShadow.card),
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return Container(
        clipBehavior: clipBehavior,
        decoration: decoration,
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        splashColor: SushiColors.redPale,
        highlightColor: SushiColors.redSurface,
        onTap: onTap,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

class AppWrapGrid extends StatelessWidget {
  const AppWrapGrid({
    super.key,
    required this.children,
    this.minChildWidth = 320,
    this.maxChildWidth = 420,
    this.spacing = SushiSpace.lg,
    this.runSpacing = SushiSpace.lg,
    this.maxColumns,
    this.itemCount = 0,
    this.itemBuilder = _defaultItemBuilder,
  });

  const AppWrapGrid.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minChildWidth = 320,
    this.maxChildWidth = 420,
    this.spacing = SushiSpace.lg,
    this.runSpacing = SushiSpace.lg,
    this.maxColumns,
    this.children,
  });

  static Widget _defaultItemBuilder(BuildContext context, int index) {
    return const SizedBox.shrink();
  }

  final List<Widget>? children;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minChildWidth;
  final double maxChildWidth;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final computedColumns = math.max(
          1,
          ((width + spacing) / (minChildWidth + spacing)).floor(),
        );
        final columns = maxColumns == null
            ? computedColumns
            : math.min(computedColumns, maxColumns!);
        final childWidth = math.min(
          maxChildWidth,
          (width - (spacing * (columns - 1))) / columns,
        );
        final builtChildren =
            children ??
            List<Widget>.generate(
              itemCount,
              (index) => itemBuilder(context, index),
            );

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in builtChildren)
              SizedBox(width: childWidth, child: child),
          ],
        );
      },
    );
  }
}

class AppCardIconBadge extends StatelessWidget {
  const AppCardIconBadge({
    super.key,
    required this.icon,
    this.accent = SushiColors.red,
    this.background = SushiColors.redSurface,
    this.size = 58,
    this.iconSize = 28,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SushiRadius.lg),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

class AppFeatureCard extends StatelessWidget {
  const AppFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.footerLabel,
    this.footerIcon,
    this.accent = SushiColors.red,
    this.selected = false,
    this.centered = false,
    this.minHeight,
    this.showArrow = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? footerLabel;
  final IconData? footerIcon;
  final Color accent;
  final bool selected;
  final bool centered;
  final double? minHeight;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return AppSurfaceCard(
      onTap: onTap,
      selected: selected,
      minHeight: minHeight,
      padding: const EdgeInsets.all(SushiSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Align(
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: AppCardIconBadge(icon: icon, accent: accent),
          ),
          const SizedBox(height: SushiSpace.lg),
          Text(
            title,
            textAlign: textAlign,
            style: SushiTypo.h2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: SushiSpace.sm),
          Text(
            description,
            textAlign: textAlign,
            style: SushiTypo.bodySm.copyWith(fontSize: 13.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (footerLabel != null || showArrow) ...[
            const SizedBox(height: SushiSpace.lg),
            Row(
              mainAxisAlignment: centered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (footerLabel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SushiSpace.sm,
                      vertical: SushiSpace.xs,
                    ),
                    decoration: SushiDeco.badge(bg: SushiColors.redPale),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (footerIcon != null) ...[
                          Icon(footerIcon, size: 14, color: accent),
                          const SizedBox(width: SushiSpace.xs),
                        ],
                        Text(
                          footerLabel!,
                          style: SushiTypo.tag.copyWith(color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showArrow) ...[
                  if (!centered) const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: SushiColors.inkMid,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent = SushiColors.red,
    this.highlight = false,
    this.minHeight,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color accent;
  final bool highlight;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final gradient = highlight
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, Color.alphaBlend(Colors.white24, accent)],
          )
        : null;
    final foreground = highlight ? SushiColors.white : SushiColors.ink;

    return AppSurfaceCard(
      minHeight: minHeight,
      gradient: gradient,
      backgroundColor: highlight ? accent : SushiColors.white,
      borderColor: highlight ? accent : SushiColors.divider,
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardIconBadge(
            icon: icon,
            accent: highlight ? SushiColors.white : accent,
            background: highlight
                ? Colors.white.withValues(alpha: 0.14)
                : SushiColors.redSurface,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(height: SushiSpace.md),
          Text(
            label,
            style: SushiTypo.caption.copyWith(
              color: highlight ? SushiColors.white : SushiColors.inkMid,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: SushiSpace.xs),
          Text(
            value,
            style: SushiTypo.h1.copyWith(
              color: foreground,
              fontSize: 26,
              height: 1.05,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: SushiSpace.xs),
            Text(
              subtitle!,
              style: SushiTypo.bodySm.copyWith(
                color: highlight ? SushiColors.white : SushiColors.inkMid,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
