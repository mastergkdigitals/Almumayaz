import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_text_fields.dart';

class AppAutocompleteField<T extends Object> extends StatefulWidget {
  const AppAutocompleteField({
    required this.controller,
    required this.label,
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    super.key,
    this.fieldKey,
    this.icon = Icons.search_rounded,
    this.hint,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.loadingText = 'جارٍ تحميل النتائج',
    this.noResultsText = 'لا توجد نتائج مطابقة',
    this.accentColor,
    this.searchTermsForOption,
    this.optionSubtitle,
    this.maxOptions = 24,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.showOptionsOnFocus = true,
    this.showLabel = true,
    this.borderRadius,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<T> options;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final Key? fieldKey;
  final IconData? icon;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool isLoading;
  final String loadingText;
  final String noResultsText;
  final Color? accentColor;
  final Iterable<String> Function(T option)? searchTermsForOption;
  final String Function(T option)? optionSubtitle;
  final int maxOptions;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final bool showOptionsOnFocus;
  final bool showLabel;
  final double? borderRadius;

  @override
  State<AppAutocompleteField<T>> createState() =>
      _AppAutocompleteFieldState<T>();
}

class _AppAutocompleteFieldState<T extends Object>
    extends State<AppAutocompleteField<T>> {
  final _internalFocusNode = FocusNode();
  final _layerLink = LayerLink();
  final _optionsScrollController = ScrollController();
  OverlayEntry? _optionsOverlay;
  var _showAllOptions = false;
  var _isSelecting = false;
  var _highlightedIndex = -1;
  var _optionsWidth = 320.0;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }

    final oldFocusNode = oldWidget.focusNode ?? _internalFocusNode;
    if (oldFocusNode != _focusNode) {
      oldFocusNode.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }

    if (!widget.enabled) {
      _closeOptions();
    } else if (_focusNode.hasFocus) {
      _scheduleOptionsUpdate();
    }
  }

  @override
  void dispose() {
    _closeOptions();
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _optionsScrollController.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_isSelecting) return;
    _showAllOptions = false;
    _highlightedIndex = -1;
    _updateOptions();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _showAllOptions = false;
      _highlightedIndex = -1;
      _closeOptions();
      return;
    }
    _showAllOptionsOnFocus();
  }

  void _showAllOptionsOnFocus() {
    if (!widget.enabled || !widget.showOptionsOnFocus) return;
    _showAllOptions = true;
    _highlightedIndex = -1;
    _updateOptions();
  }

  List<T> _matchingOptions() {
    if (!widget.enabled) return <T>[];
    final query = _showAllOptions
        ? ''
        : _normalizeAutocompleteText(widget.controller.text);
    if (query.isEmpty) {
      return widget.options.take(widget.maxOptions).toList(growable: false);
    }

    final matches = widget.options.where((option) {
      final values = widget.searchTermsForOption?.call(option) ??
          [widget.displayStringForOption(option)];
      return values.any(
        (text) => _normalizeAutocompleteText(text).contains(query),
      );
    }).toList(growable: false);

    matches.sort((first, second) {
      bool startsWithQuery(T option) {
        final values = widget.searchTermsForOption?.call(option) ??
            [widget.displayStringForOption(option)];
        return values.any(
          (text) => _normalizeAutocompleteText(text).startsWith(query),
        );
      }

      final firstStarts = startsWithQuery(first);
      final secondStarts = startsWithQuery(second);
      if (firstStarts == secondStarts) return 0;
      return firstStarts ? -1 : 1;
    });
    return matches.take(widget.maxOptions).toList(growable: false);
  }

  void _scheduleOptionsUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateOptions();
    });
  }

  void _updateOptions() {
    if (!mounted || !_focusNode.hasFocus || !widget.enabled) {
      _closeOptions();
      return;
    }

    final options = _matchingOptions();
    if (_highlightedIndex >= options.length) {
      _highlightedIndex = options.length - 1;
    }
    if (_optionsOverlay == null) {
      final overlay = Overlay.of(context);
      _optionsOverlay = OverlayEntry(builder: _buildOptionsOverlay);
      overlay.insert(_optionsOverlay!);
    } else {
      _optionsOverlay!.markNeedsBuild();
    }
  }

  void _closeOptions() {
    _optionsOverlay?.remove();
    _optionsOverlay = null;
  }

  void _selectOption(T option) {
    final displayText = widget.displayStringForOption(option);
    _isSelecting = true;
    widget.controller.value = TextEditingValue(
      text: displayText,
      selection: TextSelection.collapsed(offset: displayText.length),
    );
    _isSelecting = false;
    _showAllOptions = false;
    _highlightedIndex = -1;
    _closeOptions();
    widget.onSelected(option);
  }

  void _moveHighlight(int offset) {
    if (widget.isLoading) return;
    if (_optionsOverlay == null) {
      _showAllOptions = widget.controller.text.isEmpty;
      _updateOptions();
    }
    final options = _matchingOptions();
    if (options.isEmpty) return;

    if (_highlightedIndex < 0) {
      _highlightedIndex = offset > 0 ? 0 : options.length - 1;
    } else {
      _highlightedIndex =
          (_highlightedIndex + offset + options.length) % options.length;
    }
    _optionsOverlay?.markNeedsBuild();
    _ensureHighlightedOptionIsVisible();
  }

  void _ensureHighlightedOptionIsVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_optionsScrollController.hasClients) return;
      final itemHeight = widget.optionSubtitle == null
          ? AppControlHeights.standard
          : 58.0;
      final targetStart = _highlightedIndex * itemHeight;
      final targetEnd = targetStart + itemHeight;
      final position = _optionsScrollController.position;
      var targetOffset = position.pixels;
      if (targetStart < position.pixels) {
        targetOffset = targetStart;
      } else if (targetEnd >
          position.pixels + position.viewportDimension) {
        targetOffset = targetEnd - position.viewportDimension;
      }
      if (targetOffset != position.pixels) {
        _optionsScrollController.jumpTo(
          targetOffset.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ).toDouble(),
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      if (_selectHighlightedOption()) return KeyEventResult.handled;
      final onSubmitted = widget.onSubmitted;
      if (onSubmitted != null) {
        onSubmitted(widget.controller.text);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showAllOptions = false;
      _highlightedIndex = -1;
      _closeOptions();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _selectHighlightedOption() {
    if (_optionsOverlay == null || widget.isLoading) return false;
    final options = _matchingOptions();
    if (options.isEmpty) return false;
    final index = _highlightedIndex < 0 ? 0 : _highlightedIndex;
    _selectOption(options[index]);
    return true;
  }

  void _handleFieldSubmitted(String value) {
    if (_selectHighlightedOption()) return;
    widget.onSubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final optionsWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;
        if (_optionsWidth != optionsWidth) {
          _optionsWidth = optionsWidth;
          if (_optionsOverlay != null) _scheduleOptionsUpdate();
        }

        return Focus(
          canRequestFocus: false,
          onKeyEvent: _handleKeyEvent,
          child: CompositedTransformTarget(
            link: _layerLink,
            child: AppTextField(
              fieldKey: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focusNode,
              label: widget.label,
              hint: widget.hint,
              helperText: widget.helperText,
              errorText: widget.errorText,
              icon: widget.icon,
              accentColor: accentColor,
              enabled: widget.enabled,
              validator: widget.validator,
              textDirection: widget.textDirection,
              textAlign: widget.textAlign,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onTap: _showAllOptionsOnFocus,
              onSubmitted: _handleFieldSubmitted,
              showLabel: widget.showLabel,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsOverlay(BuildContext context) {
    final options = _matchingOptions();
    final accentColor = widget.accentColor ?? AppColors.primary;
    final borderColor = Color.lerp(
      accentColor,
      AppColors.surface,
      0.62,
    )!;
    final highlightedColor = Color.alphaBlend(
      accentColor.withAlpha(22),
      AppColors.surface,
    );
    final hoverColor = Color.alphaBlend(
      accentColor.withAlpha(14),
      AppColors.surface,
    );

    return Positioned(
      width: _optionsWidth,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, AppSpacing.xs),
        child: Material(
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: AppColors.menuShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: widget.isLoading
                ? _AutocompleteOptionsState(
                    key: const Key('appAutocompleteLoadingState'),
                    message: widget.loadingText,
                    accentColor: accentColor,
                    isLoading: true,
                  )
                : options.isEmpty
                    ? _AutocompleteOptionsState(
                        key: const Key('appAutocompleteNoResultsState'),
                        message: widget.noResultsText,
                        accentColor: accentColor,
                      )
                    : ListView.builder(
                        controller: _optionsScrollController,
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final highlighted = index == _highlightedIndex;
                          return Semantics(
                            button: true,
                            selected: highlighted,
                            child: InkWell(
                              onTap: () => _selectOption(option),
                              onHover: (value) {
                                if (!value ||
                                    _highlightedIndex == index) {
                                  return;
                                }
                                _highlightedIndex = index;
                                _optionsOverlay?.markNeedsBuild();
                              },
                              mouseCursor: SystemMouseCursors.click,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                              hoverColor: hoverColor,
                              child: Container(
                                height: widget.optionSubtitle == null
                                    ? AppControlHeights.standard
                                    : 58,
                                alignment:
                                    AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: highlighted
                                      ? highlightedColor
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Directionality(
                                  textDirection: widget.textDirection ??
                                      TextDirection.rtl,
                                  child: widget.optionSubtitle == null
                                      ? Text(
                                          widget.displayStringForOption(
                                            option,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: AppTypography.fieldText
                                              .copyWith(
                                            color: highlighted
                                                ? accentColor
                                                : AppColors.textPrimary,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              widget
                                                  .displayStringForOption(
                                                option,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: AppTypography.fieldText
                                                  .copyWith(
                                                color: highlighted
                                                    ? accentColor
                                                    : AppColors.textPrimary,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.optionSubtitle!(
                                                option,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: const TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

class _AutocompleteOptionsState extends StatelessWidget {
  const _AutocompleteOptionsState({
    required this.message,
    required this.accentColor,
    this.isLoading = false,
    super.key,
  });

  final String message;
  final Color accentColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: SizedBox(
        height: AppControlHeights.standard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: AppIconSizes.md,
                  child: CircularProgressIndicator(
                    color: accentColor,
                    strokeWidth: 2.4,
                  ),
                )
              else
                Icon(
                  Icons.search_off_rounded,
                  color: accentColor,
                  size: AppIconSizes.md,
                ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.fieldText.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef AppSearchableDropdownField<T extends Object> =
    AppAutocompleteField<T>;

String _normalizeAutocompleteText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه');
}
