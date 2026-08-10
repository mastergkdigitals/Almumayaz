import 'package:flutter/foundation.dart';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../items/domain/item_repository.dart';
import '../domain/inventory_records.dart';
import '../domain/warehouse.dart';
import '../domain/warehouse_repository.dart';

@immutable
class WarehousesState {
  const WarehousesState({
    this.dataState = const AppDataState.loading(),
    this.inventoryByWarehouse = const {},
    this.transferRecords = const [],
    this.query = '',
    this.selectedWarehouseEntityId,
  });

  final AppDataState<List<Warehouse>> dataState;
  final Map<EntityId, List<WarehouseInventoryItem>> inventoryByWarehouse;
  final List<WarehouseTransferRecord> transferRecords;
  final String query;
  final EntityId? selectedWarehouseEntityId;
  String? get selectedWarehouseId => selectedWarehouseEntityId?.value;

  List<Warehouse> get warehouses => dataState.data ?? const [];

  WarehousesState copyWith({
    AppDataState<List<Warehouse>>? dataState,
    Map<EntityId, List<WarehouseInventoryItem>>? inventoryByWarehouse,
    List<WarehouseTransferRecord>? transferRecords,
    String? query,
    Object? selectedWarehouseEntityId = _unchanged,
  }) {
    return WarehousesState(
      dataState: dataState ?? this.dataState,
      inventoryByWarehouse:
          inventoryByWarehouse ?? this.inventoryByWarehouse,
      transferRecords: transferRecords ?? this.transferRecords,
      query: query ?? this.query,
      selectedWarehouseEntityId:
          identical(selectedWarehouseEntityId, _unchanged)
              ? this.selectedWarehouseEntityId
              : selectedWarehouseEntityId as EntityId?,
    );
  }
}

const _unchanged = Object();

class WarehousesController extends ChangeNotifier {
  WarehousesController({
    required WarehouseRepository repository,
    required ItemRepository itemRepository,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _itemRepository = itemRepository,
        _onDataChanged = onDataChanged;

  final WarehouseRepository _repository;
  final ItemRepository _itemRepository;
  final VoidCallback? _onDataChanged;
  WarehousesState _state = const WarehousesState();
  Map<String, EntityId> _itemIdsByProductCode = const {};
  bool _isDisposed = false;
  int _loadGeneration = 0;

  WarehousesState get state => _state;

  List<Warehouse> get visibleWarehouses {
    final query = _state.query.trim().toLowerCase();
    if (query.isEmpty) return _state.warehouses;
    return List.unmodifiable(
      _state.warehouses.where(
        (warehouse) => warehouse.searchText.contains(query),
      ),
    );
  }

  Warehouse? get selectedWarehouse {
    final selectedId = _state.selectedWarehouseEntityId;
    if (selectedId == null) return null;
    for (final warehouse in _state.warehouses) {
      if (warehouse.entityId == selectedId) return warehouse;
    }
    return null;
  }

  int get nextNumber {
    if (_state.warehouses.isEmpty) return 1;
    return _state.warehouses
            .map((warehouse) => warehouse.number)
            .reduce((first, second) => first > second ? first : second) +
        1;
  }

  int get nextTransferNumber {
    if (_state.transferRecords.isEmpty) return 1;
    return _state.transferRecords
            .map((transfer) => transfer.number)
            .reduce((first, second) => first > second ? first : second) +
        1;
  }

  int get selectedVisibleIndex => _selectedVisibleIndex(visibleWarehouses);

  List<WarehouseInventoryItem> inventoryFor(String? warehouseId) {
    if (warehouseId == null) return const [];
    return _state.inventoryByWarehouse[EntityId(warehouseId)] ?? const [];
  }

  int materialCountFor(String warehouseId) => inventoryFor(warehouseId)
      .where((item) => item.quantity != 0)
      .length;

  int totalQuantityFor(String warehouseId) => inventoryFor(warehouseId).fold(
        0,
        (total, item) => total + item.quantity,
      );

  bool isWarehouseReferenced(String warehouseId) {
    final hasInventory = inventoryFor(warehouseId).any(
      (item) => item.quantity != 0,
    );
    final hasTransfer = _state.transferRecords.any(
      (transfer) =>
          transfer.fromWarehouseId == warehouseId ||
          transfer.toWarehouseId == warehouseId,
    );
    return hasInventory || hasTransfer;
  }

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_loadGeneration;
    _state = _state.copyWith(dataState: const AppDataState.loading());
    _notifyListenersIfActive();
    try {
      final warehouses = await _repository.getAll();
      final items = await _itemRepository.getAll();
      final transfers = await _repository.getTransfers();
      if (_loadIsStale(generation)) return;

      final warehousesById = {
        for (final warehouse in warehouses) warehouse.entityId: warehouse,
      };
      final itemsById = {for (final item in items) item.entityId: item};
      final inventory = <EntityId, List<WarehouseInventoryItem>>{};
      for (final warehouse in warehouses) {
        final balances = await _repository.getInventory(warehouse.entityId);
        if (_loadIsStale(generation)) return;
        final resolvedBalances = <WarehouseInventoryItem>[];
        for (final balance in balances) {
          final item = itemsById[balance.itemId];
          if (item == null) {
            _setMissingReference(
              'تعذر العثور على مادة مرتبطة بمخزون ${warehouse.name}',
              generation,
            );
            return;
          }
          resolvedBalances.add(
            WarehouseInventoryItem.typed(
              balanceId: balance.id,
              productCode: item.code,
              productName: item.name,
              stockQuantity: balance.quantity,
            ),
          );
        }
        inventory[warehouse.entityId] = List.unmodifiable(resolvedBalances);
      }

      final resolvedTransfers = <WarehouseTransferRecord>[];
      for (final transfer in transfers) {
        final source = warehousesById[transfer.fromWarehouseId];
        final destination = warehousesById[transfer.toWarehouseId];
        if (source == null || destination == null) {
          _setMissingReference(
            'تعذر العثور على مخزن مرتبط بسجل النقل رقم '
            '${transfer.documentNumber}',
            generation,
          );
          return;
        }
        final lines = <WarehouseTransferLine>[];
        for (final line in transfer.lines) {
          final item = itemsById[line.itemId];
          if (item == null) {
            _setMissingReference(
              'تعذر العثور على مادة مرتبطة بسجل النقل رقم '
              '${transfer.documentNumber}',
              generation,
            );
            return;
          }
          lines.add(
            WarehouseTransferLine.typed(
              productCode: item.code,
              productName: item.name,
              wholeQuantity: line.quantity,
            ),
          );
        }
        resolvedTransfers.add(
          WarehouseTransferRecord.typed(
            entityId: transfer.id,
            number: transfer.documentNumber,
            createdTimestamp: transfer.createdAt,
            fromWarehouseEntityId: source.entityId,
            fromWarehouseName: source.name,
            toWarehouseEntityId: destination.entityId,
            toWarehouseName: destination.name,
            lines: List.unmodifiable(lines),
            reversalOfEntityId: transfer.reversalOfId,
          ),
        );
      }

      _itemIdsByProductCode = Map.unmodifiable({
        for (final item in items) item.code: item.entityId,
      });
      _state = _state.copyWith(
        dataState: warehouses.isEmpty
            ? const AppDataState.empty(
                message: 'لا توجد مخازن مسجلة حالياً.',
              )
            : AppDataState.ready(List.unmodifiable(warehouses)),
        inventoryByWarehouse: Map.unmodifiable(inventory),
        transferRecords: List.unmodifiable(resolvedTransfers),
        selectedWarehouseEntityId: warehouses.any(
          (warehouse) =>
              warehouse.entityId == _state.selectedWarehouseEntityId,
        )
            ? _state.selectedWarehouseEntityId
            : null,
      );
      _notifyListenersIfActive();
    } catch (error) {
      if (_loadIsStale(generation)) return;
      _state = _state.copyWith(
        dataState: AppDataState.error(
          error,
          message: 'تعذر تحميل بيانات المخازن.',
        ),
      );
      _notifyListenersIfActive();
    }
  }

  void search(String value) {
    if (_isDisposed || _state.query == value) return;
    _state = _state.copyWith(query: value);
    _notifyListenersIfActive();
  }

  void select(String? warehouseId) {
    if (_isDisposed) return;
    final entityId = warehouseId == null ? null : EntityId(warehouseId);
    if (_state.selectedWarehouseEntityId == entityId) return;
    _state = _state.copyWith(selectedWarehouseEntityId: entityId);
    _notifyListenersIfActive();
  }

  void first() => _selectAt(0);

  void previous() {
    final warehouses = visibleWarehouses;
    if (warehouses.isEmpty) return;
    final index = _selectedVisibleIndex(warehouses);
    if (index < 0) {
      _selectAt(warehouses.length - 1);
      return;
    }
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final warehouses = visibleWarehouses;
    if (warehouses.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(warehouses);
    if (index < 0) {
      _selectAt(0);
      return;
    }
    if (index >= warehouses.length - 1) {
      select(null);
      return;
    }
    _selectAt(index + 1);
  }

  void last() {
    final warehouses = visibleWarehouses;
    if (warehouses.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(warehouses);
    if (index == warehouses.length - 1) {
      select(null);
      return;
    }
    _selectAt(warehouses.length - 1);
  }

  Future<Warehouse> add(Warehouse warehouse) async {
    final saved = await _repository.save(warehouse);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.id);
    _onDataChanged?.call();
    return selectedWarehouse ?? saved;
  }

  Future<Warehouse> update(Warehouse warehouse) async {
    final saved = await _repository.save(warehouse);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.id);
    _onDataChanged?.call();
    return selectedWarehouse ?? saved;
  }

  Future<DeleteDecision> canDeleteSelected() async {
    final selected = selectedWarehouse;
    if (selected == null) {
      return const DeleteDecision.blocked('اختر مخزناً من الجدول لحذفه');
    }
    return _repository.canDelete(selected.entityId);
  }

  Future<Warehouse?> deleteSelected() async {
    final selected = selectedWarehouse;
    if (selected == null) return null;
    final decision = await _repository.canDelete(selected.entityId);
    if (!decision.isAllowed) return null;
    await _repository.delete(selected.entityId);
    if (_isDisposed) return selected;
    await load();
    if (_isDisposed) return selected;
    _onDataChanged?.call();
    return selected;
  }

  Future<bool> transferInventory({
    required String fromWarehouseId,
    required String toWarehouseId,
    required Map<String, int> quantitiesByProductCode,
    DateTime? createdAt,
  }) async {
    if (_isDisposed || quantitiesByProductCode.isEmpty) return false;
    try {
      final lines = <InventoryTransferLine>[];
      for (final entry in quantitiesByProductCode.entries) {
        final itemId = _itemIdsByProductCode[entry.key];
        if (itemId == null || entry.value <= 0) return false;
        lines.add(
          InventoryTransferLine(
            itemId: itemId,
            quantity: WholeQuantity(entry.value),
          ),
        );
      }
      await _repository.transfer(
        InventoryTransferDraft(
          fromWarehouseId: EntityId(fromWarehouseId),
          toWarehouseId: EntityId(toWarehouseId),
          lines: lines,
          createdAt:
              createdAt == null ? null : AuditTimestamp(createdAt),
        ),
      );
      if (_isDisposed) return true;
      await load();
      if (!_isDisposed) _onDataChanged?.call();
      return true;
    } on ArgumentError {
      return false;
    } on StateError {
      return false;
    }
  }

  Future<bool> reverseTransfer(
    String transferId, {
    DateTime? createdAt,
  }) async {
    if (_isDisposed) return false;
    try {
      await _repository.reverseTransfer(
        EntityId(transferId),
        createdAt: createdAt == null ? null : AuditTimestamp(createdAt),
      );
      if (_isDisposed) return true;
      await load();
      if (!_isDisposed) _onDataChanged?.call();
      return true;
    } on ArgumentError {
      return false;
    } on StateError {
      return false;
    }
  }

  void _setMissingReference(String message, int generation) {
    if (_loadIsStale(generation)) return;
    _state = _state.copyWith(
      dataState: AppDataState.missingReference(message),
    );
    _notifyListenersIfActive();
  }

  bool _loadIsStale(int generation) {
    return _isDisposed || generation != _loadGeneration;
  }

  void _notifyListenersIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  void _selectAt(int index) {
    final warehouses = visibleWarehouses;
    if (warehouses.isEmpty || index < 0 || index >= warehouses.length) {
      return;
    }
    select(warehouses[index].id);
  }

  int _selectedVisibleIndex(List<Warehouse> warehouses) {
    return warehouses.indexWhere(
      (warehouse) => warehouse.entityId == _state.selectedWarehouseEntityId,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
