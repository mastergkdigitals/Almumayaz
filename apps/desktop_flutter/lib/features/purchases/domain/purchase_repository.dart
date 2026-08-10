import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'purchase_invoice.dart';

abstract interface class PurchaseRepository
    implements AppRepository<PurchaseInvoice> {
  Future<List<PurchaseInvoice>> search(String query);

  Future<int> nextDocumentNumber();

  Future<PurchaseInvoice> createInvoice(PurchaseInvoice invoice);

  /// API adapters must reverse the previous effects and apply [invoice]
  /// atomically. Demo adapters validate fully before replacing the record.
  Future<PurchaseInvoice> replaceInvoice(PurchaseInvoice invoice);

  /// Permanently removes the invoice without making its number reusable.
  /// Audit retention belongs to the application transaction coordinator.
  Future<void> deleteInvoicePermanently(EntityId id);
}
