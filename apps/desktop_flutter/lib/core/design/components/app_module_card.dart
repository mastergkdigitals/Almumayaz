import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_header_button.dart';

/// Shared gradient card used to enter a top-level application module.
class AppModuleCard extends StatefulWidget {
  const AppModuleCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    this.imageAsset,
    this.onTap,
    this.disabledReason,
    super.key,
  }) : assert(
          onTap == null || disabledReason == null,
          'An interactive module card cannot also be disabled.',
        );

  final String title;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final String? imageAsset;
  final VoidCallback? onTap;
  final String? disabledReason;

  @override
  State<AppModuleCard> createState() => _AppModuleCardState();
}

class _AppModuleCardState extends State<AppModuleCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final disabledReason = widget.disabledReason?.trim();
    final disabled = !interactive &&
        disabledReason != null &&
        disabledReason.isNotEmpty;
    final lift = interactive && _hovered && !_pressed ? -4.0 : 0.0;
    final scale = _pressed
        ? 0.985
        : interactive && _hovered
            ? 1.01
            : 1.0;

    final gradientColors = disabled
        ? <Color>[
            Color.lerp(AppColors.textPrimary, AppColors.grey, 0.58)!,
            AppColors.grey,
          ]
        : widget.colors;

    final card = Semantics(
      container: true,
      excludeSemantics: true,
      button: interactive || disabled,
      enabled: interactive || disabled ? interactive : null,
      focused: interactive ? _focused : null,
      label: widget.title,
      hint: disabled ? 'غير متاح. $disabledReason' : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, lift, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradientColors,
            ),
            border: _focused
                ? Border.all(color: AppColors.onStrong, width: 2)
                : null,
            boxShadow: [
              if (_focused)
                const BoxShadow(
                  color: AppColors.navigation,
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: (disabled ? AppColors.grey : widget.shadowColor)
                    .withValues(
                  alpha: _hovered ? 0.24 : 0.16,
                ),
                blurRadius: _hovered ? 24 : 16,
                offset: Offset(0, _hovered ? 12 : 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              overlayColor:
                  const WidgetStatePropertyAll<Color>(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onHover: interactive
                  ? (value) => setState(() => _hovered = value)
                  : null,
              onHighlightChanged: interactive
                  ? (value) => setState(() => _pressed = value)
                  : null,
              onFocusChange: (value) => setState(() => _focused = value),
              mouseCursor: interactive
                  ? SystemMouseCursors.click
                  : disabled
                      ? SystemMouseCursors.forbidden
                      : SystemMouseCursors.basic,
              child: Stack(
                children: [
                  _DecorativeIcon(
                    icon: widget.icon,
                    size: 92,
                    top: -18,
                    left: 24,
                    opacity: 0.12,
                  ),
                  _DecorativeIcon(
                    icon: widget.icon,
                    size: 46,
                    top: 28,
                    right: 26,
                    opacity: 0.15,
                  ),
                  _DecorativeIcon(
                    icon: widget.icon,
                    size: 64,
                    bottom: 18,
                    left: 34,
                    opacity: 0.11,
                  ),
                  _DecorativeIcon(
                    icon: widget.icon,
                    size: 34,
                    bottom: 28,
                    right: 38,
                    opacity: 0.17,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(
                              color:
                                  AppColors.onStrong.withValues(alpha: 0.45),
                            ),
                          ),
                          child: _ModuleCardIdentity(
                            icon: widget.icon,
                            imageAsset: widget.imageAsset,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.onStrong,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return disabled
        ? AppTooltip(message: disabledReason, child: card)
        : card;
  }
}

class _ModuleCardIdentity extends StatelessWidget {
  const _ModuleCardIdentity({required this.icon, this.imageAsset});

  final IconData icon;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset?.trim();
    if (asset == null || asset.isEmpty) {
      return Icon(icon, color: AppColors.onStrong, size: 34);
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        asset,
        key: const Key('appModuleCardLogo'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          icon,
          color: AppColors.onStrong,
          size: 34,
        ),
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  const _DecorativeIcon({
    required this.icon,
    required this.size,
    required this.opacity,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final IconData icon;
  final double size;
  final double opacity;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: ExcludeSemantics(
        child: Icon(
          icon,
          size: size,
          color: AppColors.onStrong.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
