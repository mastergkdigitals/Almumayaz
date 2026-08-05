import 'package:flutter/foundation.dart';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/item.dart';
import '../domain/item_repository.dart';

@immutable
class ItemsState {
  const ItemsState({
    this.dataState = const AppDataState.loading(),
    this.query = '',
    this.selectedItemEntityId,
    this.groups = const [],
    this.types = const [],
  });

  final AppDataState<List<Item>> dataState;
  final String query;
  final EntityId? selectedItemEntityId;
  String? get selectedItemId => selectedItemEntityId?.value;
  final List<ItemGroup> groups;
  final List<ItemType> types;

  List<Item> get items => dataState.data ?? const [];

  ItemsState copyWith({
    AppDataState<List<Item>>? dataState,
    String? query,
    Object? selectedItemEntityId = _unchanged,
    List<ItemGroup>? groups,
    List<ItemType>? types,
  }) {
    return ItemsState(
      dataState: dataState ?? this.dataState,
      query: query ?? this.query,
      selectedItemEntityId: identical(selectedItemEntityId, _unchanged)
          ? this.selectedItemEntityId
          : selectedItemEntityId as EntityId?,
      groups: groups ?? this.groups,
      types: types ?? this.types,
    );
  }
}

const _unchanged = Object();

class ItemsController extends ChangeNotifier {
  ItemsController({
    required ItemRepository repository,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _onDataChanged = onDataChanged;

  final ItemRepository _repository;
  final VoidCallback? _onDataChanged;
  ItemsState _state = const ItemsState();
  bool _isDisposed = false;
  int _loadGeneration = 0;

  ItemsState get state => _state;

  List<Item> get visibleItems {
    final query = _state.query.trim().toLowerCase().replaceAll(',', '');
    if (query.isEmpty) return _state.items;
    return List.unmodifiable(
      _state.items.where(
        (item) => item.searchText.replaceAll(',', '').contains(query),
      ),
    );
  }

  Item? get selectedItem {
    final selectedId = _state.selectedItemEntityId;
    if (selectedId == null) return null;
    for (final item in _state.items) {
      if (item.entityId == selectedId) return item;
    }
    return null;
  }

  List<ItemType> typesFor(String groupId) {
    return List.unmodifiable(
      _state.types.where((type) => type.groupId == groupId),
    );
  }

  ItemGroup? groupById(String groupId) {
    for (final group in _state.groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  ItemType? typeById(String typeId) {
    for (final type in _state.types) {
      if (type.id == typeId) return type;
    }
    return null;
  }

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_loadGeneration;
    _state = _state.copyWith(dataState: const AppDataState.loading());
    _notifyListenersIfActive();
    try {
      final items = await _repository.getAll();
      final groups = await _repository.getGroups();
      final types = await _repository.getTypes();
      if (_loadIsStale(generation)) return;
      if (groups.isEmpty || types.isEmpty) {
        _setMissingReference(
          'مجموعات المواد أو أنواعها غير متاحة',
          generation,
        );
        return;
      }
      final resolved = <Item>[];
      for (final item in items) {
        final group = _groupFrom(groups, item.groupEntityId);
        final type = _typeFrom(types, item.typeEntityId);
        if (group == null ||
            type == null ||
            type.groupEntityId != group.entityId) {
          _setMissingReference(
            'مجموعة المادة أو نوعها غير متاح: ${item.name}',
            generation,
          );
          return;
        }
        resolved.add(
          item.copyWith(groupName: group.name, typeName: type.name),
        );
      }
      _state = _state.copyWith(
        dataState: resolved.isEmpty
            ? const AppDataState.empty(message: 'لا توجد مواد مسجلة حالياً.')
            : AppDataState.ready(List.unmodifiable(resolved)),
        groups: List.unmodifiable(groups),
        types: List.unmodifiable(types),
        selectedItemEntityId: resolved.any(
          (item) => item.entityId == _state.selectedItemEntityId,
        )
            ? _state.selectedItemEntityId
            : null,
      );
      _notifyListenersIfActive();
    } catch (error) {
      if (_loadIsStale(generation)) return;
      _state = _state.copyWith(
        dataState: AppDataState.error(
          error,
          message: 'تعذر تحميل بيانات المواد.',
        ),
      );
      _notifyListenersIfActive();
    }
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
    if (_isDisposed) return;
    if (_state.query == value) return;
    _state = _state.copyWith(query: value);
    _notifyListenersIfActive();
  }

  void select(String? itemId) {
    if (_isDisposed) return;
    final entityId = itemId == null ? null : EntityId(itemId);
    if (_state.selectedItemEntityId == entityId) return;
    _state = _state.copyWith(selectedItemEntityId: entityId);
    _notifyListenersIfActive();
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

  Future<Item> add(Item item) async {
    final saved = await _repository.save(item);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.entityId.value);
    _onDataChanged?.call();
    return selectedItem ?? saved;
  }

  Future<Item> update(Item item) async {
    final saved = await _repository.save(item);
    if (_isDisposed) return saved;
    await load();
    if (_isDisposed) return saved;
    select(saved.entityId.value);
    _onDataChanged?.call();
    return selectedItem ?? saved;
  }

  Future<DeleteDecision> canDeleteSelected() async {
    final selected = selectedItem;
    if (selected == null) {
      return const DeleteDecision.blocked('اختر مادة من الجدول لحذفها');
    }
    return _repository.canDelete(selected.entityId);
  }

  Future<Item?> deleteSelected() async {
    final selected = selectedItem;
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

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }

  ItemGroup? _groupFrom(List<ItemGroup> groups, EntityId id) {
    for (final group in groups) {
      if (group.entityId == id) return group;
    }
    return null;
  }

  ItemType? _typeFrom(List<ItemType> types, EntityId id) {
    for (final type in types) {
      if (type.entityId == id) return type;
    }
    return null;
  }

  void _selectAt(int index) {
    final items = visibleItems;
    if (items.isEmpty || index < 0 || index >= items.length) return;
    select(items[index].entityId.value);
  }

  int _selectedVisibleIndex(List<Item> items) {
    return items.indexWhere(
      (item) => item.entityId == _state.selectedItemEntityId,
    );
  }
}
