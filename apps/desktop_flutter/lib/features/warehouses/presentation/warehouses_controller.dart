import 'package:flutter/foundation.dart';

import '../domain/warehouse.dart';

@immutable
class WarehousesState {
  const WarehousesState({
    required this.warehouses,
    required this.inventoryByWarehouse,
    this.query = '',
    this.selectedWarehouseId,
  });

  final List<Warehouse> warehouses;
  final Map<String, List<WarehouseInventoryItem>> inventoryByWarehouse;
  final String query;
  final String? selectedWarehouseId;

  WarehousesState copyWith({
    List<Warehouse>? warehouses,
    Map<String, List<WarehouseInventoryItem>>? inventoryByWarehouse,
    String? query,
    Object? selectedWarehouseId = _unchanged,
  }) {
    return WarehousesState(
      warehouses: warehouses ?? this.warehouses,
      inventoryByWarehouse:
          inventoryByWarehouse ?? this.inventoryByWarehouse,
      query: query ?? this.query,
      selectedWarehouseId: identical(selectedWarehouseId, _unchanged)
          ? this.selectedWarehouseId
          : selectedWarehouseId as String?,
    );
  }
}

const _unchanged = Object();

class WarehousesController extends ChangeNotifier {
  WarehousesController({
    List<Warehouse>? initialWarehouses,
    Map<String, List<WarehouseInventoryItem>>? initialInventory,
  }) : _state = WarehousesState(
          warehouses: List.unmodifiable(
            initialWarehouses ?? _demoWarehouses,
          ),
          inventoryByWarehouse: _freezeInventory(
            initialInventory ?? _demoInventory,
          ),
        );

  WarehousesState _state;

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
    final selectedId = _state.selectedWarehouseId;
    if (selectedId == null) return null;
    for (final warehouse in _state.warehouses) {
      if (warehouse.id == selectedId) return warehouse;
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

  int get selectedVisibleIndex =>
      _selectedVisibleIndex(visibleWarehouses);

  List<WarehouseInventoryItem> inventoryFor(String? warehouseId) {
    if (warehouseId == null) return const [];
    return _state.inventoryByWarehouse[warehouseId] ?? const [];
  }

  int materialCountFor(String warehouseId) =>
      inventoryFor(warehouseId)
          .where((item) => item.quantity != 0)
          .length;

  int totalQuantityFor(String warehouseId) =>
      inventoryFor(warehouseId).fold(
        0,
        (total, item) => total + item.quantity,
      );

  void search(String value) {
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    notifyListeners();
  }

  void select(String? warehouseId) {
    if (_state.selectedWarehouseId == warehouseId) return;
    _state = _state.copyWith(selectedWarehouseId: warehouseId);
    notifyListeners();
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

  void add(Warehouse warehouse) {
    final updatedInventory = {
      ..._state.inventoryByWarehouse,
      warehouse.id: const <WarehouseInventoryItem>[],
    };
    _state = _state.copyWith(
      warehouses: List.unmodifiable([..._state.warehouses, warehouse]),
      inventoryByWarehouse: _freezeInventory(updatedInventory),
      selectedWarehouseId: warehouse.id,
    );
    notifyListeners();
  }

  void update(Warehouse warehouse) {
    final index = _state.warehouses.indexWhere(
      (item) => item.id == warehouse.id,
    );
    if (index < 0) return;
    final updated = [..._state.warehouses]..[index] = warehouse;
    _state = _state.copyWith(warehouses: List.unmodifiable(updated));
    notifyListeners();
  }

  Warehouse? deleteSelected() {
    final selected = selectedWarehouse;
    if (selected == null || selected.isMain) return null;

    final updatedInventory = {
      for (final entry in _state.inventoryByWarehouse.entries)
        if (entry.key != selected.id) entry.key: entry.value,
    };
    _state = _state.copyWith(
      warehouses: List.unmodifiable(
        _state.warehouses.where(
          (warehouse) => warehouse.id != selected.id,
        ),
      ),
      inventoryByWarehouse: _freezeInventory(updatedInventory),
      selectedWarehouseId: null,
    );
    notifyListeners();
    return selected;
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
      (warehouse) => warehouse.id == _state.selectedWarehouseId,
    );
  }

  static Map<String, List<WarehouseInventoryItem>> _freezeInventory(
    Map<String, List<WarehouseInventoryItem>> source,
  ) {
    return Map.unmodifiable({
      for (final entry in source.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }
}

const _demoWarehouses = <Warehouse>[
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

const _demoInventory = <String, List<WarehouseInventoryItem>>{
  'warehouse-001': [
    WarehouseInventoryItem(
      id: 'inventory-001',
      productCode: 'P-1001',
      productName: 'طابعة ليزر',
      quantity: 18,
    ),
    WarehouseInventoryItem(
      id: 'inventory-002',
      productCode: 'P-1002',
      productName: 'حبر طابعة أسود',
      quantity: 64,
    ),
    WarehouseInventoryItem(
      id: 'inventory-003',
      productCode: 'P-1003',
      productName: 'ورق تصوير A4',
      quantity: 120,
    ),
    WarehouseInventoryItem(
      id: 'inventory-004',
      productCode: 'P-1004',
      productName: 'آلة حاسبة مكتبية',
      quantity: 25,
    ),
  ],
  'warehouse-002': [
    WarehouseInventoryItem(
      id: 'inventory-005',
      productCode: 'P-1001',
      productName: 'طابعة ليزر',
      quantity: 7,
    ),
    WarehouseInventoryItem(
      id: 'inventory-006',
      productCode: 'P-1003',
      productName: 'ورق تصوير A4',
      quantity: 45,
    ),
  ],
  'warehouse-003': [
    WarehouseInventoryItem(
      id: 'inventory-007',
      productCode: 'P-1002',
      productName: 'حبر طابعة أسود',
      quantity: 22,
    ),
    WarehouseInventoryItem(
      id: 'inventory-008',
      productCode: 'P-1004',
      productName: 'آلة حاسبة مكتبية',
      quantity: 11,
    ),
  ],
  'warehouse-004': [
    WarehouseInventoryItem(
      id: 'inventory-009',
      productCode: 'P-1003',
      productName: 'ورق تصوير A4',
      quantity: 32,
    ),
  ],
};
