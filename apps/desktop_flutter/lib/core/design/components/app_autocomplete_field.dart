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
    this.focusNode,
    this.onSubmitted,
    this.enabled = true,
    this.accentColor,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<T> options;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final Key? fieldKey;
  final IconData icon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Color? accentColor;

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
            if (!widget.enabled) return const Iterable<T>.empty();
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return widget.options;
            return widget.options.where(
              (option) => widget
                  .displayStringForOption(option)
                  .toLowerCase()
                  .contains(query),
            );
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
              icon: widget.icon,
              accentColor: accentColor,
              enabled: widget.enabled,
              textInputAction: TextInputAction.search,
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
                              height: AppControlHeights.standard,
                              alignment: Alignment.center,
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
                              child: Text(
                                widget.displayStringForOption(option),
                                textAlign: TextAlign.center,
                                style: AppTypography.fieldText.copyWith(
                                  color: highlighted
                                      ? accentColor
                                      : AppColors.textPrimary,
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
          },
        );
      },
    );
  }
}

typedef AppSearchableDropdownField<T extends Object> =
    AppAutocompleteField<T>;
