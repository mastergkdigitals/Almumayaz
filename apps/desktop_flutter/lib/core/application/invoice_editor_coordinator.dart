import '../data/app_repository.dart';

class InvoiceMissingReferenceException implements Exception {
  const InvoiceMissingReferenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Shared asynchronous lifecycle for Sales and Purchase editors.
///
/// Calculation and mapping rules deliberately stay in their feature modules;
/// this coordinator only standardizes loading, empty/missing/error states and
/// serialized repository mutations.
class InvoiceEditorCoordinator<T extends Object> {
  InvoiceEditorCoordinator({required this.loadRecords});

  final Future<List<T>> Function() loadRecords;

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
    if (generation == _loadGeneration) state = loadedState;
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
