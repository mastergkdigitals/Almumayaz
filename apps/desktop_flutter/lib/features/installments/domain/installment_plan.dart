import 'package:flutter/foundation.dart';

import '../../../core/domain/business_values.dart';

enum InstallmentPaymentStatus { pending, paid }

@immutable
class InstallmentEntry {
  InstallmentEntry({
    required this.id,
    required this.number,
    required this.dueDate,
    required this.amount,
    this.status = InstallmentPaymentStatus.pending,
    this.paidAt,
    String notes = '',
  }) : notes = notes.trim() {
    if (number < 1) {
      throw ArgumentError.value(number, 'number', 'Must be positive');
    }
    if (!amount.isPositive) {
      throw ArgumentError.value(amount, 'amount', 'Must be positive');
    }
    final isPaid = status == InstallmentPaymentStatus.paid;
    if (isPaid != (paidAt != null)) {
      throw ArgumentError(
        'A paid installment must have a payment timestamp, and a pending '
        'installment must not have one.',
      );
    }
  }

  final EntityId id;
  final int number;
  final BusinessDate dueDate;
  final Money amount;
  final InstallmentPaymentStatus status;
  final AuditTimestamp? paidAt;
  final String notes;

  bool get isPaid => status == InstallmentPaymentStatus.paid;

  InstallmentEntry markPaid({
    required AuditTimestamp paidAt,
    String notes = '',
  }) {
    if (isPaid) throw StateError('القسط مسدد مسبقاً');
    return InstallmentEntry(
      id: id,
      number: number,
      dueDate: dueDate,
      amount: amount,
      status: InstallmentPaymentStatus.paid,
      paidAt: paidAt,
      notes: notes,
    );
  }

  InstallmentEntry copyWith({
    BusinessDate? dueDate,
    Money? amount,
    String? notes,
  }) {
    return InstallmentEntry(
      id: id,
      number: number,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status,
      paidAt: paidAt,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class InstallmentPlan {
  InstallmentPlan({
    required this.id,
    required this.salesInvoiceId,
    required this.customerId,
    required this.currency,
    required Iterable<InstallmentEntry> entries,
  }) : entries = List.unmodifiable(entries) {
    if (this.entries.any((entry) => entry.amount.currency != currency)) {
      throw ArgumentError('Every installment must use the plan currency');
    }
    if ({for (final entry in this.entries) entry.id}.length !=
        this.entries.length) {
      throw ArgumentError('Installment entry IDs must be unique');
    }
    if ({for (final entry in this.entries) entry.number}.length !=
        this.entries.length) {
      throw ArgumentError('Installment numbers must be unique');
    }
  }

  final EntityId id;
  final EntityId salesInvoiceId;
  final EntityId customerId;
  final AppCurrency currency;
  final List<InstallmentEntry> entries;

  Money get total => entries.fold(
        Money.zero(currency),
        (sum, entry) => sum + entry.amount,
      );

  Money get paid => entries.where((entry) => entry.isPaid).fold(
        Money.zero(currency),
        (sum, entry) => sum + entry.amount,
      );

  Money get remaining => total - paid;

  bool get hasPaidEntries => entries.any((entry) => entry.isPaid);

  InstallmentEntry? entryById(EntityId entryId) {
    for (final entry in entries) {
      if (entry.id == entryId) return entry;
    }
    return null;
  }

  InstallmentPlan markEntryPaid({
    required EntityId entryId,
    required AuditTimestamp paidAt,
    String notes = '',
  }) {
    final current = entryById(entryId);
    if (current == null) throw StateError('القسط المحدد غير موجود');
    return InstallmentPlan(
      id: id,
      salesInvoiceId: salesInvoiceId,
      customerId: customerId,
      currency: currency,
      entries: [
        for (final entry in entries)
          if (entry.id == entryId)
            entry.markPaid(paidAt: paidAt, notes: notes)
          else
            entry,
      ],
    );
  }
}
