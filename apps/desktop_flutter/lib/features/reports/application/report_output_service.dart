enum ReportExportFormat { pdf, excel }

class ReportOutputRequest {
  const ReportOutputRequest({
    required this.reportTitle,
    required this.variantLabel,
    required this.columnLabels,
    required this.rowValues,
    required this.metrics,
  });

  final String reportTitle;
  final String variantLabel;
  final List<String> columnLabels;
  final List<List<String>> rowValues;
  final Map<String, String> metrics;
}

class ReportOutputResult {
  const ReportOutputResult({
    required this.title,
    required this.content,
    required this.rowCount,
    this.fileName,
    this.filePath,
    this.isDemo = true,
  });

  final String title;
  final String content;
  final int rowCount;
  final String? fileName;
  final String? filePath;
  final bool isDemo;
}

abstract interface class ReportPrintService {
  Future<ReportOutputResult> createPreview(ReportOutputRequest request);
}

abstract interface class ReportExportService {
  Future<ReportOutputResult> export(
    ReportOutputRequest request,
    ReportExportFormat format,
  );
}

abstract interface class ReportOutputService
    implements ReportPrintService, ReportExportService {}

class ReportOutputException implements Exception {
  const ReportOutputException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Demo-only output generator.
///
/// It creates a deterministic in-app representation of the filtered report.
/// The desktop composition replaces this with the document-backed native
/// adapter, while widget tests keep this deterministic implementation.
class DemoReportOutputService
    implements ReportOutputService {
  const DemoReportOutputService({
    this.delay = const Duration(milliseconds: 120),
  });

  final Duration delay;

  @override
  Future<ReportOutputResult> createPreview(
    ReportOutputRequest request,
  ) async {
    await Future<void>.delayed(delay);
    _validate(request);
    return ReportOutputResult(
      title: 'معاينة الطباعة',
      rowCount: request.rowValues.length,
      content: _buildContent(request, separator: ' | '),
    );
  }

  @override
  Future<ReportOutputResult> export(
    ReportOutputRequest request,
    ReportExportFormat format,
  ) async {
    await Future<void>.delayed(delay);
    _validate(request);
    final extension = switch (format) {
      ReportExportFormat.pdf => 'pdf',
      ReportExportFormat.excel => 'xlsx',
    };
    final title = switch (format) {
      ReportExportFormat.pdf => 'نتيجة تصدير PDF',
      ReportExportFormat.excel => 'نتيجة تصدير Excel',
    };
    return ReportOutputResult(
      title: title,
      rowCount: request.rowValues.length,
      fileName: '${_safeFileName(request.reportTitle)}.$extension',
      content: _buildContent(
        request,
        separator: format == ReportExportFormat.excel ? '\t' : ' | ',
      ),
    );
  }

  void _validate(ReportOutputRequest request) {
    if (request.rowValues.isEmpty) {
      throw const ReportOutputException('لا توجد نتائج لتجهيزها');
    }
    if (request.rowValues.any(
      (row) => row.length != request.columnLabels.length,
    )) {
      throw const ReportOutputException(
        'تعذر تجهيز التقرير بسبب عدم تطابق الأعمدة',
      );
    }
  }

  String _buildContent(
    ReportOutputRequest request, {
    required String separator,
  }) {
    final buffer = StringBuffer()
      ..writeln(request.reportTitle)
      ..writeln(request.variantLabel)
      ..writeln()
      ..writeln(
        request.metrics.entries
            .map((metric) => '${metric.key}: ${metric.value}')
            .join(separator),
      )
      ..writeln()
      ..writeln(
        request.columnLabels.join(separator),
      );
    for (final row in request.rowValues) {
      buffer.writeln(row.join(separator));
    }
    return buffer.toString().trimRight();
  }

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
