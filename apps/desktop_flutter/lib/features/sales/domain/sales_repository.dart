import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'sales_invoice.dart';

abstract interface class SalesRepository
    implements AppRepository<SalesInvoice> {
  Future<List<SalesInvoice>> search(String query);

  Future<int> nextDocumentNumber();

  Future<SalesInvoice> createInvoice(SalesInvoice invoice);

  /// API adapters must reverse the previous effects and apply [invoice]
  /// atomically. Demo adapters validate fully before replacing the record.
  Future<SalesInvoice> replaceInvoice(SalesInvoice invoice);

  /// Permanently removes the invoice without making its number reusable.
  /// Audit retention belongs to the application transaction coordinator.
  Future<void> deleteInvoicePermanently(EntityId id);
}
