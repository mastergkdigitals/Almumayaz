import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../parties/domain/party.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';
import 'demo_expense_mutation_effects.dart';

typedef ExpensePartyLoader = Future<Party?> Function(EntityId id);

class DemoExpenseRepository extends InMemoryDemoRepository<Expense>
    implements ExpenseRepository {
  factory DemoExpenseRepository({
    Iterable<Expense>? initialValues,
    required ExpensePartyLoader partyLoader,
    required DemoExpenseMutationEffects mutationEffects,
  }) {
    final values = List<Expense>.of(initialValues ?? demoExpenses());
    return DemoExpenseRepository._(
      initialValues: values,
      partyLoader: partyLoader,
      mutationEffects: mutationEffects,
    );
  }

  DemoExpenseRepository._({
    required List<Expense> initialValues,
    required ExpensePartyLoader partyLoader,
    required DemoExpenseMutationEffects mutationEffects,
  })  : _partyLoader = partyLoader,
        _mutationEffects = mutationEffects,
        _highestIssuedDocumentNumber = _highestDocumentNumber(initialValues),
        _issuedDocumentNumbers = {
          for (final expense in initialValues) expense.documentNumber,
        },
        _issuedIds = {for (final expense in initialValues) expense.id},
        _nextIdSequence = _nextExpenseSequence(initialValues),
        super(initialValues: initialValues, idOf: (expense) => expense.id);

  final ExpensePartyLoader _partyLoader;
  final DemoExpenseMutationEffects _mutationEffects;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;
  final Set<EntityId> _issuedIds;
  int _nextIdSequence;

  @override
  Future<List<Expense>> search(String query) async {
    final normalized = query.trim().toLowerCase().replaceAll(',', '');
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where(
        (expense) => expense.searchText
            .replaceAll(',', '')
            .contains(normalized),
      ),
    );
  }

  @override
  Future<int> nextDocumentNumber() async =>
      _highestIssuedDocumentNumber + 1;

  @override
  Future<Expense> create(ExpenseCreateRequest request) {
    return _mutationEffects.applyExpense(
      kind: DemoExpenseMutationKind.create,
      preflightAndBuildMutation: () async {
        if (request.paymentStatus == ExpensePaymentStatus.unpaid &&
            request.paidAt != null) {
          throw StateError('المصروف غير المدفوع لا يقبل وقت تسديد');
        }
        final supplier = await _loadSupplier(
          request.supplierId,
          requiredForUnpaid:
              request.paymentStatus == ExpensePaymentStatus.unpaid,
        );
        final id = _issueId();
        final occurredAt = AuditTimestamp(
          request.date.atTime(
            hour: request.minuteOfDay ~/ Duration.minutesPerHour,
            minute: request.minuteOfDay % Duration.minutesPerHour,
          ),
        );
        final candidate = Expense(
          id: id,
          documentNumber: _highestIssuedDocumentNumber + 1,
          date: request.date,
          minuteOfDay: request.minuteOfDay,
          description: request.description,
          amount: request.amount,
          exchangeRate: request.exchangeRate,
          supplierId: supplier?.entityId,
          supplierNameSnapshot: supplier?.name,
          paymentStatus: request.paymentStatus,
          paidAt: request.paymentStatus == ExpensePaymentStatus.paid
              ? request.paidAt ?? occurredAt
              : null,
          notes: request.notes.trim(),
        );
        _ensureIdentityAvailable(candidate);
        return DemoExpenseMutation(candidate: candidate);
      },
      commit: _commitExpense,
    );
  }

  @override
  Future<Expense> update(ExpenseUpdateRequest request) {
    return _mutationEffects.applyExpense(
      kind: DemoExpenseMutationKind.update,
      preflightAndBuildMutation: () async {
        final existing = getDemoValue(request.id);
        if (existing == null) throw StateError('المصروف غير موجود');
        final supplier = await _loadSupplier(
          request.supplierId,
          requiredForUnpaid: existing.isUnpaid,
        );
        final candidate = existing.copyWithDetails(
          date: request.date,
          minuteOfDay: request.minuteOfDay,
          description: request.description,
          amount: request.amount,
          exchangeRate: request.exchangeRate,
          supplierId: supplier?.entityId,
          supplierNameSnapshot: supplier?.name,
          notes: request.notes.trim(),
        );
        return DemoExpenseMutation(previous: existing, candidate: candidate);
      },
      commit: _commitExpense,
    );
  }

  @override
  Future<Expense> settle(
    EntityId id, {
    required AuditTimestamp paidAt,
  }) {
    return _mutationEffects.applyExpense(
      kind: DemoExpenseMutationKind.settle,
      preflightAndBuildMutation: () async {
        final existing = getDemoValue(id);
        if (existing == null) throw StateError('المصروف غير موجود');
        final candidate = existing.markPaid(paidAt);
        return DemoExpenseMutation(previous: existing, candidate: candidate);
      },
      commit: _commitExpense,
    );
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async =>
      getDemoValue(id) == null
          ? const DeleteDecision.blocked('المصروف غير موجود')
          : const DeleteDecision.allowed();

  @override
  Future<void> deletePermanently(EntityId id) {
    return _mutationEffects.deleteExpense(
      id: id,
      preflightAndLoadPrevious: () async {
        final existing = getDemoValue(id);
        if (existing == null) throw StateError('المصروف غير موجود');
        return existing;
      },
      commit: () {
        final staged = createDemoSnapshot()..remove(id);
        commitDemoSnapshot(staged);
      },
    );
  }

  @override
  Future<bool> referencesParty(EntityId partyId) async =>
      (await getAll()).any((expense) => expense.supplierId == partyId);

  @override
  Future<Expense> save(Expense value) {
    throw StateError('استخدم عمليات إنشاء أو تحديث المصروف الصريحة');
  }

  @override
  Future<void> delete(EntityId id) => deletePermanently(id);

  Future<Party?> _loadSupplier(
    EntityId? supplierId, {
    required bool requiredForUnpaid,
  }) async {
    if (supplierId == null) {
      if (requiredForUnpaid) {
        throw StateError('اختر المجهز للمصروف غير المدفوع');
      }
      return null;
    }
    final party = await _partyLoader(supplierId);
    final isSupplier = party != null &&
        (party.type == PartyType.supplier ||
            party.type == PartyType.customerAndSupplier);
    if (!isSupplier) throw StateError('المجهز المحدد غير موجود');
    return party;
  }

  EntityId _issueId() {
    while (true) {
      final candidate = EntityId.demo('expense', _nextIdSequence++);
      if (!_issuedIds.contains(candidate) && getDemoValue(candidate) == null) {
        return candidate;
      }
    }
  }

  void _ensureIdentityAvailable(Expense expense) {
    if (_issuedIds.contains(expense.id) || getDemoValue(expense.id) != null) {
      throw StateError('معرف المصروف مستخدم مسبقاً');
    }
    if (_issuedDocumentNumbers.contains(expense.documentNumber)) {
      throw StateError('رقم المصروف مستخدم مسبقاً');
    }
  }

  void _commitExpense(Expense expense) {
    final staged = createDemoSnapshot()..[expense.id] = expense;
    commitDemoSnapshot(staged);
    _issuedIds.add(expense.id);
    _issuedDocumentNumbers.add(expense.documentNumber);
    if (expense.documentNumber > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = expense.documentNumber;
    }
  }
}

int _highestDocumentNumber(Iterable<Expense> expenses) {
  var highest = 0;
  for (final expense in expenses) {
    if (expense.documentNumber > highest) highest = expense.documentNumber;
  }
  return highest;
}

int _nextExpenseSequence(Iterable<Expense> expenses) {
  var next = 1;
  final pattern = RegExp(r'^demo-expense-(\d+)$');
  for (final expense in expenses) {
    final match = pattern.firstMatch(expense.id.value);
    final sequence = match == null ? null : int.tryParse(match.group(1)!);
    if (sequence != null && sequence >= next) next = sequence + 1;
  }
  return next;
}

List<Expense> demoExpenses() => [
      Expense(
        id: EntityId.demo('expense', 1),
        documentNumber: 1,
        date: BusinessDate(2026, 7, 28),
        minuteOfDay: 8 * 60 + 15,
        description: 'مواد تنظيف المكتب',
        amount: Money.fromMajor(75000, AppCurrency.iqd),
        exchangeRate: ExchangeRate.parse('1310'),
        paymentStatus: ExpensePaymentStatus.paid,
        paidAt: AuditTimestamp(DateTime(2026, 7, 28, 8, 15)),
        notes: 'مصروف تشغيلي مدفوع',
      ),
      Expense(
        id: EntityId.demo('expense', 2),
        documentNumber: 2,
        date: BusinessDate(2026, 7, 28),
        minuteOfDay: 11 * 60,
        description: 'صيانة أجهزة المكتب',
        amount: Money.fromMajor(150, AppCurrency.usd),
        exchangeRate: ExchangeRate.parse('1310'),
        supplierId: EntityId('party-003'),
        supplierNameSnapshot: 'مجهز الرافدين',
        paymentStatus: ExpensePaymentStatus.unpaid,
        notes: 'مستحق للمجهز',
      ),
    ];
