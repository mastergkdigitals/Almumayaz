import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';

class ReportShortcutScope extends StatelessWidget {
  const ReportShortcutScope({
    required this.allowPrint,
    required this.allowExport,
    required this.onSearch,
    required this.onPrint,
    required this.onPdf,
    required this.onExcel,
    required this.child,
    super.key,
  });

  final bool allowPrint;
  final bool allowExport;
  final VoidCallback onSearch;
  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final VoidCallback onExcel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        if (allowPrint)
          const SingleActivator(LogicalKeyboardKey.keyP, control: true):
              onPrint,
        if (allowExport) ...{
          const SingleActivator(
            LogicalKeyboardKey.keyP,
            control: true,
            shift: true,
          ): onPdf,
          const SingleActivator(LogicalKeyboardKey.keyE, control: true):
              onExcel,
        },
      },
      child: AppShortcutScope(
        onSearch: onSearch,
        child: child,
      ),
    );
  }
}
