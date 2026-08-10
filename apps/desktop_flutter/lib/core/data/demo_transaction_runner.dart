import 'dart:async';

/// Serializes mutations that span more than one in-memory demo repository.
///
/// The callback must perform every asynchronous preflight before making its
/// final synchronous, no-fail commit. The queue deliberately absorbs a failed
/// turn so later independent mutations can still run.
class DemoTransactionRunner {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(FutureOr<T> Function() action) {
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
}
