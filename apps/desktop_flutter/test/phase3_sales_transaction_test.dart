import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales/domain/sales_repository.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('demo Sales transactions', () {
    test('create applies stock and partial-credit customer effects once',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      final invoice = _sale(
        id: 'phase3-sale-create',
        documentNumber: 104,
        customerId: customerId,
        warehouseId: warehouseId,
        currency: AppCurrency.iqd,
        received: 50,
        lines: [
          _line(
            id: 'phase3-sale-create-line',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: 2,
            unitPrice: 100,
            currency: AppCurrency.iqd,
          ),
        ],
      );

      final saved = await repositories.sales.createInvoice(invoice);

      expect(saved.id, invoice.id);
      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore - 2,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore + Money.fromMajor(150, AppCurrency.iqd),
      );
      expect(
        saved.balanceAfterInvoice,
        balanceBefore + Money.fromMajor(150, AppCurrency.iqd),
      );
      expect(await repositories.sales.nextDocumentNumber(), 105);
    });

    test('generic save chooses create or replace inside the transaction',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      SalesInvoice invoice(int quantity) => _sale(
            id: 'phase3-sale-generic-save',
            documentNumber: 104,
            customerId: customerId,
            warehouseId: warehouseId,
            currency: AppCurrency.iqd,
            lines: [
              _line(
                id: 'phase3-sale-generic-save-line',
                itemId: itemId,
                warehouseId: warehouseId,
                quantity: quantity,
                unitPrice: 1,
                currency: AppCurrency.iqd,
              ),
            ],
          );

      await repositories.sales.save(invoice(2));
      await repositories.sales.save(invoice(3));

      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore - 3,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore + Money.fromMajor(3, AppCurrency.iqd),
      );
      expect(await repositories.sales.nextDocumentNumber(), 105);
    });

    test('seeded replace is neutral and seeded delete reverses projections',
        () async {
      final repositories = AppRepositories.demo();
      final seeded = (await repositories.sales.getAll())
          .firstWhere((invoice) => invoice.documentNumber == 101);
      final customerBefore =
          (await repositories.parties.getById(seeded.customerId))!;
      final quantities = <(EntityId, EntityId), int>{};
      for (final line in seeded.lines) {
        final key = (line.warehouseId, line.itemId);
        quantities[key] = (quantities[key] ?? 0) + line.quantity.value;
      }
      final stockBefore = <(EntityId, EntityId), int>{};
      for (final key in quantities.keys) {
        stockBefore[key] = await _stock(
          repositories,
          warehouseId: key.$1,
          itemId: key.$2,
        );
      }

      final replaced = await repositories.sales.replaceInvoice(
        _copySale(seeded, notes: 'تعديل ملاحظات فقط'),
      );

      expect(
        (await repositories.parties.getById(seeded.customerId))!.iqdBalance,
        customerBefore.iqdBalance,
      );
      for (final key in quantities.keys) {
        expect(
          await _stock(
            repositories,
            warehouseId: key.$1,
            itemId: key.$2,
          ),
          stockBefore[key],
        );
      }

      await repositories.sales.deleteInvoicePermanently(replaced.id);

      final remaining = seeded.total - seeded.received;
      expect(
        (await repositories.parties.getById(seeded.customerId))!.iqdBalance,
        customerBefore.iqdBalance - remaining,
      );
      for (final entry in quantities.entries) {
        expect(
          await _stock(
            repositories,
            warehouseId: entry.key.$1,
            itemId: entry.key.$2,
          ),
          stockBefore[entry.key]! + entry.value,
        );
      }
      expect(await repositories.sales.nextDocumentNumber(), 104);
    });

    test(
        'replace reverses old projections, applies new projections, and '
        'reserves both numbers', () async {
      final repositories = AppRepositories.demo();
      final oldWarehouseId = EntityId('warehouse-001');
      final oldItemId = EntityId('item-003');
      final oldCustomerId = EntityId('party-001');
      final newWarehouseId = EntityId('warehouse-003');
      final newItemId = EntityId('item-002');
      final newCustomerId = EntityId('party-002');
      final oldStockBefore = await _stock(
        repositories,
        warehouseId: oldWarehouseId,
        itemId: oldItemId,
      );
      final newStockBefore = await _stock(
        repositories,
        warehouseId: newWarehouseId,
        itemId: newItemId,
      );
      final oldBalanceBefore =
          (await repositories.parties.getById(oldCustomerId))!.iqdBalance;
      final newBalanceBefore =
          (await repositories.parties.getById(newCustomerId))!.usdBalance;
      final lineId = EntityId('phase3-sale-replace-line');
      final original = _sale(
        id: 'phase3-sale-replace',
        documentNumber: 104,
        customerId: oldCustomerId,
        warehouseId: oldWarehouseId,
        currency: AppCurrency.iqd,
        received: 50,
        lines: [
          _line(
            id: lineId.value,
            itemId: oldItemId,
            warehouseId: oldWarehouseId,
            quantity: 2,
            unitPrice: 100,
            currency: AppCurrency.iqd,
          ),
        ],
      );
      await repositories.sales.createInvoice(original);
      final replacement = _sale(
        id: original.id.value,
        documentNumber: 105,
        customerId: newCustomerId,
        warehouseId: newWarehouseId,
        currency: AppCurrency.usd,
        received: 5,
        lines: [
          _line(
            id: lineId.value,
            itemId: newItemId,
            warehouseId: newWarehouseId,
            quantity: 3,
            unitPrice: 10,
            currency: AppCurrency.usd,
          ),
        ],
      );

      final saved = await repositories.sales.replaceInvoice(replacement);

      expect(saved.id, original.id);
      expect(saved.lines.single.id, lineId);
      expect(
        await _stock(
          repositories,
          warehouseId: oldWarehouseId,
          itemId: oldItemId,
        ),
        oldStockBefore,
      );
      expect(
        await _stock(
          repositories,
          warehouseId: newWarehouseId,
          itemId: newItemId,
        ),
        newStockBefore - 3,
      );
      expect(
        (await repositories.parties.getById(oldCustomerId))!.iqdBalance,
        oldBalanceBefore,
      );
      expect(
        (await repositories.parties.getById(newCustomerId))!.usdBalance,
        newBalanceBefore + Money.fromMajor(25, AppCurrency.usd),
      );
      expect(await repositories.sales.nextDocumentNumber(), 106);

      for (final reservedNumber in [104, 105]) {
        await expectLater(
          repositories.sales.createInvoice(
            _sale(
              id: 'phase3-sale-reserved-$reservedNumber',
              documentNumber: reservedNumber,
              customerId: oldCustomerId,
              warehouseId: oldWarehouseId,
              currency: AppCurrency.iqd,
              lines: [
                _line(
                  id: 'phase3-sale-reserved-line-$reservedNumber',
                  itemId: oldItemId,
                  warehouseId: oldWarehouseId,
                  quantity: 1,
                  unitPrice: 1,
                  currency: AppCurrency.iqd,
                ),
              ],
            ),
          ),
          throwsStateError,
        );
      }
      expect(await repositories.sales.nextDocumentNumber(), 106);
    });

    test('generic delete reverses projections without releasing the number',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      final invoice = _sale(
        id: 'phase3-sale-delete',
        documentNumber: 104,
        customerId: customerId,
        warehouseId: warehouseId,
        currency: AppCurrency.iqd,
        received: 10,
        lines: [
          _line(
            id: 'phase3-sale-delete-line',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: 4,
            unitPrice: 10,
            currency: AppCurrency.iqd,
          ),
        ],
      );
      await repositories.sales.createInvoice(invoice);

      await repositories.sales.delete(invoice.id);

      expect(await repositories.sales.getById(invoice.id), isNull);
      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore,
      );
      expect(await repositories.sales.nextDocumentNumber(), 105);
      await expectLater(
        repositories.sales.createInvoice(
          _sale(
            id: 'phase3-sale-reuse',
            documentNumber: 104,
            customerId: customerId,
            warehouseId: warehouseId,
            currency: AppCurrency.iqd,
            lines: [
              _line(
                id: 'phase3-sale-reuse-line',
                itemId: itemId,
                warehouseId: warehouseId,
                quantity: 1,
                unitPrice: 1,
                currency: AppCurrency.iqd,
              ),
            ],
          ),
        ),
        throwsStateError,
      );
      expect(await repositories.sales.nextDocumentNumber(), 105);
    });

    test('repeated stock lines aggregate before insufficient-stock failure',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      final invoice = _sale(
        id: 'phase3-sale-aggregate',
        documentNumber: 104,
        customerId: customerId,
        warehouseId: warehouseId,
        currency: AppCurrency.iqd,
        lines: [
          _line(
            id: 'phase3-sale-aggregate-line-1',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: 60,
            unitPrice: 1,
            currency: AppCurrency.iqd,
          ),
          _line(
            id: 'phase3-sale-aggregate-line-2',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: 61,
            unitPrice: 1,
            currency: AppCurrency.iqd,
          ),
        ],
      );

      await expectLater(
        repositories.sales.createInvoice(invoice),
        throwsStateError,
      );

      expect(await repositories.sales.getById(invoice.id), isNull);
      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore,
      );
      expect(await repositories.sales.nextDocumentNumber(), 104);
    });

    test('insufficient-stock failure is fully atomic and reserves nothing',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      final invoice = _sale(
        id: 'phase3-sale-insufficient',
        documentNumber: 104,
        customerId: customerId,
        warehouseId: warehouseId,
        currency: AppCurrency.iqd,
        lines: [
          _line(
            id: 'phase3-sale-insufficient-line',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: stockBefore + 1,
            unitPrice: 1,
            currency: AppCurrency.iqd,
          ),
        ],
      );

      await expectLater(
        repositories.sales.createInvoice(invoice),
        throwsStateError,
      );

      expect(await repositories.sales.getById(invoice.id), isNull);
      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore,
      );
      expect(await repositories.sales.nextDocumentNumber(), 104);
    });

    test('concurrent creates for the same document and stock commit once',
        () async {
      final repositories = AppRepositories.demo();
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final balanceBefore = (await repositories.parties.getById(customerId))!
          .iqdBalance;
      SalesInvoice candidate(String suffix) => _sale(
            id: 'phase3-sale-concurrent-$suffix',
            documentNumber: 104,
            customerId: customerId,
            warehouseId: warehouseId,
            currency: AppCurrency.iqd,
            lines: [
              _line(
                id: 'phase3-sale-concurrent-line-$suffix',
                itemId: itemId,
                warehouseId: warehouseId,
                quantity: 80,
                unitPrice: 1,
                currency: AppCurrency.iqd,
              ),
            ],
          );

      final results = await Future.wait<Object>([
        _attemptCreate(repositories.sales, candidate('a')),
        _attemptCreate(repositories.sales, candidate('b')),
      ]);

      expect(results.whereType<SalesInvoice>(), hasLength(1));
      expect(results.whereType<StateError>(), hasLength(1));
      expect(
        (await repositories.sales.getAll())
            .where((invoice) => invoice.documentNumber == 104),
        hasLength(1),
      );
      expect(
        await _stock(
          repositories,
          warehouseId: warehouseId,
          itemId: itemId,
        ),
        stockBefore - 80,
      );
      expect(
        (await repositories.parties.getById(customerId))!.iqdBalance,
        balanceBefore + Money.fromMajor(80, AppCurrency.iqd),
      );
      expect(await repositories.sales.nextDocumentNumber(), 105);
    });

    test('allow-insufficient policy exposes a negative StockQuantity',
        () async {
      final repositories = AppRepositories.demo();
      final policies =
          await repositories.businessSettings.loadBusinessPolicies();
      await repositories.businessSettings.saveBusinessPolicies(
        BusinessPolicySettings(
          defaultExchangeRate: policies.defaultExchangeRate,
          allowSaleWithInsufficientStock: true,
          defaultCustomerDebtLimit: policies.defaultCustomerDebtLimit,
          defaultDebtDueDays: policies.defaultDebtDueDays,
          overdueDebtAlertsEnabled: policies.overdueDebtAlertsEnabled,
        ),
      );
      final warehouseId = EntityId('warehouse-001');
      final itemId = EntityId('item-003');
      final customerId = EntityId('party-001');
      final stockBefore = await _stock(
        repositories,
        warehouseId: warehouseId,
        itemId: itemId,
      );
      final invoice = _sale(
        id: 'phase3-sale-negative-stock',
        documentNumber: 104,
        customerId: customerId,
        warehouseId: warehouseId,
        currency: AppCurrency.iqd,
        lines: [
          _line(
            id: 'phase3-sale-negative-stock-line',
            itemId: itemId,
            warehouseId: warehouseId,
            quantity: stockBefore + 5,
            unitPrice: 1,
            currency: AppCurrency.iqd,
          ),
        ],
      );

      await repositories.sales.createInvoice(invoice);

      final balance = (await repositories.warehouses.getInventory(warehouseId))
          .singleWhere((entry) => entry.itemId == itemId);
      expect(balance.quantity, isA<StockQuantity>());
      expect(balance.quantity.value, -5);
    });
  });
}

Future<Object> _attemptCreate(
  SalesRepository repository,
  SalesInvoice invoice,
) async {
  try {
    return await repository.createInvoice(invoice);
  } catch (error) {
    return error;
  }
}

Future<int> _stock(
  AppRepositories repositories, {
  required EntityId warehouseId,
  required EntityId itemId,
}) async {
  final balances = await repositories.warehouses.getInventory(warehouseId);
  for (final balance in balances) {
    if (balance.itemId == itemId) return balance.quantity.value;
  }
  return 0;
}

SalesInvoice _sale({
  required String id,
  required int documentNumber,
  required EntityId customerId,
  required EntityId warehouseId,
  required AppCurrency currency,
  required List<SalesInvoiceLine> lines,
  num received = 0,
}) {
  return SalesInvoice(
    id: EntityId(id),
    documentNumber: documentNumber,
    date: BusinessDate(2026, 8, 10),
    minuteOfDay: 10 * 60,
    customerId: customerId,
    defaultWarehouseId: warehouseId,
    currency: currency,
    exchangeRate: ExchangeRate.parse('1310'),
    settlementKind: SalesSettlementKind.credit,
    lines: lines,
    invoiceDiscount: Money.zero(currency),
    received: Money.fromMajor(received, currency),
  );
}

SalesInvoice _copySale(SalesInvoice source, {required String notes}) {
  return SalesInvoice(
    id: source.id,
    documentNumber: source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    customerId: source.customerId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    settlementKind: source.settlementKind,
    lines: source.lines,
    invoiceDiscount: source.invoiceDiscount,
    received: source.received,
    customerNameSnapshot: source.customerNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    driverName: source.driverName,
    notes: notes,
  );
}

SalesInvoiceLine _line({
  required String id,
  required EntityId itemId,
  required EntityId warehouseId,
  required int quantity,
  required num unitPrice,
  required AppCurrency currency,
}) {
  return SalesInvoiceLine(
    id: EntityId(id),
    itemId: itemId,
    warehouseId: warehouseId,
    quantity: WholeQuantity(quantity),
    unitPrice: Money.fromMajor(unitPrice, currency),
    discountPerUnit: Money.zero(currency),
  );
}
