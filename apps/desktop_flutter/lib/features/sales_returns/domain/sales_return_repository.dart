import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/domain/invoice_value_allocator.dart';
import '../../sales/domain/sales_invoice.dart';
import 'sales_return.dart';

class SalesReturnableLine {
  SalesReturnableLine({
    required this.source,
    required this.previouslyReturned,
    required this.available,
    required this.sourceAllocatedRefund,
    required this.availableRefund,
  }) {
    if (previouslyReturned.value + available.value != source.quantity.value) {
      throw ArgumentError('Returnable quantities do not reconcile');
    }
    if (sourceAllocatedRefund.currency != source.unitPrice.currency ||
        availableRefund.currency != source.unitPrice.currency ||
        sourceAllocatedRefund.isNegative ||
        availableRefund.isNegative) {
      throw ArgumentError.value(availableRefund, 'availableRefund');
    }
    final previouslyAllocated =
        sourceAllocatedRefund.minorUnits - availableRefund.minorUnits;
    final expectedPreviouslyAllocated = previouslyReturned.value ==
            source.quantity.value
        ? sourceAllocatedRefund.minorUnits
        : multiplyDivideAndRoundHalfAwayFromZero(
            sourceAllocatedRefund.minorUnits,
            previouslyReturned.value,
            source.quantity.value,
          );
    if (previouslyAllocated != expectedPreviouslyAllocated) {
      throw ArgumentError('Returnable refund values do not reconcile');
    }
  }

  final SalesInvoiceLine source;
  final WholeQuantity previouslyReturned;
  final WholeQuantity available;
  final Money sourceAllocatedRefund;
  final Money availableRefund;

  /// Allocates the next refund from the original line value cumulatively.
  ///
  /// Basing every partial return on the original allocation makes the result
  /// independent of how earlier quantities were split across return documents.
  Money allocatedRefundFor(WholeQuantity requested) {
    if (requested.value > available.value) {
      throw ArgumentError.value(requested, 'requested', 'Exceeds available');
    }
    if (requested.isZero) return Money.zero(sourceAllocatedRefund.currency);

    final cumulativeQuantity = previouslyReturned.value + requested.value;
    final cumulativeTarget = cumulativeQuantity == source.quantity.value
        ? sourceAllocatedRefund.minorUnits
        : multiplyDivideAndRoundHalfAwayFromZero(
            sourceAllocatedRefund.minorUnits,
            cumulativeQuantity,
            source.quantity.value,
          );
    final previouslyAllocated =
        sourceAllocatedRefund.minorUnits - availableRefund.minorUnits;
    final result = cumulativeTarget - previouslyAllocated;
    if (result < 0 || result > availableRefund.minorUnits) {
      throw StateError('Returnable refund allocation is inconsistent');
    }
    return Money.fromMinorUnits(result, sourceAllocatedRefund.currency);
  }
}

class SalesReturnableSource {
  SalesReturnableSource({
    required this.invoice,
    required Iterable<SalesReturnableLine> lines,
  }) : lines = List.unmodifiable(lines);

  final SalesInvoice invoice;
  final List<SalesReturnableLine> lines;

  bool get hasAvailableQuantity => lines.any((line) => !line.available.isZero);
}

abstract interface class SalesReturnRepository
    implements AppRepository<SalesReturn> {
  Future<List<SalesReturn>> search(String query);

  /// Preview only. The create response remains authoritative.
  Future<int> nextDocumentNumber();

  Future<SalesReturnableSource> loadReturnableSource(
    EntityId originalSalesInvoiceId, {
    EntityId? excludingReturnId,
  });

  Future<SalesReturn> createReturn(SalesReturnSaveRequest request);

  Future<SalesReturn> replaceReturn(
    EntityId id,
    SalesReturnSaveRequest request,
  );

  Future<void> deleteReturnPermanently(EntityId id);

  Future<bool> hasReturnsForInvoice(EntityId originalSalesInvoiceId);
}
