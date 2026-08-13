import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'installment_plan.dart';

abstract interface class InstallmentRepository
    implements AppRepository<InstallmentPlan> {
  Future<InstallmentPlan?> getBySalesInvoiceId(EntityId salesInvoiceId);

  /// Settles one full installment. Implementations must reject a second
  /// settlement of the same entry and apply the Party/Cashbox effects in the
  /// same transaction as the plan update.
  Future<InstallmentPlan> settleEntry({
    required EntityId entryId,
    required AuditTimestamp paidAt,
    String notes = '',
  });
}
