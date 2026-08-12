import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../domain/report_models.dart';
import 'report_output_service.dart';

class DocumentBackedReportOutputService implements ReportOutputService {
  const DocumentBackedReportOutputService({
    required this.printService,
    required this.exportService,
  });

  final DocumentPrintService printService;
  final DocumentExportService exportService;

  @override
  Future<ReportOutputResult> createPreview(
    ReportOutputRequest request,
  ) async {
    _validate(request);
    try {
      final result = await printService.createPreview(_documentRequest(request));
      return _mapResult(result);
    } on ServiceFailure catch (failure) {
      throw ReportOutputException(failure.message);
    }
  }

  @override
  Future<ReportOutputResult> export(
    ReportOutputRequest request,
    ReportExportFormat format,
  ) async {
    _validate(request);
    try {
      final result = await exportService.export(
        _documentRequest(request),
        format == ReportExportFormat.pdf
            ? DocumentExportFormat.pdf
            : DocumentExportFormat.excel,
      );
      return _mapResult(result);
    } on ServiceFailure catch (failure) {
      throw ReportOutputException(failure.message);
    }
  }

  DocumentOutputRequest _documentRequest(ReportOutputRequest request) {
    return DocumentOutputRequest(
      title: request.reportTitle,
      subtitle: request.variantLabel,
      fileNameBase: request.reportTitle,
      fields: [
        for (final metric in request.metrics.entries)
          DocumentField(
            label: metric.key,
            value: metric.value,
            spreadsheetCellKind: _documentCellKind(
              request.metricSpreadsheetCellKinds[metric.key] ??
                  ReportSpreadsheetCellKind.text,
            ),
            spreadsheetDecimalPlaces:
                request.metricSpreadsheetDecimalPlaces[metric.key],
          ),
      ],
      columns: [
        for (var index = 0; index < request.columnLabels.length; index++)
          DocumentColumn(
            label: request.columnLabels[index],
            spreadsheetCellKind: _documentCellKind(
              request.columnSpreadsheetCellKinds.isEmpty
                  ? ReportSpreadsheetCellKind.text
                  : request.columnSpreadsheetCellKinds[index],
            ),
            spreadsheetDecimalPlaces:
                request.columnSpreadsheetDecimalPlaces.isEmpty
                    ? null
                    : request.columnSpreadsheetDecimalPlaces[index],
          ),
      ],
      rows: request.rowValues,
    );
  }

  ReportOutputResult _mapResult(DocumentOutputResult result) {
    return ReportOutputResult(
      title: result.title,
      content: result.content,
      rowCount: result.rowCount,
      fileName: result.fileName,
      filePath: result.filePath,
      isDemo: result.isDemo,
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
    if (request.columnSpreadsheetCellKinds.isNotEmpty &&
        request.columnSpreadsheetCellKinds.length !=
            request.columnLabels.length) {
      throw const ReportOutputException(
        'تعذر تجهيز التقرير بسبب عدم تطابق أنواع الأعمدة',
      );
    }
    if (request.columnSpreadsheetDecimalPlaces.isNotEmpty &&
        request.columnSpreadsheetDecimalPlaces.length !=
            request.columnLabels.length) {
      throw const ReportOutputException(
        'تعذر تجهيز التقرير بسبب عدم تطابق تنسيق الأعمدة',
      );
    }
  }
}

DocumentSpreadsheetCellKind _documentCellKind(
  ReportSpreadsheetCellKind kind,
) => switch (kind) {
  ReportSpreadsheetCellKind.text => DocumentSpreadsheetCellKind.text,
  ReportSpreadsheetCellKind.integer => DocumentSpreadsheetCellKind.integer,
  ReportSpreadsheetCellKind.decimal => DocumentSpreadsheetCellKind.decimal,
  ReportSpreadsheetCellKind.date => DocumentSpreadsheetCellKind.date,
  ReportSpreadsheetCellKind.time => DocumentSpreadsheetCellKind.time,
  ReportSpreadsheetCellKind.percentage =>
    DocumentSpreadsheetCellKind.percentage,
};
