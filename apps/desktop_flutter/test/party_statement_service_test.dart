import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/cashbox/domain/cashbox_repository.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/parties/application/party_statement_service.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/sales_returns/domain/sales_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRepositories repositories;
  late PartyStatementService service;

  setUp(() {
    repositories = AppRepositories.demo();
    service = RepositoryPartyStatementService(
      parties: repositories.parties,
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: repositories.cashbox,
      salesReturns: repositories.salesReturns,
      expenses: repositories.expenses,
    );
  });

  test('combines party movements chronologically and calculates balance',
      () async {
    final result = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-001'),
        fromDate: BusinessDate(2026, 7, 25),
        toDate: BusinessDate(2026, 7, 27),
        currency: AppCurrency.iqd,
      ),
    );

    expect(result.entries, hasLength(2));
    expect(
      result.entries.map((entry) => entry.type),
      [PartyStatementEntryType.sale, PartyStatementEntryType.receipt],
    );
    expect(result.entries.first.date, DateTime(2026, 7, 25, 9, 15));
    expect(result.entries.first.debit.majorUnits, 177000);
    expect(result.entries.first.credit.majorUnits, 0);
    expect(result.openingBalance.majorUnits, 1073000);
    expect(result.entries.first.balance.majorUnits, 1250000);
    expect(result.entries.first.quantity, 10);
    expect(result.entries.first.details, contains('قائمة بيع رقم 101'));

    final receipt = result.entries.last;
    expect(receipt.date, DateTime(2026, 7, 27, 8, 30));
    expect(receipt.debit.majorUnits, 0);
    expect(receipt.credit.majorUnits, 750000);
    expect(receipt.balance.majorUnits, 500000);
    expect(receipt.quantity, isNull);
    expect(receipt.details, contains('سند قبض رقم 1'));
    expect(result.closingBalance.majorUnits, 500000);
  });

  test('filters inclusively by dates and currency', () async {
    final oneDay = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-001'),
        fromDate: BusinessDate(2026, 7, 25),
        toDate: BusinessDate(2026, 7, 25),
        currency: AppCurrency.iqd,
      ),
    );
    expect(oneDay.entries, hasLength(1));
    expect(oneDay.entries.single.type, PartyStatementEntryType.sale);

    final dollars = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-002'),
        fromDate: BusinessDate(2026, 7, 24),
        toDate: BusinessDate(2026, 7, 26),
        currency: AppCurrency.usd,
      ),
    );
    expect(dollars.entries, hasLength(1));
    expect(dollars.entries.single.type, PartyStatementEntryType.sale);
    expect(dollars.entries.single.debit.majorUnits, 1250);
    expect(dollars.entries.single.credit.majorUnits, 250);
    expect(dollars.openingBalance.majorUnits, -1000);
    expect(dollars.closingBalance.majorUnits, 0);
  });

  test('uses purchase payment as debit and invoice total as credit',
      () async {
    final result = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-012'),
        fromDate: BusinessDate(2026, 7, 26),
        toDate: BusinessDate(2026, 7, 26),
        currency: AppCurrency.usd,
      ),
    );

    expect(result.entries, hasLength(1));
    final purchase = result.entries.single;
    expect(purchase.type, PartyStatementEntryType.purchase);
    expect(purchase.debit.majorUnits, 500);
    expect(purchase.credit.majorUnits, 1500);
    expect(result.openingBalance.majorUnits, -250);
    expect(purchase.balance.majorUnits, -1250);
    expect(purchase.quantity, 5);
    expect(purchase.details, contains('قائمة شراء رقم 102'));
  });

  test('reverses debit and credit sides for a purchase return', () async {
    final seeded = (await repositories.purchases.getAll()).firstWhere(
      (invoice) =>
          invoice.purchaseKind == PurchaseTransactionKind.returnPurchase,
    );
    await repositories.purchases.replaceInvoice(
      PurchaseInvoice(
        id: seeded.id,
        documentNumber: seeded.documentNumber,
        date: seeded.date,
        minuteOfDay: seeded.minuteOfDay,
        supplierId: seeded.supplierId,
        defaultWarehouseId: seeded.defaultWarehouseId,
        currency: seeded.currency,
        exchangeRate: seeded.exchangeRate,
        purchaseKind: seeded.purchaseKind,
        settlementKind: PurchaseSettlementKind.credit,
        lines: seeded.lines,
        expenses: seeded.expenses,
        invoiceDiscount: seeded.invoiceDiscount,
        paid: Money.fromMajor(40000, AppCurrency.iqd),
        originalPurchaseInvoiceId: seeded.originalPurchaseInvoiceId,
        supplierNameSnapshot: seeded.supplierNameSnapshot,
        searchDetailsSnapshot: seeded.searchDetailsSnapshot,
        notes: seeded.notes,
      ),
    );

    final result = await service.load(
      PartyStatementQuery(
        partyId: seeded.supplierId,
        fromDate: seeded.date,
        toDate: seeded.date,
        currency: seeded.currency,
      ),
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.debit.majorUnits, 90000);
    expect(result.entries.single.credit.majorUnits, 40000);
    expect(result.entries.single.balance.majorUnits, -490000);
  });

  test('shows an unpaid supplier expense without a duplicate Cashbox row',
      () async {
    final result = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-003'),
        fromDate: BusinessDate(2026, 7, 28),
        toDate: BusinessDate(2026, 7, 28),
        currency: AppCurrency.usd,
      ),
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.type, PartyStatementEntryType.expense);
    expect(result.entries.single.debit, Money.zero(AppCurrency.usd));
    expect(
      result.entries.single.credit,
      Money.fromMajor(150, AppCurrency.usd),
    );
    expect(
      result.entries.single.balance,
      Money.fromMajor(-950, AppCurrency.usd),
    );
  });

  test('shows one Sales-return movement and excludes its system payment',
      () async {
    final source = (await repositories.sales.getById(
      EntityId('sales-invoice-103'),
    ))!;
    final saved = await repositories.salesReturns.createReturn(
      SalesReturnSaveRequest(
        originalSalesInvoiceId: source.id,
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 10 * 60,
        lines: [
          SalesReturnLineRequest(
            sourceSalesLineId: source.lines.first.id,
            quantity: WholeQuantity(1),
          ),
        ],
        refundedAtReturn: Money.fromMajor(10000, AppCurrency.iqd),
      ),
    );

    final result = await service.load(
      PartyStatementQuery(
        partyId: source.customerId,
        fromDate: BusinessDate(2026, 8, 14),
        toDate: BusinessDate(2026, 8, 14),
        currency: source.currency,
      ),
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.type, PartyStatementEntryType.saleReturn);
    expect(result.entries.single.debit, saved.refundedAtReturn);
    expect(result.entries.single.credit, saved.total);
    expect(
      result.closingBalance,
      (await repositories.parties.getById(source.customerId))!.iqdBalance,
    );
  });

  test('carries pre-range movements into opening and running balances',
      () async {
    final result = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-001'),
        fromDate: BusinessDate(2026, 7, 27),
        toDate: BusinessDate(2026, 7, 27),
        currency: AppCurrency.iqd,
      ),
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.type, PartyStatementEntryType.receipt);
    expect(result.openingBalance.majorUnits, 1250000);
    expect(result.entries.single.balance.majorUnits, 500000);
    expect(result.closingBalance, result.entries.single.balance);
  });

  test('combines sale, purchase, and manual cashbox movements by party id',
      () async {
    final template = (await repositories.purchases.getAll()).firstWhere(
      (invoice) =>
          invoice.id == const EntityId('purchase-invoice-101'),
    );
    await repositories.purchases.createInvoice(
      PurchaseInvoice(
        id: EntityId('purchase-invoice-mixed-party'),
        documentNumber: await repositories.purchases.nextDocumentNumber(),
        date: BusinessDate(2026, 7, 26),
        minuteOfDay: 10 * 60 + 30,
        supplierId: EntityId('party-001'),
        supplierNameSnapshot: 'اسم مستندي قديم',
        defaultWarehouseId: template.defaultWarehouseId,
        currency: template.currency,
        exchangeRate: template.exchangeRate,
        purchaseKind: template.purchaseKind,
        settlementKind: PurchaseSettlementKind.credit,
        lines: template.lines,
        expenses: template.expenses,
        invoiceDiscount: template.invoiceDiscount,
        paid: Money.zero(template.currency),
        notes: 'حركة اختبار مشتركة',
      ),
    );

    final result = await service.load(
      PartyStatementQuery(
        partyId: EntityId('party-001'),
        fromDate: BusinessDate(2026, 7, 25),
        toDate: BusinessDate(2026, 7, 27),
        currency: AppCurrency.iqd,
      ),
    );

    expect(
      result.entries.map((entry) => entry.type),
      [
        PartyStatementEntryType.sale,
        PartyStatementEntryType.purchase,
        PartyStatementEntryType.receipt,
      ],
    );
    var expectedBalance = result.openingBalance;
    for (final entry in result.entries) {
      expectedBalance = expectedBalance + entry.debit - entry.credit;
      expect(entry.balance, expectedBalance);
    }
    expect(result.closingBalance, expectedBalance);
    expect(result.closingBalance.majorUnits, 260000);
  });

  test('excludes source-linked invoice postings from statement movements',
      () async {
    final systemPosting = CashboxVoucher.typed(
      entityId: EntityId('cashbox-system-sales-102'),
      number: 99,
      createdTimestamp: AuditTimestamp(DateTime(2026, 7, 26, 12, 40)),
      type: CashboxVoucherType.receipt,
      mainAccountEntityId: EntityId.demo('cashbox-main-account', 4),
      mainAccountLabel: 'الأطراف',
      subaccountEntityId: EntityId.demo('cashbox-subaccount', 5),
      subaccountLabel: '2 - أحمد كريم',
      exchangeRateValue: ExchangeRate.parse('1310'),
      iqdAmount: Money.zero(AppCurrency.iqd),
      usdAmount: Money.fromMajor(250, AppCurrency.usd),
      iqdBalanceBefore: Money.zero(AppCurrency.iqd),
      iqdBalanceAfter: Money.zero(AppCurrency.iqd),
      usdBalanceBefore: Money.zero(AppCurrency.usd),
      usdBalanceAfter: Money.zero(AppCurrency.usd),
      notes: 'تسوية مولدة من قائمة البيع',
      source: CashboxVoucherSource(
        kind: CashboxVoucherSourceKind.salesInvoice,
        sourceId: EntityId('sales-invoice-102'),
        partyId: EntityId('party-002'),
      ),
    );
    final serviceWithPosting = RepositoryPartyStatementService(
      parties: repositories.parties,
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: _CashboxWithExtraPartyVoucher(
        repositories.cashbox,
        systemPosting,
      ),
    );

    final result = await serviceWithPosting.load(
      PartyStatementQuery(
        partyId: EntityId('party-002'),
        fromDate: BusinessDate(2026, 7, 24),
        toDate: BusinessDate(2026, 7, 26),
        currency: AppCurrency.usd,
      ),
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.type, PartyStatementEntryType.sale);
    expect(result.closingBalance.majorUnits, 0);
  });

  test('rejects a reversed date range', () {
    expect(
      () => PartyStatementQuery(
        partyId: EntityId('party-001'),
        fromDate: BusinessDate(2026, 7, 28),
        toDate: BusinessDate(2026, 7, 27),
        currency: AppCurrency.iqd,
      ),
      throwsArgumentError,
    );
  });
}

class _CashboxWithExtraPartyVoucher implements CashboxRepository {
  _CashboxWithExtraPartyVoucher(this._delegate, this._extraVoucher);

  final CashboxRepository _delegate;
  final CashboxVoucher _extraVoucher;

  @override
  Future<List<CashboxVoucher>> getByParty(EntityId partyId) async {
    return [
      ...await _delegate.getByParty(partyId),
      if (_extraVoucher.source?.partyId == partyId) _extraVoucher,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unused cashbox repository member');
}
