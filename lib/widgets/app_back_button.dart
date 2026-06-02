import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.iconColor,
    this.onPressed,
    this.alwaysVisible = false,
  });

  final Color? iconColor;
  final VoidCallback? onPressed;
  final bool alwaysVisible;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && !alwaysVisible) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.arrow_back, size: 20),
      color: iconColor ?? IconTheme.of(context).color ?? AppColors.charbon,
      onPressed:
          onPressed ??
          () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
    );
  }
}
