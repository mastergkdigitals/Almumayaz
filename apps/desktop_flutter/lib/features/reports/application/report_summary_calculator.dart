import '../domain/report_models.dart';

/// Calculates report summaries from the rows that are currently visible.
///
/// The demo report rows intentionally keep their display-ready strings. This
/// calculator is the single safe boundary that parses those values and turns
/// them into typed numbers. Invalid or missing cells never throw and are
/// excluded from the affected calculation.
abstract final class ReportSummaryCalculator {
  static List<ReportMetricValue> calculate({
    required String reportId,
    required String variantId,
    required List<ReportRowDefinition> rows,
    required List<ReportMetricDefinition> fallbackMetrics,
    Map<String, String> selectedFilters = const {},
    num? cashboxOpeningIqd,
    num? cashboxOpeningUsd,
  }) {
    final values = switch ((reportId, variantId)) {
      ('salesInvoices', 'returns') => _salesReturnValues(rows),
      ('salesInvoices', _) => _invoiceValues(
          rows,
          paidColumn: 8,
          paidLabel: 'المقبوض',
        ),
      ('purchaseInvoices', _) => _purchaseValues(rows),
      ('profits', _) => _profitValues(rows),
      ('inventory', 'currentStock') => _stockValues(rows),
      ('inventory', 'transfers') => _transferValues(rows),
      ('cashbox', 'expenses') => _expenseValues(rows),
      ('cashbox', _) => _cashboxValues(
          rows,
          openingIqd: cashboxOpeningIqd,
          openingUsd: cashboxOpeningUsd,
        ),
      ('partyBalances', _) => _partyBalanceValues(
          rows,
          selectedCurrency: selectedFilters['currency'],
        ),
      ('debtsInstallments', _) => _debtValues(rows),
      _ => const <String, String>{},
    };

    return [
      for (final metric in fallbackMetrics)
        ReportMetricValue(
          label: metric.label,
          value: values[metric.label] ?? _emptyValueFor(metric.label),
          spreadsheetCellKind: metric.spreadsheetCellKind,
          spreadsheetDecimalPlaces: metric.spreadsheetDecimalPlaces,
        ),
    ];
  }

  static Map<String, String> _invoiceValues(
    List<ReportRowDefinition> rows, {
    required int paidColumn,
    required String paidLabel,
    int totalColumn = 7,
    int remainingColumn = 9,
  }) {
    final values = <String, String>{};
    for (final currency in const ['IQD', 'USD']) {
      final currencyRows = rows
          .where((row) => _hasFilterValue(row, 'currency', currency))
          .toList(growable: false);
      final suffix = currency == 'IQD' ? 'دينار' : 'دولار';
      final decimals = currency == 'IQD' ? 0 : 2;
      values['عدد القوائم - $suffix'] = '${currencyRows.length}';
      values['الإجمالي - $suffix'] = _format(
        _sumColumn(currencyRows, totalColumn),
        decimals: decimals,
      );
      values['$paidLabel - $suffix'] = _format(
        _sumColumn(currencyRows, paidColumn),
        decimals: decimals,
      );
      values['المتبقي - $suffix'] = _format(
        _sumColumn(currencyRows, remainingColumn),
        decimals: decimals,
      );
    }
    return values;
  }

  static Map<String, String> _profitValues(
    List<ReportRowDefinition> rows,
  ) {
    final values = <String, String>{};
    for (final currency in const ['IQD', 'USD']) {
      final currencyRows = rows
          .where((row) => _hasFilterValue(row, 'currency', currency))
          .toList(growable: false);
      final costedRows = currencyRows
          .where((row) => _numberAt(row, 10) != null)
          .toList(growable: false);
      final costedSales = _sumColumn(costedRows, 9);
      final cost = _sumColumn(costedRows, 10);
      final profit = _sumColumn(costedRows, 11);
      final suffix = currency == 'IQD' ? 'دينار' : 'دولار';
      final decimals = currency == 'IQD' ? 0 : 2;
      values['المبيعات المحتسبة - $suffix'] =
          _format(costedSales, decimals: decimals);
      if (currencyRows.isNotEmpty && costedRows.isEmpty) {
        values['التكلفة - $suffix'] = 'غير متوفرة';
        values['الربح - $suffix'] = 'غير متوفر';
        values['هامش الربح - $suffix'] = 'غير متوفر';
        continue;
      }
      values['التكلفة - $suffix'] = _format(cost, decimals: decimals);
      values['الربح - $suffix'] = _format(profit, decimals: decimals);
      values['هامش الربح - $suffix'] =
          costedSales == 0
              ? '0.00%'
              : '${(profit / costedSales * 100).toStringAsFixed(2)}%';
    }
    return values;
  }

  static Map<String, String> _salesReturnValues(
    List<ReportRowDefinition> rows,
  ) {
    final values = <String, String>{};
    for (final currency in const ['IQD', 'USD']) {
      final currencyRows = rows
          .where((row) => _hasFilterValue(row, 'currency', currency))
          .toList(growable: false);
      final suffix = currency == 'IQD' ? 'دينار' : 'دولار';
      final decimals = currency == 'IQD' ? 0 : 2;
      values['عدد المرتجعات - $suffix'] = '${currencyRows.length}';
      values['الإجمالي - $suffix'] = _format(
        _sumColumn(currencyRows, 6),
        decimals: decimals,
      );
      values['المسترد - $suffix'] = _format(
        _sumColumn(currencyRows, 7),
        decimals: decimals,
      );
      values['المضاف للرصيد - $suffix'] = _format(
        _sumColumn(currencyRows, 8),
        decimals: decimals,
      );
    }
    return values;
  }

  static Map<String, String> _purchaseValues(
    List<ReportRowDefinition> rows,
  ) {
    final values = <String, String>{};
    for (final currency in const ['IQD', 'USD']) {
      final currencyRows = rows
          .where((row) => _hasFilterValue(row, 'currency', currency))
          .toList(growable: false);
      final suffix = currency == 'IQD' ? 'دينار' : 'دولار';
      final decimals = currency == 'IQD' ? 0 : 2;
      double netColumn(int column) => currencyRows.fold<double>(
            0,
            (sum, row) {
              final direction =
                  _hasFilterValue(row, 'purchaseType', 'return') ? -1 : 1;
              return sum + (_numberAt(row, column) ?? 0) * direction;
            },
          );
      values['عدد القوائم - $suffix'] = '${currencyRows.length}';
      values['الإجمالي - $suffix'] = _format(
        netColumn(9),
        decimals: decimals,
      );
      values['المدفوع - $suffix'] = _format(
        netColumn(10),
        decimals: decimals,
      );
      values['المتبقي - $suffix'] = _format(
        netColumn(11),
        decimals: decimals,
      );
    }
    return values;
  }

  static Map<String, String> _stockValues(
    List<ReportRowDefinition> rows,
  ) {
    final products = <String>{};
    final warehouses = <String>{};
    var positiveBalances = 0;
    var quantity = 0.0;
    for (final row in rows) {
      final product = _textAt(row, 1);
      final warehouse = _textAt(row, 5);
      if (product != null) products.add(product);
      if (warehouse != null) warehouses.add(warehouse);
      final rowQuantity = _numberAt(row, 6);
      if (rowQuantity != null) {
        quantity += rowQuantity;
        if (rowQuantity > 0) positiveBalances++;
      }
    }
    return {
      'المواد المختلفة': '${products.length}',
      'المخازن': '${warehouses.length}',
      'الأرصدة الموجبة': '$positiveBalances',
      'مجموع الكميات': _format(quantity),
    };
  }

  static Map<String, String> _transferValues(
    List<ReportRowDefinition> rows,
  ) {
    final quantityPattern = RegExp(r'\(([0-9][0-9,]*(?:\.[0-9]+)?)\)');
    var lineCount = 0;
    var quantity = 0.0;
    for (final row in rows) {
      final items = _textAt(row, 5) ?? '';
      for (final match in quantityPattern.allMatches(items)) {
        lineCount++;
        quantity += _parseNumber(match.group(1)) ?? 0;
      }
    }
    return {
      'عدد عمليات النقل': '${rows.length}',
      'عدد سطور المواد': '$lineCount',
      'مجموع الكميات': _format(quantity),
    };
  }

  static Map<String, String> _cashboxValues(
    List<ReportRowDefinition> rows, {
    num? openingIqd,
    num? openingUsd,
  }) {
    final resolvedOpeningIqd = (openingIqd ?? 9800000).toDouble();
    final resolvedOpeningUsd = (openingUsd ?? 4500).toDouble();

    double received(int amountColumn) => rows
        .where((row) => _textAt(row, 4) == 'قبض')
        .fold<double>(
          0,
          (sum, row) => sum + (_numberAt(row, amountColumn) ?? 0),
        );
    double spent(int amountColumn) => rows
        .where((row) => _textAt(row, 4) == 'صرف')
        .fold<double>(
          0,
          (sum, row) => sum + (_numberAt(row, amountColumn) ?? 0),
        );

    final receivedIqd = received(7);
    final spentIqd = spent(7);
    final receivedUsd = received(8);
    final spentUsd = spent(8);
    final netIqd = receivedIqd - spentIqd;
    final netUsd = receivedUsd - spentUsd;
    final hasIqd = rows.any(
      (row) => _hasFilterValue(row, 'currency', 'IQD'),
    );
    final hasUsd = rows.any(
      (row) => _hasFilterValue(row, 'currency', 'USD'),
    );

    return {
      'القبض - دينار': _format(receivedIqd),
      'الصرف - دينار': _format(spentIqd),
      'الصافي - دينار': _format(netIqd),
      'الرصيد - دينار': _format(
        hasIqd ? resolvedOpeningIqd + netIqd : 0,
      ),
      'القبض - دولار': _format(receivedUsd, decimals: 2),
      'الصرف - دولار': _format(spentUsd, decimals: 2),
      'الصافي - دولار': _format(netUsd, decimals: 2),
      'الرصيد - دولار': _format(
        hasUsd ? resolvedOpeningUsd + netUsd : 0,
        decimals: 2,
      ),
      'عدد الحركات': '${rows.length}',
    };
  }

  static Map<String, String> _expenseValues(
    List<ReportRowDefinition> rows,
  ) {
    double amountFor(String currency, String status, int column) => rows
        .where(
          (row) =>
              _hasFilterValue(row, 'currency', currency) &&
              _hasFilterValue(row, 'status', status),
        )
        .fold<double>(
          0,
          (sum, row) => sum + (_numberAt(row, column) ?? 0),
        );
    return {
      'عدد المصاريف': '${rows.length}',
      'المدفوع - دينار': _format(amountFor('IQD', 'paid', 9)),
      'غير المدفوع - دينار': _format(amountFor('IQD', 'unpaid', 10)),
      'المدفوع - دولار': _format(
        amountFor('USD', 'paid', 9),
        decimals: 2,
      ),
      'غير المدفوع - دولار': _format(
        amountFor('USD', 'unpaid', 10),
        decimals: 2,
      ),
      'عدد غير المدفوع':
          '${rows.where((row) => _hasFilterValue(row, 'status', 'unpaid')).length}',
    };
  }

  static Map<String, String> _partyBalanceValues(
    List<ReportRowDefinition> rows, {
    String? selectedCurrency,
  }) {
    final includeIqd = selectedCurrency == null ||
        selectedCurrency == 'all' ||
        selectedCurrency == 'IQD';
    final includeUsd = selectedCurrency == null ||
        selectedCurrency == 'all' ||
        selectedCurrency == 'USD';
    var withoutBalance = 0;
    var receivableIqd = 0.0;
    var receivableUsd = 0.0;
    var payableIqd = 0.0;
    var payableUsd = 0.0;

    for (final row in rows) {
      final iqd = _numberAt(row, 8) ?? 0;
      final usd = _numberAt(row, 10) ?? 0;
      if ((!includeIqd || iqd == 0) && (!includeUsd || usd == 0)) {
        withoutBalance++;
      }
      if (includeIqd && _textAt(row, 9) == 'لنا') receivableIqd += iqd;
      if (includeUsd && _textAt(row, 11) == 'لنا') receivableUsd += usd;
      if (includeIqd && _textAt(row, 9) == 'علينا') payableIqd += iqd;
      if (includeUsd && _textAt(row, 11) == 'علينا') payableUsd += usd;
    }

    return {
      'عدد الأطراف': '${rows.length}',
      'بدون رصيد': '$withoutBalance',
      'ذمم لنا - دينار': _format(receivableIqd),
      'ذمم لنا - دولار': _format(receivableUsd, decimals: 2),
      'ذمم علينا - دينار': _format(payableIqd),
      'ذمم علينا - دولار': _format(payableUsd, decimals: 2),
    };
  }

  static Map<String, String> _debtValues(
    List<ReportRowDefinition> rows,
  ) {
    final values = <String, String>{};
    for (final currency in const ['IQD', 'USD']) {
      final currencyRows = rows
          .where((row) => _hasFilterValue(row, 'currency', currency))
          .toList(growable: false);
      final suffix = currency == 'IQD' ? 'دينار' : 'دولار';
      final decimals = currency == 'IQD' ? 0 : 2;
      double sumForStatus(String status, int column) => currencyRows
          .where((row) => _textAt(row, 10) == status)
          .fold<double>(
            0,
            (sum, row) => sum + (_numberAt(row, column) ?? 0),
          );
      values['المتبقي - $suffix'] = _format(
        _sumColumn(currencyRows, 9),
        decimals: decimals,
      );
      values['المتأخر - $suffix'] = _format(
        sumForStatus('متأخر', 9),
        decimals: decimals,
      );
      values['المستحق - $suffix'] = _format(
        sumForStatus('مستحق', 9),
        decimals: decimals,
      );
      values['المدفوع - $suffix'] = _format(
        _sumColumn(currencyRows, 8),
        decimals: decimals,
      );
    }
    values['عدد المتأخر'] =
        '${rows.where((row) => _textAt(row, 10) == 'متأخر').length}';
    values['عدد المستحق'] =
        '${rows.where((row) => _textAt(row, 10) == 'مستحق').length}';
    return values;
  }

  static bool _hasFilterValue(
    ReportRowDefinition row,
    String id,
    String value,
  ) {
    return (row.filterValues[id] ?? '').split('|').contains(value);
  }

  static double _sumColumn(
    List<ReportRowDefinition> rows,
    int column,
  ) {
    return rows.fold<double>(
      0,
      (sum, row) => sum + (_numberAt(row, column) ?? 0),
    );
  }

  static double? _numberAt(ReportRowDefinition row, int index) {
    return _parseNumber(_textAt(row, index));
  }

  static String? _textAt(ReportRowDefinition row, int index) {
    if (index < 0 || index >= row.cells.length) return null;
    return row.cells[index];
  }

  static double? _parseNumber(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return null;
    return double.tryParse(normalized);
  }

  static String _emptyValueFor(String label) {
    if (label.contains('هامش الربح')) return '0.00%';
    if (label.endsWith(' - دولار')) return '0.00';
    return '0';
  }

  static String _format(double value, {int decimals = 0}) {
    final fixed = value.toStringAsFixed(decimals);
    final negative = fixed.startsWith('-');
    final unsigned = negative ? fixed.substring(1) : fixed;
    final parts = unsigned.split('.');
    final digits = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(digits[index]);
    }
    final fraction =
        decimals > 0 ? '.${parts.length > 1 ? parts[1] : ''}' : '';
    return '${negative ? '-' : ''}$grouped$fraction';
  }
}
