import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/sales_returns/domain/sales_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create and delete commit every Sales-return projection atomically',
    () async {
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final repositories = store.repositories;
      final source = (await repositories.sales.getAll()).firstWhere(
        (invoice) => invoice.documentNumber == 103,
      );
      final sourceLine = source.lines.first;
      final partyBefore = await repositories.parties.getById(
        source.customerId,
      );
      expect(partyBefore, isNotNull);
      final originalParty = partyBefore!;
      final stockBefore = await _stockQuantity(
        store,
        sourceLine.warehouseId,
        sourceLine.itemId,
      );

      final saved = await repositories.salesReturns.createReturn(
        SalesReturnSaveRequest(
          originalSalesInvoiceId: source.id,
          date: BusinessDate(2026, 8, 14),
          minuteOfDay: 12 * 60,
          lines: [
            SalesReturnLineRequest(
              sourceSalesLineId: sourceLine.id,
              quantity: WholeQuantity(1),
            ),
          ],
          refundedAtReturn: Money.fromMajor(10000, source.currency),
          notes: 'اختبار الآثار المترابطة',
        ),
      );

      expect(
        await _stockQuantity(
          store,
          sourceLine.warehouseId,
          sourceLine.itemId,
        ),
        stockBefore + 1,
      );
      final partyAfterCreate = await repositories.parties.getById(
        source.customerId,
      );
      expect(
        partyAfterCreate!.iqdBalance,
        originalParty.iqdBalance - saved.creditedToCustomer,
      );
      final vouchers = await repositories.cashbox.getByParty(
        source.customerId,
      );
      final returnVoucher = vouchers.singleWhere(
        (voucher) =>
            voucher.source?.kind == CashboxVoucherSourceKind.salesReturn &&
            voucher.source?.sourceId == saved.id,
      );
      expect(returnVoucher.type, CashboxVoucherType.payment);
      expect(returnVoucher.iqdAmount, saved.refundedAtReturn);
      final returnCost = await repositories.inventoryCosts
          .getSalesReturnLineCost(saved.lines.single.id);
      expect(returnCost, isNotNull);
      final savedReturnCost = returnCost!;
      expect(savedReturnCost.originalSalesLineId, sourceLine.id);
      expect(savedReturnCost.quantity.value, 1);
      expect((await repositories.sales.canDelete(source.id)).isAllowed, isFalse);

      final noteOnlyUpdate = await repositories.sales.replaceInvoice(
        source.copyWith(
          notes: 'ملاحظة محدثة لا تغير آثار القائمة',
          driverName: 'سائق محدث',
        ),
      );
      expect(noteOnlyUpdate.notes, contains('محدثة'));
      await expectLater(
        repositories.sales.replaceInvoice(
          noteOnlyUpdate.copyWith(date: BusinessDate(2026, 8, 13)),
        ),
        throwsA(isA<StateError>()),
      );
      final otherSource = (await repositories.sales.getAll()).firstWhere(
        (invoice) => invoice.documentNumber == 101,
      );
      await expectLater(
        repositories.salesReturns.replaceReturn(
          saved.id,
          SalesReturnSaveRequest(
            originalSalesInvoiceId: otherSource.id,
            date: BusinessDate(2026, 8, 14),
            minuteOfDay: 12 * 60,
            lines: [
              SalesReturnLineRequest(
                sourceSalesLineId: otherSource.lines.first.id,
                quantity: WholeQuantity(1),
              ),
            ],
            refundedAtReturn: Money.zero(otherSource.currency),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repositories.salesReturns.getById(saved.id))!
            .originalSalesInvoiceId,
        source.id,
      );

      await repositories.salesReturns.deleteReturnPermanently(saved.id);

      expect(await repositories.salesReturns.getAll(), isEmpty);
      expect((await repositories.sales.canDelete(source.id)).isAllowed, isTrue);
      expect(
        await _stockQuantity(
          store,
          sourceLine.warehouseId,
          sourceLine.itemId,
        ),
        stockBefore,
      );
      final partyAfterDelete = await repositories.parties.getById(
        source.customerId,
      );
      expect(partyAfterDelete!.iqdBalance, originalParty.iqdBalance);
      expect(
        (await repositories.cashbox.getByParty(source.customerId)).where(
          (voucher) =>
              voucher.source?.kind ==
                  CashboxVoucherSourceKind.salesReturn &&
              voucher.source?.sourceId == saved.id,
        ),
        isEmpty,
      );
      expect(
        await repositories.inventoryCosts.getSalesReturnLineCost(
          saved.lines.single.id,
        ),
        isNull,
      );
      expect(await repositories.salesReturns.nextDocumentNumber(), 2);

      final audit = await store.services.audit.search(
        AuditQuery(entityType: 'sales_return', limit: 20),
      );
      expect(
        audit.records.map((record) => record.action),
        containsAll([AuditAction.create, AuditAction.delete]),
      );
    },
  );
}

Future<int> _stockQuantity(
  AppStore store,
  EntityId warehouseId,
  EntityId itemId,
) async {
  final inventory = await store.repositories.warehouses.getInventory(
    warehouseId,
  );
  for (final balance in inventory) {
    if (balance.itemId == itemId) return balance.quantity.value;
  }
  return 0;
}
