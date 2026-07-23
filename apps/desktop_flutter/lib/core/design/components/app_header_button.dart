import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.flipIconHorizontally = false,
    this.size = 52,
  });

  static const tooltipBackgroundColor = Color(0xFFFFF4C2);
  static const tooltipBorderColor = Color(0xFFD8A900);
  static const tooltipTextColor = Color(0xFF332400);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final bool flipIconHorizontally;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: tooltipKey,
      message: tooltip,
      preferBelow: true,
      verticalOffset: size / 2 + AppSpacing.sm,
      waitDuration: AppDurations.normal,
      showDuration: const Duration(seconds: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tooltipBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: tooltipBorderColor),
      ),
      textStyle: const TextStyle(
        color: tooltipTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: AppButton(
          label: '',
          icon: icon,
          flipIconHorizontally: flipIconHorizontally,
          variant: AppButtonVariant.navigation,
          width: size,
          height: size,
          padding: EdgeInsets.zero,
          iconSize: AppIconSizes.lg,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
