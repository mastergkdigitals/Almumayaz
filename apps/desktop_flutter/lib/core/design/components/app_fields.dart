import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.fieldKey,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.focusNode,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      style: AppTypography.fieldText,
      textDirection: textDirection,
      textAlign: textAlign,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppIntegerField extends StatelessWidget {
  const AppIntegerField({
    required this.controller,
    required this.label,
    super.key,
    this.fieldKey,
    this.icon,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final IconData? icon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      fieldKey: fieldKey,
      icon: icon,
      enabled: enabled,
      validator: validator,
      onSubmitted: onSubmitted,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}

class AppMoneyField extends StatelessWidget {
  const AppMoneyField({
    required this.controller,
    required this.label,
    super.key,
    this.fieldKey,
    this.icon = Icons.payments_rounded,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final IconData icon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      fieldKey: fieldKey,
      icon: icon,
      enabled: enabled,
      validator: validator,
      onSubmitted: onSubmitted,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*(?:\.\d{0,4})?$'),
        ),
      ],
    );
  }
}

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
    this.enabled = true,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final Key? fieldKey;
  final IconData? icon;
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
    final borderColor = _isOpen
        ? AppColors.primary
        : _isHovered
            ? const Color(0xFFB8CAE0)
            : AppColors.border;
    final backgroundColor = !widget.enabled
        ? const Color(0xFFF8FAFC)
        : _isOpen
            ? const Color(0xFFF1F6FF)
            : _isHovered
                ? const Color(0xFFF8FBFF)
                : AppColors.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;

        return MenuAnchor(
          crossAxisUnconstrained: false,
      animated: true,
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
                if (isSelected) return const Color(0xFFE8F0FE);
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return const Color(0xFFF3F7FC);
                }
                return Colors.transparent;
              },
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(
              isSelected ? AppColors.primary : AppColors.textPrimary,
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
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Icon(
                      Icons.check_rounded,
                      size: AppIconSizes.sm,
                      color: AppColors.primary,
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
                              ? AppColors.primary
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
                              ? AppColors.primary
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

class AppSwitchField extends StatelessWidget {
  const AppSwitchField({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary),
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
                  ? AppColors.success
                  : AppColors.danger;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFFE2E8F0);
              }
              return states.contains(WidgetState.selected)
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE2E8F0);
            }),
            trackOutlineColor:
                const WidgetStatePropertyAll(Colors.transparent),
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
              final isSelected = states.contains(WidgetState.selected);
              return Icon(
                isSelected ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 14,
              );
            }),
          ),
        ],
      ),
    );
  }
}
