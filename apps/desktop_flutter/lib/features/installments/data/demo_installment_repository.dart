import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../sales/domain/sales_invoice.dart';
import '../domain/installment_plan.dart';
import '../domain/installment_repository.dart';
import 'demo_installment_mutation_effects.dart';

class DemoInstallmentRepository
    extends InMemoryDemoRepository<InstallmentPlan>
    implements InstallmentRepository {
  DemoInstallmentRepository({
    super.initialValues = const [],
    required DemoInstallmentMutationEffects mutationEffects,
    required Future<SalesInvoice?> Function(EntityId salesInvoiceId)
        salesInvoiceLoader,
  })  : _mutationEffects = mutationEffects,
        _salesInvoiceLoader = salesInvoiceLoader,
        super(
          idOf: (plan) => plan.id,
        ) {
    _validateOnePlanPerInvoice(createDemoSnapshot().values);
  }

  final DemoInstallmentMutationEffects _mutationEffects;
  final Future<SalesInvoice?> Function(EntityId salesInvoiceId)
      _salesInvoiceLoader;

  @override
  Future<InstallmentPlan?> getBySalesInvoiceId(
    EntityId salesInvoiceId,
  ) async {
    return getDemoPlanForSalesInvoice(salesInvoiceId);
  }

  @override
  Future<InstallmentPlan> settleEntry({
    required EntityId entryId,
    required AuditTimestamp paidAt,
    String notes = '',
  }) {
    return _mutationEffects.settleInstallment(
      entryId: entryId,
      paidAt: paidAt,
      notes: notes.trim(),
      preflightAndBuildSettlement: () async {
        final match = _locateEntry(entryId);
        if (match == null) throw StateError('القسط المحدد غير موجود');
        if (match.entry.isPaid) throw StateError('القسط مسدد مسبقاً');
        final updated = match.plan.markEntryPaid(
          entryId: entryId,
          paidAt: paidAt,
          notes: notes.trim(),
        );
        final salesInvoice = await _salesInvoiceLoader(
          match.plan.salesInvoiceId,
        );
        if (salesInvoice == null) {
          throw StateError('فاتورة البيع المرتبطة بخطة الأقساط غير موجودة');
        }
        return DemoInstallmentSettlement(
          previous: match.plan,
          updated: updated,
          paidEntry: updated.entryById(entryId)!,
          salesInvoice: salesInvoice,
        );
      },
      commit: (updated) {
        final staged = createDemoSnapshot()..[updated.id] = updated;
        commitDemoSnapshot(staged);
      },
    );
  }

  @override
  Future<InstallmentPlan> save(InstallmentPlan value) {
    throw StateError('تدار خطة الأقساط من خلال قائمة البيع');
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    return getDemoValue(id) == null
        ? const DeleteDecision.blocked('السجل غير موجود')
        : const DeleteDecision.blocked(
            'تدار خطة الأقساط من خلال قائمة البيع',
          );
  }

  @override
  Future<void> delete(EntityId id) {
    throw StateError('تدار خطة الأقساط من خلال قائمة البيع');
  }

  /// Synchronous read used only while the shared demo transaction is owned by
  /// the invoice/installment coordinator.
  InstallmentPlan? getDemoPlanForSalesInvoice(EntityId salesInvoiceId) {
    final matches = createDemoSnapshot().values.where(
          (plan) => plan.salesInvoiceId == salesInvoiceId,
        );
    if (matches.length > 1) {
      throw StateError('توجد أكثر من خطة أقساط لقائمة البيع نفسها');
    }
    return matches.isEmpty ? null : matches.single;
  }

  Map<EntityId, InstallmentPlan> stageUpsertPlan(InstallmentPlan plan) {
    final staged = createDemoSnapshot();
    final owned = staged.values.where(
      (candidate) =>
          candidate.salesInvoiceId == plan.salesInvoiceId &&
          candidate.id != plan.id,
    );
    if (owned.isNotEmpty) {
      throw StateError('قائمة البيع مرتبطة بخطة أقساط أخرى');
    }
    staged[plan.id] = plan;
    _validateOnePlanPerInvoice(staged.values);
    return staged;
  }

  Map<EntityId, InstallmentPlan> stageRemoveForSalesInvoice(
    EntityId salesInvoiceId,
  ) {
    final staged = createDemoSnapshot();
    staged.removeWhere(
      (_, plan) => plan.salesInvoiceId == salesInvoiceId,
    );
    return staged;
  }

  void commitInstallmentSnapshot(
    Map<EntityId, InstallmentPlan> staged,
  ) {
    commitDemoSnapshot(staged);
  }

  ({InstallmentPlan plan, InstallmentEntry entry})? _locateEntry(
    EntityId entryId,
  ) {
    ({InstallmentPlan plan, InstallmentEntry entry})? match;
    for (final plan in createDemoSnapshot().values) {
      final entry = plan.entryById(entryId);
      if (entry == null) continue;
      if (match != null) {
        throw StateError('معرف القسط مستخدم في أكثر من خطة');
      }
      match = (plan: plan, entry: entry);
    }
    return match;
  }

  static void _validateOnePlanPerInvoice(
    Iterable<InstallmentPlan> plans,
  ) {
    final invoiceIds = <EntityId>{};
    final entryIds = <EntityId>{};
    for (final plan in plans) {
      if (!invoiceIds.add(plan.salesInvoiceId)) {
        throw ArgumentError('A Sales invoice can own only one plan');
      }
      for (final entry in plan.entries) {
        if (!entryIds.add(entry.id)) {
          throw ArgumentError('Installment entry IDs must be globally unique');
        }
      }
    }
  }
}
