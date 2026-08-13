import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/domain/invoice_value_allocator.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/warehouses/data/demo_inventory_cost_repository.dart';
import 'package:erp/features/warehouses/data/demo_warehouse_repository.dart';
import 'package:erp/features/warehouses/domain/inventory_cost.dart';
import 'package:erp/features/warehouses/domain/inventory_records.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integer allocation is exact and deterministic in minor units', () {
    expect(
      allocateIntegerByWeights(1003, [1, 1, 1, 1]),
      [251, 251, 251, 250],
    );
    expect(allocateIntegerByWeights(3, [-1, 1]), [0, 3]);
    expect(allocateIntegerByWeights(9, [0, 0]), [0, 0]);
    expect(
      allocateInvoiceTotalMinorUnits(
        totalMinorUnits: 5,
        netLineMinorUnits: [0, 0, 0],
        grossLineMinorUnits: [0, 0, 0],
        quantities: [1, 2, 1],
        includedLines: [true, false, true],
      ),
      [3, 0, 2],
    );
    expect(divideAndRoundHalfAwayFromZero(5, 2), 3);
    expect(divideAndRoundHalfAwayFromZero(-5, 2), -3);
  });

  test('seeded cost quantities reconcile with shared warehouse inventory',
      () async {
    final repositories = AppRepositories.demo();
    final costQuantities = <(EntityId, EntityId), int>{
      for (final balance in await repositories.inventoryCosts.getBalances())
        (balance.warehouseId, balance.itemId): balance.quantity.value,
    };
    final inventoryQuantities = <(EntityId, EntityId), int>{};
    for (final warehouse in await repositories.warehouses.getAll()) {
      for (final balance in
          await repositories.warehouses.getInventory(warehouse.entityId)) {
        inventoryQuantities[(balance.warehouseId, balance.itemId)] =
            balance.quantity.value;
      }
    }

    expect(costQuantities, inventoryQuantities);
  });

  test('USD purchase allocation includes adjustments without losing IQD',
      () async {
    final repository = DemoInventoryCostRepository(openingBalances: const []);
    final purchase = _purchase(
      id: 'purchase-usd-allocation',
      documentNumber: 1,
      date: BusinessDate(2026, 8, 1),
      minuteOfDay: 9 * 60,
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _purchaseLine(
          id: 'purchase-usd-line-a',
          itemId: 'item-a',
          warehouseId: 'warehouse-a',
          quantity: 2,
          unitPrice: Money.fromMinorUnits(100, AppCurrency.usd),
        ),
        _purchaseLine(
          id: 'purchase-usd-line-b',
          itemId: 'item-b',
          warehouseId: 'warehouse-a',
          quantity: 1,
          unitPrice: Money.fromMinorUnits(100, AppCurrency.usd),
        ),
      ],
      expenses: Money.fromMinorUnits(2, AppCurrency.usd),
      invoiceDiscount: Money.fromMinorUnits(1, AppCurrency.usd),
    );

    final staged = repository.stagePurchase(
      repository.createSnapshot(),
      previous: null,
      candidate: purchase,
    );

    expect(await repository.getBalances(), isEmpty);
    final first = _snapshotBalance(staged, 'warehouse-a', 'item-a');
    final second = _snapshotBalance(staged, 'warehouse-a', 'item-b');
    expect(first.quantity, const StockQuantity(2));
    expect(first.totalCostIqd, Money.fromMajor(2629, AppCurrency.iqd));
    expect(second.quantity, const StockQuantity(1));
    expect(second.totalCostIqd, Money.fromMajor(1314, AppCurrency.iqd));
    expect(
      first.totalCostIqd! + second.totalCostIqd!,
      Money.fromMajor(3943, AppCurrency.iqd),
    );

    repository.commitSnapshot(staged);
    expect(
      (await repository.getBalance(
        warehouseId: EntityId('warehouse-a'),
        itemId: EntityId('item-a'),
      ))
          ?.totalCostIqd,
      Money.fromMajor(2629, AppCurrency.iqd),
    );
  });

  test('sale snapshots moving-average COGS and allocated net revenue',
      () async {
    final purchase = _purchase(
      id: 'purchase-moving-average',
      documentNumber: 2,
      date: BusinessDate(2026, 8, 1),
      minuteOfDay: 10 * 60,
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _purchaseLine(
          id: 'purchase-moving-line',
          itemId: 'item-moving',
          warehouseId: 'warehouse-moving',
          quantity: 2,
          unitPrice: Money.fromMinorUnits(100, AppCurrency.usd),
        ),
      ],
    );
    final sale = _sale(
      id: 'sale-moving-average',
      documentNumber: 3,
      date: BusinessDate(2026, 8, 2),
      minuteOfDay: 10 * 60,
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _salesLine(
          id: 'sale-moving-line',
          itemId: 'item-moving',
          warehouseId: 'warehouse-moving',
          quantity: 1,
          unitPrice: Money.fromMinorUnits(200, AppCurrency.usd),
        ),
      ],
      invoiceDiscount: Money.fromMinorUnits(1, AppCurrency.usd),
    );
    final repository = DemoInventoryCostRepository(
      openingBalances: [
        _openingCost(
          warehouseId: 'warehouse-moving',
          itemId: 'item-moving',
          quantity: 2,
          totalCostIqd: 2000,
        ),
      ],
      purchases: [purchase],
      sales: [sale],
    );

    final record = (await repository.getSalesLineCosts(
      salesInvoiceId: sale.id,
    ))
        .single;
    expect(record.allocatedRevenue, Money.fromMinorUnits(199, AppCurrency.usd));
    expect(record.totalCostIqd, Money.fromMajor(1155, AppCurrency.iqd));
    expect(record.totalCost, Money.fromMinorUnits(88, AppCurrency.usd));
    expect(record.profit, Money.fromMinorUnits(111, AppCurrency.usd));
    expect(record.availability, InventoryCostAvailability.available);
    expect(record.method, InventoryCostMethod.movingAverage);
    final balance = (await repository.getBalances()).single;
    expect(balance.quantity, const StockQuantity(3));
    expect(balance.totalCostIqd, Money.fromMajor(3465, AppCurrency.iqd));
  });

  test('backdated purchase and sale changes restate every downstream cost',
      () async {
    final opening = _openingCost(
      warehouseId: 'warehouse-replay',
      itemId: 'item-replay',
      quantity: 10,
      totalCostIqd: 1000,
    );
    final purchase = _purchase(
      id: 'purchase-replay',
      documentNumber: 4,
      date: BusinessDate(2026, 8, 2),
      minuteOfDay: 9 * 60,
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _purchaseLine(
          id: 'purchase-replay-line',
          itemId: 'item-replay',
          warehouseId: 'warehouse-replay',
          quantity: 10,
          unitPrice: Money.fromMajor(300, AppCurrency.iqd),
        ),
      ],
    );
    final sale = _sale(
      id: 'sale-replay',
      documentNumber: 5,
      date: BusinessDate(2026, 8, 3),
      minuteOfDay: 9 * 60,
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _salesLine(
          id: 'sale-replay-line',
          itemId: 'item-replay',
          warehouseId: 'warehouse-replay',
          quantity: 10,
          unitPrice: Money.fromMajor(500, AppCurrency.iqd),
        ),
      ],
    );
    final repository = DemoInventoryCostRepository(
      openingBalances: [opening],
      purchases: [purchase],
      sales: [sale],
    );
    expect(
      (await repository.getSalesLineCost(sale.lines.single.id))?.totalCostIqd,
      Money.fromMajor(2000, AppCurrency.iqd),
    );
    expect(
      (await repository.getBalances()).single.totalCostIqd,
      Money.fromMajor(2000, AppCurrency.iqd),
    );

    final laterPurchase = _purchase(
      id: purchase.id.value,
      documentNumber: purchase.documentNumber,
      date: BusinessDate(2026, 8, 4),
      minuteOfDay: purchase.minuteOfDay,
      currency: purchase.currency,
      exchangeRate: purchase.exchangeRate,
      lines: purchase.lines,
    );
    final restated = repository.stagePurchase(
      repository.createSnapshot(),
      previous: purchase,
      candidate: laterPurchase,
    );
    expect(
      (await repository.getSalesLineCost(sale.lines.single.id))?.totalCostIqd,
      Money.fromMajor(2000, AppCurrency.iqd),
    );
    expect(
      restated.salesLineCosts.single.totalCostIqd,
      Money.fromMajor(1000, AppCurrency.iqd),
    );
    expect(
      restated.balances.single.totalCostIqd,
      Money.fromMajor(3000, AppCurrency.iqd),
    );
    repository.commitSnapshot(restated);

    final withoutPurchase = repository.stagePurchase(
      repository.createSnapshot(),
      previous: laterPurchase,
      candidate: null,
    );
    expect((await repository.getBalances()).single.quantity.value, 10);
    expect(withoutPurchase.balances, isEmpty);
    expect(
      withoutPurchase.salesLineCosts.single.totalCostIqd,
      Money.fromMajor(1000, AppCurrency.iqd),
    );
    repository.commitSnapshot(withoutPurchase);

    final shorterSale = _sale(
      id: sale.id.value,
      documentNumber: sale.documentNumber,
      date: sale.date,
      minuteOfDay: sale.minuteOfDay,
      currency: sale.currency,
      exchangeRate: sale.exchangeRate,
      lines: [
        _salesLine(
          id: sale.lines.single.id.value,
          itemId: 'item-replay',
          warehouseId: 'warehouse-replay',
          quantity: 5,
          unitPrice: Money.fromMajor(500, AppCurrency.iqd),
        ),
      ],
    );
    final resized = repository.stageSale(
      repository.createSnapshot(),
      previous: sale,
      candidate: shorterSale,
    );
    expect(await repository.getBalances(), isEmpty);
    expect(
      resized.salesLineCosts.single.totalCostIqd,
      Money.fromMajor(500, AppCurrency.iqd),
    );
    expect(
      resized.balances.single.totalCostIqd,
      Money.fromMajor(500, AppCurrency.iqd),
    );
    repository.commitSnapshot(resized);

    final withoutSale = repository.stageSale(
      repository.createSnapshot(),
      previous: shorterSale,
      candidate: null,
    );
    expect(withoutSale.salesLineCosts, isEmpty);
    expect(withoutSale.balances.single.quantity.value, 10);
    expect(
      withoutSale.balances.single.totalCostIqd,
      Money.fromMajor(1000, AppCurrency.iqd),
    );
    repository.commitSnapshot(withoutSale);
    expect(await repository.getSalesLineCosts(), isEmpty);
    expect((await repository.getBalances()).single.quantity.value, 10);
  });

  test('purchase returns issue current moving-average cost', () async {
    final purchaseReturn = _purchase(
      id: 'purchase-return',
      documentNumber: 6,
      date: BusinessDate(2026, 8, 5),
      minuteOfDay: 9 * 60,
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.returnPurchase,
      lines: [
        _purchaseLine(
          id: 'purchase-return-line',
          itemId: 'item-return',
          warehouseId: 'warehouse-return',
          quantity: 1,
          unitPrice: Money.fromMajor(999, AppCurrency.iqd),
        ),
      ],
    );
    final repository = DemoInventoryCostRepository(
      openingBalances: [
        _openingCost(
          warehouseId: 'warehouse-return',
          itemId: 'item-return',
          quantity: 3,
          totalCostIqd: 301,
        ),
      ],
      purchases: [purchaseReturn],
    );

    final balance = (await repository.getBalances()).single;
    expect(balance.quantity, const StockQuantity(2));
    expect(balance.totalCostIqd, Money.fromMajor(201, AppCurrency.iqd));
  });

  test('unknown and negative stock produce explicit unavailable sale cost',
      () async {
    final sale = _sale(
      id: 'sale-unknown-cost',
      documentNumber: 7,
      date: BusinessDate(2026, 8, 5),
      minuteOfDay: 10 * 60,
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      lines: [
        _salesLine(
          id: 'sale-unknown-cost-line',
          itemId: 'item-unknown-cost',
          warehouseId: 'warehouse-unknown-cost',
          quantity: 2,
          unitPrice: Money.fromMajor(10, AppCurrency.usd),
        ),
      ],
    );
    final repository = DemoInventoryCostRepository(
      openingBalances: const [],
      sales: [sale],
    );

    final record = (await repository.getSalesLineCosts()).single;
    expect(record.availability, InventoryCostAvailability.unavailable);
    expect(record.method, InventoryCostMethod.unavailable);
    expect(record.totalCostIqd, isNull);
    expect(record.totalCost, isNull);
    expect(record.profit, isNull);
    final balance = (await repository.getBalances()).single;
    expect(balance.quantity, const StockQuantity(-2));
    expect(balance.totalCostIqd, isNull);
    expect(balance.availability, InventoryCostAvailability.unavailable);
  });

  test('transfers are staged atomically and reversals use current average',
      () async {
    final repository = DemoInventoryCostRepository(
      openingBalances: [
        _openingCost(
          warehouseId: 'warehouse-source',
          itemId: 'item-transfer',
          quantity: 2,
          totalCostIqd: 200,
        ),
        _openingCost(
          warehouseId: 'warehouse-destination',
          itemId: 'item-transfer',
          quantity: 1,
          totalCostIqd: 200,
        ),
      ],
    );
    final original = _transfer(
      id: 'transfer-original',
      documentNumber: 1,
      createdAt: DateTime.utc(2026, 8, 6, 9),
      fromWarehouseId: 'warehouse-source',
      toWarehouseId: 'warehouse-destination',
      itemId: 'item-transfer',
      quantity: 1,
    );
    final staged = repository.stageTransfer(
      repository.createSnapshot(),
      transfer: original,
    );
    expect(
      (await repository.getBalance(
        warehouseId: EntityId('warehouse-source'),
        itemId: EntityId('item-transfer'),
      ))
          ?.quantity,
      const StockQuantity(2),
    );
    expect(
      _snapshotBalance(staged, 'warehouse-source', 'item-transfer')
          .totalCostIqd,
      Money.fromMajor(100, AppCurrency.iqd),
    );
    expect(
      _snapshotBalance(staged, 'warehouse-destination', 'item-transfer')
          .totalCostIqd,
      Money.fromMajor(300, AppCurrency.iqd),
    );
    repository.commitSnapshot(staged);

    final conflicting = _transfer(
      id: original.id.value,
      documentNumber: original.documentNumber,
      createdAt: DateTime.utc(2026, 8, 6, 10),
      fromWarehouseId: original.fromWarehouseId.value,
      toWarehouseId: original.toWarehouseId.value,
      itemId: 'item-transfer',
      quantity: 1,
    );
    expect(
      () => repository.stageTransfer(
        repository.createSnapshot(),
        transfer: conflicting,
      ),
      throwsStateError,
    );
    final impossible = _transfer(
      id: 'transfer-impossible',
      documentNumber: 2,
      createdAt: DateTime.utc(2026, 8, 6, 11),
      fromWarehouseId: 'warehouse-source',
      toWarehouseId: 'warehouse-destination',
      itemId: 'item-transfer',
      quantity: 99,
    );
    expect(
      () => repository.stageTransfer(
        repository.createSnapshot(),
        transfer: impossible,
      ),
      throwsStateError,
    );
    expect(
      (await repository.getBalances())
          .fold<int>(0, (sum, balance) => sum + balance.quantity.value),
      3,
    );

    final reversal = _transfer(
      id: 'transfer-reversal',
      documentNumber: 3,
      createdAt: DateTime.utc(2026, 8, 7, 9),
      fromWarehouseId: 'warehouse-destination',
      toWarehouseId: 'warehouse-source',
      itemId: 'item-transfer',
      quantity: 1,
      reversalOfId: original.id.value,
    );
    final reversed = repository.stageTransfer(
      repository.createSnapshot(),
      transfer: reversal,
    );
    expect(
      _snapshotBalance(reversed, 'warehouse-source', 'item-transfer')
          .totalCostIqd,
      Money.fromMajor(250, AppCurrency.iqd),
    );
    expect(
      _snapshotBalance(reversed, 'warehouse-destination', 'item-transfer')
          .totalCostIqd,
      Money.fromMajor(150, AppCurrency.iqd),
    );
    expect(
      reversed.balances.fold<int>(
        0,
        (sum, balance) => sum + balance.totalCostIqd!.minorUnits,
      ),
      400,
    );
  });

  test('reversals must be strictly later and rejection is fully atomic',
      () async {
    final runner = DemoTransactionRunner();
    final itemId = EntityId('item-reversal-time');
    final sourceId = EntityId('warehouse-reversal-source');
    final destinationId = EntityId('warehouse-reversal-destination');
    final originalTime = AuditTimestamp(DateTime.utc(2026, 8, 8, 10));
    final costRepository = DemoInventoryCostRepository(
      openingBalances: [
        _openingCost(
          warehouseId: sourceId.value,
          itemId: itemId.value,
          quantity: 2,
          totalCostIqd: 200,
        ),
      ],
    );
    final warehouseRepository = DemoWarehouseRepository(
      initialValues: [
        _warehouse(sourceId.value, 1),
        _warehouse(destinationId.value, 2),
      ],
      initialInventory: [
        InventoryBalance(
          id: EntityId('inventory-reversal-time-source'),
          warehouseId: sourceId,
          itemId: itemId,
          quantity: const StockQuantity(2),
        ),
      ],
      initialTransfers: const [],
      itemExists: (candidate) async => candidate == itemId,
      transactionRunner: runner,
      inventoryCostEffects: costRepository,
    );
    final original = await warehouseRepository.transfer(
      InventoryTransferDraft(
        fromWarehouseId: sourceId,
        toWarehouseId: destinationId,
        lines: [
          InventoryTransferLine(
            itemId: itemId,
            quantity: WholeQuantity(1),
          ),
        ],
        createdAt: originalTime,
      ),
    );
    final historyBefore = (await warehouseRepository.getTransfers())
        .map(_transferSignature)
        .toList(growable: false);
    final inventoryBefore = await _warehouseInventorySignatures(
      warehouseRepository,
      [sourceId, destinationId],
    );
    final costsBefore = (await costRepository.getBalances())
        .map(_costSignature)
        .toList(growable: false);
    final rejectedTimes = [
      originalTime,
      AuditTimestamp(
        originalTime.value.subtract(const Duration(seconds: 1)),
      ),
    ];

    for (final rejectedAt in rejectedTimes) {
      await expectLater(
        warehouseRepository.reverseTransfer(
          original.id,
          createdAt: rejectedAt,
        ),
        throwsStateError,
      );
      expect(
        (await warehouseRepository.getTransfers()).map(_transferSignature),
        orderedEquals(historyBefore),
      );
      expect(
        await _warehouseInventorySignatures(
          warehouseRepository,
          [sourceId, destinationId],
        ),
        orderedEquals(inventoryBefore),
      );
      expect(
        (await costRepository.getBalances()).map(_costSignature),
        orderedEquals(costsBefore),
      );
    }

    for (var index = 0; index < rejectedTimes.length; index++) {
      final rejected = _transfer(
        id: 'direct-invalid-reversal-$index',
        documentNumber: index + 2,
        createdAt: rejectedTimes[index].value,
        fromWarehouseId: destinationId.value,
        toWarehouseId: sourceId.value,
        itemId: itemId.value,
        quantity: 1,
        reversalOfId: original.id.value,
      );
      expect(
        () => costRepository.stageTransfer(
          costRepository.createSnapshot(),
          transfer: rejected,
        ),
        throwsStateError,
      );
      expect(
        (await costRepository.getBalances()).map(_costSignature),
        orderedEquals(costsBefore),
      );
    }
  });

  test('concurrent warehouse transfers commit one consistent cost snapshot',
      () async {
    final runner = DemoTransactionRunner();
    final itemId = EntityId('item-concurrent');
    final costRepository = DemoInventoryCostRepository(
      openingBalances: [
        _openingCost(
          warehouseId: 'warehouse-concurrent-source',
          itemId: itemId.value,
          quantity: 3,
          totalCostIqd: 300,
        ),
      ],
    );
    final warehouseRepository = DemoWarehouseRepository(
      initialValues: [
        _warehouse('warehouse-concurrent-source', 1),
        _warehouse('warehouse-concurrent-a', 2),
        _warehouse('warehouse-concurrent-b', 3),
      ],
      initialInventory: [
        InventoryBalance(
          id: EntityId('inventory-concurrent-source'),
          warehouseId: EntityId('warehouse-concurrent-source'),
          itemId: itemId,
          quantity: const StockQuantity(3),
        ),
      ],
      initialTransfers: const [],
      itemExists: (candidate) async => candidate == itemId,
      transactionRunner: runner,
      inventoryCostEffects: costRepository,
    );

    Future<Object> transferTo(String warehouseId, int minute) async {
      try {
        return await warehouseRepository.transfer(
          InventoryTransferDraft(
            fromWarehouseId: EntityId('warehouse-concurrent-source'),
            toWarehouseId: EntityId(warehouseId),
            lines: [
              InventoryTransferLine(
                itemId: itemId,
                quantity: WholeQuantity(2),
              ),
            ],
            createdAt: AuditTimestamp(DateTime.utc(2026, 8, 8, 9, minute)),
          ),
        );
      } catch (error) {
        return error;
      }
    }

    final results = await Future.wait<Object>([
      transferTo('warehouse-concurrent-a', 1),
      transferTo('warehouse-concurrent-b', 2),
    ]);
    expect(results.whereType<InventoryTransfer>(), hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    final committed = results.whereType<InventoryTransfer>().single;
    expect(await warehouseRepository.getTransfers(), hasLength(1));
    expect(
      _inventoryQuantity(
        await warehouseRepository.getInventory(
          EntityId('warehouse-concurrent-source'),
        ),
        itemId,
      ),
      1,
    );
    expect(
      _inventoryQuantity(
        await warehouseRepository.getInventory(committed.toWarehouseId),
        itemId,
      ),
      2,
    );
    final sourceCost = await costRepository.getBalance(
      warehouseId: EntityId('warehouse-concurrent-source'),
      itemId: itemId,
    );
    final destinationCost = await costRepository.getBalance(
      warehouseId: committed.toWarehouseId,
      itemId: itemId,
    );
    expect(sourceCost?.quantity, const StockQuantity(1));
    expect(sourceCost?.totalCostIqd, Money.fromMajor(100, AppCurrency.iqd));
    expect(destinationCost?.quantity, const StockQuantity(2));
    expect(
      destinationCost?.totalCostIqd,
      Money.fromMajor(200, AppCurrency.iqd),
    );

    final costsBeforeMissingReference = await costRepository.getBalances();
    await expectLater(
      warehouseRepository.transfer(
        InventoryTransferDraft(
          fromWarehouseId: EntityId('warehouse-concurrent-source'),
          toWarehouseId: EntityId('warehouse-concurrent-a'),
          lines: [
            InventoryTransferLine(
              itemId: EntityId('item-missing'),
              quantity: WholeQuantity(1),
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    expect(await warehouseRepository.getTransfers(), hasLength(1));
    expect(
      (await costRepository.getBalances()).map(_costSignature),
      orderedEquals(costsBeforeMissingReference.map(_costSignature)),
    );
  });
}

PurchaseInvoice _purchase({
  required String id,
  required int documentNumber,
  required BusinessDate date,
  required int minuteOfDay,
  required AppCurrency currency,
  required ExchangeRate exchangeRate,
  required Iterable<PurchaseInvoiceLine> lines,
  PurchaseTransactionKind purchaseKind = PurchaseTransactionKind.local,
  Money? expenses,
  Money? invoiceDiscount,
}) {
  return PurchaseInvoice(
    id: EntityId(id),
    documentNumber: documentNumber,
    date: date,
    minuteOfDay: minuteOfDay,
    supplierId: EntityId('supplier-test'),
    defaultWarehouseId: lines.first.warehouseId,
    currency: currency,
    exchangeRate: exchangeRate,
    purchaseKind: purchaseKind,
    settlementKind: PurchaseSettlementKind.credit,
    lines: lines,
    expenses: expenses ?? Money.zero(currency),
    invoiceDiscount: invoiceDiscount ?? Money.zero(currency),
    paid: Money.zero(currency),
  );
}

PurchaseInvoiceLine _purchaseLine({
  required String id,
  required String itemId,
  required String warehouseId,
  required int quantity,
  required Money unitPrice,
}) {
  return PurchaseInvoiceLine(
    id: EntityId(id),
    itemId: EntityId(itemId),
    warehouseId: EntityId(warehouseId),
    quantity: WholeQuantity(quantity),
    containerQuantity: WholeQuantity(0),
    purchasePrice: unitPrice,
    lineDiscount: Money.zero(unitPrice.currency),
    salePrice: Money.zero(unitPrice.currency),
  );
}

SalesInvoice _sale({
  required String id,
  required int documentNumber,
  required BusinessDate date,
  required int minuteOfDay,
  required AppCurrency currency,
  required ExchangeRate exchangeRate,
  required Iterable<SalesInvoiceLine> lines,
  Money? invoiceDiscount,
}) {
  return SalesInvoice(
    id: EntityId(id),
    documentNumber: documentNumber,
    date: date,
    minuteOfDay: minuteOfDay,
    customerId: EntityId('customer-test'),
    defaultWarehouseId: lines.first.warehouseId,
    currency: currency,
    exchangeRate: exchangeRate,
    settlementKind: SalesSettlementKind.credit,
    lines: lines,
    invoiceDiscount: invoiceDiscount ?? Money.zero(currency),
    received: Money.zero(currency),
  );
}

SalesInvoiceLine _salesLine({
  required String id,
  required String itemId,
  required String warehouseId,
  required int quantity,
  required Money unitPrice,
}) {
  return SalesInvoiceLine(
    id: EntityId(id),
    itemId: EntityId(itemId),
    warehouseId: EntityId(warehouseId),
    quantity: WholeQuantity(quantity),
    unitPrice: unitPrice,
    discountPerUnit: Money.zero(unitPrice.currency),
  );
}

InventoryCostBalance _openingCost({
  required String warehouseId,
  required String itemId,
  required int quantity,
  required int totalCostIqd,
}) {
  return InventoryCostBalance(
    id: EntityId('opening-$warehouseId-$itemId'),
    warehouseId: EntityId(warehouseId),
    itemId: EntityId(itemId),
    quantity: StockQuantity(quantity),
    totalCostIqd: Money.fromMajor(totalCostIqd, AppCurrency.iqd),
  );
}

InventoryTransfer _transfer({
  required String id,
  required int documentNumber,
  required DateTime createdAt,
  required String fromWarehouseId,
  required String toWarehouseId,
  required String itemId,
  required int quantity,
  String? reversalOfId,
}) {
  return InventoryTransfer(
    id: EntityId(id),
    documentNumber: documentNumber,
    createdAt: AuditTimestamp(createdAt),
    fromWarehouseId: EntityId(fromWarehouseId),
    toWarehouseId: EntityId(toWarehouseId),
    lines: [
      InventoryTransferLine(
        itemId: EntityId(itemId),
        quantity: WholeQuantity(quantity),
      ),
    ],
    reversalOfId: reversalOfId == null ? null : EntityId(reversalOfId),
  );
}

InventoryCostBalance _snapshotBalance(
  DemoInventoryCostSnapshot snapshot,
  String warehouseId,
  String itemId,
) {
  return snapshot.balances.singleWhere(
    (balance) =>
        balance.warehouseId == EntityId(warehouseId) &&
        balance.itemId == EntityId(itemId),
  );
}

Warehouse _warehouse(String id, int number) {
  return Warehouse(
    id: id,
    number: number,
    name: id,
    location: 'test',
    notes: '',
  );
}

int _inventoryQuantity(List<InventoryBalance> balances, EntityId itemId) {
  for (final balance in balances) {
    if (balance.itemId == itemId) return balance.quantity.value;
  }
  return 0;
}

String _costSignature(InventoryCostBalance balance) {
  return '${balance.warehouseId.value}|${balance.itemId.value}|'
      '${balance.quantity.value}|${balance.totalCostIqd?.minorUnits}';
}

String _transferSignature(InventoryTransfer transfer) {
  return '${transfer.id.value}|${transfer.documentNumber}|'
      '${transfer.createdAt.value.toIso8601String()}|'
      '${transfer.fromWarehouseId.value}|${transfer.toWarehouseId.value}|'
      '${transfer.reversalOfId?.value}';
}

Future<List<String>> _warehouseInventorySignatures(
  DemoWarehouseRepository repository,
  Iterable<EntityId> warehouseIds,
) async {
  final values = <String>[];
  for (final warehouseId in warehouseIds) {
    for (final balance in await repository.getInventory(warehouseId)) {
      values.add(
        '${balance.warehouseId.value}|${balance.itemId.value}|'
        '${balance.quantity.value}',
      );
    }
  }
  values.sort();
  return List.unmodifiable(values);
}
