import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/cashbox/domain/cashbox_repository.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded Cashbox projections and generated routing are coherent',
      () async {
    final repositories = AppRepositories.demo();
    final partyOne = (await repositories.parties.getById(
      EntityId('party-001'),
    ))!;
    final partyThree = (await repositories.parties.getById(
      EntityId('party-003'),
    ))!;
    final partyTwo = (await repositories.parties.getById(
      EntityId('party-002'),
    ))!;
    final partyOneAccount = await repositories.cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 4),
    );
    final partyThreeAccount = await repositories.cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 6),
    );
    final partyTwoAccount = await repositories.cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 5),
    );
    final generated = (await repositories.cashbox.getAll())
        .where((voucher) => voucher.isSystemGenerated)
        .toList();

    expect(partyOne.iqdBalance, partyOneAccount.iqd);
    expect(partyTwo.iqdBalance, partyTwoAccount.iqd);
    expect(partyTwo.usdBalance, partyTwoAccount.usd);
    expect(partyThree.usdBalance, partyThreeAccount.usd);
    expect(generated, hasLength(4));
    expect(
      generated.every(
        (voucher) =>
            voucher.subaccountEntityId ==
            EntityId.demo('cashbox-subaccount', 1),
      ),
      isTrue,
    );
    expect(
      generated
          .where(
            (voucher) =>
                voucher.source?.kind ==
                CashboxVoucherSourceKind.purchaseInvoice,
          )
          .any(
            (voucher) =>
                voucher.subaccountEntityId ==
                EntityId.demo('cashbox-subaccount', 4),
          ),
      isFalse,
    );
    final purchasePostings = generated
        .where(
          (voucher) =>
              voucher.source?.kind ==
              CashboxVoucherSourceKind.purchaseInvoice,
        )
        .toList();
    expect(
      purchasePostings.singleWhere(
        (voucher) =>
            voucher.source?.sourceId == EntityId('purchase-invoice-102'),
      ).type,
      CashboxVoucherType.payment,
    );
    expect(
      purchasePostings.singleWhere(
        (voucher) =>
            voucher.source?.sourceId == EntityId('purchase-invoice-103'),
      ).type,
      CashboxVoucherType.receipt,
    );
  });

  test('manual party voucher create, move, and delete is atomic', () async {
    final repositories = AppRepositories.demo();
    final numbered =
        repositories.cashbox as CashboxIssuedNumberRepository;
    final partyOneId = EntityId('party-001');
    final partyTwoId = EntityId('party-002');
    final partyOneBefore = (await repositories.parties.getById(partyOneId))!;
    final partyTwoBefore = (await repositories.parties.getById(partyTwoId))!;
    final number = await numbered.nextVoucherNumber();
    final voucher = _voucher(
      id: 'phase4-manual-party',
      number: number,
      subaccountNumber: 4,
      type: CashboxVoucherType.receipt,
      amountIqd: 100,
    );

    await repositories.cashbox.save(voucher);
    expect(
      (await repositories.parties.getById(partyOneId))!.iqdBalance,
      partyOneBefore.iqdBalance - Money.fromMajor(100, AppCurrency.iqd),
    );

    await repositories.cashbox.save(
      _voucher(
        id: voucher.id,
        number: number,
        subaccountNumber: 5,
        type: CashboxVoucherType.payment,
        amountIqd: 40,
      ),
    );
    expect(
      (await repositories.parties.getById(partyOneId))!.iqdBalance,
      partyOneBefore.iqdBalance,
    );
    expect(
      (await repositories.parties.getById(partyTwoId))!.iqdBalance,
      partyTwoBefore.iqdBalance + Money.fromMajor(40, AppCurrency.iqd),
    );

    await repositories.cashbox.delete(voucher.entityId);
    expect(
      (await repositories.parties.getById(partyTwoId))!.iqdBalance,
      partyTwoBefore.iqdBalance,
    );
    expect(await numbered.nextVoucherNumber(), number + 1);
    await expectLater(
      repositories.cashbox.save(
        _voucher(
          id: 'phase4-reused-number',
          number: number,
          subaccountNumber: 4,
          type: CashboxVoucherType.receipt,
          amountIqd: 1,
        ),
      ),
      throwsStateError,
    );
  });

  test('generated Sales posting keeps source identity and is read-only',
      () async {
    final repositories = AppRepositories.demo();
    final seeded = (await repositories.sales.getAll()).firstWhere(
      (invoice) => invoice.id == EntityId('sales-invoice-102'),
    );
    final customerBefore = (await repositories.parties.getById(
      seeded.customerId,
    ))!;
    final originalPosting = _sourcePosting(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      seeded.id,
    );

    await repositories.sales.replaceInvoice(
      _copySale(
        seeded,
        received: Money.fromMajor(300, AppCurrency.usd),
      ),
    );
    final replacedPosting = _sourcePosting(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      seeded.id,
    );
    expect(replacedPosting.entityId, originalPosting.entityId);
    expect(replacedPosting.number, originalPosting.number);
    expect(replacedPosting.usdAmount.majorUnits, 300);
    expect(
      (await repositories.parties.getById(seeded.customerId))!.usdBalance,
      customerBefore.usdBalance - Money.fromMajor(50, AppCurrency.usd),
    );
    expect(
      (await repositories.cashbox.canDelete(replacedPosting.entityId))
          .isAllowed,
      isFalse,
    );
    await expectLater(
      repositories.cashbox.save(
        replacedPosting.copyWith(notes: 'manual edit'),
      ),
      throwsStateError,
    );
    await expectLater(
      repositories.cashbox.delete(replacedPosting.entityId),
      throwsStateError,
    );

    await repositories.sales.replaceInvoice(
      _copySale(
        seeded,
        received: Money.zero(AppCurrency.usd),
      ),
    );
    expect(
      (await repositories.cashbox.getAll()).where(
        (voucher) =>
            voucher.source?.kind == CashboxVoucherSourceKind.salesInvoice &&
            voucher.source?.sourceId == seeded.id,
      ),
      isEmpty,
    );
    await repositories.sales.replaceInvoice(
      _copySale(
        seeded,
        received: Money.fromMajor(350, AppCurrency.usd),
      ),
    );
    final recreatedPosting = _sourcePosting(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      seeded.id,
    );
    expect(recreatedPosting.entityId, originalPosting.entityId);
    expect(recreatedPosting.number, 11);
    await repositories.sales.deleteInvoicePermanently(seeded.id);
    expect(
      (await repositories.cashbox.getAll()).where(
        (voucher) => voucher.source?.sourceId == seeded.id,
      ),
      isEmpty,
    );
    expect(
      await (repositories.cashbox as CashboxIssuedNumberRepository)
          .nextVoucherNumber(),
      12,
    );
  });

  test('failed invoice replacement leaves posting and Party unchanged',
      () async {
    final repositories = AppRepositories.demo();
    final seeded = (await repositories.sales.getAll()).firstWhere(
      (invoice) => invoice.id == EntityId('sales-invoice-102'),
    );
    final postingBefore = _sourcePosting(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      seeded.id,
    );
    final partyBefore = (await repositories.parties.getById(
      seeded.customerId,
    ))!;
    final firstLine = seeded.lines.first;
    final invalidLine = SalesInvoiceLine(
      id: firstLine.id,
      itemId: firstLine.itemId,
      warehouseId: firstLine.warehouseId,
      quantity: WholeQuantity(1000000),
      unitPrice: firstLine.unitPrice,
      discountPerUnit: firstLine.discountPerUnit,
      itemCodeSnapshot: firstLine.itemCodeSnapshot,
      itemNameSnapshot: firstLine.itemNameSnapshot,
      warehouseNameSnapshot: firstLine.warehouseNameSnapshot,
    );

    await expectLater(
      repositories.sales.replaceInvoice(
        _copySale(
          seeded,
          received: Money.fromMajor(300, AppCurrency.usd),
          lines: [invalidLine, ...seeded.lines.skip(1)],
        ),
      ),
      throwsStateError,
    );
    final postingAfter = _sourcePosting(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      seeded.id,
    );
    expect(postingAfter.entityId, postingBefore.entityId);
    expect(postingAfter.number, postingBefore.number);
    expect(postingAfter.usdAmount, postingBefore.usdAmount);
    expect(
      (await repositories.parties.getById(seeded.customerId))!.usdBalance,
      partyBefore.usdBalance,
    );
    expect(
      (await repositories.sales.getById(seeded.id))!.received,
      seeded.received,
    );
  });
}

CashboxVoucher _voucher({
  required String id,
  required int number,
  required int subaccountNumber,
  required CashboxVoucherType type,
  required num amountIqd,
}) {
  return CashboxVoucher(
    id: id,
    number: number,
    createdAt: DateTime(2026, 7, 28, 9),
    type: type,
    mainAccountId: EntityId.demo('cashbox-main-account', 4).value,
    mainAccountLabel: 'الأطراف',
    subaccountId:
        EntityId.demo('cashbox-subaccount', subaccountNumber).value,
    subaccountLabel: '',
    exchangeRate: 1310,
    amountIqd: amountIqd,
    amountUsd: 0,
    balanceBeforeIqd: 0,
    balanceAfterIqd: 0,
    balanceBeforeUsd: 0,
    balanceAfterUsd: 0,
    notes: '',
  );
}

CashboxVoucher _sourcePosting(
  Iterable<CashboxVoucher> vouchers,
  CashboxVoucherSourceKind kind,
  EntityId sourceId,
) {
  return vouchers.singleWhere(
    (voucher) =>
        voucher.source?.kind == kind &&
        voucher.source?.sourceId == sourceId,
  );
}

SalesInvoice _copySale(
  SalesInvoice source, {
  required Money received,
  Iterable<SalesInvoiceLine>? lines,
}) {
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
    lines: lines ?? source.lines,
    invoiceDiscount: source.invoiceDiscount,
    received: received,
    customerNameSnapshot: source.customerNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    driverName: source.driverName,
    notes: source.notes,
  );
}
