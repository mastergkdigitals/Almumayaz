import 'package:erp/core/app_state/app_data_profile.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unpaid lifecycle updates Party and Cashbox atomically', () async {
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    final repositories = store.repositories;
    final supplierId = EntityId('party-003');
    final supplierBefore =
        (await repositories.parties.getById(supplierId))!;
    final vouchersBefore = await repositories.cashbox.getAll();
    final nextNumberBefore = await repositories.expenses.nextDocumentNumber();

    final created = await repositories.expenses.create(
      ExpenseCreateRequest(
        date: BusinessDate(2026, 8, 14),
        minuteOfDay: 10 * 60,
        description: 'خدمة تشغيل مستحقة',
        amount: Money.fromMajor(50, AppCurrency.usd),
        exchangeRate: ExchangeRate.parse('1310'),
        supplierId: supplierId,
        paymentStatus: ExpensePaymentStatus.unpaid,
        notes: '',
      ),
    );

    expect(created.documentNumber, nextNumberBefore);
    expect(
      (await repositories.parties.getById(supplierId))!.usdBalance,
      supplierBefore.usdBalance - Money.fromMajor(50, AppCurrency.usd),
    );
    expect(await repositories.cashbox.getAll(), hasLength(vouchersBefore.length));

    final updated = await repositories.expenses.update(
      ExpenseUpdateRequest(
        id: created.id,
        date: created.date,
        minuteOfDay: created.minuteOfDay,
        description: created.description,
        amount: Money.fromMajor(75, AppCurrency.usd),
        exchangeRate: created.exchangeRate,
        supplierId: supplierId,
        notes: 'تم تصحيح المبلغ',
      ),
    );
    expect(
      (await repositories.parties.getById(supplierId))!.usdBalance,
      supplierBefore.usdBalance - Money.fromMajor(75, AppCurrency.usd),
    );

    final settled = await repositories.expenses.settle(
      updated.id,
      paidAt: AuditTimestamp(DateTime(2026, 8, 14, 12)),
    );
    expect(settled.isPaid, isTrue);
    expect(
      (await repositories.parties.getById(supplierId))!.usdBalance,
      supplierBefore.usdBalance,
    );
    final afterSettlement = await repositories.cashbox.getAll();
    expect(afterSettlement, hasLength(vouchersBefore.length + 1));
    final posting = afterSettlement.singleWhere(
      (voucher) =>
          voucher.source?.kind == CashboxVoucherSourceKind.expense &&
          voucher.source?.sourceId == settled.id,
    );
    expect(posting.isSystemGenerated, isTrue);
    expect(posting.type, CashboxVoucherType.payment);
    expect(posting.usdAmount, Money.fromMajor(75, AppCurrency.usd));

    await repositories.expenses.deletePermanently(settled.id);
    expect(await repositories.expenses.getById(settled.id), isNull);
    expect(await repositories.cashbox.getAll(), hasLength(vouchersBefore.length));
    expect(
      (await repositories.parties.getById(supplierId))!.usdBalance,
      supplierBefore.usdBalance,
    );
    expect(
      await repositories.expenses.nextDocumentNumber(),
      nextNumberBefore + 1,
    );
    final audit = await store.services.audit.search(
      AuditQuery(entityType: 'expense', limit: 20),
    );
    expect(
      audit.records.map((record) => record.action),
      [
        AuditAction.delete,
        AuditAction.update,
        AuditAction.update,
        AuditAction.create,
      ],
    );
    expect(
      audit.records.every((record) => record.actorUsername == 'admin'),
      isTrue,
    );
  });

  test('failed Cashbox staging leaves a paid Expense uncommitted', () async {
    final repositories = AppRepositories.forProfile(AppDataProfile.cleared);

    await expectLater(
      repositories.expenses.create(
        ExpenseCreateRequest(
          date: BusinessDate(2026, 8, 14),
          minuteOfDay: 10 * 60,
          description: 'مصروف دون حساب صندوق',
          amount: Money.fromMajor(1000, AppCurrency.iqd),
          exchangeRate: ExchangeRate.parse('1310'),
          paymentStatus: ExpensePaymentStatus.paid,
          paidAt: AuditTimestamp(DateTime(2026, 8, 14, 10)),
          notes: '',
        ),
      ),
      throwsStateError,
    );

    expect(await repositories.expenses.getAll(), isEmpty);
    expect(await repositories.cashbox.getAll(), isEmpty);
    expect(await repositories.expenses.nextDocumentNumber(), 1);
  });
}
