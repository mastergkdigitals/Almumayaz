import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_dropdown_field.dart';
import 'app_invoice_field_table.dart';
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
      code.trim().isEmpty &&
      name.trim().isEmpty &&
      quantityValue == 0;

  num get purchasePriceValue =>
      AppFormatters.parseNumber(purchasePrice) ?? 0;

  num get discountValue => AppFormatters.parseNumber(discount) ?? 0;

  num get grossTotalValue => quantityValue * purchasePriceValue;

  num get totalValue => grossTotalValue - discountValue;

  num get priceAfterDiscountValue {
    if (quantityValue <= 0) return 0;
    return totalValue / quantityValue;
  }

  num totalCostValue({
    required num lineBaseTotal,
    required num invoiceAdjustment,
  }) {
    if (lineBaseTotal <= 0) return totalValue;
    return totalValue +
        invoiceAdjustment * (totalValue / lineBaseTotal);
  }

  num costValue({
    required num lineBaseTotal,
    required num invoiceAdjustment,
  }) {
    if (quantityValue <= 0) return 0;
    return totalCostValue(
          lineBaseTotal: lineBaseTotal,
          invoiceAdjustment: invoiceAdjustment,
        ) /
        quantityValue;
  }

  AppPurchaseInvoiceTableRowData withCalculatedValues(
    String currencyCode, {
    required num lineBaseTotal,
    required num invoiceAdjustment,
  }) {
    final calculatedTotalCost = totalCostValue(
      lineBaseTotal: lineBaseTotal,
      invoiceAdjustment: invoiceAdjustment,
    );
    return AppPurchaseInvoiceTableRowData(
      code: code,
      name: name,
      warehouse: warehouse,
      quantity: quantity,
      container: container,
      purchasePrice: purchasePrice,
      discount: discount,
      priceAfterDiscount: AppFormatters.moneyByCurrency(
        priceAfterDiscountValue,
        currencyCode,
      ),
      total: AppFormatters.moneyByCurrency(totalValue, currencyCode),
      cost: AppFormatters.moneyByCurrency(
        costValue(
          lineBaseTotal: lineBaseTotal,
          invoiceAdjustment: invoiceAdjustment,
        ),
        currencyCode,
      ),
      totalCost: AppFormatters.moneyByCurrency(
        calculatedTotalCost,
        currencyCode,
      ),
      salePrice: salePrice,
    );
  }
}

class _PurchaseInvoiceTemplateRow {
  _PurchaseInvoiceTemplateRow({
    required this.id,
    required int index,
    required AppPurchaseInvoiceTableRowData data,
  })  : indexController = TextEditingController(text: '$index'),
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
    this.lineBaseTotal = 0,
    this.invoiceAdjustment = 0,
    this.onRowsChanged,
  });

  final List<AppPurchaseInvoiceTableRowData> initialRows;
  final Object? dataVersion;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;
  final String summaryTotalCost;
  final String currencyCode;
  final num lineBaseTotal;
  final num invoiceAdjustment;
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
          oldWidget.lineBaseTotal != widget.lineBaseTotal ||
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
    if (rows.isEmpty) return [_newRow(1)];

    return [
      for (var index = 0; index < rows.length; index++)
        _newRow(index + 1, rows[index]),
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
      data: data.withCalculatedValues(
        widget.currencyCode,
        lineBaseTotal: widget.lineBaseTotal,
        invoiceAdjustment: widget.invoiceAdjustment,
      ),
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

    late final _PurchaseInvoiceTemplateRow removed;
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
    _PurchaseInvoiceTemplateRow row,
    String? value,
  ) {
    if (value == null) return;
    setState(() => row.warehouse = value);
    _notifyRowsChanged();
  }

  void _changeCalculatedValue() {
    setState(_recalculateRows);
    _notifyRowsChanged();
  }

  void _changeRowText() {
    setState(() {});
    _notifyRowsChanged();
  }

  bool _canAddRow(_PurchaseInvoiceTemplateRow row) {
    return AppPurchaseInvoiceTableRowData(
      code: row.codeController.text,
      name: row.nameController.text,
      quantity: row.quantityController.text,
    ).hasRequiredValues;
  }

  void _recalculateRows() {
    for (final row in _rows) {
      final data = AppPurchaseInvoiceTableRowData(
        quantity: row.quantityController.text,
        purchasePrice: row.purchasePriceController.text,
        discount: row.discountController.text,
      ).withCalculatedValues(
        widget.currencyCode,
        lineBaseTotal: widget.lineBaseTotal,
        invoiceAdjustment: widget.invoiceAdjustment,
      );
      row.priceAfterDiscountController.text = data.priceAfterDiscount;
      row.totalController.text = data.total;
      row.costController.text = data.cost;
      row.totalCostController.text = data.totalCost;
    }
  }

  void _notifyRowsChanged() {
    widget.onRowsChanged?.call(
      List<AppPurchaseInvoiceTableRowData>.unmodifiable(
        _rows.map(
          (row) => AppPurchaseInvoiceTableRowData(
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
      _editableField(
        keyName: 'Code',
        row: row,
        controller: row.codeController,
        label: 'رمز المادة',
      ),
      _editableField(
        keyName: 'Name',
        row: row,
        controller: row.nameController,
        label: 'اسم المادة',
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
  }) {
    return AppTextField(
      fieldKey: Key(
        'appPurchaseInvoiceTemplate${keyName}Field-${row.id}',
      ),
      controller: controller,
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
