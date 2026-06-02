import 'package:flutter/material.dart';
import 'sushi_design.dart';

/// 🎨 Alias de compatibilité pour transition en douceur
/// Les anciennes références App* pointent vers le nouveau système Sushi

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COULEURS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppColors {
  // Couleurs Sushi (mapping direct)
  static const Color red = SushiColors.red;
  static const Color redDark = SushiColors.redDark;
  static const Color redLight = SushiColors.redLight;
  static const Color green = SushiColors.green;
  static const Color teal = SushiColors.teal;
  static const Color orange = SushiColors.orange;
  static const Color yellow = SushiColors.yellow;

  // Couleurs neutres
  static const Color charbon = SushiColors.inkSoft;
  static const Color blancPur = SushiColors.white;
  static const Color cloudDancer = SushiColors.bg;
  static const Color grisLeger = SushiColors.divider;
  static const Color grisPale = SushiColors.surface;
  static const Color grisModerne = SushiColors.inkLight;
  static const Color grisFonce = SushiColors.inkMid;
  static const Color inkFaint = SushiColors.inkFaint;

  // Couleurs accent
  static const Color terraCotta = SushiColors.red;
  static const Color bleuGris = SushiColors.teal;
  static const Color deepTeal = SushiColors.teal;
  static const Color burntOrange = SushiColors.orange;
  static const Color taupeDore = SushiColors.yellow;

  // Status
  static const Color success = SushiColors.success;
  static const Color warning = SushiColors.warning;
  static const Color error = SushiColors.error;
  static const Color info = SushiColors.info;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ESPACEMENTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppSpacing {
  static const double xs = 2.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double xl = 24.0;
  static const double xxl = 20.0;
  static const double xxxl = 30.0;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RAYONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TYPOGRAPHIE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTypography {
  static const TextStyle display = SushiTypo.display;
  static const TextStyle headline1 = SushiTypo.h1;
  static const TextStyle headline2 = SushiTypo.h2;
  static const TextStyle headline3 = SushiTypo.h3;
  static const TextStyle headline4 = SushiTypo.h4;
  static const TextStyle bodyLg = SushiTypo.bodyLg;
  static const TextStyle bodyMd = SushiTypo.bodyMd;
  static const TextStyle bodySm = SushiTypo.bodySm;
  static const TextStyle caption = SushiTypo.caption;
  static const TextStyle overline = SushiTypo.overline;
  static const TextStyle btnLg = SushiTypo.btnLg;
  static const TextStyle btnMd = SushiTypo.btnMd;
  static const TextStyle price = SushiTypo.price;
  static const TextStyle priceLg = SushiTypo.priceLg;

  // Alias pour compatibilité Material
  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm;
  static TextStyle get labelLarge => caption;
  static TextStyle get labelMedium => bodySm;
  static TextStyle get labelSmall => overline;
  static TextStyle get titleLarge => headline1;
  static TextStyle get titleMedium => headline2;
  static TextStyle get titleSmall => headline3;
  static TextStyle get button => btnMd;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHADOWS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppShadows {
  static const List<BoxShadow> card = SushiShadow.card;
  static const List<BoxShadow> button = SushiShadow.button;
  static const List<BoxShadow> elevated = SushiShadow.elevated;
  static const List<BoxShadow> bottomBar = SushiShadow.bottomBar;
  static const List<BoxShadow> cta = SushiShadow.ctaRed;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GRADIENTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppGradients {
  static const LinearGradient primary = SushiGradients.primary;
  static const LinearGradient background = SushiGradients.hero;
}
