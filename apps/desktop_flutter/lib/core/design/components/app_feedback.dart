import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_loading_indicator.dart';

enum AppStatusTone { success, warning, danger, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    required this.tone,
    super.key,
  });

  final String label;
  final AppStatusTone tone;

  Color get _foreground => switch (tone) {
        AppStatusTone.success => AppColors.success,
        AppStatusTone.warning => AppColors.warning,
        AppStatusTone.danger => AppColors.danger,
        AppStatusTone.info => AppColors.info,
        AppStatusTone.neutral => AppColors.textSecondary,
      };

  Color get _background => switch (tone) {
        AppStatusTone.success => const Color(0xFFE8F7EF),
        AppStatusTone.warning => const Color(0xFFFFF3E5),
        AppStatusTone.danger => const Color(0xFFFDECEC),
        AppStatusTone.info => const Color(0xFFE8F1FF),
        AppStatusTone.neutral => const Color(0xFFF1F5F9),
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _foreground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum AppStateType { empty, error, loading }

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    required this.type,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final AppStateType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  IconData get _icon => switch (type) {
        AppStateType.empty => Icons.inbox_rounded,
        AppStateType.error => Icons.error_outline_rounded,
        AppStateType.loading => Icons.hourglass_top_rounded,
      };

  Color get _color => switch (type) {
        AppStateType.empty => AppColors.textSecondary,
        AppStateType.error => AppColors.danger,
        AppStateType.loading => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == AppStateType.loading)
            const AppLoadingIndicator(size: 40, strokeWidth: 4)
          else
            Icon(_icon, size: 40, color: _color),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

abstract final class AppToast {
  static const duration = Duration(seconds: 2);

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('appToast'),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          dismissDirection: DismissDirection.none,
          content: IgnorePointer(
            key: const Key('appToastContent'),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
