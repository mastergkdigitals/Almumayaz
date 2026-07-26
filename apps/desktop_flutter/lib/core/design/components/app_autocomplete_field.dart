import 'package:flutter/material.dart';

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
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.accentColor,
    this.searchTermsForOption,
    this.optionSubtitle,
    this.maxOptions = 24,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<T> options;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final Key? fieldKey;
  final IconData icon;
  final String? hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Color? accentColor;
  final Iterable<String> Function(T option)? searchTermsForOption;
  final String Function(T option)? optionSubtitle;
  final int maxOptions;

  @override
  State<AppAutocompleteField<T>> createState() =>
      _AppAutocompleteFieldState<T>();
}

class _AppAutocompleteFieldState<T extends Object>
    extends State<AppAutocompleteField<T>> {
  final _internalFocusNode = FocusNode();

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void dispose() {
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final optionsWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;

        return RawAutocomplete<T>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          displayStringForOption: widget.displayStringForOption,
          optionsBuilder: (value) {
            if (!widget.enabled) return Iterable<T>.empty();
            final query = _normalizeAutocompleteText(value.text);
            if (query.isEmpty) {
              return widget.options.take(widget.maxOptions);
            }

            final matches = widget.options.where((option) {
              final values = widget.searchTermsForOption?.call(option) ??
                  [widget.displayStringForOption(option)];
              return values.any(
                (text) =>
                    _normalizeAutocompleteText(text).contains(query),
              );
            }).toList(growable: false);

            matches.sort((first, second) {
              bool startsWithQuery(T option) {
                final values =
                    widget.searchTermsForOption?.call(option) ??
                        [widget.displayStringForOption(option)];
                return values.any(
                  (text) => _normalizeAutocompleteText(text)
                      .startsWith(query),
                );
              }

              final firstStarts = startsWithQuery(first);
              final secondStarts = startsWithQuery(second);
              if (firstStarts == secondStarts) return 0;
              return firstStarts ? -1 : 1;
            });
            return matches.take(widget.maxOptions);
          },
          onSelected: widget.onSelected,
          fieldViewBuilder: (
            context,
            controller,
            focusNode,
            onFieldSubmitted,
          ) {
            return AppTextField(
              fieldKey: widget.fieldKey,
              controller: controller,
              focusNode: focusNode,
              label: widget.label,
              hint: widget.hint,
              icon: widget.icon,
              accentColor: accentColor,
              enabled: widget.enabled,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                onFieldSubmitted();
                widget.onSubmitted?.call(value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final values = options.toList(growable: false);
            final highlightedIndex =
                AutocompleteHighlightedOption.of(context);

            return Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                color: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 4,
                shadowColor: AppColors.menuShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: optionsWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      shrinkWrap: true,
                      itemCount: values.length,
                      itemBuilder: (context, index) {
                        final option = values[index];
                        final highlighted = index == highlightedIndex;
                        return Semantics(
                          button: true,
                          child: InkWell(
                            onTap: () => onSelected(option),
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            hoverColor: AppColors.controlHoverSurface,
                            child: Container(
                              height: widget.optionSubtitle == null
                                  ? AppControlHeights.standard
                                  : 58,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: highlighted
                                    ? AppColors.infoSurface
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                              ),
                              child: widget.optionSubtitle == null
                                  ? Text(
                                      widget.displayStringForOption(option),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style:
                                          AppTypography.fieldText.copyWith(
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
                                          widget.displayStringForOption(
                                            option,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: AppTypography.fieldText
                                              .copyWith(
                                            color: highlighted
                                                ? accentColor
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.optionSubtitle!(option),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
          },
        );
      },
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
