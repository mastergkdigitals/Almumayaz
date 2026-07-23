import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../design/app_tokens.dart';

abstract final class ResponsiveDesktopConfig {
  static const double designWidth = AppBreakpoints.designWidth;
  static const double compactBreakpoint = AppBreakpoints.compactDesktop;

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

class _ResponsiveDesktopScope extends InheritedWidget {
  const _ResponsiveDesktopScope({
    required this.isCompact,
    required super.child,
  });

  final bool isCompact;

  static bool isCompactOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ResponsiveDesktopScope>();
    assert(scope != null, 'ResponsiveDesktopShell is missing.');
    return scope!.isCompact;
  }

  @override
  bool updateShouldNotify(_ResponsiveDesktopScope oldWidget) {
    return oldWidget.isCompact != isCompact;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < ResponsiveDesktopConfig.compactBreakpoint;

        return _ResponsiveDesktopScope(
          isCompact: isCompact,
          child: ResponsiveBreakpoints.builder(
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
            child: ResponsiveScaledBox(
              width: ResponsiveDesktopConfig.designWidth,
              autoCalculateMediaQueryData: true,
              child: child,
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
    final info = ResponsiveInfo(
      isCompact: _ResponsiveDesktopScope.isCompactOf(context),
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
