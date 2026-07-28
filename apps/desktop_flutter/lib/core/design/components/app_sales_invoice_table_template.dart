import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_dropdown_field.dart';
import 'app_number_input_formatters.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

const _salesInvoiceWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
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

final _salesInvoiceTableHeaderColor = Color.lerp(
  AppModulePalettes.sales.light,
  Colors.white,
  0.82,
)!;
final _salesInvoiceTableSummaryColor = Color.lerp(
  _salesInvoiceTableHeaderColor,
  Colors.white,
  0.48,
)!;
final _salesInvoiceTableBorderColor = Color.lerp(
  AppModulePalettes.sales.middle,
  Colors.white,
  0.62,
)!;

const _salesInvoiceTableColumns = <_SalesInvoiceTableColumn>[
  _SalesInvoiceTableColumn('ت', 72),
  _SalesInvoiceTableColumn('رمز المادة', 142, grow: 0.75),
  _SalesInvoiceTableColumn('اسم المادة', 210, grow: 3),
  _SalesInvoiceTableColumn('المخزن', 168, grow: 1.35),
  _SalesInvoiceTableColumn('الكمية', 122, grow: 0.70),
  _SalesInvoiceTableColumn('سعر البيع', 142, grow: 0.90),
  _SalesInvoiceTableColumn('الخصم', 122, grow: 0.70),
  _SalesInvoiceTableColumn('السعر بعد الخصم', 172, grow: 1.45),
  _SalesInvoiceTableColumn('الإجمالي', 142, grow: 1.55),
  _SalesInvoiceTableColumn('', 82),
];

class _SalesInvoiceTemplateRow {
  _SalesInvoiceTemplateRow({
    required this.id,
    required int index,
    required AppSalesInvoiceTableRowData data,
  }) : indexController = TextEditingController(text: '$index'),
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
  });

  final List<AppSalesInvoiceTableRowData> initialRows;
  final Object? dataVersion;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _changeWarehouse(
    _SalesInvoiceTemplateRow row,
    String? value,
  ) {
    if (value == null) return;
    setState(() => row.warehouse = value);
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
    return _SalesInvoiceFieldTableTemplate(
      rows: _rows,
      verticalScrollController: _tableScrollController,
      onAddRow: _addRow,
      onDeleteRow: _removeRow,
      onWarehouseChanged: _changeWarehouse,
      summaryQuantity: widget.summaryQuantity,
      summaryDiscount: widget.summaryDiscount,
      summaryTotal: widget.summaryTotal,
    );
  }
}

class _SalesInvoiceFieldTableTemplate extends StatelessWidget {
  const _SalesInvoiceFieldTableTemplate({
    required this.rows,
    required this.verticalScrollController,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onWarehouseChanged,
    required this.summaryQuantity,
    required this.summaryDiscount,
    required this.summaryTotal,
  });

  final List<_SalesInvoiceTemplateRow> rows;
  final ScrollController verticalScrollController;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;
  final void Function(
    _SalesInvoiceTemplateRow row,
    String? value,
  ) onWarehouseChanged;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseContentWidth = _salesInvoiceTableColumns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        final minimumWidth = baseContentWidth + 12;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minimumWidth;
        final tableWidth =
            availableWidth > minimumWidth ? availableWidth : minimumWidth;
        final tableHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 308.0;
        final columns = _expandSalesInvoiceColumns(
          _salesInvoiceTableColumns,
          tableWidth - 12,
        );

        return Container(
          key: const Key('appSalesInvoiceTableTemplate'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: _salesInvoiceTableBorderColor,
              width: 1.4,
            ),
          ),
          child: SingleChildScrollView(
            key: const Key('appSalesInvoiceTableHorizontalScroll'),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: tableHeight,
              child: Column(
                children: [
                  _SalesInvoiceTableHeader(columns: columns),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Scrollbar(
                        controller: verticalScrollController,
                        child: ListView.builder(
                          key: const Key('appSalesInvoiceTableRows'),
                          controller: verticalScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          itemExtent: 80,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _SalesInvoiceTableFieldRow(
                              key: Key(
                                'appSalesInvoiceTableRow-${row.id}',
                              ),
                              columns: columns,
                              row: row,
                              isLastRow: index == rows.length - 1,
                              onAddRow: onAddRow,
                              onDeleteRow: () => onDeleteRow(index),
                              onWarehouseChanged: (value) {
                                onWarehouseChanged(row, value);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _SalesInvoiceTableSummary(
                    columns: columns,
                    quantity: summaryQuantity,
                    discount: summaryDiscount,
                    total: summaryTotal,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SalesInvoiceTableHeader extends StatelessWidget {
  const _SalesInvoiceTableHeader({required this.columns});

  final List<_SalesInvoiceTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('appSalesInvoiceTableHeader'),
      height: 46,
      decoration: BoxDecoration(
        color: _salesInvoiceTableHeaderColor,
        border: Border(
          bottom: BorderSide(color: _salesInvoiceTableBorderColor),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: 6),
            for (final column in columns)
              SizedBox(
                width: column.width,
                child: Center(
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _SalesInvoiceTableFieldRow extends StatelessWidget {
  const _SalesInvoiceTableFieldRow({
    required this.columns,
    required this.row,
    required this.isLastRow,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onWarehouseChanged,
    super.key,
  });

  final List<_SalesInvoiceTableColumn> columns;
  final _SalesInvoiceTemplateRow row;
  final bool isLastRow;
  final VoidCallback onAddRow;
  final VoidCallback onDeleteRow;
  final ValueChanged<String?> onWarehouseChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: _salesInvoiceTableBorderColor),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: 6),
            _SalesInvoiceTableCell(
              width: columns[0].width,
              child: AppReadOnlyField(
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
            ),
            _SalesInvoiceTableCell(
              width: columns[1].width,
              child: AppTextField(
                fieldKey: Key(
                  'appSalesInvoiceTemplateCodeField-${row.id}',
                ),
                controller: row.codeController,
                label: 'رمز المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[2].width,
              child: AppTextField(
                fieldKey: Key(
                  'appSalesInvoiceTemplateNameField-${row.id}',
                ),
                controller: row.nameController,
                label: 'اسم المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[3].width,
              child: AppDropdownField<String>(
                fieldKey: Key(
                  'appSalesInvoiceTemplateWarehouseDropdown-${row.id}',
                ),
                label: 'المخزن',
                icon: Icons.warehouse_rounded,
                accentColor: AppModuleColors.sales,
                value: row.warehouse,
                options: _salesInvoiceWarehouseOptions,
                onChanged: onWarehouseChanged,
                useIntrinsicHeight: true,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[4].width,
              child: AppTextField(
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
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[5].width,
              child: AppTextField(
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
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[6].width,
              child: AppTextField(
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
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SalesInvoiceTableCell(
              width: columns[7].width,
              child: AppReadOnlyField(
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
            ),
            _SalesInvoiceTableCell(
              width: columns[8].width,
              child: AppReadOnlyField(
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
            ),
            SizedBox(
              width: columns[9].width,
              child: Center(
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
                  icon: isLastRow
                      ? Icons.add_rounded
                      : Icons.close_rounded,
                  tooltip:
                      isLastRow ? 'إضافة سطر' : 'حذف السطر',
                  variant: isLastRow
                      ? AppButtonVariant.success
                      : AppButtonVariant.danger,
                  backgroundColor:
                      isLastRow ? AppColors.green : AppColors.red,
                  foregroundColor: Colors.white,
                  size: 40,
                  iconSize: AppIconSizes.md,
                  borderRadius: AppRadii.sm,
                  onPressed: isLastRow ? onAddRow : onDeleteRow,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _SalesInvoiceTableCell extends StatelessWidget {
  const _SalesInvoiceTableCell({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: child,
      ),
    );
  }
}

class _SalesInvoiceTableSummary extends StatelessWidget {
  const _SalesInvoiceTableSummary({
    required this.columns,
    required this.quantity,
    required this.discount,
    required this.total,
  });

  final List<_SalesInvoiceTableColumn> columns;
  final String quantity;
  final String discount;
  final String total;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      '',
      '',
      'المجموع',
      '',
      quantity,
      '',
      discount,
      '',
      total,
      '',
    ];

    return Container(
      key: const Key('appSalesInvoiceTableSummary'),
      height: 46,
      color: _salesInvoiceTableSummaryColor,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: 6),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Center(
                  child: Text(
                    values[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _SalesInvoiceTableColumn {
  const _SalesInvoiceTableColumn(
    this.label,
    this.width, {
    this.grow = 0,
  });

  final String label;
  final double width;
  final double grow;

  _SalesInvoiceTableColumn withWidth(double value) {
    return _SalesInvoiceTableColumn(label, value, grow: grow);
  }
}

List<_SalesInvoiceTableColumn> _expandSalesInvoiceColumns(
  List<_SalesInvoiceTableColumn> columns,
  double targetWidth,
) {
  final baseWidth = columns.fold<double>(
    0,
    (sum, column) => sum + column.width,
  );
  final extraWidth = targetWidth - baseWidth;
  final totalGrow = columns.fold<double>(
    0,
    (sum, column) => sum + column.grow,
  );

  if (extraWidth <= 0 || totalGrow <= 0) return columns;

  return [
    for (final column in columns)
      column.withWidth(
        column.width + (extraWidth * (column.grow / totalGrow)),
      ),
  ];
}
