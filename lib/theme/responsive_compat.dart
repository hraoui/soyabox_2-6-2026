import 'package:flutter/material.dart';
import '../utils/responsive_design.dart';

/// 🎨 Wrapper de compatibilité pour transition responsive
/// Utilise les valeurs responsives quand BuildContext est disponible
/// Fallback aux constantes sinon
class SushiRadiusCompat {
  // Constantes originales (pour compatibilité)
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  // Versions responsives
  static double smResp(BuildContext context) =>
      sm * ResponsiveDesign.scale(context);
  static double mdResp(BuildContext context) =>
      md * ResponsiveDesign.scale(context);
  static double lgResp(BuildContext context) =>
      lg * ResponsiveDesign.scale(context);
  static double xlResp(BuildContext context) =>
      xl * ResponsiveDesign.scale(context);
  static double xxlResp(BuildContext context) =>
      xxl * ResponsiveDesign.scale(context);
  static double fullResp(BuildContext context) =>
      full * ResponsiveDesign.scale(context);
}

class SushiSpaceCompat {
  // Constantes originales (pour compatibilité)
  static const double xs = 2.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double xl = 24.0;
  static const double xxl = 20.0;
  static const double xxxl = 30.0;

  // Versions responsives
  static double xsResp(BuildContext context) =>
      xs * ResponsiveDesign.scale(context);
  static double smResp(BuildContext context) =>
      sm * ResponsiveDesign.scale(context);
  static double mdResp(BuildContext context) =>
      md * ResponsiveDesign.scale(context);
  static double lgResp(BuildContext context) =>
      lg * ResponsiveDesign.scale(context);
  static double xlResp(BuildContext context) =>
      xl * ResponsiveDesign.scale(context);
  static double xxlResp(BuildContext context) =>
      xxl * ResponsiveDesign.scale(context);
  static double xxxlResp(BuildContext context) =>
      xxxl * ResponsiveDesign.scale(context);
}
