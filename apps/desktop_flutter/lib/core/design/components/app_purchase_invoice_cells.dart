import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_invoice_table.dart';
import 'app_shortcuts.dart';

class AppPurchaseInvoiceValueText extends StatelessWidget {
  const AppPurchaseInvoiceValueText(
    this.value, {
    super.key,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppPurchaseInvoiceSummaryValueText extends StatelessWidget {
  const AppPurchaseInvoiceSummaryValueText(
    this.value, {
    super.key,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppPurchaseInvoiceCellField extends StatelessWidget {
  const AppPurchaseInvoiceCellField({
    required this.controller,
    required this.focusNode,
    super.key,
    this.fieldKey,
    this.numeric = false,
    this.enabled = true,
    this.onChanged,
    this.nextFocusNode,
    this.onSubmitted,
    this.keyHoldGuard,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Key? fieldKey;
  final bool numeric;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final FocusNode? nextFocusNode;
  final ValueChanged<String>? onSubmitted;
  final AppKeyHoldGuard? keyHoldGuard;

  @override
  Widget build(BuildContext context) {
    void submit(String value) {
      void action() {
        final callback = onSubmitted;
        if (callback != null) {
          callback(value);
          return;
        }
        nextFocusNode?.requestFocus();
      }

      final guard = keyHoldGuard;
      if (guard == null) {
        action();
        return;
      }

      guard.runOnce(
        keys: {
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
        },
        action: action,
      );
    }

    return _VerticalArrowKeyGuard(
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        cursorColor: AppColors.cursor,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        textAlign: numeric ? TextAlign.center : TextAlign.right,
        textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        ),
        onChanged: onChanged,
        onSubmitted:
            onSubmitted == null && nextFocusNode == null ? null : submit,
      ),
    );
  }
}

class AppPurchaseInvoiceAutocomplete<T> extends StatefulWidget {
  const AppPurchaseInvoiceAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.options,
    required this.optionLabel,
    required this.optionSearchValues,
    required this.onChanged,
    required this.onSelected,
    required this.minMenuWidth,
    super.key,
    this.fieldKey,
    this.nextFocusNode,
    this.optionSubtitle,
    this.onSubmitted,
    this.onFocusLost,
    this.keyHoldGuard,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final bool enabled;
  final List<T> options;
  final String Function(T option) optionLabel;
  final String Function(T option)? optionSubtitle;
  final Iterable<String?> Function(T option) optionSearchValues;
  final ValueChanged<String> onChanged;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onFocusLost;
  final double minMenuWidth;
  final Key? fieldKey;
  final AppKeyHoldGuard? keyHoldGuard;

  @override
  State<AppPurchaseInvoiceAutocomplete<T>> createState() =>
      _AppPurchaseInvoiceAutocompleteState<T>();
}

class _AppPurchaseInvoiceAutocompleteState<T>
    extends State<AppPurchaseInvoiceAutocomplete<T>> {
  final _layerLink = LayerLink();
  final _fieldBoxKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  var _isOpen = false;
  var _overlayRebuildScheduled = false;

  List<T> get _filteredOptions {
    final query = widget.controller.text.trim().toLowerCase();
    return widget.options
        .where((option) {
          if (query.isEmpty) return true;
          return widget
              .optionSearchValues(option)
              .whereType<String>()
              .map((value) => value.trim().toLowerCase())
              .any((value) => value.contains(query));
        })
        .take(24)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(
    covariant AppPurchaseInvoiceAutocomplete<T> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    if (!widget.enabled && _isOpen) {
      _hideMenu(updateState: false);
    } else {
      _scheduleOverlayRebuild();
    }
  }

  @override
  void deactivate() {
    _hideMenu(updateState: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _hideMenu(updateState: false);
    widget.controller.removeListener(_handleControllerChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!widget.enabled) return;
    if (widget.focusNode.hasFocus) {
      _showMenu();
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || widget.focusNode.hasFocus) return;
      _hideMenu();
      widget.onFocusLost?.call(widget.controller.text);
    });
  }

  void _handleControllerChanged() {
    if (!widget.focusNode.hasFocus || !widget.enabled) return;
    if (_isOpen) {
      _scheduleOverlayRebuild();
    } else {
      _showMenu();
    }
  }

  void _scheduleOverlayRebuild() {
    if (_overlayEntry == null || _overlayRebuildScheduled) return;
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted || _overlayEntry == null) return;
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _showMenu() {
    if (!mounted || !widget.enabled || _isOpen) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final fieldRenderObject =
        _fieldBoxKey.currentContext?.findRenderObject();
    final overlayRenderObject = overlay?.context.findRenderObject();
    if (overlay == null ||
        fieldRenderObject is! RenderBox ||
        overlayRenderObject is! RenderBox ||
        !fieldRenderObject.attached ||
        !overlayRenderObject.attached ||
        !fieldRenderObject.hasSize ||
        !overlayRenderObject.hasSize) {
      return;
    }

    final fieldSize = fieldRenderObject.size;
    final fieldOffset = fieldRenderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );
    final overlaySize = overlayRenderObject.size;
    final spaceBelow =
        overlaySize.height - fieldOffset.dy - fieldSize.height;
    final spaceAbove = fieldOffset.dy;
    final openBelow = spaceBelow >= 180 || spaceBelow >= spaceAbove;
    final availableSpace = (openBelow ? spaceBelow : spaceAbove) - 12;
    final maxMenuHeight =
        availableSpace.clamp(96.0, 260.0).toDouble();
    final menuWidth = fieldSize.width < widget.minMenuWidth
        ? widget.minMenuWidth
        : fieldSize.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: openBelow
                  ? Alignment.bottomRight
                  : Alignment.topRight,
              followerAnchor: openBelow
                  ? Alignment.topRight
                  : Alignment.bottomRight,
              offset: Offset(0, openBelow ? 4 : -4),
              showWhenUnlinked: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _PurchaseAutocompleteMenu<T>(
                  width: menuWidth,
                  maxHeight: maxMenuHeight,
                  options: _filteredOptions,
                  optionLabel: widget.optionLabel,
                  optionSubtitle: widget.optionSubtitle,
                  onSelected: _selectOption,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _hideMenu({bool updateState = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    _overlayRebuildScheduled = false;
    entry?.remove();
    if (updateState && mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  void _selectOption(T option, {bool advanceFocus = false}) {
    widget.onSelected(option);
    _hideMenu();
    if (advanceFocus && widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
      return;
    }
    widget.focusNode.unfocus();
  }

  void _submit(String value) {
    void action() {
      if (_isOpen && _filteredOptions.isNotEmpty) {
        _selectOption(_filteredOptions.first, advanceFocus: true);
        return;
      }
      widget.onSubmitted?.call(value);
    }

    final guard = widget.keyHoldGuard;
    if (guard == null) {
      action();
      return;
    }
    guard.runOnce(
      keys: {
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
      },
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        key: _fieldBoxKey,
        child: _VerticalArrowKeyGuard(
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            cursorColor: AppColors.cursor,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            textInputAction: TextInputAction.search,
            onTap: _showMenu,
            onChanged: widget.onChanged,
            onSubmitted: _submit,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseAutocompleteMenu<T> extends StatelessWidget {
  const _PurchaseAutocompleteMenu({
    required this.width,
    required this.maxHeight,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
    this.optionSubtitle,
  });

  final double width;
  final double maxHeight;
  final List<T> options;
  final String Function(T option) optionLabel;
  final String Function(T option)? optionSubtitle;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: DecoratedBox(
          key: const Key('appPurchaseAutocompleteMenu'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppModuleColors.purchases),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: options.isEmpty
                  ? const SizedBox(
                      height: 46,
                      child: Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      primary: false,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final option in options)
                            _PurchaseAutocompleteOption<T>(
                              option: option,
                              label: optionLabel(option),
                              subtitle: optionSubtitle?.call(option),
                              onSelected: onSelected,
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseAutocompleteOption<T> extends StatefulWidget {
  const _PurchaseAutocompleteOption({
    required this.option,
    required this.label,
    required this.onSelected,
    this.subtitle,
  });

  final T option;
  final String label;
  final String? subtitle;
  final ValueChanged<T> onSelected;

  @override
  State<_PurchaseAutocompleteOption<T>> createState() =>
      _PurchaseAutocompleteOptionState<T>();
}

class _PurchaseAutocompleteOptionState<T>
    extends State<_PurchaseAutocompleteOption<T>> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle?.trim();
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(widget.option),
        child: Container(
          key: ValueKey('appPurchaseAutocompleteOption-${widget.label}'),
          height: 50,
          width: double.infinity,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered ? _purchaseHoverTint : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: hasSubtitle
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: (Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle())
                          .copyWith(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: kTextHeightNone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: (Theme.of(context).textTheme.bodySmall ??
                              const TextStyle())
                          .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: kTextHeightNone,
                      ),
                    ),
                  ],
                )
              : Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: (Theme.of(context).textTheme.bodyMedium ??
                          const TextStyle())
                      .copyWith(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: kTextHeightNone,
                  ),
                ),
        ),
      ),
    );
  }
}

class AppPurchaseInvoiceCellDropdown extends StatefulWidget {
  const AppPurchaseInvoiceCellDropdown({
    required this.value,
    required this.focusNode,
    required this.enabled,
    required this.options,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.nextFocusNode,
  });

  final String value;
  final FocusNode focusNode;
  final bool enabled;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final FocusNode? nextFocusNode;

  @override
  State<AppPurchaseInvoiceCellDropdown> createState() =>
      _AppPurchaseInvoiceCellDropdownState();
}

class _AppPurchaseInvoiceCellDropdownState
    extends State<AppPurchaseInvoiceCellDropdown> {
  final _layerLink = LayerLink();
  final _fieldBoxKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  var _overlayRebuildScheduled = false;

  bool get _isOpen => _overlayEntry != null;

  String? get _selectedValue =>
      widget.options.contains(widget.value) ? widget.value : null;

  @override
  void didUpdateWidget(
    covariant AppPurchaseInvoiceCellDropdown oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) {
      _hideMenu(updateState: false);
    } else {
      _scheduleOverlayRebuild();
    }
  }

  @override
  void deactivate() {
    _hideMenu(updateState: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _hideMenu(updateState: false);
    super.dispose();
  }

  void _toggleMenu() {
    if (!widget.enabled) return;
    widget.focusNode.requestFocus();
    if (_isOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _scheduleOverlayRebuild() {
    if (_overlayEntry == null || _overlayRebuildScheduled) return;
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted || _overlayEntry == null) return;
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _showMenu() {
    if (!mounted || !widget.enabled || _isOpen) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final fieldRenderObject =
        _fieldBoxKey.currentContext?.findRenderObject();
    final overlayRenderObject = overlay?.context.findRenderObject();
    if (overlay == null ||
        fieldRenderObject is! RenderBox ||
        overlayRenderObject is! RenderBox ||
        !fieldRenderObject.attached ||
        !overlayRenderObject.attached ||
        !fieldRenderObject.hasSize ||
        !overlayRenderObject.hasSize) {
      return;
    }

    final fieldSize = fieldRenderObject.size;
    final fieldOffset = fieldRenderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );
    final overlaySize = overlayRenderObject.size;
    final spaceBelow =
        overlaySize.height - fieldOffset.dy - fieldSize.height;
    final spaceAbove = fieldOffset.dy;
    final openBelow = spaceBelow >= 180 || spaceBelow >= spaceAbove;
    final availableSpace = (openBelow ? spaceBelow : spaceAbove) - 12;
    final maxMenuHeight =
        availableSpace.clamp(96.0, 260.0).toDouble();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: openBelow
                  ? Alignment.bottomRight
                  : Alignment.topRight,
              followerAnchor: openBelow
                  ? Alignment.topRight
                  : Alignment.bottomRight,
              offset: Offset(0, openBelow ? 4 : -4),
              showWhenUnlinked: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _PurchaseDropdownMenu(
                  width: fieldSize.width,
                  maxHeight: maxMenuHeight,
                  options: widget.options,
                  selectedValue: widget.value,
                  onSelected: _selectValue,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _hideMenu({bool updateState = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    _overlayRebuildScheduled = false;
    entry?.remove();
    if (mounted && updateState) setState(() {});
  }

  void _selectValue(String value, {bool advanceFocus = false}) {
    widget.onChanged(value);
    _hideMenu();
    if (advanceFocus) widget.nextFocusNode?.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    if (key == LogicalKeyboardKey.tab) {
      if (_isOpen) _hideMenu();
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.escape && _isOpen) {
      if (event is KeyDownEvent) _hideMenu();
      return KeyEventResult.handled;
    }

    if (!isEnter) return KeyEventResult.ignored;
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_isOpen) {
      final selectedValue = _selectedValue ??
          (widget.options.isEmpty ? null : widget.options.first);
      if (selectedValue != null) {
        _selectValue(selectedValue, advanceFocus: true);
      }
      return KeyEventResult.handled;
    }

    _showMenu();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.enabled ? _textPrimary : AppColors.textSecondary;

    final dropdown = FractionallySizedBox(
      widthFactor: 1,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          key: _fieldBoxKey,
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: MouseRegion(
            key: widget.fieldKey,
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: SizedBox(
              height: AppInvoiceItemsTable.cellHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Icon(
                        _isOpen
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: widget.enabled
                            ? AppModuleColors.purchases
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      Expanded(
                        child: Text(
                          _selectedValue ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: widget.enabled,
      onKeyEvent: _handleKeyEvent,
      child: dropdown,
    );
  }
}

class _PurchaseDropdownMenu extends StatelessWidget {
  const _PurchaseDropdownMenu({
    required this.width,
    required this.maxHeight,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final double width;
  final double maxHeight;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: DecoratedBox(
          key: const Key('appPurchaseWarehouseMenu'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppModuleColors.purchases),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in options)
                        _PurchaseDropdownMenuItem(
                          option: option,
                          selected: option == selectedValue,
                          onSelected: onSelected,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseDropdownMenuItem extends StatefulWidget {
  const _PurchaseDropdownMenuItem({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final String option;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  State<_PurchaseDropdownMenuItem> createState() =>
      _PurchaseDropdownMenuItemState();
}

class _PurchaseDropdownMenuItemState
    extends State<_PurchaseDropdownMenuItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? _purchaseSelectedRowTint
        : _hovered
            ? _purchaseHoverTint
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.selected) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(widget.option),
        child: Container(
          key: ValueKey('appPurchaseWarehouseOption-${widget.option}'),
          height: 44,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.option,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.selected
                  ? AppModulePalettes.purchases.dark
                  : _textPrimary,
              fontSize: 18,
              fontWeight:
                  widget.selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalArrowKeyGuard extends StatelessWidget {
  const _VerticalArrowKeyGuard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _ConsumeVerticalArrowIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _ConsumeVerticalArrowIntent(),
      },
      child: Actions(
        actions: {
          _ConsumeVerticalArrowIntent:
              CallbackAction<_ConsumeVerticalArrowIntent>(
            onInvoke: (_) => null,
          ),
        },
        child: child,
      ),
    );
  }
}

class _ConsumeVerticalArrowIntent extends Intent {
  const _ConsumeVerticalArrowIntent();
}

const _textPrimary = Color(0xFF111827);

final Color _purchaseSelectedRowTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.58,
)!;

final Color _purchaseHoverTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.78,
)!;
