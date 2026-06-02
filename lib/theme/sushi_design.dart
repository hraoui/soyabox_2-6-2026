import 'package:flutter/material.dart';

class SushiColors {
  // Primaires
  static const Color red = Color(0xFFE8003D);
  static const Color redDark = Color(0xFFB5002E);
  static const Color redLight = Color(0xFFFF3366);
  static const Color redPale = Color(0xFFFFE5EC);
  static const Color redSurface = Color(0xFFFFF0F3);

  // Accents
  static const Color orange = Color(0xFFFF6B35);
  static const Color yellow = Color(0xFFFFD60A);
  static const Color green = Color(0xFF00B67A);
  static const Color teal = Color(0xFF0096C7);

  // Neutres
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF1C1C1E);
  static const Color inkMid = Color(0xFF48484A);
  static const Color inkLight = Color(0xFF8E8E93);
  static const Color inkFaint = Color(0xFFC7C7CC);
  static const Color divider = Color(0xFFE5E5EA);
  static const Color surface = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFFAFAFA);

  // Status
  static const Color success = Color(0xFF00B67A);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF0096C7);

  // Additional colors for POS
  static const Color greenPale = Color(0xFFE8F5E9);
  static const Color orangePale = Color(0xFFFFF3E0);
  static const Color bluePale = Color(0xFFE3F2FD);
}

class SushiRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;
}

class SushiSpace {
  static const double xs = 2.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double xl = 24.0;
  static const double xxl = 20.0;
  static const double xxxl = 30.0;
}

class SushiTypo {
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: SushiColors.ink,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: SushiColors.ink,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: SushiColors.ink,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: SushiColors.ink,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: SushiColors.ink,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
    color: SushiColors.inkSoft,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
    color: SushiColors.inkSoft,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: SushiColors.inkMid,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SushiColors.inkMid,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: SushiColors.inkLight,
  );
  static const TextStyle btnLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: SushiColors.white,
  );
  static const TextStyle btnMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SushiColors.white,
  );
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    fontFamily: 'RobotoMono',
    color: SushiColors.green,
  );
  static const TextStyle priceLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    fontFamily: 'RobotoMono',
    color: SushiColors.green,
  );
  static const TextStyle tag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: SushiColors.ink,
  );
}

class SushiShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x240A0A0A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x99E8003D), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x330A0A0A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A0A0A0A), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x2E0A0A0A), blurRadius: 20, offset: Offset(0, -4)),
  ];
  static const List<BoxShadow> ctaRed = [
    BoxShadow(color: Color(0xCCE8003D), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

class SushiGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SushiColors.red, SushiColors.redLight],
  );
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SushiColors.red, SushiColors.redDark],
  );
}

/// 🎨 Sushi Decorations - Card and UI element decorators
class SushiDeco {
  static BoxDecoration card({bool selected = false}) {
    return BoxDecoration(
      color: SushiColors.white,
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      border: Border.all(
        color: selected ? SushiColors.red : SushiColors.divider,
        width: selected ? 1.8 : 1,
      ),
      boxShadow: selected ? SushiShadow.elevated : SushiShadow.card,
    );
  }

  static BoxDecoration badge({required Color bg}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(SushiRadius.full),
      border: Border.all(color: SushiColors.divider, width: 1),
    );
  }

  static BoxDecoration button({Color? color}) {
    return BoxDecoration(
      color: color ?? SushiColors.red,
      borderRadius: BorderRadius.circular(SushiRadius.md),
      boxShadow: SushiShadow.button,
    );
  }

  static BoxDecoration featured({Color? accentColor}) {
    return BoxDecoration(
      color: SushiColors.white,
      borderRadius: BorderRadius.circular(SushiRadius.xl),
      border: Border.all(color: accentColor ?? SushiColors.redLight, width: 2),
      boxShadow: SushiShadow.elevated,
    );
  }

  static BoxDecoration tinted({required Color color, double opacity = 0.1}) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    );
  }
}
