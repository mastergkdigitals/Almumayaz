part of 'app_purchase_invoice_table_template.dart';

const _purchaseInvoiceDefaultWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

class AppPurchaseInvoiceTableRowData {
  const AppPurchaseInvoiceTableRowData({
    this.lineId,
    this.itemId,
    this.code = '',
    this.name = '',
    this.warehouseId,
    this.warehouse = 'الرئيسي',
    this.quantity = '0',
    this.container = '0',
    this.purchasePrice = '0',
    this.discount = '0',
    this.priceAfterDiscount = '0',
    this.total = '0',
    this.cost = '0',
    this.totalCost = '0',
    this.salePrice = '0',
  });

  final String? lineId;
  final String? itemId;
  final String code;
  final String name;

  /// Stable repository identity used for validation and persistence.
  final String? warehouseId;

  /// Display-only snapshot retained for historical invoice lines.
  final String warehouse;
  final String quantity;
  final String container;
  final String purchasePrice;
  final String discount;
  final String priceAfterDiscount;
  final String total;
  final String cost;
  final String totalCost;
  final String salePrice;

  int get quantityValue => AppFormatters.parseInteger(quantity) ?? 0;

  bool get hasRequiredValues =>
      code.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      quantityValue > 0;

  bool get isEmpty => isEmptyForDefaultWarehouse(
        _purchaseInvoiceDefaultWarehouseOptions.first.value,
      );

  bool isEmptyForDefaultWarehouse(String defaultWarehouseId) =>
      lineId == null &&
      itemId == null &&
      code.trim().isEmpty &&
      name.trim().isEmpty &&
      (warehouseId?.trim().isNotEmpty ?? false
          ? warehouseId!.trim() == defaultWarehouseId.trim()
          : warehouse.trim() == defaultWarehouseId.trim()) &&
      _isZeroOrBlank(quantity) &&
      _isZeroOrBlank(container) &&
      _isZeroOrBlank(purchasePrice) &&
      _isZeroOrBlank(discount) &&
      _isZeroOrBlank(salePrice);

  bool get hasValidNumericValues =>
      _isPositiveWholeNumber(quantity) &&
      _isNonNegativeWholeNumberOrBlank(container) &&
      _isNonNegativeNumberOrBlank(purchasePrice) &&
      _isNonNegativeNumberOrBlank(discount) &&
      _isNonNegativeNumberOrBlank(salePrice);

  num get purchasePriceValue =>
      AppFormatters.parseNumber(purchasePrice) ?? 0;

  num get discountValue => AppFormatters.parseNumber(discount) ?? 0;

  num get grossTotalValue => quantityValue * purchasePriceValue;

  bool get hasValidLineDiscount {
    final parsedDiscount = AppFormatters.parseNumber(discount);
    if (discount.trim().isNotEmpty && parsedDiscount == null) return false;
    final value = parsedDiscount ?? 0;
    return value >= 0 && value <= grossTotalValue;
  }

  num get effectiveDiscountValue {
    final value = discountValue;
    if (value <= 0) return 0;
    return value > grossTotalValue ? grossTotalValue : value;
  }

  num get totalValue => grossTotalValue - effectiveDiscountValue;

  num get priceAfterDiscountValue {
    if (quantityValue <= 0) return 0;
    return totalValue / quantityValue;
  }

  AppPurchaseInvoiceTableRowData withCurrencyPrecision(
    String currencyCode,
  ) {
    final normalizedPurchasePrice = _moneyAtCurrencyPrecision(
      purchasePrice,
      currencyCode,
    );
    final normalizedGrossTotal = quantityValue *
        (AppFormatters.parseNumber(normalizedPurchasePrice) ?? 0);
    final requestedDiscount = AppFormatters.parseNumber(
          _moneyAtCurrencyPrecision(discount, currencyCode),
        ) ??
        0;
    final normalizedDiscount = requestedDiscount < 0
        ? 0
        : requestedDiscount > normalizedGrossTotal
            ? normalizedGrossTotal
            : requestedDiscount;
    return AppPurchaseInvoiceTableRowData(
      lineId: lineId,
      itemId: itemId,
      code: code,
      name: name,
      warehouseId: warehouseId,
      warehouse: warehouse,
      quantity: quantity,
      container: container,
      purchasePrice: normalizedPurchasePrice,
      discount: AppFormatters.moneyByCurrency(
        normalizedDiscount,
        currencyCode,
      ),
      priceAfterDiscount: priceAfterDiscount,
      total: total,
      cost: cost,
      totalCost: totalCost,
      salePrice: _moneyAtCurrencyPrecision(salePrice, currencyCode),
    );
  }
}

class AppPurchaseInvoiceRowsCalculation {
  const AppPurchaseInvoiceRowsCalculation({
    required this.rows,
    required this.totalCost,
  });

  final List<AppPurchaseInvoiceTableRowData> rows;
  final String totalCost;
}

AppPurchaseInvoiceRowsCalculation calculatePurchaseInvoiceRows({
  required List<AppPurchaseInvoiceTableRowData> rows,
  required String currencyCode,
  required num invoiceAdjustment,
  String defaultWarehouse = 'الرئيسي',
}) {
  final lineTotals = [
    for (final row in rows)
      _valueToMinorUnits(row.totalValue, currencyCode),
  ];
  final grossTotals = [
    for (final row in rows)
      _valueToMinorUnits(row.grossTotalValue, currencyCode),
  ];
  final lineBaseTotal = lineTotals.fold<int>(0, (sum, value) => sum + value);
  final adjustment = _valueToMinorUnits(invoiceAdjustment, currencyCode);
  final targetTotal = lineBaseTotal + adjustment < 0
      ? 0
      : lineBaseTotal + adjustment;

  // Prefer net value, then gross value, then quantity. The final equal
  // fallback keeps zero-value rows deterministic while excluding a trailing
  // empty row whenever any meaningful row exists.
  final included = [
    for (final row in rows)
      !row.isEmptyForDefaultWarehouse(defaultWarehouse),
  ];
  if (included.isNotEmpty && included.every((value) => !value)) {
    included[0] = true;
  }
  final allocatedTotals = allocateInvoiceTotalMinorUnits(
    totalMinorUnits: targetTotal,
    netLineMinorUnits: lineTotals,
    grossLineMinorUnits: grossTotals,
    quantities: [for (final row in rows) row.quantityValue],
    includedLines: included,
  );
  final calculatedRows = <AppPurchaseInvoiceTableRowData>[];
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final allocatedTotal = allocatedTotals[index];
    final allocatedMajor = _minorUnitsToMajor(
      allocatedTotal,
      currencyCode,
    );
    calculatedRows.add(
      AppPurchaseInvoiceTableRowData(
        lineId: row.lineId,
        itemId: row.itemId,
        code: row.code,
        name: row.name,
        warehouseId: row.warehouseId,
        warehouse: row.warehouse,
        quantity: row.quantity,
        container: row.container,
        purchasePrice: row.purchasePrice,
        discount: row.discount,
        priceAfterDiscount: AppFormatters.moneyByCurrency(
          row.priceAfterDiscountValue,
          currencyCode,
        ),
        total: _formatMinorUnits(lineTotals[index], currencyCode),
        cost: AppFormatters.moneyByCurrency(
          row.quantityValue <= 0
              ? 0
              : allocatedMajor / row.quantityValue,
          currencyCode,
        ),
        totalCost: _formatMinorUnits(allocatedTotal, currencyCode),
        salePrice: row.salePrice,
      ),
    );
  }

  final allocatedTotal = allocatedTotals.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  return AppPurchaseInvoiceRowsCalculation(
    rows: List.unmodifiable(calculatedRows),
    totalCost: _formatMinorUnits(allocatedTotal, currencyCode),
  );
}

bool _isZeroOrBlank(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return true;
  final parsed = AppFormatters.parseNumber(normalized);
  return parsed != null && parsed == 0;
}

bool _isPositiveWholeNumber(String value) {
  final parsed = AppFormatters.parseInteger(value);
  return parsed != null && parsed > 0;
}

bool _isNonNegativeWholeNumberOrBlank(String value) {
  if (value.trim().isEmpty) return true;
  final parsed = AppFormatters.parseInteger(value);
  return parsed != null && parsed >= 0;
}

bool _isNonNegativeNumberOrBlank(String value) {
  if (value.trim().isEmpty) return true;
  final parsed = AppFormatters.parseNumber(value);
  return parsed != null && parsed >= 0;
}

String _moneyAtCurrencyPrecision(String value, String currencyCode) {
  return AppFormatters.moneyByCurrency(
    AppFormatters.parseNumber(value) ?? 0,
    currencyCode,
  );
}

int _valueToMinorUnits(num value, String currencyCode) {
  final decimalPlaces = currencyCode.toUpperCase() == 'USD' ? 2 : 0;
  final normalized = AppFormatters.money(
    value,
    decimalPlaces: decimalPlaces,
  ).replaceAll(',', '');
  final negative = normalized.startsWith('-');
  final unsigned = negative ? normalized.substring(1) : normalized;
  final parts = unsigned.split('.');
  final whole = int.parse(parts.first);
  final scale = decimalPlaces == 0 ? 1 : 100;
  final fraction = decimalPlaces == 0
      ? 0
      : int.parse(parts.length == 1 ? '0' : parts.last.padRight(2, '0'));
  final minorUnits = whole * scale + fraction;
  return negative ? -minorUnits : minorUnits;
}

num _minorUnitsToMajor(int value, String currencyCode) {
  return currencyCode.toUpperCase() == 'USD' ? value / 100 : value;
}

String _formatMinorUnits(int value, String currencyCode) {
  final decimalPlaces = currencyCode.toUpperCase() == 'USD' ? 2 : 0;
  final scale = decimalPlaces == 0 ? 1 : 100;
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  final whole = _groupWholeDigits('${absolute ~/ scale}');
  if (decimalPlaces == 0) return '$sign$whole';
  final fraction = (absolute % scale).toString().padLeft(2, '0');
  return '$sign$whole.$fraction';
}

String _groupWholeDigits(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
