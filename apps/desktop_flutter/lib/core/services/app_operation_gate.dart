import 'dart:async';

import 'service_failure.dart';

/// Keeps asynchronous operations attached to one application-data graph.
///
/// A data-graph replacement closes the gate synchronously, waits for
/// [AppOperationRetirement.drained], and then either commits the retirement or
/// rolls it back. Operations admitted before closing may start nested work on
/// the same gate; unrelated work is rejected as soon as retirement begins.
class AppOperationGate {
  static final Object _leaseZoneKey = Object();

  bool _accepting = true;
  bool _retired = false;
  int _activeOperationCount = 0;
  int _retirementEpoch = 0;
  Completer<void>? _drainedCompleter;

  bool get acceptsNewOperations => _accepting;
  bool get isRetired => _retired;
  int get activeOperationCount => _activeOperationCount;

  Future<T> run<T>(FutureOr<T> Function() operation) {
    final parentLease = Zone.current[_leaseZoneKey];
    final isAdmittedChild = parentLease is _AppOperationLease &&
        identical(parentLease.gate, this) &&
        parentLease.isOpen;
    if (!_accepting && !isAdmittedChild) {
      return Future<T>.error(
        const ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'application_data_replacement_in_progress',
          message: 'يجري استبدال بيانات التطبيق؛ أعد المحاولة بعد اكتمال العملية',
        ),
      );
    }

    final lease = _AppOperationLease(this);
    _activeOperationCount++;
    try {
      final result = runZoned<Future<T>>(
        () => Future<T>.sync(operation),
        zoneValues: {_leaseZoneKey: lease},
      );
      return result.whenComplete(() {
        lease.close();
        _releaseOperation();
      });
    } on Object catch (error, stackTrace) {
      lease.close();
      _releaseOperation();
      return Future<T>.error(error, stackTrace);
    }
  }

  AppOperationRetirement beginRetirement() {
    if (!_accepting) {
      throw StateError(
        _retired
            ? 'The application operation gate is retired.'
            : 'Application operation retirement is already in progress.',
      );
    }
    _accepting = false;
    final epoch = ++_retirementEpoch;
    final drained = Completer<void>();
    _drainedCompleter = drained;
    if (_activeOperationCount == 0) drained.complete();
    return AppOperationRetirement._(
      gate: this,
      epoch: epoch,
      drained: drained.future,
    );
  }

  void _releaseOperation() {
    assert(_activeOperationCount > 0);
    _activeOperationCount--;
    if (_activeOperationCount != 0 || _accepting) return;
    final drained = _drainedCompleter;
    if (drained != null && !drained.isCompleted) drained.complete();
  }

  void _commitRetirement(int epoch) {
    if (epoch != _retirementEpoch || _accepting || _retired) return;
    if (_activeOperationCount != 0) {
      throw StateError(
        'Cannot commit application operation retirement before it drains.',
      );
    }
    _retired = true;
    _drainedCompleter = null;
  }

  void _rollbackRetirement(int epoch) {
    if (epoch != _retirementEpoch || _accepting || _retired) return;
    final drained = _drainedCompleter;
    if (drained != null && !drained.isCompleted) drained.complete();
    _drainedCompleter = null;
    _accepting = true;
  }
}

class AppOperationRetirement {
  AppOperationRetirement._({
    required AppOperationGate gate,
    required int epoch,
    required this.drained,
  })  : _gate = gate,
        _epoch = epoch;

  final AppOperationGate _gate;
  final int _epoch;
  final Future<void> drained;
  bool _isResolved = false;

  bool get isResolved => _isResolved;

  void commit() {
    if (_isResolved) return;
    _gate._commitRetirement(_epoch);
    _isResolved = true;
  }

  void rollback() {
    if (_isResolved) return;
    _gate._rollbackRetirement(_epoch);
    _isResolved = true;
  }
}

class _AppOperationLease {
  _AppOperationLease(this.gate);

  final AppOperationGate gate;
  bool isOpen = true;

  void close() => isOpen = false;
}
