import 'package:erp/core/app_state/app_data_profile.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales_returns/domain/sales_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sales return restates stock, cost, Party and Cashbox atomically',
      () async {
    final repositories = AppRepositories.forProfile(
      AppDataProfile.originalDemo,
    );
    final source = (await repositories.sales.getById(
      EntityId('sales-invoice-103'),
    ))!;
    final sourceLine = source.lines.first;
    final partyBefore = (await repositories.parties.getById(
      source.customerId,
    ))!;
    final quantityBefore = await _quantity(
      repositories,
      warehouseId: sourceLine.warehouseId,
      itemId: sourceLine.itemId,
    );
    final vouchersBefore = await repositories.cashbox.getAll();

    final created = await repositories.salesReturns.createReturn(
      _request(
        source,
        sourceLine: sourceLine,
        quantity: 1,
        refund: Money.fromMajor(20000, source.currency),
      ),
    );

    expect(
      await _quantity(
        repositories,
        warehouseId: sourceLine.warehouseId,
        itemId: sourceLine.itemId,
      ),
      quantityBefore + 1,
    );
    expect(
      (await repositories.parties.getById(source.customerId))!.iqdBalance,
      partyBefore.iqdBalance - created.creditedToCustomer,
    );
    final createdPosting = (await repositories.cashbox.getAll()).singleWhere(
      (voucher) =>
          voucher.source?.kind == CashboxVoucherSourceKind.salesReturn &&
          voucher.source?.sourceId == created.id,
    );
    expect(createdPosting.type, CashboxVoucherType.payment);
    expect(createdPosting.iqdAmount, created.refundedAtReturn);
    final createdCost = await repositories.inventoryCosts
        .getSalesReturnLineCost(created.lines.single.id);
    expect(createdCost, isNotNull);
    expect(createdCost!.restoredCostIqd, isNotNull);

    final replaced = await repositories.salesReturns.replaceReturn(
      created.id,
      _request(
        source,
        sourceLine: sourceLine,
        quantity: 2,
        refund: Money.fromMajor(30000, source.currency),
      ),
    );
    expect(replaced.id, created.id);
    expect(replaced.documentNumber, created.documentNumber);
    expect(
      await _quantity(
        repositories,
        warehouseId: sourceLine.warehouseId,
        itemId: sourceLine.itemId,
      ),
      quantityBefore + 2,
    );
    expect(
      (await repositories.cashbox.getAll()),
      hasLength(vouchersBefore.length + 1),
    );
    expect(
      (await repositories.parties.getById(source.customerId))!.iqdBalance,
      partyBefore.iqdBalance - replaced.creditedToCustomer,
    );

    await repositories.salesReturns.deleteReturnPermanently(replaced.id);
    expect(await repositories.salesReturns.getAll(), isEmpty);
    expect(
      await _quantity(
        repositories,
        warehouseId: sourceLine.warehouseId,
        itemId: sourceLine.itemId,
      ),
      quantityBefore,
    );
    expect(await repositories.cashbox.getAll(), hasLength(vouchersBefore.length));
    expect(
      (await repositories.parties.getById(source.customerId))!.iqdBalance,
      partyBefore.iqdBalance,
    );
    expect(
      await repositories.inventoryCosts
          .getSalesReturnLineCost(replaced.lines.single.id),
      isNull,
    );
    expect(await repositories.salesReturns.nextDocumentNumber(), 2);
  });

  test('paid reduced installment remains exact across later return changes',
      () async {
    final repositories = AppRepositories.forProfile(
      AppDataProfile.originalDemo,
    );
    final source = (await repositories.sales.getById(
      EntityId('sales-invoice-102'),
    ))!;
    final sourceLine = source.lines.last;

    final first = await repositories.salesReturns.createReturn(
      _request(
        source,
        sourceLine: sourceLine,
        quantity: 1,
        refund: Money.zero(source.currency),
      ),
    );
    var plan = (await repositories.installments.getBySalesInvoiceId(
      source.id,
    ))!;
    final reduced = plan.entries.singleWhere((entry) => entry.number == 4);
    expect(reduced.amount, Money.fromMajor(50, AppCurrency.usd));

    plan = await repositories.installments.settleEntry(
      entryId: reduced.id,
      paidAt: AuditTimestamp(DateTime(2026, 8, 15, 10)),
    );
    expect(plan.paid, Money.fromMajor(50, AppCurrency.usd));

    var second = await repositories.salesReturns.createReturn(
      _request(
        source,
        sourceLine: sourceLine,
        quantity: 1,
        refund: Money.zero(source.currency),
      ),
    );
    plan = (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(plan.paid, Money.fromMajor(50, AppCurrency.usd));
    expect(plan.remaining, Money.fromMajor(550, AppCurrency.usd));
    expect(
      plan.entries.singleWhere((entry) => entry.id == reduced.id).amount,
      Money.fromMajor(50, AppCurrency.usd),
    );

    second = await repositories.salesReturns.replaceReturn(
      second.id,
      _request(
        source,
        sourceLine: sourceLine,
        quantity: 1,
        refund: Money.fromMajor(50, source.currency),
      ),
    );
    plan = (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(plan.paid, Money.fromMajor(50, AppCurrency.usd));
    expect(plan.remaining, Money.fromMajor(600, AppCurrency.usd));
    expect(
      plan.entries.singleWhere((entry) => entry.id == reduced.id).amount,
      Money.fromMajor(50, AppCurrency.usd),
    );

    await repositories.salesReturns.deleteReturnPermanently(second.id);
    plan = (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(plan.paid, Money.fromMajor(50, AppCurrency.usd));
    expect(plan.remaining, Money.fromMajor(750, AppCurrency.usd));

    await repositories.salesReturns.deleteReturnPermanently(first.id);
    plan = (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(plan.paid, Money.fromMajor(50, AppCurrency.usd));
    expect(plan.remaining, Money.fromMajor(950, AppCurrency.usd));
    expect(
      (await repositories.sales.getById(source.id))!.installmentReceived,
      Money.fromMajor(50, AppCurrency.usd),
    );
  });

  test('harmless Sale edits preserve return-restated pending and empty plans',
      () async {
    final repositories = AppRepositories.forProfile(
      AppDataProfile.originalDemo,
    );
    final source = (await repositories.sales.getById(
      EntityId('sales-invoice-102'),
    ))!;
    final firstLine = source.lines.first;
    final secondLine = source.lines.last;

    await repositories.salesReturns.createReturn(
      _request(
        source,
        sourceLine: secondLine,
        quantity: 1,
        refund: Money.zero(source.currency),
      ),
    );
    final reduced = (await repositories.installments.getBySalesInvoiceId(
      source.id,
    ))!;
    final reducedEntries = [
      for (final entry in reduced.entries)
        (entry.id, entry.number, entry.dueDate, entry.amount),
    ];
    expect(reduced.hasPaidEntries, isFalse);
    expect(reduced.remaining, Money.fromMajor(800, source.currency));

    var edited = await repositories.sales.replaceInvoice(
      source.copyWith(notes: 'ملاحظة بعد مرتجع جزئي'),
    );
    final afterPendingEdit =
        (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(afterPendingEdit.id, reduced.id);
    expect(afterPendingEdit.remaining, reduced.remaining);
    expect(
      [
        for (final entry in afterPendingEdit.entries)
          (entry.id, entry.number, entry.dueDate, entry.amount),
      ],
      reducedEntries,
    );

    await repositories.salesReturns.createReturn(
      SalesReturnSaveRequest(
        originalSalesInvoiceId: source.id,
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 12 * 60,
        lines: [
          SalesReturnLineRequest(
            sourceSalesLineId: firstLine.id,
            quantity: firstLine.quantity,
          ),
          SalesReturnLineRequest(
            sourceSalesLineId: secondLine.id,
            quantity: WholeQuantity(1),
          ),
        ],
        refundedAtReturn: Money.zero(source.currency),
        notes: 'إكمال رد القائمة',
      ),
    );
    final empty = (await repositories.installments.getBySalesInvoiceId(
      source.id,
    ))!;
    expect(empty.entries, isEmpty);
    expect(empty.remaining, Money.zero(source.currency));

    edited = await repositories.sales.replaceInvoice(
      edited.copyWith(driverName: 'سائق بعد الرد الكامل'),
    );
    expect(edited.driverName, 'سائق بعد الرد الكامل');
    final afterEmptyEdit =
        (await repositories.installments.getBySalesInvoiceId(source.id))!;
    expect(afterEmptyEdit.id, empty.id);
    expect(afterEmptyEdit.entries, isEmpty);
    expect(afterEmptyEdit.remaining, Money.zero(source.currency));
  });
}

SalesReturnSaveRequest _request(
  SalesInvoice source, {
  required SalesInvoiceLine sourceLine,
  required int quantity,
  required Money refund,
}) {
  return SalesReturnSaveRequest(
    originalSalesInvoiceId: source.id,
    date: BusinessDate(2026, 8, 14),
    minuteOfDay: 12 * 60,
    lines: [
      SalesReturnLineRequest(
        sourceSalesLineId: sourceLine.id,
        quantity: WholeQuantity(quantity),
      ),
    ],
    refundedAtReturn: refund,
    notes: 'اختبار آثار المرتجع',
  );
}

Future<int> _quantity(
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
