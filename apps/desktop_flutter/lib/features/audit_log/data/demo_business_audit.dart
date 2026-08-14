import '../../../core/domain/business_values.dart';
import '../../authentication/data/demo_identity_state.dart';
import '../../authentication/domain/session_models.dart';
import '../../cashbox/domain/cashbox_voucher.dart';
import '../../expenses/domain/expense.dart';
import '../../installments/domain/installment_plan.dart';
import '../../items/domain/item.dart';
import '../../parties/domain/party.dart';
import '../../parties/domain/party_repository.dart';
import '../../permissions/domain/permission_models.dart';
import '../../purchases/domain/purchase_invoice.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../sales_returns/domain/sales_return.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/settings_models.dart';
import '../../warehouses/domain/inventory_records.dart';
import '../../warehouses/domain/warehouse.dart';
import '../domain/audit_models.dart';

/// Immutable actor/session context captured before a demo workflow starts.
///
/// Repository mutations normally append while owning the shared transaction
/// runner, so [captureContext] and [append] cannot race a session transition.
/// Output adapters may retain this value across an external await and still
/// attribute the result to the user who initiated it.
class DemoAuditContext {
  const DemoAuditContext({
    required this.actor,
    this.sessionId,
    this.sessionState,
  });

  final AuditActor actor;
  final EntityId? sessionId;
  final SessionState? sessionState;
}

/// Fully validated event envelope waiting for the business commit.
///
/// Preparing first makes snapshot/permission validation part of preflight;
/// [DemoBusinessAudit.appendPrepared] is then the only synchronous journal
/// insertion performed after the business projections become visible.
class DemoPreparedBusinessAudit {
  const DemoPreparedBusinessAudit._(this.record);

  final AuditRecord record;
}

/// Synchronous, no-fail audit commit used inside staged demo transactions.
///
/// All event construction and snapshot generation must finish before the
/// business projections commit. Preparation also allocates deterministic
/// metadata, so appending only inserts the immutable record into the journal.
class DemoBusinessAudit {
  const DemoBusinessAudit({required DemoIdentityState state}) : _state = state;

  final DemoIdentityState _state;

  DemoAuditContext captureContext() {
    final session = _state.currentSession;
    final user = session == null ? null : _state.usersById[session.userId];
    return DemoAuditContext(
      actor: user == null
          ? const AuditActor(userId: null, username: 'system')
          : AuditActor(userId: user.id, username: user.username),
      sessionId: session?.id,
      sessionState: session?.state,
    );
  }

  AuditRecord append({
    required AuditEvent event,
    required PermissionCode permission,
    DemoAuditContext? context,
  }) {
    return appendPrepared(
      prepare(
        event: event,
        permission: permission,
        context: context,
      ),
    );
  }

  DemoPreparedBusinessAudit prepare({
    required AuditEvent event,
    required PermissionCode permission,
    DemoAuditContext? context,
  }) {
    final resolvedContext = context ?? captureContext();
    final details = <String, Object?>{
      ...event.details,
      'permission': permission.value,
      if (resolvedContext.sessionId != null)
        'sessionId': resolvedContext.sessionId!.value,
      if (resolvedContext.sessionState != null)
        'sessionState': resolvedContext.sessionState!.name,
    };
    return DemoPreparedBusinessAudit._(
      _state.prepareAudit(
        actorUserId: event.actor?.userId ?? resolvedContext.actor.userId,
        actorUsername:
            event.actor?.username ?? resolvedContext.actor.username,
        action: event.action,
        outcome: event.outcome,
        summary: event.summary,
        details: details,
        before: event.before,
        after: event.after,
        entityType: event.entityType,
        entityId: event.entityId,
      ),
    );
  }

  AuditRecord appendPrepared(DemoPreparedBusinessAudit prepared) {
    return _state.commitPreparedAudit(prepared.record);
  }
}

Map<String, Object?> partyAuditSnapshot(
  Party value, {
  PartyMasterDataReferences? references,
}) =>
    <String, Object?>{
      'id': value.entityId.value,
      'number': value.number,
      'createdAt': value.createdTimestamp.toString(),
      'name': value.name,
      'type': value.type.name,
      'workplaceId': references?.workplaceId?.value,
      'workplace': value.workplace,
      'branchId': references?.branchId?.value,
      'branch': value.branch,
      'phone': value.phone,
      'alternatePhone': value.alternatePhone,
      'city': value.city,
      'address': value.address,
      'notes': value.notes,
      ..._moneySnapshot('iqdBalance', value.iqdBalance),
      ..._moneySnapshot('usdBalance', value.usdBalance),
    };

Map<String, Object?> itemAuditSnapshot(Item value) => <String, Object?>{
      'id': value.entityId.value,
      'code': value.code,
      'name': value.name,
      'barcode': value.barcode,
      'groupId': value.groupEntityId.value,
      'groupName': value.groupName,
      'typeId': value.typeEntityId.value,
      'typeName': value.typeName,
      ..._moneySnapshot('iqdSalePrice', value.iqdSalePrice),
      ..._moneySnapshot('usdSalePrice', value.usdSalePrice),
      'notes': value.notes,
    };

Map<String, Object?> warehouseAuditSnapshot(Warehouse value) =>
    <String, Object?>{
      'id': value.entityId.value,
      'number': value.number,
      'name': value.name,
      'location': value.location,
      'notes': value.notes,
      'isMain': value.isMain,
    };

Map<String, Object?> transferAuditSnapshot(InventoryTransfer value) {
  final result = <String, Object?>{
    'id': value.id.value,
    'documentNumber': value.documentNumber,
    'createdAt': value.createdAt.toString(),
    'fromWarehouseId': value.fromWarehouseId.value,
    'toWarehouseId': value.toWarehouseId.value,
    'reversalOfId': value.reversalOfId?.value,
    'lineCount': value.lines.length,
  };
  for (var index = 0; index < value.lines.length; index++) {
    final line = value.lines[index];
    result
      ..['line.$index.itemId'] = line.itemId.value
      ..['line.$index.quantity'] = line.quantity.value;
  }
  return result;
}

Map<String, Object?> cashboxVoucherAuditSnapshot(CashboxVoucher value) =>
    <String, Object?>{
      'id': value.entityId.value,
      'number': value.number,
      'createdAt': value.createdTimestamp.toString(),
      'type': value.type.name,
      'mainAccountId': value.mainAccountEntityId.value,
      'mainAccountLabel': value.mainAccountLabel,
      'subaccountId': value.subaccountEntityId.value,
      'subaccountLabel': value.subaccountLabel,
      'exchangeRateTenThousandths': value.exchangeRateValue.tenThousandths,
      ..._moneySnapshot('iqdAmount', value.iqdAmount),
      ..._moneySnapshot('usdAmount', value.usdAmount),
      ..._moneySnapshot('iqdBalanceBefore', value.iqdBalanceBefore),
      ..._moneySnapshot('iqdBalanceAfter', value.iqdBalanceAfter),
      ..._moneySnapshot('usdBalanceBefore', value.usdBalanceBefore),
      ..._moneySnapshot('usdBalanceAfter', value.usdBalanceAfter),
      'notes': value.notes,
      'sourceKind': value.source?.kind.name,
      'sourceId': value.source?.sourceId.value,
      'sourcePartyId': value.source?.partyId?.value,
    };

Map<String, Object?> salesInvoiceAuditSnapshot(SalesInvoice value) {
  final result = <String, Object?>{
    'id': value.id.value,
    'documentNumber': value.documentNumber,
    'date': value.date.toString(),
    'minuteOfDay': value.minuteOfDay,
    'customerId': value.customerId.value,
    'customerNameSnapshot': value.customerNameSnapshot,
    'defaultWarehouseId': value.defaultWarehouseId.value,
    'currency': value.currency.code,
    'exchangeRateTenThousandths': value.exchangeRate.tenThousandths,
    'settlementKind': value.settlementKind.name,
    ..._moneySnapshot('invoiceDiscount', value.invoiceDiscount),
    ..._moneySnapshot('received', value.received),
    ..._moneySnapshot('receivedAtSale', value.receivedAtSale),
    ..._moneySnapshot('installmentReceived', value.installmentReceived),
    if (value.balanceAfterInvoice != null)
      ..._moneySnapshot('balanceAfterInvoice', value.balanceAfterInvoice!),
    'driverName': value.driverName,
    'notes': value.notes,
    'searchDetailsSnapshot': value.searchDetailsSnapshot,
    'lineCount': value.lines.length,
  };
  for (var index = 0; index < value.lines.length; index++) {
    final line = value.lines[index];
    result
      ..['line.$index.id'] = line.id.value
      ..['line.$index.itemId'] = line.itemId.value
      ..['line.$index.warehouseId'] = line.warehouseId.value
      ..['line.$index.quantity'] = line.quantity.value
      ..['line.$index.unitPriceMinorUnits'] = line.unitPrice.minorUnits
      ..['line.$index.discountPerUnitMinorUnits'] =
          line.discountPerUnit.minorUnits
      ..['line.$index.currency'] = line.unitPrice.currency.code
      ..['line.$index.itemCodeSnapshot'] = line.itemCodeSnapshot
      ..['line.$index.itemNameSnapshot'] = line.itemNameSnapshot
      ..['line.$index.warehouseNameSnapshot'] = line.warehouseNameSnapshot;
  }
  return result;
}

Map<String, Object?> purchaseInvoiceAuditSnapshot(PurchaseInvoice value) {
  final result = <String, Object?>{
    'id': value.id.value,
    'documentNumber': value.documentNumber,
    'date': value.date.toString(),
    'minuteOfDay': value.minuteOfDay,
    'supplierId': value.supplierId.value,
    'supplierNameSnapshot': value.supplierNameSnapshot,
    'defaultWarehouseId': value.defaultWarehouseId.value,
    'currency': value.currency.code,
    'exchangeRateTenThousandths': value.exchangeRate.tenThousandths,
    'purchaseKind': value.purchaseKind.name,
    'originalPurchaseInvoiceId': value.originalPurchaseInvoiceId?.value,
    'settlementKind': value.settlementKind.name,
    ..._moneySnapshot('expenses', value.expenses),
    ..._moneySnapshot('invoiceDiscount', value.invoiceDiscount),
    ..._moneySnapshot('paid', value.paid),
    if (value.balanceAfterInvoice != null)
      ..._moneySnapshot('balanceAfterInvoice', value.balanceAfterInvoice!),
    'notes': value.notes,
    'searchDetailsSnapshot': value.searchDetailsSnapshot,
    'lineCount': value.lines.length,
  };
  for (var index = 0; index < value.lines.length; index++) {
    final line = value.lines[index];
    result
      ..['line.$index.id'] = line.id.value
      ..['line.$index.itemId'] = line.itemId.value
      ..['line.$index.warehouseId'] = line.warehouseId.value
      ..['line.$index.quantity'] = line.quantity.value
      ..['line.$index.containerQuantity'] = line.containerQuantity.value
      ..['line.$index.purchasePriceMinorUnits'] = line.purchasePrice.minorUnits
      ..['line.$index.lineDiscountMinorUnits'] = line.lineDiscount.minorUnits
      ..['line.$index.salePriceMinorUnits'] = line.salePrice.minorUnits
      ..['line.$index.originalPurchaseLineId'] =
          line.originalPurchaseLineId?.value
      ..['line.$index.currency'] = line.purchasePrice.currency.code
      ..['line.$index.itemCodeSnapshot'] = line.itemCodeSnapshot
      ..['line.$index.itemNameSnapshot'] = line.itemNameSnapshot
      ..['line.$index.warehouseNameSnapshot'] = line.warehouseNameSnapshot;
  }
  return result;
}

Map<String, Object?> salesReturnAuditSnapshot(SalesReturn value) {
  final result = <String, Object?>{
    'id': value.id.value,
    'documentNumber': value.documentNumber,
    'date': value.date.toString(),
    'minuteOfDay': value.minuteOfDay,
    'originalSalesInvoiceId': value.originalSalesInvoiceId.value,
    'originalSalesInvoiceNumber':
        value.originalSalesInvoiceNumberSnapshot,
    'customerId': value.customerId.value,
    'customerNameSnapshot': value.customerNameSnapshot,
    'currency': value.currency.code,
    'exchangeRateTenThousandths': value.exchangeRate.tenThousandths,
    ..._moneySnapshot('total', value.total),
    ..._moneySnapshot('refundedAtReturn', value.refundedAtReturn),
    ..._moneySnapshot('creditedToCustomer', value.creditedToCustomer),
    if (value.balanceAfterReturn != null)
      ..._moneySnapshot('balanceAfterReturn', value.balanceAfterReturn!),
    'notes': value.notes,
    'lineCount': value.lines.length,
  };
  for (var index = 0; index < value.lines.length; index++) {
    final line = value.lines[index];
    result
      ..['line.$index.id'] = line.id.value
      ..['line.$index.sourceSalesLineId'] = line.sourceSalesLineId.value
      ..['line.$index.itemId'] = line.itemId.value
      ..['line.$index.warehouseId'] = line.warehouseId.value
      ..['line.$index.quantity'] = line.quantity.value
      ..['line.$index.sourceNetUnitPriceMinorUnits'] =
          line.sourceNetUnitPrice.minorUnits
      ..['line.$index.allocatedRefundMinorUnits'] =
          line.allocatedRefund.minorUnits
      ..['line.$index.currency'] = line.allocatedRefund.currency.code
      ..['line.$index.itemCodeSnapshot'] = line.itemCodeSnapshot
      ..['line.$index.itemNameSnapshot'] = line.itemNameSnapshot
      ..['line.$index.warehouseNameSnapshot'] =
          line.warehouseNameSnapshot;
  }
  return result;
}

Map<String, Object?> expenseAuditSnapshot(Expense value) =>
    <String, Object?>{
      'id': value.id.value,
      'documentNumber': value.documentNumber,
      'date': value.date.toString(),
      'minuteOfDay': value.minuteOfDay,
      'description': value.description,
      ..._moneySnapshot('amount', value.amount),
      'exchangeRateTenThousandths': value.exchangeRate.tenThousandths,
      'supplierId': value.supplierId?.value,
      'supplierNameSnapshot': value.supplierNameSnapshot,
      'paymentStatus': value.paymentStatus.name,
      'paidAt': value.paidAt?.toString(),
      'notes': value.notes,
    };

Map<String, Object?> installmentEntryAuditSnapshot(
  InstallmentEntry value,
) =>
    <String, Object?>{
      'id': value.id.value,
      'number': value.number,
      'dueDate': value.dueDate.toString(),
      ..._moneySnapshot('amount', value.amount),
      'status': value.status.name,
      'paidAt': value.paidAt?.toString(),
      'notes': value.notes,
    };

Map<String, Object?> operationalMasterDataAuditSnapshot(
  OperationalMasterDataRecord value,
) =>
    <String, Object?>{
      'id': value.id.value,
      'kind': value.kind.name,
      'number': value.number,
      'name': value.name,
      'parentId': value.parentId?.value,
      'relatedEntityId': value.relatedEntityId?.value,
      'isProtected': value.isProtected,
    };

Map<String, Object?> businessPoliciesAuditSnapshot(
  BusinessPolicySettings value,
) =>
    <String, Object?>{
      'defaultExchangeRateTenThousandths':
          value.defaultExchangeRate.tenThousandths,
      'allowSaleWithInsufficientStock':
          value.allowSaleWithInsufficientStock,
      ..._moneySnapshot(
        'defaultCustomerDebtLimit',
        value.defaultCustomerDebtLimit,
      ),
      'defaultDebtDueDays': value.defaultDebtDueDays,
      'overdueDebtAlertsEnabled': value.overdueDebtAlertsEnabled,
    };

Map<String, Object?> operationalDefaultsAuditSnapshot(
  OperationalDefaults value,
) =>
    <String, Object?>{
      'purchasesWarehouseId': value.purchases.warehouseId.value,
      'purchasesKind': value.purchases.purchaseKind.name,
      'purchasesPaymentKind': value.purchases.paymentKind.name,
      'purchasesCurrency': value.purchases.currency.code,
      'salesWarehouseId': value.sales.warehouseId.value,
      'salesKind': value.sales.saleKind.name,
      'salesCurrency': value.sales.currency.code,
      'cashboxMovementKind': value.cashbox.movementKind.name,
      'cashboxMainAccountId': value.cashbox.mainAccountId.value,
    };

Map<String, Object?> deviceSettingsAuditSnapshot(DeviceSettings value) =>
    <String, Object?>{
      'deviceId': value.deviceId,
      'defaultPrinterName': value.defaultPrinterName,
      'paperSize': value.paperSize.name,
      'printCopies': value.printCopies,
      'printPreviewEnabled': value.printPreviewEnabled,
    };

Map<String, Object?> _moneySnapshot(String prefix, Money value) =>
    <String, Object?>{
      '${prefix}MinorUnits': value.minorUnits,
      '${prefix}Currency': value.currency.code,
    };
