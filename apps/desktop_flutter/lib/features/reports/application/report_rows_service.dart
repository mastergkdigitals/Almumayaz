import '../domain/report_models.dart';

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
