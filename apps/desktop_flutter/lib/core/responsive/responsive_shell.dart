import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class ResponsiveDesktopConfig {
  static const double designWidth = 1440;
  static const double minimumScale = 0.88;
  static const double maximumScale = 1.12;
  static const double compactBreakpoint = 1180;
}

class ResponsiveInfo {
  const ResponsiveInfo({
    required this.isCompact,
    required this.availableWidth,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.scale,
  });

  final bool isCompact;
  final double availableWidth;
  final double viewportWidth;
  final double viewportHeight;
  final double scale;
}

class ResponsiveDesktopScope extends InheritedWidget {
  const ResponsiveDesktopScope({
    required this.info,
    required super.child,
    super.key,
  });

  final ResponsiveInfo info;

  static ResponsiveInfo of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ResponsiveDesktopScope>();
    assert(scope != null, 'ResponsiveDesktopShell is missing above this widget.');
    return scope!.info;
  }

  @override
  bool updateShouldNotify(ResponsiveDesktopScope oldWidget) {
    return oldWidget.info.isCompact != info.isCompact ||
        oldWidget.info.availableWidth != info.availableWidth ||
        oldWidget.info.viewportWidth != info.viewportWidth ||
        oldWidget.info.viewportHeight != info.viewportHeight ||
        oldWidget.info.scale != info.scale;
  }
}

class ResponsiveDesktopShell extends StatelessWidget {
  const ResponsiveDesktopShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final physicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaQuery.size.width;
        final physicalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;

        final scale = (physicalWidth / ResponsiveDesktopConfig.designWidth)
            .clamp(
              ResponsiveDesktopConfig.minimumScale,
              ResponsiveDesktopConfig.maximumScale,
            )
            .toDouble();

        final viewportWidth = physicalWidth / scale;
        final viewportHeight = physicalHeight / scale;
        final info = ResponsiveInfo(
          isCompact:
              physicalWidth < ResponsiveDesktopConfig.compactBreakpoint,
          availableWidth: math.min(
            viewportWidth,
            ResponsiveDesktopConfig.designWidth,
          ),
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          scale: scale,
        );

        final scaledContent = MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(viewportWidth, viewportHeight),
          ),
          child: ResponsiveDesktopScope(
            info: info,
            child: child,
          ),
        );

        return SizedBox(
          width: physicalWidth,
          height: physicalHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: viewportWidth,
              maxWidth: viewportWidth,
              minHeight: viewportHeight,
              maxHeight: viewportHeight,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: viewportWidth,
                  height: viewportHeight,
                  child: scaledContent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.builder,
    super.key,
    this.maxContentWidth = ResponsiveDesktopConfig.designWidth,
  });

  final Widget Function(BuildContext, ResponsiveInfo) builder;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final info = ResponsiveDesktopScope.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: builder(context, info),
      ),
    );
  }
}
