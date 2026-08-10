import 'package:flutter/widgets.dart';

import 'document_output_service.dart';

class DocumentOutputScope extends InheritedWidget {
  const DocumentOutputScope({
    required this.printService,
    required this.exportService,
    required super.child,
    super.key,
  });

  final DocumentPrintService printService;
  final DocumentExportService exportService;

  static DocumentOutputScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<DocumentOutputScope>();
  }

  @override
  bool updateShouldNotify(DocumentOutputScope oldWidget) {
    return printService != oldWidget.printService ||
        exportService != oldWidget.exportService;
  }
}
