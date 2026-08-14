import '../domain/sales_return.dart';

class DemoSalesReturnMutation {
  const DemoSalesReturnMutation({
    required this.previous,
    required this.candidate,
  });

  final SalesReturn? previous;
  final SalesReturn candidate;
}
/// Demo transaction boundary for Sales-return storage and its cross-feature
/// projections. Implementations stage inventory, original COGS, Party,
/// Cashbox, installments and audit before invoking the no-fail commit.
abstract interface class DemoSalesReturnMutationEffects {
  Future<SalesReturn> applySalesReturn({
    required Future<DemoSalesReturnMutation> Function()
        preflightAndBuildMutation,
    required void Function(SalesReturn normalized) commit,
  });

  Future<void> deleteSalesReturn({
    required Future<SalesReturn> Function() preflightAndLoadPrevious,
    required void Function() commit,
  });
}
