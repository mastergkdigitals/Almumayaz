import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/operational_master_data.dart';
import '../domain/operational_master_data_repository.dart';
import '../domain/settings_models.dart';
import '../domain/settings_repository.dart';

typedef SettingsReferenceExists = Future<bool> Function(EntityId id);

class DemoBusinessSettingsRepository implements BusinessSettingsRepository {
  DemoBusinessSettingsRepository({
    BusinessPolicySettings? businessPolicies,
    OperationalDefaults? operationalDefaults,
    required SettingsReferenceExists warehouseExists,
    required SettingsReferenceExists cashboxMainAccountExists,
  })  : _businessPolicies = businessPolicies ?? demoBusinessPolicies(),
        _operationalDefaults = operationalDefaults ?? demoOperationalDefaults(),
        _warehouseExists = warehouseExists,
        _cashboxMainAccountExists = cashboxMainAccountExists;

  final SettingsReferenceExists _warehouseExists;
  final SettingsReferenceExists _cashboxMainAccountExists;
  BusinessPolicySettings _businessPolicies;
  OperationalDefaults _operationalDefaults;

  @override
  Future<BusinessPolicySettings> loadBusinessPolicies() async {
    return _businessPolicies;
  }

  @override
  Future<void> saveBusinessPolicies(BusinessPolicySettings settings) async {
    _businessPolicies = settings;
  }

  @override
  Future<OperationalDefaults> loadOperationalDefaults() async {
    return _operationalDefaults;
  }

  @override
  Future<void> saveOperationalDefaults(OperationalDefaults settings) async {
    if (!await _warehouseExists(settings.purchases.warehouseId) ||
        !await _warehouseExists(settings.sales.warehouseId)) {
      throw StateError('أحد المخازن الافتراضية غير موجود');
    }
    if (!await _cashboxMainAccountExists(settings.cashbox.mainAccountId)) {
      throw StateError('حساب الصندوق الافتراضي غير موجود');
    }
    _operationalDefaults = settings;
  }
}

class DemoDeviceSettingsRepository implements DeviceSettingsRepository {
  DemoDeviceSettingsRepository({Iterable<DeviceSettings>? initialValues})
      : _settings = {
          for (final settings in initialValues ?? [demoDeviceSettings()])
            settings.deviceId: settings,
        };

  final Map<String, DeviceSettings> _settings;

  @override
  Future<DeviceSettings> loadDeviceSettings(String deviceId) async {
    return _settings[deviceId] ??
        DeviceSettings(
          deviceId: deviceId,
          defaultPrinterName: null,
          paperSize: PrintPaperSize.a4,
          printCopies: 1,
          printPreviewEnabled: true,
        );
  }

  @override
  Future<void> saveDeviceSettings(DeviceSettings settings) async {
    _settings[settings.deviceId] = settings;
  }
}

class DemoOperationalMasterDataRepository
    extends InMemoryDemoRepository<OperationalMasterDataRecord>
    implements OperationalMasterDataRepository {
  DemoOperationalMasterDataRepository({
    Iterable<OperationalMasterDataRecord>? initialValues,
    SettingsReferenceExists? isExternallyReferenced,
  })  : _isExternallyReferenced =
            isExternallyReferenced ?? _neverReferenced,
        super(
          initialValues: initialValues ?? demoOperationalMasterData(),
          idOf: (record) => record.id,
        );

  final SettingsReferenceExists _isExternallyReferenced;

  @override
  Future<List<OperationalMasterDataRecord>> getByKind(
    OperationalMasterDataKind kind, {
    EntityId? parentId,
  }) async {
    return List.unmodifiable(
      (await getAll()).where(
        (record) =>
            record.kind == kind &&
            (parentId == null || record.parentId == parentId),
      ),
    );
  }

  @override
  Future<OperationalMasterDataRecord> save(
    OperationalMasterDataRecord value,
  ) async {
    final existing = await getById(value.id);
    if (existing != null && existing.kind != value.kind) {
      throw StateError('لا يمكن تغيير نوع السجل');
    }
    if (existing?.isProtected == true && !value.isProtected) {
      throw StateError('لا يمكن إزالة حماية سجل النظام');
    }
    final existingRelatedEntityId = existing?.relatedEntityId;
    if (existingRelatedEntityId != null &&
        existingRelatedEntityId != value.relatedEntityId) {
      throw StateError('لا يمكن تغيير ارتباط سجل النظام');
    }
    if (existing != null &&
        existing.parentId != value.parentId &&
        await _isExternallyReferenced(value.id)) {
      throw StateError('لا يمكن نقل هذا السجل لأنه مرتبط ببيانات أخرى');
    }
    final parentId = value.parentId;
    if (parentId != null) {
      final parent = await getById(parentId);
      if (parent == null) throw StateError('السجل الأب غير موجود');
      final requiredKind = _requiredParentKind(value.kind);
      if (requiredKind != null && parent.kind != requiredKind) {
        throw StateError('نوع السجل الأب غير صحيح');
      }
    }
    final normalizedName = value.name.toLowerCase();
    final duplicate = (await getAll()).any(
      (record) =>
          record.id != value.id &&
          record.kind == value.kind &&
          record.parentId == value.parentId &&
          (record.number == value.number ||
              record.name.toLowerCase() == normalizedName),
    );
    if (duplicate) {
      throw StateError('يوجد سجل آخر بالرقم أو الاسم نفسه');
    }
    return super.save(value);
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final record = await getById(id);
    if (record == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (record.isProtected) {
      return const DeleteDecision.blocked('لا يمكن حذف سجل نظام محمي');
    }
    if (record.relatedEntityId != null ||
        (await getAll()).any((record) => record.parentId == id) ||
        await _isExternallyReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  OperationalMasterDataKind? _requiredParentKind(
    OperationalMasterDataKind kind,
  ) {
    return switch (kind) {
      OperationalMasterDataKind.itemType =>
        OperationalMasterDataKind.itemGroup,
      OperationalMasterDataKind.branch =>
        OperationalMasterDataKind.workplace,
      OperationalMasterDataKind.cashboxSubaccount =>
        OperationalMasterDataKind.cashboxMainAccount,
      _ => null,
    };
  }
}

Future<bool> _neverReferenced(EntityId _) async => false;

BusinessPolicySettings demoBusinessPolicies() => BusinessPolicySettings(
      defaultExchangeRate: ExchangeRate.parse('1310'),
      allowSaleWithInsufficientStock: false,
      defaultCustomerDebtLimit: Money.fromMajor(5000000, AppCurrency.iqd),
      defaultDebtDueDays: 30,
      overdueDebtAlertsEnabled: true,
    );

OperationalDefaults demoOperationalDefaults() => OperationalDefaults(
      purchases: PurchaseDefaults(
        warehouseId: EntityId('warehouse-001'),
        purchaseKind: PurchaseKind.local,
        paymentKind: PaymentKind.cash,
        currency: AppCurrency.iqd,
      ),
      sales: SalesDefaults(
        warehouseId: EntityId('warehouse-001'),
        saleKind: SaleKind.cash,
        currency: AppCurrency.iqd,
      ),
      cashbox: CashboxDefaults(
        movementKind: CashboxMovementKind.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 1),
      ),
    );

DeviceSettings demoDeviceSettings() => DeviceSettings(
      deviceId: 'demo-windows-device',
      defaultPrinterName: 'Microsoft Print to PDF',
      paperSize: PrintPaperSize.a4,
      printCopies: 1,
      printPreviewEnabled: true,
    );

List<OperationalMasterDataRecord> demoOperationalMasterData() => [
      OperationalMasterDataRecord(
        id: EntityId.demo('item-group', 1),
        kind: OperationalMasterDataKind.itemGroup,
        number: 1,
        name: 'أجهزة مكتبية',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 1),
        kind: OperationalMasterDataKind.itemType,
        number: 1,
        name: 'طابعات',
        parentId: EntityId.demo('item-group', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 2),
        kind: OperationalMasterDataKind.itemType,
        number: 2,
        name: 'آلات حاسبة',
        parentId: EntityId.demo('item-group', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 7),
        kind: OperationalMasterDataKind.itemType,
        number: 3,
        name: 'ماسحات باركود',
        parentId: EntityId.demo('item-group', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-group', 2),
        kind: OperationalMasterDataKind.itemGroup,
        number: 2,
        name: 'مستلزمات طباعة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 3),
        kind: OperationalMasterDataKind.itemType,
        number: 1,
        name: 'أحبار',
        parentId: EntityId.demo('item-group', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 4),
        kind: OperationalMasterDataKind.itemType,
        number: 2,
        name: 'ورق طباعة',
        parentId: EntityId.demo('item-group', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-group', 3),
        kind: OperationalMasterDataKind.itemGroup,
        number: 3,
        name: 'قرطاسية',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 5),
        kind: OperationalMasterDataKind.itemType,
        number: 1,
        name: 'أقلام',
        parentId: EntityId.demo('item-group', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 6),
        kind: OperationalMasterDataKind.itemType,
        number: 2,
        name: 'ملفات',
        parentId: EntityId.demo('item-group', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 8),
        kind: OperationalMasterDataKind.itemType,
        number: 3,
        name: 'دباسات',
        parentId: EntityId.demo('item-group', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 9),
        kind: OperationalMasterDataKind.itemType,
        number: 4,
        name: 'دفاتر',
        parentId: EntityId.demo('item-group', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 1),
        kind: OperationalMasterDataKind.workplace,
        number: 1,
        name: 'التجارة العامة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 1),
        kind: OperationalMasterDataKind.branch,
        number: 1,
        name: 'بغداد',
        parentId: EntityId.demo('workplace', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 2),
        kind: OperationalMasterDataKind.workplace,
        number: 2,
        name: 'تجارة المفرد',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 2),
        kind: OperationalMasterDataKind.branch,
        number: 2,
        name: 'المنصور',
        parentId: EntityId.demo('workplace', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 3),
        kind: OperationalMasterDataKind.workplace,
        number: 3,
        name: 'تجهيز المواد',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 3),
        kind: OperationalMasterDataKind.branch,
        number: 3,
        name: 'البصرة',
        parentId: EntityId.demo('workplace', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 4),
        kind: OperationalMasterDataKind.workplace,
        number: 4,
        name: 'الإدارة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 4),
        kind: OperationalMasterDataKind.branch,
        number: 4,
        name: 'الرئيسي',
        parentId: EntityId.demo('workplace', 4),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 14),
        kind: OperationalMasterDataKind.branch,
        number: 14,
        name: 'أربيل',
        parentId: EntityId.demo('workplace', 4),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 5),
        kind: OperationalMasterDataKind.workplace,
        number: 5,
        name: 'تجارة الجملة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 5),
        kind: OperationalMasterDataKind.branch,
        number: 5,
        name: 'النجف',
        parentId: EntityId.demo('workplace', 5),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 6),
        kind: OperationalMasterDataKind.workplace,
        number: 6,
        name: 'الأجهزة المكتبية',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 6),
        kind: OperationalMasterDataKind.branch,
        number: 6,
        name: 'الموصل',
        parentId: EntityId.demo('workplace', 6),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 7),
        kind: OperationalMasterDataKind.workplace,
        number: 7,
        name: 'الخدمات',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 7),
        kind: OperationalMasterDataKind.branch,
        number: 7,
        name: 'البصرة',
        parentId: EntityId.demo('workplace', 7),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 8),
        kind: OperationalMasterDataKind.branch,
        number: 8,
        name: 'الكاظمية',
        parentId: EntityId.demo('workplace', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 9),
        kind: OperationalMasterDataKind.branch,
        number: 9,
        name: 'كربلاء',
        parentId: EntityId.demo('workplace', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 8),
        kind: OperationalMasterDataKind.workplace,
        number: 8,
        name: 'المبيعات',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 10),
        kind: OperationalMasterDataKind.branch,
        number: 10,
        name: 'الرئيسي',
        parentId: EntityId.demo('workplace', 8),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 9),
        kind: OperationalMasterDataKind.workplace,
        number: 9,
        name: 'شركة المميز',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 11),
        kind: OperationalMasterDataKind.branch,
        number: 11,
        name: 'الفرع الرئيسي',
        parentId: EntityId.demo('workplace', 9),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 10),
        kind: OperationalMasterDataKind.workplace,
        number: 10,
        name: 'السوق المحلي',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 12),
        kind: OperationalMasterDataKind.branch,
        number: 12,
        name: 'فرع الكرادة',
        parentId: EntityId.demo('workplace', 10),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('workplace', 11),
        kind: OperationalMasterDataKind.workplace,
        number: 11,
        name: 'المبيعات المباشرة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('branch', 13),
        kind: OperationalMasterDataKind.branch,
        number: 13,
        name: 'فرع المنصور',
        parentId: EntityId.demo('workplace', 11),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 1),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 1,
        name: 'الصندوق الرئيسي',
        isProtected: true,
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 1),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'النقدية اليومية',
        parentId: EntityId.demo('cashbox-main-account', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 2),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 2,
        name: 'المصاريف العامة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 2),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'أجور النقل',
        parentId: EntityId.demo('cashbox-main-account', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 3),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 2,
        name: 'مصروفات المكتب',
        parentId: EntityId.demo('cashbox-main-account', 2),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 3),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 3,
        name: 'حساب الأطراف',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 4),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 4,
        name: 'الأطراف',
        isProtected: true,
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 4),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'شركة النخيل للتجارة',
        parentId: EntityId.demo('cashbox-main-account', 4),
        relatedEntityId: EntityId('party-001'),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 5),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 2,
        name: 'أحمد كريم',
        parentId: EntityId.demo('cashbox-main-account', 4),
        relatedEntityId: EntityId('party-002'),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 6),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 3,
        name: 'مجهز الرافدين',
        parentId: EntityId.demo('cashbox-main-account', 4),
        relatedEntityId: EntityId('party-003'),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 5),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 5,
        name: 'المصاريف',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 7),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'نقل',
        parentId: EntityId.demo('cashbox-main-account', 5),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 8),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 2,
        name: 'صيانة',
        parentId: EntityId.demo('cashbox-main-account', 5),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 9),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 3,
        name: 'خدمات',
        parentId: EntityId.demo('cashbox-main-account', 5),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 6),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 6,
        name: 'إيرادات أخرى',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 10),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'خدمات',
        parentId: EntityId.demo('cashbox-main-account', 6),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 11),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 2,
        name: 'إيرادات متنوعة',
        parentId: EntityId.demo('cashbox-main-account', 6),
      ),
    ];
