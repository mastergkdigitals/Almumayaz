import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_fields.dart';

class AppActionBar extends StatelessWidget {
  const AppActionBar({
    required this.searchController,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    required this.onSave,
    required this.onUpdate,
    required this.onUndo,
    required this.onDelete,
    super.key,
    this.searchFieldKey,
    this.searchClearButtonKey,
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
    this.buttonWidth = 108,
  });

  final TextEditingController searchController;
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
  final double buttonWidth;

  @override
  Widget build(BuildContext context) {
    const actionPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xs);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppRecordNavigation(
            firstButtonKey: firstButtonKey,
            buttonWidth: buttonWidth,
            previousButtonKey: previousButtonKey,
            nextButtonKey: nextButtonKey,
            lastButtonKey: lastButtonKey,
            onFirst: onFirst,
            onPrevious: onPrevious,
            onNext: onNext,
            onLast: onLast,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppSearchField(
              controller: searchController,
              fieldKey: searchFieldKey,
              clearButtonKey: searchClearButtonKey,
              label: searchLabel,
              hint: searchHint,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Wrap(
            textDirection: TextDirection.rtl,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: saveButtonKey,
                label: 'حفظ',
                icon: Icons.save_rounded,
                width: buttonWidth,
                padding: actionPadding,
                iconSize: 18,
                iconSpacing: AppSpacing.xs,
                onPressed: onSave,
              ),
              AppButton(
                key: updateButtonKey,
                label: 'تحديث',
                icon: Icons.update_rounded,
                variant: AppButtonVariant.success,
                width: buttonWidth,
                padding: actionPadding,
                iconSize: 18,
                iconSpacing: AppSpacing.xs,
                onPressed: onUpdate,
              ),
              AppButton(
                key: undoButtonKey,
                label: 'تراجع',
                icon: Icons.undo_rounded,
                variant: AppButtonVariant.warning,
                width: buttonWidth,
                padding: actionPadding,
                iconSize: 18,
                iconSpacing: AppSpacing.xs,
                onPressed: onUndo,
              ),
              AppButton(
                key: deleteButtonKey,
                label: 'حذف',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                width: buttonWidth,
                padding: actionPadding,
                iconSize: 18,
                iconSpacing: AppSpacing.xs,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
