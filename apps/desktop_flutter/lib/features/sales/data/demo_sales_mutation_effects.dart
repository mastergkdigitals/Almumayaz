import '../../../core/domain/business_values.dart';
import '../domain/sales_invoice.dart';

/// Demo-only transaction boundary used by [DemoSalesRepository].
///
/// [preflightAndLoadPrevious] runs inside the shared transaction runner. It
/// must validate references, identity, and document-number availability and
/// returns the record being replaced, or null for a create. [commit] is called
/// only after every cross-feature effect has been staged successfully and must
/// be synchronous and no-fail.
abstract interface class DemoSalesMutationEffects {
  Future<SalesInvoice> applySale({
    required SalesInvoice candidate,
    required Future<SalesInvoice?> Function() preflightAndLoadPrevious,
    required void Function(SalesInvoice normalized) commit,
  });

  Future<void> deleteSale({
    required EntityId id,
    required Future<SalesInvoice> Function() preflightAndLoadPrevious,
    required void Function() commit,
  });
}
