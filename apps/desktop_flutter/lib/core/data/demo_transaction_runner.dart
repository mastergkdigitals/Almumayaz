import 'dart:async';

/// Serializes mutations that span more than one in-memory demo repository.
///
/// The callback must perform every asynchronous preflight before making its
/// final synchronous, no-fail commit. The queue deliberately absorbs a failed
/// turn so later independent mutations can still run.
class DemoTransactionRunner {
  Future<void> _tail = Future<void>.value();
  _DemoTransactionRunnerState _state = _DemoTransactionRunnerState.active;

  Future<T> run<T>(FutureOr<T> Function() action) {
    if (_state != _DemoTransactionRunnerState.active) {
      return Future<T>.error(
        StateError('The demo transaction runner is retiring or retired.'),
      );
    }
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  /// Drains all accepted turns, then grants one final exclusive turn.
  ///
  /// New turns are rejected as soon as retirement starts. A successful final
  /// turn permanently retires this runner so stale repository references
  /// cannot mutate a graph that has been replaced. If the final turn fails,
  /// the runner becomes active again and the still-live graph remains usable.
  Future<T> retireAfterDrain<T>(FutureOr<T> Function() finalTurn) {
    if (_state != _DemoTransactionRunnerState.active) {
      return Future<T>.error(
        StateError('The demo transaction runner is retiring or retired.'),
      );
    }
    _state = _DemoTransactionRunnerState.retiring;
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final value = await finalTurn();
        _state = _DemoTransactionRunnerState.retired;
        result.complete(value);
      } catch (error, stackTrace) {
        _state = _DemoTransactionRunnerState.active;
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

enum _DemoTransactionRunnerState { active, retiring, retired }
