import 'package:flutter/material.dart';

/// 🎨 Système Responsive Professionnel pour POS
/// Optimisé pour la résolution de base : 1024 × 768 (ratio 4:3)
/// Orientation : Paysage (landscape)
class ResponsiveDesign {
  ResponsiveDesign._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RÉFÉRENCES DE BASE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Résolution de référence (design base)
  static const double baseWidth = 1024.0;
  static const double baseHeight = 768.0;
  static const double baseAspectRatio = baseWidth / baseHeight; // 1.333 (4:3)
  
  /// Seuil minimum pour le mode paysage
  static const double landscapeThreshold = 1.2;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FACTEURS D'ÉCHELLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Facteur d'échle horizontal basé sur la largeur
  static double scaleX(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width / baseWidth;
  }
  
  /// Facteur d'échle vertical basé sur la hauteur
  static double scaleY(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height / baseHeight;
  }
  
  /// Facteur d'échle principal (utilise le plus petit pour préserver les proportions)
  static double scale(BuildContext context) {
    return scaleX(context).clamp(0.8, 1.5);
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ESPACEMENTS RESPONSIVES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Espacement extra-small : 4px → adaptatif
  static double xs(BuildContext context) => 4.0 * scale(context);
  
  /// Espacement small : 8px → adaptatif
  static double sm(BuildContext context) => 8.0 * scale(context);
  
  /// Espacement medium : 12px → adaptatif
  static double md(BuildContext context) => 12.0 * scale(context);
  
  /// Espacement large : 16px → adaptatif
  static double lg(BuildContext context) => 16.0 * scale(context);
  
  /// Espacement extra-large : 24px → adaptatif
  static double xl(BuildContext context) => 24.0 * scale(context);
  
  /// Espacement extra-extra-large : 32px → adaptatif
  static double xxl(BuildContext context) => 32.0 * scale(context);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TAILLES DE POLICE RESPONSIVES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Très petit : 10px → adaptatif
  static double fontSizeXs(BuildContext context) => 10.0 * scale(context);
  
  /// Petit : 12px → adaptatif
  static double fontSizeSm(BuildContext context) => 12.0 * scale(context);
  
  /// Medium : 14px → adaptatif
  static double fontSizeMd(BuildContext context) => 14.0 * scale(context);
  
  /// Grand : 16px → adaptatif
  static double fontSizeLg(BuildContext context) => 16.0 * scale(context);
  
  /// Très grand : 18px → adaptatif
  static double fontSizeXl(BuildContext context) => 18.0 * scale(context);
  
  /// Extra grand : 24px → adaptatif
  static double fontSizeXxl(BuildContext context) => 24.0 * scale(context);
  
  /// Display : 32px → adaptatif
  static double fontSizeDisplay(BuildContext context) => 32.0 * scale(context);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RAYONS RESPONSIVES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Petit rayon : 6px → adaptatif
  static double radiusSm(BuildContext context) => 6.0 * scale(context);
  
  /// Medium rayon : 10px → adaptatif
  static double radiusMd(BuildContext context) => 10.0 * scale(context);
  
  /// Grand rayon : 14px → adaptatif
  static double radiusLg(BuildContext context) => 14.0 * scale(context);
  
  /// Extra grand rayon : 20px → adaptatif
  static double radiusXl(BuildContext context) => 20.0 * scale(context);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TAILLES DE BOUTONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Hauteur de bouton small : 36px → adaptatif
  static double buttonHeightSm(BuildContext context) => 36.0 * scale(context);
  
  /// Hauteur de bouton medium : 44px → adaptatif
  static double buttonHeightMd(BuildContext context) => 44.0 * scale(context);
  
  /// Hauteur de bouton large : 52px → adaptatif
  static double buttonHeightLg(BuildContext context) => 52.0 * scale(context);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // GRILLE RESPONSIVE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Nombre de colonnes selon la largeur
  static int gridColumns(double width) {
    if (width < 600) return 1;      // Mobile
    if (width < 900) return 2;      // Small tablet
    if (width < 1200) return 3;     // Tablet 1024×768
    if (width < 1600) return 4;     // Desktop
    return 5;                       // Large desktop
  }
  
  /// Largeur de carte optimale pour la grille
  static double cardWidth(double width, {int columns = 3}) {
    final cols = gridColumns(width);
    final spacing = 16.0 * 2; // Espacement entre cartes
    return (width - (spacing * (cols - 1))) / cols;
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // VERIFICATIONS DE TYPE D'APPAREIL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Est-ce que l'appareil est en mode paysage ?
  static bool isLandscape(BuildContext context) {
    final aspectRatio = MediaQuery.of(context).size.aspectRatio;
    return aspectRatio >= landscapeThreshold;
  }
  
  /// Est-ce que l'appareil est un mobile ?
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }
  
  /// Est-ce que l'appareil est une tablette ?
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }
  
  /// Est-ce que l'appareil est un desktop ?
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1200;
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WIDGETS RESPONSIVES PRÊTS À L'EMPLOI
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Widget qui adapte son enfant selon le contexte
  static Widget adaptiveScale({
    required BuildContext context,
    required Widget child,
    double? scaleFactor,
  }) {
    final scale = scaleFactor ?? ResponsiveDesign.scale(context);
    return Transform.scale(
      scale: scale,
      child: child,
    );
  }
  
  /// Padding responsive standard
  static EdgeInsets responsivePadding(BuildContext context) {
    final scale = ResponsiveDesign.scale(context);
    return EdgeInsets.all(16.0 * scale);
  }
  
  /// Padding d'écran standard pour les pages POS
  static EdgeInsets screenPadding(BuildContext context) {
    final scale = ResponsiveDesign.scale(context);
    return EdgeInsets.symmetric(
      horizontal: 20.0 * scale,
      vertical: 12.0 * scale,
    );
  }
}

/// Extension pour faciliter l'utilisation
extension ResponsiveContext on BuildContext {
  double get responsiveScale => ResponsiveDesign.scale(this);
  double get responsiveXs => ResponsiveDesign.xs(this);
  double get responsiveSm => ResponsiveDesign.sm(this);
  double get responsiveMd => ResponsiveDesign.md(this);
  double get responsiveLg => ResponsiveDesign.lg(this);
  double get responsiveXl => ResponsiveDesign.xl(this);
  double get responsiveXxl => ResponsiveDesign.xxl(this);
  
  double get fontSizeXs => ResponsiveDesign.fontSizeXs(this);
  double get fontSizeSm => ResponsiveDesign.fontSizeSm(this);
  double get fontSizeMd => ResponsiveDesign.fontSizeMd(this);
  double get fontSizeLg => ResponsiveDesign.fontSizeLg(this);
  double get fontSizeXl => ResponsiveDesign.fontSizeXl(this);
  
  double get radiusSm => ResponsiveDesign.radiusSm(this);
  double get radiusMd => ResponsiveDesign.radiusMd(this);
  double get radiusLg => ResponsiveDesign.radiusLg(this);
  
  double get buttonHeightSm => ResponsiveDesign.buttonHeightSm(this);
  double get buttonHeightMd => ResponsiveDesign.buttonHeightMd(this);
  double get buttonHeightLg => ResponsiveDesign.buttonHeightLg(this);
  
  bool get isLandscape => ResponsiveDesign.isLandscape(this);
  bool get isMobile => ResponsiveDesign.isMobile(this);
  bool get isTablet => ResponsiveDesign.isTablet(this);
  bool get isDesktop => ResponsiveDesign.isDesktop(this);
  
  EdgeInsets get responsivePadding => ResponsiveDesign.responsivePadding(this);
  EdgeInsets get screenPadding => ResponsiveDesign.screenPadding(this);
}
