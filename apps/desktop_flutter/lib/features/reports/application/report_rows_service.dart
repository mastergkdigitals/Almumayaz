import '../data/report_demo_catalog.dart';
import '../presentation/report_definition.dart';

class ReportRowsRequest {
  const ReportRowsRequest({
    required this.reportId,
    required this.variantId,
  });

  final String reportId;
  final String variantId;
}

abstract interface class ReportRowsService {
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request);
}

/// Optional synchronous snapshot used while the first asynchronous refresh is
/// pending. Real API-backed services can omit it and start with an empty state.
abstract interface class ReportRowsSnapshotProvider {
  List<ReportRowDefinition> snapshot(ReportRowsRequest request);
}

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
