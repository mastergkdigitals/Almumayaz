import '../../../core/domain/business_values.dart';
import '../domain/expense.dart';

enum DemoExpenseMutationKind { create, update, settle }

class DemoExpenseMutation {
  const DemoExpenseMutation({required this.candidate, this.previous});

  final Expense? previous;
  final Expense candidate;
}

/// Cross-feature transaction boundary for the demo Expense adapter.
///
/// The concrete application coordinator owns the shared transaction runner.
/// It stages Party, Cashbox and audit projections, then invokes [commit] only
/// after every validation and derived effect has succeeded.
abstract interface class DemoExpenseMutationEffects {
  Future<Expense> applyExpense({
    required DemoExpenseMutationKind kind,
    required Future<DemoExpenseMutation> Function()
        preflightAndBuildMutation,
    required void Function(Expense normalized) commit,
  });

  Future<void> deleteExpense({
    required EntityId id,
    required Future<Expense> Function() preflightAndLoadPrevious,
    required void Function() commit,
  });
}
