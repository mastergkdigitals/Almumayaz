import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_shortcuts.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

enum AppDropdownVisualStyle { standard, oldPurchase }

const _oldPurchaseTextColor = Color(0xFF111827);
const _oldPurchaseSecondaryTextColor = Color(0xFF64748B);
const _oldPurchaseBorderColor = Color(0xFFE5E7EB);
const _oldPurchaseFieldRadius = 14.0;
const _oldPurchaseMenuRadius = 16.0;

final _oldPurchaseSelectedTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.58,
)!;
final _oldPurchaseHoverTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.78,
)!;

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
    this.focusNode,
    this.onSubmitted,
    this.keyHoldGuard,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.menuTextDirection,
    this.useIntrinsicHeight = false,
    this.contentPadding,
    this.visualStyle = AppDropdownVisualStyle.standard,
    this.enabled = true,
    this.showLabel = true,
    this.borderRadius,
  }) : assert(
          !useIntrinsicHeight ||
              visualStyle == AppDropdownVisualStyle.oldPurchase,
          'Intrinsic dropdown height is reserved for old-app references.',
        );

  final String label;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final Key? fieldKey;
  final IconData? icon;
  final Color? accentColor;
  final FocusNode? focusNode;
  final ValueChanged<T?>? onSubmitted;
  final AppKeyHoldGuard? keyHoldGuard;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextDirection? menuTextDirection;

  /// Preserves the variable height of old-app reference dropdowns.
  ///
  /// Current application dropdowns use [AppControlHeights.large].
  final bool useIntrinsicHeight;
  final EdgeInsetsGeometry? contentPadding;
  final AppDropdownVisualStyle visualStyle;
  final bool enabled;
  final bool showLabel;
  final double? borderRadius;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _menuController = MenuController();
  final _internalFocusNode = FocusNode();
  AppKeyHoldGuard? _internalKeyHoldGuard;
  late List<FocusNode> _itemFocusNodes;
  bool _isHovered = false;
  bool _isOpen = false;

  bool get _usesOldPurchaseStyle =>
      widget.visualStyle == AppDropdownVisualStyle.oldPurchase;
  bool get _usesIntrinsicHeight =>
      _usesOldPurchaseStyle && widget.useIntrinsicHeight;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;
  AppKeyHoldGuard get _keyHoldGuard =>
      widget.keyHoldGuard ??
      (_internalKeyHoldGuard ??= AppKeyHoldGuard());

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

  void _ignoreHorizontalNavigation() {}

  void _replaceItemFocusNodes() {
    for (final focusNode in _itemFocusNodes) {
      focusNode.dispose();
    }
    _itemFocusNodes = List.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
  }

  void _openMenu(MenuController controller) {
    controller.open();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.isOpen || _itemFocusNodes.isEmpty) return;

      final selectedIndex = widget.options.indexWhere(
        (option) => option.value == widget.value,
      );
      _itemFocusNodes[selectedIndex < 0 ? 0 : selectedIndex].requestFocus();
    });
  }

  void _toggleMenu(MenuController controller) {
    if (controller.isOpen) {
      controller.close();
    } else {
      _openMenu(controller);
    }
  }

  void _toggleMenuOnce(MenuController controller) {
    if (!widget.enabled) return;
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _toggleMenu(controller),
    );
  }

  void _selectOptionOnce(AppDropdownOption<T> option) {
    if (!widget.enabled) return;
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _selectOption(option),
    );
  }

  void _selectOption(AppDropdownOption<T> option) {
    final submittedWithEnter = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.enter) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.numpadEnter);

    widget.onChanged(option.value);
    _menuController.close();

    if (!submittedWithEnter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSubmitted?.call(option.value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _itemFocusNodes = List.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          .removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.options.length != widget.options.length) {
      _replaceItemFocusNodes();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    for (final focusNode in _itemFocusNodes) {
      focusNode.dispose();
    }
    _internalKeyHoldGuard?.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildSelectedValue(Color valueColor) {
    final textStyle = _usesOldPurchaseStyle
        ? const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          )
        : AppTypography.fieldText.copyWith(
            fontWeight: FontWeight.w600,
          );
    final value = Text(
      widget.value == null ? '' : _selectedLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
      style: textStyle.copyWith(color: valueColor),
    );

    if (!_usesIntrinsicHeight) {
      return value;
    }

    return SizedBox(width: double.infinity, child: value);
  }

  @override
  Widget build(BuildContext context) {
    final usesOldPurchaseStyle = _usesOldPurchaseStyle;
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
    final borderColor = usesOldPurchaseStyle
        ? _oldPurchaseBorderColor
        : _isOpen
            ? accentColor
            : _isHovered
                ? AppColors.controlHoverBorder
                : AppColors.border;
    final backgroundColor = !widget.enabled
        ? AppColors.disabledSurface
        : usesOldPurchaseStyle
            ? AppColors.surface
            : _isOpen
                ? openBackgroundColor
                : _isHovered
                    ? hoverBackgroundColor
                    : AppColors.surface;
    final valueColor = widget.enabled
        ? usesOldPurchaseStyle
            ? _oldPurchaseTextColor
            : AppColors.textPrimary
        : usesOldPurchaseStyle
            ? _oldPurchaseTextColor.withAlpha(97)
            : AppColors.disabled;
    final iconColor = widget.enabled
        ? accentColor
        : usesOldPurchaseStyle
            ? accentColor.withAlpha(107)
            : AppColors.disabled;
    final fieldRadius = widget.borderRadius ??
        (usesOldPurchaseStyle ? _oldPurchaseFieldRadius : AppRadii.md);

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;

        return MenuAnchor(
          controller: _menuController,
          childFocusNode: _focusNode,
          crossAxisUnconstrained: false,
          animated: false,
          onOpen: () => setState(() => _isOpen = true),
          onClose: () => setState(() => _isOpen = false),
          style: MenuStyle(
            backgroundColor:
                const WidgetStatePropertyAll<Color>(AppColors.surface),
            surfaceTintColor:
                const WidgetStatePropertyAll<Color>(Colors.transparent),
            shadowColor: WidgetStatePropertyAll<Color>(
              usesOldPurchaseStyle
                  ? Colors.black.withAlpha(36)
                  : AppColors.menuShadow,
            ),
            elevation: WidgetStatePropertyAll<double>(
              usesOldPurchaseStyle ? 8 : 4,
            ),
            fixedSize: WidgetStatePropertyAll<Size>(
              Size.fromWidth(menuWidth),
            ),
            padding:
                const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.all(AppSpacing.xs),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  usesOldPurchaseStyle
                      ? _oldPurchaseMenuRadius
                      : AppRadii.md,
                ),
                side: BorderSide(
                  color: usesOldPurchaseStyle
                      ? accentColor
                      : AppColors.border,
                ),
              ),
            ),
          ),
          menuChildren: widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = option.value == widget.value;

            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    () => _selectOptionOnce(option),
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    () => _selectOptionOnce(option),
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    _ignoreHorizontalNavigation,
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    _ignoreHorizontalNavigation,
              },
              child: MenuItemButton(
                focusNode: _itemFocusNodes[index],
                requestFocusOnHover: false,
                onPressed: widget.enabled
                    ? () => _selectOption(option)
                    : null,
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll<Size>(
                    Size(0, usesOldPurchaseStyle ? 48 : 44),
                  ),
                  padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(
                      horizontal:
                          usesOldPurchaseStyle ? 12 : AppSpacing.md,
                    ),
                  ),
                  elevation:
                      const WidgetStatePropertyAll<double>(0),
                  shadowColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                  overlayColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (isSelected) {
                        return usesOldPurchaseStyle
                            ? _oldPurchaseSelectedTint
                            : selectedBackgroundColor;
                      }
                      if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return usesOldPurchaseStyle
                            ? _oldPurchaseHoverTint
                            : AppColors.controlHoverSurface;
                      }
                      return Colors.transparent;
                    },
                  ),
                  foregroundColor: WidgetStatePropertyAll<Color>(
                    isSelected
                        ? usesOldPurchaseStyle
                            ? AppModulePalettes.purchases.dark
                            : accentColor
                        : usesOldPurchaseStyle
                            ? _oldPurchaseTextColor
                            : AppColors.textPrimary,
                  ),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        usesOldPurchaseStyle ? 10 : AppRadii.sm,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  animationDuration: usesOldPurchaseStyle
                      ? Duration.zero
                      : AppDurations.fast,
                ),
                child: usesOldPurchaseStyle
                    ? SizedBox(
                        height: 46,
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            textDirection: widget.menuTextDirection ??
                                widget.textDirection,
                            style: TextStyle(
                              color: isSelected
                                  ? AppModulePalettes.purchases.dark
                                  : _oldPurchaseTextColor,
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
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
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Align(
                                alignment:
                                    AlignmentDirectional.centerStart,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: AppIconSizes.sm,
                                  color: accentColor,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            );
          }).toList(growable: false),
          builder: (context, controller, child) {
            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    () => _toggleMenuOnce(controller),
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    () => _toggleMenuOnce(controller),
              },
              child: Semantics(
                button: true,
                enabled: widget.enabled,
                label: widget.label,
                value: _selectedLabel,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: widget.fieldKey,
                    focusNode: _focusNode,
                    onTap: widget.enabled
                        ? () => _toggleMenu(controller)
                        : null,
                    onHover: widget.enabled ? _setHovered : null,
                    mouseCursor: widget.enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    borderRadius: BorderRadius.circular(fieldRadius),
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    overlayColor:
                        const WidgetStatePropertyAll<Color>(Colors.transparent),
                    child: SizedBox(
                      height: _usesIntrinsicHeight
                          ? null
                          : AppControlHeights.large,
                      child: InputDecorator(
                        baseStyle: _usesIntrinsicHeight
                            ? null
                            : AppTypography.fieldText,
                        textAlign: _usesIntrinsicHeight
                            ? null
                            : widget.textAlign,
                        textAlignVertical: _usesIntrinsicHeight
                            ? null
                            : TextAlignVertical.center,
                        expands: !_usesIntrinsicHeight,
                        isEmpty: widget.value == null,
                        isFocused: _isOpen || _focusNode.hasFocus,
                        decoration: InputDecoration(
                          enabled: widget.enabled,
                          labelText:
                              widget.showLabel ? widget.label : null,
                          hintText: widget.showLabel
                              ? 'اختر ${widget.label}'
                              : null,
                          labelStyle: usesOldPurchaseStyle
                              ? const TextStyle(
                                  color: _oldPurchaseSecondaryTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                )
                              : null,
                          contentPadding: widget.contentPadding ??
                              (usesOldPurchaseStyle
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    )
                                  : null),
                          prefixIcon: widget.icon == null
                              ? null
                              : Icon(
                                  widget.icon,
                                  color: iconColor,
                                  size: usesOldPurchaseStyle
                                      ? AppIconSizes.md
                                      : null,
                                ),
                          suffixIcon: usesOldPurchaseStyle
                              ? Icon(
                                  _isOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: AppIconSizes.md,
                                  color: iconColor,
                                )
                              : AnimatedRotation(
                                  turns: _isOpen ? 0.5 : 0,
                                  duration: AppDurations.fast,
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: AppIconSizes.md,
                                    color: iconColor,
                                  ),
                                ),
                          filled: true,
                          fillColor: backgroundColor,
                          floatingLabelStyle: usesOldPurchaseStyle
                              ? TextStyle(
                                  color: iconColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                )
                              : AppTypography.fieldText.copyWith(
                                  color: iconColor,
                                ),
                          border: usesOldPurchaseStyle
                              ? OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius),
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.6,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: BorderSide(
                              color: usesOldPurchaseStyle
                                  ? _oldPurchaseBorderColor
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        child: _buildSelectedValue(valueColor),
                      ),
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
