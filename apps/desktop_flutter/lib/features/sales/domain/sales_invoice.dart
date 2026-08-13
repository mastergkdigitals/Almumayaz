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
    Money? receivedAtSale,
    Money? installmentReceived,
    this.customerNameSnapshot = '',
    this.searchDetailsSnapshot = '',
    this.balanceAfterInvoice,
    this.driverName = '',
    this.notes = '',
  })  : receivedAtSale = receivedAtSale ??
            received - (installmentReceived ?? Money.zero(currency)),
        installmentReceived =
            installmentReceived ?? Money.zero(currency),
        lines = List.unmodifiable(lines) {
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
        this.receivedAtSale.currency != currency ||
        this.installmentReceived.currency != currency ||
        received.isNegative ||
        this.receivedAtSale.isNegative ||
        this.installmentReceived.isNegative ||
        received != this.receivedAtSale + this.installmentReceived ||
        received.compareTo(total) > 0) {
      throw ArgumentError.value(received, 'received', 'Invalid received value');
    }
    if (settlementKind != SalesSettlementKind.installments &&
        !this.installmentReceived.isZero) {
      throw ArgumentError.value(
        this.installmentReceived,
        'installmentReceived',
        'Only installment Sales can contain installment receipts',
      );
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

  /// Aggregate amount received for the invoice, including later installment
  /// settlements. Existing adapters can continue reading this field.
  final Money received;

  /// Amount entered when the Sales invoice itself was saved. Only this amount
  /// owns the invoice-level Cashbox source posting.
  final Money receivedAtSale;

  /// Sum of persisted installment settlements. Each entry owns a separate
  /// Cashbox source posting, preventing the invoice posting from double-counting
  /// later receipts.
  final Money installmentReceived;
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

  SalesInvoice copyWith({
    int? documentNumber,
    BusinessDate? date,
    int? minuteOfDay,
    EntityId? customerId,
    EntityId? defaultWarehouseId,
    AppCurrency? currency,
    ExchangeRate? exchangeRate,
    SalesSettlementKind? settlementKind,
    Iterable<SalesInvoiceLine>? lines,
    Money? invoiceDiscount,
    Money? received,
    Money? receivedAtSale,
    Money? installmentReceived,
    String? customerNameSnapshot,
    String? searchDetailsSnapshot,
    Money? balanceAfterInvoice,
    String? driverName,
    String? notes,
  }) {
    final resolvedCurrency = currency ?? this.currency;
    final changingCurrency = resolvedCurrency != this.currency;
    final resolvedInstallmentReceived = installmentReceived ??
        (changingCurrency
            ? Money.zero(resolvedCurrency)
            : this.installmentReceived);
    final resolvedReceivedAtSale = receivedAtSale ??
        (changingCurrency ? Money.zero(resolvedCurrency) : this.receivedAtSale);
    final resolvedReceived = received ??
        (resolvedReceivedAtSale.currency == resolvedCurrency &&
                resolvedInstallmentReceived.currency == resolvedCurrency
            ? resolvedReceivedAtSale + resolvedInstallmentReceived
            : this.received);
    return SalesInvoice(
      id: id,
      documentNumber: documentNumber ?? this.documentNumber,
      date: date ?? this.date,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      customerId: customerId ?? this.customerId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      currency: resolvedCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      settlementKind: settlementKind ?? this.settlementKind,
      lines: lines ?? this.lines,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      received: resolvedReceived,
      receivedAtSale: resolvedReceivedAtSale,
      installmentReceived: resolvedInstallmentReceived,
      customerNameSnapshot:
          customerNameSnapshot ?? this.customerNameSnapshot,
      searchDetailsSnapshot:
          searchDetailsSnapshot ?? this.searchDetailsSnapshot,
      balanceAfterInvoice: balanceAfterInvoice ?? this.balanceAfterInvoice,
      driverName: driverName ?? this.driverName,
      notes: notes ?? this.notes,
    );
  }
}
