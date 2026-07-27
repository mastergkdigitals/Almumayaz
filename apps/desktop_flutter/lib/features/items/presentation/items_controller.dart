import 'package:flutter/foundation.dart';

import '../domain/item.dart';

@immutable
class ItemsState {
  const ItemsState({
    required this.items,
    this.query = '',
    this.selectedItemId,
  });

  final List<Item> items;
  final String query;
  final String? selectedItemId;

  ItemsState copyWith({
    List<Item>? items,
    String? query,
    Object? selectedItemId = _unchanged,
  }) {
    return ItemsState(
      items: items ?? this.items,
      query: query ?? this.query,
      selectedItemId: identical(selectedItemId, _unchanged)
          ? this.selectedItemId
          : selectedItemId as String?,
    );
  }
}

const _unchanged = Object();

class ItemsController extends ChangeNotifier {
  ItemsController({List<Item>? initialItems})
      : _state = ItemsState(
          items: List.unmodifiable(initialItems ?? _demoItems),
        );

  static const groups = <ItemGroup>[
    ItemGroup(id: 'group-office', number: 1, name: 'أجهزة مكتبية'),
    ItemGroup(id: 'group-printing', number: 2, name: 'مستلزمات طباعة'),
    ItemGroup(id: 'group-stationery', number: 3, name: 'قرطاسية'),
  ];

  static const types = <ItemType>[
    ItemType(
      id: 'type-printers',
      groupId: 'group-office',
      number: 1,
      name: 'طابعات',
    ),
    ItemType(
      id: 'type-calculators',
      groupId: 'group-office',
      number: 2,
      name: 'آلات حاسبة',
    ),
    ItemType(
      id: 'type-toner',
      groupId: 'group-printing',
      number: 1,
      name: 'أحبار',
    ),
    ItemType(
      id: 'type-paper',
      groupId: 'group-printing',
      number: 2,
      name: 'ورق طباعة',
    ),
    ItemType(
      id: 'type-pens',
      groupId: 'group-stationery',
      number: 1,
      name: 'أقلام',
    ),
    ItemType(
      id: 'type-files',
      groupId: 'group-stationery',
      number: 2,
      name: 'ملفات',
    ),
  ];

  ItemsState _state;

  ItemsState get state => _state;

  List<Item> get visibleItems {
    final query = _state.query.trim().toLowerCase().replaceAll(',', '');
    if (query.isEmpty) return _state.items;
    return List.unmodifiable(
      _state.items.where(
        (item) =>
            item.searchText.replaceAll(',', '').contains(query),
      ),
    );
  }

  Item? get selectedItem {
    final selectedId = _state.selectedItemId;
    if (selectedId == null) return null;
    for (final item in _state.items) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  List<ItemType> typesFor(String groupId) {
    return List.unmodifiable(
      types.where((type) => type.groupId == groupId),
    );
  }

  ItemGroup groupById(String groupId) {
    return groups.firstWhere((group) => group.id == groupId);
  }

  ItemType typeById(String typeId) {
    return types.firstWhere((type) => type.id == typeId);
  }

  bool codeExists(String code, {String? exceptItemId}) {
    final normalized = code.trim().toLowerCase();
    return _state.items.any(
      (item) =>
          item.id != exceptItemId &&
          item.code.trim().toLowerCase() == normalized,
    );
  }

  int get selectedVisibleIndex => _selectedVisibleIndex(visibleItems);

  void search(String value) {
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    notifyListeners();
  }

  void select(String? itemId) {
    if (_state.selectedItemId == itemId) return;
    _state = _state.copyWith(selectedItemId: itemId);
    notifyListeners();
  }

  void first() => _selectAt(0);

  void previous() {
    final items = visibleItems;
    if (items.isEmpty) return;
    final index = _selectedVisibleIndex(items);
    if (index < 0) {
      _selectAt(items.length - 1);
      return;
    }
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final items = visibleItems;
    if (items.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(items);
    if (index < 0) {
      _selectAt(0);
      return;
    }
    if (index >= items.length - 1) {
      select(null);
      return;
    }
    _selectAt(index + 1);
  }

  void last() {
    final items = visibleItems;
    if (items.isEmpty) {
      select(null);
      return;
    }
    final index = _selectedVisibleIndex(items);
    if (index == items.length - 1) {
      select(null);
      return;
    }
    _selectAt(items.length - 1);
  }

  void add(Item item) {
    _state = _state.copyWith(
      items: List.unmodifiable([..._state.items, item]),
      selectedItemId: item.id,
    );
    notifyListeners();
  }

  void update(Item item) {
    final index = _state.items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;
    final updated = [..._state.items]..[index] = item;
    _state = _state.copyWith(items: List.unmodifiable(updated));
    notifyListeners();
  }

  Item? deleteSelected() {
    final selected = selectedItem;
    if (selected == null) return null;
    _state = _state.copyWith(
      items: List.unmodifiable(
        _state.items.where((item) => item.id != selected.id),
      ),
      selectedItemId: null,
    );
    notifyListeners();
    return selected;
  }

  void _selectAt(int index) {
    final items = visibleItems;
    if (items.isEmpty || index < 0 || index >= items.length) return;
    select(items[index].id);
  }

  int _selectedVisibleIndex(List<Item> items) {
    return items.indexWhere((item) => item.id == _state.selectedItemId);
  }
}

const _demoItems = <Item>[
  Item(
    id: 'item-001',
    code: 'P-1001',
    name: 'طابعة ليزر',
    barcode: '1000000000001',
    groupId: 'group-office',
    groupName: 'أجهزة مكتبية',
    typeId: 'type-printers',
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
    groupId: 'group-printing',
    groupName: 'مستلزمات طباعة',
    typeId: 'type-toner',
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
    groupId: 'group-printing',
    groupName: 'مستلزمات طباعة',
    typeId: 'type-paper',
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
    groupId: 'group-office',
    groupName: 'أجهزة مكتبية',
    typeId: 'type-calculators',
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
    groupId: 'group-stationery',
    groupName: 'قرطاسية',
    typeId: 'type-pens',
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
    groupId: 'group-stationery',
    groupName: 'قرطاسية',
    typeId: 'type-files',
    typeName: 'ملفات',
    salePriceIqd: 2500,
    salePriceUsd: 1.75,
    notes: '',
  ),
];
