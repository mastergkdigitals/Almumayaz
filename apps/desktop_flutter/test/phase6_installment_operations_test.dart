import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/app_state/feature_action_permissions.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/responsive/responsive_shell.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/installments/application/installment_schedule_builder.dart';
import 'package:erp/features/installments/domain/installment_plan.dart';
import 'package:erp/features/parties/application/party_statement_service.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/reports/application/report_rows_service.dart';
import 'package:erp/features/reports/data/repository_report_data_service.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales/presentation/sales_screen.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typed schedules preserve minor units, month ends, and stable IDs', () {
    final iqd = InstallmentScheduleBuilder.build(
      planId: EntityId('phase6-plan-iqd'),
      salesInvoiceId: EntityId('phase6-sale-iqd'),
      customerId: EntityId('party-001'),
      remaining: Money.fromMajor(1003, AppCurrency.iqd),
      invoiceDate: BusinessDate(2026, 1, 31),
    );
    expect(
      iqd.entries.map((entry) => entry.amount.minorUnits),
      [250, 250, 250, 253],
    );
    expect(
      iqd.entries.map((entry) => entry.dueDate),
      [
        BusinessDate(2026, 2, 28),
        BusinessDate(2026, 3, 31),
        BusinessDate(2026, 4, 30),
        BusinessDate(2026, 5, 31),
      ],
    );
    expect(
      iqd.entries.map((entry) => entry.id.value),
      [
        'phase6-plan-iqd-entry-1',
        'phase6-plan-iqd-entry-2',
        'phase6-plan-iqd-entry-3',
        'phase6-plan-iqd-entry-4',
      ],
    );
    expect(iqd.total, Money.fromMajor(1003, AppCurrency.iqd));

    final usd = InstallmentScheduleBuilder.build(
      planId: EntityId('phase6-plan-usd'),
      salesInvoiceId: EntityId('phase6-sale-usd'),
      customerId: EntityId('party-002'),
      remaining: Money.fromMajor(1000.01, AppCurrency.usd),
      invoiceDate: BusinessDate(2026, 1, 31),
    );
    expect(
      usd.entries.map((entry) => entry.amount.minorUnits),
      [25000, 25000, 25000, 25001],
    );
    expect(usd.total, Money.fromMajor(1000.01, AppCurrency.usd));

    final cents = InstallmentScheduleBuilder.build(
      planId: EntityId('phase6-plan-cents'),
      salesInvoiceId: EntityId('phase6-sale-cents'),
      customerId: EntityId('party-002'),
      remaining: Money.fromMinorUnits(2, AppCurrency.usd),
      invoiceDate: BusinessDate(2026, 8, 13),
    );
    expect(cents.entries, hasLength(2));
    expect(cents.entries.map((entry) => entry.amount.minorUnits), [1, 1]);
  });

  test('settlement updates plan, invoice, Party, and Cashbox exactly once',
      () async {
    final repositories = AppRepositories.demo();
    final invoiceBefore = await _installmentInvoice(repositories);
    final planBefore = await repositories.installments.getBySalesInvoiceId(
      invoiceBefore.id,
    );
    expect(planBefore, isNotNull);
    final plan = planBefore!;
    final entry = plan.entries.first;
    final partyBefore = (await repositories.parties.getById(
      invoiceBefore.customerId,
    ))!;
    final invoicePostingBefore = _sourcePostings(
      await repositories.cashbox.getAll(),
      CashboxVoucherSourceKind.salesInvoice,
      invoiceBefore.id,
    ).single;
    final paidAt = AuditTimestamp(DateTime.utc(2026, 8, 13, 9, 15));

    final settled = await repositories.installments.settleEntry(
      entryId: entry.id,
      paidAt: paidAt,
      notes: '  دفعة القسط الأولى  ',
    );

    final paidEntry = settled.entryById(entry.id)!;
    expect(paidEntry.status, InstallmentPaymentStatus.paid);
    expect(paidEntry.paidAt, paidAt);
    expect(paidEntry.notes, 'دفعة القسط الأولى');
    expect(settled.paid, entry.amount);
    expect(settled.remaining, plan.total - entry.amount);

    final invoiceAfter = (await repositories.sales.getById(
      invoiceBefore.id,
    ))!;
    expect(invoiceAfter.receivedAtSale, invoiceBefore.receivedAtSale);
    expect(
      invoiceAfter.installmentReceived,
      invoiceBefore.installmentReceived + entry.amount,
    );
    expect(invoiceAfter.received, invoiceBefore.received + entry.amount);
    expect(
      _partyMoney(
        await repositories.parties.getById(invoiceBefore.customerId),
        invoiceBefore.currency,
      ),
      _partyMoney(partyBefore, invoiceBefore.currency) - entry.amount,
    );

    final cashboxAfter = await repositories.cashbox.getAll();
    final invoicePostingAfter = _sourcePostings(
      cashboxAfter,
      CashboxVoucherSourceKind.salesInvoice,
      invoiceBefore.id,
    ).single;
    expect(invoicePostingAfter.entityId, invoicePostingBefore.entityId);
    expect(invoicePostingAfter.number, invoicePostingBefore.number);
    expect(
      invoicePostingAfter.usdAmount,
      invoicePostingBefore.usdAmount,
    );
    final paymentPosting = _sourcePostings(
      cashboxAfter,
      CashboxVoucherSourceKind.installmentPayment,
      entry.id,
    ).single;
    expect(paymentPosting.type, CashboxVoucherType.receipt);
    expect(paymentPosting.source!.partyId, invoiceBefore.customerId);
    expect(
      invoiceBefore.currency == AppCurrency.iqd
          ? paymentPosting.iqdAmount
          : paymentPosting.usdAmount,
      entry.amount,
    );
  });

  test('concurrent settlement of one entry commits only one payment',
      () async {
    final repositories = AppRepositories.demo();
    final invoiceBefore = await _installmentInvoice(repositories);
    final plan = (await repositories.installments.getBySalesInvoiceId(
      invoiceBefore.id,
    ))!;
    final entry = plan.entries.first;
    final partyBefore = await repositories.parties.getById(
      invoiceBefore.customerId,
    );

    Future<Object> settle(int minute) async {
      try {
        return await repositories.installments.settleEntry(
          entryId: entry.id,
          paidAt: AuditTimestamp(DateTime.utc(2026, 8, 13, 10, minute)),
        );
      } catch (error) {
        return error;
      }
    }

    final results = await Future.wait<Object>([settle(1), settle(2)]);

    expect(results.whereType<InstallmentPlan>(), hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    final persisted = (await repositories.installments.getBySalesInvoiceId(
      invoiceBefore.id,
    ))!;
    expect(
      persisted.entries.where((candidate) => candidate.isPaid),
      hasLength(1),
    );
    final invoiceAfter = (await repositories.sales.getById(
      invoiceBefore.id,
    ))!;
    expect(invoiceAfter.received, invoiceBefore.received + entry.amount);
    expect(
      _partyMoney(
        await repositories.parties.getById(invoiceBefore.customerId),
        invoiceBefore.currency,
      ),
      _partyMoney(partyBefore, invoiceBefore.currency) - entry.amount,
    );
    expect(
      _sourcePostings(
        await repositories.cashbox.getAll(),
        CashboxVoucherSourceKind.installmentPayment,
        entry.id,
      ),
      hasLength(1),
    );
  });

  test('statement separates at-sale receipt from installment settlement',
      () async {
    final repositories = AppRepositories.demo();
    final invoiceBefore = await _installmentInvoice(repositories);
    final plan = (await repositories.installments.getBySalesInvoiceId(
      invoiceBefore.id,
    ))!;
    final entry = plan.entries.first;
    await repositories.installments.settleEntry(
      entryId: entry.id,
      paidAt: AuditTimestamp(DateTime.utc(2026, 8, 13, 13, 30)),
      notes: 'دفعة عبر جدول الأقساط',
    );
    final service = RepositoryPartyStatementService(
      parties: repositories.parties,
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: repositories.cashbox,
    );

    final statement = await service.load(
      PartyStatementQuery(
        partyId: invoiceBefore.customerId,
        fromDate: BusinessDate(2026, 7, 1),
        toDate: BusinessDate(2026, 8, 31),
        currency: invoiceBefore.currency,
      ),
    );

    final sale = statement.entries.singleWhere(
      (candidate) => candidate.id == invoiceBefore.id,
    );
    expect(sale.type, PartyStatementEntryType.sale);
    expect(sale.debit, invoiceBefore.total);
    expect(sale.credit, invoiceBefore.receivedAtSale);
    final installmentReceipt = statement.entries.singleWhere(
      (candidate) =>
          candidate.type == PartyStatementEntryType.receipt &&
          candidate.credit == entry.amount,
    );
    expect(installmentReceipt.debit, Money.zero(invoiceBefore.currency));
    expect(installmentReceipt.details, contains('دفعة عبر جدول الأقساط'));
    expect(
      statement.entries.map((candidate) => candidate.type),
      containsAllInOrder([
        PartyStatementEntryType.sale,
        PartyStatementEntryType.receipt,
      ]),
    );
    expect(
      statement.closingBalance,
      _partyMoney(
        await repositories.parties.getById(invoiceBefore.customerId),
        invoiceBefore.currency,
      ),
    );
    var running = statement.openingBalance;
    for (final movement in statement.entries) {
      running = running + movement.debit - movement.credit;
      expect(movement.balance, running);
    }
  });

  test('debt report projects persisted installments and payment status',
      () async {
    final repositories = AppRepositories.demo();
    final invoice = await _installmentInvoice(repositories);
    final plan = (await repositories.installments.getBySalesInvoiceId(
      invoice.id,
    ))!;
    final service = RepositoryReportDataService(
      repositories,
      clock: () => DateTime(2026, 9, 1, 8),
    );

    final before = await service.loadSnapshot(
      const ReportRowsRequest(
        reportId: 'debtsInstallments',
        variantId: 'main',
      ),
    );
    final installmentRows = before.rows
        .where((row) => row.filterValues['recordType'] == 'installment')
        .where((row) => row.cells[2] == '${invoice.documentNumber}')
        .toList(growable: false);
    expect(installmentRows, hasLength(4));
    expect(
      before.rows.where((row) => row.id == 'debt:${invoice.id.value}'),
      isEmpty,
    );
    expect(installmentRows.map((row) => row.cells[3]), ['1', '2', '3', '4']);
    expect(
      installmentRows.map((row) => row.cells[10]),
      ['متأخر', 'مستحق', 'مستحق', 'مستحق'],
    );
    expect(
      installmentRows.map((row) => row.cells[9]),
      plan.entries.map((entry) => _reportMoney(entry.amount)),
    );

    final firstEntry = plan.entries.first;
    await repositories.installments.settleEntry(
      entryId: firstEntry.id,
      paidAt: AuditTimestamp(DateTime.utc(2026, 9, 1, 9)),
      notes: 'مسدد في اختبار التقرير',
    );
    final after = await service.loadSnapshot(
      const ReportRowsRequest(
        reportId: 'debtsInstallments',
        variantId: 'main',
      ),
    );
    final paidRow = after.rows.singleWhere(
      (row) => row.id == 'installment:${firstEntry.id.value}',
    );
    expect(paidRow.cells[8], _reportMoney(firstEntry.amount));
    expect(paidRow.cells[9], _reportMoney(Money.zero(plan.currency)));
    expect(paidRow.cells[10], 'مدفوع');
    expect(paidRow.cells[11], 'مسدد في اختبار التقرير');
    expect(
      after.rows
          .where((row) => row.filterValues['recordType'] == 'installment')
          .where((row) => row.cells[10] == 'مدفوع'),
      hasLength(1),
    );
  });

  test('unpaid plans rebuild deterministically and paid plans guard terms',
      () async {
    final repositories = AppRepositories.demo();
    final invoice = await _installmentInvoice(repositories);
    final before = (await repositories.installments.getBySalesInvoiceId(
      invoice.id,
    ))!;
    final repricedLine = _copyLine(
      invoice.lines.first,
      unitPrice: invoice.lines.first.unitPrice +
          Money.fromMajor(40, invoice.currency),
    );
    final repriced = invoice.copyWith(
      lines: [repricedLine, ...invoice.lines.skip(1)],
    );

    final saved = await repositories.sales.replaceInvoice(repriced);
    final rebuilt = (await repositories.installments.getBySalesInvoiceId(
      invoice.id,
    ))!;

    expect(rebuilt.id, before.id);
    expect(
      rebuilt.entries.map((entry) => entry.id),
      orderedEquals(before.entries.map((entry) => entry.id)),
    );
    expect(rebuilt.entries.every((entry) => !entry.isPaid), isTrue);
    expect(rebuilt.total, saved.total - saved.receivedAtSale);

    final paidEntry = rebuilt.entries.first;
    await repositories.installments.settleEntry(
      entryId: paidEntry.id,
      paidAt: AuditTimestamp(DateTime.utc(2026, 8, 13, 11)),
    );
    final paidInvoice = (await repositories.sales.getById(invoice.id))!;
    final harmless = await repositories.sales.replaceInvoice(
      paidInvoice.copyWith(notes: 'تعديل ملاحظات بعد تسديد قسط'),
    );
    expect(harmless.notes, 'تعديل ملاحظات بعد تسديد قسط');
    expect(
      (await repositories.installments.getBySalesInvoiceId(invoice.id))!
          .entryById(paidEntry.id)!
          .isPaid,
      isTrue,
    );

    await expectLater(
      repositories.sales.replaceInvoice(
        harmless.copyWith(date: BusinessDate(2026, 8, 14)),
      ),
      throwsStateError,
    );
    final afterRejected = (await repositories.sales.getById(invoice.id))!;
    expect(afterRejected.date, harmless.date);
    expect(afterRejected.notes, harmless.notes);
  });

  test('concurrent settlement and invoice deletion leave no partial effects',
      () async {
    final repositories = AppRepositories.demo();
    final invoice = await _installmentInvoice(repositories);
    final plan = (await repositories.installments.getBySalesInvoiceId(
      invoice.id,
    ))!;
    final entry = plan.entries.first;
    final partyBefore = await repositories.parties.getById(invoice.customerId);
    final stockBefore = <(EntityId, EntityId), int>{};
    for (final line in invoice.lines) {
      final key = (line.warehouseId, line.itemId);
      stockBefore.putIfAbsent(
        key,
        () => 0,
      );
      stockBefore[key] = await _stock(
        repositories,
        warehouseId: line.warehouseId,
        itemId: line.itemId,
      );
    }

    Future<Object> captureSettlement() async {
      try {
        return await repositories.installments.settleEntry(
          entryId: entry.id,
          paidAt: AuditTimestamp(DateTime.utc(2026, 8, 13, 12)),
        );
      } catch (error) {
        return error;
      }
    }

    Future<Object> captureDelete() async {
      try {
        await repositories.sales.deleteInvoicePermanently(invoice.id);
        return true;
      } catch (error) {
        return error;
      }
    }

    final results = await Future.wait<Object>([
      captureSettlement(),
      captureDelete(),
    ]);

    expect(results.whereType<StateError>().length, lessThanOrEqualTo(1));
    expect(await repositories.sales.getById(invoice.id), isNull);
    expect(
      await repositories.installments.getBySalesInvoiceId(invoice.id),
      isNull,
    );
    expect(
      _partyMoney(
        await repositories.parties.getById(invoice.customerId),
        invoice.currency,
      ),
      _partyMoney(partyBefore, invoice.currency) -
          (invoice.total - invoice.received),
    );
    final restoredQuantities = <(EntityId, EntityId), int>{};
    for (final line in invoice.lines) {
      final key = (line.warehouseId, line.itemId);
      restoredQuantities[key] =
          (restoredQuantities[key] ?? 0) + line.quantity.value;
    }
    for (final entry in restoredQuantities.entries) {
      expect(
        await _stock(
          repositories,
          warehouseId: entry.key.$1,
          itemId: entry.key.$2,
        ),
        stockBefore[entry.key]! + entry.value,
      );
    }
    final postings = await repositories.cashbox.getAll();
    expect(
      postings.where(
        (voucher) =>
            voucher.source?.kind == CashboxVoucherSourceKind.salesInvoice &&
            voucher.source?.sourceId == invoice.id,
      ),
      isEmpty,
    );
    expect(
      postings.where(
        (voucher) =>
            voucher.source?.kind ==
                CashboxVoucherSourceKind.installmentPayment &&
            plan.entries.any(
              (candidate) => candidate.id == voucher.source?.sourceId,
            ),
      ),
      isEmpty,
    );
  });

  testWidgets('view-only Sales can inspect but cannot settle installments',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _signedInViewOnlyStore();
    addTearDown(store.dispose);
    final invoice = await _installmentInvoice(store.repositories);
    final planBefore = (await store.repositories.installments
        .getBySalesInvoiceId(invoice.id))!;

    await tester.pumpWidget(
      _screenHarness(store, const SalesScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesInstallmentsButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('appInstallmentScheduleDialog')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appInstallmentScheduleSettle')),
          )
          .onPressed,
      isNull,
    );
    final planAfter = (await store.repositories.installments
        .getBySalesInvoiceId(invoice.id))!;
    expect(planAfter.id, planBefore.id);
    expect(
      planAfter.entries.map((entry) => entry.status),
      orderedEquals(planBefore.entries.map((entry) => entry.status)),
    );
  });

  testWidgets(
      'paid installments lock Sales terms but keep harmless fields editable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo()..suspendIdleMonitoring();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    store.suspendIdleMonitoring();
    expect(
      store.allowsFeatureAction('sales', PermissionAction.update),
      isTrue,
    );
    final invoice = await _installmentInvoice(store.repositories);
    final plan = (await store.repositories.installments
        .getBySalesInvoiceId(invoice.id))!;
    await store.repositories.installments.settleEntry(
      entryId: plan.entries.first.id,
      paidAt: AuditTimestamp(DateTime.utc(2026, 8, 13, 15)),
      notes: 'دفعة قبل اختبار قفل التعديل',
    );
    final settled = (await store.repositories.sales.getById(invoice.id))!;

    await tester.pumpWidget(_screenHarness(store, const SalesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'salesInvoiceNumberField'), '102');

    expect(_dateField(tester, 'salesDateField').enabled, isFalse);
    expect(
      _autocompleteField<Party>(tester, 'salesCustomerNameField').enabled,
      isFalse,
    );
    for (final key in const ['salesTypeField', 'salesCurrencyField']) {
      expect(_dropdownField(tester, key).enabled, isFalse);
    }
    for (final key in const [
      'salesExchangeRateField',
      'salesReceivedField',
      'salesInvoiceDiscountField',
      'salesDiscountPercentageField',
    ]) {
      final field = _textField(tester, key);
      expect(field.enabled, isFalse, reason: '$key must be disabled');
      expect(field.readOnly, isTrue, reason: '$key must be read-only');
    }
    final table = tester.widget<AppSalesInvoiceTableTemplate>(
      find.byKey(const Key('salesItemsTable')),
    );
    expect(table.enabled, isFalse);
    final rowTextFields = tester.widgetList<TextField>(
      find.descendant(
        of: find.byKey(const Key('salesItemsTable')),
        matching: find.byType(TextField),
      ),
    );
    expect(rowTextFields, isNotEmpty);
    expect(rowTextFields.every((field) => field.enabled == false), isTrue);
    final rowDropdowns = tester.widgetList<AppDropdownField<String>>(
      find.descendant(
        of: find.byKey(const Key('salesItemsTable')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(rowDropdowns, isNotEmpty);
    expect(rowDropdowns.every((field) => !field.enabled), isTrue);
    final rowAutocompletes =
        tester.widgetList<AppAutocompleteField<AppInvoiceItemOption>>(
      find.descendant(
        of: find.byKey(const Key('salesItemsTable')),
        matching: find.byType(
          AppAutocompleteField<AppInvoiceItemOption>,
        ),
      ),
    );
    expect(rowAutocompletes, isNotEmpty);
    expect(rowAutocompletes.every((field) => !field.enabled), isTrue);
    final rowActionButtons = tester.widgetList<AppTableActionButton>(
      find.descendant(
        of: find.byKey(const Key('salesItemsTable')),
        matching: find.byType(AppTableActionButton),
      ),
    );
    expect(rowActionButtons, isNotEmpty);
    expect(
      rowActionButtons.every((button) => button.onPressed == null),
      isTrue,
    );

    for (final key in const ['salesNotesField', 'salesDriverNameField']) {
      final field = _textField(tester, key);
      expect(field.enabled, isTrue, reason: '$key must stay enabled');
      expect(field.readOnly, isFalse, reason: '$key must stay editable');
    }
    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'ملاحظة مسموحة بعد تسديد القسط',
    );
    await tester.enterText(
      find.byKey(const Key('salesDriverNameField')),
      'سائق محدث بعد التسديد',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('salesUpdateButton')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pumpAndSettle();

    final updated = (await store.repositories.sales.getById(invoice.id))!;
    expect(updated.notes, 'ملاحظة مسموحة بعد تسديد القسط');
    expect(updated.driverName, 'سائق محدث بعد التسديد');
    expect(updated.receivedAtSale, settled.receivedAtSale);
    expect(updated.installmentReceived, settled.installmentReceived);
    expect(updated.received, settled.received);
    expect(
      (await store.repositories.installments
              .getBySalesInvoiceId(invoice.id))!
          .entries
          .first
          .isPaid,
      isTrue,
    );
  });
}

Future<SalesInvoice> _installmentInvoice(
  AppRepositories repositories,
) async {
  return (await repositories.sales.getAll()).firstWhere(
    (invoice) =>
        invoice.settlementKind == SalesSettlementKind.installments,
  );
}

List<CashboxVoucher> _sourcePostings(
  List<CashboxVoucher> values,
  CashboxVoucherSourceKind kind,
  EntityId sourceId,
) {
  return values
      .where(
        (voucher) =>
            voucher.source?.kind == kind &&
            voucher.source?.sourceId == sourceId,
      )
      .toList(growable: false);
}

Money _partyMoney(Party? party, AppCurrency currency) {
  final resolved = party!;
  return currency == AppCurrency.iqd
      ? resolved.iqdBalance
      : resolved.usdBalance;
}

String _reportMoney(Money value) {
  return AppFormatters.money(
    value.majorUnits,
    decimalPlaces: value.currency.decimalPlaces,
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(EditableText),
    ),
  ).controller.text;
}

TextField _textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    ),
  );
}

AppDateField _dateField(WidgetTester tester, String key) {
  return tester.widget<AppDateField>(
    find.ancestor(
      of: find.byKey(Key(key)),
      matching: find.byType(AppDateField),
    ),
  );
}

AppDropdownField<String> _dropdownField(
  WidgetTester tester,
  String key,
) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: find.byKey(Key(key)),
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

AppAutocompleteField<T> _autocompleteField<T extends Object>(
  WidgetTester tester,
  String key,
) {
  return tester.widget<AppAutocompleteField<T>>(
    find.ancestor(
      of: find.byKey(Key(key)),
      matching: find.byType(AppAutocompleteField<T>),
    ),
  );
}

SalesInvoiceLine _copyLine(
  SalesInvoiceLine source, {
  required Money unitPrice,
}) {
  return SalesInvoiceLine(
    id: source.id,
    itemId: source.itemId,
    warehouseId: source.warehouseId,
    quantity: source.quantity,
    unitPrice: unitPrice,
    discountPerUnit: source.discountPerUnit,
    itemCodeSnapshot: source.itemCodeSnapshot,
    itemNameSnapshot: source.itemNameSnapshot,
    warehouseNameSnapshot: source.warehouseNameSnapshot,
  );
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

Future<AppStore> _signedInViewOnlyStore() async {
  final store = AppStore.demo()..suspendIdleMonitoring();
  await store.signIn(
    SignInCredentials(username: 'admin', password: 'password'),
  );
  await store.services.administration.createUser(
    UserCreateRequest(
      fullName: 'مستخدم أقساط للعرض فقط',
      username: 'phase6.installments.viewer',
      roleIds: {EntityId.demo('role', 4)},
      initialPassword: 'viewer-password',
    ),
  );
  await store.signOut();
  await store.signIn(
    SignInCredentials(
      username: 'phase6.installments.viewer',
      password: 'viewer-password',
    ),
  );
  store.suspendIdleMonitoring();
  return store;
}

Widget _screenHarness(AppStore store, Widget screen) {
  return MaterialApp(
    locale: const Locale('ar', 'IQ'),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: AppKeyboardScope(
        child: ResponsiveDesktopShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: AppStoreScope(store: store, child: screen),
  );
}
