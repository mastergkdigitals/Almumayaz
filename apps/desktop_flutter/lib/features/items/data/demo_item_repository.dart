import '../../../core/data/app_repository.dart';
import '../../../core/data/demo_transaction_runner.dart';
import '../../../core/domain/business_values.dart';
import '../../audit_log/data/demo_business_audit.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../permissions/domain/permission_models.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/item.dart';
import '../domain/item_repository.dart';

typedef ItemReferenceLookup = Future<bool> Function(EntityId itemId);

class DemoItemRepository extends InMemoryDemoRepository<Item>
    implements ItemRepository {
  DemoItemRepository({
    Iterable<Item>? initialValues,
    required OperationalMasterDataRepository masterData,
    Set<EntityId>? initiallyReferencedIds,
    ItemReferenceLookup? isReferenced,
    DemoTransactionRunner? transactionRunner,
    DemoBusinessAudit? businessAudit,
  })  : _masterData = masterData,
        _isReferenced = isReferenced ?? _neverReferenced,
        _transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _businessAudit = businessAudit,
        _initiallyReferencedIds = Set.unmodifiable(
          initiallyReferencedIds ?? const <EntityId>{},
        ),
        super(
          initialValues: initialValues ?? demoItems(),
          idOf: (item) => item.entityId,
        );

  final OperationalMasterDataRepository _masterData;
  final ItemReferenceLookup _isReferenced;
  final Set<EntityId> _initiallyReferencedIds;
  final DemoTransactionRunner _transactionRunner;
  final DemoBusinessAudit? _businessAudit;
  final Set<EntityId> _issuedIds = {};
  int _nextGeneratedIdSequence = 1;

  @override
  Future<List<Item>> search(String query) async {
    final normalized = query.trim().toLowerCase().replaceAll(',', '');
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where(
        (item) => item.searchText.replaceAll(',', '').contains(normalized),
      ),
    );
  }

  @override
  Future<List<ItemGroup>> getGroups() async {
    final records = await _masterData.getByKind(
      OperationalMasterDataKind.itemGroup,
    );
    return List.unmodifiable(
      records.map(
        (record) => ItemGroup.typed(
          entityId: record.id,
          number: record.number,
          name: record.name,
        ),
      ),
    );
  }

  @override
  Future<List<ItemType>> getTypes({EntityId? groupId}) async {
    final records = await _masterData.getByKind(
      OperationalMasterDataKind.itemType,
      parentId: groupId,
    );
    return List.unmodifiable(
      records.map(
        (record) => ItemType.typed(
          entityId: record.id,
          groupEntityId: record.parentId!,
          number: record.number,
          name: record.name,
        ),
      ),
    );
  }

  @override
  Future<Item> save(Item value) {
    return _transactionRunner.run(() => _saveUnlocked(value));
  }

  Future<Item> _saveUnlocked(Item value) async {
    final before = getDemoValue(value.entityId);
    _captureIssuedIds(await getAll());
    if (getDemoValue(value.entityId) == null &&
        _issuedIds.contains(value.entityId)) {
      throw StateError('معرف المادة مستخدم مسبقاً');
    }
    final groups = await getGroups();
    final types = await getTypes(groupId: value.groupEntityId);
    final group = groups.where(
      (candidate) => candidate.entityId == value.groupEntityId,
    );
    final type = types.where(
      (candidate) =>
          candidate.entityId == value.typeEntityId &&
          candidate.groupEntityId == value.groupEntityId,
    );
    if (group.length != 1 || type.length != 1) {
      throw StateError('مجموعة المادة أو نوعها غير موجود');
    }
    final duplicateCode = (await getAll()).any(
      (item) =>
          item.entityId != value.entityId &&
          item.code.trim().toLowerCase() == value.code.trim().toLowerCase(),
    );
    if (duplicateCode) throw StateError('رمز المادة مستخدم مسبقاً');
    final saved = value.copyWithTyped(
      groupName: group.single.name,
      typeName: type.single.name,
    );
    final isCreate = before == null;
    final audit = _businessAudit?.prepare(
      event: AuditEvent(
        action: isCreate ? AuditAction.create : AuditAction.update,
        outcome: AuditOutcome.success,
        summary: isCreate
            ? 'إضافة المادة ${saved.name}'
            : 'تحديث المادة ${saved.name}',
        before: before == null
            ? const <String, Object?>{}
            : itemAuditSnapshot(before),
        after: itemAuditSnapshot(saved),
        entityType: 'item',
        entityId: saved.entityId,
      ),
      permission: PermissionCode(
        module: 'items',
        action: isCreate ? PermissionAction.create : PermissionAction.update,
      ),
    );
    final staged = createDemoSnapshot()..[saved.entityId] = saved;
    commitDemoSnapshot(staged);
    _issuedIds.add(saved.entityId);
    if (audit != null) _businessAudit!.appendPrepared(audit);
    return saved;
  }

  @override
  Future<Item> quickCreate(ItemQuickCreateRequest request) {
    return _transactionRunner.run(() async {
      final code = request.code.trim();
      final name = request.name.trim();
      if (code.isEmpty) throw StateError('أدخل رمز المادة أولاً');
      if (name.isEmpty) throw StateError('أدخل اسم المادة أولاً');
      _captureIssuedIds(await getAll());
      return _saveUnlocked(
        Item.typed(
          entityId: _issueItemId(),
          code: code,
          name: name,
          barcode: request.barcode.trim(),
          groupEntityId: request.groupId,
          groupName: '',
          typeEntityId: request.typeId,
          typeName: '',
          iqdSalePrice: request.iqdSalePrice,
          usdSalePrice: request.usdSalePrice,
          notes: request.notes.trim(),
        ),
      );
    });
  }

  @override
  Future<void> delete(EntityId id) {
    return _transactionRunner.run(() async {
      _captureIssuedIds(await getAll());
      final decision = await canDelete(id);
      if (!decision.isAllowed) {
        throw StateError(decision.reason ?? 'لا يمكن حذف المادة');
      }
      final staged = createDemoSnapshot();
      final existing = staged[id]!;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف المادة ${existing.name}',
          before: itemAuditSnapshot(existing),
          details: const {'permanent': true},
          entityType: 'item',
          entityId: existing.entityId,
        ),
        permission: PermissionCode(
          module: 'items',
          action: PermissionAction.delete,
        ),
      );
      staged.remove(id);
      commitDemoSnapshot(staged);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    if (await getById(id) == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (_initiallyReferencedIds.contains(id) || await _isReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  void _captureIssuedIds(Iterable<Item> items) {
    _issuedIds.addAll(items.map((item) => item.entityId));
  }

  EntityId _issueItemId() {
    while (true) {
      final sequence = _nextGeneratedIdSequence++;
      final candidate = EntityId(
        'local-item-${sequence.toString().padLeft(6, '0')}',
      );
      if (!_issuedIds.contains(candidate)) return candidate;
    }
  }
}

Future<bool> _neverReferenced(EntityId _) async => false;

Item _demoItem({
  required String id,
  required String code,
  required String name,
  required String barcode,
  required EntityId groupId,
  required String groupName,
  required EntityId typeId,
  required String typeName,
  required num salePriceIqd,
  required num salePriceUsd,
  required String notes,
}) {
  return Item.typed(
    entityId: EntityId(id),
    code: code,
    name: name,
    barcode: barcode,
    groupEntityId: groupId,
    groupName: groupName,
    typeEntityId: typeId,
    typeName: typeName,
    iqdSalePrice: Money.fromMajor(salePriceIqd, AppCurrency.iqd),
    usdSalePrice: Money.fromMajor(salePriceUsd, AppCurrency.usd),
    notes: notes,
  );
}

List<Item> demoItems() => [
      _demoItem(
        id: 'item-001',
        code: 'P-1001',
        name: 'طابعة ليزر',
        barcode: '1000000000001',
        groupId: EntityId.demo('item-group', 1),
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 1),
        typeName: 'طابعات',
        salePriceIqd: 285000,
        salePriceUsd: 190,
        notes: '',
      ),
      _demoItem(
        id: 'item-002',
        code: 'P-1002',
        name: 'حبر طابعة أسود',
        barcode: '1000000000002',
        groupId: EntityId.demo('item-group', 2),
        groupName: 'مستلزمات طباعة',
        typeId: EntityId.demo('item-type', 3),
        typeName: 'أحبار',
        salePriceIqd: 72000,
        salePriceUsd: 48,
        notes: '',
      ),
      _demoItem(
        id: 'item-003',
        code: 'P-1003',
        name: 'ورق تصوير A4',
        barcode: '1000000000003',
        groupId: EntityId.demo('item-group', 2),
        groupName: 'مستلزمات طباعة',
        typeId: EntityId.demo('item-type', 4),
        typeName: 'ورق طباعة',
        salePriceIqd: 8500,
        salePriceUsd: 5.75,
        notes: 'رزمة 500 ورقة',
      ),
      _demoItem(
        id: 'item-004',
        code: 'P-1004',
        name: 'آلة حاسبة مكتبية',
        barcode: '1000000000004',
        groupId: EntityId.demo('item-group', 1),
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 2),
        typeName: 'آلات حاسبة',
        salePriceIqd: 24000,
        salePriceUsd: 16,
        notes: '',
      ),
      _demoItem(
        id: 'item-005',
        code: 'P-1005',
        name: 'قلم جاف أزرق',
        barcode: '1000000000005',
        groupId: EntityId.demo('item-group', 3),
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 5),
        typeName: 'أقلام',
        salePriceIqd: 750,
        salePriceUsd: 0.5,
        notes: '',
      ),
      _demoItem(
        id: 'item-006',
        code: 'P-1006',
        name: 'ملف حفظ مستندات',
        barcode: '1000000000006',
        groupId: EntityId.demo('item-group', 3),
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 6),
        typeName: 'ملفات',
        salePriceIqd: 2500,
        salePriceUsd: 1.75,
        notes: '',
      ),
      _demoItem(
        id: 'item-007',
        code: 'P-1007',
        name: 'طابعة حرارية',
        barcode: '1000000000007',
        groupId: EntityId.demo('item-group', 1),
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 1),
        typeName: 'طابعات',
        salePriceIqd: 1179000,
        salePriceUsd: 900,
        notes: '',
      ),
      _demoItem(
        id: 'item-008',
        code: 'P-1008',
        name: 'ماسح باركود',
        barcode: '1000000000008',
        groupId: EntityId.demo('item-group', 1),
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 7),
        typeName: 'ماسحات باركود',
        salePriceIqd: 262000,
        salePriceUsd: 200,
        notes: '',
      ),
      _demoItem(
        id: 'item-009',
        code: 'P-1009',
        name: 'دباسة',
        barcode: '1000000000009',
        groupId: EntityId.demo('item-group', 3),
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 8),
        typeName: 'دباسات',
        salePriceIqd: 10000,
        salePriceUsd: 7,
        notes: '',
      ),
      _demoItem(
        id: 'item-010',
        code: 'P-1010',
        name: 'دفتر ملاحظات',
        barcode: '1000000000010',
        groupId: EntityId.demo('item-group', 3),
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 9),
        typeName: 'دفاتر',
        salePriceIqd: 35000,
        salePriceUsd: 25,
        notes: '',
      ),
    ];
