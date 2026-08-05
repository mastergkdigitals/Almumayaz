import '../../../core/domain/business_values.dart';

enum SalesSettlementKind { cash, credit, installments }

class SalesInvoiceLine {
  SalesInvoiceLine({
    required this.id,
    required this.itemId,
    required this.warehouseId,
    required this.quantity,
    required this.unitPrice,
    required this.discountPerUnit,
    this.itemCodeSnapshot = '',
    this.itemNameSnapshot = '',
    this.warehouseNameSnapshot = '',
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    if (unitPrice.isNegative ||
        discountPerUnit.currency != unitPrice.currency ||
        discountPerUnit.isNegative ||
        discountPerUnit.compareTo(unitPrice) > 0) {
      throw ArgumentError.value(
        discountPerUnit,
        'discountPerUnit',
        'Invalid discount',
      );
    }
  }

  final EntityId id;
  final EntityId itemId;
  final EntityId warehouseId;
  final WholeQuantity quantity;
  final Money unitPrice;
  final Money discountPerUnit;

  /// Document snapshots keep old invoices readable after master-data labels
  /// change. References remain the canonical source of identity.
  final String itemCodeSnapshot;
  final String itemNameSnapshot;
  final String warehouseNameSnapshot;

  Money get netUnitPrice => unitPrice - discountPerUnit;

  Money get total => netUnitPrice * quantity.value;
}

class SalesInvoice {
  SalesInvoice({
    required this.id,
    required this.documentNumber,
    required this.date,
    required this.minuteOfDay,
    required this.customerId,
    required this.defaultWarehouseId,
    required this.currency,
    required this.exchangeRate,
    required this.settlementKind,
    required Iterable<SalesInvoiceLine> lines,
    required this.invoiceDiscount,
    required this.received,
    this.customerNameSnapshot = '',
    this.searchDetailsSnapshot = '',
    this.balanceAfterInvoice,
    this.driverName = '',
    this.notes = '',
  }) : lines = List.unmodifiable(lines) {
    if (documentNumber < 1) {
      throw ArgumentError.value(documentNumber, 'documentNumber');
    }
    if (this.lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'At least one line is required');
    }
    if (minuteOfDay < 0 ||
        minuteOfDay >= Duration.hoursPerDay * Duration.minutesPerHour) {
      throw ArgumentError.value(minuteOfDay, 'minuteOfDay');
    }
    if (this.lines.any(
      (line) => line.unitPrice.currency != currency,
    )) {
      throw ArgumentError('Sales lines must use the invoice currency');
    }
    if (invoiceDiscount.currency != currency ||
        invoiceDiscount.isNegative ||
        invoiceDiscount.compareTo(subtotal) > 0) {
      throw ArgumentError.value(invoiceDiscount, 'invoiceDiscount');
    }
    if (received.currency != currency ||
        received.isNegative ||
        received.compareTo(total) > 0) {
      throw ArgumentError.value(received, 'received', 'Invalid received value');
    }
    if (settlementKind == SalesSettlementKind.cash && received != total) {
      throw ArgumentError.value(
        received,
        'received',
        'Cash invoices must be received in full',
      );
    }
    if (balanceAfterInvoice != null &&
        balanceAfterInvoice!.currency != currency) {
      throw ArgumentError.value(
        balanceAfterInvoice,
        'balanceAfterInvoice',
        'Invalid balance currency',
      );
    }
  }

  final EntityId id;

  /// Visible business number. It is intentionally separate from [id].
  final int documentNumber;
  final BusinessDate date;
  final int minuteOfDay;
  final EntityId customerId;
  final EntityId defaultWarehouseId;
  final AppCurrency currency;
  final ExchangeRate exchangeRate;
  final SalesSettlementKind settlementKind;
  final List<SalesInvoiceLine> lines;
  final Money invoiceDiscount;
  final Money received;
  final String customerNameSnapshot;
  final String searchDetailsSnapshot;
  final Money? balanceAfterInvoice;
  final String driverName;
  final String notes;

  Money get subtotal => lines.fold(
        Money.zero(currency),
        (total, line) => total + line.total,
      );

  Money get total => subtotal - invoiceDiscount;

  Percentage get invoiceDiscountPercentage {
    if (subtotal.isZero) return Percentage.fromBasisPoints(0);
    final basisPoints =
        (invoiceDiscount.minorUnits * 10000 / subtotal.minorUnits).round();
    return Percentage.fromBasisPoints(
      basisPoints > 10000 ? 10000 : basisPoints,
    );
  }
}
