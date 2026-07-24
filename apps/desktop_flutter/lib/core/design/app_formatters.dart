import 'package:flutter/material.dart';

abstract final class AppFormatters {
  static String date(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String time(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final period = value.period == DayPeriod.am ? 'ص' : 'م';
    return '${hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')} $period';
  }

  static String quantity(int value) => _groupInteger(value);

  static String iqd(num value) => money(value);

  static String usd(num value) => money(value, decimalPlaces: 2);

  static String money(
    num value, {
    int decimalPlaces = 0,
  }) {
    assert(decimalPlaces >= 0 && decimalPlaces <= 4);
    final fixed = value.abs().toStringAsFixed(decimalPlaces);
    final parts = fixed.split('.');
    final sign = value.isNegative ? '-' : '';
    final whole = _groupDigits(parts.first);

    if (parts.length == 1) return '$sign$whole';
    return '$sign$whole.${parts.last}';
  }

  static int? parseInteger(String value) {
    return int.tryParse(value.replaceAll(',', '').trim());
  }

  static num? parseNumber(String value) {
    return num.tryParse(value.replaceAll(',', '').trim());
  }

  static String currency(String code) => switch (code.toUpperCase()) {
        'IQD' => 'دينار',
        'USD' => 'دولار',
        _ => code,
      };

  static String _groupInteger(int value) {
    final sign = value.isNegative ? '-' : '';
    return '$sign${_groupDigits(value.abs().toString())}';
  }

  static String _groupDigits(String digits) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
