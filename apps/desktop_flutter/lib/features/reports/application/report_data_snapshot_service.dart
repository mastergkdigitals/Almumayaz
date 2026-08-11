import '../../../core/domain/business_values.dart';
import '../domain/report_models.dart';
import 'report_rows_service.dart';

/// A coherent report read-model built from one refresh of the repositories.
///
/// Filter option values are persistence identities, not display labels. This
/// keeps an active filter valid when a master-data label is edited.
class ReportDataSnapshot {
  ReportDataSnapshot({
    required Iterable<ReportRowDefinition> rows,
    Map<String, Iterable<ReportFilterOption>> filterOptions = const {},
    this.cashboxMetadata,
  })  : rows = List.unmodifiable(rows),
        filterOptions = Map<String, List<ReportFilterOption>>.unmodifiable({
          for (final entry in filterOptions.entries)
            entry.key:
                List<ReportFilterOption>.unmodifiable(entry.value),
        });

  final List<ReportRowDefinition> rows;
  final Map<String, List<ReportFilterOption>> filterOptions;
  final CashboxReportMetadata? cashboxMetadata;
}

/// Typed values that cannot be represented honestly by display rows alone.
class CashboxReportMetadata {
  CashboxReportMetadata({
    required this.openingIqd,
    required this.openingUsd,
  }) {
    if (openingIqd.currency != AppCurrency.iqd) {
      throw ArgumentError.value(openingIqd, 'openingIqd', 'Must use IQD');
    }
    if (openingUsd.currency != AppCurrency.usd) {
      throw ArgumentError.value(openingUsd, 'openingUsd', 'Must use USD');
    }
  }

  final Money openingIqd;
  final Money openingUsd;
}

abstract interface class ReportDataSnapshotService {
  Future<ReportDataSnapshot> loadSnapshot(ReportRowsRequest request);
}
