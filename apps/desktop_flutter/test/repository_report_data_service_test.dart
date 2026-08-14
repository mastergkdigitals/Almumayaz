import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/items/domain/item.dart';
import 'package:erp/features/items/domain/item_repository.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/reports/application/report_data_snapshot_service.dart';
import 'package:erp/features/reports/application/report_rows_service.dart';
import 'package:erp/features/reports/data/repository_report_data_service.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales_returns/domain/sales_return.dart';
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
      ('purchaseInvoices', 'main'): 13,
      ('profits', 'main'): 16,
      ('inventory', 'currentStock'): 7,
      ('inventory', 'transfers'): 6,
      ('cashbox', 'main'): 11,
      ('cashbox', 'expenses'): 12,
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

  test('projects Sales returns, restored profit, Expenses and source links',
      () async {
    final source = (await repositories.sales.getById(
      EntityId('sales-invoice-103'),
    ))!;
    final saved = await repositories.salesReturns.createReturn(
      SalesReturnSaveRequest(
        originalSalesInvoiceId: source.id,
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 12 * 60,
        lines: [
          SalesReturnLineRequest(
            sourceSalesLineId: source.lines.first.id,
            quantity: WholeQuantity(1),
          ),
        ],
        refundedAtReturn: Money.fromMajor(10000, AppCurrency.iqd),
      ),
    );

    final returns = await _snapshot(
      service,
      'salesInvoices',
      variantId: 'returns',
    );
    final returnRow = returns.rows.singleWhere(
      (row) => row.id == saved.id.value,
    );
    expect(returnRow.cells, hasLength(12));
    expect(returnRow.cells[2], '${source.documentNumber}');
    expect(
      returnRow.cells[6].replaceAll(',', ''),
      saved.total.toPlainString(),
    );
    expect(returnRow.filterValues['customer'], source.customerId.value);

    final profits = await _snapshot(service, 'profits');
    final returnProfit = profits.rows.singleWhere(
      (row) => row.id == '${saved.id.value}:${saved.lines.single.id.value}',
    );
    expect(profits.rows.first.id, returnProfit.id);
    expect(returnProfit.cells[7], '-1');
    expect(returnProfit.cells[9], startsWith('-'));
    expect(returnProfit.cells[10], startsWith('-'));

    final expenses = await _snapshot(
      service,
      'cashbox',
      variantId: 'expenses',
    );
    expect(expenses.rows, hasLength(2));
    expect(
      expenses.rows.map((row) => row.filterValues['status']),
      containsAll(['paid', 'unpaid']),
    );

    final purchases = await _snapshot(service, 'purchaseInvoices');
    final purchaseReturn = purchases.rows.singleWhere(
      (row) => row.id == 'purchase-invoice-103',
    );
    expect(purchaseReturn.cells[2], '101');
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
    expect(created.cells[9], '50');
    expect(created.cells[10], '20');
    expect(created.cells[11], '30');
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

  test('current stock keeps orphan balances with stable deleted labels',
      () async {
    final base = AppRepositories.demo();
    final removedItemId = EntityId('item-001');
    final balance = (await base.warehouses.getInventory(
      EntityId('warehouse-001'),
    ))
        .firstWhere((candidate) => candidate.itemId == removedItemId);
    final staleService = RepositoryReportDataService(
      _replaceRepositories(
        base,
        items: _ItemsMissingIds(base.items, {removedItemId}),
      ),
      clock: () => DateTime(2026, 8, 13),
    );

    final snapshot = await _snapshot(
      staleService,
      'inventory',
      variantId: 'currentStock',
    );
    final row = snapshot.rows.firstWhere(
      (candidate) => candidate.filterValues['product'] == removedItemId.value,
    );

    expect(row.id, balance.id.value);
    expect(row.filterValues['product'], removedItemId.value);
    expect(row.cells.sublist(1, 5), everyElement('محذوف'));
  });

  test('party balances distinguish absent references from stale references',
      () async {
    final base = AppRepositories.demo();
    final withoutReference = _party(
      id: 'phase8-party-no-reference',
      number: 901,
      name: 'طرف بلا جهة',
    );
    final legacySnapshot = _party(
      id: 'phase8-party-legacy',
      number: 902,
      name: 'طرف ببيانات قديمة',
      workplace: '  جهة قديمة  ',
      branch: '  فرع قديم  ',
    );
    final staleReference = _party(
      id: 'phase8-party-stale-reference',
      number: 903,
      name: 'طرف بمرجع محذوف',
    );
    final parties = _PartiesProjection(
      base.parties,
      values: [withoutReference, legacySnapshot, staleReference],
      references: {
        staleReference.entityId: PartyMasterDataReferences(
          workplaceId: EntityId('phase8-missing-workplace'),
          branchId: EntityId('phase8-missing-branch'),
        ),
      },
    );
    final staleService = RepositoryReportDataService(
      _replaceRepositories(base, parties: parties),
      clock: () => DateTime(2026, 8, 13),
    );

    final snapshot = await _snapshot(staleService, 'partyBalances');
    final noReferenceRow = snapshot.rows.firstWhere(
      (row) => row.id == withoutReference.id,
    );
    final legacyRow = snapshot.rows.firstWhere(
      (row) => row.id == legacySnapshot.id,
    );
    final staleRow = snapshot.rows.firstWhere(
      (row) => row.id == staleReference.id,
    );

    expect(noReferenceRow.cells[4], '—');
    expect(noReferenceRow.cells[5], '—');
    expect(legacyRow.cells[4], 'جهة قديمة');
    expect(legacyRow.cells[5], 'فرع قديم');
    expect(staleRow.cells[4], 'محذوف');
    expect(staleRow.cells[5], 'محذوف');
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

AppRepositories _replaceRepositories(
  AppRepositories base, {
  PartyRepository? parties,
  ItemRepository? items,
}) {
  return AppRepositories(
    parties: parties ?? base.parties,
    items: items ?? base.items,
    warehouses: base.warehouses,
    inventoryCosts: base.inventoryCosts,
    cashbox: base.cashbox,
    sales: base.sales,
    salesReturns: base.salesReturns,
    purchases: base.purchases,
    installments: base.installments,
    expenses: base.expenses,
    businessSettings: base.businessSettings,
    deviceSettings: base.deviceSettings,
    operationalMasterData: base.operationalMasterData,
  );
}

Party _party({
  required String id,
  required int number,
  required String name,
  String workplace = '',
  String branch = '',
}) {
  return Party(
    id: id,
    number: number,
    createdAt: DateTime(2026, 8, 13),
    name: name,
    type: PartyType.customer,
    workplace: workplace,
    branch: branch,
    phone: '',
    alternatePhone: '',
    city: '',
    address: '',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 0,
  );
}

class _ItemsMissingIds implements ItemRepository {
  const _ItemsMissingIds(this._delegate, this._removedIds);

  final ItemRepository _delegate;
  final Set<EntityId> _removedIds;

  @override
  Future<List<Item>> getAll() async => [
        for (final item in await _delegate.getAll())
          if (!_removedIds.contains(item.entityId)) item,
      ];

  @override
  Future<Item?> getById(EntityId id) =>
      _removedIds.contains(id)
          ? Future<Item?>.value()
          : _delegate.getById(id);

  @override
  Future<Item> save(Item value) => _delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) => _delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => _delegate.delete(id);

  @override
  Future<List<Item>> search(String query) async => [
        for (final item in await _delegate.search(query))
          if (!_removedIds.contains(item.entityId)) item,
      ];

  @override
  Future<List<ItemGroup>> getGroups() => _delegate.getGroups();

  @override
  Future<List<ItemType>> getTypes({EntityId? groupId}) =>
      _delegate.getTypes(groupId: groupId);

  @override
  Future<Item> quickCreate(ItemQuickCreateRequest request) =>
      _delegate.quickCreate(request);
}

class _PartiesProjection implements PartyRepository {
  const _PartiesProjection(
    this._delegate, {
    required this.values,
    required this.references,
  });

  final PartyRepository _delegate;
  final List<Party> values;
  final Map<EntityId, PartyMasterDataReferences> references;

  @override
  Future<List<Party>> getAll() async => List<Party>.unmodifiable(values);

  @override
  Future<Party?> getById(EntityId id) async {
    for (final party in values) {
      if (party.entityId == id) return party;
    }
    return null;
  }

  @override
  Future<Party> save(Party value) => _delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) => _delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => _delegate.delete(id);

  @override
  Future<List<Party>> search(String query) async => [
        for (final party in values)
          if (party.searchText.contains(query.toLowerCase())) party,
      ];

  @override
  Future<Party?> findByName(String name) async {
    for (final party in values) {
      if (party.name == name) return party;
    }
    return null;
  }

  @override
  Future<Party> saveWithMasterData(
    Party party,
    PartyMasterDataReferences references,
  ) =>
      _delegate.saveWithMasterData(party, references);

  @override
  Future<PartyMasterDataReferences?> getMasterDataReferences(
    EntityId partyId,
  ) async =>
      references[partyId];

  @override
  Future<bool> referencesMasterData(EntityId masterDataId) async =>
      references.values.any(
        (value) =>
            value.workplaceId == masterDataId ||
            value.branchId == masterDataId,
      );

  @override
  Future<int> nextPartyNumber() => _delegate.nextPartyNumber();

  @override
  Future<Party> quickCreate(PartyQuickCreateRequest request) =>
      _delegate.quickCreate(request);
}
