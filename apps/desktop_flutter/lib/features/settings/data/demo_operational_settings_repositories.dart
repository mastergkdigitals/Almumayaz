import '../../../core/data/app_repository.dart';
import '../../../core/data/demo_transaction_runner.dart';
import '../../../core/domain/business_values.dart';
import '../../audit_log/data/demo_business_audit.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../permissions/domain/permission_models.dart';
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
    DemoTransactionRunner? transactionRunner,
    DemoBusinessAudit? businessAudit,
  })  : _businessPolicies = businessPolicies ?? demoBusinessPolicies(),
        _operationalDefaults = operationalDefaults ?? demoOperationalDefaults(),
        _warehouseExists = warehouseExists,
        _cashboxMainAccountExists = cashboxMainAccountExists,
        _transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _businessAudit = businessAudit;

  final SettingsReferenceExists _warehouseExists;
  final SettingsReferenceExists _cashboxMainAccountExists;
  final DemoTransactionRunner _transactionRunner;
  final DemoBusinessAudit? _businessAudit;
  BusinessPolicySettings _businessPolicies;
  OperationalDefaults _operationalDefaults;

  @override
  Future<BusinessPolicySettings> loadBusinessPolicies() async {
    return _businessPolicies;
  }

  @override
  Future<void> saveBusinessPolicies(BusinessPolicySettings settings) {
    return _transactionRunner.run(() {
      final before = _businessPolicies;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.success,
          summary: 'تحديث سياسات العمل',
          before: businessPoliciesAuditSnapshot(before),
          after: businessPoliciesAuditSnapshot(settings),
          entityType: 'business_policy_settings',
          entityId: EntityId('business-policy-settings'),
        ),
        permission: PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      );
      _businessPolicies = settings;
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  @override
  Future<OperationalDefaults> loadOperationalDefaults() async {
    return _operationalDefaults;
  }

  @override
  Future<void> saveOperationalDefaults(OperationalDefaults settings) {
    return _transactionRunner.run(() async {
      if (!await _warehouseExists(settings.purchases.warehouseId) ||
          !await _warehouseExists(settings.sales.warehouseId)) {
        throw StateError('أحد المخازن الافتراضية غير موجود');
      }
      if (!await _cashboxMainAccountExists(settings.cashbox.mainAccountId)) {
        throw StateError('حساب الصندوق الافتراضي غير موجود');
      }
      final before = _operationalDefaults;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.success,
          summary: 'تحديث الإعدادات التشغيلية الافتراضية',
          before: operationalDefaultsAuditSnapshot(before),
          after: operationalDefaultsAuditSnapshot(settings),
          entityType: 'operational_defaults',
          entityId: EntityId('operational-defaults'),
        ),
        permission: PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      );
      _operationalDefaults = settings;
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }
}

class DemoDeviceSettingsRepository implements DeviceSettingsRepository {
  DemoDeviceSettingsRepository({
    Iterable<DeviceSettings>? initialValues,
    DemoTransactionRunner? transactionRunner,
    DemoBusinessAudit? businessAudit,
  })  : _transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _businessAudit = businessAudit,
        _settings = {
          for (final settings in initialValues ?? [demoDeviceSettings()])
            settings.deviceId: settings,
        };

  final Map<String, DeviceSettings> _settings;
  final DemoTransactionRunner _transactionRunner;
  final DemoBusinessAudit? _businessAudit;

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
  Future<void> saveDeviceSettings(DeviceSettings settings) {
    return _transactionRunner.run(() {
      final before = _settings[settings.deviceId] ??
          DeviceSettings(
            deviceId: settings.deviceId,
            defaultPrinterName: null,
            paperSize: PrintPaperSize.a4,
            printCopies: 1,
            printPreviewEnabled: true,
          );
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.success,
          summary: 'تحديث إعدادات جهاز Windows',
          before: deviceSettingsAuditSnapshot(before),
          after: deviceSettingsAuditSnapshot(settings),
          entityType: 'device_settings',
          entityId: EntityId('device-settings-${settings.deviceId}'),
        ),
        permission: PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      );
      _settings[settings.deviceId] = settings;
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }
}

class DemoOperationalMasterDataRepository
    extends InMemoryDemoRepository<OperationalMasterDataRecord>
    implements OperationalMasterDataRepository {
  DemoOperationalMasterDataRepository({
    Iterable<OperationalMasterDataRecord>? initialValues,
    SettingsReferenceExists? isExternallyReferenced,
    DemoTransactionRunner? transactionRunner,
    DemoBusinessAudit? businessAudit,
  })  : _isExternallyReferenced =
            isExternallyReferenced ?? _neverReferenced,
        _transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _businessAudit = businessAudit,
        super(
          initialValues: initialValues ?? demoOperationalMasterData(),
          idOf: (record) => record.id,
        );

  final SettingsReferenceExists _isExternallyReferenced;
  final DemoTransactionRunner _transactionRunner;
  final DemoBusinessAudit? _businessAudit;
  final Map<(OperationalMasterDataKind, String?), int>
      _highestIssuedNumbers = {};
  final Map<(OperationalMasterDataKind, String?), Set<int>>
      _issuedNumbers = {};
  final Set<EntityId> _issuedIds = {};
  int _nextGeneratedIdSequence = 1;

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
  ) {
    return _transactionRunner.run(() async {
      final staged = createDemoSnapshot();
      final existing = staged[value.id];
      _captureIssuedNumbers(staged.values);
      await _stageSaveUnlocked(staged, value);
      final audit = _prepareRecordSaveAudit(before: existing, after: value);
      commitDemoSnapshot(staged);
      _recordIssuedNumber(value);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return value;
    });
  }

  Future<void> _stageSaveUnlocked(
    Map<EntityId, OperationalMasterDataRecord> staged,
    OperationalMasterDataRecord value,
  ) async {
    final existing = staged[value.id];
    final key = (value.kind, value.parentId?.value);
    if (existing == null && _issuedIds.contains(value.id)) {
      throw StateError('معرف السجل مستخدم مسبقاً');
    }
    if (existing == null &&
        (_issuedNumbers[key]?.contains(value.number) ?? false)) {
      throw StateError('رقم السجل مستخدم مسبقاً');
    }
    if (existing != null && existing.number != value.number) {
      throw StateError('لا يمكن تغيير رقم سجل صادر');
    }
    if (existing != null && existing.kind != value.kind) {
      throw StateError('لا يمكن تغيير نوع السجل');
    }
    if (existing != null &&
        existing.parentId != value.parentId &&
        (_issuedNumbers[key]?.contains(value.number) ?? false)) {
      throw StateError('رقم السجل مستخدم مسبقاً');
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
      final parent = staged[parentId];
      if (parent == null) throw StateError('السجل الأب غير موجود');
      final requiredKind = _requiredParentKind(value.kind);
      if (requiredKind != null && parent.kind != requiredKind) {
        throw StateError('نوع السجل الأب غير صحيح');
      }
    }
    final normalizedName = normalizeOperationalMasterDataName(value.name);
    final duplicate = staged.values.any(
      (record) =>
          record.id != value.id &&
          record.kind == value.kind &&
          record.parentId == value.parentId &&
          (record.number == value.number ||
              normalizeOperationalMasterDataName(record.name) ==
                  normalizedName),
    );
    if (duplicate) {
      throw StateError('يوجد سجل آخر بالرقم أو الاسم نفسه');
    }
    staged[value.id] = value;
  }

  @override
  Future<OperationalMasterDataRecord> createNamedRecord(
    CreateOperationalMasterDataRequest request,
  ) {
    return _transactionRunner.run(() async {
      final name = _requireName(request.name);
      final staged = createDemoSnapshot();
      _captureIssuedNumbers(staged.values);
      final record = OperationalMasterDataRecord(
        id: _issueId(staged, request.kind),
        kind: request.kind,
        number: _nextNumber(request.kind, request.parentId),
        name: name,
        parentId: request.parentId,
      );
      await _stageSaveUnlocked(staged, record);
      final audit = _prepareRecordSaveAudit(before: null, after: record);
      commitDemoSnapshot(staged);
      _recordIssuedNumber(record);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return record;
    });
  }

  @override
  Future<OperationalCashboxAccountPair> createCashboxAccountPair(
    CreateCashboxAccountPairRequest request,
  ) {
    return _transactionRunner.run(() async {
      final mainName = _requireName(request.mainAccountName);
      final subaccountName = _requireName(request.firstSubaccountName);
      final staged = createDemoSnapshot();
      _captureIssuedNumbers(staged.values);

      final mainAccount = OperationalMasterDataRecord(
        id: _issueId(
          staged,
          OperationalMasterDataKind.cashboxMainAccount,
        ),
        kind: OperationalMasterDataKind.cashboxMainAccount,
        number: _nextNumber(
          OperationalMasterDataKind.cashboxMainAccount,
          null,
        ),
        name: mainName,
      );
      await _stageSaveUnlocked(staged, mainAccount);

      final subaccount = OperationalMasterDataRecord(
        id: _issueId(
          staged,
          OperationalMasterDataKind.cashboxSubaccount,
        ),
        kind: OperationalMasterDataKind.cashboxSubaccount,
        number: _nextNumber(
          OperationalMasterDataKind.cashboxSubaccount,
          mainAccount.id,
        ),
        name: subaccountName,
        parentId: mainAccount.id,
      );
      await _stageSaveUnlocked(staged, subaccount);
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.create,
          outcome: AuditOutcome.success,
          summary: 'إضافة حساب صندوق رئيسي وفرعي',
          after: {
            ...operationalMasterDataAuditSnapshot(mainAccount),
            'subaccountId': subaccount.id.value,
            'subaccountKind': subaccount.kind.name,
            'subaccountNumber': subaccount.number,
            'subaccountName': subaccount.name,
            'subaccountParentId': subaccount.parentId?.value,
          },
          details: {'subaccountId': subaccount.id.value},
          entityType: 'operational_master_data',
          entityId: mainAccount.id,
        ),
        permission: PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      );

      // Both validated records become visible in one synchronous swap.
      commitDemoSnapshot(staged);
      _recordIssuedNumber(mainAccount);
      _recordIssuedNumber(subaccount);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return OperationalCashboxAccountPair(
        mainAccount: mainAccount,
        subaccount: subaccount,
      );
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) {
    return _canDeleteUnlocked(createDemoSnapshot(), id);
  }

  Future<DeleteDecision> _canDeleteUnlocked(
    Map<EntityId, OperationalMasterDataRecord> values,
    EntityId id,
  ) async {
    final record = values[id];
    if (record == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (record.isProtected) {
      return const DeleteDecision.blocked('لا يمكن حذف سجل نظام محمي');
    }
    if (record.relatedEntityId != null ||
        values.values.any((record) => record.parentId == id) ||
        await _isExternallyReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) {
    return _transactionRunner.run(() async {
      final staged = createDemoSnapshot();
      _captureIssuedNumbers(staged.values);
      final decision = await _canDeleteUnlocked(staged, id);
      if (!decision.isAllowed) {
        throw StateError(decision.reason ?? 'لا يمكن حذف السجل');
      }
      final existing = staged[id]!;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف البيانات الأساسية ${existing.name}',
          before: operationalMasterDataAuditSnapshot(existing),
          details: const {'permanent': true},
          entityType: 'operational_master_data',
          entityId: existing.id,
        ),
        permission: PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      );
      staged.remove(id);
      commitDemoSnapshot(staged);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  DemoPreparedBusinessAudit? _prepareRecordSaveAudit({
    required OperationalMasterDataRecord? before,
    required OperationalMasterDataRecord after,
  }) {
    final isCreate = before == null;
    return _businessAudit?.prepare(
      event: AuditEvent(
        action: isCreate ? AuditAction.create : AuditAction.update,
        outcome: AuditOutcome.success,
        summary: isCreate
            ? 'إضافة البيانات الأساسية ${after.name}'
            : 'تحديث البيانات الأساسية ${after.name}',
        before: before == null
            ? const <String, Object?>{}
            : operationalMasterDataAuditSnapshot(before),
        after: operationalMasterDataAuditSnapshot(after),
        entityType: 'operational_master_data',
        entityId: after.id,
      ),
      permission: PermissionCode(
        module: 'settings',
        action: PermissionAction.manage,
      ),
    );
  }

  int _nextNumber(
    OperationalMasterDataKind kind,
    EntityId? parentId,
  ) {
    return (_highestIssuedNumbers[(kind, parentId?.value)] ?? 0) + 1;
  }

  void _captureIssuedNumbers(
    Iterable<OperationalMasterDataRecord> records,
  ) {
    for (final record in records) {
      _recordIssuedNumber(record);
    }
  }

  void _recordIssuedNumber(OperationalMasterDataRecord record) {
    _issuedIds.add(record.id);
    final key = (record.kind, record.parentId?.value);
    (_issuedNumbers[key] ??= <int>{}).add(record.number);
    final current = _highestIssuedNumbers[key] ?? 0;
    if (record.number > current) {
      _highestIssuedNumbers[key] = record.number;
    }
  }

  EntityId _issueId(
    Map<EntityId, OperationalMasterDataRecord> staged,
    OperationalMasterDataKind kind,
  ) {
    while (true) {
      final sequence = _nextGeneratedIdSequence++;
      final candidate = EntityId(
        'local-${kind.name}-${sequence.toString().padLeft(6, '0')}',
      );
      if (!staged.containsKey(candidate) && !_issuedIds.contains(candidate)) {
        return candidate;
      }
    }
  }

  String _requireName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw StateError('أدخل الاسم أولاً');
    return normalized;
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
