import 'dart:async';

import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/items/domain/item.dart';
import 'package:erp/features/parties/data/demo_party_repository.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/warehouses/data/demo_warehouse_repository.dart';
import 'package:erp/features/warehouses/domain/inventory_records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transaction runner serializes turns and survives a failed turn',
      () async {
    final runner = DemoTransactionRunner();
    final releaseFirst = Completer<void>();
    final firstStarted = Completer<void>();
    final order = <String>[];

    final first = runner.run(() async {
      order.add('first-start');
      firstStarted.complete();
      await releaseFirst.future;
      order.add('first-end');
    });
    final second = runner.run(() {
      order.add('second');
      throw StateError('expected');
    });
    final secondExpectation = expectLater(second, throwsStateError);
    final third = runner.run(() {
      order.add('third');
      return 3;
    });

    await firstStarted.future;
    expect(order, ['first-start']);
    releaseFirst.complete();
    await first;
    await secondExpectation;
    expect(await third, 3);
    expect(order, ['first-start', 'first-end', 'second', 'third']);
  });

  test('party balance staging is invisible until its no-fail commit', () async {
    final repositories = AppRepositories.demo();
    final parties = repositories.parties as DemoPartyRepository;
    final partyId = EntityId('party-009');
    final before = (await parties.getById(partyId))!;

    final staged = parties.stageBalanceAdjustments([
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: Money.fromMajor(-125, AppCurrency.iqd),
      ),
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: Money.fromMajor(25, AppCurrency.iqd),
      ),
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: Money.fromMajor(5, AppCurrency.usd),
      ),
    ]);

    expect((await parties.getById(partyId))!.iqdBalance, before.iqdBalance);
    parties.commitPartySnapshot(staged);
    final after = (await parties.getById(partyId))!;
    expect(
      after.iqdBalance,
      before.iqdBalance - Money.fromMajor(100, AppCurrency.iqd),
    );
    expect(
      after.usdBalance,
      before.usdBalance + Money.fromMajor(5, AppCurrency.usd),
    );
  });

  test('stale party profile edits preserve transaction-owned balances',
      () async {
    final repositories = AppRepositories.demo();
    final parties = repositories.parties as DemoPartyRepository;
    final partyId = EntityId('party-009');
    final staleProfile = (await parties.getById(partyId))!;
    final adjustedIqd =
        staleProfile.iqdBalance - Money.fromMajor(75, AppCurrency.iqd);

    final staged = parties.stageBalanceAdjustments([
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: Money.fromMajor(-75, AppCurrency.iqd),
      ),
    ]);
    parties.commitPartySnapshot(staged);

    final saved = await parties.save(
      staleProfile.copyWith(name: 'مجهز الفرات المحدث'),
    );

    expect(saved.name, 'مجهز الفرات المحدث');
    expect(saved.iqdBalance, adjustedIqd);
    expect(saved.usdBalance, staleProfile.usdBalance);
  });

  test('inventory staging aggregates identities and exposes negative stock',
      () async {
    final repositories = AppRepositories.demo();
    final warehouses = repositories.warehouses as DemoWarehouseRepository;
    final warehouseId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final before = _quantity(
      await warehouses.getInventory(warehouseId),
      itemId,
    );

    final staged = warehouses.stageInventoryAdjustments(
      [
        DemoInventoryAdjustment(
          warehouseId: warehouseId,
          itemId: itemId,
          quantityDelta: -before,
        ),
        DemoInventoryAdjustment(
          warehouseId: warehouseId,
          itemId: itemId,
          quantityDelta: -2,
        ),
      ],
      allowNegative: true,
    );

    expect(
      _quantity(await warehouses.getInventory(warehouseId), itemId),
      before,
    );
    warehouses.commitInventorySnapshot(staged);
    final balance = (await warehouses.getInventory(warehouseId)).singleWhere(
      (entry) => entry.itemId == itemId,
    );
    expect(balance.quantity, const StockQuantity(-2));
    expect(balance.quantity.isNegative, isTrue);
  });

  test('concurrent transfers cannot overdraw or partially commit', () async {
    final repositories = AppRepositories.demo();
    final warehouses = repositories.warehouses;
    final sourceId = EntityId('warehouse-001');
    final itemId = EntityId('item-001');
    final historyBefore = await warehouses.getTransfers();

    Future<bool> attempt(String destination) async {
      try {
        await warehouses.transfer(
          InventoryTransferDraft(
            fromWarehouseId: sourceId,
            toWarehouseId: EntityId(destination),
            lines: [
              InventoryTransferLine(
                itemId: itemId,
                quantity: WholeQuantity(15),
              ),
            ],
          ),
        );
        return true;
      } on StateError {
        return false;
      }
    }

    final results = await Future.wait([
      attempt('warehouse-002'),
      attempt('warehouse-003'),
    ]);

    expect(results.where((value) => value), hasLength(1));
    expect(
      _quantity(await warehouses.getInventory(sourceId), itemId),
      3,
    );
    expect(
      await warehouses.getTransfers(),
      hasLength(historyBefore.length + 1),
    );
  });

  test('a failing later transfer line leaves every balance and history intact',
      () async {
    final repositories = AppRepositories.demo();
    final warehouses = repositories.warehouses;
    final sourceId = EntityId('warehouse-001');
    final destinationId = EntityId('warehouse-002');
    final sourceBefore = await warehouses.getInventory(sourceId);
    final destinationBefore = await warehouses.getInventory(destinationId);
    final historyBefore = await warehouses.getTransfers();

    await expectLater(
      warehouses.transfer(
        InventoryTransferDraft(
          fromWarehouseId: sourceId,
          toWarehouseId: destinationId,
          lines: [
            InventoryTransferLine(
              itemId: EntityId('item-001'),
              quantity: WholeQuantity(1),
            ),
            InventoryTransferLine(
              itemId: EntityId('item-002'),
              quantity: WholeQuantity(9999),
            ),
          ],
        ),
      ),
      throwsStateError,
    );

    expect(_inventoryValues(await warehouses.getInventory(sourceId)),
        _inventoryValues(sourceBefore));
    expect(_inventoryValues(await warehouses.getInventory(destinationId)),
        _inventoryValues(destinationBefore));
    expect(await warehouses.getTransfers(), hasLength(historyBefore.length));
  });

  test('queued item deletion cannot orphan a concurrently created invoice',
      () async {
    final repositories = AppRepositories.demo();
    final group = (await repositories.items.getGroups()).first;
    final type = (await repositories.items.getTypes(groupId: group.entityId))
        .first;
    final item = Item.typed(
      entityId: EntityId('phase3-concurrent-item'),
      code: 'PHASE3-CONCURRENT',
      name: 'مادة اختبار التزامن',
      barcode: '9900000000001',
      groupEntityId: group.entityId,
      groupName: group.name,
      typeEntityId: type.entityId,
      typeName: type.name,
      iqdSalePrice: Money.fromMajor(100, AppCurrency.iqd),
      usdSalePrice: Money.fromMajor(1, AppCurrency.usd),
      notes: '',
    );
    await repositories.items.save(item);

    final invoice = PurchaseInvoice(
      id: EntityId('phase3-concurrent-item-purchase'),
      documentNumber: 104,
      date: BusinessDate(2026, 8, 10),
      minuteOfDay: 13 * 60,
      supplierId: EntityId('party-009'),
      defaultWarehouseId: EntityId('warehouse-001'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.local,
      settlementKind: PurchaseSettlementKind.credit,
      lines: [
        PurchaseInvoiceLine(
          id: EntityId('phase3-concurrent-item-purchase-line'),
          itemId: item.entityId,
          warehouseId: EntityId('warehouse-001'),
          quantity: WholeQuantity(1),
          containerQuantity: WholeQuantity(0),
          purchasePrice: Money.fromMajor(100, AppCurrency.iqd),
          lineDiscount: Money.zero(AppCurrency.iqd),
          salePrice: Money.fromMajor(120, AppCurrency.iqd),
        ),
      ],
      expenses: Money.zero(AppCurrency.iqd),
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      paid: Money.zero(AppCurrency.iqd),
    );

    final createFuture = repositories.purchases.createInvoice(invoice);
    final deleteExpectation = expectLater(
      repositories.items.delete(item.entityId),
      throwsStateError,
    );

    await createFuture;
    await deleteExpectation;
    expect(await repositories.items.getById(item.entityId), isNotNull);
    expect(await repositories.purchases.getById(invoice.id), isNotNull);
    expect(
      _quantity(
        await repositories.warehouses.getInventory(
          EntityId('warehouse-001'),
        ),
        item.entityId,
      ),
      1,
    );
  });
}

int _quantity(List<InventoryBalance> inventory, EntityId itemId) {
  for (final balance in inventory) {
    if (balance.itemId == itemId) return balance.quantity.value;
  }
  return 0;
}

Map<EntityId, int> _inventoryValues(List<InventoryBalance> inventory) => {
      for (final balance in inventory) balance.itemId: balance.quantity.value,
    };
