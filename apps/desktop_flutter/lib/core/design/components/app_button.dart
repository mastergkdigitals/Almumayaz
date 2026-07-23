import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = AppControlHeights.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final content = isLoading
        ? const SizedBox.square(
            dimension: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: AppLoadingIndicator(size: 18, strokeWidth: 2.2),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSizes.md),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          );

    final child = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.primary),
          ),
          child: content,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: content,
        ),
    };

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
