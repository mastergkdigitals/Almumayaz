import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales_returns/data/demo_sales_return_mutation_effects.dart';
import 'package:erp/features/sales_returns/data/demo_sales_return_repository.dart';
import 'package:erp/features/sales_returns/domain/sales_return.dart';
import 'package:erp/features/sales_returns/domain/sales_return_repository.dart';
import 'package:erp/features/sales_returns/presentation/sales_return_document.dart';
import 'package:erp/features/sales_returns/presentation/widgets/sales_return_lines_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line editor parses Design System grouped whole quantities', () {
    final sourceLine = SalesInvoiceLine(
      id: EntityId('grouped-source-line'),
      itemId: EntityId('item-1'),
      warehouseId: EntityId('warehouse-1'),
      quantity: WholeQuantity(1200),
      unitPrice: Money.fromMajor(1, AppCurrency.iqd),
      discountPerUnit: Money.zero(AppCurrency.iqd),
    );
    final editor = SalesReturnLineEditor(
      returnable: SalesReturnableLine(
        source: sourceLine,
        previouslyReturned: WholeQuantity(0),
        available: WholeQuantity(1200),
        sourceAllocatedRefund: Money.fromMajor(1200, AppCurrency.iqd),
        availableRefund: Money.fromMajor(1200, AppCurrency.iqd),
      ),
    );
    addTearDown(editor.dispose);

    editor.quantityController.text = '1,000';

    expect(editor.requestedQuantity, 1000);
    expect(
      editor.previewRefund,
      Money.fromMajor(1000, AppCurrency.iqd),
    );
  });

  group('linked Sales-return repository', () {
    test('normalizes source links and allocates partial returns exactly',
        () async {
      final source = _invoice();
      final repository = _repository(source);

      final first = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.fromMajor(3, AppCurrency.iqd),
        ),
      );
      final second = await repository.createReturn(
        _request(
          source,
          quantity: 2,
          refund: Money.fromMajor(7, AppCurrency.iqd),
        ),
      );

      expect(first.documentNumber, 1);
      expect(second.documentNumber, 2);
      expect(first.originalSalesInvoiceId, source.id);
      expect(first.lines.single.sourceSalesLineId, source.lines.single.id);
      expect(first.lines.single.itemId, source.lines.single.itemId);
      expect(first.lines.single.warehouseId, source.lines.single.warehouseId);
      expect(first.total, Money.fromMajor(3, AppCurrency.iqd));
      expect(second.total, Money.fromMajor(7, AppCurrency.iqd));
      expect(first.total + second.total, source.total);

      final returnable = await repository.loadReturnableSource(source.id);
      expect(returnable.lines.single.previouslyReturned.value, 3);
      expect(returnable.lines.single.available.value, 0);
      expect(returnable.lines.single.availableRefund.isZero, isTrue);
    });

    test('partial refunds use one cumulative target and preserve the remainder',
        () async {
      final source = _smallAllocationInvoice();
      final repository = _repository(source);

      final first = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );
      final afterFirst = await repository.loadReturnableSource(source.id);
      final preview = SalesReturnLineEditor(
        returnable: afterFirst.lines.single,
      );
      addTearDown(preview.dispose);
      preview.quantityController.text = '1';
      final second = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );
      final third = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );

      expect(first.lines.single.allocatedRefund.minorUnits, 1);
      expect(preview.previewRefund.minorUnits, 0);
      expect(second.lines.single.allocatedRefund.minorUnits, 0);
      expect(third.lines.single.allocatedRefund.minorUnits, 1);
      expect(
        first.total + second.total + third.total,
        source.total,
      );
    });

    test('rejects cumulative over-return and a foreign source line', () async {
      final source = _invoice();
      final repository = _repository(source);
      await repository.createReturn(
        _request(
          source,
          quantity: 2,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );

      await expectLater(
        repository.createReturn(
          _request(
            source,
            quantity: 2,
            refund: Money.zero(AppCurrency.iqd),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.createReturn(
          SalesReturnSaveRequest(
            originalSalesInvoiceId: source.id,
            date: BusinessDate(2026, 7, 26),
            minuteOfDay: 10 * 60,
            lines: [
              SalesReturnLineRequest(
                sourceSalesLineId: EntityId('foreign-sales-line'),
                quantity: WholeQuantity(1),
              ),
            ],
            refundedAtReturn: Money.zero(AppCurrency.iqd),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('retains identity and number across replace', () async {
      final source = _invoice();
      final repository = _repository(source);
      final created = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );

      final replaced = await repository.replaceReturn(
        created.id,
        _request(
          source,
          quantity: 2,
          refund: Money.fromMajor(1, AppCurrency.iqd),
        ),
      );

      expect(replaced.id, created.id);
      expect(replaced.documentNumber, created.documentNumber);
      expect(replaced.lines.single.id, created.lines.single.id);
      expect(replaced.lines.single.quantity.value, 2);
      expect(replaced.total, Money.fromMajor(7, AppCurrency.iqd));
    });

    test('only the latest issued return for a source can change', () async {
      final source = _invoice();
      final repository = _repository(source);
      final first = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );
      final second = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );

      expect((await repository.canDelete(first.id)).isAllowed, isFalse);
      await expectLater(
        repository.replaceReturn(
          first.id,
          _request(
            source,
            quantity: 1,
            refund: Money.zero(AppCurrency.iqd),
          ),
        ),
        throwsStateError,
      );
      await expectLater(
        repository.deleteReturnPermanently(first.id),
        throwsStateError,
      );

      expect(await repository.getAll(), hasLength(2));
      expect((await repository.getById(first.id))!.total, first.total);
      await repository.deleteReturnPermanently(second.id);
      expect((await repository.canDelete(first.id)).isAllowed, isTrue);
    });

    test('deleted return numbers are never reused', () async {
      final source = _invoice();
      final repository = _repository(source);
      final first = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );
      await repository.deleteReturnPermanently(first.id);

      final second = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );

      expect(second.documentNumber, 2);
      expect(await repository.nextDocumentNumber(), 3);
    });

    test('cash refunds cannot exceed receipts from the original invoice',
        () async {
      final source = _invoice(received: 5);
      final repository = _repository(source);
      await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.fromMajor(3, AppCurrency.iqd),
        ),
      );

      await expectLater(
        repository.createReturn(
          _request(
            source,
            quantity: 2,
            refund: Money.fromMajor(3, AppCurrency.iqd),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect((await repository.getAll()).length, 1);
    });

    test('return date cannot precede its original invoice', () async {
      final source = _invoice();
      final repository = _repository(source);

      await expectLater(
        repository.createReturn(
          SalesReturnSaveRequest(
            originalSalesInvoiceId: source.id,
            date: BusinessDate(2026, 7, 24),
            minuteOfDay: 10 * 60,
            lines: [
              SalesReturnLineRequest(
                sourceSalesLineId: source.lines.single.id,
                quantity: WholeQuantity(1),
              ),
            ],
            refundedAtReturn: Money.zero(AppCurrency.iqd),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('newer return cannot be backdated before an older return', () async {
      final source = _invoice();
      final repository = _repository(source);
      await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(source.currency),
          date: BusinessDate(2026, 7, 27),
        ),
      );

      await expectLater(
        repository.createReturn(
          _request(
            source,
            quantity: 1,
            refund: Money.zero(source.currency),
            date: BusinessDate(2026, 7, 26),
          ),
        ),
        throwsStateError,
      );
    });

    test('failed cross-feature staging leaves storage and number untouched',
        () async {
      final source = _invoice();
      final effects = _TestSalesReturnEffects()..failApply = true;
      final repository = _repository(source, effects: effects);

      await expectLater(
        repository.createReturn(
          _request(
            source,
            quantity: 1,
            refund: Money.zero(AppCurrency.iqd),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await repository.getAll(), isEmpty);
      expect(await repository.nextDocumentNumber(), 1);
    });

    test('hasReturnsForInvoice follows create and delete', () async {
      final source = _invoice();
      final repository = _repository(source);
      expect(await repository.hasReturnsForInvoice(source.id), isFalse);
      final created = await repository.createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.zero(AppCurrency.iqd),
        ),
      );
      expect(await repository.hasReturnsForInvoice(source.id), isTrue);
      await repository.deleteReturnPermanently(created.id);
      expect(await repository.hasReturnsForInvoice(source.id), isFalse);
    });

    test('document output keeps dates and amounts typed for Excel', () async {
      final source = _invoice();
      final value = await _repository(source).createReturn(
        _request(
          source,
          quantity: 1,
          refund: Money.fromMajor(3, AppCurrency.iqd),
        ),
      );

      final request = salesReturnDocumentRequest(value);

      expect(request.title, 'مرتجع بيع رقم 1');
      expect(request.auditTarget?.entityType, 'sales_return');
      expect(
        request.fields
            .firstWhere((field) => field.label == 'التاريخ')
            .spreadsheetCellKind,
        DocumentSpreadsheetCellKind.date,
      );
      expect(
        request.columns
            .firstWhere((column) => column.label == 'الكمية')
            .spreadsheetCellKind,
        DocumentSpreadsheetCellKind.integer,
      );
      expect(
        request.columns
            .firstWhere((column) => column.label == 'قيمة المرتجع')
            .spreadsheetCellKind,
        DocumentSpreadsheetCellKind.decimal,
      );
      expect(request.rows.single[3], '1');
      expect(request.rows.single[5], '3');
    });
  });
}

DemoSalesReturnRepository _repository(
  SalesInvoice source, {
  _TestSalesReturnEffects? effects,
}) {
  return DemoSalesReturnRepository(
    salesInvoiceLoader: (id) async => id == source.id ? source : null,
    mutationEffects: effects ?? _TestSalesReturnEffects(),
    clock: () => DateTime(2026, 8, 14, 12),
  );
}

SalesReturnSaveRequest _request(
  SalesInvoice source, {
  required int quantity,
  required Money refund,
  BusinessDate? date,
}) {
  return SalesReturnSaveRequest(
    originalSalesInvoiceId: source.id,
    date: date ?? BusinessDate(2026, 7, 26),
    minuteOfDay: 10 * 60,
    lines: [
      SalesReturnLineRequest(
        sourceSalesLineId: source.lines.single.id,
        quantity: WholeQuantity(quantity),
      ),
    ],
    refundedAtReturn: refund,
    notes: 'مرتجع اختباري',
  );
}

SalesInvoice _invoice({int received = 10}) {
  return SalesInvoice(
    id: EntityId('source-sales-invoice'),
    documentNumber: 70,
    date: BusinessDate(2026, 7, 25),
    minuteOfDay: 9 * 60,
    customerId: EntityId('customer-1'),
    customerNameSnapshot: 'زبون الاختبار',
    defaultWarehouseId: EntityId('warehouse-1'),
    currency: AppCurrency.iqd,
    exchangeRate: ExchangeRate.parse('1310'),
    settlementKind: received == 10
        ? SalesSettlementKind.cash
        : SalesSettlementKind.credit,
    lines: [
      SalesInvoiceLine(
        id: EntityId('source-sales-line'),
        itemId: EntityId('item-1'),
        warehouseId: EntityId('warehouse-1'),
        quantity: WholeQuantity(3),
        unitPrice: Money.fromMajor(4, AppCurrency.iqd),
        discountPerUnit: Money.zero(AppCurrency.iqd),
        itemCodeSnapshot: '1001',
        itemNameSnapshot: 'مادة اختبار',
        warehouseNameSnapshot: 'المخزن الرئيسي',
      ),
    ],
    invoiceDiscount: Money.fromMajor(2, AppCurrency.iqd),
    received: Money.fromMajor(received, AppCurrency.iqd),
    balanceAfterInvoice: Money.fromMajor(10 - received, AppCurrency.iqd),
  );
}

SalesInvoice _smallAllocationInvoice() {
  return SalesInvoice(
    id: EntityId('small-allocation-sales-invoice'),
    documentNumber: 71,
    date: BusinessDate(2026, 7, 25),
    minuteOfDay: 9 * 60,
    customerId: EntityId('customer-1'),
    customerNameSnapshot: 'زبون الاختبار',
    defaultWarehouseId: EntityId('warehouse-1'),
    currency: AppCurrency.iqd,
    exchangeRate: ExchangeRate.parse('1310'),
    settlementKind: SalesSettlementKind.cash,
    lines: [
      SalesInvoiceLine(
        id: EntityId('small-allocation-sales-line'),
        itemId: EntityId('item-1'),
        warehouseId: EntityId('warehouse-1'),
        quantity: WholeQuantity(3),
        unitPrice: Money.fromMinorUnits(1, AppCurrency.iqd),
        discountPerUnit: Money.zero(AppCurrency.iqd),
      ),
    ],
    invoiceDiscount: Money.fromMinorUnits(1, AppCurrency.iqd),
    received: Money.fromMinorUnits(2, AppCurrency.iqd),
    balanceAfterInvoice: Money.zero(AppCurrency.iqd),
  );
}

class _TestSalesReturnEffects implements DemoSalesReturnMutationEffects {
  bool failApply = false;

  @override
  Future<SalesReturn> applySalesReturn({
    required Future<DemoSalesReturnMutation> Function()
        preflightAndBuildMutation,
    required void Function(SalesReturn normalized) commit,
  }) async {
    final mutation = await preflightAndBuildMutation();
    if (failApply) throw StateError('تعذر تطبيق آثار المرتجع');
    commit(mutation.candidate);
    return mutation.candidate;
  }

  @override
  Future<void> deleteSalesReturn({
    required Future<SalesReturn> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) async {
    await preflightAndLoadPrevious();
    commit();
  }
}
