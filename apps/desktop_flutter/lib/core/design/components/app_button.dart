import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

enum AppButtonIconPosition { beforeLabel, afterLabel }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.iconPosition = AppButtonIconPosition.beforeLabel,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = AppControlHeights.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
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
    final content = widget.isLoading
        ? const SizedBox.square(
            dimension: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
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
              if (widget.icon != null &&
                  widget.iconPosition == AppButtonIconPosition.beforeLabel) ...[
                Icon(widget.icon, size: AppIconSizes.md),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (widget.icon != null &&
                  widget.iconPosition == AppButtonIconPosition.afterLabel) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(widget.icon, size: AppIconSizes.md),
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
              foregroundColor: Colors.white,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            TextButton.styleFrom(foregroundColor: AppColors.primary),
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
    this.variant = AppButtonVariant.secondary,
    this.buttonWidth = 128,
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
            onPressed: onFirst,
          ),
          AppButton(
            key: previousButtonKey,
            label: 'السابق',
            icon: Icons.chevron_left_rounded,
            variant: variant,
            width: buttonWidth,
            onPressed: onPrevious,
          ),
          AppButton(
            key: nextButtonKey,
            label: 'التالي',
            icon: Icons.chevron_right_rounded,
            iconPosition: AppButtonIconPosition.afterLabel,
            variant: variant,
            width: buttonWidth,
            onPressed: onNext,
          ),
          AppButton(
            key: lastButtonKey,
            label: 'الأخير',
            icon: Icons.last_page_rounded,
            iconPosition: AppButtonIconPosition.afterLabel,
            variant: variant,
            width: buttonWidth,
            onPressed: onLast,
          ),
        ],
      ),
    );
  }
}
