import 'package:flutter/foundation.dart';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../parties/domain/party.dart';
import '../../parties/domain/party_repository.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';

@immutable
class ExpensesState {
  const ExpensesState({
    this.dataState = const AppDataState.loading(),
    this.suppliers = const [],
    this.query = '',
    this.selectedExpenseId,
  });

  final AppDataState<List<Expense>> dataState;
  final List<Party> suppliers;
  final String query;
  final EntityId? selectedExpenseId;

  List<Expense> get expenses => dataState.data ?? const [];

  ExpensesState copyWith({
    AppDataState<List<Expense>>? dataState,
    List<Party>? suppliers,
    String? query,
    Object? selectedExpenseId = _unchanged,
  }) {
    return ExpensesState(
      dataState: dataState ?? this.dataState,
      suppliers: suppliers ?? this.suppliers,
      query: query ?? this.query,
      selectedExpenseId: identical(selectedExpenseId, _unchanged)
          ? this.selectedExpenseId
          : selectedExpenseId as EntityId?,
    );
  }
}

const _unchanged = Object();

class ExpensesController extends ChangeNotifier {
  ExpensesController({
    required ExpenseRepository repository,
    required PartyRepository parties,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _parties = parties,
        _onDataChanged = onDataChanged;

  final ExpenseRepository _repository;
  final PartyRepository _parties;
  final VoidCallback? _onDataChanged;

  ExpensesState _state = const ExpensesState();
  int _nextDocumentNumber = 1;
  int _loadGeneration = 0;
  bool _isDisposed = false;

  ExpensesState get state => _state;
  int get nextDocumentNumber => _nextDocumentNumber;

  List<Expense> get visibleExpenses {
    final query = _state.query.trim().toLowerCase();
    if (query.isEmpty) return _state.expenses;
    return List.unmodifiable(
      _state.expenses.where((expense) => expense.searchText.contains(query)),
    );
  }

  Expense? get selectedExpense {
    final id = _state.selectedExpenseId;
    if (id == null) return null;
    for (final expense in _state.expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  int get selectedVisibleIndex =>
      visibleExpenses.indexWhere((expense) => expense.id == _state.selectedExpenseId);

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_loadGeneration;
    _state = _state.copyWith(dataState: const AppDataState.loading());
    _notify();
    try {
      final values = await Future.wait([
        _repository.getAll(),
        _parties.getAll(),
        _repository.nextDocumentNumber(),
      ]);
      if (_isStale(generation)) return;
      final expenses = values[0] as List<Expense>;
      final parties = values[1] as List<Party>;
      final supplierOptions = parties
          .where(
            (party) =>
                party.type == PartyType.supplier ||
                party.type == PartyType.customerAndSupplier,
          )
          .toList(growable: false)
        ..sort((first, second) => first.number.compareTo(second.number));
      final suppliersById = {
        for (final supplier in supplierOptions) supplier.entityId: supplier,
      };
      for (final expense in expenses) {
        final supplierId = expense.supplierId;
        if (supplierId != null && suppliersById[supplierId] == null) {
          _state = _state.copyWith(
            dataState: const AppDataState.missingReference(
              'أحد المصاريف مرتبط بمجهز غير موجود.',
            ),
            suppliers: List.unmodifiable(supplierOptions),
            selectedExpenseId: null,
          );
          _notify();
          return;
        }
      }
      final sorted = [...expenses]..sort(_compareExpenses);
      _nextDocumentNumber = values[2] as int;
      _state = _state.copyWith(
        dataState: sorted.isEmpty
            ? const AppDataState.empty(
                message: 'لا توجد مصاريف مسجلة حالياً.',
              )
            : AppDataState.ready(List.unmodifiable(sorted)),
        suppliers: List.unmodifiable(supplierOptions),
        selectedExpenseId: sorted.any(
          (expense) => expense.id == _state.selectedExpenseId,
        )
            ? _state.selectedExpenseId
            : null,
      );
      _notify();
    } catch (error) {
      if (_isStale(generation)) return;
      _state = _state.copyWith(
        dataState: AppDataState.error(
          error,
          message: 'تعذر تحميل بيانات المصاريف.',
        ),
        selectedExpenseId: null,
      );
      _notify();
    }
  }

  void search(String value) {
    if (_isDisposed || value == _state.query) return;
    _state = _state.copyWith(query: value);
    _notify();
  }

  void select(EntityId? id) {
    if (_isDisposed || id == _state.selectedExpenseId) return;
    _state = _state.copyWith(selectedExpenseId: id);
    _notify();
  }

  void first() => _selectAt(0);

  void previous() {
    final values = visibleExpenses;
    if (values.isEmpty) return;
    final index = selectedVisibleIndex;
    _selectAt(index <= 0 ? 0 : index - 1);
  }

  void next() {
    final values = visibleExpenses;
    if (values.isEmpty) return;
    final index = selectedVisibleIndex;
    if (index < 0) {
      _selectAt(0);
    } else if (index >= values.length - 1) {
      select(null);
    } else {
      _selectAt(index + 1);
    }
  }

  void last() {
    final values = visibleExpenses;
    if (values.isNotEmpty) _selectAt(values.length - 1);
  }

  Future<Expense> create(ExpenseCreateRequest request) async {
    final saved = await _repository.create(request);
    await _reloadAfterMutation(saved.id);
    return saved;
  }

  Future<Expense> update(ExpenseUpdateRequest request) async {
    final saved = await _repository.update(request);
    await _reloadAfterMutation(saved.id);
    return saved;
  }

  Future<Expense> settle(
    EntityId id, {
    required AuditTimestamp paidAt,
  }) async {
    final saved = await _repository.settle(id, paidAt: paidAt);
    await _reloadAfterMutation(saved.id);
    return saved;
  }

  /// Reloads the selected saved aggregate immediately before document output.
  ///
  /// The repository is shared by every screen, so the in-memory list held by
  /// this controller can legitimately be older than the authoritative record.
  /// A deleted selection becomes an explicit missing-reference state instead
  /// of producing a document from stale data.
  Future<Expense?> refreshSelectedForOutput() async {
    final selectedId = _state.selectedExpenseId;
    if (_isDisposed || selectedId == null) return null;
    final latest = await _repository.getById(selectedId);
    if (_isDisposed) return null;
    if (latest == null) {
      _state = _state.copyWith(
        dataState: const AppDataState.missingReference(
          'المصروف المحدد لم يعد موجوداً.',
        ),
        selectedExpenseId: null,
      );
      _notify();
      return null;
    }

    final refreshed = [..._state.expenses];
    final index = refreshed.indexWhere((expense) => expense.id == selectedId);
    if (index < 0) {
      refreshed.add(latest);
    } else {
      refreshed[index] = latest;
    }
    refreshed.sort(_compareExpenses);
    _state = _state.copyWith(
      dataState: AppDataState.ready(List.unmodifiable(refreshed)),
      selectedExpenseId: latest.id,
    );
    _notify();
    return latest;
  }

  Future<DeleteDecision> canDeleteSelected() async {
    final selected = selectedExpense;
    return selected == null
        ? const DeleteDecision.blocked('اختر مصروفاً أولاً')
        : _repository.canDelete(selected.id);
  }

  Future<void> deleteSelected() async {
    final selected = selectedExpense;
    if (selected == null) throw StateError('اختر مصروفاً أولاً');
    await _repository.deletePermanently(selected.id);
    await _reloadAfterMutation(null);
  }

  Future<void> _reloadAfterMutation(EntityId? selectedId) async {
    _state = _state.copyWith(selectedExpenseId: selectedId);
    _onDataChanged?.call();
    await load();
  }

  void _selectAt(int index) {
    final values = visibleExpenses;
    if (index < 0 || index >= values.length) return;
    select(values[index].id);
  }

  bool _isStale(int generation) =>
      _isDisposed || generation != _loadGeneration;

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}

int _compareExpenses(Expense first, Expense second) {
  final byDate = first.date.compareTo(second.date);
  if (byDate != 0) return byDate;
  final byTime = first.minuteOfDay.compareTo(second.minuteOfDay);
  return byTime != 0
      ? byTime
      : first.documentNumber.compareTo(second.documentNumber);
}
