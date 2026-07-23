import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

abstract final class AppDialogs {
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppDialogSizes.small),
            child: Padding(
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
                        label: confirmLabel,
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        variant: isDanger
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        width: 120,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        label: cancelLabel,
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        variant: AppButtonVariant.secondary,
                        width: 120,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}
