import 'package:flutter/material.dart';

import '../app_tokens.dart';

class AppSwitchField extends StatelessWidget {
  const AppSwitchField({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final selectedThumbColor = accentColor ?? AppColors.success;
    final selectedTrackColor = accentColor == null
        ? AppColors.switchTrackSelected
        : Color.alphaBlend(
            accentColor!.withAlpha(48),
            AppColors.surface,
          );
    final borderColor = accentColor == null
        ? AppColors.border
        : Color.lerp(
            accentColor!,
            AppColors.surface,
            0.62,
          )!;

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppControlHeights.large,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor ?? AppColors.primary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTypography.fieldText),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            overlayColor:
                const WidgetStatePropertyAll<Color>(Colors.transparent),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashRadius: 0,
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.disabled;
              }
              return states.contains(WidgetState.selected)
                  ? selectedThumbColor
                  : AppColors.danger;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.switchTrack;
              }
              return states.contains(WidgetState.selected)
                  ? selectedTrackColor
                  : AppColors.switchTrack;
            }),
            trackOutlineColor:
                const WidgetStatePropertyAll(Colors.transparent),
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
              final isSelected = states.contains(WidgetState.selected);
              return Icon(
                isSelected ? Icons.check_rounded : Icons.close_rounded,
                color: AppColors.onStrong,
                size: 14,
              );
            }),
          ),
        ],
      ),
    );
  }
}
