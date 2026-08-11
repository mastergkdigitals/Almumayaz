import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_autocomplete_field.dart';
import 'app_dropdown_field.dart';
import 'app_invoice_field_table.dart';
import 'app_invoice_item_option.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

const _salesInvoiceDefaultWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _salesInvoiceTableColumns = <AppInvoiceFieldColumn>[
  AppInvoiceFieldColumn('ت', 72),
  AppInvoiceFieldColumn('رمز المادة', 142, grow: 0.75),
  AppInvoiceFieldColumn('اسم المادة', 210, grow: 3),
  AppInvoiceFieldColumn('المخزن', 168, grow: 1.35),
  AppInvoiceFieldColumn('الكمية', 122, grow: 0.70),
  AppInvoiceFieldColumn('سعر البيع', 142, grow: 0.90),
  AppInvoiceFieldColumn('الخصم', 122, grow: 0.70),
  AppInvoiceFieldColumn('السعر بعد الخصم', 172, grow: 1.45),
  AppInvoiceFieldColumn('الإجمالي', 142, grow: 1.55),
  AppInvoiceFieldColumn('', 82, padding: EdgeInsets.zero),
];

class AppSalesInvoiceTableRowData {
  const AppSalesInvoiceTableRowData({
    this.lineId,
    this.itemId,
    this.code = '',
    this.name = '',
    this.warehouseId,
    this.warehouse = 'الرئيسي',
    this.quantity = '0',
    this.salePrice = '0',
    this.discount = '0',
    this.priceAfterDiscount = '0',
    this.total = '0',
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
  final String salePrice;
  final String discount;
  final String priceAfterDiscount;
  final String total;

  int get quantityValue => AppFormatters.parseInteger(quantity) ?? 0;

  bool get hasRequiredValues =>
      code.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      quantityValue > 0;

  bool get isEmpty =>
      isEmptyForDefaultWarehouse(
        _salesInvoiceDefaultWarehouseOptions.first.value,
      );

  bool isEmptyForDefaultWarehouse(String defaultWarehouseId) =>
      code.trim().isEmpty &&
      name.trim().isEmpty &&
      _isBlankOrZeroNumber(quantity) &&
      _isBlankOrZeroNumber(salePrice) &&
      _isBlankOrZeroNumber(discount) &&
      (warehouseId?.trim().isNotEmpty ?? false
          ? warehouseId!.trim() == defaultWarehouseId.trim()
          : warehouse.trim() == defaultWarehouseId.trim());

  num get salePriceValue => AppFormatters.parseNumber(salePrice) ?? 0;

  num get discountValue {
    final requestedDiscount = AppFormatters.parseNumber(discount) ?? 0;
    final maximumDiscount = salePriceValue < 0 ? 0 : salePriceValue;
    return requestedDiscount.clamp(0, maximumDiscount);
  }

  num get totalDiscountValue => discountValue * quantityValue;

  num get priceAfterDiscountValue {
    final value = salePriceValue - discountValue;
    return value < 0 ? 0 : value;
  }

  num get totalValue => priceAfterDiscountValue * quantityValue;

  AppSalesInvoiceTableRowData normalizeMonetaryValues(
    String currencyCode,
  ) {
    final normalizedSalePrice = _moneyValueForCurrency(
      salePriceValue,
      currencyCode,
    );
    final requestedDiscount = _moneyValueForCurrency(
      AppFormatters.parseNumber(discount) ?? 0,
      currencyCode,
    );
    final maximumDiscount =
        normalizedSalePrice < 0 ? 0 : normalizedSalePrice;
    final normalizedDiscount = requestedDiscount.clamp(
      0,
      maximumDiscount,
    );

    return AppSalesInvoiceTableRowData(
      lineId: lineId,
      itemId: itemId,
      code: code,
      name: name,
      warehouseId: warehouseId,
      warehouse: warehouse,
      quantity: quantity,
      salePrice: AppFormatters.moneyByCurrency(
        normalizedSalePrice,
        currencyCode,
      ),
      discount: AppFormatters.moneyByCurrency(
        normalizedDiscount,
        currencyCode,
      ),
    ).withCalculatedValues(currencyCode);
  }

  AppSalesInvoiceTableRowData withCalculatedValues(
    String currencyCode,
  ) {
    return AppSalesInvoiceTableRowData(
      lineId: lineId,
      itemId: itemId,
      code: code,
      name: name,
      warehouseId: warehouseId,
      warehouse: warehouse,
      quantity: quantity,
      salePrice: salePrice,
      discount: discount,
      priceAfterDiscount: AppFormatters.moneyByCurrency(
        priceAfterDiscountValue,
        currencyCode,
      ),
      total: AppFormatters.moneyByCurrency(totalValue, currencyCode),
    );
  }
}

num _moneyValueForCurrency(num value, String currencyCode) {
  final formatted = AppFormatters.moneyByCurrency(value, currencyCode);
  return AppFormatters.parseNumber(formatted) ?? 0;
}

List<AppDropdownOption<String>> _salesWarehouseDropdownOptions({
  required Iterable<AppDropdownOption<String>> configuredOptions,
  required String defaultWarehouseId,
  required String defaultWarehouseLabel,
  required String? currentWarehouseId,
  required String currentWarehouseLabel,
}) {
  final options = <AppDropdownOption<String>>[];
  final seen = <String>{};

  void addOption(String value, String label) {
    final normalizedValue = value.trim();
    final normalizedLabel = label.trim();
    if (normalizedValue.isEmpty || !seen.add(normalizedValue)) return;
    options.add(
      AppDropdownOption<String>(
        value: normalizedValue,
        label: normalizedLabel.isEmpty ? normalizedValue : normalizedLabel,
      ),
    );
  }

  if (currentWarehouseId != null) {
    addOption(currentWarehouseId, currentWarehouseLabel);
  }
  for (final option in configuredOptions) {
    addOption(option.value, option.label);
  }
  addOption(defaultWarehouseId, defaultWarehouseLabel);
  if (currentWarehouseId == null) {
    addOption(currentWarehouseLabel, currentWarehouseLabel);
  }

  return options;
}

bool _isBlankOrZeroNumber(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return true;
  final parsed = AppFormatters.parseNumber(normalized);
  return parsed != null && parsed == 0;
}

class _SalesInvoiceTemplateRow {
  _SalesInvoiceTemplateRow({
    required this.id,
    required int index,
    required AppSalesInvoiceTableRowData data,
  })  : indexController = TextEditingController(text: '$index'),
        lineId = data.lineId,
        itemId = data.itemId,
        codeController = TextEditingController(text: data.code),
        nameController = TextEditingController(text: data.name),
        quantityController = TextEditingController(text: data.quantity),
        salePriceController = TextEditingController(text: data.salePrice),
        discountController = TextEditingController(text: data.discount),
        priceAfterDiscountController =
            TextEditingController(text: data.priceAfterDiscount),
        totalController = TextEditingController(text: data.total),
        warehouseId = data.warehouseId,
        warehouse = data.warehouse;

  final String id;
  final String? lineId;
  String? itemId;
  final TextEditingController indexController;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController salePriceController;
  final TextEditingController discountController;
  final TextEditingController priceAfterDiscountController;
  final TextEditingController totalController;
  final codeFocusNode = FocusNode();
  final nameFocusNode = FocusNode();
  final quantityFocusNode = FocusNode();
  String? warehouseId;
  String warehouse;

  void setIndex(int value) {
    indexController.text = '$value';
  }

  void dispose() {
    indexController.dispose();
    codeController.dispose();
    nameController.dispose();
    quantityController.dispose();
    salePriceController.dispose();
    discountController.dispose();
    priceAfterDiscountController.dispose();
    totalController.dispose();
    codeFocusNode.dispose();
    nameFocusNode.dispose();
    quantityFocusNode.dispose();
  }
}

class AppSalesInvoiceTableTemplate extends StatefulWidget {
  const AppSalesInvoiceTableTemplate({
    super.key,
    this.initialRows = const [],
    this.dataVersion,
    this.summaryQuantity = '0',
    this.summaryDiscount = '0',
    this.summaryTotal = '0',
    this.currencyCode = 'IQD',
    this.itemOptions = const [],
    this.warehouseOptions = _salesInvoiceDefaultWarehouseOptions,
    this.defaultWarehouse = 'الرئيسي',
    this.defaultWarehouseLabel = '',
    this.onRowsChanged,
  });

  final List<AppSalesInvoiceTableRowData> initialRows;
  final Object? dataVersion;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;
  final String currencyCode;
  final List<AppInvoiceItemOption> itemOptions;
  final List<AppDropdownOption<String>> warehouseOptions;

  /// Stable ID used as the dropdown value and persisted in emitted rows.
  final String defaultWarehouse;

  /// Display label for [defaultWarehouse].
  final String defaultWarehouseLabel;
  final ValueChanged<List<AppSalesInvoiceTableRowData>>? onRowsChanged;

  @override
  State<AppSalesInvoiceTableTemplate> createState() =>
      _AppSalesInvoiceTableTemplateState();
}

class _AppSalesInvoiceTableTemplateState
    extends State<AppSalesInvoiceTableTemplate> {
  final _tableScrollController = ScrollController();
  late List<_SalesInvoiceTemplateRow> _rows;
  var _nextRowId = 1;

  String get _defaultWarehouse {
    final configuredDefault = widget.defaultWarehouse.trim();
    if (configuredDefault.isNotEmpty) return configuredDefault;
    for (final option in widget.warehouseOptions) {
      final normalized = option.value.trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return _salesInvoiceDefaultWarehouseOptions.first.value;
  }

  String get _defaultWarehouseLabel {
    final configuredLabel = widget.defaultWarehouseLabel.trim();
    if (configuredLabel.isNotEmpty) return configuredLabel;
    for (final option in widget.warehouseOptions) {
      if (option.value.trim() == _defaultWarehouse) return option.label;
    }
    return _defaultWarehouse;
  }

  @override
  void initState() {
    super.initState();
    _rows = _createRows(widget.initialRows);
  }

  @override
  void didUpdateWidget(covariant AppSalesInvoiceTableTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion == widget.dataVersion) {
      if (oldWidget.currencyCode != widget.currencyCode) {
        for (final row in _rows) {
          _recalculateRow(row);
        }
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

  List<_SalesInvoiceTemplateRow> _createRows(
    List<AppSalesInvoiceTableRowData> rows,
  ) {
    if (rows.isEmpty) return [_newRow(1)];

    return [
      for (var index = 0; index < rows.length; index++)
        _newRow(index + 1, rows[index]),
    ];
  }

  _SalesInvoiceTemplateRow _newRow(
    int index, [
    AppSalesInvoiceTableRowData? data,
  ]) {
    final rowData = data ??
        AppSalesInvoiceTableRowData(
          warehouseId: _defaultWarehouse,
          warehouse: _defaultWarehouseLabel,
        );
    return _SalesInvoiceTemplateRow(
      id: 'r${_nextRowId++}',
      index: index,
      data: rowData.withCalculatedValues(widget.currencyCode),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_newRow(_rows.length + 1)));
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

    late final _SalesInvoiceTemplateRow removed;
    setState(() {
      removed = _rows.removeAt(index);
      for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
        _rows[rowIndex].setIndex(rowIndex + 1);
      }
    });
    _notifyRowsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _changeWarehouse(
    _SalesInvoiceTemplateRow row,
    String? value,
  ) {
    if (value == null) return;
    final options = _salesWarehouseDropdownOptions(
      configuredOptions: widget.warehouseOptions,
      defaultWarehouseId: _defaultWarehouse,
      defaultWarehouseLabel: _defaultWarehouseLabel,
      currentWarehouseId: row.warehouseId,
      currentWarehouseLabel: row.warehouse,
    );
    final selected = options.firstWhere((option) => option.value == value);
    setState(() {
      row.warehouseId = selected.value;
      row.warehouse = selected.label;
    });
    _notifyRowsChanged();
  }

  void _changeCalculatedValue(_SalesInvoiceTemplateRow row) {
    setState(() => _recalculateRow(row));
    _notifyRowsChanged();
  }

  void _changeRowText() {
    setState(() {});
    _notifyRowsChanged();
  }

  void _changeItemText(_SalesInvoiceTemplateRow row) {
    row.itemId = null;
    _changeRowText();
  }

  void _selectItem(
    _SalesInvoiceTemplateRow row,
    AppInvoiceItemOption option,
  ) {
    setState(() {
      row.itemId = option.id;
      row.codeController.text = option.code;
      row.nameController.text = option.name;
    });
    _notifyRowsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) row.quantityFocusNode.requestFocus();
    });
  }

  bool _canAddRow(_SalesInvoiceTemplateRow row) {
    return AppSalesInvoiceTableRowData(
      code: row.codeController.text,
      name: row.nameController.text,
      quantity: row.quantityController.text,
    ).hasRequiredValues;
  }

  void _recalculateRow(_SalesInvoiceTemplateRow row) {
    final requestedDiscount =
        AppFormatters.parseNumber(row.discountController.text) ?? 0;
    final data = AppSalesInvoiceTableRowData(
      code: row.codeController.text,
      name: row.nameController.text,
      quantity: row.quantityController.text,
      salePrice: row.salePriceController.text,
      discount: row.discountController.text,
    ).withCalculatedValues(widget.currencyCode);
    final hasPricingContext =
        data.quantityValue > 0 || data.salePriceValue > 0;
    if (hasPricingContext && requestedDiscount != data.discountValue) {
      row.discountController.text = AppFormatters.moneyByCurrency(
        data.discountValue,
        widget.currencyCode,
      );
    }
    row.priceAfterDiscountController.text = data.priceAfterDiscount;
    row.totalController.text = data.total;
  }

  void _notifyRowsChanged() {
    widget.onRowsChanged?.call(
      List<AppSalesInvoiceTableRowData>.unmodifiable(
        _rows.map(
          (row) => AppSalesInvoiceTableRowData(
            lineId: row.lineId,
            itemId: row.itemId,
            code: row.codeController.text,
            name: row.nameController.text,
            warehouseId: row.warehouseId,
            warehouse: row.warehouse,
            quantity: row.quantityController.text,
            salePrice: row.salePriceController.text,
            discount: row.discountController.text,
            priceAfterDiscount: row.priceAfterDiscountController.text,
            total: row.totalController.text,
          ),
        ),
      ),
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
      surfaceKey: const Key('appSalesInvoiceTableTemplate'),
      horizontalScrollKey:
          const Key('appSalesInvoiceTableHorizontalScroll'),
      rowsKey: const Key('appSalesInvoiceTableRows'),
      headerKey: const Key('appSalesInvoiceTableHeader'),
      summaryKey: const Key('appSalesInvoiceTableSummary'),
      columns: _salesInvoiceTableColumns,
      rowCount: _rows.length,
      verticalScrollController: _tableScrollController,
      accentColor: AppModulePalettes.sales.middle,
      lightAccentColor: AppModulePalettes.sales.light,
      rowKeyBuilder: (index) =>
          Key('appSalesInvoiceTableRow-${_rows[index].id}'),
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
        _summaryValue(widget.summaryDiscount),
        const SizedBox.shrink(),
        _summaryValue(widget.summaryTotal),
        const SizedBox.shrink(),
      ],
    );
  }

  List<Widget> _buildRowCells(
    _SalesInvoiceTemplateRow row,
    bool isLastRow,
    int index,
  ) {
    return [
      AppReadOnlyField(
        fieldKey: Key(
          'appSalesInvoiceTemplateIndexField-${row.id}',
        ),
        controller: row.indexController,
        label: 'ت',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppAutocompleteField<AppInvoiceItemOption>(
        fieldKey: Key(
          'appSalesInvoiceTemplateCodeField-${row.id}',
        ),
        controller: row.codeController,
        label: 'رمز المادة',
        options: widget.itemOptions,
        displayStringForOption: (option) => option.code,
        searchTermsForOption: (option) => [option.code, option.name],
        optionSubtitle: (option) => option.name,
        onSelected: (option) => _selectItem(row, option),
        accentColor: AppModuleColors.sales,
        focusNode: row.codeFocusNode,
        icon: null,
        textDirection: TextDirection.rtl,
        onChanged: (_) => _changeItemText(row),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppAutocompleteField<AppInvoiceItemOption>(
        fieldKey: Key(
          'appSalesInvoiceTemplateNameField-${row.id}',
        ),
        controller: row.nameController,
        label: 'اسم المادة',
        options: widget.itemOptions,
        displayStringForOption: (option) => option.name,
        searchTermsForOption: (option) => [option.code, option.name],
        optionSubtitle: (option) => option.code,
        onSelected: (option) => _selectItem(row, option),
        accentColor: AppModuleColors.sales,
        focusNode: row.nameFocusNode,
        icon: null,
        textDirection: TextDirection.rtl,
        onChanged: (_) => _changeItemText(row),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppDropdownField<String>(
        fieldKey: Key(
          'appSalesInvoiceTemplateWarehouseDropdown-${row.id}',
        ),
        label: 'المخزن',
        icon: Icons.warehouse_rounded,
        accentColor: AppModuleColors.sales,
        value: row.warehouseId ?? row.warehouse,
        options: _salesWarehouseDropdownOptions(
          configuredOptions: widget.warehouseOptions,
          defaultWarehouseId: _defaultWarehouse,
          defaultWarehouseLabel: _defaultWarehouseLabel,
          currentWarehouseId: row.warehouseId,
          currentWarehouseLabel: row.warehouse,
        ),
        onChanged: (value) => _changeWarehouse(row, value),
        useIntrinsicHeight: true,
        minimumHeight: AppControlHeights.invoiceField,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppIntegerField(
        fieldKey: Key(
          'appSalesInvoiceTemplateQuantityField-${row.id}',
        ),
        controller: row.quantityController,
        focusNode: row.quantityFocusNode,
        label: 'الكمية',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _changeCalculatedValue(row),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppMoneyField(
        fieldKey: Key(
          'appSalesInvoiceTemplateSalePriceField-${row.id}',
        ),
        controller: row.salePriceController,
        label: 'سعر البيع',
        icon: null,
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        decimalPlaces: widget.currencyCode == 'USD' ? 2 : 0,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _changeCalculatedValue(row),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppMoneyField(
        fieldKey: Key(
          'appSalesInvoiceTemplateDiscountField-${row.id}',
        ),
        controller: row.discountController,
        label: 'الخصم',
        icon: null,
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        decimalPlaces: widget.currencyCode == 'USD' ? 2 : 0,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _changeCalculatedValue(row),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppReadOnlyField(
        fieldKey: Key(
          'appSalesInvoiceTemplatePriceAfterDiscountField-${row.id}',
        ),
        controller: row.priceAfterDiscountController,
        label: 'السعر بعد الخصم',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppReadOnlyField(
        fieldKey: Key(
          'appSalesInvoiceTemplateTotalField-${row.id}',
        ),
        controller: row.totalController,
        label: 'الإجمالي',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      Center(
        child: AppTableActionButton(
          key: Key(
            isLastRow
                ? 'appSalesInvoiceTemplateAddButton'
                : 'appSalesInvoiceTemplateDeleteButton-${row.id}',
          ),
          tooltipKey: Key(
            isLastRow
                ? 'appSalesInvoiceTemplateAddButtonTooltip'
                : 'appSalesInvoiceTemplateDeleteButtonTooltip-${row.id}',
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

  static Widget _summaryValue(String value) {
    return Text(
      value,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }
}
