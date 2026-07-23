import 'package:flutter/material.dart';

class ResponsiveInfo {
  const ResponsiveInfo({
    required this.isCompact,
    required this.availableWidth,
  });

  final bool isCompact;
  final double availableWidth;
}

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    required this.builder,
    super.key,
    this.maxContentWidth = 1440,
    this.compactBreakpoint = 1180,
  });

  final Widget Function(BuildContext, ResponsiveInfo) builder;
  final double maxContentWidth;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, maxContentWidth).toDouble();
        final info = ResponsiveInfo(
          isCompact: constraints.maxWidth < compactBreakpoint,
          availableWidth: width,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: builder(context, info),
          ),
        );
      },
    );
  }
}
