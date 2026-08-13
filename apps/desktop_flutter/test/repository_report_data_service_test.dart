import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/reports/application/report_data_snapshot_service.dart';
import 'package:erp/features/reports/application/report_rows_service.dart';
import 'package:erp/features/reports/data/repository_report_data_service.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/warehouses/domain/inventory_records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRepositories repositories;
  late RepositoryReportDataService service;

  setUp(() {
    repositories = AppRepositories.demo();
    service = RepositoryReportDataService(
      repositories,
      clock: () => DateTime(2026, 8, 13),
    );
  });

  test('all repository projections preserve their report column shapes',
      () async {
    final expectedColumns = <(String, String), int>{
      ('salesInvoices', 'main'): 11,
      ('purchaseInvoices', 'main'): 12,
      ('profits', 'main'): 16,
      ('inventory', 'currentStock'): 7,
      ('inventory', 'transfers'): 6,
      ('cashbox', 'main'): 11,
      ('partyBalances', 'main'): 12,
      ('debtsInstallments', 'main'): 12,
    };

    for (final entry in expectedColumns.entries) {
      final snapshot = await service.loadSnapshot(
        ReportRowsRequest(
          reportId: entry.key.$1,
          variantId: entry.key.$2,
        ),
      );
      expect(snapshot.rows, isNotEmpty, reason: '${entry.key} has rows');
      expect(
        snapshot.rows.every((row) => row.cells.length == entry.value),
        isTrue,
        reason: '${entry.key} keeps ${entry.value} cells',
      );
    }
  });

  test('dynamic options use stable IDs and cashbox opening is typed',
      () async {
    final sales = await _snapshot(service, 'salesInvoices');

    expect(
      sales.filterOptions['warehouse']!.map((option) => option.value),
      contains('warehouse-001'),
    );
    expect(
      sales.filterOptions['customer']!.map((option) => option.value),
      contains('party-001'),
    );
    expect(
      sales.filterOptions['warehouse']!.map((option) => option.value),
      isNot(contains('main')),
    );
    expect(
      sales.rows.firstWhere((row) => row.id == 'sales-invoice-101')
          .filterValues['customer'],
      'party-001',
    );

    final cashbox = await _snapshot(service, 'cashbox');
    expect(cashbox.cashboxMetadata, isNotNull);
    expect(
      cashbox.cashboxMetadata!.openingIqd,
      Money.fromMajor(9800000, AppCurrency.iqd),
    );
    expect(
      cashbox.cashboxMetadata!.openingUsd,
      Money.fromMajor(4500, AppCurrency.usd),
    );
    expect(
      cashbox.filterOptions['mainAccount']!
          .where((option) => option.value != 'all')
          .every((option) => option.value.startsWith('demo-')),
      isTrue,
    );
  });

  test('invoice mutations refresh sales, stock, balances, debts and profits',
      () async {
    final warehouseId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final customerId = EntityId('party-001');
    final stockBefore = _stockQuantity(
      await _snapshot(service, 'inventory', variantId: 'currentStock'),
      warehouseId: warehouseId,
      itemId: itemId,
    );
    final partyBefore = (await repositories.parties.getById(customerId))!;

    await repositories.sales.createInvoice(
      SalesInvoice(
        id: EntityId('phase4-report-sale'),
        documentNumber: 104,
        date: BusinessDate(2026, 8, 10),
        minuteOfDay: 10 * 60,
        customerId: customerId,
        defaultWarehouseId: warehouseId,
        currency: AppCurrency.iqd,
        exchangeRate: ExchangeRate.parse('1310'),
        settlementKind: SalesSettlementKind.credit,
        lines: [
          SalesInvoiceLine(
            id: EntityId('phase4-report-sale-line'),
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: WholeQuantity(2),
            unitPrice: Money.fromMajor(100, AppCurrency.iqd),
            discountPerUnit: Money.zero(AppCurrency.iqd),
          ),
        ],
        invoiceDiscount: Money.zero(AppCurrency.iqd),
        received: Money.zero(AppCurrency.iqd),
      ),
    );

    final sales = await _snapshot(service, 'salesInvoices');
    final created = sales.rows.firstWhere(
      (row) => row.id == 'phase4-report-sale',
    );
    expect(created.cells[1], '104');
    expect(created.cells[7], '200');
    expect(created.filterValues['customer'], customerId.value);

    final inventory = await _snapshot(
      service,
      'inventory',
      variantId: 'currentStock',
    );
    expect(
      _stockQuantity(
        inventory,
        warehouseId: warehouseId,
        itemId: itemId,
      ),
      stockBefore - 2,
    );

    final balances = await _snapshot(service, 'partyBalances');
    final partyRow = balances.rows.firstWhere(
      (row) => row.id == customerId.value,
    );
    expect(
      partyRow.cells[8].replaceAll(',', ''),
      '${partyBefore.iqdBalance.minorUnits + 200}',
    );

    final debts = await _snapshot(service, 'debtsInstallments');
    final debt = debts.rows.firstWhere(
      (row) => row.id == 'debt:phase4-report-sale',
    );
    expect(debt.cells[8], '0');
    expect(debt.cells[9], '200');
    expect(debt.cells[10], 'مستحق');

    final profits = await _snapshot(service, 'profits');
    final profit = profits.rows.firstWhere(
      (row) => row.id == 'phase4-report-sale:phase4-report-sale-line',
    );
    expect(profit.cells[9], '200');
    expect(profit.cells[10], '400,000');
    expect(profit.cells[11], '-399,800');
    expect(profit.cells[13], 'متوفرة');
    expect(profit.cells[14], 'متوسط متحرك');
  });

  test('purchase mutations refresh purchase rows and current stock', () async {
    final warehouseId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final stockBefore = _stockQuantity(
      await _snapshot(service, 'inventory', variantId: 'currentStock'),
      warehouseId: warehouseId,
      itemId: itemId,
    );

    await repositories.purchases.createInvoice(
      PurchaseInvoice(
        id: EntityId('phase4-report-purchase'),
        documentNumber: 104,
        date: BusinessDate(2026, 8, 11),
        minuteOfDay: 11 * 60,
        supplierId: EntityId('party-011'),
        defaultWarehouseId: warehouseId,
        currency: AppCurrency.iqd,
        exchangeRate: ExchangeRate.parse('1310'),
        purchaseKind: PurchaseTransactionKind.local,
        settlementKind: PurchaseSettlementKind.credit,
        lines: [
          PurchaseInvoiceLine(
            id: EntityId('phase4-report-purchase-line'),
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: WholeQuantity(1),
            containerQuantity: WholeQuantity(0),
            purchasePrice: Money.fromMajor(50, AppCurrency.iqd),
            lineDiscount: Money.zero(AppCurrency.iqd),
            salePrice: Money.fromMajor(60, AppCurrency.iqd),
          ),
        ],
        expenses: Money.zero(AppCurrency.iqd),
        invoiceDiscount: Money.zero(AppCurrency.iqd),
        paid: Money.fromMajor(20, AppCurrency.iqd),
      ),
    );

    final purchases = await _snapshot(service, 'purchaseInvoices');
    final created = purchases.rows.firstWhere(
      (row) => row.id == 'phase4-report-purchase',
    );
    expect(created.cells[8], '50');
    expect(created.cells[9], '20');
    expect(created.cells[10], '30');
    expect(created.filterValues['supplier'], 'party-011');

    final stock = await _snapshot(
      service,
      'inventory',
      variantId: 'currentStock',
    );
    expect(
      _stockQuantity(
        stock,
        warehouseId: warehouseId,
        itemId: itemId,
      ),
      stockBefore + 1,
    );
  });

  test('warehouse edits and transfers refresh options and history', () async {
    final destination = (await repositories.warehouses.getById(
      EntityId('warehouse-002'),
    ))!;
    await repositories.warehouses.save(
      destination.copyWith(name: 'مخزن الكرادة المحدث'),
    );
    final transfer = await repositories.warehouses.transfer(
      InventoryTransferDraft(
        fromWarehouseId: EntityId('warehouse-001'),
        toWarehouseId: destination.entityId,
        createdAt: AuditTimestamp(DateTime(2026, 8, 10, 14, 5)),
        lines: [
          InventoryTransferLine(
            itemId: EntityId('item-001'),
            quantity: WholeQuantity(1),
          ),
        ],
      ),
    );

    final snapshot = await _snapshot(
      service,
      'inventory',
      variantId: 'transfers',
    );
    final destinationOption = snapshot
        .filterOptions['destinationWarehouse']!
        .firstWhere((option) => option.value == destination.id);
    expect(
      destinationOption.label,
      'مخزن الكرادة المحدث',
    );
    final row = snapshot.rows.firstWhere(
      (candidate) => candidate.id == transfer.id.value,
    );
    expect(row.cells[4], 'مخزن الكرادة المحدث');
    expect(row.filterValues['destinationWarehouse'], destination.id);
    expect(row.filterValues['product'], 'item-001');
  });
}

Future<ReportDataSnapshot> _snapshot(
  RepositoryReportDataService service,
  String reportId, {
  String variantId = 'main',
}) {
  return service.loadSnapshot(
    ReportRowsRequest(reportId: reportId, variantId: variantId),
  );
}

int _stockQuantity(
  ReportDataSnapshot snapshot, {
  required EntityId warehouseId,
  required EntityId itemId,
}) {
  final row = snapshot.rows.firstWhere(
    (candidate) =>
        candidate.filterValues['warehouse'] == warehouseId.value &&
        candidate.filterValues['product'] == itemId.value,
  );
  return int.parse(row.cells[6].replaceAll(',', ''));
}
