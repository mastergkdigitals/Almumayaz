import '../domain/report_models.dart';
import 'demo/cashbox_report_demo_data.dart';
import 'demo/debt_report_demo_data.dart';
import 'demo/inventory_report_demo_data.dart';
import 'demo/party_balance_report_demo_data.dart';
import 'demo/profit_report_demo_data.dart';
import 'demo/purchase_report_demo_data.dart';
import 'demo/sales_report_demo_data.dart';

final Map<String, Map<String, List<ReportRowDefinition>>> _demoRowsByReport =
    {
  'salesInvoices': {
    'main': salesInvoiceDemoRows,
    'returns': const [],
  },
  'purchaseInvoices': {'main': purchaseInvoiceDemoRows},
  'profits': {'main': profitDemoRows},
  'inventory': {
    'currentStock': currentStockDemoRows,
    'transfers': transferDemoRows,
  },
  'cashbox': {
    'main': cashboxDemoRows,
    'expenses': const [],
  },
  'partyBalances': {'main': partyBalanceDemoRows},
  'debtsInstallments': {'main': debtDemoRows},
};

List<ReportRowDefinition> reportDemoRowsFor({
  required String reportId,
  required String variantId,
}) {
  final rows = _demoRowsByReport[reportId]?[variantId];
  if (rows == null) return const [];
  return rows;
}
