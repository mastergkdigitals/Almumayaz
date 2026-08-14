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
        AppStatusTone.success => AppColors.successForeground,
        AppStatusTone.warning => AppColors.warningForeground,
        AppStatusTone.danger => AppColors.dangerForeground,
        AppStatusTone.info => AppColors.infoForeground,
        AppStatusTone.neutral => AppColors.neutralForeground,
      };

  Color get _background => switch (tone) {
        AppStatusTone.success => AppColors.successSurface,
        AppStatusTone.warning => AppColors.warningSurface,
        AppStatusTone.danger => AppColors.dangerSurface,
        AppStatusTone.info => AppColors.infoSurface,
        AppStatusTone.neutral => AppColors.neutralSurface,
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


class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    required this.message,
    super.key,
    this.icon = Icons.info_rounded,
    this.foregroundColor = AppColors.infoForeground,
    this.backgroundColor = AppColors.infoSurface,
    this.textAlign = TextAlign.start,
    this.announce = false,
  });

  final String message;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final TextAlign textAlign;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: foregroundColor.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: AppIconSizes.md),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              message,
              textAlign: textAlign,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (!announce) return banner;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: banner,
    );
  }
}

enum AppStateType {
  empty,
  missingReference,
  error,
  loading,
  permissionDenied,
  unavailable,
}

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
        AppStateType.missingReference => Icons.link_off_rounded,
        AppStateType.error => Icons.error_outline_rounded,
        AppStateType.loading => Icons.hourglass_top_rounded,
        AppStateType.permissionDenied => Icons.lock_outline_rounded,
        AppStateType.unavailable => Icons.block_rounded,
      };

  Color get _color => switch (type) {
        AppStateType.empty => AppColors.neutralForeground,
        AppStateType.missingReference => AppColors.warningForeground,
        AppStateType.error => AppColors.dangerForeground,
        AppStateType.loading => AppColors.infoForeground,
        AppStateType.permissionDenied => AppColors.dangerForeground,
        AppStateType.unavailable => AppColors.neutralForeground,
      };

  Color get _surfaceColor => switch (type) {
        AppStateType.empty => AppColors.neutralSurface,
        AppStateType.missingReference => AppColors.warningSurface,
        AppStateType.error || AppStateType.permissionDenied =>
          AppColors.dangerSurface,
        AppStateType.loading => AppColors.infoSurface,
        AppStateType.unavailable => AppColors.disabledSurface,
      };

  Color get _borderColor => _color.withAlpha(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: '$title. $message',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == AppStateType.loading)
                  const AppLoadingIndicator(size: 40, strokeWidth: 4)
                else
                  Icon(_icon, size: 40, color: _color),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.sectionTitle.copyWith(color: _color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.neutralForeground,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppRegularButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

abstract final class AppToast {
  static const duration = Duration(seconds: 2);

  static void showSuccess(
    BuildContext context,
    String message, {
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      message,
      AppColors.successStrong,
      Icons.check_circle_rounded,
      messenger: messenger,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      message,
      AppColors.blue,
      Icons.info_rounded,
      messenger: messenger,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      message,
      AppColors.warningStrong,
      Icons.warning_rounded,
      messenger: messenger,
    );
  }

  static void showDanger(
    BuildContext context,
    String message, {
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      message,
      AppColors.red,
      Icons.delete_rounded,
      messenger: messenger,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      message,
      AppColors.red,
      Icons.error_rounded,
      messenger: messenger,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    ScaffoldMessengerState? messenger,
  }) {
    (messenger ?? ScaffoldMessenger.of(context))
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
                Icon(icon, color: AppColors.onStrong),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.onStrong,
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
