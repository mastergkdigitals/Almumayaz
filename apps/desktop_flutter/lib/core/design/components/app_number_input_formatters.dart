import 'package:flutter/services.dart';

class AppIntegerInputFormatter extends TextInputFormatter {
  const AppIntegerInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _formatNumber(
      oldValue: oldValue,
      newValue: newValue,
      decimalPlaces: null,
    );
  }
}

class AppMoneyInputFormatter extends TextInputFormatter {
  const AppMoneyInputFormatter({this.decimalPlaces = 4})
      : assert(decimalPlaces >= 0);

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _formatNumber(
      oldValue: oldValue,
      newValue: newValue,
      decimalPlaces: decimalPlaces,
    );
  }
}

TextEditingValue _formatNumber({
  required TextEditingValue oldValue,
  required TextEditingValue newValue,
  required int? decimalPlaces,
}) {
  final ungrouped = newValue.text.replaceAll(',', '');
  if (ungrouped.isEmpty) {
    return const TextEditingValue(
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  final valid = decimalPlaces == null
      ? RegExp(r'^\d+$').hasMatch(ungrouped)
      : RegExp('^\\d*(?:\\.\\d{0,$decimalPlaces})?\$')
          .hasMatch(ungrouped);
  if (!valid) return oldValue;

  final decimalIndex = ungrouped.indexOf('.');
  final integerPart = decimalIndex < 0
      ? ungrouped
      : ungrouped.substring(0, decimalIndex);
  final fractionPart =
      decimalIndex < 0 ? null : ungrouped.substring(decimalIndex + 1);
  final groupedInteger = _groupDigits(integerPart);
  final formatted = fractionPart == null
      ? groupedInteger
      : '$groupedInteger.$fractionPart';

  return TextEditingValue(
    text: formatted,
    selection: TextSelection(
      baseOffset: _mapOffset(
        formatted,
        _ungroupedOffset(newValue.text, newValue.selection.baseOffset),
      ),
      extentOffset: _mapOffset(
        formatted,
        _ungroupedOffset(newValue.text, newValue.selection.extentOffset),
      ),
      affinity: newValue.selection.affinity,
      isDirectional: newValue.selection.isDirectional,
    ),
    composing: TextRange.empty,
  );
}

String _groupDigits(String digits) {
  if (digits.isEmpty) return '';

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

int _ungroupedOffset(String text, int offset) {
  if (offset < 0) return 0;
  final safeOffset = offset > text.length ? text.length : offset;
  return text.substring(0, safeOffset).replaceAll(',', '').length;
}

int _mapOffset(String formatted, int ungroupedOffset) {
  if (ungroupedOffset <= 0) return 0;

  var seen = 0;
  for (var index = 0; index < formatted.length; index++) {
    if (formatted[index] != ',') seen++;
    if (seen == ungroupedOffset) return index + 1;
  }
  return formatted.length;
}
