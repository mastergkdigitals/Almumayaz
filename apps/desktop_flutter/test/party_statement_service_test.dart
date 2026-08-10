import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/parties/application/party_statement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRepositories repositories;
  late PartyStatementService service;

  setUp(() {
    repositories = AppRepositories.demo();
    service = RepositoryPartyStatementService(
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: repositories.cashbox,
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
    expect(result.entries.first.balance.majorUnits, 177000);
    expect(result.entries.first.quantity, 10);
    expect(result.entries.first.details, contains('قائمة بيع رقم 101'));

    final receipt = result.entries.last;
    expect(receipt.date, DateTime(2026, 7, 27, 8, 30));
    expect(receipt.debit.majorUnits, 0);
    expect(receipt.credit.majorUnits, 750000);
    expect(receipt.balance.majorUnits, -573000);
    expect(receipt.quantity, isNull);
    expect(receipt.details, contains('سند قبض رقم 1'));
    expect(result.closingBalance.majorUnits, -573000);
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
    expect(dollars.closingBalance.majorUnits, 1000);
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
    expect(purchase.balance.majorUnits, -1000);
    expect(purchase.quantity, 5);
    expect(purchase.details, contains('قائمة شراء رقم 102'));
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
