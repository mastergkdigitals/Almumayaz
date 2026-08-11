import '../data/app_repository.dart';
import '../domain/business_values.dart';

enum InvoiceEditorNavigation { first, previous, next, last }

/// Flutter-independent record selection shared by invoice editors.
///
/// Repository identity always comes from [idOf]. Visible document numbers are
/// deliberately not accepted as selection keys.
class InvoiceEditorSelection<T extends Object> {
  InvoiceEditorSelection({required this.idOf});

  final EntityId Function(T value) idOf;

  List<T> _records = const [];
  EntityId? _selectedId;

  List<T> get records => _records;
  EntityId? get selectedId => _selectedId;

  int get selectedIndex {
    final selectedId = _selectedId;
    if (selectedId == null) return -1;
    return _records.indexWhere((record) => idOf(record) == selectedId);
  }

  T? get selected {
    final selectedId = _selectedId;
    if (selectedId == null) return null;
    for (final record in _records) {
      if (idOf(record) == selectedId) return record;
    }
    return null;
  }

  void replaceAll(Iterable<T> records) {
    _records = List<T>.unmodifiable(records);
    if (selected == null) _selectedId = null;
  }

  T? select(EntityId? id, {bool fallbackToFirst = false}) {
    if (id != null) {
      for (final record in _records) {
        if (idOf(record) == id) {
          _selectedId = id;
          return record;
        }
      }
    }
    if (fallbackToFirst && _records.isNotEmpty) {
      final first = _records.first;
      _selectedId = idOf(first);
      return first;
    }
    _selectedId = null;
    return null;
  }

  void clear() => _selectedId = null;

  /// Matches the existing invoice-editor boundary behavior: moving past the
  /// last record opens a new form, while Previous at the first record stays on
  /// the first record.
  T? navigate(InvoiceEditorNavigation destination) {
    if (_records.isEmpty) {
      _selectedId = null;
      return null;
    }

    final current = selected;
    final selectedIndex = current == null ? -1 : _records.indexOf(current);
    final target = switch (destination) {
      InvoiceEditorNavigation.first => _records.first,
      InvoiceEditorNavigation.previous => selectedIndex < 0
          ? _records.last
          : _records[selectedIndex <= 0 ? 0 : selectedIndex - 1],
      InvoiceEditorNavigation.next => selectedIndex < 0
          ? _records.first
          : selectedIndex >= _records.length - 1
              ? null
              : _records[selectedIndex + 1],
      InvoiceEditorNavigation.last => selectedIndex == _records.length - 1
          ? null
          : _records.last,
    };
    _selectedId = target == null ? null : idOf(target);
    return target;
  }
}

/// Tracks a feature-owned form snapshot without knowing any calculation rules.
class InvoiceEditorDirtyTracker<T extends Object> {
  InvoiceEditorDirtyTracker(T initialValue) : _baseline = initialValue;

  T _baseline;

  bool hasChanges(T currentValue) => currentValue != _baseline;

  void accept(T currentValue) => _baseline = currentValue;
}

class InvoiceMissingReferenceException implements Exception {
  const InvoiceMissingReferenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Shared asynchronous lifecycle for Sales and Purchase editors.
///
/// Calculation and mapping rules deliberately stay in their feature modules;
/// this coordinator only standardizes loading, empty/missing/error states,
/// stable record selection/navigation and serialized repository mutations.
class InvoiceEditorCoordinator<T extends Object> {
  InvoiceEditorCoordinator({
    required this.loadRecords,
    required EntityId Function(T value) idOf,
  }) : selection = InvoiceEditorSelection<T>(idOf: idOf);

  final Future<List<T>> Function() loadRecords;
  final InvoiceEditorSelection<T> selection;

  AppDataState<List<T>> state = const AppDataState.loading();
  bool isBusy = false;
  int _loadGeneration = 0;

  Future<AppDataState<List<T>>> load() async {
    final generation = ++_loadGeneration;
    state = const AppDataState.loading();
    late final AppDataState<List<T>> loadedState;
    try {
      final records = List<T>.unmodifiable(await loadRecords());
      loadedState = records.isEmpty
          ? const AppDataState.empty(
              message: 'لا توجد قوائم محفوظة حتى الآن.',
            )
          : AppDataState.ready(records);
    } on InvoiceMissingReferenceException catch (error) {
      loadedState = AppDataState.missingReference(error.message);
    } catch (error) {
      loadedState = AppDataState.error(
        error,
        message: 'تعذر تحميل القوائم. حاول مرة أخرى.',
      );
    }
    if (generation == _loadGeneration) {
      state = loadedState;
      selection.replaceAll(loadedState.data ?? <T>[]);
    }
    return state;
  }

  Future<R> mutate<R>(Future<R> Function() operation) async {
    if (isBusy) throw StateError('هناك عملية أخرى قيد التنفيذ');
    isBusy = true;
    try {
      return await operation();
    } finally {
      isBusy = false;
    }
  }
}
