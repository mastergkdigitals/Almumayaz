import '../../../core/domain/business_values.dart';
import '../../installments/application/installment_schedule_builder.dart'
    as typed;

class InstallmentScheduleItem {
  const InstallmentScheduleItem({
    required this.number,
    required this.dueDate,
    required this.amount,
  });

  final int number;
  final DateTime dueDate;
  final num amount;
}

abstract final class InstallmentScheduleBuilder {
  static List<InstallmentScheduleItem> build({
    required num remaining,
    required String currencyCode,
    required DateTime invoiceDate,
    int installmentCount = 4,
  }) {
    if (remaining <= 0 || installmentCount <= 0) return const [];
    final currency = AppCurrency.parse(currencyCode);
    final typedRemaining = Money.fromMajor(remaining, currency);
    if (typedRemaining.isZero) return const [];
    final plan = typed.InstallmentScheduleBuilder.build(
      planId: EntityId('compatibility-installment-plan'),
      salesInvoiceId: EntityId('compatibility-sales-invoice'),
      customerId: EntityId('compatibility-customer'),
      remaining: typedRemaining,
      invoiceDate: BusinessDate.fromDateTime(invoiceDate),
      installmentCount: installmentCount,
    );
    return List.unmodifiable([
      for (final entry in plan.entries)
        InstallmentScheduleItem(
          number: entry.number,
          dueDate: entry.dueDate.atTime(
            hour: invoiceDate.hour,
            minute: invoiceDate.minute,
            second: invoiceDate.second,
          ).add(
                Duration(
                  milliseconds: invoiceDate.millisecond,
                  microseconds: invoiceDate.microsecond,
                ),
              ),
          amount: entry.amount.majorUnits,
        ),
    ]);
  }
}
