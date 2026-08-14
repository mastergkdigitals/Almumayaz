/// Allocates an integer [total] proportionally without losing a minor unit.
///
/// Negative weights are treated as zero. The largest remainders receive the
/// residual units and original order breaks ties, so identical inputs always
/// produce identical allocations.
List<int> allocateIntegerByWeights(int total, List<int> weights) {
  if (total < 0) {
    throw ArgumentError.value(total, 'total', 'Must not be negative');
  }
  final allocations = List<int>.filled(weights.length, 0);
  if (total == 0 || weights.isEmpty) return allocations;

  final normalized = [for (final weight in weights) weight < 0 ? 0 : weight];
  final exactWeightTotal = normalized.fold<BigInt>(
    BigInt.zero,
    (sum, value) => sum + BigInt.from(value),
  );
  if (exactWeightTotal == BigInt.zero) return allocations;

  final remainders = List<BigInt>.filled(weights.length, BigInt.zero);
  final exactTotal = BigInt.from(total);
  var allocated = 0;
  for (var index = 0; index < normalized.length; index++) {
    final weightedTotal = exactTotal * BigInt.from(normalized[index]);
    allocations[index] = (weightedTotal ~/ exactWeightTotal).toInt();
    remainders[index] = weightedTotal % exactWeightTotal;
    allocated += allocations[index];
  }

  final order = List<int>.generate(weights.length, (index) => index)
    ..sort((left, right) {
      final byRemainder = remainders[right].compareTo(remainders[left]);
      return byRemainder != 0 ? byRemainder : left.compareTo(right);
    });
  for (var offset = 0; offset < total - allocated; offset++) {
    allocations[order[offset]]++;
  }
  return allocations;
}

/// Allocates a final invoice value to its lines using the agreed fallbacks.
///
/// Net line value is authoritative. Gross value, quantity, and finally equal
/// line weight cover fully discounted and zero-value documents without
/// introducing presentation-layer arithmetic into persistence code.
List<int> allocateInvoiceTotalMinorUnits({
  required int totalMinorUnits,
  required List<int> netLineMinorUnits,
  required List<int> grossLineMinorUnits,
  required List<int> quantities,
  List<bool>? includedLines,
}) {
  final length = netLineMinorUnits.length;
  if (grossLineMinorUnits.length != length || quantities.length != length) {
    throw ArgumentError(
      'Every invoice allocation input must have equal length',
    );
  }
  if (includedLines != null && includedLines.length != length) {
    throw ArgumentError('includedLines must match the invoice line count');
  }
  if (totalMinorUnits < 0) {
    throw ArgumentError.value(
      totalMinorUnits,
      'totalMinorUnits',
      'Must not be negative',
    );
  }
  if (length == 0) return const [];

  final included = includedLines ?? List<bool>.filled(length, true);
  List<int> eligible(List<int> source) => [
        for (var index = 0; index < length; index++)
          included[index] && source[index] > 0 ? source[index] : 0,
      ];
  var weights = eligible(netLineMinorUnits);
  if (weights.every((weight) => weight == 0)) {
    weights = eligible(grossLineMinorUnits);
  }
  if (weights.every((weight) => weight == 0)) {
    weights = eligible(quantities);
  }
  if (weights.every((weight) => weight == 0)) {
    weights = [for (final isIncluded in included) isIncluded ? 1 : 0];
  }
  return allocateIntegerByWeights(totalMinorUnits, weights);
}

/// Integer division rounded to the nearest value, with halves away from zero.
int divideAndRoundHalfAwayFromZero(int numerator, int denominator) {
  return multiplyDivideAndRoundHalfAwayFromZero(
    numerator,
    1,
    denominator,
  );
}

/// Multiplies before dividing, without overflowing an intermediate [int].
///
/// The result is rounded to the nearest integer, with exact halves away from
/// zero. The mathematically rounded result must still fit in an [int].
int multiplyDivideAndRoundHalfAwayFromZero(
  int multiplicand,
  int multiplier,
  int denominator,
) {
  if (denominator <= 0) {
    throw ArgumentError.value(denominator, 'denominator', 'Must be positive');
  }
  final product = BigInt.from(multiplicand) * BigInt.from(multiplier);
  final absolute = product.abs();
  final rounded =
      (absolute + BigInt.from(denominator ~/ 2)) ~/ BigInt.from(denominator);
  final signed = product.isNegative ? -rounded : rounded;
  final result = signed.toInt();
  if (BigInt.from(result) != signed) {
    throw RangeError('Rounded multiply/divide result does not fit in an int');
  }
  return result;
}
