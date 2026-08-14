import '../../../core/domain/business_values.dart';

/// One persisted line in an independently numbered sales-return document.
///
/// Identity, item, warehouse and monetary snapshots are derived from the
/// linked sales line by the repository. A caller only chooses the source line
/// and a whole quantity through [SalesReturnLineRequest].
class SalesReturnLine {
  SalesReturnLine({
    required this.id,
    required this.sourceSalesLineId,
    required this.itemId,
    required this.warehouseId,
    required this.quantity,
    required this.sourceNetUnitPrice,
    required this.allocatedRefund,
    this.itemCodeSnapshot = '',
    this.itemNameSnapshot = '',
    this.warehouseNameSnapshot = '',
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    if (sourceNetUnitPrice.currency != allocatedRefund.currency ||
        sourceNetUnitPrice.isNegative ||
        allocatedRefund.isNegative) {
      throw ArgumentError('Sales-return line money is invalid');
    }
  }

  final EntityId id;
  final EntityId sourceSalesLineId;
  final EntityId itemId;
  final EntityId warehouseId;
  final WholeQuantity quantity;
  final Money sourceNetUnitPrice;

  /// Source-derived share of the original invoice value after both line and
  /// invoice discounts. This is authoritative for Party/refund effects.
  final Money allocatedRefund;
  final String itemCodeSnapshot;
  final String itemNameSnapshot;
  final String warehouseNameSnapshot;
}
class SalesReturn {
  SalesReturn({
    required this.id,
    required this.documentNumber,
    required this.date,
    required this.minuteOfDay,
    required this.originalSalesInvoiceId,
    required this.originalSalesInvoiceNumberSnapshot,
    required this.customerId,
    required this.currency,
    required this.exchangeRate,
    required Iterable<SalesReturnLine> lines,
    required this.refundedAtReturn,
    this.customerNameSnapshot = '',
    this.searchDetailsSnapshot = '',
    this.balanceAfterReturn,
    this.notes = '',
  }) : lines = List.unmodifiable(lines) {
    if (documentNumber < 1) {
      throw ArgumentError.value(documentNumber, 'documentNumber');
    }
    if (originalSalesInvoiceNumberSnapshot < 1) {
      throw ArgumentError.value(
        originalSalesInvoiceNumberSnapshot,
        'originalSalesInvoiceNumberSnapshot',
      );
    }
    if (minuteOfDay < 0 ||
        minuteOfDay >= Duration.hoursPerDay * Duration.minutesPerHour) {
      throw ArgumentError.value(minuteOfDay, 'minuteOfDay');
    }
    if (this.lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'At least one line is required');
    }
    if ({for (final line in this.lines) line.id}.length != this.lines.length ||
        {for (final line in this.lines) line.sourceSalesLineId}.length !=
            this.lines.length) {
      throw ArgumentError('Sales-return line identities must be unique');
    }
    if (this.lines.any(
      (line) => line.allocatedRefund.currency != currency,
    )) {
      throw ArgumentError('Sales-return lines must use the document currency');
    }
    if (refundedAtReturn.currency != currency ||
        refundedAtReturn.isNegative ||
        refundedAtReturn.compareTo(total) > 0) {
      throw ArgumentError.value(
        refundedAtReturn,
        'refundedAtReturn',
        'Invalid cash refund',
      );
    }
    if (balanceAfterReturn != null &&
        balanceAfterReturn!.currency != currency) {
      throw ArgumentError.value(balanceAfterReturn, 'balanceAfterReturn');
    }
  }

  final EntityId id;
  final int documentNumber;
  final BusinessDate date;
  final int minuteOfDay;
  final EntityId originalSalesInvoiceId;
  final int originalSalesInvoiceNumberSnapshot;
  final EntityId customerId;
  final AppCurrency currency;
  final ExchangeRate exchangeRate;
  final List<SalesReturnLine> lines;
  final Money refundedAtReturn;
  final String customerNameSnapshot;
  final String searchDetailsSnapshot;
  final Money? balanceAfterReturn;
  final String notes;

  Money get total => lines.fold(
        Money.zero(currency),
        (sum, line) => sum + line.allocatedRefund,
      );

  Money get creditedToCustomer => total - refundedAtReturn;

  SalesReturn copyWith({
    BusinessDate? date,
    int? minuteOfDay,
    Iterable<SalesReturnLine>? lines,
    Money? refundedAtReturn,
    String? customerNameSnapshot,
    String? searchDetailsSnapshot,
    Money? balanceAfterReturn,
    String? notes,
  }) {
    return SalesReturn(
      id: id,
      documentNumber: documentNumber,
      date: date ?? this.date,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      originalSalesInvoiceId: originalSalesInvoiceId,
      originalSalesInvoiceNumberSnapshot:
          originalSalesInvoiceNumberSnapshot,
      customerId: customerId,
      currency: currency,
      exchangeRate: exchangeRate,
      lines: lines ?? this.lines,
      refundedAtReturn: refundedAtReturn ?? this.refundedAtReturn,
      customerNameSnapshot:
          customerNameSnapshot ?? this.customerNameSnapshot,
      searchDetailsSnapshot:
          searchDetailsSnapshot ?? this.searchDetailsSnapshot,
      balanceAfterReturn: balanceAfterReturn ?? this.balanceAfterReturn,
      notes: notes ?? this.notes,
    );
  }
}

class SalesReturnLineRequest {
  SalesReturnLineRequest({
    required this.sourceSalesLineId,
    required this.quantity,
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
  }

  final EntityId sourceSalesLineId;
  final WholeQuantity quantity;
}

/// API-ready write command: all reference snapshots and amounts are derived
/// by the repository/server from the authoritative original invoice.
class SalesReturnSaveRequest {
  SalesReturnSaveRequest({
    required this.originalSalesInvoiceId,
    required this.date,
    required this.minuteOfDay,
    required Iterable<SalesReturnLineRequest> lines,
    required this.refundedAtReturn,
    String notes = '',
  })  : lines = List.unmodifiable(lines),
        notes = notes.trim() {
    if (minuteOfDay < 0 ||
        minuteOfDay >= Duration.hoursPerDay * Duration.minutesPerHour) {
      throw ArgumentError.value(minuteOfDay, 'minuteOfDay');
    }
    if (this.lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'At least one line is required');
    }
    if (refundedAtReturn.isNegative) {
      throw ArgumentError.value(refundedAtReturn, 'refundedAtReturn');
    }
  }

  final EntityId originalSalesInvoiceId;
  final BusinessDate date;
  final int minuteOfDay;
  final List<SalesReturnLineRequest> lines;
  final Money refundedAtReturn;
  final String notes;
}
