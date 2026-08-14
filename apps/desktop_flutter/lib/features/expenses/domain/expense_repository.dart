import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'expense.dart';

abstract interface class ExpenseRepository {
  Future<List<Expense>> getAll();

  Future<Expense?> getById(EntityId id);

  Future<List<Expense>> search(String query);

  /// Preview only. [create] remains responsible for issuing the authoritative
  /// stable identity and document number inside its transaction boundary.
  Future<int> nextDocumentNumber();

  Future<Expense> create(ExpenseCreateRequest request);

  Future<Expense> update(ExpenseUpdateRequest request);

  Future<Expense> settle(
    EntityId id, {
    required AuditTimestamp paidAt,
  });

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> deletePermanently(EntityId id);

  Future<bool> referencesParty(EntityId partyId);
}
