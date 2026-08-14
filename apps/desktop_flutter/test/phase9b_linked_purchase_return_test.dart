import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/purchases/data/demo_purchase_mutation_effects.dart';
import 'package:erp/features/purchases/data/demo_purchase_repository.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/purchases/domain/purchase_return_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo return is linked to the added source line and refunds its net',
      () {
    final invoices = demoPurchaseInvoices();
    final source = invoices.singleWhere(
      (invoice) => invoice.id == EntityId('purchase-invoice-101'),
    );
    final returned = invoices.singleWhere(
      (invoice) => invoice.id == EntityId('purchase-invoice-103'),
    );
    final sourceLine = source.lines.singleWhere(
      (line) => line.id == EntityId('purchase-line-1013'),
    );

    expect(returned.originalPurchaseInvoiceId, source.id);
    expect(returned.lines.single.originalPurchaseLineId, sourceLine.id);
    expect(returned.supplierId, source.supplierId);
    expect(returned.lines.single.netTotal.majorUnits, 90000);
    expect(returned.total.majorUnits, 90000);
    expect(returned.expenses.isZero, isTrue);
  });

  test('partial linked returns allocate source discounts without drift',
      () async {
    final source = _sourceInvoice();
    final repository = _repository(source);
    final first = _returnInvoice(
      id: 'return-1',
      documentNumber: 2,
      source: source,
      quantity: 4,
      lineDiscount: 4,
      invoiceDiscount: 4,
    );
    final second = _returnInvoice(
      id: 'return-2',
      documentNumber: 3,
      source: source,
      quantity: 6,
      lineDiscount: 6,
      invoiceDiscount: 5,
    );

    await repository.createInvoice(first);
    await repository.createInvoice(second);

    expect(first.total.majorUnits, 392);
    expect(second.total.majorUnits, 589);
    expect(first.total + second.total, Money.fromMajor(981, AppCurrency.iqd));
    expect(
      source.subtotal - source.invoiceDiscount,
      Money.fromMajor(981, AppCurrency.iqd),
      reason: 'source expenses are intentionally non-refundable',
    );
  });

  test('half-minor line rounding stays compatible with invoice discount',
      () async {
    final source = _halfMinorSourceInvoice();
    final sourceLine = source.lines.single;
    final invoiceDiscount = PurchaseReturnPolicy.invoiceDiscount(
      source: source,
      totalReturnedQuantities: {sourceLine.id: 1},
      discountAlreadyReturned: Money.zero(source.currency),
    );

    expect(invoiceDiscount, Money.zero(source.currency));
    final returned = PurchaseInvoice(
      id: EntityId('half-minor-return'),
      documentNumber: 2,
      date: BusinessDate(2026, 8, 2),
      minuteOfDay: 10 * 60,
      supplierId: source.supplierId,
      defaultWarehouseId: source.defaultWarehouseId,
      currency: source.currency,
      exchangeRate: source.exchangeRate,
      purchaseKind: PurchaseTransactionKind.returnPurchase,
      settlementKind: PurchaseSettlementKind.credit,
      originalPurchaseInvoiceId: source.id,
      lines: [
        PurchaseInvoiceLine(
          id: EntityId('half-minor-return-line'),
          itemId: sourceLine.itemId,
          warehouseId: sourceLine.warehouseId,
          quantity: WholeQuantity(1),
          containerQuantity: WholeQuantity(0),
          purchasePrice: sourceLine.purchasePrice,
          lineDiscount: Money.fromMinorUnits(1, source.currency),
          salePrice: sourceLine.salePrice,
          originalPurchaseLineId: sourceLine.id,
        ),
      ],
      expenses: Money.zero(source.currency),
      invoiceDiscount: invoiceDiscount,
      paid: Money.zero(source.currency),
    );

    final saved = await _repository(source).createInvoice(returned);
    expect(saved.total, Money.zero(source.currency));
  });

  test('only the latest issued linked return can change', () async {
    final source = _sourceInvoice();
    final repository = _repository(source);
    final first = _returnInvoice(
      id: 'return-1',
      documentNumber: 2,
      source: source,
      quantity: 4,
      lineDiscount: 4,
      invoiceDiscount: 4,
    );
    final second = _returnInvoice(
      id: 'return-2',
      documentNumber: 3,
      source: source,
      quantity: 6,
      lineDiscount: 6,
      invoiceDiscount: 5,
    );
    await repository.createInvoice(first);
    await repository.createInvoice(second);

    expect((await repository.canDelete(first.id)).isAllowed, isFalse);
    await expectLater(repository.replaceInvoice(first), throwsStateError);
    await expectLater(
      repository.deleteInvoicePermanently(first.id),
      throwsStateError,
    );

    expect(await repository.getAll(), hasLength(3));
    expect((await repository.getById(first.id))!.total, first.total);
    await repository.deleteInvoicePermanently(second.id);
    expect((await repository.canDelete(first.id)).isAllowed, isTrue);
  });

  test('repository rejects missing links, source-value changes, and overreturn',
      () async {
    final source = _sourceInvoice();
    final repository = _repository(source);

    await expectLater(
      repository.createInvoice(
        _returnInvoice(
          id: 'unlinked',
          documentNumber: 2,
          source: source,
          quantity: 1,
          lineDiscount: 1,
          invoiceDiscount: 1,
          linked: false,
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      repository.createInvoice(
        _returnInvoice(
          id: 'changed-price',
          documentNumber: 2,
          source: source,
          quantity: 4,
          lineDiscount: 4,
          invoiceDiscount: 4,
          purchasePrice: 101,
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      repository.createInvoice(
        _returnInvoice(
          id: 'skipped-number',
          documentNumber: 3,
          source: source,
          quantity: 1,
          lineDiscount: 1,
          invoiceDiscount: 1,
        ),
      ),
      throwsStateError,
    );

    await repository.createInvoice(
      _returnInvoice(
        id: 'partial',
        documentNumber: 2,
        source: source,
        quantity: 4,
        lineDiscount: 4,
        invoiceDiscount: 4,
      ),
    );
    await expectLater(
      repository.createInvoice(
        _returnInvoice(
          id: 'overreturn',
          documentNumber: 3,
          source: source,
          quantity: 7,
          lineDiscount: 7,
          invoiceDiscount: 6,
        ),
      ),
      throwsStateError,
    );
  });

  test('saved normal purchase cannot be converted into a return', () async {
    final source = _sourceInvoice();
    final repository = _repository(source);
    final converted = _returnInvoice(
      id: source.id.value,
      documentNumber: source.documentNumber,
      source: source,
      quantity: 1,
      lineDiscount: 1,
      invoiceDiscount: 1,
    );

    await expectLater(
      repository.replaceInvoice(converted),
      throwsStateError,
    );
    expect((await repository.getById(source.id))!.isReturn, isFalse);
  });

  test('newer purchase return cannot be backdated before an older return',
      () async {
    final source = _sourceInvoice();
    final repository = _repository(source);
    await repository.createInvoice(
      _returnInvoice(
        id: 'dated-return-1',
        documentNumber: 2,
        source: source,
        quantity: 4,
        lineDiscount: 4,
        invoiceDiscount: 4,
        date: BusinessDate(2026, 8, 3),
      ),
    );

    await expectLater(
      repository.createInvoice(
        _returnInvoice(
          id: 'dated-return-2',
          documentNumber: 3,
          source: source,
          quantity: 1,
          lineDiscount: 1,
          invoiceDiscount: 1,
          date: BusinessDate(2026, 8, 2),
        ),
      ),
      throwsStateError,
    );
  });

  test('linked source terms are guarded and deleting a return frees quantity',
      () async {
    final source = _sourceInvoice();
    final repository = _repository(source);
    final returned = _returnInvoice(
      id: 'full-return',
      documentNumber: 2,
      source: source,
      quantity: 10,
      lineDiscount: 10,
      invoiceDiscount: 9,
    );
    await repository.createInvoice(returned);

    final sourceDeleteDecision = await repository.canDelete(source.id);
    expect(sourceDeleteDecision.isAllowed, isFalse);

    await expectLater(
      repository.replaceInvoice(_copySource(source, purchasePrice: 101)),
      throwsStateError,
    );
    await expectLater(
      repository.deleteInvoicePermanently(source.id),
      throwsStateError,
    );

    final noteOnly = await repository.replaceInvoice(
      _copySource(source, notes: 'تحديث ملاحظة لا يغير شروط المرتجع'),
    );
    expect(noteOnly.notes, isNotEmpty);

    await repository.deleteInvoicePermanently(returned.id);
    final replacement = await repository.replaceInvoice(
      _copySource(noteOnly, purchasePrice: 101),
    );
    expect(replacement.lines.single.purchasePrice.majorUnits, 101);
    final returnedAgain = await repository.createInvoice(
      _returnInvoice(
        id: 'return-after-delete',
        documentNumber: 3,
        source: replacement,
        quantity: 10,
        lineDiscount: 10,
        invoiceDiscount: 9,
        purchasePrice: 101,
      ),
    );
    expect(returnedAgain.lines.single.quantity.value, 10);
  });
}

DemoPurchaseRepository _repository(PurchaseInvoice source) {
  return DemoPurchaseRepository(
    initialValues: [source],
    partyExists: (_) async => true,
    itemExists: (_) async => true,
    warehouseExists: (_) async => true,
    mutationEffects: _PurchaseEffects(),
  );
}

class _PurchaseEffects implements DemoPurchaseMutationEffects {
  final _runner = DemoTransactionRunner();

  @override
  Future<PurchaseInvoice> applyPurchase({
    required PurchaseInvoice candidate,
    required Future<PurchaseInvoice?> Function() preflightAndLoadPrevious,
    required void Function(PurchaseInvoice normalized) commit,
  }) {
    return _runner.run(() async {
      await preflightAndLoadPrevious();
      commit(candidate);
      return candidate;
    });
  }

  @override
  Future<void> deletePurchase({
    required EntityId id,
    required Future<PurchaseInvoice> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) {
    return _runner.run(() async {
      await preflightAndLoadPrevious();
      commit();
    });
  }
}

PurchaseInvoice _sourceInvoice() {
  return PurchaseInvoice(
    id: EntityId('source-purchase'),
    documentNumber: 1,
    date: BusinessDate(2026, 8, 1),
    minuteOfDay: 9 * 60,
    supplierId: EntityId('supplier'),
    defaultWarehouseId: EntityId('warehouse'),
    currency: AppCurrency.iqd,
    exchangeRate: ExchangeRate.parse('1310'),
    purchaseKind: PurchaseTransactionKind.local,
    settlementKind: PurchaseSettlementKind.credit,
    lines: [
      PurchaseInvoiceLine(
        id: EntityId('source-line'),
        itemId: EntityId('item'),
        warehouseId: EntityId('warehouse'),
        quantity: WholeQuantity(10),
        containerQuantity: WholeQuantity(0),
        purchasePrice: Money.fromMajor(100, AppCurrency.iqd),
        lineDiscount: Money.fromMajor(10, AppCurrency.iqd),
        salePrice: Money.fromMajor(120, AppCurrency.iqd),
      ),
    ],
    expenses: Money.fromMajor(20, AppCurrency.iqd),
    invoiceDiscount: Money.fromMajor(9, AppCurrency.iqd),
    paid: Money.zero(AppCurrency.iqd),
  );
}

PurchaseInvoice _halfMinorSourceInvoice() {
  return PurchaseInvoice(
    id: EntityId('half-minor-source'),
    documentNumber: 1,
    date: BusinessDate(2026, 8, 1),
    minuteOfDay: 9 * 60,
    supplierId: EntityId('supplier'),
    defaultWarehouseId: EntityId('warehouse'),
    currency: AppCurrency.iqd,
    exchangeRate: ExchangeRate.parse('1310'),
    purchaseKind: PurchaseTransactionKind.local,
    settlementKind: PurchaseSettlementKind.credit,
    lines: [
      PurchaseInvoiceLine(
        id: EntityId('half-minor-source-line'),
        itemId: EntityId('item'),
        warehouseId: EntityId('warehouse'),
        quantity: WholeQuantity(2),
        containerQuantity: WholeQuantity(0),
        purchasePrice: Money.fromMinorUnits(1, AppCurrency.iqd),
        lineDiscount: Money.fromMinorUnits(1, AppCurrency.iqd),
        salePrice: Money.fromMinorUnits(1, AppCurrency.iqd),
      ),
    ],
    expenses: Money.zero(AppCurrency.iqd),
    invoiceDiscount: Money.fromMinorUnits(1, AppCurrency.iqd),
    paid: Money.zero(AppCurrency.iqd),
  );
}

PurchaseInvoice _returnInvoice({
  required String id,
  required int documentNumber,
  required PurchaseInvoice source,
  required int quantity,
  required num lineDiscount,
  required num invoiceDiscount,
  bool linked = true,
  num purchasePrice = 100,
  BusinessDate? date,
}) {
  return PurchaseInvoice(
    id: EntityId(id),
    documentNumber: documentNumber,
    date: date ?? BusinessDate(2026, 8, 2),
    minuteOfDay: 10 * 60,
    supplierId: source.supplierId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    purchaseKind: PurchaseTransactionKind.returnPurchase,
    settlementKind: PurchaseSettlementKind.credit,
    originalPurchaseInvoiceId: linked ? source.id : null,
    lines: [
      PurchaseInvoiceLine(
        id: EntityId('$id-line'),
        itemId: source.lines.single.itemId,
        warehouseId: source.lines.single.warehouseId,
        quantity: WholeQuantity(quantity),
        containerQuantity: WholeQuantity(0),
        purchasePrice: Money.fromMajor(purchasePrice, source.currency),
        lineDiscount: Money.fromMajor(lineDiscount, source.currency),
        salePrice: source.lines.single.salePrice,
        originalPurchaseLineId: linked ? source.lines.single.id : null,
      ),
    ],
    expenses: Money.zero(source.currency),
    invoiceDiscount: Money.fromMajor(invoiceDiscount, source.currency),
    paid: Money.zero(source.currency),
  );
}

PurchaseInvoice _copySource(
  PurchaseInvoice source, {
  num? purchasePrice,
  String? notes,
}) {
  final sourceLine = source.lines.single;
  return PurchaseInvoice(
    id: source.id,
    documentNumber: source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    supplierId: source.supplierId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    purchaseKind: source.purchaseKind,
    settlementKind: source.settlementKind,
    lines: [
      PurchaseInvoiceLine(
        id: sourceLine.id,
        itemId: sourceLine.itemId,
        warehouseId: sourceLine.warehouseId,
        quantity: sourceLine.quantity,
        containerQuantity: sourceLine.containerQuantity,
        purchasePrice: Money.fromMajor(
          purchasePrice ?? sourceLine.purchasePrice.majorUnits,
          source.currency,
        ),
        lineDiscount: sourceLine.lineDiscount,
        salePrice: sourceLine.salePrice,
      ),
    ],
    expenses: source.expenses,
    invoiceDiscount: source.invoiceDiscount,
    paid: source.paid,
    notes: notes ?? source.notes,
  );
}
