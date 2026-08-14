import '../../../core/domain/business_values.dart';

enum PurchaseTransactionKind { local, import, returnPurchase }

enum PurchaseSettlementKind { cash, credit }

class PurchaseInvoiceLine {
  PurchaseInvoiceLine({
    required this.id,
    required this.itemId,
    required this.warehouseId,
    required this.quantity,
    required this.containerQuantity,
    required this.purchasePrice,
    required this.lineDiscount,
    required this.salePrice,
    this.originalPurchaseLineId,
    this.itemCodeSnapshot = '',
    this.itemNameSnapshot = '',
    this.warehouseNameSnapshot = '',
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    if (purchasePrice.isNegative ||
        salePrice.isNegative ||
        lineDiscount.currency != purchasePrice.currency ||
        salePrice.currency != purchasePrice.currency ||
        lineDiscount.isNegative ||
        lineDiscount.compareTo(grossTotal) > 0) {
      throw ArgumentError('Purchase line values are invalid');
    }
  }

  final EntityId id;
  final EntityId itemId;
  final EntityId warehouseId;
  final WholeQuantity quantity;
  final WholeQuantity containerQuantity;
  final Money purchasePrice;
  final Money lineDiscount;
  final Money salePrice;

  /// Source line for a linked purchase return.
  ///
  /// Normal purchase lines keep this null. Demo and API repositories are the
  /// authoritative boundary that requires and validates it for returns.
  final EntityId? originalPurchaseLineId;
  final String itemCodeSnapshot;
  final String itemNameSnapshot;
  final String warehouseNameSnapshot;

  Money get grossTotal => purchasePrice * quantity.value;

  Money get netTotal => grossTotal - lineDiscount;
}

class PurchaseInvoice {
  PurchaseInvoice({
    required this.id,
    required this.documentNumber,
    required this.date,
    required this.minuteOfDay,
    required this.supplierId,
    required this.defaultWarehouseId,
    required this.currency,
    required this.exchangeRate,
    required this.purchaseKind,
    required this.settlementKind,
    required Iterable<PurchaseInvoiceLine> lines,
    required this.expenses,
    required this.invoiceDiscount,
    required this.paid,
    this.originalPurchaseInvoiceId,
    this.supplierNameSnapshot = '',
    this.searchDetailsSnapshot = '',
    this.balanceAfterInvoice,
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
      (line) => line.purchasePrice.currency != currency,
    )) {
      throw ArgumentError('Purchase lines must use the invoice currency');
    }
    if (expenses.currency != currency ||
        invoiceDiscount.currency != currency ||
        expenses.isNegative ||
        invoiceDiscount.isNegative) {
      throw ArgumentError('Purchase adjustments are invalid');
    }
    final discountBase = subtotal + expenses;
    if (invoiceDiscount.compareTo(discountBase) > 0) {
      throw ArgumentError.value(
        invoiceDiscount,
        'invoiceDiscount',
        'Discount must not exceed the invoice subtotal and expenses',
      );
    }
    if (paid.currency != currency ||
        paid.isNegative ||
        paid.compareTo(total) > 0) {
      throw ArgumentError.value(paid, 'paid', 'Invalid paid value');
    }
    if (settlementKind == PurchaseSettlementKind.cash && paid != total) {
      throw ArgumentError.value(
        paid,
        'paid',
        'Cash invoices must be paid in full',
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
  final EntityId supplierId;
  final EntityId defaultWarehouseId;
  final AppCurrency currency;
  final ExchangeRate exchangeRate;
  final PurchaseTransactionKind purchaseKind;
  final PurchaseSettlementKind settlementKind;
  final List<PurchaseInvoiceLine> lines;
  final Money expenses;
  final Money invoiceDiscount;
  final Money paid;

  /// Source invoice for a linked purchase return.
  ///
  /// Kept nullable at the value-object boundary for compatibility with normal
  /// purchases. Repositories reject unlinked return mutations.
  final EntityId? originalPurchaseInvoiceId;
  final String supplierNameSnapshot;
  final String searchDetailsSnapshot;
  final Money? balanceAfterInvoice;
  final String notes;

  bool get isReturn =>
      purchaseKind == PurchaseTransactionKind.returnPurchase;

  Money get subtotal => lines.fold(
        Money.zero(currency),
        (total, line) => total + line.netTotal,
      );

  Money get total => subtotal + expenses - invoiceDiscount;

  num get invoiceDiscountPercentageValue {
    final base = subtotal + expenses;
    if (base.isZero) return 0;
    return invoiceDiscount.minorUnits * 100 / base.minorUnits;
  }
}
