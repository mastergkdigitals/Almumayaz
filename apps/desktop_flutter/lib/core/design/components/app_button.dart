import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant {
  primary,
  success,
  warning,
  neutral,
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
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.textStyle,
    this.isLoading = false,
    this.width,
    this.minWidth,
    this.height = AppControlHeights.standard,
  }) : assert(
          width == null || minWidth == null,
          'Provide either width or minWidth, not both.',
        );

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final bool flipIconHorizontally;
  final double iconSize;
  final double iconSpacing;
  final EdgeInsetsGeometry? padding;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final TextStyle? textStyle;
  final bool isLoading;
  final double? width;
  final double? minWidth;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const _defaultHoverScale = 1.03;
  static const _defaultPressedScale = 0.96;
  static const _defaultPressDuration = Duration(milliseconds: 70);
  static const _navigationHoverScale = 1.04;
  static const _navigationPressedScale = 0.94;
  static const _navigationAnimationDuration =
      Duration(milliseconds: 130);

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

    final EdgeInsetsGeometry? effectivePadding =
        widget.padding ??
            (widget.width == null && widget.minWidth == null
                ? null
                : EdgeInsets.symmetric(
                    horizontal: hasLabel ? AppSpacing.xs : 0,
                  ));

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
                  style: widget.textStyle ?? AppTypography.buttonText,
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
        padding: effectivePadding == null
            ? null
            : WidgetStatePropertyAll<EdgeInsetsGeometry>(
                effectivePadding,
              ),
        minimumSize: widget.minWidth == null
            ? null
            : WidgetStatePropertyAll<Size>(
                Size(widget.minWidth!, widget.height),
              ),
        mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>(
          (states) => states.contains(WidgetState.disabled)
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
        ),
        splashFactory: NoSplash.splashFactory,
        shape: widget.borderRadius == null
            ? null
            : WidgetStatePropertyAll<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius!),
                ),
              ),
      );
    }

    ButtonStyle navigationStyle() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final foreground = widget.foregroundColor ??
          (isDark
              ? const Color(0xFFF9FAFB)
              : const Color(0xFF111827));
      final border =
          isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB);
      final background = widget.backgroundColor ??
          (isDark ? const Color(0xFF111827) : AppColors.surface);
      final pressedBackground =
          isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
      final outline =
          isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
      final focusRing =
          isDark ? const Color(0xFF60A5FA) : AppColors.blue;
      final radius = widget.borderRadius ?? 14;

      return withoutShadow(
        OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ).copyWith(
        animationDuration: const Duration(milliseconds: 160),
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return background.withValues(alpha: isDark ? 0.40 : 0.55);
            }
            if (states.contains(WidgetState.pressed)) {
              return pressedBackground;
            }
            return background;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.disabled)
              ? foreground.withValues(alpha: 0.38)
              : foreground,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: border.withValues(alpha: 0.55),
              );
            }
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: focusRing);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return BorderSide(color: outline);
            }
            return BorderSide(color: border);
          },
        ),
      );
    }

    final button = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppColors.blue,
              foregroundColor:
                  widget.foregroundColor ?? AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.success => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppColors.green,
              foregroundColor:
                  widget.foregroundColor ?? AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.warning => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppColors.orange,
              foregroundColor:
                  widget.foregroundColor ?? AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.neutral => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppColors.grey,
              foregroundColor:
                  widget.foregroundColor ?? AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            OutlinedButton.styleFrom(
              foregroundColor:
                  widget.foregroundColor ?? AppColors.navigation,
              disabledForegroundColor: AppColors.disabled,
              backgroundColor:
                  widget.backgroundColor ?? AppColors.surface,
              disabledBackgroundColor: AppColors.disabledSurface,
            ).copyWith(
              side: WidgetStateProperty.resolveWith<BorderSide?>(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? AppColors.disabled
                      : (widget.foregroundColor ?? AppColors.navigation),
                ),
              ),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.navigation => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: navigationStyle(),
          child: content,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppColors.red,
              foregroundColor:
                  widget.foregroundColor ?? AppColors.onStrong,
            ),
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: withoutShadow(
            TextButton.styleFrom(
              foregroundColor:
                  widget.foregroundColor ?? AppColors.navigation,
              backgroundColor: widget.backgroundColor,
            ),
          ),
          child: content,
        ),
    };

    final usesNavigationInteraction =
        widget.variant == AppButtonVariant.navigation;
    final hoverScale = usesNavigationInteraction
        ? _navigationHoverScale
        : _defaultHoverScale;
    final pressedScale = usesNavigationInteraction
        ? _navigationPressedScale
        : _defaultPressedScale;
    final scale = !_isInteractive
        ? 1.0
        : _isPressed
            ? pressedScale
            : _isHovered
                ? hoverScale
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
          duration: usesNavigationInteraction
              ? _navigationAnimationDuration
              : _isPressed
                  ? _defaultPressDuration
                  : AppDurations.fast,
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

class AppRegularButton extends StatelessWidget {
  const AppRegularButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.iconPosition = AppButtonIconPosition.beforeLabel,
    this.flipIconHorizontally = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final bool flipIconHorizontally;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconPosition: iconPosition,
      flipIconHorizontally: flipIconHorizontally,
      iconSize: defaultIconSize,
      iconSpacing: defaultIconSpacing,
      padding: defaultPadding,
      variant: AppButtonVariant.navigation,
      textStyle: defaultTextStyle,
      isLoading: isLoading,
      minWidth: defaultMinWidth,
      height: defaultHeight,
    );
  }

  static const double defaultMinWidth = 104;
  static const double defaultHeight = 52;
  static const EdgeInsetsGeometry defaultPadding =
      EdgeInsets.symmetric(horizontal: 14);
  static const double defaultIconSize = AppIconSizes.md;
  static const double defaultIconSpacing = AppSpacing.sm;
  static const TextStyle defaultTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
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
    this.buttonWidth = AppRegularButton.defaultMinWidth,
    this.buttonHeight = AppRegularButton.defaultHeight,
    this.buttonPadding = AppRegularButton.defaultPadding,
    this.iconSize = AppRegularButton.defaultIconSize,
    this.iconSpacing = AppRegularButton.defaultIconSpacing,
    this.spacing = AppSpacing.sm,
    this.textStyle = AppRegularButton.defaultTextStyle,
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
  final double buttonHeight;
  final EdgeInsetsGeometry buttonPadding;
  final double iconSize;
  final double iconSpacing;
  final double spacing;
  final TextStyle textStyle;

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
            minWidth: buttonWidth,
            height: buttonHeight,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            textStyle: textStyle,
            onPressed: onFirst,
          ),
          AppButton(
            key: previousButtonKey,
            label: 'السابق',
            icon: Icons.chevron_left_rounded,
            variant: variant,
            minWidth: buttonWidth,
            height: buttonHeight,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            textStyle: textStyle,
            onPressed: onPrevious,
          ),
          AppButton(
            key: nextButtonKey,
            label: 'التالي',
            icon: Icons.chevron_right_rounded,
            variant: variant,
            minWidth: buttonWidth,
            height: buttonHeight,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            textStyle: textStyle,
            onPressed: onNext,
          ),
          AppButton(
            key: lastButtonKey,
            label: 'الأخير',
            icon: Icons.last_page_rounded,
            variant: variant,
            minWidth: buttonWidth,
            height: buttonHeight,
            padding: buttonPadding,
            iconSize: iconSize,
            iconSpacing: iconSpacing,
            textStyle: textStyle,
            onPressed: onLast,
          ),
        ],
      ),
    );
  }
}
