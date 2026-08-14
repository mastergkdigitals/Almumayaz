import 'package:erp/core/app_state/app_data_composition.dart';
import 'package:erp/core/app_state/app_data_profile.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/data/demo_business_audit.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/data/demo_identity_state.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_repository.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/items/domain/item_repository.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/operational_master_data_repository.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:erp/features/warehouses/domain/inventory_records.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 9 business audit', () {
    test('application composition shares identity journal and runner', () async {
      final composition = AppDataComposition.demo(
        AppDataProfile.originalDemo,
      );
      final session = await composition.services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );

      final party = await composition.repositories.parties.quickCreate(
        const PartyQuickCreateRequest(name: 'طرف من التركيب الفعلي'),
      );
      final records = (await composition.services.audit.search(
        AuditQuery(entityType: 'party'),
      ))
          .records;

      expect(records, hasLength(1));
      expect(records.single.entityId, party.entityId);
      expect(records.single.actorUserId, session.userId);
      expect(records.single.details['sessionId'], session.id.value);
    });

    test('master records retain actor, metadata, live snapshots and deletion',
        () async {
      final harness = _AuditHarness();

      final party = await harness.repositories.parties.quickCreate(
        const PartyQuickCreateRequest(name: 'طرف تدقيق جديد'),
      );
      await harness.repositories.parties.saveWithMasterData(
        party.copyWith(notes: 'ملاحظة محدثة'),
        const PartyMasterDataReferences(),
      );
      await harness.repositories.parties.delete(party.entityId);

      final item = await harness.repositories.items.quickCreate(
        ItemQuickCreateRequest(
          code: 'AUD-ITEM',
          name: 'مادة تدقيق',
          groupId: EntityId.demo('item-group', 1),
          typeId: EntityId.demo('item-type', 1),
        ),
      );
      await harness.repositories.items.delete(item.entityId);

      final warehouse = Warehouse.typed(
        entityId: EntityId('audit-warehouse'),
        number: 99,
        name: 'مخزن التدقيق',
        location: 'بغداد',
        notes: '',
      );
      await harness.repositories.warehouses.save(warehouse);
      await harness.repositories.warehouses.save(
        warehouse.copyWith(notes: 'بعد التحديث'),
      );
      await harness.repositories.warehouses.delete(warehouse.entityId);

      final master = await harness.repositories.operationalMasterData
          .createNamedRecord(
        const CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.workplace,
          name: 'جهة تدقيق',
        ),
      );
      await harness.repositories.operationalMasterData.save(
        OperationalMasterDataRecord(
          id: master.id,
          kind: master.kind,
          number: master.number,
          name: 'جهة تدقيق محدثة',
        ),
      );
      await harness.repositories.operationalMasterData.delete(master.id);

      final partyEvents = await harness.eventsFor('party');
      expect(
        partyEvents.map((event) => event.action),
        [AuditAction.delete, AuditAction.update, AuditAction.create],
      );
      final partyDelete = partyEvents.first;
      expect(partyDelete.metadata.before['name'], 'طرف تدقيق جديد');
      expect(partyDelete.metadata.before['notes'], 'ملاحظة محدثة');
      expect(partyDelete.metadata.after, isEmpty);
      expect(partyDelete.details['permanent'], isTrue);
      expect(await harness.repositories.parties.getById(party.entityId), isNull);

      for (final event in await harness.allEvents()) {
        expect(event.actorUserId, EntityId.demo('user', 1));
        expect(event.actorUsername, 'admin');
        expect(event.metadata.deviceId, 'demo-windows-device');
        expect(event.metadata.requestId, startsWith('demo-request-'));
        expect(event.metadata.ipAddress, isNull);
        expect(event.metadata.macAddress, isNull);
        expect(event.details['sessionId'], isNotNull);
        expect(event.details['sessionState'], 'active');
        expect(event.details['permission'], isNotNull);
      }

      final itemDelete = (await harness.eventsFor('item')).first;
      expect(itemDelete.metadata.before['code'], 'AUD-ITEM');
      expect(itemDelete.metadata.before['groupId'], 'demo-item-group-1');
      expect(itemDelete.metadata.before['iqdSalePriceMinorUnits'], 0);
      final warehouseDelete =
          (await harness.eventsFor('warehouse')).first;
      expect(warehouseDelete.metadata.before['notes'], 'بعد التحديث');
      final masterDelete =
          (await harness.eventsFor('operational_master_data')).first;
      expect(masterDelete.metadata.before['name'], 'جهة تدقيق محدثة');

      final requestIds = {
        for (final event in await harness.allEvents())
          event.metadata.requestId,
      };
      expect(requestIds, hasLength((await harness.allEvents()).length));
    });

    test('transfers, vouchers and compound invoices emit one primary event',
        () async {
      final harness = _AuditHarness();

      final transfer = await harness.repositories.warehouses.transfer(
        InventoryTransferDraft(
          fromWarehouseId: EntityId('warehouse-001'),
          toWarehouseId: EntityId('warehouse-002'),
          lines: [
            InventoryTransferLine(
              itemId: EntityId('item-003'),
              quantity: WholeQuantity(1),
            ),
          ],
          createdAt: AuditTimestamp(DateTime.utc(2026, 8, 14, 9)),
        ),
      );
      final reversal = await harness.repositories.warehouses.reverseTransfer(
        transfer.id,
        createdAt: AuditTimestamp(DateTime.utc(2026, 8, 14, 9, 1)),
      );
      final transferEvents = await harness.eventsFor('inventory_transfer');
      expect(transferEvents, hasLength(2));
      expect(transferEvents.first.entityId, reversal.id);
      expect(transferEvents.first.details['operation'], 'reverse');
      expect(transferEvents.first.details['reversalOfId'], transfer.id.value);
      expect(transferEvents.last.metadata.after['line.0.quantity'], 1);

      final numbered =
          harness.repositories.cashbox as CashboxIssuedNumberRepository;
      final voucher = _manualVoucher(await numbered.nextVoucherNumber());
      await harness.repositories.cashbox.save(voucher);
      await harness.repositories.cashbox.save(
        voucher.copyWith(notes: 'تحديث السند'),
      );
      await harness.repositories.cashbox.delete(voucher.entityId);
      final voucherEvents = await harness.eventsFor('cashbox_voucher');
      expect(
        voucherEvents.map((event) => event.action),
        [AuditAction.delete, AuditAction.update, AuditAction.create],
      );
      expect(voucherEvents.first.metadata.before['notes'], 'تحديث السند');

      final sale = (await harness.repositories.sales.getAll()).firstWhere(
        (invoice) => invoice.id == EntityId('sales-invoice-101'),
      );
      final beforeSaleEventCount = (await harness.allEvents()).length;
      final savedSale = await harness.repositories.sales.replaceInvoice(
        sale.copyWith(notes: 'تحديث تدقيق البيع'),
      );
      expect(
        (await harness.allEvents()).length,
        beforeSaleEventCount + 1,
      );
      final saleUpdate = (await harness.eventsFor('sales_invoice')).first;
      expect(saleUpdate.action, AuditAction.update);
      expect(saleUpdate.metadata.before['notes'], sale.notes);
      expect(saleUpdate.metadata.after['notes'], 'تحديث تدقيق البيع');
      expect(saleUpdate.metadata.after['line.0.itemId'], isNotNull);
      expect(
        (await harness.eventsFor('cashbox_voucher')).length,
        voucherEvents.length,
        reason: 'derived system postings are not separate user operations',
      );
      await harness.repositories.sales.deleteInvoicePermanently(savedSale.id);
      final saleDelete = (await harness.eventsFor('sales_invoice')).first;
      expect(saleDelete.action, AuditAction.delete);
      expect(saleDelete.metadata.before['lineCount'], sale.lines.length);
      expect(saleDelete.metadata.after, isEmpty);

      final purchase =
          (await harness.repositories.purchases.getAll()).firstWhere(
        (invoice) => invoice.id == EntityId('purchase-invoice-102'),
      );
      final savedPurchase =
          await harness.repositories.purchases.replaceInvoice(
        _copyPurchase(purchase, notes: 'تحديث تدقيق الشراء'),
      );
      final purchaseUpdate =
          (await harness.eventsFor('purchase_invoice')).first;
      expect(purchaseUpdate.action, AuditAction.update);
      expect(purchaseUpdate.metadata.before['notes'], purchase.notes);
      expect(
        purchaseUpdate.metadata.after['notes'],
        'تحديث تدقيق الشراء',
      );
      await harness.repositories.purchases
          .deleteInvoicePermanently(savedPurchase.id);
      final purchaseDelete =
          (await harness.eventsFor('purchase_invoice')).first;
      expect(purchaseDelete.action, AuditAction.delete);
      expect(purchaseDelete.details['permanent'], isTrue);
      expect(purchaseDelete.metadata.before['line.0.id'], isNotNull);
    });

    test('installments and settings retain exact before and after values',
        () async {
      final harness = _AuditHarness();
      final installmentSale =
          (await harness.repositories.sales.getAll()).firstWhere(
        (invoice) => invoice.settlementKind == SalesSettlementKind.installments,
      );
      final plan = (await harness.repositories.installments
          .getBySalesInvoiceId(installmentSale.id))!;
      final entry = plan.entries.first;
      await harness.repositories.installments.settleEntry(
        entryId: entry.id,
        paidAt: AuditTimestamp(DateTime.utc(2026, 8, 14, 10)),
        notes: 'تسديد تجريبي',
      );
      final installmentEvent =
          (await harness.eventsFor('installment_entry')).single;
      expect(installmentEvent.metadata.before['status'], 'pending');
      expect(installmentEvent.metadata.after['status'], 'paid');
      expect(installmentEvent.metadata.after['notes'], 'تسديد تجريبي');
      expect(installmentEvent.details['salesInvoiceId'], installmentSale.id.value);

      final policies =
          await harness.repositories.businessSettings.loadBusinessPolicies();
      await harness.repositories.businessSettings.saveBusinessPolicies(
        BusinessPolicySettings(
          defaultExchangeRate: ExchangeRate.parse('1400'),
          allowSaleWithInsufficientStock: true,
          defaultCustomerDebtLimit: policies.defaultCustomerDebtLimit,
          defaultDebtDueDays: 45,
          overdueDebtAlertsEnabled: false,
        ),
      );
      final defaults =
          await harness.repositories.businessSettings.loadOperationalDefaults();
      await harness.repositories.businessSettings.saveOperationalDefaults(
        OperationalDefaults(
          purchases: PurchaseDefaults(
            warehouseId: EntityId('warehouse-002'),
            purchaseKind: defaults.purchases.purchaseKind,
            paymentKind: defaults.purchases.paymentKind,
            currency: defaults.purchases.currency,
          ),
          sales: SalesDefaults(
            warehouseId: EntityId('warehouse-002'),
            saleKind: defaults.sales.saleKind,
            currency: defaults.sales.currency,
          ),
          cashbox: defaults.cashbox,
        ),
      );
      final device = await harness.repositories.deviceSettings
          .loadDeviceSettings('audit-device');
      await harness.repositories.deviceSettings.saveDeviceSettings(
        DeviceSettings(
          deviceId: device.deviceId,
          defaultPrinterName: 'Audit Printer',
          paperSize: PrintPaperSize.a5,
          printCopies: 2,
          printPreviewEnabled: false,
        ),
      );

      final policyEvent =
          (await harness.eventsFor('business_policy_settings')).single;
      expect(
        policyEvent.metadata.before['defaultExchangeRateTenThousandths'],
        policies.defaultExchangeRate.tenThousandths,
      );
      expect(
        policyEvent.metadata.after['defaultExchangeRateTenThousandths'],
        ExchangeRate.parse('1400').tenThousandths,
      );
      final defaultsEvent =
          (await harness.eventsFor('operational_defaults')).single;
      expect(defaultsEvent.metadata.before['salesWarehouseId'], isNotNull);
      expect(defaultsEvent.metadata.after['salesWarehouseId'], 'warehouse-002');
      final deviceEvent =
          (await harness.eventsFor('device_settings')).single;
      expect(deviceEvent.metadata.before['printCopies'], 1);
      expect(deviceEvent.metadata.after['printCopies'], 2);
    });

    test('failed mutations add no success record and runner fixes actor order',
        () async {
      final harness = _AuditHarness();
      await harness.repositories.parties.quickCreate(
        const PartyQuickCreateRequest(name: 'اسم غير مكرر'),
      );
      final beforeFailure = (await harness.allEvents()).length;
      await expectLater(
        harness.repositories.parties.quickCreate(
          const PartyQuickCreateRequest(name: 'اسم غير مكرر'),
        ),
        throwsStateError,
      );
      expect((await harness.allEvents()).length, beforeFailure);

      final session = harness.identity.state.currentSession!;
      final warehouseMutation = harness.repositories.warehouses.save(
        Warehouse.typed(
          entityId: EntityId('ordered-audit-warehouse'),
          number: 100,
          name: 'مخزن ترتيب التدقيق',
          location: '',
          notes: '',
        ),
      );
      final signOut = harness.identity.authentication.signOut(session.id);
      await warehouseMutation;
      await signOut;

      final event = (await harness.eventsFor('warehouse')).single;
      expect(event.actorUserId, session.userId);
      expect(event.actorUsername, 'admin');
      expect(event.details['sessionId'], session.id.value);
      expect(harness.identity.state.currentSession, isNull);
    });

    test('audit preparation failure leaves the business projection unchanged',
        () async {
      final runner = DemoTransactionRunner();
      final state = DemoIdentityState(
        initialAuditRecords: const [],
        transactionRunner: runner,
        clock: () => throw StateError('تعذر تخصيص وقت التدقيق'),
      );
      final repositories = AppRepositories.forProfile(
        AppDataProfile.originalDemo,
        transactionRunner: runner,
        businessAudit: DemoBusinessAudit(state: state),
      );
      final warehouse = Warehouse.typed(
        entityId: EntityId('audit-clock-failure'),
        number: 101,
        name: 'مخزن لا يجب حفظه',
        location: '',
        notes: '',
      );

      await expectLater(
        repositories.warehouses.save(warehouse),
        throwsStateError,
      );

      expect(await repositories.warehouses.getById(warehouse.entityId), isNull);
      expect(state.auditRecords, isEmpty);
    });
  });
}

class _AuditHarness {
  _AuditHarness() {
    final runner = DemoTransactionRunner();
    final state = DemoIdentityState(
      initialAuditRecords: const [],
      transactionRunner: runner,
    );
    identity = DemoIdentityServiceBundle(state: state);
    repositories = AppRepositories.forProfile(
      AppDataProfile.originalDemo,
      transactionRunner: runner,
      businessAudit: DemoBusinessAudit(state: state),
    );
  }

  late final DemoIdentityServiceBundle identity;
  late final AppRepositories repositories;

  Future<List<AuditRecord>> allEvents() async {
    return (await identity.audit.search(AuditQuery(limit: 1000))).records;
  }

  Future<List<AuditRecord>> eventsFor(String entityType) async {
    return (await identity.audit.search(
      AuditQuery(entityType: entityType, limit: 1000),
    ))
        .records;
  }
}

CashboxVoucher _manualVoucher(int number) => CashboxVoucher.typed(
      entityId: EntityId('phase9-voucher'),
      number: number,
      createdTimestamp: AuditTimestamp(DateTime.utc(2026, 8, 14, 9, 30)),
      type: CashboxVoucherType.receipt,
      mainAccountEntityId: EntityId.demo('cashbox-main-account', 1),
      mainAccountLabel: '',
      subaccountEntityId: EntityId.demo('cashbox-subaccount', 1),
      subaccountLabel: '',
      exchangeRateValue: ExchangeRate.parse('1310'),
      iqdAmount: Money.fromMajor(1000, AppCurrency.iqd),
      usdAmount: Money.zero(AppCurrency.usd),
      iqdBalanceBefore: Money.zero(AppCurrency.iqd),
      iqdBalanceAfter: Money.zero(AppCurrency.iqd),
      usdBalanceBefore: Money.zero(AppCurrency.usd),
      usdBalanceAfter: Money.zero(AppCurrency.usd),
      notes: 'سند تدقيق',
    );

PurchaseInvoice _copyPurchase(PurchaseInvoice source, {required String notes}) {
  return PurchaseInvoice(
    id: source.id,
    documentNumber: source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    supplierId: source.supplierId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    purchaseKind: source.purchaseKind,
    settlementKind: source.settlementKind,
    originalPurchaseInvoiceId: source.originalPurchaseInvoiceId,
    lines: source.lines,
    expenses: source.expenses,
    invoiceDiscount: source.invoiceDiscount,
    paid: source.paid,
    supplierNameSnapshot: source.supplierNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    notes: notes,
  );
}
