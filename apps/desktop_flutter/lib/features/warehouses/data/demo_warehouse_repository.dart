import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/inventory_records.dart';
import '../domain/warehouse.dart';
import '../domain/warehouse_repository.dart';

typedef WarehouseReferenceExists = Future<bool> Function(EntityId id);

class DemoWarehouseRepository extends InMemoryDemoRepository<Warehouse>
    implements WarehouseRepository {
  DemoWarehouseRepository({
    Iterable<Warehouse>? initialValues,
    Iterable<InventoryBalance>? initialInventory,
    Iterable<InventoryTransfer>? initialTransfers,
    required WarehouseReferenceExists itemExists,
    WarehouseReferenceExists? isExternallyReferenced,
  })  : _itemExists = itemExists,
        _isExternallyReferenced =
            isExternallyReferenced ?? _neverReferenced,
        _inventory = {
          for (final balance in initialInventory ?? demoInventory())
            balance.id: balance,
        },
        _transfers = List.of(
          initialTransfers ?? demoInventoryTransfers(),
        ),
        super(
          initialValues: initialValues ?? demoWarehouses(),
          idOf: (warehouse) => warehouse.entityId,
        );

  final WarehouseReferenceExists _itemExists;
  final WarehouseReferenceExists _isExternallyReferenced;
  final Map<EntityId, InventoryBalance> _inventory;
  final List<InventoryTransfer> _transfers;

  @override
  Future<List<Warehouse>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where((warehouse) => warehouse.searchText.contains(normalized)),
    );
  }

  @override
  Future<List<InventoryBalance>> getInventory(EntityId warehouseId) async {
    if (await getById(warehouseId) == null) {
      throw StateError('المخزن غير موجود');
    }
    return List.unmodifiable(
      _inventory.values.where(
        (balance) => balance.warehouseId == warehouseId,
      ),
    );
  }

  @override
  Future<List<InventoryTransfer>> getTransfers() async {
    return List.unmodifiable(_transfers.reversed);
  }

  @override
  Future<InventoryTransfer> transfer(InventoryTransferDraft draft) {
    return _performTransfer(
      draft,
      createdAt: draft.createdAt ?? AuditTimestamp(DateTime.now()),
    );
  }

  @override
  Future<InventoryTransfer> reverseTransfer(
    EntityId transferId, {
    AuditTimestamp? createdAt,
  }) async {
    InventoryTransfer? original;
    for (final transfer in _transfers) {
      if (transfer.id == transferId) {
        original = transfer;
        break;
      }
    }
    final originalTransfer = original;
    if (originalTransfer == null) {
      throw StateError('النقل المخزني غير موجود');
    }
    if (originalTransfer.reversalOfId != null ||
        _transfers.any(
          (entry) => entry.reversalOfId == originalTransfer.id,
        )) {
      throw StateError('لا يمكن عكس هذا النقل مرة أخرى');
    }
    return _performTransfer(
      InventoryTransferDraft(
        fromWarehouseId: originalTransfer.toWarehouseId,
        toWarehouseId: originalTransfer.fromWarehouseId,
        lines: originalTransfer.lines,
      ),
      createdAt: createdAt ?? AuditTimestamp(DateTime.now()),
      reversalOfId: originalTransfer.id,
    );
  }

  Future<InventoryTransfer> _performTransfer(
    InventoryTransferDraft draft, {
    required AuditTimestamp createdAt,
    EntityId? reversalOfId,
  }) async {
    if (await getById(draft.fromWarehouseId) == null ||
        await getById(draft.toWarehouseId) == null) {
      throw StateError('أحد المخازن المحددة غير موجود');
    }

    final uniqueItems = <EntityId>{};
    for (final line in draft.lines) {
      if (!uniqueItems.add(line.itemId)) {
        throw StateError('لا يمكن تكرار المادة في النقل نفسه');
      }
      if (!await _itemExists(line.itemId)) {
        throw StateError('إحدى المواد المحددة غير موجودة');
      }
      final source = _findBalance(draft.fromWarehouseId, line.itemId);
      if (source == null || source.quantity.value < line.quantity.value) {
        throw StateError('الكمية غير كافية في المخزن المصدر');
      }
    }

    for (final line in draft.lines) {
      final source = _findBalance(draft.fromWarehouseId, line.itemId)!;
      final destination = _findBalance(draft.toWarehouseId, line.itemId);
      _inventory[source.id] = source.copyWith(
        quantity: WholeQuantity(source.quantity.value - line.quantity.value),
      );
      if (destination == null) {
        final id = EntityId(
          'inventory-${draft.toWarehouseId.value}-${line.itemId.value}',
        );
        _inventory[id] = InventoryBalance(
          id: id,
          warehouseId: draft.toWarehouseId,
          itemId: line.itemId,
          quantity: WholeQuantity(line.quantity.value),
        );
      } else {
        _inventory[destination.id] = destination.copyWith(
          quantity: WholeQuantity(
            destination.quantity.value + line.quantity.value,
          ),
        );
      }
    }

    final number = _nextTransferNumber;
    final transfer = InventoryTransfer(
      id: EntityId.demo('inventory-transfer', number),
      documentNumber: number,
      createdAt: createdAt,
      fromWarehouseId: draft.fromWarehouseId,
      toWarehouseId: draft.toWarehouseId,
      lines: draft.lines,
      reversalOfId: reversalOfId,
    );
    _transfers.add(transfer);
    return transfer;
  }

  int get _nextTransferNumber {
    if (_transfers.isEmpty) return 1;
    return _transfers
            .map((transfer) => transfer.documentNumber)
            .reduce((first, second) => first > second ? first : second) +
        1;
  }

  InventoryBalance? _findBalance(EntityId warehouseId, EntityId itemId) {
    for (final balance in _inventory.values) {
      if (balance.warehouseId == warehouseId && balance.itemId == itemId) {
        return balance;
      }
    }
    return null;
  }

  @override
  Future<bool> referencesItem(EntityId itemId) async {
    return _inventory.values.any(
          (balance) => balance.itemId == itemId && !balance.quantity.isZero,
        ) ||
        _transfers.any(
          (transfer) => transfer.lines.any((line) => line.itemId == itemId),
        );
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final warehouse = await getById(id);
    if (warehouse == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    final hasInventory = _inventory.values.any(
      (balance) => balance.warehouseId == id && !balance.quantity.isZero,
    );
    final hasTransfer = _transfers.any(
      (transfer) =>
          transfer.fromWarehouseId == id || transfer.toWarehouseId == id,
    );
    if (warehouse.isMain ||
        hasInventory ||
        hasTransfer ||
        await _isExternallyReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }
}

Future<bool> _neverReferenced(EntityId _) async => false;

List<Warehouse> demoWarehouses() => [
      Warehouse(
        id: 'warehouse-001',
        number: 1,
        name: 'المخزن الرئيسي',
        location: 'بغداد - الشورجة',
        notes: 'المخزن الرئيسي للشركة',
        isMain: true,
      ),
      Warehouse(
        id: 'warehouse-002',
        number: 2,
        name: 'مخزن الكرادة',
        location: 'بغداد - الكرادة',
        notes: '',
      ),
      Warehouse(
        id: 'warehouse-003',
        number: 3,
        name: 'مخزن البصرة',
        location: 'البصرة - العشار',
        notes: 'مخزن فرع البصرة',
      ),
      Warehouse(
        id: 'warehouse-004',
        number: 4,
        name: 'مخزن أربيل',
        location: 'أربيل - المنطقة الصناعية',
        notes: '',
      ),
    ];

List<InventoryBalance> demoInventory() => [
      InventoryBalance(
        id: EntityId('inventory-001'),
        warehouseId: EntityId('warehouse-001'),
        itemId: EntityId('item-001'),
        quantity: WholeQuantity(18),
      ),
      InventoryBalance(
        id: EntityId('inventory-002'),
        warehouseId: EntityId('warehouse-001'),
        itemId: EntityId('item-002'),
        quantity: WholeQuantity(64),
      ),
      InventoryBalance(
        id: EntityId('inventory-003'),
        warehouseId: EntityId('warehouse-001'),
        itemId: EntityId('item-003'),
        quantity: WholeQuantity(120),
      ),
      InventoryBalance(
        id: EntityId('inventory-004'),
        warehouseId: EntityId('warehouse-001'),
        itemId: EntityId('item-004'),
        quantity: WholeQuantity(25),
      ),
      InventoryBalance(
        id: EntityId('inventory-005'),
        warehouseId: EntityId('warehouse-002'),
        itemId: EntityId('item-001'),
        quantity: WholeQuantity(7),
      ),
      InventoryBalance(
        id: EntityId('inventory-006'),
        warehouseId: EntityId('warehouse-002'),
        itemId: EntityId('item-003'),
        quantity: WholeQuantity(45),
      ),
      InventoryBalance(
        id: EntityId('inventory-007'),
        warehouseId: EntityId('warehouse-003'),
        itemId: EntityId('item-002'),
        quantity: WholeQuantity(22),
      ),
      InventoryBalance(
        id: EntityId('inventory-008'),
        warehouseId: EntityId('warehouse-003'),
        itemId: EntityId('item-004'),
        quantity: WholeQuantity(11),
      ),
      InventoryBalance(
        id: EntityId('inventory-009'),
        warehouseId: EntityId('warehouse-004'),
        itemId: EntityId('item-003'),
        quantity: WholeQuantity(32),
      ),
    ];

List<InventoryTransfer> demoInventoryTransfers() => [
      InventoryTransfer(
        id: EntityId('transfer-103'),
        documentNumber: 103,
        createdAt: AuditTimestamp(DateTime(2026, 7, 22)),
        fromWarehouseId: EntityId('warehouse-003'),
        toWarehouseId: EntityId('warehouse-001'),
        lines: [
          InventoryTransferLine(
            itemId: EntityId('item-002'),
            quantity: WholeQuantity(5),
          ),
          InventoryTransferLine(
            itemId: EntityId('item-004'),
            quantity: WholeQuantity(2),
          ),
        ],
      ),
      InventoryTransfer(
        id: EntityId('transfer-104'),
        documentNumber: 104,
        createdAt: AuditTimestamp(DateTime(2026, 7, 24)),
        fromWarehouseId: EntityId('warehouse-001'),
        toWarehouseId: EntityId('warehouse-002'),
        lines: [
          InventoryTransferLine(
            itemId: EntityId('item-003'),
            quantity: WholeQuantity(20),
          ),
        ],
      ),
    ];
