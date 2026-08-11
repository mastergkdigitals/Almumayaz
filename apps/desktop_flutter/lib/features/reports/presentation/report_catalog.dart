import 'catalog/cashbox_report_definition.dart';
import 'catalog/debt_report_definition.dart';
import 'catalog/inventory_report_definition.dart';
import 'catalog/party_balance_report_definition.dart';
import 'catalog/profit_report_definition.dart';
import 'catalog/purchase_report_definition.dart';
import 'catalog/sales_report_definition.dart';
import 'report_definition.dart';

final List<ReportDefinition> reportDefinitions =
    List<ReportDefinition>.unmodifiable([
  salesInvoicesReportDefinition,
  purchaseInvoicesReportDefinition,
  profitsReportDefinition,
  inventoryReportDefinition,
  cashboxReportDefinition,
  partyBalancesReportDefinition,
  debtsInstallmentsReportDefinition,
]);
