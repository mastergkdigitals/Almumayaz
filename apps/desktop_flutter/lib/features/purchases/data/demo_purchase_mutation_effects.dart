import '../../../core/domain/business_values.dart';
import '../domain/purchase_invoice.dart';

/// Demo-only transaction boundary used by [DemoPurchaseRepository].
///
/// [preflightAndLoadPrevious] runs inside the shared transaction runner. It
/// must validate references, identity, and document-number availability and
/// returns the record being replaced, or null for a create. [commit] is called
/// only after every cross-feature effect has been staged successfully and must
/// be synchronous and no-fail.
abstract interface class DemoPurchaseMutationEffects {
  Future<PurchaseInvoice> applyPurchase({
    required PurchaseInvoice candidate,
    required Future<PurchaseInvoice?> Function() preflightAndLoadPrevious,
    required void Function(PurchaseInvoice normalized) commit,
  });

  Future<void> deletePurchase({
    required EntityId id,
    required Future<PurchaseInvoice> Function() preflightAndLoadPrevious,
    required void Function() commit,
  });
}
