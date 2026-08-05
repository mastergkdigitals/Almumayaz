import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Settings demo repositories own every canonical visible fixture',
      () async {
    final repositories = AppRepositories.demo();
    final masterData = repositories.operationalMasterData;
    final groups = await masterData.getByKind(
      OperationalMasterDataKind.itemGroup,
    );
    final types = await masterData.getByKind(
      OperationalMasterDataKind.itemType,
    );
    final workplaces = await masterData.getByKind(
      OperationalMasterDataKind.workplace,
    );
    final branches = await masterData.getByKind(
      OperationalMasterDataKind.branch,
    );
    final mainAccounts = await masterData.getByKind(
      OperationalMasterDataKind.cashboxMainAccount,
    );
    final subaccounts = await masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
    );

    expect(groups.map((record) => record.name), [
      'أجهزة مكتبية',
      'مستلزمات طباعة',
      'قرطاسية',
    ]);
    expect(types, hasLength(6));
    expect(types.map((record) => record.name), [
      'طابعات',
      'آلات حاسبة',
      'أحبار',
      'ورق طباعة',
      'أقلام',
      'ملفات',
    ]);
    expect(types.map((record) => record.number), [1, 2, 1, 2, 1, 2]);
    for (final type in types) {
      expect(groups.any((group) => group.id == type.parentId), isTrue);
    }

    expect(workplaces.map((record) => record.name), containsAll([
      'التجارة العامة',
      'تجارة المفرد',
      'تجهيز المواد',
      'الإدارة',
      'تجارة الجملة',
      'الأجهزة المكتبية',
      'الخدمات',
      'المبيعات',
      'شركة المميز',
      'السوق المحلي',
      'المبيعات المباشرة',
    ]));
    expect(branches, hasLength(14));
    expect(branches.map((record) => record.name), contains('أربيل'));
    for (final branch in branches) {
      expect(
        workplaces.any((workplace) => workplace.id == branch.parentId),
        isTrue,
      );
    }

    expect(mainAccounts.map((record) => record.name), containsAll([
      'الصندوق الرئيسي',
      'المصاريف العامة',
      'حساب الأطراف',
      'الأطراف',
      'المصاريف',
      'إيرادات أخرى',
    ]));
    expect(subaccounts, hasLength(11));
    for (final subaccount in subaccounts) {
      expect(
        mainAccounts.any((account) => account.id == subaccount.parentId),
        isTrue,
      );
    }
  });

  test('business, operational and device Settings persist typed values',
      () async {
    final repositories = AppRepositories.demo();
    final initial =
        await repositories.businessSettings.loadBusinessPolicies();
    expect(initial.defaultCustomerDebtLimit.toPlainString(), '5000000');

    final policies = BusinessPolicySettings(
      defaultExchangeRate: ExchangeRate.parse('1425'),
      allowSaleWithInsufficientStock: true,
      defaultCustomerDebtLimit: Money.fromMajor(
        6000000,
        AppCurrency.iqd,
      ),
      defaultDebtDueDays: 45,
      overdueDebtAlertsEnabled: false,
    );
    await repositories.businessSettings.saveBusinessPolicies(policies);
    final saved = await repositories.businessSettings.loadBusinessPolicies();
    expect(saved.defaultExchangeRate.toPlainString(), '1425');
    expect(saved.defaultDebtDueDays, 45);

    final initialDefaults =
        await repositories.businessSettings.loadOperationalDefaults();
    expect(
      await repositories.warehouses.getById(
        initialDefaults.purchases.warehouseId,
      ),
      isNotNull,
    );
    expect(
      (await repositories.cashbox.getMainAccounts()).any(
        (account) =>
            account.id == initialDefaults.cashbox.mainAccountId.value,
      ),
      isTrue,
    );

    final defaults = OperationalDefaults(
      purchases: PurchaseDefaults(
        warehouseId: EntityId('warehouse-002'),
        purchaseKind: PurchaseKind.imported,
        paymentKind: PaymentKind.credit,
        currency: AppCurrency.usd,
      ),
      sales: SalesDefaults(
        warehouseId: EntityId('warehouse-003'),
        saleKind: SaleKind.installments,
        currency: AppCurrency.usd,
      ),
      cashbox: CashboxDefaults(
        movementKind: CashboxMovementKind.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 2),
      ),
    );
    await repositories.businessSettings.saveOperationalDefaults(defaults);
    final savedDefaults =
        await repositories.businessSettings.loadOperationalDefaults();
    expect(savedDefaults.purchases.warehouseId, EntityId('warehouse-002'));
    expect(savedDefaults.purchases.purchaseKind, PurchaseKind.imported);
    expect(savedDefaults.sales.saleKind, SaleKind.installments);
    expect(
      savedDefaults.cashbox.mainAccountId,
      EntityId.demo('cashbox-main-account', 2),
    );

    final device = DeviceSettings(
      deviceId: 'test-device',
      defaultPrinterName: 'HP LaserJet Pro',
      paperSize: PrintPaperSize.a5,
      printCopies: 2,
      printPreviewEnabled: false,
    );
    await repositories.deviceSettings.saveDeviceSettings(device);
    final savedDevice =
        await repositories.deviceSettings.loadDeviceSettings('test-device');
    expect(savedDevice.defaultPrinterName, 'HP LaserJet Pro');
    expect(savedDevice.paperSize, PrintPaperSize.a5);
    expect(savedDevice.printCopies, 2);
  });

  test('master data rejects duplicates and protects parent relationships',
      () async {
    final repository = AppRepositories.demo().operationalMasterData;
    final duplicate = OperationalMasterDataRecord(
      id: EntityId.demo('item-group', 90),
      kind: OperationalMasterDataKind.itemGroup,
      number: 90,
      name: 'أجهزة مكتبية',
    );
    await expectLater(repository.save(duplicate), throwsStateError);

    final group = OperationalMasterDataRecord(
      id: EntityId.demo('item-group', 91),
      kind: OperationalMasterDataKind.itemGroup,
      number: 91,
      name: 'مجموعة مستقلة',
    );
    final type = OperationalMasterDataRecord(
      id: EntityId.demo('item-type', 91),
      kind: OperationalMasterDataKind.itemType,
      number: 91,
      name: 'نوع مستقل',
      parentId: group.id,
    );
    await repository.save(group);
    await repository.save(type);

    expect((await repository.canDelete(group.id)).isAllowed, isFalse);
    await repository.delete(type.id);
    expect((await repository.canDelete(group.id)).isAllowed, isTrue);
    await repository.delete(group.id);
    expect(await repository.getById(group.id), isNull);
    expect(
      (await repository.canDelete(
        EntityId.demo('cashbox-main-account', 1),
      ))
          .isAllowed,
      isFalse,
    );
  });
}
