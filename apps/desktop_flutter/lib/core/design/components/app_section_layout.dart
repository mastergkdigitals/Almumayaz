import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

/// Shared bordered section card used by dense operational screens.
class AppSectionPanel extends StatelessWidget {
  const AppSectionPanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    super.key,
    this.expandChild = false,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final bool expandChild;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
    final borderRadius = BorderRadius.circular(AppRadii.lg);
    final borderColor = Color.lerp(
      accentColor,
      AppColors.surface,
      0.62,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Color.alphaBlend(
                  accentColor.withAlpha(14),
                  AppColors.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          accentColor.withAlpha(24),
                          AppColors.surface,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: accentColor.withAlpha(90),
                        ),
                      ),
                      child: Icon(icon, color: accentColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              if (expandChild) Expanded(child: body) else body,
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive equal-width grid shared by Settings and other dense screens.
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    required this.children,
    super.key,
    this.preferredColumns = 2,
    this.spacing = AppSpacing.md,
    this.minimumChildHeight,
  });

  final List<Widget> children;
  final int preferredColumns;
  final double spacing;
  final double? minimumChildHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;
        if (constraints.maxWidth >= 1060 && preferredColumns >= 3) {
          columns = 3;
        } else if (constraints.maxWidth >= 650 && preferredColumns >= 2) {
          columns = 2;
        }
        if (columns > children.length) columns = children.length;

        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: minimumChildHeight == null
                    ? child
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minimumChildHeight!,
                        ),
                        child: child,
                      ),
              ),
          ],
        );
      },
    );
  }
}

typedef AppSelectionTab<T> = ({T value, String label, IconData icon});

/// Shared primary/navigation selection buttons used for section and variant
/// switching. It can use a wrapping layout or preserve a compact single row.
class AppSelectionTabs<T> extends StatelessWidget {
  const AppSelectionTabs({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    required this.accentColor,
    super.key,
    this.valueId,
    this.isSelected,
    this.wrap = true,
    this.notifyWhenSelected = false,
    this.minWidth = 160,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.spacing = AppSpacing.sm,
    this.textDirection = TextDirection.rtl,
  });

  final List<AppSelectionTab<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final String keyPrefix;
  final Color accentColor;
  final String Function(T value)? valueId;
  final bool Function(T value, T selected)? isSelected;
  final bool wrap;
  final bool notifyWhenSelected;
  final double minWidth;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final TextDirection textDirection;

  Widget _button(AppSelectionTab<T> item) {
    final selectedItem = isSelected?.call(item.value, selected) ??
        (item.value == selected);
    final id = valueId?.call(item.value) ?? '${item.value}';
    return AppButton(
      key: Key('$keyPrefix$id'),
      label: item.label,
      icon: item.icon,
      variant: selectedItem
          ? AppButtonVariant.primary
          : AppButtonVariant.navigation,
      backgroundColor: selectedItem ? accentColor : null,
      padding: padding,
      minWidth: minWidth,
      height: height ?? AppControlHeights.standard,
      onPressed: selectedItem && !notifyWhenSelected
          ? () {}
          : () => onChanged(item.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        textDirection: textDirection,
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final item in items) _button(item)],
      );
    }

    return Directionality(
      textDirection: textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            _button(items[index]),
          ],
        ],
      ),
    );
  }
}
