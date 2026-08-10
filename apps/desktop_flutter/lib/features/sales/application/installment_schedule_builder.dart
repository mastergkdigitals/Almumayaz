import 'dart:math' as math;

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

    final minorUnitFactor =
        currencyCode.toUpperCase() == 'USD' ? 100 : 1;
    final totalMinorUnits = (remaining * minorUnitFactor).round();
    if (totalMinorUnits <= 0) return const [];

    final effectiveInstallmentCount = installmentCount < totalMinorUnits
        ? installmentCount
        : totalMinorUnits;
    final regularMinorUnits =
        totalMinorUnits ~/ effectiveInstallmentCount;
    return List<InstallmentScheduleItem>.unmodifiable([
      for (var index = 0; index < effectiveInstallmentCount; index++)
        InstallmentScheduleItem(
          number: index + 1,
          dueDate: _addClampedMonths(invoiceDate, index + 1),
          amount: _fromMinorUnits(
            index == effectiveInstallmentCount - 1
                ? totalMinorUnits -
                    regularMinorUnits * (effectiveInstallmentCount - 1)
                : regularMinorUnits,
            minorUnitFactor,
          ),
        ),
    ]);
  }

  static num _fromMinorUnits(int value, int factor) {
    return factor == 1 ? value : value / factor;
  }

  static DateTime _addClampedMonths(DateTime date, int months) {
    final zeroBasedTargetMonth =
        date.year * 12 + date.month - 1 + months;
    final targetYear = zeroBasedTargetMonth ~/ 12;
    final targetMonth = zeroBasedTargetMonth % 12 + 1;
    final lastDayOfTargetMonth = DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;
    return DateTime(
      targetYear,
      targetMonth,
      math.min(date.day, lastDayOfTargetMonth),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
