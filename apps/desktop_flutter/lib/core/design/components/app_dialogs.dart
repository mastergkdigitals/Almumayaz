import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_shortcuts.dart';

enum AppDialogSize { small, medium, large }

abstract final class AppDialogs {
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool isDanger = false,
    AppDialogSize size = AppDialogSize.small,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final viewport = MediaQuery.sizeOf(dialogContext);

        return AppShortcutScope(
          onEscape: () => Navigator.of(dialogContext).pop(false),
          child: Dialog(
            key: const Key('appConfirmDialog'),
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _widthFor(size),
                maxHeight: viewport.height * AppDialogSizes.maxHeightFactor,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDanger
                          ? Icons.warning_amber_rounded
                          : Icons.help_outline_rounded,
                      color: isDanger ? AppColors.danger : AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(
                          key: const Key('appDialogCancelButton'),
                          label: cancelLabel,
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          variant: AppButtonVariant.secondary,
                          width: 120,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        AppButton(
                          key: const Key('appDialogConfirmButton'),
                          label: confirmLabel,
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          variant: isDanger
                              ? AppButtonVariant.danger
                              : AppButtonVariant.primary,
                          width: 120,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  static double _widthFor(AppDialogSize size) => switch (size) {
        AppDialogSize.small => AppDialogSizes.small,
        AppDialogSize.medium => AppDialogSizes.medium,
        AppDialogSize.large => AppDialogSizes.large,
      };
}
