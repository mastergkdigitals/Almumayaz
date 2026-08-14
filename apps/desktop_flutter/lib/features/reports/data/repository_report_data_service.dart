import '../../../core/app_state/app_repositories.dart';
import '../../../core/design/app_formatters.dart';
import '../../../core/domain/business_values.dart';
import '../../cashbox/domain/cashbox_repository.dart';
import '../../cashbox/domain/cashbox_voucher.dart';
import '../../expenses/domain/expense.dart';
import '../../items/domain/item.dart';
import '../../installments/domain/installment_plan.dart';
import '../../parties/domain/party.dart';
import '../../parties/domain/party_repository.dart';
import '../../purchases/domain/purchase_invoice.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../sales_returns/domain/sales_return.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/settings_models.dart';
import '../../warehouses/domain/inventory_records.dart';
import '../../warehouses/domain/inventory_cost.dart';
import '../../warehouses/domain/warehouse.dart';
import '../application/report_data_snapshot_service.dart';
import '../application/report_rows_service.dart';
import '../domain/report_models.dart';

part 'repository_report_options.dart';
part 'repository_report_projection_loaders.dart';
part 'repository_report_row_mappers.dart';

/// Repository-backed reports projection used by the Flutter demo application.
///
/// It intentionally does not retain a snapshot. Each call observes the latest
/// shared repository state, including invoice effects and warehouse transfers.
class RepositoryReportDataService
    implements ReportDataSnapshotService, ReportRowsService {
  RepositoryReportDataService(
    this._repositories, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppRepositories _repositories;
  final DateTime Function() _clock;

  @override
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request) async {
    return (await loadSnapshot(request)).rows;
  }

  @override
  Future<ReportDataSnapshot> loadSnapshot(ReportRowsRequest request) {
    return switch ((request.reportId, request.variantId)) {
      ('salesInvoices', 'main') =>
        _RepositoryReportProjectionLoaders(this)._sales(),
      ('salesInvoices', 'returns') =>
        _RepositoryReportProjectionLoaders(this)._salesReturns(),
      ('purchaseInvoices', 'main') =>
        _RepositoryReportProjectionLoaders(this)._purchases(),
      ('profits', 'main') =>
        _RepositoryReportProjectionLoaders(this)._profits(),
      ('inventory', 'currentStock') =>
        _RepositoryReportProjectionLoaders(this)._currentStock(),
      ('inventory', 'transfers') =>
        _RepositoryReportProjectionLoaders(this)._transfers(),
      ('cashbox', 'main') =>
        _RepositoryReportProjectionLoaders(this)._cashbox(),
      ('cashbox', 'expenses') =>
        _RepositoryReportProjectionLoaders(this)._expenses(),
      ('partyBalances', 'main') =>
        _RepositoryReportProjectionLoaders(this)._partyBalances(),
      ('debtsInstallments', 'main') =>
        _RepositoryReportProjectionLoaders(this)._debts(),
      _ => Future.value(ReportDataSnapshot(rows: const [])),
    };
  }
}
