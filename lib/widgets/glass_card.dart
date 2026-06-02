import 'package:flutter/material.dart';

import '../data/glass_theme.dart';
import '../theme/sushi_design.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SushiSpace.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: const EdgeInsets.symmetric(vertical: SushiSpace.sm),
      decoration: GlassThemeData.glassContainerLight(
        borderWidth: 1.5,
        borderColor: GlassColors.glassBorder,
      ),
      child: child,
    );
  }
}
