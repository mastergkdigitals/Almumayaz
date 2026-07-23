import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant {
  primary,
  success,
  warning,
  secondary,
  navigation,
  danger,
  ghost,
}

enum AppButtonIconPosition { beforeLabel, afterLabel }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.iconPosition = AppButtonIconPosition.beforeLabel,
    this.flipIconHorizontally = false,
    this.iconSize = AppIconSizes.md,
    this.iconSpacing = AppSpacing.sm,
    this.padding,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = AppControlHeights.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final bool flipIconHorizontally;
  final double iconSize;
  final double iconSpacing;
  final EdgeInsetsGeometry? padding;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const _hoverScale = 1.03;
  static const _pressedScale = 0.96;
  static const _pressDuration = Duration(milliseconds: 70);

  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isInteractive => !widget.isLoading && widget.onPressed != null;

  void _setHovered(bool value) {
    if ((!_isInteractive && value) || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if ((!_isInteractive && value) || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInteractive) {
      _isHovered = false;
      _isPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;
    final hasLabel = widget.label.isNotEmpty;
    final rawIcon = widget.icon == null
        ? null
        : Icon(widget.icon, size: widget.iconSize);
    final icon = rawIcon == null || !widget.flipIconHorizontally
        ? rawIcon
        : Transform.flip(flipX: true, child: rawIcon);

    final content = widget.isLoading
        ? const SizedBox.square(
            dimension: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: AppLoadingIndicator(size: 18, strokeWidth: 2.2),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null &&
                  widget.iconPosition == AppButtonIconPosition.beforeLabel) ...[
                icon,
                if (hasLabel) SizedBox(width: widget.iconSpacing),
              ],
              if (hasLabel)
                Text(
                  widget.label,
                  style: AppTypography.buttonText,
                ),
              if (icon != null &&
                  widget.iconPosition == AppButtonIconPosition.afterLabel) ...[
                if (hasLabel) SizedBox(width: widget.iconSpacing),
                icon,
              ],
            ],
          );

    ButtonStyle withoutShadow(ButtonStyle style) {
      return style.copyWith(
        elevation: const WidgetStatePropertyAll<double>(0),
        shadowColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        surfaceTintColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        overlayColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        padding: widget.padding == null
            ? null
            : WidgetStatePropertyAll<EdgeInsetsGeometry>(widget.padding!),
        mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>(
          (states) => states.contains(WidgetState.disabled)
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
        ),
        splashFactory: NoSplash.splashFactory,
      );
    }

    final button = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.success => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.warning => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.navigation,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.navigation),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.navigation => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.navigation,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.navigation),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            TextButton.styleFrom(foregroundColor: AppColors.navigation),
          ),
          child: content,
        ),
    };

    final scale = !_isInteractive
        ? 1.0
        : _isPressed
            ? _pressedScale
            : _isHovered
                ? _hoverScale
                : 1.0;

    return MouseRegion(
      cursor: _isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: scale,
          duration: _isPressed ? _pressDuration : AppDurations.fast,
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: button,
          ),
        ),
      ),
    );
  }
}

class AppRecordNavigation extends StatelessWidget {
  const AppRecordNavigation({
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    super.key,
    this.firstButtonKey,
    this.previousButtonKey,
    this.nextButtonKey,
    this.lastButtonKey,
    this.variant = AppButtonVariant.navigation,
    this.buttonWidth = 108,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 2),
    this.iconSize = 16,
    this.iconSpacing = AppSpacing.xs / 2,
    this.spacing = AppSpacing.sm,
  });

  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;
  final Key? firstButtonKey;
  final Key? previousButtonKey;
  final Key? nextButtonKey;
  final Key? lastButtonKey;
  final AppButtonVariant variant;
  final double buttonWidth;
  final EdgeInsetsGeometry buttonPadding;
  final double iconSize;
  final double iconSpacing;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        textDirection: TextDirection.rtl,
        spacing: spacing,
        runSpacing: spacing,
        children: [
          AppButton(
            key: firstButtonKey,
            label: 'الأول',
            icon: Icons.first_page_rounded,
            variant: variant,
            width: buttonWidth,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            onPressed: onFirst,
          ),
          AppButton(
            key: previousButtonKey,
            label: 'السابق',
            icon: Icons.chevron_left_rounded,
            variant: variant,
            width: buttonWidth,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            onPressed: onPrevious,
          ),
          AppButton(
            key: nextButtonKey,
            label: 'التالي',
            icon: Icons.chevron_right_rounded,
            iconPosition: AppButtonIconPosition.afterLabel,
            variant: variant,
            width: buttonWidth,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            onPressed: onNext,
          ),
          AppButton(
            key: lastButtonKey,
            label: 'الأخير',
            icon: Icons.last_page_rounded,
            iconPosition: AppButtonIconPosition.afterLabel,
            variant: variant,
            width: buttonWidth,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            onPressed: onLast,
          ),
        ],
      ),
    );
  }
}
