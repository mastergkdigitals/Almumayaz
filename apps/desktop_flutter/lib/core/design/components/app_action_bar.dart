import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_fields.dart';

class AppActionBar extends StatelessWidget {
  const AppActionBar({
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    required this.onSave,
    required this.onUpdate,
    required this.onUndo,
    required this.onDelete,
    super.key,
    this.searchController,
    this.middle,
    this.searchFieldKey,
    this.searchClearButtonKey,
    this.searchFocusNode,
    this.firstButtonKey,
    this.previousButtonKey,
    this.nextButtonKey,
    this.lastButtonKey,
    this.saveButtonKey,
    this.updateButtonKey,
    this.undoButtonKey,
    this.deleteButtonKey,
    this.searchLabel = 'بحث',
    this.searchHint,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.navigationButtonWidth = 104,
    this.buttonWidth = 108,
  }) : assert(
          searchController != null || middle != null,
          'Provide either searchController or middle.',
        );

  static const _compactWidth = 1180.0;
  static const _actionPadding = EdgeInsets.symmetric(horizontal: 6);
  static const _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  final TextEditingController? searchController;
  final Widget? middle;
  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;
  final VoidCallback? onSave;
  final VoidCallback? onUpdate;
  final VoidCallback? onUndo;
  final VoidCallback? onDelete;
  final Key? searchFieldKey;
  final Key? searchClearButtonKey;
  final FocusNode? searchFocusNode;
  final Key? firstButtonKey;
  final Key? previousButtonKey;
  final Key? nextButtonKey;
  final Key? lastButtonKey;
  final Key? saveButtonKey;
  final Key? updateButtonKey;
  final Key? undoButtonKey;
  final Key? deleteButtonKey;
  final String searchLabel;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final double navigationButtonWidth;
  final double buttonWidth;

  Widget _navigation() {
    return AppRecordNavigation(
      firstButtonKey: firstButtonKey,
      previousButtonKey: previousButtonKey,
      nextButtonKey: nextButtonKey,
      lastButtonKey: lastButtonKey,
      buttonWidth: navigationButtonWidth,
      onFirst: onFirst,
      onPrevious: onPrevious,
      onNext: onNext,
      onLast: onLast,
    );
  }

  Widget _middle() {
    final customMiddle = middle;
    if (customMiddle != null) return customMiddle;

    return AppSearchField(
      controller: searchController!,
      fieldKey: searchFieldKey,
      clearButtonKey: searchClearButtonKey,
      focusNode: searchFocusNode,
      label: searchLabel,
      hint: searchHint,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );
  }

  Widget _actions() {
    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          key: saveButtonKey,
          label: 'حفظ',
          icon: Icons.save_rounded,
          width: buttonWidth,
          height: 52,
          padding: _actionPadding,
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _buttonTextStyle,
          onPressed: onSave,
        ),
        AppButton(
          key: updateButtonKey,
          label: 'تحديث',
          icon: Icons.update_rounded,
          variant: AppButtonVariant.success,
          width: buttonWidth,
          height: 52,
          padding: _actionPadding,
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _buttonTextStyle,
          onPressed: onUpdate,
        ),
        AppButton(
          key: undoButtonKey,
          label: 'تراجع',
          icon: Icons.undo_rounded,
          variant: AppButtonVariant.warning,
          width: buttonWidth,
          height: 52,
          padding: _actionPadding,
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _buttonTextStyle,
          onPressed: onUndo,
        ),
        AppButton(
          key: deleteButtonKey,
          label: 'حذف',
          icon: Icons.delete_rounded,
          variant: AppButtonVariant.danger,
          width: buttonWidth,
          height: 52,
          padding: _actionPadding,
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _buttonTextStyle,
          onPressed: onDelete,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _compactWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _navigation(),
                ),
                const SizedBox(height: AppSpacing.md),
                _middle(),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _actions(),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _navigation(),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _middle()),
              const SizedBox(width: AppSpacing.md),
              _actions(),
            ],
          );
        },
      ),
    );
  }
}
