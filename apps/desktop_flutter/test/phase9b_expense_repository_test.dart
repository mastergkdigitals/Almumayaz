import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/expenses/data/demo_expense_mutation_effects.dart';
import 'package:erp/features/expenses/data/demo_expense_repository.dart';
import 'package:erp/features/expenses/domain/expense.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo seeds keep paid and unpaid expenses distinct', () {
    final seeds = demoExpenses();
    final paid = seeds.singleWhere((expense) => expense.isPaid);
    final unpaid = seeds.singleWhere((expense) => expense.isUnpaid);

    expect(paid.description, 'مواد تنظيف المكتب');
    expect(paid.amount, Money.fromMajor(75000, AppCurrency.iqd));
    expect(paid.occurredAt, AuditTimestamp(DateTime(2026, 7, 28, 8, 15)));
    expect(paid.supplierId, isNull);

    expect(unpaid.description, 'صيانة أجهزة المكتب');
    expect(unpaid.amount, Money.fromMajor(150, AppCurrency.usd));
    expect(unpaid.supplierId, EntityId('party-003'));
  });

  group('Phase 9B expense repository', () {
    late _DirectExpenseEffects effects;
    late Map<EntityId, Party> parties;
    late DemoExpenseRepository repository;

    setUp(() {
      effects = _DirectExpenseEffects();
      parties = {
        EntityId('supplier-1'): _supplier('supplier-1', 'مجهز الاختبار'),
      };
      repository = DemoExpenseRepository(
        initialValues: const [],
        partyLoader: (id) async => parties[id],
        mutationEffects: effects,
      );
    });

    test('issues stable identity and retained independent number', () async {
      effects.failNextApply = true;
      await expectLater(
        repository.create(_paidRequest(description: 'عملية تفشل')),
        throwsStateError,
      );
      expect(await repository.getAll(), isEmpty);
      expect(await repository.nextDocumentNumber(), 1);

      final first = await repository.create(
        _paidRequest(description: 'مصروف مدفوع'),
      );
      expect(first.id, EntityId.demo('expense', 2));
      expect(first.documentNumber, 1);
      expect(first.isPaid, isTrue);

      await repository.deletePermanently(first.id);
      expect(await repository.nextDocumentNumber(), 2);
      final second = await repository.create(
        _paidRequest(description: 'مصروف تالٍ'),
      );
      expect(second.documentNumber, 2);
      expect(second.id, isNot(first.id));
    });

    test('unpaid requires a real supplier and settles only in full', () async {
      await expectLater(
        repository.create(_unpaidRequest(supplierId: null)),
        throwsStateError,
      );
      await expectLater(
        repository.create(
          _unpaidRequest(supplierId: EntityId('missing-supplier')),
        ),
        throwsStateError,
      );

      final unpaid = await repository.create(
        _unpaidRequest(supplierId: EntityId('supplier-1')),
      );
      expect(unpaid.isUnpaid, isTrue);
      expect(unpaid.supplierNameSnapshot, 'مجهز الاختبار');
      expect(await repository.referencesParty(EntityId('supplier-1')), isTrue);

      final paidAt = AuditTimestamp(DateTime(2026, 8, 14, 12));
      final settled = await repository.settle(unpaid.id, paidAt: paidAt);
      expect(settled.isPaid, isTrue);
      expect(settled.paidAt, paidAt);
      expect(settled.amount, unpaid.amount);
      expect(effects.kinds.last, DemoExpenseMutationKind.settle);

      await expectLater(
        repository.settle(unpaid.id, paidAt: paidAt),
        throwsStateError,
      );
    });

    test('update preserves status, payment time, identity and number', () async {
      final original = await repository.create(
        _paidRequest(description: 'الوصف القديم'),
      );
      final updated = await repository.update(
        ExpenseUpdateRequest(
          id: original.id,
          date: original.date,
          minuteOfDay: original.minuteOfDay,
          description: 'الوصف الجديد',
          amount: Money.fromMajor(250, AppCurrency.usd),
          exchangeRate: ExchangeRate.parse('1320'),
          supplierId: EntityId('supplier-1'),
          notes: 'ملاحظة',
        ),
      );

      expect(updated.id, original.id);
      expect(updated.documentNumber, original.documentNumber);
      expect(updated.paymentStatus, original.paymentStatus);
      expect(updated.paidAt, original.paidAt);
      expect(updated.description, 'الوصف الجديد');
      expect(updated.amount, Money.fromMajor(250, AppCurrency.usd));
      expect(updated.supplierNameSnapshot, 'مجهز الاختبار');
      expect(effects.kinds.last, DemoExpenseMutationKind.update);
    });

    test('failed derived mutation never commits expense projection', () async {
      final original = await repository.create(
        _unpaidRequest(supplierId: EntityId('supplier-1')),
      );
      effects.failNextApply = true;

      await expectLater(
        repository.update(
          ExpenseUpdateRequest(
            id: original.id,
            date: original.date,
            minuteOfDay: original.minuteOfDay,
            description: 'يجب ألا يحفظ',
            amount: original.amount,
            exchangeRate: original.exchangeRate,
            supplierId: original.supplierId,
            notes: original.notes,
          ),
        ),
        throwsStateError,
      );
      expect((await repository.getById(original.id))!.description,
          original.description);

      effects.failNextDelete = true;
      await expectLater(
        repository.deletePermanently(original.id),
        throwsStateError,
      );
      expect(await repository.getById(original.id), isNotNull);
    });
  });

  test('domain rejects partial or internally inconsistent payment states', () {
    expect(
      () => Expense(
        id: EntityId('invalid-unpaid'),
        documentNumber: 1,
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 9 * 60,
        description: 'غير صالح',
        amount: Money.fromMajor(100, AppCurrency.iqd),
        exchangeRate: ExchangeRate.parse('1310'),
        paymentStatus: ExpensePaymentStatus.unpaid,
        notes: '',
      ),
      throwsArgumentError,
    );
    expect(
      () => Expense(
        id: EntityId('invalid-paid'),
        documentNumber: 2,
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 9 * 60,
        description: 'غير صالح',
        amount: Money.fromMajor(100, AppCurrency.iqd),
        exchangeRate: ExchangeRate.parse('1310'),
        paymentStatus: ExpensePaymentStatus.paid,
        notes: '',
      ),
      throwsArgumentError,
    );
  });
}

class _DirectExpenseEffects implements DemoExpenseMutationEffects {
  final kinds = <DemoExpenseMutationKind>[];
  bool failNextApply = false;
  bool failNextDelete = false;

  @override
  Future<Expense> applyExpense({
    required DemoExpenseMutationKind kind,
    required Future<DemoExpenseMutation> Function()
        preflightAndBuildMutation,
    required void Function(Expense normalized) commit,
  }) async {
    final mutation = await preflightAndBuildMutation();
    if (failNextApply) {
      failNextApply = false;
      throw StateError('فشل تأثير مشتق');
    }
    commit(mutation.candidate);
    kinds.add(kind);
    return mutation.candidate;
  }

  @override
  Future<void> deleteExpense({
    required EntityId id,
    required Future<Expense> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) async {
    await preflightAndLoadPrevious();
    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('فشل تأثير الحذف');
    }
    commit();
  }
}

ExpenseCreateRequest _paidRequest({required String description}) {
  return ExpenseCreateRequest(
    date: BusinessDate(2026, 8, 14),
    minuteOfDay: 9 * 60,
    description: description,
    amount: Money.fromMajor(100000, AppCurrency.iqd),
    exchangeRate: ExchangeRate.parse('1310'),
    paymentStatus: ExpensePaymentStatus.paid,
    paidAt: AuditTimestamp(DateTime(2026, 8, 14, 9)),
    notes: '',
  );
}

ExpenseCreateRequest _unpaidRequest({required EntityId? supplierId}) {
  return ExpenseCreateRequest(
    date: BusinessDate(2026, 8, 14),
    minuteOfDay: 9 * 60,
    description: 'مصروف مستحق',
    amount: Money.fromMajor(100000, AppCurrency.iqd),
    exchangeRate: ExchangeRate.parse('1310'),
    supplierId: supplierId,
    paymentStatus: ExpensePaymentStatus.unpaid,
    notes: '',
  );
}

Party _supplier(String id, String name) {
  return Party(
    id: id,
    number: 1,
    createdAt: DateTime(2026, 1, 1),
    name: name,
    type: PartyType.supplier,
    workplace: '',
    branch: '',
    phone: '',
    alternatePhone: '',
    city: '',
    address: '',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 0,
  );
}
