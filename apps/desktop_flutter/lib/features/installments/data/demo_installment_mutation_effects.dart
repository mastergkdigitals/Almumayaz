import '../../../core/domain/business_values.dart';
import '../../sales/domain/sales_invoice.dart';
import '../domain/installment_plan.dart';

class DemoInstallmentSettlement {
  const DemoInstallmentSettlement({
    required this.previous,
    required this.updated,
    required this.paidEntry,
    required this.salesInvoice,
  });

  final InstallmentPlan previous;
  final InstallmentPlan updated;
  final InstallmentEntry paidEntry;
  final SalesInvoice salesInvoice;
}

/// Demo transaction boundary used by the demo installment repository.
///
/// The implementation owns the shared runner and stages the Sales, Party and
/// Cashbox projections before invoking the synchronous [commit] callback.
abstract interface class DemoInstallmentMutationEffects {
  Future<InstallmentPlan> settleInstallment({
    required EntityId entryId,
    required AuditTimestamp paidAt,
    required String notes,
    required Future<DemoInstallmentSettlement> Function()
        preflightAndBuildSettlement,
    required void Function(InstallmentPlan updated) commit,
  });
}
