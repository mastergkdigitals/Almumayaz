import 'package:erp/features/sales/application/installment_schedule_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allocates whole IQD amounts and puts the remainder in the last row',
      () {
    final schedule = InstallmentScheduleBuilder.build(
      remaining: 1003,
      currencyCode: 'IQD',
      invoiceDate: DateTime(2026, 1, 31),
    );

    expect(
      schedule.map((installment) => installment.amount).toList(),
      [250, 250, 250, 253],
    );
    expect(
      schedule.fold<num>(
        0,
        (total, installment) => total + installment.amount,
      ),
      1003,
    );
  });

  test('uses cents for USD and clamps month-end due dates', () {
    final schedule = InstallmentScheduleBuilder.build(
      remaining: 1000.01,
      currencyCode: 'USD',
      invoiceDate: DateTime(2026, 1, 31, 9, 45),
    );

    expect(
      schedule.map((installment) => installment.amount).toList(),
      [250, 250, 250, 250.01],
    );
    expect(
      schedule.map((installment) => installment.dueDate).toList(),
      [
        DateTime(2026, 2, 28, 9, 45),
        DateTime(2026, 3, 31, 9, 45),
        DateTime(2026, 4, 30, 9, 45),
        DateTime(2026, 5, 31, 9, 45),
      ],
    );
    expect(
      schedule.fold<num>(
        0,
        (total, installment) => total + installment.amount,
      ),
      closeTo(1000.01, 0.000001),
    );
  });
}
