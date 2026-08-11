part of 'app_purchase_invoice_table_template.dart';

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

List<AppDropdownOption<String>> _purchaseWarehouseDropdownOptions({
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
        warehouseId = data.warehouseId,
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
    this.warehouseOptions = _purchaseInvoiceDefaultWarehouseOptions,
    this.defaultWarehouse = 'الرئيسي',
    this.defaultWarehouseLabel = '',
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
  final List<AppDropdownOption<String>> warehouseOptions;

  /// Stable ID used as the dropdown value and persisted in emitted rows.
  final String defaultWarehouse;

  /// Display label for [defaultWarehouse].
  final String defaultWarehouseLabel;
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

  String get _defaultWarehouse {
    final configuredDefault = widget.defaultWarehouse.trim();
    if (configuredDefault.isNotEmpty) return configuredDefault;
    for (final option in widget.warehouseOptions) {
      final normalized = option.value.trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return _purchaseInvoiceDefaultWarehouseOptions.first.value;
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
        ? [
            AppPurchaseInvoiceTableRowData(
              warehouseId: _defaultWarehouse,
              warehouse: _defaultWarehouseLabel,
            ),
          ]
        : rows;
    final calculatedRows = calculatePurchaseInvoiceRows(
      rows: sourceRows,
      currencyCode: widget.currencyCode,
      invoiceAdjustment: widget.invoiceAdjustment,
      defaultWarehouse: _defaultWarehouse,
    ).rows;

    return [
      for (var index = 0; index < calculatedRows.length; index++)
        _newRow(index + 1, calculatedRows[index]),
    ];
  }

  _PurchaseInvoiceTemplateRow _newRow(
    int index, [
    AppPurchaseInvoiceTableRowData? data,
  ]) {
    final rowData = data ??
        AppPurchaseInvoiceTableRowData(
          warehouseId: _defaultWarehouse,
          warehouse: _defaultWarehouseLabel,
        );
    return _PurchaseInvoiceTemplateRow(
      id: 'r${_nextRowId++}',
      index: index,
      data: rowData,
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
    final options = _purchaseWarehouseDropdownOptions(
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
      defaultWarehouse: _defaultWarehouse,
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
      warehouseId: row.warehouseId,
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
        value: row.warehouseId ?? row.warehouse,
        options: _purchaseWarehouseDropdownOptions(
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
        recalculates: true,
      ),
      _editableField(
        keyName: 'Discount',
        row: row,
        controller: row.discountController,
        label: 'الخصم',
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
    bool wholeNumber = false,
    bool recalculates = false,
    FocusNode? focusNode,
  }) {
    final fieldKey = Key(
      'appPurchaseInvoiceTemplate${keyName}Field-${row.id}',
    );
    void handleChanged(String _) {
      if (recalculates) {
        _changeCalculatedValue();
      } else {
        _changeRowText();
      }
    }

    if (wholeNumber) {
      return AppIntegerField(
        fieldKey: fieldKey,
        controller: controller,
        focusNode: focusNode,
        label: label,
        icon: null,
        accentColor: AppModuleColors.purchases,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textInputAction: TextInputAction.next,
        onChanged: handleChanged,
        showLabel: false,
        borderRadius: AppRadii.sm,
      );
    }

    return AppMoneyField(
      fieldKey: fieldKey,
      controller: controller,
      focusNode: focusNode,
      label: label,
      icon: null,
      accentColor: AppModuleColors.purchases,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      decimalPlaces: widget.currencyCode == 'USD' ? 2 : 0,
      textInputAction: TextInputAction.next,
      onChanged: handleChanged,
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
