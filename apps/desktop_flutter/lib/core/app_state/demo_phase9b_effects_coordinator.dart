import '../../features/audit_log/data/demo_business_audit.dart';
import '../../features/audit_log/domain/audit_models.dart';
import '../../features/cashbox/data/demo_cashbox_repository.dart';
import '../../features/cashbox/domain/cashbox_voucher.dart';
import '../../features/expenses/data/demo_expense_mutation_effects.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/installments/application/installment_schedule_builder.dart';
import '../../features/installments/data/demo_installment_repository.dart';
import '../../features/installments/domain/installment_plan.dart';
import '../../features/parties/data/demo_party_repository.dart';
import '../../features/parties/domain/party.dart';
import '../../features/permissions/domain/permission_models.dart';
import '../../features/sales/data/demo_sales_repository.dart';
import '../../features/sales/domain/sales_invoice.dart';
import '../../features/sales_returns/data/demo_sales_return_mutation_effects.dart';
import '../../features/sales_returns/data/demo_sales_return_repository.dart';
import '../../features/sales_returns/domain/sales_return.dart';
import '../../features/warehouses/data/demo_inventory_cost_repository.dart';
import '../../features/warehouses/data/demo_warehouse_repository.dart';
import '../data/demo_transaction_runner.dart';
import '../domain/business_values.dart';

/// Owns the cross-feature, no-fail commit boundary for Phase 9B workflows.
///
/// Repositories normalize and validate their authoritative aggregates inside
/// this coordinator's shared runner. Every derived projection is then staged
/// before the aggregate, inventory, cost, Party, Cashbox, installment plan,
/// and audit journal become visible together.
class DemoPhase9bEffectsCoordinator
    implements DemoSalesReturnMutationEffects, DemoExpenseMutationEffects {
  const DemoPhase9bEffectsCoordinator({
    required DemoTransactionRunner transactionRunner,
    required DemoPartyRepository parties,
    required DemoWarehouseRepository warehouses,
    required DemoCashboxRepository cashbox,
    required DemoInventoryCostRepository inventoryCosts,
    required DemoSalesRepository Function() sales,
    required DemoSalesReturnRepository Function() salesReturns,
    required DemoInstallmentRepository Function() installments,
    DemoBusinessAudit? businessAudit,
  })  : _transactionRunner = transactionRunner,
        _parties = parties,
        _warehouses = warehouses,
        _cashbox = cashbox,
        _inventoryCosts = inventoryCosts,
        _sales = sales,
        _salesReturns = salesReturns,
        _installments = installments,
        _businessAudit = businessAudit;

  final DemoTransactionRunner _transactionRunner;
  final DemoPartyRepository _parties;
  final DemoWarehouseRepository _warehouses;
  final DemoCashboxRepository _cashbox;
  final DemoInventoryCostRepository _inventoryCosts;
  final DemoSalesRepository Function() _sales;
  final DemoSalesReturnRepository Function() _salesReturns;
  final DemoInstallmentRepository Function() _installments;
  final DemoBusinessAudit? _businessAudit;

  @override
  Future<SalesReturn> applySalesReturn({
    required Future<DemoSalesReturnMutation> Function()
        preflightAndBuildMutation,
    required void Function(SalesReturn normalized) commit,
  }) {
    return _transactionRunner.run(() async {
      final mutation = await preflightAndBuildMutation();
      final previous = mutation.previous;
      final candidate = mutation.candidate;
      if (previous != null &&
          previous.originalSalesInvoiceId !=
              candidate.originalSalesInvoiceId) {
        throw StateError('لا يمكن تغيير قائمة البيع الأصلية للمرتجع');
      }
      final sourceInvoice =
          await _sales().getById(candidate.originalSalesInvoiceId);
      if (sourceInvoice == null) {
        throw StateError('قائمة البيع الأصلية للمرتجع غير موجودة');
      }

      final stagedCosts = _inventoryCosts.stageSalesReturn(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: candidate,
      );
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        [
          if (previous != null)
            for (final line in previous.lines)
              DemoInventoryAdjustment(
                warehouseId: line.warehouseId,
                itemId: line.itemId,
                quantityDelta: -line.quantity.value,
              ),
          for (final line in candidate.lines)
            DemoInventoryAdjustment(
              warehouseId: line.warehouseId,
              itemId: line.itemId,
              quantityDelta: line.quantity.value,
            ),
        ],
        allowNegative: false,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        if (previous != null)
          DemoPartyBalanceAdjustment(
            partyId: previous.customerId,
            delta: previous.creditedToCustomer,
          ),
        DemoPartyBalanceAdjustment(
          partyId: candidate.customerId,
          delta: -candidate.creditedToCustomer,
        ),
      ]);
      final stagedCashbox = await _cashbox.stageSystemPosting(
        _salesReturnPosting(candidate),
      );
      final finalParty = stagedParties[candidate.customerId]!;
      final normalized = candidate.copyWith(
        balanceAfterReturn: _partyBalance(finalParty, candidate.currency),
      );
      final installmentRepository = _installments();
      final stagedInstallments = _stageInstallmentsAfterReturnChange(
        repository: installmentRepository,
        sourceInvoice: sourceInvoice,
        proposedReturns: [
          ..._salesReturns().getDemoReturnsForInvoice(
            sourceInvoice.id,
            excludingReturnId: previous?.id,
          ),
          normalized,
        ],
      );
      final isCreate = previous == null;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: isCreate ? AuditAction.create : AuditAction.update,
          outcome: AuditOutcome.success,
          summary: isCreate
              ? 'إضافة مرتجع البيع رقم ${normalized.documentNumber}'
              : 'تحديث مرتجع البيع رقم ${normalized.documentNumber}',
          before: previous == null
              ? const <String, Object?>{}
              : salesReturnAuditSnapshot(previous),
          after: salesReturnAuditSnapshot(normalized),
          details: {
            'originalSalesInvoiceId': sourceInvoice.id.value,
            'inventoryLineCount': normalized.lines.length,
            'partyId': normalized.customerId.value,
            'cashboxSourceId': normalized.id.value,
            'installmentPlanId': stagedInstallments.values
                .where((plan) => plan.salesInvoiceId == sourceInvoice.id)
                .firstOrNull
                ?.id
                .value,
          },
          entityType: 'sales_return',
          entityId: normalized.id,
        ),
        permission: PermissionCode(
          module: 'sales',
          action:
              isCreate ? PermissionAction.create : PermissionAction.update,
        ),
      );

      commit(normalized);
      _warehouses.commitInventorySnapshot(stagedInventory);
      _inventoryCosts.commitSnapshot(stagedCosts);
      _parties.commitPartySnapshot(stagedParties);
      _cashbox.commitCashboxMutation(stagedCashbox);
      installmentRepository.commitInstallmentSnapshot(stagedInstallments);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return normalized;
    });
  }

  @override
  Future<void> deleteSalesReturn({
    required Future<SalesReturn> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final sourceInvoice =
          await _sales().getById(previous.originalSalesInvoiceId);
      if (sourceInvoice == null) {
        throw StateError('قائمة البيع الأصلية للمرتجع غير موجودة');
      }
      final stagedCosts = _inventoryCosts.stageSalesReturn(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: null,
      );
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        [
          for (final line in previous.lines)
            DemoInventoryAdjustment(
              warehouseId: line.warehouseId,
              itemId: line.itemId,
              quantityDelta: -line.quantity.value,
            ),
        ],
        allowNegative: false,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        DemoPartyBalanceAdjustment(
          partyId: previous.customerId,
          delta: previous.creditedToCustomer,
        ),
      ]);
      final stagedCashbox = _cashbox.stageRemoveSystemPosting(
        _salesReturnSource(previous),
      );
      final installmentRepository = _installments();
      final stagedInstallments = _stageInstallmentsAfterReturnChange(
        repository: installmentRepository,
        sourceInvoice: sourceInvoice,
        proposedReturns: _salesReturns().getDemoReturnsForInvoice(
          sourceInvoice.id,
          excludingReturnId: previous.id,
        ),
      );
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف مرتجع البيع رقم ${previous.documentNumber}',
          before: salesReturnAuditSnapshot(previous),
          details: {
            'permanent': true,
            'originalSalesInvoiceId': sourceInvoice.id.value,
            'inventoryLineCount': previous.lines.length,
            'partyId': previous.customerId.value,
            'cashboxSourceId': previous.id.value,
          },
          entityType: 'sales_return',
          entityId: previous.id,
        ),
        permission: PermissionCode(
          module: 'sales',
          action: PermissionAction.delete,
        ),
      );

      commit();
      _warehouses.commitInventorySnapshot(stagedInventory);
      _inventoryCosts.commitSnapshot(stagedCosts);
      _parties.commitPartySnapshot(stagedParties);
      _cashbox.commitCashboxMutation(stagedCashbox);
      installmentRepository.commitInstallmentSnapshot(stagedInstallments);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  @override
  Future<Expense> applyExpense({
    required DemoExpenseMutationKind kind,
    required Future<DemoExpenseMutation> Function()
        preflightAndBuildMutation,
    required void Function(Expense normalized) commit,
  }) {
    return _transactionRunner.run(() async {
      final mutation = await preflightAndBuildMutation();
      final previous = mutation.previous;
      final candidate = mutation.candidate;
      final stagedParties = _parties.stageBalanceAdjustments([
        if (previous?.isUnpaid ?? false)
          DemoPartyBalanceAdjustment(
            partyId: previous!.supplierId!,
            delta: previous.amount,
          ),
        if (candidate.isUnpaid)
          DemoPartyBalanceAdjustment(
            partyId: candidate.supplierId!,
            delta: -candidate.amount,
          ),
      ]);
      final stagedCashbox = await _cashbox.stageSystemPosting(
        _expensePosting(candidate),
      );
      final auditAction = switch (kind) {
        DemoExpenseMutationKind.create => AuditAction.create,
        DemoExpenseMutationKind.update || DemoExpenseMutationKind.settle =>
          AuditAction.update,
      };
      final permissionAction = switch (kind) {
        DemoExpenseMutationKind.create => PermissionAction.create,
        DemoExpenseMutationKind.update || DemoExpenseMutationKind.settle =>
          PermissionAction.update,
      };
      final summary = switch (kind) {
        DemoExpenseMutationKind.create =>
          'إضافة المصروف رقم ${candidate.documentNumber}',
        DemoExpenseMutationKind.update =>
          'تحديث المصروف رقم ${candidate.documentNumber}',
        DemoExpenseMutationKind.settle =>
          'تسديد المصروف رقم ${candidate.documentNumber}',
      };
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: auditAction,
          outcome: AuditOutcome.success,
          summary: summary,
          before: previous == null
              ? const <String, Object?>{}
              : expenseAuditSnapshot(previous),
          after: expenseAuditSnapshot(candidate),
          details: {
            'supplierId': candidate.supplierId?.value,
            'cashboxSourceId': candidate.id.value,
            'operation': kind.name,
          },
          entityType: 'expense',
          entityId: candidate.id,
        ),
        permission: PermissionCode(
          module: 'expenses',
          action: permissionAction,
        ),
      );

      commit(candidate);
      _parties.commitPartySnapshot(stagedParties);
      _cashbox.commitCashboxMutation(stagedCashbox);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return candidate;
    });
  }

  @override
  Future<void> deleteExpense({
    required EntityId id,
    required Future<Expense> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      if (previous.id != id) throw StateError('معرف المصروف غير متطابق');
      final stagedParties = _parties.stageBalanceAdjustments([
        if (previous.isUnpaid)
          DemoPartyBalanceAdjustment(
            partyId: previous.supplierId!,
            delta: previous.amount,
          ),
      ]);
      final stagedCashbox = _cashbox.stageRemoveSystemPosting(
        _expenseSource(previous),
      );
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف المصروف رقم ${previous.documentNumber}',
          before: expenseAuditSnapshot(previous),
          details: {
            'permanent': true,
            'supplierId': previous.supplierId?.value,
            'cashboxSourceId': previous.id.value,
          },
          entityType: 'expense',
          entityId: previous.id,
        ),
        permission: PermissionCode(
          module: 'expenses',
          action: PermissionAction.delete,
        ),
      );

      commit();
      _parties.commitPartySnapshot(stagedParties);
      _cashbox.commitCashboxMutation(stagedCashbox);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  Map<EntityId, InstallmentPlan> _stageInstallmentsAfterReturnChange({
    required DemoInstallmentRepository repository,
    required SalesInvoice sourceInvoice,
    required Iterable<SalesReturn> proposedReturns,
  }) {
    final current = repository.getDemoPlanForSalesInvoice(sourceInvoice.id);
    if (sourceInvoice.settlementKind != SalesSettlementKind.installments) {
      if (current != null) {
        throw StateError('قائمة البيع غير المقسطة مرتبطة بخطة أقساط');
      }
      return repository.stageRemoveForSalesInvoice(sourceInvoice.id);
    }
    if (current == null) {
      throw StateError('خطة الأقساط المرتبطة بقائمة البيع غير موجودة');
    }
    final base = InstallmentScheduleBuilder.build(
      planId: current.id,
      salesInvoiceId: sourceInvoice.id,
      customerId: sourceInvoice.customerId,
      remaining: sourceInvoice.total - sourceInvoice.receivedAtSale,
      invoiceDate: sourceInvoice.date,
    );
    final credit = proposedReturns.fold(
      Money.zero(sourceInvoice.currency),
      (sum, salesReturn) => sum + salesReturn.creditedToCustomer,
    );
    final paidEntries = current.entries
        .where((entry) => entry.isPaid)
        .toList(growable: false);
    final paid = paidEntries.fold(
      Money.zero(sourceInvoice.currency),
      (sum, entry) => sum + entry.amount,
    );
    if (paid != sourceInvoice.installmentReceived) {
      throw StateError('سجل الأقساط المسدد لا يطابق المقبوض من القائمة');
    }
    var targetPending = base.total - paid - credit;
    if (targetPending.isNegative) {
      targetPending = Money.zero(sourceInvoice.currency);
    }

    final paidIds = {for (final entry in paidEntries) entry.id};
    final baseIds = {for (final entry in base.entries) entry.id};
    final pendingEntries = <InstallmentEntry>[
      for (final entry in base.entries)
        if (!paidIds.contains(entry.id)) entry,
      for (final entry in current.entries)
        if (!entry.isPaid && !baseIds.contains(entry.id)) entry,
    ];
    final pendingTotal = pendingEntries.fold(
      Money.zero(sourceInvoice.currency),
      (sum, entry) => sum + entry.amount,
    );
    if (pendingTotal.compareTo(targetPending) > 0) {
      var reduction = pendingTotal - targetPending;
      final adjusted = <InstallmentEntry>[];
      for (final entry in pendingEntries.reversed) {
        if (reduction.isZero) {
          adjusted.add(entry);
        } else if (reduction.compareTo(entry.amount) >= 0) {
          reduction = reduction - entry.amount;
        } else {
          adjusted.add(entry.copyWith(amount: entry.amount - reduction));
          reduction = Money.zero(sourceInvoice.currency);
        }
      }
      pendingEntries
        ..clear()
        ..addAll(adjusted.reversed);
    } else if (pendingTotal.compareTo(targetPending) < 0) {
      final increase = targetPending - pendingTotal;
      if (pendingEntries.isNotEmpty) {
        final last = pendingEntries.removeLast();
        pendingEntries.add(last.copyWith(amount: last.amount + increase));
      } else {
        final usedIds = {for (final entry in current.entries) entry.id};
        final maxNumber = [
          ...base.entries.map((entry) => entry.number),
          ...current.entries.map((entry) => entry.number),
        ].fold<int>(0, (highest, value) => value > highest ? value : highest);
        var number = maxNumber + 1;
        var id = EntityId('${current.id.value}-return-adjustment-$number');
        while (usedIds.contains(id)) {
          number++;
          id = EntityId('${current.id.value}-return-adjustment-$number');
        }
        pendingEntries.add(
          InstallmentEntry(
            id: id,
            number: number,
            dueDate: base.entries.last.dueDate,
            amount: increase,
          ),
        );
      }
    }
    final entries = [...paidEntries, ...pendingEntries]
      ..sort((first, second) => first.number.compareTo(second.number));
    return repository.stageUpsertPlan(
      InstallmentPlan(
        id: current.id,
        salesInvoiceId: current.salesInvoiceId,
        customerId: current.customerId,
        currency: current.currency,
        entries: entries,
      ),
    );
  }

  DemoSystemCashboxPosting _salesReturnPosting(SalesReturn value) {
    return DemoSystemCashboxPosting(
      source: _salesReturnSource(value),
      createdTimestamp: _timestamp(value.date, value.minuteOfDay),
      type: CashboxVoucherType.payment,
      exchangeRate: value.exchangeRate,
      amount: value.refundedAtReturn,
      notes: 'قيد آلي لمرتجع بيع رقم ${value.documentNumber} '
          'عن القائمة رقم ${value.originalSalesInvoiceNumberSnapshot}',
    );
  }

  CashboxVoucherSource _salesReturnSource(SalesReturn value) {
    return CashboxVoucherSource(
      kind: CashboxVoucherSourceKind.salesReturn,
      sourceId: value.id,
      partyId: value.customerId,
    );
  }

  DemoSystemCashboxPosting _expensePosting(Expense value) {
    return DemoSystemCashboxPosting(
      source: _expenseSource(value),
      createdTimestamp: value.paidAt ?? value.occurredAt,
      type: CashboxVoucherType.payment,
      exchangeRate: value.exchangeRate,
      amount: value.isPaid ? value.amount : Money.zero(value.amount.currency),
      notes: 'قيد آلي للمصروف رقم ${value.documentNumber}: '
          '${value.description}',
    );
  }

  CashboxVoucherSource _expenseSource(Expense value) {
    return CashboxVoucherSource(
      kind: CashboxVoucherSourceKind.expense,
      sourceId: value.id,
      partyId: value.supplierId,
    );
  }

  Money _partyBalance(Party party, AppCurrency currency) {
    return currency == AppCurrency.iqd
        ? party.iqdBalance
        : party.usdBalance;
  }
}

AuditTimestamp _timestamp(BusinessDate date, int minuteOfDay) {
  return AuditTimestamp(
    date.atTime(
      hour: minuteOfDay ~/ Duration.minutesPerHour,
      minute: minuteOfDay % Duration.minutesPerHour,
    ),
  );
}
