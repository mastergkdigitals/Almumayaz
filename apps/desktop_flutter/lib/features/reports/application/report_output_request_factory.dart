import '../domain/report_models.dart';
import 'report_output_service.dart';

/// Builds a report output request from the already filtered visible snapshot.
abstract final class ReportOutputRequestFactory {
  static ReportOutputRequest create({
    required String reportTitle,
    required String variantLabel,
    required Iterable<String> columnLabels,
    required Iterable<ReportRowDefinition> rows,
    required Iterable<ReportMetricValue> metrics,
    Iterable<ReportSpreadsheetCellKind> columnSpreadsheetCellKinds = const [],
    Iterable<int?> columnSpreadsheetDecimalPlaces = const [],
  }) {
    final outputColumnLabels = columnLabels.toList(growable: false);
    final outputMetrics = metrics.toList(growable: false);
    return ReportOutputRequest(
      reportTitle: reportTitle,
      variantLabel: variantLabel,
      columnLabels: outputColumnLabels,
      rowValues: [for (final row in rows) row.cells],
      metrics: {
        for (final metric in outputMetrics) metric.label: metric.value,
      },
      columnSpreadsheetCellKinds: [
        for (final kind in columnSpreadsheetCellKinds) kind,
      ],
      columnSpreadsheetDecimalPlaces: [
        for (final decimalPlaces in columnSpreadsheetDecimalPlaces)
          decimalPlaces,
      ],
      metricSpreadsheetCellKinds: {
        for (final metric in outputMetrics)
          metric.label: metric.spreadsheetCellKind,
      },
      metricSpreadsheetDecimalPlaces: {
        for (final metric in outputMetrics)
          metric.label: metric.spreadsheetDecimalPlaces,
      },
    );
  }
}
