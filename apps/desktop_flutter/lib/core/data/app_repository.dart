import '../domain/business_values.dart';

enum AppDataStatus { loading, ready, empty, missingReference, error }

class AppDataState<T> {
  const AppDataState._({
    required this.status,
    this.data,
    this.message,
    this.error,
  });

  const AppDataState.loading() : this._(status: AppDataStatus.loading);

  const AppDataState.ready(T data)
      : this._(status: AppDataStatus.ready, data: data);

  const AppDataState.empty({String? message})
      : this._(status: AppDataStatus.empty, message: message);

  const AppDataState.missingReference(String message)
      : this._(
          status: AppDataStatus.missingReference,
          message: message,
        );

  const AppDataState.error(Object error, {String? message})
      : this._(
          status: AppDataStatus.error,
          error: error,
          message: message,
        );

  final AppDataStatus status;
  final T? data;
  final String? message;
  final Object? error;

  bool get hasData => status == AppDataStatus.ready && data != null;
}

class DeleteDecision {
  const DeleteDecision._({required this.isAllowed, this.reason});

  const DeleteDecision.allowed() : this._(isAllowed: true);

  const DeleteDecision.blocked(String reason)
      : this._(isAllowed: false, reason: reason);

  final bool isAllowed;
  final String? reason;
}

abstract interface class AppRepository<T extends Object> {
  Future<List<T>> getAll();

  Future<T?> getById(EntityId id);

  Future<T> save(T value);

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> delete(EntityId id);
}

abstract class InMemoryDemoRepository<T extends Object>
    implements AppRepository<T> {
  InMemoryDemoRepository({
    required Iterable<T> initialValues,
    required this.idOf,
  }) : _values = {
          for (final value in initialValues) idOf(value): value,
        };

  final EntityId Function(T value) idOf;
  final Map<EntityId, T> _values;

  /// Returns a mutable point-in-time copy for a staged demo transaction.
  ///
  /// Callers must finish validation before passing the candidate map to
  /// [commitDemoSnapshot]. These primitives intentionally contain no awaits,
  /// allowing a coordinator to swap several staged repository projections in
  /// one uninterrupted event-loop turn.
  Map<EntityId, T> createDemoSnapshot() => Map<EntityId, T>.of(_values);

  /// Reads the current value synchronously while a demo transaction owns the
  /// shared runner.
  T? getDemoValue(EntityId id) => _values[id];

  /// Applies an already validated snapshot. This method must stay no-fail.
  void commitDemoSnapshot(Map<EntityId, T> stagedValues) {
    _values
      ..clear()
      ..addAll(stagedValues);
  }

  @override
  Future<List<T>> getAll() async => List<T>.unmodifiable(_values.values);

  @override
  Future<T?> getById(EntityId id) async => _values[id];

  @override
  Future<T> save(T value) async {
    _values[idOf(value)] = value;
    return value;
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    return _values.containsKey(id)
        ? const DeleteDecision.allowed()
        : const DeleteDecision.blocked('السجل غير موجود');
  }

  @override
  Future<void> delete(EntityId id) async {
    final decision = await canDelete(id);
    if (!decision.isAllowed) {
      throw StateError(decision.reason ?? 'لا يمكن حذف السجل');
    }
    _values.remove(id);
  }
}
