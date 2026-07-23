import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

class AppTooltipIconButton extends StatelessWidget {
  const AppTooltipIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.flipIconHorizontally = false,
    this.size = 52,
    this.iconSize = AppIconSizes.lg,
    this.variant = AppButtonVariant.navigation,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final bool flipIconHorizontally;
  final double size;
  final double iconSize;
  final AppButtonVariant variant;

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
        color: AppTooltipColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppTooltipColors.border),
      ),
      textStyle: const TextStyle(
        color: AppTooltipColors.text,
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
          variant: variant,
          width: size,
          height: size,
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

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

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final bool flipIconHorizontally;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppTooltipIconButton(
      tooltipKey: tooltipKey,
      icon: icon,
      tooltip: tooltip,
      flipIconHorizontally: flipIconHorizontally,
      size: size,
      onPressed: onPressed,
    );
  }
}
