import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_dropdown_field.dart';
import 'app_invoice_field_table.dart';
import 'app_number_input_formatters.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

const _salesInvoiceWarehouseOptions = <AppDropdownOption<String>>[
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
    this.code = '',
    this.name = '',
    this.warehouse = 'الرئيسي',
    this.quantity = '0',
    this.salePrice = '0',
    this.discount = '0',
    this.priceAfterDiscount = '0',
    this.total = '0',
  });

  final String code;
  final String name;
  final String warehouse;
  final String quantity;
  final String salePrice;
  final String discount;
  final String priceAfterDiscount;
  final String total;
}

class _SalesInvoiceTemplateRow {
  _SalesInvoiceTemplateRow({
    required this.id,
    required int index,
    required AppSalesInvoiceTableRowData data,
  })  : indexController = TextEditingController(text: '$index'),
        codeController = TextEditingController(text: data.code),
        nameController = TextEditingController(text: data.name),
        quantityController = TextEditingController(text: data.quantity),
        salePriceController = TextEditingController(text: data.salePrice),
        discountController = TextEditingController(text: data.discount),
        priceAfterDiscountController =
            TextEditingController(text: data.priceAfterDiscount),
        totalController = TextEditingController(text: data.total),
        warehouse = data.warehouse;

  final String id;
  final TextEditingController indexController;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController salePriceController;
  final TextEditingController discountController;
  final TextEditingController priceAfterDiscountController;
  final TextEditingController totalController;
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
    this.onRowsChanged,
  });

  final List<AppSalesInvoiceTableRowData> initialRows;
  final Object? dataVersion;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;
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

  @override
  void initState() {
    super.initState();
    _rows = _createRows(widget.initialRows);
  }

  @override
  void didUpdateWidget(covariant AppSalesInvoiceTableTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion == widget.dataVersion) return;

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
    AppSalesInvoiceTableRowData data =
        const AppSalesInvoiceTableRowData(),
  ]) {
    return _SalesInvoiceTemplateRow(
      id: 'r${_nextRowId++}',
      index: index,
      data: data,
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
    setState(() => row.warehouse = value);
    _notifyRowsChanged();
  }

  void _notifyRowsChanged() {
    widget.onRowsChanged?.call(
      List<AppSalesInvoiceTableRowData>.unmodifiable(
        _rows.map(
          (row) => AppSalesInvoiceTableRowData(
            code: row.codeController.text,
            name: row.nameController.text,
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
      AppTextField(
        fieldKey: Key(
          'appSalesInvoiceTemplateCodeField-${row.id}',
        ),
        controller: row.codeController,
        label: 'رمز المادة',
        accentColor: AppModuleColors.sales,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyRowsChanged(),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppTextField(
        fieldKey: Key(
          'appSalesInvoiceTemplateNameField-${row.id}',
        ),
        controller: row.nameController,
        label: 'اسم المادة',
        accentColor: AppModuleColors.sales,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyRowsChanged(),
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
        value: row.warehouse,
        options: _salesInvoiceWarehouseOptions,
        onChanged: (value) => _changeWarehouse(row, value),
        useIntrinsicHeight: true,
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppTextField(
        fieldKey: Key(
          'appSalesInvoiceTemplateQuantityField-${row.id}',
        ),
        controller: row.quantityController,
        label: 'الكمية',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        inputFormatters: const [AppIntegerInputFormatter()],
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyRowsChanged(),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppTextField(
        fieldKey: Key(
          'appSalesInvoiceTemplateSalePriceField-${row.id}',
        ),
        controller: row.salePriceController,
        label: 'سعر البيع',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [AppMoneyInputFormatter()],
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyRowsChanged(),
        showLabel: false,
        borderRadius: AppRadii.sm,
      ),
      AppTextField(
        fieldKey: Key(
          'appSalesInvoiceTemplateDiscountField-${row.id}',
        ),
        controller: row.discountController,
        label: 'الخصم',
        accentColor: AppModuleColors.sales,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [AppMoneyInputFormatter()],
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyRowsChanged(),
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
          onPressed: isLastRow ? _addRow : () => _removeRow(index),
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
