import '../application/report_rows_service.dart';
import '../domain/report_models.dart';
import 'report_demo_catalog.dart';

/// Temporary rows source used until the report API is connected.
class DemoReportRowsService
    implements ReportRowsService, ReportRowsSnapshotProvider {
  const DemoReportRowsService({
    this.delay = const Duration(milliseconds: 100),
  });

  final Duration delay;

  @override
  List<ReportRowDefinition> snapshot(ReportRowsRequest request) {
    return List<ReportRowDefinition>.unmodifiable(
      reportDemoRowsFor(
        reportId: request.reportId,
        variantId: request.variantId,
      ),
    );
  }

  @override
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request) async {
    await Future<void>.delayed(delay);
    return snapshot(request);
  }
}
