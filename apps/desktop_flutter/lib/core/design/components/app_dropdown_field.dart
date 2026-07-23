import 'package:flutter/material.dart';

import '../app_tokens.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.icon,
    this.accentColor,
    this.enabled = true,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final Key? fieldKey;
  final IconData? icon;
  final Color? accentColor;
  final bool enabled;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  bool _isHovered = false;
  bool _isOpen = false;

  String get _selectedLabel {
    for (final option in widget.options) {
      if (option.value == widget.value) return option.label;
    }
    return 'اختر ${widget.label}';
  }

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.primary;
    final openBackgroundColor = Color.alphaBlend(
      accentColor.withAlpha(14),
      AppColors.surface,
    );
    final hoverBackgroundColor = Color.alphaBlend(
      accentColor.withAlpha(8),
      AppColors.surface,
    );
    final selectedBackgroundColor = Color.alphaBlend(
      accentColor.withAlpha(22),
      AppColors.surface,
    );
    final borderColor = _isOpen
        ? accentColor
        : _isHovered
            ? const Color(0xFFB8CAE0)
            : AppColors.border;
    final backgroundColor = !widget.enabled
        ? const Color(0xFFF8FAFC)
        : _isOpen
            ? openBackgroundColor
            : _isHovered
                ? hoverBackgroundColor
                : AppColors.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;

        return MenuAnchor(
          crossAxisUnconstrained: false,
          animated: false,
          onOpen: () => setState(() => _isOpen = true),
          onClose: () => setState(() => _isOpen = false),
          style: MenuStyle(
            backgroundColor:
                const WidgetStatePropertyAll<Color>(AppColors.surface),
            surfaceTintColor:
                const WidgetStatePropertyAll<Color>(Colors.transparent),
            shadowColor:
                const WidgetStatePropertyAll<Color>(Color(0x24102A56)),
            elevation: const WidgetStatePropertyAll<double>(4),
            fixedSize: WidgetStatePropertyAll<Size>(
              Size.fromWidth(menuWidth),
            ),
            padding:
                const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.all(AppSpacing.xs),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          menuChildren: widget.options.map((option) {
            final isSelected = option.value == widget.value;

            return MenuItemButton(
              requestFocusOnHover: false,
              onPressed:
                  widget.enabled ? () => widget.onChanged(option.value) : null,
              style: ButtonStyle(
                minimumSize:
                    const WidgetStatePropertyAll<Size>(Size(0, 44)),
                padding:
                    const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                elevation:
                    const WidgetStatePropertyAll<double>(0),
                shadowColor:
                    const WidgetStatePropertyAll<Color>(Colors.transparent),
                overlayColor:
                    const WidgetStatePropertyAll<Color>(Colors.transparent),
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) {
                    if (isSelected) return selectedBackgroundColor;
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return const Color(0xFFF3F7FC);
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: WidgetStatePropertyAll<Color>(
                  isSelected ? accentColor : AppColors.textPrimary,
                ),
                shape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
                alignment: Alignment.center,
                animationDuration: AppDurations.fast,
              ),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.fieldText.copyWith(
                          color: isSelected
                              ? accentColor
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(
                          Icons.check_rounded,
                          size: AppIconSizes.sm,
                          color: accentColor,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
          builder: (context, controller, child) {
            return Semantics(
              button: true,
              enabled: widget.enabled,
              label: widget.label,
              value: _selectedLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: widget.fieldKey,
                  onTap: widget.enabled
                      ? () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        }
                      : null,
                  onHover: widget.enabled ? _setHovered : null,
                  mouseCursor: widget.enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  overlayColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: Curves.easeOutCubic,
                    height: AppControlHeights.large,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: borderColor,
                        width: _isOpen ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.icon != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Icon(
                              widget.icon,
                              size: AppIconSizes.md,
                              color: widget.enabled
                                  ? accentColor
                                  : AppColors.disabled,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 44),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.enabled
                                      ? AppColors.textSecondary
                                      : AppColors.disabled,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _selectedLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTypography.fieldText.copyWith(
                                  color: widget.enabled
                                      ? AppColors.textPrimary
                                      : AppColors.disabled,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AnimatedRotation(
                            turns: _isOpen ? 0.5 : 0,
                            duration: AppDurations.fast,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: AppIconSizes.md,
                              color: widget.enabled
                                  ? accentColor
                                  : AppColors.disabled,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
