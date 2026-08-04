/// Strongly typed values shared by the Flutter application.
///
/// These types keep parsing, rounding and validation rules out of widgets so
/// the same rules can later be reused by API-backed repositories.
library;

enum AppCurrency {
  iqd(code: 'IQD', arabicName: 'دينار', decimalPlaces: 0),
  usd(code: 'USD', arabicName: 'دولار', decimalPlaces: 2);

  const AppCurrency({
    required this.code,
    required this.arabicName,
    required this.decimalPlaces,
  });

  final String code;
  final String arabicName;
  final int decimalPlaces;

  int get scale => _powerOfTen(decimalPlaces);

  static AppCurrency parse(String value) {
    final normalized = value.trim().toUpperCase();
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == normalized,
      orElse: () => throw FormatException('Unsupported currency: $value'),
    );
  }
}

class Money implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits, this.currency);

  factory Money.zero(AppCurrency currency) {
    return Money.fromMinorUnits(0, currency);
  }

  factory Money.parse(String value, AppCurrency currency) {
    return Money.fromMinorUnits(
      _parseScaledNumber(value, currency.decimalPlaces),
      currency,
    );
  }

  factory Money.fromMajor(num value, AppCurrency currency) {
    return Money.parse(value.toString(), currency);
  }

  final int minorUnits;
  final AppCurrency currency;

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;
  num get majorUnits => minorUnits / currency.scale;

  Money clamp({Money? minimum, Money? maximum}) {
    _requireSameCurrency(minimum);
    _requireSameCurrency(maximum);
    if (minimum != null && this < minimum) return minimum;
    if (maximum != null && this > maximum) return maximum;
    return this;
  }

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money.fromMinorUnits(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money.fromMinorUnits(minorUnits - other.minorUnits, currency);
  }

  Money operator *(int multiplier) {
    return Money.fromMinorUnits(minorUnits * multiplier, currency);
  }

  Money percentage(Percentage percentage) {
    final scaled = minorUnits * percentage.basisPoints;
    return Money.fromMinorUnits(
      _roundRatio(scaled, Percentage.basisPointsPerHundredPercent),
      currency,
    );
  }

  String toPlainString() {
    final sign = minorUnits < 0 ? '-' : '';
    final absolute = minorUnits.abs();
    if (currency.decimalPlaces == 0) return '$sign$absolute';
    final whole = absolute ~/ currency.scale;
    final fraction = (absolute % currency.scale)
        .toString()
        .padLeft(currency.decimalPlaces, '0');
    return '$sign$whole.$fraction';
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _requireSameCurrency(Money? other) {
    if (other != null && other.currency != currency) {
      throw ArgumentError(
        'Money values must use the same currency: '
        '${currency.code} != ${other.currency.code}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${toPlainString()} ${currency.code}';
}

class ExchangeRate implements Comparable<ExchangeRate> {
  const ExchangeRate._(this.tenThousandths);

  factory ExchangeRate.parse(String value) {
    final scaled = _parseScaledNumber(value, decimalPlaces);
    if (scaled <= 0) {
      throw ArgumentError.value(value, 'value', 'Must be greater than zero');
    }
    return ExchangeRate._(scaled);
  }

  static const decimalPlaces = 4;
  final int tenThousandths;

  num get value => tenThousandths / _powerOfTen(decimalPlaces);

  String toPlainString() {
    final whole = tenThousandths ~/ _powerOfTen(decimalPlaces);
    final fraction = (tenThousandths % _powerOfTen(decimalPlaces))
        .toString()
        .padLeft(decimalPlaces, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }

  @override
  int compareTo(ExchangeRate other) =>
      tenThousandths.compareTo(other.tenThousandths);

  @override
  bool operator ==(Object other) =>
      other is ExchangeRate && other.tenThousandths == tenThousandths;

  @override
  int get hashCode => tenThousandths.hashCode;

  @override
  String toString() => toPlainString();
}

class Percentage implements Comparable<Percentage> {
  Percentage.fromBasisPoints(int basisPoints) : basisPoints = basisPoints {
    if (basisPoints < 0 || basisPoints > basisPointsPerHundredPercent) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'Must be between 0 and $basisPointsPerHundredPercent',
      );
    }
  }

  factory Percentage.parse(String value) {
    final scaled = _parseScaledNumber(value, 2);
    if (scaled < 0 || scaled > basisPointsPerHundredPercent) {
      throw ArgumentError.value(value, 'value', 'Must be between 0 and 100');
    }
    return Percentage.fromBasisPoints(scaled);
  }

  static const basisPointsPerHundredPercent = 10000;
  final int basisPoints;

  num get value => basisPoints / 100;
  bool get isZero => basisPoints == 0;

  String toPlainString() {
    final whole = basisPoints ~/ 100;
    final fraction = (basisPoints % 100).toString().padLeft(2, '0');
    return fraction == '00' ? '$whole' : '$whole.$fraction';
  }

  @override
  int compareTo(Percentage other) => basisPoints.compareTo(other.basisPoints);

  @override
  bool operator ==(Object other) =>
      other is Percentage && other.basisPoints == basisPoints;

  @override
  int get hashCode => basisPoints.hashCode;

  @override
  String toString() => '${toPlainString()}%';
}

class WholeQuantity implements Comparable<WholeQuantity> {
  WholeQuantity(int value) : value = value {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Must not be negative');
    }
  }

  factory WholeQuantity.parse(String value) {
    final normalized = _normalizeNumber(value);
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      throw FormatException('Quantity must be a whole number: $value');
    }
    return WholeQuantity(int.parse(normalized));
  }

  final int value;

  bool get isZero => value == 0;

  @override
  int compareTo(WholeQuantity other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is WholeQuantity && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}

class BusinessDate implements Comparable<BusinessDate> {
  BusinessDate(int year, int month, int day)
      : value = _validatedDate(year, month, day);

  factory BusinessDate.fromDateTime(DateTime value) {
    return BusinessDate(value.year, value.month, value.day);
  }

  final DateTime value;

  int get year => value.year;
  int get month => value.month;
  int get day => value.day;

  DateTime atTime({int hour = 0, int minute = 0, int second = 0}) {
    return DateTime(year, month, day, hour, minute, second);
  }

  @override
  int compareTo(BusinessDate other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is BusinessDate && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class AuditTimestamp implements Comparable<AuditTimestamp> {
  AuditTimestamp(DateTime value) : value = value.toUtc();

  final DateTime value;

  @override
  int compareTo(AuditTimestamp other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is AuditTimestamp && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toIso8601String();
}

class EntityId {
  EntityId(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'ID must not be empty');
    }
  }

  factory EntityId.demo(String entityType, int sequence) {
    final normalizedType = entityType.trim().toLowerCase();
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(normalizedType)) {
      throw ArgumentError.value(entityType, 'entityType', 'Invalid type');
    }
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'Must be positive');
    }
    return EntityId('demo-$normalizedType-$sequence');
  }

  final String value;

  @override
  bool operator ==(Object other) => other is EntityId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

int _parseScaledNumber(String value, int decimalPlaces) {
  final normalized = _normalizeNumber(value);
  final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$').firstMatch(normalized);
  if (match == null) throw FormatException('Invalid number: $value');

  final negative = match.group(1) == '-';
  final whole = int.parse(match.group(2)!);
  final fractionText = match.group(3) ?? '';
  final scale = _powerOfTen(decimalPlaces);
  final paddedFraction = fractionText.padRight(decimalPlaces + 1, '0');
  var fraction = decimalPlaces == 0
      ? 0
      : int.parse(paddedFraction.substring(0, decimalPlaces));
  final roundingDigit = int.parse(
    paddedFraction.substring(decimalPlaces, decimalPlaces + 1),
  );
  if (roundingDigit >= 5) fraction++;

  var result = whole * scale + fraction;
  if (fraction >= scale) result = (whole + 1) * scale;
  return negative ? -result : result;
}

String _normalizeNumber(String value) {
  return value
      .trim()
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll('٫', '.')
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');
}

int _roundRatio(int numerator, int denominator) {
  final sign = numerator < 0 ? -1 : 1;
  final absolute = numerator.abs();
  return sign * ((absolute + denominator ~/ 2) ~/ denominator);
}

int _powerOfTen(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index++) {
    result *= 10;
  }
  return result;
}

DateTime _validatedDate(int year, int month, int day) {
  final value = DateTime(year, month, day);
  if (value.year != year || value.month != month || value.day != day) {
    throw ArgumentError('Invalid business date: $year-$month-$day');
  }
  return value;
}
