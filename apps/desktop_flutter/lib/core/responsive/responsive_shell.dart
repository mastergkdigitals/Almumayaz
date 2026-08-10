import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../design/app_tokens.dart';

abstract final class ResponsiveDesktopConfig {
  static const double designWidth = AppBreakpoints.designWidth;
  static const double compactBreakpoint = AppBreakpoints.compactDesktop;

  static const String compactDesktop = 'COMPACT_DESKTOP';
  static const String desktop = 'DESKTOP';
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
      child: ResponsiveScaledBox(
        width: ResponsiveDesktopConfig.designWidth,
        autoCalculateMediaQueryData: true,
        child: child,
      ),
    );
  }
}
