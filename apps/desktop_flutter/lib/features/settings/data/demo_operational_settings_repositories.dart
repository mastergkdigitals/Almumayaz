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
    if ((await getAll()).any((record) => record.parentId == id) ||
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
      defaultCustomerDebtLimit: Money.fromMajor(1000000, AppCurrency.iqd),
      defaultDebtDueDays: 30,
      overdueDebtAlertsEnabled: true,
    );

OperationalDefaults demoOperationalDefaults() => OperationalDefaults(
      purchases: PurchaseDefaults(
        warehouseId: EntityId.demo('warehouse', 1),
        purchaseKind: PurchaseKind.local,
        paymentKind: PaymentKind.cash,
        currency: AppCurrency.iqd,
      ),
      sales: SalesDefaults(
        warehouseId: EntityId.demo('warehouse', 1),
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
        id: EntityId.demo('item-group', 2),
        kind: OperationalMasterDataKind.itemGroup,
        number: 2,
        name: 'مستلزمات طباعة',
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('item-type', 2),
        kind: OperationalMasterDataKind.itemType,
        number: 1,
        name: 'أحبار',
        parentId: EntityId.demo('item-group', 2),
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
        number: 1,
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
        number: 1,
        name: 'البصرة',
        parentId: EntityId.demo('workplace', 3),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 1),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 1,
        name: 'الأطراف',
        isProtected: true,
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 1),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'شركة النخيل للتجارة',
        parentId: EntityId.demo('cashbox-main-account', 1),
        relatedEntityId: EntityId.demo('party', 1),
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-main-account', 2),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: 2,
        name: 'المصاريف',
        isProtected: true,
      ),
      OperationalMasterDataRecord(
        id: EntityId.demo('cashbox-subaccount', 2),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: 1,
        name: 'نقل',
        parentId: EntityId.demo('cashbox-main-account', 2),
      ),
    ];
