import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/items/domain/item.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:erp/features/warehouses/presentation/warehouses_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local and import creates apply inventory and supplier effects once',
      () async {
    final repositories = AppRepositories.demo();
    final supplierId = EntityId('party-009');
    final localWarehouseId = EntityId('warehouse-001');
    final importWarehouseId = EntityId('warehouse-002');
    final localItemId = EntityId('item-001');
    final importItemId = EntityId('item-003');
    final localStockBefore = await _stock(
      repositories,
      localWarehouseId,
      localItemId,
    );
    final importStockBefore = await _stock(
      repositories,
      importWarehouseId,
      importItemId,
    );
    final supplierBefore = (await repositories.parties.getById(supplierId))!;

    final local = _invoice(
      id: 'phase3-purchase-local',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: supplierId,
      warehouseId: localWarehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase3-purchase-local-line',
          itemId: localItemId,
          warehouseId: localWarehouseId,
          quantity: 2,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 50,
    );
    final savedLocal = await repositories.purchases.createInvoice(local);

    expect(savedLocal.id, local.id);
    expect(
      await _stock(repositories, localWarehouseId, localItemId),
      localStockBefore + 2,
    );
    var supplier = (await repositories.parties.getById(supplierId))!;
    expect(
      supplier.iqdBalance,
      supplierBefore.iqdBalance - Money.fromMajor(150, AppCurrency.iqd),
    );
    expect(
      savedLocal.balanceAfterInvoice,
      (supplierBefore.iqdBalance - Money.fromMajor(150, AppCurrency.iqd))
          .absolute,
    );
    expect(supplier.usdBalance, supplierBefore.usdBalance);

    final imported = _invoice(
      id: 'phase3-purchase-import',
      documentNumber: 105,
      kind: PurchaseTransactionKind.import,
      supplierId: supplierId,
      warehouseId: importWarehouseId,
      currency: AppCurrency.usd,
      lines: [
        _line(
          id: 'phase3-purchase-import-line',
          itemId: importItemId,
          warehouseId: importWarehouseId,
          quantity: 3,
          price: 10,
          currency: AppCurrency.usd,
        ),
      ],
      paid: 2,
    );
    await repositories.purchases.save(imported);
    await repositories.purchases.save(
      _copyInvoice(imported, notes: 'generic save replaces exactly once'),
    );

    expect(
      await _stock(repositories, importWarehouseId, importItemId),
      importStockBefore + 3,
    );
    supplier = (await repositories.parties.getById(supplierId))!;
    expect(
      supplier.usdBalance,
      supplierBefore.usdBalance - Money.fromMajor(28, AppCurrency.usd),
    );
    expect(await repositories.purchases.nextDocumentNumber(), 106);
  });

  test('purchase returns subtract stock and restore supplier credit', () async {
    final repositories = AppRepositories.demo();
    final source = (await repositories.purchases.getById(
      EntityId('purchase-invoice-101'),
    ))!;
    final sourceLine = source.lines.first;
    final supplierId = source.supplierId;
    final warehouseId = sourceLine.warehouseId;
    final itemId = sourceLine.itemId;
    final stockBefore = await _stock(repositories, warehouseId, itemId);
    final supplierBefore = (await repositories.parties.getById(supplierId))!;
    final returned = _invoice(
      id: 'phase3-purchase-return',
      documentNumber: 104,
      kind: PurchaseTransactionKind.returnPurchase,
      supplierId: supplierId,
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      originalPurchaseInvoiceId: source.id,
      lines: [
        _line(
          id: 'phase3-purchase-return-line',
          itemId: itemId,
          warehouseId: warehouseId,
          quantity: 2,
          price: sourceLine.purchasePrice.majorUnits,
          salePrice: sourceLine.salePrice.majorUnits,
          currency: AppCurrency.iqd,
          originalPurchaseLineId: sourceLine.id,
        ),
      ],
      paid: 50,
    );

    await repositories.purchases.createInvoice(returned);

    expect(await _stock(repositories, warehouseId, itemId), stockBefore - 2);
    final supplierAfter = (await repositories.parties.getById(supplierId))!;
    expect(
      supplierAfter.iqdBalance,
      supplierBefore.iqdBalance + Money.fromMajor(15950, AppCurrency.iqd),
    );
  });

  test('replace reverses old effects across every changed dimension', () async {
    final repositories = AppRepositories.demo();
    final returnSource = (await repositories.purchases.getById(
      EntityId('purchase-invoice-102'),
    ))!;
    final returnSourceLine = returnSource.lines.last;
    final oldSupplierId = EntityId('party-009');
    final newSupplierId = returnSource.supplierId;
    final oldWarehouseId = EntityId('warehouse-001');
    final newWarehouseId = returnSourceLine.warehouseId;
    final oldItemId = EntityId('item-001');
    final newItemId = returnSourceLine.itemId;
    final oldStockBefore = await _stock(
      repositories,
      oldWarehouseId,
      oldItemId,
    );
    final newStockBefore = await _stock(
      repositories,
      newWarehouseId,
      newItemId,
    );
    final oldSupplierBefore =
        (await repositories.parties.getById(oldSupplierId))!;
    final newSupplierBefore =
        (await repositories.parties.getById(newSupplierId))!;
    final original = _invoice(
      id: 'phase3-purchase-replace',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: oldSupplierId,
      warehouseId: oldWarehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase3-purchase-replace-old-line',
          itemId: oldItemId,
          warehouseId: oldWarehouseId,
          quantity: 2,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 50,
    );
    await repositories.purchases.createInvoice(original);

    final replacement = _invoice(
      id: original.id.value,
      documentNumber: 105,
      kind: PurchaseTransactionKind.import,
      supplierId: newSupplierId,
      warehouseId: newWarehouseId,
      currency: AppCurrency.usd,
      lines: [
        _line(
          id: 'phase3-purchase-replace-new-line',
          itemId: newItemId,
          warehouseId: newWarehouseId,
          quantity: 3,
          price: returnSourceLine.purchasePrice.majorUnits,
          salePrice: returnSourceLine.salePrice.majorUnits,
          currency: AppCurrency.usd,
        ),
      ],
      invoiceDiscount: 10.34,
      paid: 4,
    );
    final saved = await repositories.purchases.replaceInvoice(replacement);

    expect(saved.id, original.id);
    expect(saved.documentNumber, 105);
    expect(
      await _stock(repositories, oldWarehouseId, oldItemId),
      oldStockBefore,
    );
    expect(
      await _stock(repositories, newWarehouseId, newItemId),
      newStockBefore + 3,
    );
    final oldSupplierAfter =
        (await repositories.parties.getById(oldSupplierId))!;
    final newSupplierAfter =
        (await repositories.parties.getById(newSupplierId))!;
    expect(oldSupplierAfter.iqdBalance, oldSupplierBefore.iqdBalance);
    expect(oldSupplierAfter.usdBalance, oldSupplierBefore.usdBalance);
    expect(newSupplierAfter.iqdBalance, newSupplierBefore.iqdBalance);
    expect(
      newSupplierAfter.usdBalance,
      newSupplierBefore.usdBalance - Money.fromMajor(285.66, AppCurrency.usd),
    );
    expect(await repositories.purchases.nextDocumentNumber(), 106);
    for (final reservedNumber in const [104, 105]) {
      await expectLater(
        repositories.purchases.createInvoice(
          _copyInvoice(
            original,
            id: EntityId('phase3-purchase-reserved-$reservedNumber'),
            documentNumber: reservedNumber,
          ),
        ),
        throwsStateError,
      );
    }
  });

  test('delete reverses projections and never releases document numbers',
      () async {
    final repositories = AppRepositories.demo();
    final supplierId = EntityId('party-009');
    final warehouseId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final stockBefore = await _stock(repositories, warehouseId, itemId);
    final supplierBefore = (await repositories.parties.getById(supplierId))!;
    final invoice = _invoice(
      id: 'phase3-purchase-delete',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: supplierId,
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase3-purchase-delete-line',
          itemId: itemId,
          warehouseId: warehouseId,
          quantity: 2,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 50,
    );
    await repositories.purchases.createInvoice(invoice);

    await repositories.purchases.delete(invoice.id);

    expect(await repositories.purchases.getById(invoice.id), isNull);
    expect(await _stock(repositories, warehouseId, itemId), stockBefore);
    final supplierAfter = (await repositories.parties.getById(supplierId))!;
    expect(supplierAfter.iqdBalance, supplierBefore.iqdBalance);
    expect(await repositories.purchases.nextDocumentNumber(), 105);
    expect(
      () => repositories.purchases.createInvoice(
        _copyInvoice(invoice, id: EntityId('phase3-purchase-reuse')),
      ),
      throwsStateError,
    );
  });

  test('purchase deletion removes zero stock before item deletion', () async {
    final repositories = AppRepositories.demo();
    final group = (await repositories.items.getGroups()).first;
    final type = (await repositories.items.getTypes(groupId: group.entityId))
        .first;
    final item = Item.typed(
      entityId: EntityId('phase1-zero-stock-item'),
      code: 'PHASE1-ZERO-STOCK',
      name: 'مادة اختبار الرصيد الصفري',
      barcode: '9900000000011',
      groupEntityId: group.entityId,
      groupName: group.name,
      typeEntityId: type.entityId,
      typeName: type.name,
      iqdSalePrice: Money.fromMajor(120, AppCurrency.iqd),
      usdSalePrice: Money.fromMajor(1, AppCurrency.usd),
      notes: '',
    );
    await repositories.items.save(item);

    final warehouseId = EntityId('warehouse-001');
    final invoice = _invoice(
      id: 'phase1-zero-stock-item-purchase',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: EntityId('party-009'),
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase1-zero-stock-item-purchase-line',
          itemId: item.entityId,
          warehouseId: warehouseId,
          quantity: 2,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 0,
    );

    await repositories.purchases.createInvoice(invoice);
    expect(await _stock(repositories, warehouseId, item.entityId), 2);

    await repositories.purchases.delete(invoice.id);

    expect(
      (await repositories.warehouses.getInventory(warehouseId))
          .where((balance) => balance.itemId == item.entityId),
      isEmpty,
    );
    await repositories.items.delete(item.entityId);
    expect(await repositories.items.getById(item.entityId), isNull);
    expect(
      (await repositories.warehouses.getInventory(warehouseId))
          .where((balance) => balance.itemId == item.entityId),
      isEmpty,
    );

    final controller = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.dataState.status, AppDataStatus.ready);
  });

  test('purchase deletion removes zero stock before warehouse deletion',
      () async {
    final repositories = AppRepositories.demo();
    final warehouse = Warehouse.typed(
      entityId: EntityId('phase1-zero-stock-warehouse'),
      number: 5,
      name: 'مخزن اختبار الرصيد الصفري',
      location: '',
      notes: '',
    );
    await repositories.warehouses.save(warehouse);

    final itemId = EntityId('item-001');
    final invoice = _invoice(
      id: 'phase1-zero-stock-warehouse-purchase',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: EntityId('party-009'),
      warehouseId: warehouse.entityId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase1-zero-stock-warehouse-purchase-line',
          itemId: itemId,
          warehouseId: warehouse.entityId,
          quantity: 3,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 0,
    );

    await repositories.purchases.createInvoice(invoice);
    expect(await _stock(repositories, warehouse.entityId, itemId), 3);

    await repositories.purchases.delete(invoice.id);

    expect(
      await repositories.warehouses.getInventory(warehouse.entityId),
      isEmpty,
    );
    await repositories.warehouses.delete(warehouse.entityId);
    expect(
      await repositories.warehouses.getById(warehouse.entityId),
      isNull,
    );
  });

  test('linked return lines are aggregated before stock validation',
      () async {
    final repositories = AppRepositories.demo();
    final supplierId = EntityId('party-009');
    final warehouseId = EntityId('warehouse-001');
    final sourceWarehouseId = EntityId('warehouse-002');
    final itemId = EntityId('item-001');
    final stockBefore = await _stock(repositories, warehouseId, itemId);
    expect(stockBefore, greaterThan(1));
    final perLine = stockBefore ~/ 2 + 1;
    final source = _invoice(
      id: 'phase3-purchase-duplicate-source',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: supplierId,
      warehouseId: sourceWarehouseId,
      currency: AppCurrency.iqd,
      lines: [
        for (var index = 0; index < 2; index++)
          _line(
            id: 'phase3-purchase-duplicate-source-line-$index',
            itemId: itemId,
            warehouseId: sourceWarehouseId,
            quantity: perLine,
            price: 1,
            currency: AppCurrency.iqd,
          ),
      ],
      paid: 0,
    );
    await repositories.purchases.createInvoice(source);
    final supplierBefore = (await repositories.parties.getById(supplierId))!;
    final invoice = _invoice(
      id: 'phase3-purchase-duplicate-lines',
      documentNumber: 105,
      kind: PurchaseTransactionKind.returnPurchase,
      supplierId: supplierId,
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      originalPurchaseInvoiceId: source.id,
      lines: [
        for (var index = 0; index < 2; index++)
          _line(
            id: 'phase3-purchase-duplicate-line-$index',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: perLine,
            price: 1,
            currency: AppCurrency.iqd,
            originalPurchaseLineId: source.lines[index].id,
          ),
      ],
      paid: 0,
    );

    await expectLater(
      repositories.purchases.createInvoice(invoice),
      throwsStateError,
    );

    expect(await repositories.purchases.getById(invoice.id), isNull);
    expect(await _stock(repositories, warehouseId, itemId), stockBefore);
    expect(
      (await repositories.parties.getById(supplierId))!.iqdBalance,
      supplierBefore.iqdBalance,
    );
    expect(await repositories.purchases.nextDocumentNumber(), 105);
  });

  test('failed multi-line mutation is atomic and reserves nothing', () async {
    final repositories = AppRepositories.demo();
    final supplierId = EntityId('party-009');
    final warehouseId = EntityId('warehouse-001');
    final sourceWarehouseId = EntityId('warehouse-002');
    final firstItemId = EntityId('item-001');
    final secondItemId = EntityId('item-002');
    final firstStockBefore = await _stock(
      repositories,
      warehouseId,
      firstItemId,
    );
    final secondStockBefore = await _stock(
      repositories,
      warehouseId,
      secondItemId,
    );
    final source = _invoice(
      id: 'phase3-purchase-atomic-source',
      documentNumber: 104,
      kind: PurchaseTransactionKind.local,
      supplierId: supplierId,
      warehouseId: sourceWarehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase3-purchase-atomic-source-line-1',
          itemId: firstItemId,
          warehouseId: sourceWarehouseId,
          quantity: 1,
          price: 100,
          currency: AppCurrency.iqd,
        ),
        _line(
          id: 'phase3-purchase-atomic-source-line-2',
          itemId: secondItemId,
          warehouseId: sourceWarehouseId,
          quantity: secondStockBefore + 1,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 0,
    );
    await repositories.purchases.createInvoice(source);
    final supplierBefore = (await repositories.parties.getById(supplierId))!;
    final invalid = _invoice(
      id: 'phase3-purchase-atomic-failure',
      documentNumber: 105,
      kind: PurchaseTransactionKind.returnPurchase,
      supplierId: supplierId,
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      originalPurchaseInvoiceId: source.id,
      lines: [
        _line(
          id: 'phase3-purchase-atomic-valid-line',
          itemId: firstItemId,
          warehouseId: warehouseId,
          quantity: 1,
          price: 100,
          currency: AppCurrency.iqd,
          originalPurchaseLineId: source.lines.first.id,
        ),
        _line(
          id: 'phase3-purchase-atomic-invalid-line',
          itemId: secondItemId,
          warehouseId: warehouseId,
          quantity: secondStockBefore + 1,
          price: 100,
          currency: AppCurrency.iqd,
          originalPurchaseLineId: source.lines.last.id,
        ),
      ],
      paid: 0,
    );

    await expectLater(
      repositories.purchases.createInvoice(invalid),
      throwsStateError,
    );

    expect(await repositories.purchases.getById(invalid.id), isNull);
    expect(
      await _stock(repositories, warehouseId, firstItemId),
      firstStockBefore,
    );
    expect(
      await _stock(repositories, warehouseId, secondItemId),
      secondStockBefore,
    );
    expect(
      (await repositories.parties.getById(supplierId))!.iqdBalance,
      supplierBefore.iqdBalance,
    );
    expect(await repositories.purchases.nextDocumentNumber(), 105);

    final valid = _invoice(
      id: 'phase3-purchase-after-failure',
      documentNumber: 105,
      kind: PurchaseTransactionKind.local,
      supplierId: supplierId,
      warehouseId: warehouseId,
      currency: AppCurrency.iqd,
      lines: [
        _line(
          id: 'phase3-purchase-after-failure-line',
          itemId: firstItemId,
          warehouseId: warehouseId,
          quantity: 1,
          price: 100,
          currency: AppCurrency.iqd,
        ),
      ],
      paid: 0,
    );
    await repositories.purchases.createInvoice(valid);
    expect(await repositories.purchases.getById(valid.id), isNotNull);
  });

  test('concurrent creates serialize document checks and effects', () async {
    final repositories = AppRepositories.demo();
    final supplierId = EntityId('party-009');
    final warehouseId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final stockBefore = await _stock(repositories, warehouseId, itemId);
    final supplierBefore = (await repositories.parties.getById(supplierId))!;
    PurchaseInvoice candidate(String suffix) => _invoice(
          id: 'phase3-purchase-concurrent-$suffix',
          documentNumber: 104,
          kind: PurchaseTransactionKind.local,
          supplierId: supplierId,
          warehouseId: warehouseId,
          currency: AppCurrency.iqd,
          lines: [
            _line(
              id: 'phase3-purchase-concurrent-$suffix-line',
              itemId: itemId,
              warehouseId: warehouseId,
              quantity: 1,
              price: 100,
              currency: AppCurrency.iqd,
            ),
          ],
          paid: 0,
        );
    Future<Object> captureCreate(PurchaseInvoice invoice) async {
      try {
        return await repositories.purchases.createInvoice(invoice);
      } catch (error) {
        return error;
      }
    }

    final results = await Future.wait<Object>([
      for (final suffix in const ['a', 'b'])
        captureCreate(candidate(suffix)),
    ]);

    expect(results.whereType<PurchaseInvoice>(), hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    expect(
      (await repositories.purchases.getAll())
          .where((invoice) => invoice.documentNumber == 104),
      hasLength(1),
    );
    expect(await _stock(repositories, warehouseId, itemId), stockBefore + 1);
    expect(
      (await repositories.parties.getById(supplierId))!.iqdBalance,
      supplierBefore.iqdBalance - Money.fromMajor(100, AppCurrency.iqd),
    );
    expect(await repositories.purchases.nextDocumentNumber(), 105);
  });

  test('seeded purchase replace is neutral and delete reverses seed effects',
      () async {
    final repositories = AppRepositories.demo();
    final seeded = (await repositories.purchases.getAll()).firstWhere(
      (invoice) => invoice.id == EntityId('purchase-invoice-102'),
    );
    final quantities = _aggregateQuantities(seeded);
    final stockBefore = <_InventoryKey, int>{};
    for (final entry in quantities.entries) {
      stockBefore[entry.key] = await _stock(
        repositories,
        entry.key.warehouseId,
        entry.key.itemId,
      );
    }
    final supplierBefore =
        (await repositories.parties.getById(seeded.supplierId))!;

    final replaced = await repositories.purchases.replaceInvoice(
      _copyInvoice(seeded, notes: 'seed effect remains exactly once'),
    );

    expect(replaced.id, seeded.id);
    for (final entry in quantities.entries) {
      expect(
        await _stock(
          repositories,
          entry.key.warehouseId,
          entry.key.itemId,
        ),
        stockBefore[entry.key],
      );
    }
    expect(
      _partyBalance(
        (await repositories.parties.getById(seeded.supplierId))!,
        seeded.currency,
      ),
      _partyBalance(supplierBefore, seeded.currency),
    );

    await repositories.purchases.deleteInvoicePermanently(seeded.id);

    for (final entry in quantities.entries) {
      expect(
        await _stock(
          repositories,
          entry.key.warehouseId,
          entry.key.itemId,
        ),
        stockBefore[entry.key]! - entry.value,
      );
    }
    expect(
      _partyBalance(
        (await repositories.parties.getById(seeded.supplierId))!,
        seeded.currency,
      ),
      _partyBalance(supplierBefore, seeded.currency) +
          (seeded.total - seeded.paid),
    );
    expect(await repositories.purchases.nextDocumentNumber(), 104);
  });
}

typedef _InventoryKey = ({EntityId warehouseId, EntityId itemId});

Map<_InventoryKey, int> _aggregateQuantities(PurchaseInvoice invoice) {
  final result = <_InventoryKey, int>{};
  for (final line in invoice.lines) {
    final key = (warehouseId: line.warehouseId, itemId: line.itemId);
    result[key] = (result[key] ?? 0) + line.quantity.value;
  }
  return result;
}

Future<int> _stock(
  AppRepositories repositories,
  EntityId warehouseId,
  EntityId itemId,
) async {
  final balances = await repositories.warehouses.getInventory(warehouseId);
  for (final balance in balances) {
    if (balance.itemId == itemId) return balance.quantity.value;
  }
  return 0;
}

Money _partyBalance(Party party, AppCurrency currency) =>
    currency == AppCurrency.iqd ? party.iqdBalance : party.usdBalance;

PurchaseInvoice _invoice({
  required String id,
  required int documentNumber,
  required PurchaseTransactionKind kind,
  required EntityId supplierId,
  required EntityId warehouseId,
  required AppCurrency currency,
  required List<PurchaseInvoiceLine> lines,
  required num paid,
  EntityId? originalPurchaseInvoiceId,
  num invoiceDiscount = 0,
}) {
  return PurchaseInvoice(
    id: EntityId(id),
    documentNumber: documentNumber,
    date: BusinessDate(2026, 8, 10),
    minuteOfDay: 12 * 60,
    supplierId: supplierId,
    defaultWarehouseId: warehouseId,
    currency: currency,
    exchangeRate: ExchangeRate.parse('1310'),
    purchaseKind: kind,
    settlementKind: PurchaseSettlementKind.credit,
    lines: lines,
    expenses: Money.zero(currency),
    invoiceDiscount: Money.fromMajor(invoiceDiscount, currency),
    paid: Money.fromMajor(paid, currency),
    originalPurchaseInvoiceId: originalPurchaseInvoiceId,
  );
}

PurchaseInvoiceLine _line({
  required String id,
  required EntityId itemId,
  required EntityId warehouseId,
  required int quantity,
  required num price,
  required AppCurrency currency,
  num? salePrice,
  EntityId? originalPurchaseLineId,
}) {
  return PurchaseInvoiceLine(
    id: EntityId(id),
    itemId: itemId,
    warehouseId: warehouseId,
    quantity: WholeQuantity(quantity),
    containerQuantity: WholeQuantity(0),
    purchasePrice: Money.fromMajor(price, currency),
    lineDiscount: Money.zero(currency),
    salePrice: Money.fromMajor(salePrice ?? price, currency),
    originalPurchaseLineId: originalPurchaseLineId,
  );
}

PurchaseInvoice _copyInvoice(
  PurchaseInvoice source, {
  EntityId? id,
  int? documentNumber,
  String? notes,
}) {
  return PurchaseInvoice(
    id: id ?? source.id,
    documentNumber: documentNumber ?? source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    supplierId: source.supplierId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    purchaseKind: source.purchaseKind,
    settlementKind: source.settlementKind,
    lines: source.lines,
    expenses: source.expenses,
    invoiceDiscount: source.invoiceDiscount,
    paid: source.paid,
    originalPurchaseInvoiceId: source.originalPurchaseInvoiceId,
    supplierNameSnapshot: source.supplierNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    notes: notes ?? source.notes,
  );
}
