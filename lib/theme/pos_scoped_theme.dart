import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/glass_theme.dart';
import 'app_theme.dart';

ThemeData buildPosTheme(ThemeData base) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GlassColors.redAccent,
    primary: GlassColors.redAccent,
    secondary: GlassColors.glassText,
    surface: GlassColors.glassWhite,
  );

  final baseText = GoogleFonts.interTextTheme(base.textTheme);
  final textTheme = baseText.copyWith(
    titleLarge: GoogleFonts.poppins(
      textStyle: (baseText.titleLarge ?? const TextStyle()).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GlassColors.glassText,
      ),
    ),
    titleMedium: GoogleFonts.poppins(
      textStyle: (baseText.titleMedium ?? const TextStyle()).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: GlassColors.glassText,
      ),
    ),
    titleSmall: GoogleFonts.poppins(
      textStyle: (baseText.titleSmall ?? const TextStyle()).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: GlassColors.glassText,
      ),
    ),
    bodyLarge: GoogleFonts.inter(
      textStyle: (baseText.bodyLarge ?? const TextStyle()).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: GlassColors.glassText,
      ),
    ),
    bodyMedium: GoogleFonts.inter(
      textStyle: (baseText.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: GlassColors.glassText,
      ),
    ),
    bodySmall: GoogleFonts.inter(
      textStyle: (baseText.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: GlassColors.glassText,
      ),
    ),
    labelLarge: GoogleFonts.inter(
      textStyle: (baseText.labelLarge ?? const TextStyle()).copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: GlassColors.glassText,
      ),
    ),
    labelMedium: GoogleFonts.inter(
      textStyle: (baseText.labelMedium ?? const TextStyle()).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: GlassColors.glassText,
      ),
    ),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    textTheme: textTheme,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 44,
      foregroundColor: GlassColors.glassText,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: GlassColors.glassWhite.withAlpha(180),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: GlassColors.sushi.withAlpha(110)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: GlassColors.sushi.withAlpha(120)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: GlassColors.redAccent.withAlpha(32),
      backgroundColor: GlassColors.glassWhite.withAlpha(190),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: GlassColors.glassText,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GlassColors.glassWhite.withAlpha(230),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GlassColors.glassText,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: GlassColors.glassText,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlassColors.glassWhite.withAlpha(210),
      isDense: true,
      contentPadding: const EdgeInsets.all(8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GlassColors.redAccent, width: 2),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      minLeadingWidth: 24,
      minVerticalPadding: 0,
      visualDensity: VisualDensity.compact,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
        foregroundColor: const WidgetStatePropertyAll(GlassColors.redAccent),
        textStyle: WidgetStateProperty.resolveWith((states) {
          final hovered = states.contains(WidgetState.hovered);
          return TextStyle(
            fontWeight: FontWeight.w600,
            decoration: hovered
                ? TextDecoration.underline
                : TextDecoration.none,
          );
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return GlassColors.redAccent.withAlpha(77);
          }
          if (states.contains(WidgetState.hovered)) {
            return GlassColors.redAccent.withAlpha(40);
          }
          return Colors.transparent;
        }),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 40),
        maximumSize: const Size(double.infinity, 40),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: Colors.white,
        backgroundColor: GlassColors.redAccent,
        shadowColor: GlassColors.redAccent.withAlpha(40),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: Colors.white,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: GlassColors.glassText,
        side: BorderSide(color: GlassColors.redAccent.withAlpha(80)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(36),
        maximumSize: const Size.square(36),
        padding: const EdgeInsets.all(8),
        foregroundColor: GlassColors.glassText,
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 1,
      color: GlassColors.glassBorder,
    ),
    dataTableTheme: const DataTableThemeData(
      dataRowMinHeight: 32,
      dataRowMaxHeight: 32,
      headingRowHeight: 36,
      columnSpacing: 12,
      horizontalMargin: 8,
      dividerThickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: GlassColors.glassDark.withAlpha(230),
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: Colors.white70,
      elevation: 4,
    ),
   pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
  },
),
  );
}
