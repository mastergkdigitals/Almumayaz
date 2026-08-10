import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps Sales discounts and receipts within the domain total', () {
    final fullyDiscounted = _invoice(
      invoiceDiscount: Money.fromMajor(100, AppCurrency.iqd),
      received: Money.zero(AppCurrency.iqd),
    );
    expect(fullyDiscounted.total, Money.zero(AppCurrency.iqd));

    expect(
      () => _invoice(
        invoiceDiscount: Money.fromMajor(101, AppCurrency.iqd),
        received: Money.zero(AppCurrency.iqd),
      ),
      throwsArgumentError,
    );
    expect(
      () => _invoice(
        invoiceDiscount: Money.zero(AppCurrency.iqd),
        received: Money.fromMajor(101, AppCurrency.iqd),
      ),
      throwsArgumentError,
    );
  });

  test('rejects a Sales per-unit discount above the unit price', () {
    expect(
      () => _line(
        discountPerUnit: Money.fromMajor(101, AppCurrency.iqd),
      ),
      throwsArgumentError,
    );
  });
}

SalesInvoice _invoice({
  required Money invoiceDiscount,
  required Money received,
}) {
  return SalesInvoice(
    id: EntityId('sales-invoice-test'),
    documentNumber: 1,
    date: BusinessDate(2026, 8, 10),
    minuteOfDay: 9 * 60,
    customerId: EntityId('party-test'),
    defaultWarehouseId: EntityId('warehouse-test'),
    currency: AppCurrency.iqd,
    exchangeRate: ExchangeRate.parse('1310'),
    settlementKind: SalesSettlementKind.credit,
    lines: [_line(discountPerUnit: Money.zero(AppCurrency.iqd))],
    invoiceDiscount: invoiceDiscount,
    received: received,
  );
}

SalesInvoiceLine _line({required Money discountPerUnit}) {
  return SalesInvoiceLine(
    id: EntityId('sales-line-test'),
    itemId: EntityId('item-test'),
    warehouseId: EntityId('warehouse-test'),
    quantity: WholeQuantity(1),
    unitPrice: Money.fromMajor(100, AppCurrency.iqd),
    discountPerUnit: discountPerUnit,
  );
}
