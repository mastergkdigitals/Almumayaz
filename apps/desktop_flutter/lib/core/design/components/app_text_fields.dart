import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

class AppFieldIconButton extends StatelessWidget {
  const AppFieldIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.buttonKey,
    this.tooltip,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(color),
          elevation: const WidgetStatePropertyAll<double>(0),
          backgroundColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          shadowColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          surfaceTintColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          overlayColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
          mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>(
            (states) => states.contains(WidgetState.disabled)
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
          ),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.fieldKey,
    this.hint,
    this.helperText,
    this.errorText,
    this.icon,
    this.suffixIcon,
    this.accentColor,
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
    this.readOnly = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.onEditingComplete,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final Widget? suffixIcon;
  final Color? accentColor;
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
  final bool readOnly;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    final themedBorder = accentColor == null
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: BorderSide(color: accentColor!),
          );
    final themedFocusedBorder = accentColor == null
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: BorderSide(color: accentColor!, width: 1.6),
          );

    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      readOnly: readOnly,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onTap: onTap,
      onEditingComplete:
          onEditingComplete ?? (onSubmitted == null ? null : () {}),
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
        helperText: helperText,
        errorText: errorText,
        prefixIcon:
            icon == null ? null : Icon(icon, color: accentColor),
        suffixIcon: suffixIcon,
        floatingLabelStyle: accentColor == null
            ? null
            : AppTypography.fieldText.copyWith(color: accentColor),
        enabledBorder: themedBorder,
        focusedBorder: themedFocusedBorder,
      ),
    );
  }
}

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.controller,
    super.key,
    this.label = 'بحث',
    this.fieldKey,
    this.clearButtonKey,
    this.hint,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final Key? clearButtonKey;
  final String? hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final FocusNode _internalFocusNode = FocusNode();
  late bool _hasText;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText == hasText) return;
    setState(() => _hasText = hasText);
  }

  void _clear() {
    if (!widget.enabled || widget.controller.text.isEmpty) return;

    widget.controller.clear();
    widget.onChanged?.call('');
    _effectiveFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      fieldKey: widget.fieldKey,
      hint: widget.hint,
      icon: Icons.search_rounded,
      focusNode: _effectiveFocusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: () {},
      textInputAction: TextInputAction.search,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      suffixIcon: _hasText && widget.enabled
          ? AppFieldIconButton(
              buttonKey: widget.clearButtonKey,
              icon: Icons.close_rounded,
              tooltip: 'مسح البحث',
              color: AppColors.danger,
              onPressed: _clear,
            )
          : null,
    );
  }
}


class AppTextArea extends StatelessWidget {
  const AppTextArea({
    required this.controller,
    required this.label,
    super.key,
    this.fieldKey,
    this.icon = Icons.notes_rounded,
    this.minLines = 3,
    this.maxLines = 5,
    this.enabled = true,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final IconData icon;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      validator: validator,
      onChanged: onChanged,
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
