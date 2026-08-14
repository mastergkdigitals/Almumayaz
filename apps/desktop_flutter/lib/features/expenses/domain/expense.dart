import '../../../core/domain/business_values.dart';

enum ExpensePaymentStatus {
  unpaid('غير مدفوع'),
  paid('مدفوع');

  const ExpensePaymentStatus(this.label);

  final String label;
}

/// A standalone operating expense with an independent, retained number.
///
/// An unpaid expense must belong to a supplier. Payment is all-or-nothing in
/// V1: an unpaid record can only become paid through the explicit settlement
/// repository operation.
class Expense {
  Expense({
    required this.id,
    required this.documentNumber,
    required this.date,
    required this.minuteOfDay,
    required String description,
    required this.amount,
    required this.exchangeRate,
    required this.paymentStatus,
    required String notes,
    this.supplierId,
    String? supplierNameSnapshot,
    this.paidAt,
  })  : description = description.trim(),
        supplierNameSnapshot = supplierNameSnapshot?.trim(),
        notes = notes.trim() {
    if (documentNumber < 1) {
      throw ArgumentError.value(
        documentNumber,
        'documentNumber',
        'Must be positive',
      );
    }
    if (minuteOfDay < 0 || minuteOfDay >= Duration.minutesPerDay) {
      throw ArgumentError.value(
        minuteOfDay,
        'minuteOfDay',
        'Must be within one day',
      );
    }
    if (this.description.isEmpty) {
      throw ArgumentError.value(description, 'description', 'Must not be empty');
    }
    if (!amount.isPositive) {
      throw ArgumentError.value(amount, 'amount', 'Must be positive');
    }
    if ((supplierId == null) != (this.supplierNameSnapshot == null)) {
      throw ArgumentError(
        'supplierId and supplierNameSnapshot must both be set or both be null',
      );
    }
    if (this.supplierNameSnapshot?.isEmpty ?? false) {
      throw ArgumentError.value(
        supplierNameSnapshot,
        'supplierNameSnapshot',
        'Must not be empty',
      );
    }
    switch (paymentStatus) {
      case ExpensePaymentStatus.unpaid:
        if (supplierId == null) {
          throw ArgumentError('An unpaid expense requires a supplier');
        }
        if (paidAt != null) {
          throw ArgumentError('An unpaid expense cannot have a payment time');
        }
        break;
      case ExpensePaymentStatus.paid:
        if (paidAt == null) {
          throw ArgumentError('A paid expense requires a payment time');
        }
        if (paidAt!.compareTo(occurredAt) < 0) {
          throw ArgumentError('Payment cannot precede the expense');
        }
        break;
    }
  }

  final EntityId id;
  final int documentNumber;
  final BusinessDate date;
  final int minuteOfDay;
  final String description;
  final Money amount;
  final ExchangeRate exchangeRate;
  final EntityId? supplierId;
  final String? supplierNameSnapshot;
  final ExpensePaymentStatus paymentStatus;
  final AuditTimestamp? paidAt;
  final String notes;

  AuditTimestamp get occurredAt => AuditTimestamp(
        date.atTime(
          hour: minuteOfDay ~/ Duration.minutesPerHour,
          minute: minuteOfDay % Duration.minutesPerHour,
        ),
      );

  bool get isPaid => paymentStatus == ExpensePaymentStatus.paid;
  bool get isUnpaid => !isPaid;

  String get searchText => [
        documentNumber,
        date,
        description,
        amount.toPlainString(),
        amount.currency.code,
        paymentStatus.label,
        supplierNameSnapshot,
        notes,
      ].whereType<Object>().join(' ').toLowerCase();

  Expense copyWithDetails({
    required BusinessDate date,
    required int minuteOfDay,
    required String description,
    required Money amount,
    required ExchangeRate exchangeRate,
    required EntityId? supplierId,
    required String? supplierNameSnapshot,
    required String notes,
  }) {
    return Expense(
      id: id,
      documentNumber: documentNumber,
      date: date,
      minuteOfDay: minuteOfDay,
      description: description,
      amount: amount,
      exchangeRate: exchangeRate,
      supplierId: supplierId,
      supplierNameSnapshot: supplierNameSnapshot,
      paymentStatus: paymentStatus,
      paidAt: paidAt,
      notes: notes,
    );
  }

  Expense markPaid(AuditTimestamp paymentTime) {
    if (isPaid) throw StateError('المصروف مسدد مسبقاً');
    return Expense(
      id: id,
      documentNumber: documentNumber,
      date: date,
      minuteOfDay: minuteOfDay,
      description: description,
      amount: amount,
      exchangeRate: exchangeRate,
      supplierId: supplierId,
      supplierNameSnapshot: supplierNameSnapshot,
      paymentStatus: ExpensePaymentStatus.paid,
      paidAt: paymentTime,
      notes: notes,
    );
  }
}

class ExpenseCreateRequest {
  const ExpenseCreateRequest({
    required this.date,
    required this.minuteOfDay,
    required this.description,
    required this.amount,
    required this.exchangeRate,
    required this.paymentStatus,
    required this.notes,
    this.supplierId,
    this.paidAt,
  });

  final BusinessDate date;
  final int minuteOfDay;
  final String description;
  final Money amount;
  final ExchangeRate exchangeRate;
  final EntityId? supplierId;
  final ExpensePaymentStatus paymentStatus;
  final AuditTimestamp? paidAt;
  final String notes;
}

class ExpenseUpdateRequest {
  const ExpenseUpdateRequest({
    required this.id,
    required this.date,
    required this.minuteOfDay,
    required this.description,
    required this.amount,
    required this.exchangeRate,
    required this.supplierId,
    required this.notes,
  });

  final EntityId id;
  final BusinessDate date;
  final int minuteOfDay;
  final String description;
  final Money amount;
  final ExchangeRate exchangeRate;
  final EntityId? supplierId;
  final String notes;
}
