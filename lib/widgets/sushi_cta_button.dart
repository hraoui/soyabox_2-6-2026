import 'package:flutter/material.dart';
import '../theme/sushi_design.dart';

/// 🎨 Sushi CTA Button - Call-to-Action Button
class SushiCTAButton extends StatelessWidget {
  const SushiCTAButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.textColor,
    this.height,
    this.fullWidth = true,
    this.icon,
  });

  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? height;
  final bool fullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? SushiColors.red;
    final buttonTextColor = textColor ?? SushiColors.white;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 52.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: buttonTextColor,
          elevation: 4,
          shadowColor: buttonColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SushiRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SushiSpace.xl,
            vertical: SushiSpace.md,
          ),
        ),
        onPressed: onPressed,
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: SushiSpace.sm),
                  child,
                ],
              )
            : child,
      ),
    );
  }
}

/// 🎨 Sushi Button Styles
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

  static ButtonStyle destructive() {
    return ElevatedButton.styleFrom(
      backgroundColor: SushiColors.error,
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
      shadowColor: SushiColors.error.withOpacity(0.4),
    );
  }

  static ButtonStyle success() {
    return ElevatedButton.styleFrom(
      backgroundColor: SushiColors.success,
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
      shadowColor: SushiColors.success.withOpacity(0.4),
    );
  }
}
