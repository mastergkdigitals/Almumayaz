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
  }) {
    return ReportOutputRequest(
      reportTitle: reportTitle,
      variantLabel: variantLabel,
      columnLabels: [for (final label in columnLabels) label],
      rowValues: [for (final row in rows) row.cells],
      metrics: {
        for (final metric in metrics) metric.label: metric.value,
      },
    );
  }
}
