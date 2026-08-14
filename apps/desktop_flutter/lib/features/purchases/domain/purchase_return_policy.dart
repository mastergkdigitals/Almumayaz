import '../../../core/domain/business_values.dart';
import '../../../core/domain/invoice_value_allocator.dart';
import 'purchase_invoice.dart';

/// Deterministic financial policy for a linked purchase return.
///
/// Merchandise prices and discounts come from the source invoice. Purchase
/// expenses are deliberately excluded because they are landed costs, not
/// merchandise refundable by the supplier. Inventory valuation is separate:
/// the inventory-cost repository issues returned stock at the warehouse's
/// moving average at the return timestamp.
abstract final class PurchaseReturnPolicy {
  static Money lineDiscount({
    required PurchaseInvoiceLine sourceLine,
    required int totalReturnedQuantity,
    required Money discountAlreadyReturned,
  }) {
    if (discountAlreadyReturned.currency != sourceLine.purchasePrice.currency) {
      throw ArgumentError('Return discount currency must match source line');
    }
    if (totalReturnedQuantity < 0 ||
        totalReturnedQuantity > sourceLine.quantity.value) {
      throw ArgumentError.value(
        totalReturnedQuantity,
        'totalReturnedQuantity',
      );
    }
    final target = multiplyDivideAndRoundHalfAwayFromZero(
      sourceLine.lineDiscount.minorUnits,
      totalReturnedQuantity,
      sourceLine.quantity.value,
    );
    final result = target - discountAlreadyReturned.minorUnits;
    if (result < 0) {
      throw StateError('Previously returned line discount is inconsistent');
    }
    return Money.fromMinorUnits(result, sourceLine.purchasePrice.currency);
  }

  static Money invoiceDiscount({
    required PurchaseInvoice source,
    required Map<EntityId, int> totalReturnedQuantities,
    required Money discountAlreadyReturned,
  }) {
    if (discountAlreadyReturned.currency != source.currency) {
      throw ArgumentError('Return discount currency must match source invoice');
    }
    final sourceSubtotal = source.subtotal.minorUnits;
    if (sourceSubtotal == 0) return Money.zero(source.currency);

    var returnedSubtotal = 0;
    for (final sourceLine in source.lines) {
      final returnedQuantity = totalReturnedQuantities[sourceLine.id] ?? 0;
      if (returnedQuantity < 0 ||
          returnedQuantity > sourceLine.quantity.value) {
        throw ArgumentError.value(
          returnedQuantity,
          'totalReturnedQuantities[${sourceLine.id.value}]',
        );
      }
      final cumulativeLineDiscount = multiplyDivideAndRoundHalfAwayFromZero(
        sourceLine.lineDiscount.minorUnits,
        returnedQuantity,
        sourceLine.quantity.value,
      );
      final returnedGross = multiplyDivideAndRoundHalfAwayFromZero(
        sourceLine.purchasePrice.minorUnits,
        returnedQuantity,
        1,
      );
      returnedSubtotal += returnedGross - cumulativeLineDiscount;
    }
    final refundableDiscount = source.invoiceDiscount.minorUnits >
            sourceSubtotal
        ? sourceSubtotal
        : source.invoiceDiscount.minorUnits;
    final target = multiplyDivideAndRoundHalfAwayFromZero(
      refundableDiscount,
      returnedSubtotal,
      sourceSubtotal,
    );
    final result = target - discountAlreadyReturned.minorUnits;
    if (result < 0) {
      throw StateError('Previously returned invoice discount is inconsistent');
    }
    return Money.fromMinorUnits(result, source.currency);
  }
}
