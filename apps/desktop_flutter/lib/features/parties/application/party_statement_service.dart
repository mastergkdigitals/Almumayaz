import 'package:flutter/foundation.dart';

import '../../../core/domain/business_values.dart';
import '../../cashbox/domain/cashbox_repository.dart';
import '../../cashbox/domain/cashbox_voucher.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/domain/expense_repository.dart';
import '../../purchases/domain/purchase_invoice.dart';
import '../../purchases/domain/purchase_repository.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../sales/domain/sales_repository.dart';
import '../../sales_returns/domain/sales_return.dart';
import '../../sales_returns/domain/sales_return_repository.dart';
import '../domain/party_repository.dart';

@immutable
class PartyStatementQuery {
  PartyStatementQuery({
    required this.partyId,
    required this.fromDate,
    required this.toDate,
    required this.currency,
  }) {
    if (fromDate.compareTo(toDate) > 0) {
      throw ArgumentError.value(
        fromDate,
        'fromDate',
        'Statement start date must not be after its end date',
      );
    }
  }

  final EntityId partyId;
  final BusinessDate fromDate;
  final BusinessDate toDate;
  final AppCurrency currency;
}

enum PartyStatementEntryType {
  sale('بيع'),
  saleReturn('مرتجع بيع'),
  purchase('شراء'),
  purchaseReturn('مرتجع شراء'),
  expense('مصروف'),
  expensePayment('تسديد مصروف'),
  receipt('قبض'),
  payment('صرف');

  const PartyStatementEntryType(this.label);

  final String label;
}

/// Presentation-independent statement row. Its fields map directly to the
/// shared statement report without making the application layer depend on a
/// Flutter dialog model.
@immutable
class PartyStatementEntry {
  const PartyStatementEntry({
    required this.id,
    required this.date,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.type,
    required this.details,
    this.quantity,
  });

  final EntityId id;
  final DateTime date;
  final Money debit;
  final Money credit;
  final Money balance;
  final PartyStatementEntryType type;
  final String details;
  final int? quantity;
}

@immutable
class PartyStatementResult {
  const PartyStatementResult({
    required this.query,
    required this.entries,
    required this.openingBalance,
    required this.closingBalance,
  });

  final PartyStatementQuery query;
  final List<PartyStatementEntry> entries;
  final Money openingBalance;
  final Money closingBalance;
}

abstract interface class PartyStatementService {
  Future<PartyStatementResult> load(PartyStatementQuery query);
}

class RepositoryPartyStatementService implements PartyStatementService {
  const RepositoryPartyStatementService({
    required PartyRepository parties,
    required SalesRepository sales,
    required PurchaseRepository purchases,
    required CashboxRepository cashbox,
    SalesReturnRepository? salesReturns,
    ExpenseRepository? expenses,
  })  : _parties = parties,
        _sales = sales,
        _purchases = purchases,
        _cashbox = cashbox,
        _salesReturns = salesReturns,
        _expenses = expenses;

  final PartyRepository _parties;
  final SalesRepository _sales;
  final PurchaseRepository _purchases;
  final CashboxRepository _cashbox;
  final SalesReturnRepository? _salesReturns;
  final ExpenseRepository? _expenses;

  @override
  Future<PartyStatementResult> load(PartyStatementQuery query) async {
    final party = await _parties.getById(query.partyId);
    if (party == null) {
      throw StateError('الطرف المرتبط بكشف الحساب غير موجود');
    }
    final sales = await _sales.getAll();
    final purchases = await _purchases.getAll();
    final purchaseById = {
      for (final invoice in purchases) invoice.id: invoice,
    };
    final salesReturns = _salesReturns == null
        ? const <SalesReturn>[]
        : await _salesReturns.getAll();
    final expenses = _expenses == null
        ? const <Expense>[]
        : await _expenses.getAll();
    final vouchers = await _cashbox.getByParty(query.partyId);
    final allMovements = <_PartyStatementMovement>[
      for (final invoice in sales)
        if (invoice.customerId == query.partyId &&
            invoice.currency == query.currency)
          _saleMovement(invoice),
      for (final invoice in purchases)
        if (invoice.supplierId == query.partyId &&
            invoice.currency == query.currency)
          _purchaseMovement(
            invoice,
            originalDocumentNumber:
                purchaseById[invoice.originalPurchaseInvoiceId]
                    ?.documentNumber,
          ),
      for (final salesReturn in salesReturns)
        if (salesReturn.customerId == query.partyId &&
            salesReturn.currency == query.currency)
          _salesReturnMovement(salesReturn),
      for (final expense in expenses)
        if (expense.supplierId == query.partyId &&
            expense.amount.currency == query.currency) ...[
          _expenseMovement(expense),
          if (expense.isPaid) _expensePaymentMovement(expense),
        ],
      for (final voucher in vouchers)
        if (!voucher.isSystemGenerated ||
            voucher.source?.kind ==
                CashboxVoucherSourceKind.installmentPayment)
          ..._cashboxMovements(voucher, query.currency),
    ];
    var recordedNet = Money.zero(query.currency);
    for (final movement in allMovements) {
      final sides = _normalizeSides(movement.debit, movement.credit);
      recordedNet = recordedNet + sides.debit - sides.credit;
    }
    final currentBalance = switch (query.currency) {
      AppCurrency.iqd => party.iqdBalance,
      AppCurrency.usd => party.usdBalance,
    };
    final baselineBalance = currentBalance - recordedNet;
    final movements = allMovements
        .where(
          (movement) => _isOnOrBeforeToDate(
            query,
            BusinessDate.fromDateTime(movement.date),
          ),
        )
        .toList()
      ..sort((first, second) {
        final byDate = first.date.compareTo(second.date);
        if (byDate != 0) return byDate;
        final byType = first.type.index.compareTo(second.type.index);
        if (byType != 0) return byType;
        return first.id.value.compareTo(second.id.value);
      });

    var openingBalance = baselineBalance;
    var balance = openingBalance;
    final entries = <PartyStatementEntry>[];
    for (final movement in movements) {
      final sides = _normalizeSides(movement.debit, movement.credit);
      balance = balance + sides.debit - sides.credit;
      if (_isBeforeFromDate(query, movement.date)) {
        openingBalance = balance;
        continue;
      }
      entries.add(
        PartyStatementEntry(
          id: movement.id,
          date: movement.date,
          debit: sides.debit,
          credit: sides.credit,
          balance: balance,
          type: movement.type,
          details: movement.details,
          quantity: movement.quantity,
        ),
      );
    }

    return PartyStatementResult(
      query: query,
      entries: List.unmodifiable(entries),
      openingBalance: openingBalance,
      closingBalance: balance,
    );
  }

  static bool _isOnOrBeforeToDate(
    PartyStatementQuery query,
    BusinessDate date,
  ) {
    return date.compareTo(query.toDate) <= 0;
  }

  static bool _isBeforeFromDate(
    PartyStatementQuery query,
    DateTime date,
  ) {
    return BusinessDate.fromDateTime(date).compareTo(query.fromDate) < 0;
  }

  static _PartyStatementMovement _saleMovement(SalesInvoice invoice) {
    return _PartyStatementMovement(
      id: invoice.id,
      date: invoice.date.atTime(
        hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
        minute: invoice.minuteOfDay % Duration.minutesPerHour,
      ),
      debit: invoice.total,
      credit: invoice.receivedAtSale,
      type: PartyStatementEntryType.sale,
      quantity: invoice.lines.fold<int>(
        0,
        (total, line) => total + line.quantity.value,
      ),
      details: _withNotes(
        'قائمة بيع رقم ${invoice.documentNumber}',
        invoice.notes,
      ),
    );
  }

  static _PartyStatementMovement _purchaseMovement(
    PurchaseInvoice invoice, {
    int? originalDocumentNumber,
  }) {
    final isReturn =
        invoice.purchaseKind == PurchaseTransactionKind.returnPurchase;
    return _PartyStatementMovement(
      id: invoice.id,
      date: invoice.date.atTime(
        hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
        minute: invoice.minuteOfDay % Duration.minutesPerHour,
      ),
      debit: isReturn ? invoice.total : invoice.paid,
      credit: isReturn ? invoice.paid : invoice.total,
      type: isReturn
          ? PartyStatementEntryType.purchaseReturn
          : PartyStatementEntryType.purchase,
      quantity: invoice.lines.fold<int>(
        0,
        (total, line) => total + line.quantity.value,
      ),
      details: _withNotes(
        isReturn
            ? 'مرتجع شراء رقم ${invoice.documentNumber} عن القائمة رقم '
                '${originalDocumentNumber ?? 'محذوف'}'
            : 'قائمة شراء رقم ${invoice.documentNumber}',
        invoice.notes,
      ),
    );
  }

  static _PartyStatementMovement _salesReturnMovement(
    SalesReturn value,
  ) {
    return _PartyStatementMovement(
      id: value.id,
      date: value.date.atTime(
        hour: value.minuteOfDay ~/ Duration.minutesPerHour,
        minute: value.minuteOfDay % Duration.minutesPerHour,
      ),
      debit: value.refundedAtReturn,
      credit: value.total,
      type: PartyStatementEntryType.saleReturn,
      quantity: value.lines.fold<int>(
        0,
        (sum, line) => sum + line.quantity.value,
      ),
      details: _withNotes(
        'مرتجع بيع رقم ${value.documentNumber} عن القائمة رقم '
            '${value.originalSalesInvoiceNumberSnapshot}',
        value.notes,
      ),
    );
  }

  static _PartyStatementMovement _expenseMovement(Expense value) {
    return _PartyStatementMovement(
      id: value.id,
      date: value.occurredAt.value.toLocal(),
      debit: Money.zero(value.amount.currency),
      credit: value.amount,
      type: PartyStatementEntryType.expense,
      details: _withNotes(
        'مصروف رقم ${value.documentNumber}: ${value.description}',
        value.notes,
      ),
    );
  }

  static _PartyStatementMovement _expensePaymentMovement(Expense value) {
    return _PartyStatementMovement(
      id: EntityId('${value.id.value}-payment'),
      date: value.paidAt!.value.toLocal(),
      debit: value.amount,
      credit: Money.zero(value.amount.currency),
      type: PartyStatementEntryType.expensePayment,
      details: 'تسديد المصروف رقم ${value.documentNumber}',
    );
  }

  static Iterable<_PartyStatementMovement> _cashboxMovements(
    CashboxVoucher voucher,
    AppCurrency currency,
  ) sync* {
    final amount =
        currency == AppCurrency.iqd ? voucher.iqdAmount : voucher.usdAmount;
    if (amount.isZero) return;
    final isReceipt = voucher.type == CashboxVoucherType.receipt;
    yield _PartyStatementMovement(
      id: voucher.entityId,
      date: voucher.createdAt,
      debit: isReceipt ? Money.zero(currency) : amount,
      credit: isReceipt ? amount : Money.zero(currency),
      type: isReceipt
          ? PartyStatementEntryType.receipt
          : PartyStatementEntryType.payment,
      details: _withNotes(
        'سند ${voucher.type.label} رقم ${voucher.number}',
        voucher.notes,
      ),
    );
  }

  static _StatementSides _normalizeSides(Money debit, Money credit) {
    var debitMinorUnits = debit.minorUnits;
    var creditMinorUnits = credit.minorUnits;
    if (debitMinorUnits < 0) {
      creditMinorUnits += -debitMinorUnits;
      debitMinorUnits = 0;
    }
    if (creditMinorUnits < 0) {
      debitMinorUnits += -creditMinorUnits;
      creditMinorUnits = 0;
    }
    return _StatementSides(
      debit: Money.fromMinorUnits(debitMinorUnits, debit.currency),
      credit: Money.fromMinorUnits(creditMinorUnits, credit.currency),
    );
  }

  static String _withNotes(String details, String notes) {
    final normalizedNotes = notes.trim();
    return normalizedNotes.isEmpty ? details : '$details — $normalizedNotes';
  }
}

@immutable
class _PartyStatementMovement {
  const _PartyStatementMovement({
    required this.id,
    required this.date,
    required this.debit,
    required this.credit,
    required this.type,
    required this.details,
    this.quantity,
  });

  final EntityId id;
  final DateTime date;
  final Money debit;
  final Money credit;
  final PartyStatementEntryType type;
  final String details;
  final int? quantity;
}

@immutable
class _StatementSides {
  const _StatementSides({required this.debit, required this.credit});

  final Money debit;
  final Money credit;
}
