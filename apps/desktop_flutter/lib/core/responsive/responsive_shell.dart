import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../design/app_theme.dart';

abstract final class ResponsiveDesktopConfig {
  static const double designWidth = 1440;
  static const double maximumScaledWidth = 1728;
  static const double compactBreakpoint = 1280;

  static const String compactDesktop = 'COMPACT_DESKTOP';
  static const String desktop = 'DESKTOP';
}

class ResponsiveInfo {
  const ResponsiveInfo({
    required this.isCompact,
    required this.availableWidth,
  });

  final bool isCompact;
  final double availableWidth;
}

class ResponsiveDesktopShell extends StatelessWidget {
  const ResponsiveDesktopShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(
          start: 0,
          end: ResponsiveDesktopConfig.compactBreakpoint - 1,
          name: ResponsiveDesktopConfig.compactDesktop,
        ),
        Breakpoint(
          start: ResponsiveDesktopConfig.compactBreakpoint,
          end: double.infinity,
          name: ResponsiveDesktopConfig.desktop,
        ),
      ],
      child: MaxWidthBox(
        maxWidth: ResponsiveDesktopConfig.maximumScaledWidth,
        background: const ColoredBox(color: AppColors.background),
        child: ResponsiveScaledBox(
          width: ResponsiveDesktopConfig.designWidth,
          autoCalculateMediaQueryData: true,
          child: child,
        ),
      ),
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
    final breakpoints = ResponsiveBreakpoints.of(context);
    final info = ResponsiveInfo(
      isCompact: breakpoints.equals(
        ResponsiveDesktopConfig.compactDesktop,
      ),
      availableWidth: math.min(
        MediaQuery.sizeOf(context).width,
        maxContentWidth,
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: builder(context, info),
      ),
    );
  }
}
