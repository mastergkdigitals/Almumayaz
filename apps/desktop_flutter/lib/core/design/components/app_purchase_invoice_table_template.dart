import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_autocomplete_field.dart';
import 'app_dropdown_field.dart';
import 'app_invoice_field_table.dart';
import 'app_invoice_item_option.dart';
import 'app_number_input_formatters.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

const _purchaseInvoiceWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _purchaseInvoiceTableColumns = <AppInvoiceFieldColumn>[
  AppInvoiceFieldColumn('ت', 54),
  AppInvoiceFieldColumn('رمز المادة', 126, grow: 0.75),
  AppInvoiceFieldColumn('اسم المادة', 190, grow: 3),
  AppInvoiceFieldColumn('المخزن', 138, grow: 1.35),
  AppInvoiceFieldColumn('الكمية', 104, grow: 0.70),
  AppInvoiceFieldColumn('الحاوية', 104, grow: 0.70),
  AppInvoiceFieldColumn('سعر الشراء', 126, grow: 0.90),
  AppInvoiceFieldColumn('الخصم', 104, grow: 0.70),
  AppInvoiceFieldColumn('السعر بعد الخصم', 146, grow: 1.45),
  AppInvoiceFieldColumn('الإجمالي', 116, grow: 1.10),
  AppInvoiceFieldColumn('الكلفة', 104, grow: 0.80),
  AppInvoiceFieldColumn('إجمالي الكلفة', 132, grow: 1.10),
  AppInvoiceFieldColumn('سعر البيع', 116, grow: 0.90),
  AppInvoiceFieldColumn('', 82, padding: EdgeInsets.zero),
];

class AppPurchaseInvoiceTableRowData {
  const AppPurchaseInvoiceTableRowData({
    this.lineId,
    this.itemId,
    this.code = '',
    this.name = '',
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

  bool get isEmpty =>
      lineId == null &&
      itemId == null &&
      code.trim().isEmpty &&
      name.trim().isEmpty &&
      warehouse == 'الرئيسي' &&
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
  late List<int> weights;
  if (lineBaseTotal > 0) {
    weights = lineTotals;
  } else {
    final grossTotal = grossTotals.fold<int>(
      0,
      (sum, value) => sum + (value < 0 ? 0 : value),
    );
    if (grossTotal > 0) {
      weights = [for (final value in grossTotals) value < 0 ? 0 : value];
    } else {
      final totalQuantity = rows.fold<int>(
        0,
        (sum, row) =>
            sum + (row.quantityValue < 0 ? 0 : row.quantityValue),
      );
      if (totalQuantity > 0) {
        weights = [
          for (final row in rows)
            row.quantityValue < 0 ? 0 : row.quantityValue,
        ];
      } else {
        weights = [for (final row in rows) row.isEmpty ? 0 : 1];
        if (weights.isNotEmpty &&
            weights.every((weight) => weight == 0)) {
          weights[0] = 1;
        }
      }
    }
  }

  final allocatedTotals = _allocateMinorUnits(targetTotal, weights);
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

List<int> _allocateMinorUnits(int total, List<int> weights) {
  final allocations = List<int>.filled(weights.length, 0);
  if (total <= 0 || weights.isEmpty) return allocations;

  final weightTotal = weights.fold<int>(
    0,
    (sum, weight) => sum + (weight < 0 ? 0 : weight),
  );
  if (weightTotal <= 0) return allocations;

  final remainders = List<int>.filled(weights.length, 0);
  var allocated = 0;
  for (var index = 0; index < weights.length; index++) {
    final weight = weights[index] < 0 ? 0 : weights[index];
    final weightedTotal = total * weight;
    allocations[index] = weightedTotal ~/ weightTotal;
    remainders[index] = weightedTotal % weightTotal;
    allocated += allocations[index];
  }

  final order = List<int>.generate(weights.length, (index) => index)
    ..sort((left, right) {
      final remainderOrder =
          remainders[right].compareTo(remainders[left]);
      return remainderOrder != 0 ? remainderOrder : left.compareTo(right);
    });
  // Largest-remainder distribution preserves every final minor unit. Stable
  // row order resolves ties, so recalculation never moves the residual at
  // random between otherwise equal rows.
  final residual = total - allocated;
  for (var offset = 0; offset < residual; offset++) {
    allocations[order[offset]]++;
  }
  return allocations;
}

class _PurchaseInvoiceTemplateRow {
  _PurchaseInvoiceTemplateRow({
    required this.id,
    required int index,
    required AppPurchaseInvoiceTableRowData data,
  })  : indexController = TextEditingController(text: '$index'),
        lineId = data.lineId,
        itemId = data.itemId,
        codeController = TextEditingController(text: data.code),
        nameController = TextEditingController(text: data.name),
        quantityController = TextEditingController(text: data.quantity),
        containerController = TextEditingController(text: data.container),
        purchasePriceController =
            TextEditingController(text: data.purchasePrice),
        discountController = TextEditingController(text: data.discount),
        priceAfterDiscountController =
            TextEditingController(text: data.priceAfterDiscount),
        totalController = TextEditingController(text: data.total),
        costController = TextEditingController(text: data.cost),
        totalCostController = TextEditingController(text: data.totalCost),
        salePriceController = TextEditingController(text: data.salePrice),
        warehouse = data.warehouse;

  final String id;
  final String? lineId;
  String? itemId;
  final TextEditingController indexController;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController containerController;
  final TextEditingController purchasePriceController;
  final TextEditingController discountController;
  final TextEditingController priceAfterDiscountController;
  final TextEditingController totalController;
  final TextEditingController costController;
  final TextEditingController totalCostController;
  final TextEditingController salePriceController;
  final codeFocusNode = FocusNode();
  final nameFocusNode = FocusNode();
  final quantityFocusNode = FocusNode();
  String warehouse;

  void setIndex(int value) {
    indexController.text = '$value';
  }

  void dispose() {
    indexController.dispose();
    codeController.dispose();
    nameController.dispose();
    quantityController.dispose();
    containerController.dispose();
    purchasePriceController.dispose();
    discountController.dispose();
    priceAfterDiscountController.dispose();
    totalController.dispose();
    costController.dispose();
    totalCostController.dispose();
    salePriceController.dispose();
    codeFocusNode.dispose();
    nameFocusNode.dispose();
    quantityFocusNode.dispose();
  }
}

class AppPurchaseInvoiceTableTemplate extends StatefulWidget {
  const AppPurchaseInvoiceTableTemplate({
    super.key,
    this.initialRows = const [],
    this.dataVersion,
    this.summaryQuantity = '0',
    this.summaryDiscount = '0',
    this.summaryTotal = '0',
    this.summaryTotalCost = '0',
    this.currencyCode = 'IQD',
    this.invoiceAdjustment = 0,
    this.itemOptions = const [],
    this.onRowsChanged,
  });

  final List<AppPurchaseInvoiceTableRowData> initialRows;
  final Object? dataVersion;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;
  final String summaryTotalCost;
  final String currencyCode;
  final num invoiceAdjustment;
  final List<AppInvoiceItemOption> itemOptions;
  final ValueChanged<List<AppPurchaseInvoiceTableRowData>>? onRowsChanged;

  @override
  State<AppPurchaseInvoiceTableTemplate> createState() =>
      _AppPurchaseInvoiceTableTemplateState();
}

class _AppPurchaseInvoiceTableTemplateState
    extends State<AppPurchaseInvoiceTableTemplate> {
  final _tableScrollController = ScrollController();
  late List<_PurchaseInvoiceTemplateRow> _rows;
  var _nextRowId = 1;

  @override
  void initState() {
    super.initState();
    _rows = _createRows(widget.initialRows);
  }

  @override
  void didUpdateWidget(
    covariant AppPurchaseInvoiceTableTemplate oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion == widget.dataVersion) {
      if (oldWidget.currencyCode != widget.currencyCode ||
          oldWidget.invoiceAdjustment != widget.invoiceAdjustment) {
        _recalculateRows();
      }
      return;
    }

    final oldRows = _rows;
    _rows = _createRows(widget.initialRows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in oldRows) {
        row.dispose();
      }
    });
  }

  List<_PurchaseInvoiceTemplateRow> _createRows(
    List<AppPurchaseInvoiceTableRowData> rows,
  ) {
    final sourceRows = rows.isEmpty
        ? const [AppPurchaseInvoiceTableRowData()]
        : rows;
    final calculatedRows = calculatePurchaseInvoiceRows(
      rows: sourceRows,
      currencyCode: widget.currencyCode,
      invoiceAdjustment: widget.invoiceAdjustment,
    ).rows;

    return [
      for (var index = 0; index < calculatedRows.length; index++)
        _newRow(index + 1, calculatedRows[index]),
    ];
  }

  _PurchaseInvoiceTemplateRow _newRow(
    int index, [
    AppPurchaseInvoiceTableRowData data =
        const AppPurchaseInvoiceTableRowData(),
  ]) {
    return _PurchaseInvoiceTemplateRow(
      id: 'r${_nextRowId++}',
      index: index,
      data: data,
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(_newRow(_rows.length + 1));
      _recalculateRows();
    });
    _notifyRowsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tableScrollController.hasClients) return;
      _tableScrollController.animateTo(
        _tableScrollController.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1 || index < 0 || index >= _rows.length) return;

    late final _PurchaseInvoiceTemplateRow removed;
    setState(() {
      removed = _rows.removeAt(index);
      for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
        _rows[rowIndex].setIndex(rowIndex + 1);
      }
      _recalculateRows();
    });
    _notifyRowsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _changeWarehouse(
    _PurchaseInvoiceTemplateRow row,
    String? value,
  ) {
    if (value == null) return;
    setState(() {
      row.warehouse = value;
      _recalculateRows();
    });
    _notifyRowsChanged();
  }

  void _changeCalculatedValue() {
    setState(_recalculateRows);
    _notifyRowsChanged();
  }

  void _changeRowText() {
    setState(_recalculateRows);
    _notifyRowsChanged();
  }

  void _changeItemText(_PurchaseInvoiceTemplateRow row) {
    row.itemId = null;
    _changeRowText();
  }

  void _selectItem(
    _PurchaseInvoiceTemplateRow row,
    AppInvoiceItemOption option,
  ) {
    setState(() {
      row.itemId = option.id;
      row.codeController.text = option.code;
      row.nameController.text = option.name;
      _recalculateRows();
    });
    _notifyRowsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) row.quantityFocusNode.requestFocus();
    });
  }

  bool _canAddRow(_PurchaseInvoiceTemplateRow row) {
    return AppPurchaseInvoiceTableRowData(
      code: row.codeController.text,
      name: row.nameController.text,
      quantity: row.quantityController.text,
    ).hasRequiredValues;
  }

  void _recalculateRows() {
    final calculatedRows = calculatePurchaseInvoiceRows(
      rows: [for (final row in _rows) _rowData(row)],
      currencyCode: widget.currencyCode,
      invoiceAdjustment: widget.invoiceAdjustment,
    ).rows;
    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index];
      final data = calculatedRows[index];
      row.priceAfterDiscountController.text = data.priceAfterDiscount;
      row.totalController.text = data.total;
      row.costController.text = data.cost;
      row.totalCostController.text = data.totalCost;
    }
  }

  void _notifyRowsChanged() {
    widget.onRowsChanged?.call(
      List<AppPurchaseInvoiceTableRowData>.unmodifiable(
        _rows.map(_rowData),
      ),
    );
  }

  AppPurchaseInvoiceTableRowData _rowData(
    _PurchaseInvoiceTemplateRow row,
  ) {
    return AppPurchaseInvoiceTableRowData(
      lineId: row.lineId,
      itemId: row.itemId,
      code: row.codeController.text,
      name: row.nameController.text,
      warehouse: row.warehouse,
      quantity: row.quantityController.text,
      container: row.containerController.text,
      purchasePrice: row.purchasePriceController.text,
      discount: row.discountController.text,
      priceAfterDiscount: row.priceAfterDiscountController.text,
      total: row.totalController.text,
      cost: row.costController.text,
      totalCost: row.totalCostController.text,
      salePrice: row.salePriceController.text,
    );
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppInvoiceFieldTable(
      surfaceKey: const Key('appPurchaseInvoiceTableTemplate'),
      horizontalScrollKey:
          const Key('appPurchaseInvoiceTableHorizontalScroll'),
      rowsKey: const Key('appPurchaseInvoiceTableRows'),
      headerKey: const Key('appPurchaseInvoiceTableHeader'),
      summaryKey: const Key('appPurchaseInvoiceTableSummary'),
      columns: _purchaseInvoiceTableColumns,
      rowCount: _rows.length,
      verticalScrollController: _tableScrollController,
      accentColor: AppModulePalettes.purchases.middle,
      lightAccentColor: AppModulePalettes.purchases.light,
      rowKeyBuilder: (index) =>
          Key('appPurchaseInvoiceTableRow-${_rows[index].id}'),
      rowCellsBuilder: (context, index) => _buildRowCells(
        _rows[index],
        index == _rows.length - 1,
        index,
      ),
      summaryCells: [
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const Text('المجموع'),
        const SizedBox.shrink(),
        _summaryValue(widget.summaryQuantity),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        _summaryValue(widget.summaryDiscount),
        const SizedBox.shrink(),
        _summaryValue(widget.summaryTotal),
        const SizedBox.shrink(),
        _summaryValue(widget.summaryTotalCost),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
    );
  }

  List<Widget> _buildRowCells(
    _PurchaseInvoiceTemplateRow row,
    bool isLastRow,
    int index,
  ) {
    return [
      _readOnlyField(
        keyName: 'Index',
        row: row,
        controller: row.indexController,
        label: 'ت',
      ),
      _itemField(
        keyName: 'Code',
        row: row,
        controller: row.codeController,
        label: 'رمز المادة',
        showsCode: true,
      ),
      _itemField(
        keyName: 'Name',
        row: row,
        controller: row.nameController,
        label: 'اسم المادة',
        showsCode: false,
      ),
      AppDropdownField<String>(
        fieldKey: Key(
          'appPurchaseInvoiceTemplateWarehouseDropdown-${row.id}',
        ),
        label: 'المخزن',
        icon: Icons.warehouse_rounded,
        accentColor: AppModuleColors.purchases,
        value: row.warehouse,
        options: _purchaseInvoiceWarehouseOptions,
        onChanged: (value) => _changeWarehouse(row, value),
        useIntrinsicHeight: true,
        minimumHeight: AppControlHeights.invoiceField,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      _editableField(
        keyName: 'Quantity',
        row: row,
        controller: row.quantityController,
        label: 'الكمية',
        wholeNumber: true,
        recalculates: true,
        focusNode: row.quantityFocusNode,
      ),
      _editableField(
        keyName: 'Container',
        row: row,
        controller: row.containerController,
        label: 'الحاوية',
        wholeNumber: true,
      ),
      _editableField(
        keyName: 'PurchasePrice',
        row: row,
        controller: row.purchasePriceController,
        label: 'سعر الشراء',
        numeric: true,
        recalculates: true,
      ),
      _editableField(
        keyName: 'Discount',
        row: row,
        controller: row.discountController,
        label: 'الخصم',
        numeric: true,
        recalculates: true,
      ),
      _readOnlyField(
        keyName: 'PriceAfterDiscount',
        row: row,
        controller: row.priceAfterDiscountController,
        label: 'السعر بعد الخصم',
      ),
      _readOnlyField(
        keyName: 'Total',
        row: row,
        controller: row.totalController,
        label: 'الإجمالي',
      ),
      _readOnlyField(
        keyName: 'Cost',
        row: row,
        controller: row.costController,
        label: 'الكلفة',
      ),
      _readOnlyField(
        keyName: 'TotalCost',
        row: row,
        controller: row.totalCostController,
        label: 'إجمالي الكلفة',
      ),
      _editableField(
        keyName: 'SalePrice',
        row: row,
        controller: row.salePriceController,
        label: 'سعر البيع',
        numeric: true,
      ),
      Center(
        child: AppTableActionButton(
          key: Key(
            isLastRow
                ? 'appPurchaseInvoiceTemplateAddButton'
                : 'appPurchaseInvoiceTemplateDeleteButton-${row.id}',
          ),
          tooltipKey: Key(
            isLastRow
                ? 'appPurchaseInvoiceTemplateAddButtonTooltip'
                : 'appPurchaseInvoiceTemplateDeleteButtonTooltip-${row.id}',
          ),
          icon: isLastRow ? Icons.add_rounded : Icons.close_rounded,
          tooltip: isLastRow ? 'إضافة سطر' : 'حذف السطر',
          variant: isLastRow
              ? AppButtonVariant.success
              : AppButtonVariant.danger,
          backgroundColor: isLastRow ? AppColors.green : AppColors.red,
          foregroundColor: Colors.white,
          size: 40,
          iconSize: AppIconSizes.md,
          borderRadius: AppRadii.sm,
          onPressed: isLastRow
              ? _canAddRow(row)
                  ? _addRow
                  : null
              : () => _removeRow(index),
        ),
      ),
    ];
  }

  Widget _editableField({
    required String keyName,
    required _PurchaseInvoiceTemplateRow row,
    required TextEditingController controller,
    required String label,
    bool numeric = false,
    bool wholeNumber = false,
    bool recalculates = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      fieldKey: Key(
        'appPurchaseInvoiceTemplate${keyName}Field-${row.id}',
      ),
      controller: controller,
      focusNode: focusNode,
      label: label,
      accentColor: AppModuleColors.purchases,
      textAlign: numeric || wholeNumber
          ? TextAlign.center
          : TextAlign.start,
      textDirection:
          numeric || wholeNumber ? TextDirection.ltr : TextDirection.rtl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : wholeNumber
              ? TextInputType.number
              : null,
      inputFormatters: numeric
          ? [
              AppMoneyInputFormatter(
                decimalPlaces: widget.currencyCode == 'USD' ? 2 : 0,
              ),
            ]
          : wholeNumber
              ? const [AppIntegerInputFormatter()]
              : null,
      textInputAction: TextInputAction.next,
      onChanged: (_) {
        if (recalculates) {
          _changeCalculatedValue();
        } else {
          _changeRowText();
        }
      },
      showLabel: false,
      borderRadius: AppRadii.sm,
    );
  }

  Widget _itemField({
    required String keyName,
    required _PurchaseInvoiceTemplateRow row,
    required TextEditingController controller,
    required String label,
    required bool showsCode,
  }) {
    return AppAutocompleteField<AppInvoiceItemOption>(
      fieldKey: Key(
        'appPurchaseInvoiceTemplate${keyName}Field-${row.id}',
      ),
      controller: controller,
      focusNode: showsCode ? row.codeFocusNode : row.nameFocusNode,
      label: label,
      options: widget.itemOptions,
      displayStringForOption:
          showsCode ? (option) => option.code : (option) => option.name,
      searchTermsForOption: (option) => [option.code, option.name],
      optionSubtitle:
          showsCode ? (option) => option.name : (option) => option.code,
      onSelected: (option) => _selectItem(row, option),
      onChanged: (_) => _changeItemText(row),
      icon: null,
      accentColor: AppModuleColors.purchases,
      textDirection: TextDirection.rtl,
      showLabel: false,
      borderRadius: AppRadii.sm,
    );
  }

  Widget _readOnlyField({
    required String keyName,
    required _PurchaseInvoiceTemplateRow row,
    required TextEditingController controller,
    required String label,
  }) {
    return AppReadOnlyField(
      fieldKey: Key(
        'appPurchaseInvoiceTemplate${keyName}Field-${row.id}',
      ),
      controller: controller,
      label: label,
      accentColor: AppModuleColors.purchases,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      showLabel: false,
      borderRadius: AppRadii.sm,
    );
  }

  static Widget _summaryValue(String value) {
    return Text(
      value,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }
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
