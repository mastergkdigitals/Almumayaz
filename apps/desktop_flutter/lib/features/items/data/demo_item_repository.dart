import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
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
  })  : _masterData = masterData,
        _isReferenced = isReferenced ?? _neverReferenced,
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
        (record) => ItemGroup(
          id: record.id.value,
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
        (record) => ItemType(
          id: record.id.value,
          groupId: record.parentId!.value,
          number: record.number,
          name: record.name,
        ),
      ),
    );
  }

  @override
  Future<Item> save(Item value) async {
    final groups = await getGroups();
    final types = await getTypes(groupId: EntityId(value.groupId));
    final groupExists = groups.any((group) => group.id == value.groupId);
    final typeExists = types.any(
      (type) => type.id == value.typeId && type.groupId == value.groupId,
    );
    if (!groupExists || !typeExists) {
      throw StateError('مجموعة المادة أو نوعها غير موجود');
    }
    final duplicateCode = (await getAll()).any(
      (item) =>
          item.entityId != value.entityId &&
          item.code.trim().toLowerCase() == value.code.trim().toLowerCase(),
    );
    if (duplicateCode) throw StateError('رمز المادة مستخدم مسبقاً');
    return super.save(value);
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
}

Future<bool> _neverReferenced(EntityId _) async => false;

List<Item> demoItems() => [
      Item(
        id: 'item-001',
        code: 'P-1001',
        name: 'طابعة ليزر',
        barcode: '1000000000001',
        groupId: EntityId.demo('item-group', 1).value,
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 1).value,
        typeName: 'طابعات',
        salePriceIqd: 285000,
        salePriceUsd: 190,
        notes: '',
      ),
      Item(
        id: 'item-002',
        code: 'P-1002',
        name: 'حبر طابعة أسود',
        barcode: '1000000000002',
        groupId: EntityId.demo('item-group', 2).value,
        groupName: 'مستلزمات طباعة',
        typeId: EntityId.demo('item-type', 3).value,
        typeName: 'أحبار',
        salePriceIqd: 72000,
        salePriceUsd: 48,
        notes: '',
      ),
      Item(
        id: 'item-003',
        code: 'P-1003',
        name: 'ورق تصوير A4',
        barcode: '1000000000003',
        groupId: EntityId.demo('item-group', 2).value,
        groupName: 'مستلزمات طباعة',
        typeId: EntityId.demo('item-type', 4).value,
        typeName: 'ورق طباعة',
        salePriceIqd: 8500,
        salePriceUsd: 5.75,
        notes: 'رزمة 500 ورقة',
      ),
      Item(
        id: 'item-004',
        code: 'P-1004',
        name: 'آلة حاسبة مكتبية',
        barcode: '1000000000004',
        groupId: EntityId.demo('item-group', 1).value,
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 2).value,
        typeName: 'آلات حاسبة',
        salePriceIqd: 24000,
        salePriceUsd: 16,
        notes: '',
      ),
      Item(
        id: 'item-005',
        code: 'P-1005',
        name: 'قلم جاف أزرق',
        barcode: '1000000000005',
        groupId: EntityId.demo('item-group', 3).value,
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 5).value,
        typeName: 'أقلام',
        salePriceIqd: 750,
        salePriceUsd: 0.5,
        notes: '',
      ),
      Item(
        id: 'item-006',
        code: 'P-1006',
        name: 'ملف حفظ مستندات',
        barcode: '1000000000006',
        groupId: EntityId.demo('item-group', 3).value,
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 6).value,
        typeName: 'ملفات',
        salePriceIqd: 2500,
        salePriceUsd: 1.75,
        notes: '',
      ),
      Item(
        id: 'item-007',
        code: 'P-1007',
        name: 'طابعة حرارية',
        barcode: '1000000000007',
        groupId: EntityId.demo('item-group', 1).value,
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 1).value,
        typeName: 'طابعات',
        salePriceIqd: 1179000,
        salePriceUsd: 900,
        notes: '',
      ),
      Item(
        id: 'item-008',
        code: 'P-1008',
        name: 'ماسح باركود',
        barcode: '1000000000008',
        groupId: EntityId.demo('item-group', 1).value,
        groupName: 'أجهزة مكتبية',
        typeId: EntityId.demo('item-type', 7).value,
        typeName: 'ماسحات باركود',
        salePriceIqd: 262000,
        salePriceUsd: 200,
        notes: '',
      ),
      Item(
        id: 'item-009',
        code: 'P-1009',
        name: 'دباسة',
        barcode: '1000000000009',
        groupId: EntityId.demo('item-group', 3).value,
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 8).value,
        typeName: 'دباسات',
        salePriceIqd: 10000,
        salePriceUsd: 7,
        notes: '',
      ),
      Item(
        id: 'item-010',
        code: 'P-1010',
        name: 'دفتر ملاحظات',
        barcode: '1000000000010',
        groupId: EntityId.demo('item-group', 3).value,
        groupName: 'قرطاسية',
        typeId: EntityId.demo('item-type', 9).value,
        typeName: 'دفاتر',
        salePriceIqd: 35000,
        salePriceUsd: 25,
        notes: '',
      ),
    ];
