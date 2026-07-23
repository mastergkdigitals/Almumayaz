import 'package:flutter/material.dart';

import '../../../core/design/app_tokens.dart';

class DashboardCard extends StatefulWidget {
  const DashboardCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback? onTap;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final lift = interactive && _hovered && !_pressed ? -4.0 : 0.0;
    final scale = _pressed
        ? 0.985
        : interactive && _hovered
            ? 1.01
            : 1.0;

    return Semantics(
      button: interactive,
      label: widget.title,
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
              colors: widget.colors,
            ),
            border: _focused
                ? Border.all(color: AppColors.onStrong, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(
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
              onHover: interactive
                  ? (value) => setState(() => _hovered = value)
                  : null,
              onHighlightChanged: interactive
                  ? (value) => setState(() => _pressed = value)
                  : null,
              onFocusChange: (value) => setState(() => _focused = value),
              mouseCursor: interactive
                  ? SystemMouseCursors.click
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
                            color: AppColors.onStrong.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(
                              color:
                                  AppColors.onStrong.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: AppColors.onStrong,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
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
