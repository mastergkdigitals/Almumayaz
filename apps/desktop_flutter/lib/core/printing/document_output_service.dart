import '../services/service_failure.dart';

enum DocumentExportFormat { pdf, excel }

enum DocumentOutputAction { print, printWithoutPrices, pdf, excel }

class DocumentField {
  const DocumentField({
    required this.label,
    required this.value,
    this.isPrice = false,
  });

  final String label;
  final String value;
  final bool isPrice;
}

class DocumentColumn {
  const DocumentColumn({
    required this.label,
    this.isPrice = false,
  });

  final String label;
  final bool isPrice;
}

class DocumentOutputRequest {
  const DocumentOutputRequest({
    required this.title,
    required this.columns,
    required this.rows,
    this.subtitle,
    this.fileNameBase,
    this.fields = const [],
  });

  final String title;
  final String? subtitle;
  final String? fileNameBase;
  final List<DocumentField> fields;
  final List<DocumentColumn> columns;
  final List<List<String>> rows;
}

class DocumentOutputResult {
  const DocumentOutputResult({
    required this.action,
    required this.title,
    required this.documentTitle,
    required this.content,
    required this.rowCount,
    this.fileName,
  });

  final DocumentOutputAction action;
  final String title;
  final String documentTitle;
  final String content;
  final int rowCount;
  final String? fileName;
}

abstract interface class DocumentPrintService {
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  });
}

abstract interface class DocumentExportService {
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  );
}

abstract interface class DocumentOutputService
    implements DocumentPrintService, DocumentExportService {}

/// Creates deterministic in-app output while native printer and file adapters
/// are not connected. No files are written and no platform APIs are invoked.
class DemoDocumentOutputService implements DocumentOutputService {
  const DemoDocumentOutputService({this.delay = Duration.zero});

  final Duration delay;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) async {
    await _waitIfNeeded();
    _validate(request);

    return DocumentOutputResult(
      action: includePrices
          ? DocumentOutputAction.print
          : DocumentOutputAction.printWithoutPrices,
      title: includePrices
          ? 'معاينة الطباعة'
          : 'معاينة الطباعة بدون أسعار',
      documentTitle: request.title,
      content: _buildContent(
        request,
        separator: ' | ',
        includePrices: includePrices,
      ),
      rowCount: request.rows.length,
    );
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) async {
    await _waitIfNeeded();
    _validate(request);

    final extension = switch (format) {
      DocumentExportFormat.pdf => 'pdf',
      DocumentExportFormat.excel => 'xlsx',
    };
    final action = switch (format) {
      DocumentExportFormat.pdf => DocumentOutputAction.pdf,
      DocumentExportFormat.excel => DocumentOutputAction.excel,
    };
    final title = switch (format) {
      DocumentExportFormat.pdf => 'نتيجة تصدير PDF',
      DocumentExportFormat.excel => 'نتيجة تصدير Excel',
    };

    return DocumentOutputResult(
      action: action,
      title: title,
      documentTitle: request.title,
      content: _buildContent(
        request,
        separator: format == DocumentExportFormat.excel ? '\t' : ' | ',
        includePrices: true,
      ),
      rowCount: request.rows.length,
      fileName: '${_safeFileName(request.fileNameBase ?? request.title)}.'
          '$extension',
    );
  }

  Future<void> _waitIfNeeded() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  void _validate(DocumentOutputRequest request) {
    if (request.title.trim().isEmpty) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        message: 'عنوان المستند مطلوب',
        code: 'document_title_required',
      );
    }
    if (request.columns.isEmpty) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        message: 'يجب تعريف عمود واحد على الأقل للمستند',
        code: 'document_columns_required',
      );
    }
    if (request.rows.any(
      (row) => row.length != request.columns.length,
    )) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        message: 'تعذر تجهيز المستند بسبب عدم تطابق الأعمدة',
        code: 'document_columns_mismatch',
      );
    }
  }

  String _buildContent(
    DocumentOutputRequest request, {
    required String separator,
    required bool includePrices,
  }) {
    final visibleColumnIndexes = <int>[
      for (var index = 0; index < request.columns.length; index++)
        if (includePrices || !request.columns[index].isPrice) index,
    ];
    final visibleFields = request.fields.where(
      (field) => includePrices || !field.isPrice,
    );

    final buffer = StringBuffer()..writeln(request.title);
    final subtitle = request.subtitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.writeln(subtitle);
    }
    if (visibleFields.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          visibleFields
              .map((field) => '${field.label}: ${field.value}')
              .join(separator),
        );
    }
    buffer
      ..writeln()
      ..writeln(
        visibleColumnIndexes
            .map((index) => request.columns[index].label)
            .join(separator),
      );

    if (request.rows.isEmpty) {
      buffer.writeln('لا توجد بيانات ضمن الخيارات المحددة');
    } else {
      for (final row in request.rows) {
        buffer.writeln(
          visibleColumnIndexes.map((index) => row[index]).join(separator),
        );
      }
    }
    return buffer.toString().trimRight();
  }

  String _safeFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'document' : normalized;
  }
}
