import 'dart:math' as math;

import '../../../core/domain/business_values.dart';
import '../domain/installment_plan.dart';

abstract final class InstallmentScheduleBuilder {
  static InstallmentPlan build({
    required EntityId planId,
    required EntityId salesInvoiceId,
    required EntityId customerId,
    required Money remaining,
    required BusinessDate invoiceDate,
    int installmentCount = 4,
  }) {
    if (!remaining.isPositive) {
      throw ArgumentError.value(remaining, 'remaining', 'Must be positive');
    }
    if (installmentCount < 1) {
      throw ArgumentError.value(
        installmentCount,
        'installmentCount',
        'Must be positive',
      );
    }

    final effectiveCount = math.min(
      installmentCount,
      remaining.minorUnits,
    );
    final regularMinorUnits = remaining.minorUnits ~/ effectiveCount;
    return InstallmentPlan(
      id: planId,
      salesInvoiceId: salesInvoiceId,
      customerId: customerId,
      currency: remaining.currency,
      entries: [
        for (var index = 0; index < effectiveCount; index++)
          InstallmentEntry(
            id: EntityId('${planId.value}-entry-${index + 1}'),
            number: index + 1,
            dueDate: _addClampedMonths(invoiceDate, index + 1),
            amount: Money.fromMinorUnits(
              index == effectiveCount - 1
                  ? remaining.minorUnits -
                      regularMinorUnits * (effectiveCount - 1)
                  : regularMinorUnits,
              remaining.currency,
            ),
          ),
      ],
    );
  }

  static BusinessDate _addClampedMonths(BusinessDate date, int months) {
    final zeroBasedTargetMonth = date.year * 12 + date.month - 1 + months;
    final targetYear = zeroBasedTargetMonth ~/ 12;
    final targetMonth = zeroBasedTargetMonth % 12 + 1;
    final lastDayOfTargetMonth = DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;
    return BusinessDate(
      targetYear,
      targetMonth,
      math.min(date.day, lastDayOfTargetMonth),
    );
  }
}
