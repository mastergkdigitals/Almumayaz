import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_header_button.dart';
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
    this.subtitleStyle,
    this.centerHeader = false,
    this.showHeaderCloseButton = false,
    this.actions = const [],
    this.actionsKey,
    this.width = AppDialogSizes.large,
    this.bodyScrollable = true,
    this.maxHeightFactor = AppDialogSizes.maxHeightFactor,
  }) : assert(maxHeightFactor > 0 && maxHeightFactor <= 1);

  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onClose;
  final Widget child;
  final bool centerHeader;
  final bool showHeaderCloseButton;
  final List<Widget> actions;
  final Key? actionsKey;
  final double width;
  final bool bodyScrollable;
  final double maxHeightFactor;

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
            maxHeight: viewport.height * maxHeightFactor,
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
                    child: centerHeader
                        ? _buildCenteredHeader()
                        : _buildStandardHeader(),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: bodyScrollable
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: child,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: child,
                          ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        key: actionsKey,
                        mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildStandardHeader() {
    return Row(
      children: [
        _HeaderIcon(icon: icon, accentColor: accentColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _HeaderText(
            title: title,
            subtitle: subtitle,
            subtitleStyle: subtitleStyle,
            centered: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredHeader() {
    return Row(
      children: [
        SizedBox(
          width: 48 * AppDensity.scale,
          height: 48 * AppDensity.scale,
          child: showHeaderCloseButton
              ? AppTooltipIconButton(
                  key: const Key('appModuleDialogClose'),
                  tooltipKey: const Key('appModuleDialogCloseTooltip'),
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  size: 48 * AppDensity.scale,
                  onPressed: onClose,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _HeaderText(
            title: title,
            subtitle: subtitle,
            subtitleStyle: subtitleStyle,
            centered: true,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _HeaderIcon(icon: icon, accentColor: accentColor),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.title,
    required this.subtitle,
    required this.subtitleStyle,
    required this.centered,
  });

  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTypography.screenTitle.copyWith(
            fontSize: 24 * AppDensity.scale,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: subtitleStyle ??
                const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.accentColor,
  });

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48 * AppDensity.scale,
      height: 48 * AppDensity.scale,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withAlpha(24),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accentColor.withAlpha(110)),
      ),
      child: Icon(icon, color: accentColor),
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
    this.expandChild = false,
  });

  final String title;
  final IconData? icon;
  final Color accentColor;
  final Widget child;
  final bool expandChild;

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
                width: 4 * AppDensity.scale,
                height: 24 * AppDensity.scale,
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
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
