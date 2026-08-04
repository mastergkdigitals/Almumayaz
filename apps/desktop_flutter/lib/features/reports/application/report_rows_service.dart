import '../presentation/report_definition.dart';

class ReportRowsRequest {
  const ReportRowsRequest({
    required this.reportId,
    required this.variantId,
    required this.demoRows,
  });

  final String reportId;
  final String variantId;
  final List<ReportRowDefinition> demoRows;
}

abstract interface class ReportRowsService {
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request);
}

/// Temporary rows source used until the report API is connected.
class DemoReportRowsService implements ReportRowsService {
  const DemoReportRowsService({
    this.delay = const Duration(milliseconds: 100),
  });

  final Duration delay;

  @override
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request) async {
    await Future<void>.delayed(delay);
    return List<ReportRowDefinition>.unmodifiable(request.demoRows);
  }
}
