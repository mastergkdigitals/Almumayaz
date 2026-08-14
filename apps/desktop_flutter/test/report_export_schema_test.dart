import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/features/reports/application/document_report_output_service.dart';
import 'package:erp/features/reports/application/report_output_request_factory.dart';
import 'package:erp/features/reports/application/report_output_service.dart';
import 'package:erp/features/reports/application/report_summary_calculator.dart';
import 'package:erp/features/reports/data/report_demo_catalog.dart';
import 'package:erp/features/reports/presentation/report_catalog.dart';
import 'package:erp/features/reports/presentation/report_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t = ReportSpreadsheetCellKind.text;
  const i = ReportSpreadsheetCellKind.integer;
  const n = ReportSpreadsheetCellKind.decimal;
  const d = ReportSpreadsheetCellKind.date;
  const m = ReportSpreadsheetCellKind.time;
  const p = ReportSpreadsheetCellKind.percentage;
  const expectedSchemas = <(String, String), _ExpectedSchema>{
    ('salesInvoices', 'main'): _ExpectedSchema(
      [i, i, d, t, t, t, t, n, n, n, i],
      [null, null, null, null, null, null, null, null, null, null, null],
      [i, n, n, n, i, n, n, n],
      [null, 0, 0, 0, null, 2, 2, 2],
    ),
    ('salesInvoices', 'returns'): _ExpectedSchema(
      [i, i, i, d, t, t, n, n, n, i, i, t],
      [null, null, null, null, null, null, null, null, null, null, null, null],
      [i, n, n, n, i, n, n, n],
      [null, 0, 0, 0, null, 2, 2, 2],
    ),
    ('purchaseInvoices', 'main'): _ExpectedSchema(
      [i, i, i, d, t, t, t, t, t, n, n, n, i],
      [
        null, null, null, null, null, null, null,
        null, null, null, null, null, null,
      ],
      [i, n, n, n, i, n, n, n],
      [null, 0, 0, 0, null, 2, 2, 2],
    ),
    ('profits', 'main'): _ExpectedSchema(
      [i, i, d, t, t, t, t, i, n, n, n, n, p, t, t, t],
      [
        null, null, null, null, null, null, null, null,
        null, null, null, null, 2, null, null, null,
      ],
      [n, n, n, p, n, n, n, p],
      [0, 0, 0, 2, 2, 2, 2, 2],
    ),
    ('inventory', 'currentStock'): _ExpectedSchema(
      [i, t, t, t, t, t, i],
      [null, null, null, null, null, null, null],
      [i, i, i, i],
      [null, null, null, null],
    ),
    ('inventory', 'transfers'): _ExpectedSchema(
      [i, i, d, t, t, t],
      [null, null, null, null, null, null],
      [i, i, i],
      [null, null, null],
    ),
    ('cashbox', 'main'): _ExpectedSchema(
      [i, i, d, m, t, t, t, n, n, n, t],
      [null, null, null, null, null, null, null, 0, 2, null, null],
      [n, n, n, n, n, n, n, n, i],
      [0, 0, 0, 0, 2, 2, 2, 2, null],
    ),
    ('cashbox', 'expenses'): _ExpectedSchema(
      [i, i, d, m, t, t, t, t, n, n, n, t],
      [null, null, null, null, null, null, null, null, null, null, null, null],
      [i, n, n, n, n, i],
      [null, 0, 0, 2, 2, null],
    ),
    ('partyBalances', 'main'): _ExpectedSchema(
      [i, i, t, t, t, t, t, t, n, t, n, t],
      [null, null, null, null, null, null, null, null, 0, null, 2, null],
      [i, i, n, n, n, n],
      [null, null, 0, 2, 0, 2],
    ),
    ('debtsInstallments', 'main'): _ExpectedSchema(
      [i, t, i, i, t, d, t, n, n, n, t, t],
      [null, null, null, null, null, null, null, null, null, null, null, null],
      [n, n, n, n, n, n, n, n, i, i],
      [0, 0, 0, 0, 2, 2, 2, 2, null, null],
    ),
  };
  const expectedSummaries = <(String, String), Map<String, String>>{
    ('salesInvoices', 'main'): {
      'عدد القوائم - دينار': '2',
      'الإجمالي - دينار': '487,000',
      'المقبوض - دينار': '310,000',
      'المتبقي - دينار': '177,000',
      'عدد القوائم - دولار': '1',
      'الإجمالي - دولار': '1,250.00',
      'المقبوض - دولار': '250.00',
      'المتبقي - دولار': '1,000.00',
    },
    ('salesInvoices', 'returns'): {
      'عدد المرتجعات - دينار': '0',
      'الإجمالي - دينار': '0',
      'المسترد - دينار': '0',
      'المضاف للرصيد - دينار': '0',
      'عدد المرتجعات - دولار': '0',
      'الإجمالي - دولار': '0.00',
      'المسترد - دولار': '0.00',
      'المضاف للرصيد - دولار': '0.00',
    },
    ('purchaseInvoices', 'main'): {
      'عدد القوائم - دينار': '2',
      'الإجمالي - دينار': '150,000',
      'المدفوع - دينار': '-90,000',
      'المتبقي - دينار': '240,000',
      'عدد القوائم - دولار': '1',
      'الإجمالي - دولار': '1,500.00',
      'المدفوع - دولار': '500.00',
      'المتبقي - دولار': '1,000.00',
    },
    ('profits', 'main'): {
      'المبيعات المحتسبة - دينار': '190,000',
      'التكلفة - دينار': '120,000',
      'الربح - دينار': '70,000',
      'هامش الربح - دينار': '36.84%',
      'المبيعات المحتسبة - دولار': '850.00',
      'التكلفة - دولار': '600.00',
      'الربح - دولار': '250.00',
      'هامش الربح - دولار': '29.41%',
    },
    ('inventory', 'currentStock'): {
      'المواد المختلفة': '4',
      'المخازن': '4',
      'الأرصدة الموجبة': '9',
      'مجموع الكميات': '344',
    },
    ('inventory', 'transfers'): {
      'عدد عمليات النقل': '2',
      'عدد سطور المواد': '3',
      'مجموع الكميات': '27',
    },
    ('cashbox', 'main'): {
      'القبض - دينار': '1,525,000',
      'الصرف - دينار': '210,000',
      'الصافي - دينار': '1,315,000',
      'الرصيد - دينار': '11,115,000',
      'القبض - دولار': '0.00',
      'الصرف - دولار': '400.00',
      'الصافي - دولار': '-400.00',
      'الرصيد - دولار': '4,100.00',
      'عدد الحركات': '6',
    },
    ('cashbox', 'expenses'): {
      'عدد المصاريف': '0',
      'المدفوع - دينار': '0',
      'غير المدفوع - دينار': '0',
      'المدفوع - دولار': '0.00',
      'غير المدفوع - دولار': '0.00',
      'عدد غير المدفوع': '0',
    },
    ('partyBalances', 'main'): {
      'عدد الأطراف': '8',
      'بدون رصيد': '0',
      'ذمم لنا - دينار': '2,775,000',
      'ذمم لنا - دولار': '1,375.00',
      'ذمم علينا - دينار': '5,875,000',
      'ذمم علينا - دولار': '1,625.00',
    },
    ('debtsInstallments', 'main'): {
      'المتبقي - دينار': '177,000',
      'المتأخر - دينار': '177,000',
      'المستحق - دينار': '0',
      'المدفوع - دينار': '0',
      'المتبقي - دولار': '1,000.00',
      'المتأخر - دولار': '0.00',
      'المستحق - دولار': '1,000.00',
      'المدفوع - دولار': '250.00',
      'عدد المتأخر': '1',
      'عدد المستحق': '2',
    },
  };

  test('catalog exposes the complete ten-variant report set', () {
    final actual = <(String, String)>{
      for (final report in reportDefinitions)
        for (final variant in report.variants) (report.id, variant.id),
    };

    expect(actual, expectedSummaries.keys.toSet());
    expect(actual, expectedSchemas.keys.toSet());
  });

  test('all ten variants declare exact spreadsheet kinds and precision', () {
    for (final entry in expectedSchemas.entries) {
      final (_, variant) = _definition(entry.key);
      expect(
        variant.columns.map((column) => column.spreadsheetCellKind),
        entry.value.columnKinds,
        reason: '${entry.key} column kinds',
      );
      expect(
        variant.columns.map((column) => column.spreadsheetDecimalPlaces),
        entry.value.columnPrecision,
        reason: '${entry.key} column precision',
      );
      expect(
        variant.metrics.map((metric) => metric.spreadsheetCellKind),
        entry.value.metricKinds,
        reason: '${entry.key} metric kinds',
      );
      expect(
        variant.metrics.map((metric) => metric.spreadsheetDecimalPlaces),
        entry.value.metricPrecision,
        reason: '${entry.key} metric precision',
      );
    }
  });

  test('all ten variants calculate exact summaries from visible rows', () {
    for (final entry in expectedSummaries.entries) {
      final (report, variant) = _definition(entry.key);
      final rows = reportDemoRowsFor(
        reportId: report.id,
        variantId: variant.id,
      );
      final values = ReportSummaryCalculator.calculate(
        reportId: report.id,
        variantId: variant.id,
        rows: rows,
        fallbackMetrics: variant.metrics,
      );

      expect(
        {for (final metric in values) metric.label: metric.value},
        entry.value,
        reason: '${report.id}/${variant.id}',
      );
    }
  });

  test('factory and document adapter preserve all ten report schemas',
      () async {
    for (final entry in expectedSchemas.entries) {
      final (report, variant) = _definition(entry.key);
      final rows = reportDemoRowsFor(
        reportId: report.id,
        variantId: variant.id,
      );
      final metrics = ReportSummaryCalculator.calculate(
        reportId: report.id,
        variantId: variant.id,
        rows: rows,
        fallbackMetrics: variant.metrics,
      );
      final request = ReportOutputRequestFactory.create(
        reportTitle: report.title,
        variantLabel: variant.label,
        columnLabels: variant.columns.map((column) => column.label),
        columnSpreadsheetCellKinds:
            variant.columns.map((column) => column.spreadsheetCellKind),
        columnSpreadsheetDecimalPlaces:
            variant.columns.map((column) => column.spreadsheetDecimalPlaces),
        rows: rows,
        metrics: metrics,
      );

      expect(
        request.columnSpreadsheetCellKinds,
        entry.value.columnKinds,
        reason: '${entry.key} request column kinds',
      );
      expect(
        request.columnSpreadsheetDecimalPlaces,
        entry.value.columnPrecision,
        reason: '${entry.key} request column precision',
      );
      expect(
        request.metricSpreadsheetCellKinds.values,
        entry.value.metricKinds,
        reason: '${entry.key} request metric kinds',
      );
      expect(
        request.metricSpreadsheetDecimalPlaces.values,
        entry.value.metricPrecision,
        reason: '${entry.key} request metric precision',
      );

      final output = _RecordingDocumentOutputService();
      final reports = DocumentBackedReportOutputService(
        printService: output,
        exportService: output,
      );
      await reports.export(request, ReportExportFormat.excel);
      final document = output.lastRequest!;

      expect(
        document.columns.map((column) => column.spreadsheetCellKind),
        entry.value.columnKinds.map(_documentKind),
        reason: '${entry.key} document column kinds',
      );
      expect(
        document.columns.map((column) => column.spreadsheetDecimalPlaces),
        entry.value.columnPrecision,
        reason: '${entry.key} document column precision',
      );
      expect(
        document.fields.map((field) => field.spreadsheetCellKind),
        entry.value.metricKinds.map(_documentKind),
        reason: '${entry.key} document metric kinds',
      );
      expect(
        document.fields.map((field) => field.spreadsheetDecimalPlaces),
        entry.value.metricPrecision,
        reason: '${entry.key} document metric precision',
      );
    }
  });
}

(ReportDefinition, ReportVariantDefinition) _definition(
  (String, String) key,
) {
  final report = reportDefinitions.singleWhere(
    (candidate) => candidate.id == key.$1,
  );
  final variant = report.variants.singleWhere(
    (candidate) => candidate.id == key.$2,
  );
  return (report, variant);
}

DocumentSpreadsheetCellKind _documentKind(ReportSpreadsheetCellKind kind) {
  return switch (kind) {
    ReportSpreadsheetCellKind.text => DocumentSpreadsheetCellKind.text,
    ReportSpreadsheetCellKind.integer => DocumentSpreadsheetCellKind.integer,
    ReportSpreadsheetCellKind.decimal => DocumentSpreadsheetCellKind.decimal,
    ReportSpreadsheetCellKind.date => DocumentSpreadsheetCellKind.date,
    ReportSpreadsheetCellKind.time => DocumentSpreadsheetCellKind.time,
    ReportSpreadsheetCellKind.percentage =>
      DocumentSpreadsheetCellKind.percentage,
  };
}

class _ExpectedSchema {
  const _ExpectedSchema(
    this.columnKinds,
    this.columnPrecision,
    this.metricKinds,
    this.metricPrecision,
  );

  final List<ReportSpreadsheetCellKind> columnKinds;
  final List<int?> columnPrecision;
  final List<ReportSpreadsheetCellKind> metricKinds;
  final List<int?> metricPrecision;
}

class _RecordingDocumentOutputService implements DocumentOutputService {
  DocumentOutputRequest? lastRequest;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) async {
    lastRequest = request;
    return _result(DocumentOutputAction.print);
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) async {
    lastRequest = request;
    return _result(
      format == DocumentExportFormat.pdf
          ? DocumentOutputAction.pdf
          : DocumentOutputAction.excel,
    );
  }

  DocumentOutputResult _result(DocumentOutputAction action) {
    return DocumentOutputResult(
      action: action,
      title: 'نتيجة',
      documentTitle: 'تقرير',
      content: '',
      rowCount: lastRequest!.rows.length,
    );
  }
}
