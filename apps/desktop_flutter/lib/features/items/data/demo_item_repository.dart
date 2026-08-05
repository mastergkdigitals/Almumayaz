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
    ItemReferenceLookup? isReferenced,
  })  : _masterData = masterData,
        _isReferenced = isReferenced ?? _neverReferenced,
        super(
          initialValues: initialValues ?? demoItems(),
          idOf: (item) => item.entityId,
        );

  final OperationalMasterDataRepository _masterData;
  final ItemReferenceLookup _isReferenced;

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
    if (await _isReferenced(id)) {
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
        id: EntityId.demo('item', 1).value,
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
        id: EntityId.demo('item', 2).value,
        code: 'P-1002',
        name: 'حبر طابعة أسود',
        barcode: '1000000000002',
        groupId: EntityId.demo('item-group', 2).value,
        groupName: 'مستلزمات طباعة',
        typeId: EntityId.demo('item-type', 2).value,
        typeName: 'أحبار',
        salePriceIqd: 72000,
        salePriceUsd: 48,
        notes: '',
      ),
    ];
