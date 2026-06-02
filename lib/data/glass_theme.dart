import 'package:flutter/material.dart';
import '../theme/sushi_design.dart';

/// 🎨 Compatibility layer for Glass* APIs
/// Provides backward compatibility while migrating to responsive system

class GlassColors {
  static const Color sushi = SushiColors.red;
  static const Color sushiDark = SushiColors.redDark;
  static const Color sushiLight = SushiColors.redLight;

  static const Color redAccent = SushiColors.red;
  static const Color redAccentDark = SushiColors.redDark;
  static const Color redAccentLight = SushiColors.redLight;

  static const Color glassWhite = SushiColors.white;
  static const Color glassBorder = SushiColors.divider;
  static const Color glassHighlight = SushiColors.surface;
  static const Color glassLight = SushiColors.surface;
  static const Color glassMid = SushiColors.surface;
  static const Color glassDark = SushiColors.inkSoft;
  static const Color glassText = SushiColors.ink;
  static const Color glassShadow = SushiColors.ink;

  static const Color bgLight = SushiColors.bg;
  static const Color bgDark = SushiColors.inkSoft;
}

/// 🎨 Sushi Button Styles (compatibility layer)
/// Use SushiButtonStyle from sushi_design.dart instead
class SushiButtonStyle {
  static ButtonStyle primary() {
    return ElevatedButton.styleFrom(
      backgroundColor: SushiColors.red,
      foregroundColor: SushiColors.white,
      textStyle: SushiTypo.btnMd,
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.xl,
        vertical: SushiSpace.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SushiRadius.md),
      ),
      elevation: 4,
      shadowColor: SushiColors.red.withOpacity(0.4),
    );
  }

  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      foregroundColor: SushiColors.red,
      side: const BorderSide(color: SushiColors.red, width: 1.5),
      textStyle: SushiTypo.btnMd,
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.xl,
        vertical: SushiSpace.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SushiRadius.md),
      ),
    );
  }
}

class GlassTypography {
  static const TextStyle headline1 = SushiTypo.h1;
  static const TextStyle headline2 = SushiTypo.h2;
  static const TextStyle bodyRegular = SushiTypo.bodyLg;
  static const TextStyle bodySmall = SushiTypo.bodySm;
  static const TextStyle label = SushiTypo.caption;
  static const TextStyle button = SushiTypo.btnMd;
}

class GlassButtonStyle {
  static ButtonStyle primary() => SushiButtonStyle.primary();
  static ButtonStyle secondary() => SushiButtonStyle.secondary();
}

class GlassPane extends StatelessWidget {
  const GlassPane({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(SushiSpace.lg),
      decoration: decoration ?? SushiDeco.card(),
      child: child,
    );
  }
}

/// 🎨 Glass Theme Data - Compatibility layer
class GlassThemeData {
  static BoxDecoration glassContainerLight({
    double blurSigma = 0,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: GlassColors.glassWhite,
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      border: Border.all(
        color: borderColor ?? GlassColors.glassBorder,
        width: borderWidth,
      ),
      boxShadow: shadows ?? SushiShadow.card,
    );
  }

  static BoxDecoration glassContainerDark({
    double blurSigma = 0,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: GlassColors.glassDark,
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      border: Border.all(
        color: borderColor ?? GlassColors.glassBorder,
        width: borderWidth,
      ),
      boxShadow: SushiShadow.elevated,
    );
  }
}
