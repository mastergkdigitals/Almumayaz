import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_shortcuts.dart';

class AppModuleDialog extends StatelessWidget {
  const AppModuleDialog({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onClose,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.width = AppDialogSizes.large,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onClose;
  final Widget child;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final tintedSurface = Color.alphaBlend(
      accentColor.withAlpha(10),
      AppColors.surface,
    );

    return AppShortcutScope(
      onEscape: onClose,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: viewport.height * AppDialogSizes.maxHeightFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: tintedSurface,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              accentColor.withAlpha(24),
                              AppColors.surface,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: accentColor.withAlpha(110),
                            ),
                          ),
                          child: Icon(icon, color: accentColor),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.screenTitle.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: child,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (var index = 0;
                              index < actions.length;
                              index++) ...[
                            if (index > 0)
                              const SizedBox(width: AppSpacing.sm),
                            actions[index],
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppDialogSection extends StatelessWidget {
  const AppDialogSection({
    required this.title,
    required this.accentColor,
    required this.child,
    super.key,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withAlpha(7),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: Color.alphaBlend(
            accentColor.withAlpha(80),
            AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (icon != null) ...[
                Icon(icon, color: accentColor, size: AppIconSizes.md),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(title, style: AppTypography.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
