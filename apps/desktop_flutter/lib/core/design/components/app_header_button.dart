import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

class AppTooltip extends StatefulWidget {
  const AppTooltip({
    required this.message,
    required this.child,
    super.key,
    this.tooltipKey,
  });

  final String message;
  final Widget child;
  final Key? tooltipKey;

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip> {
  static const _targetGap = 6.0;
  static const _fallbackTargetHeight = 42.0;

  final _targetKey = GlobalKey();
  Size _targetSize = Size.zero;
  bool _measureScheduled = false;

  void _scheduleTargetMeasure() {
    if (_measureScheduled) return;

    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;

      final renderObject = _targetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      final nextSize = renderObject.size;
      if (nextSize != _targetSize) {
        setState(() => _targetSize = nextSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleTargetMeasure();

    final textDirection =
        Directionality.maybeOf(context) ?? TextDirection.rtl;
    final targetHeight = _targetSize.height > 0
        ? _targetSize.height
        : _fallbackTargetHeight;

    return Tooltip(
      key: widget.tooltipKey,
      message: widget.message,
      preferBelow: true,
      verticalOffset: (targetHeight / 2) + _targetGap,
      decoration: BoxDecoration(
        color: AppTooltipColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppTooltipColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: AppTooltipColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: KeyedSubtree(
        key: _targetKey,
        child: Directionality(
          textDirection: textDirection,
          child: widget.child,
        ),
      ),
    );
  }
}

class AppTooltipIconButton extends StatelessWidget {
  const AppTooltipIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.flipIconHorizontally = false,
    this.size = 52,
    this.iconSize = AppIconSizes.lg,
    this.variant = AppButtonVariant.navigation,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final bool flipIconHorizontally;
  final double size;
  final double iconSize;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppTooltip(
      tooltipKey: tooltipKey,
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: AppButton(
          label: '',
          icon: icon,
          flipIconHorizontally: flipIconHorizontally,
          variant: variant,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          width: size,
          height: size,
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          borderRadius: borderRadius,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.flipIconHorizontally = false,
    this.size = 52,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final bool flipIconHorizontally;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppTooltipIconButton(
      tooltipKey: tooltipKey,
      icon: icon,
      tooltip: tooltip,
      flipIconHorizontally: flipIconHorizontally,
      size: size,
      onPressed: onPressed,
    );
  }
}
