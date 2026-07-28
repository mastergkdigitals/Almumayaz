import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _settingsWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

final _settingsTableHeaderColor = Color.lerp(
  AppModulePalettes.sales.light,
  Colors.white,
  0.82,
)!;
final _settingsTableSummaryColor = Color.lerp(
  _settingsTableHeaderColor,
  Colors.white,
  0.48,
)!;
final _settingsTableBorderColor = Color.lerp(
  AppModulePalettes.sales.middle,
  Colors.white,
  0.62,
)!;

const _settingsTableColumns = <_SettingsTableColumn>[
  _SettingsTableColumn('ت', 72),
  _SettingsTableColumn('رمز المادة', 142, grow: 0.75),
  _SettingsTableColumn('اسم المادة', 210, grow: 3),
  _SettingsTableColumn('المخزن', 168, grow: 1.35),
  _SettingsTableColumn('الكمية', 122, grow: 0.70),
  _SettingsTableColumn('سعر البيع', 142, grow: 0.90),
  _SettingsTableColumn('الخصم', 122, grow: 0.70),
  _SettingsTableColumn('السعر بعد الخصم', 172, grow: 1.45),
  _SettingsTableColumn('الإجمالي', 142, grow: 1.55),
  _SettingsTableColumn('', 82),
];

class _SettingsTemplateRow {
  _SettingsTemplateRow({
    required this.id,
    required int index,
  }) : indexController = TextEditingController(text: '$index');

  final String id;
  final TextEditingController indexController;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '0');
  final TextEditingController salePriceController =
      TextEditingController(text: '0');
  final TextEditingController discountController =
      TextEditingController(text: '0');
  final TextEditingController priceAfterDiscountController =
      TextEditingController(text: '0');
  final TextEditingController totalController =
      TextEditingController(text: '0');
  String warehouse = 'الرئيسي';

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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tableScrollController = ScrollController();
  late final List<_SettingsTemplateRow> _rows;
  var _nextRowId = 1;

  @override
  void initState() {
    super.initState();
    _rows = [_newRow(1)];
  }

  _SettingsTemplateRow _newRow(int index) {
    return _SettingsTemplateRow(
      id: 'r${_nextRowId++}',
      index: index,
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

    late final _SettingsTemplateRow removed;
    setState(() {
      removed = _rows.removeAt(index);
      for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
        _rows[rowIndex].setIndex(rowIndex + 1);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _changeWarehouse(
    _SettingsTemplateRow row,
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
    final tint = Color.alphaBlend(
      AppModuleColors.settings.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('settingsScreen'),
      title: 'الإعدادات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        key: const Key('settingsTintBackground'),
        color: tint,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قالب جدول الحقول',
                key: Key('settingsFieldTableTitle'),
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _SettingsFieldTableTemplate(
                  rows: _rows,
                  verticalScrollController: _tableScrollController,
                  onAddRow: _addRow,
                  onDeleteRow: _removeRow,
                  onWarehouseChanged: _changeWarehouse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsFieldTableTemplate extends StatelessWidget {
  const _SettingsFieldTableTemplate({
    required this.rows,
    required this.verticalScrollController,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onWarehouseChanged,
  });

  final List<_SettingsTemplateRow> rows;
  final ScrollController verticalScrollController;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;
  final void Function(
    _SettingsTemplateRow row,
    String? value,
  ) onWarehouseChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseContentWidth = _settingsTableColumns.fold<double>(
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
        final columns = _expandSettingsColumns(
          _settingsTableColumns,
          tableWidth - 12,
        );

        return Container(
          key: const Key('settingsFieldTableTemplate'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: _settingsTableBorderColor,
              width: 1.4,
            ),
          ),
          child: SingleChildScrollView(
            key: const Key('settingsTableHorizontalScroll'),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: tableHeight,
              child: Column(
                children: [
                  _SettingsTableHeader(columns: columns),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Scrollbar(
                        controller: verticalScrollController,
                        child: ListView.builder(
                          key: const Key('settingsFieldTableRows'),
                          controller: verticalScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          itemExtent: 80,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _SettingsTableFieldRow(
                              key: Key(
                                'settingsFieldTableRow-${row.id}',
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
                  _SettingsTableSummary(columns: columns),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTableHeader extends StatelessWidget {
  const _SettingsTableHeader({required this.columns});

  final List<_SettingsTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settingsFieldTableHeader'),
      height: 46,
      decoration: BoxDecoration(
        color: _settingsTableHeaderColor,
        border: Border(
          bottom: BorderSide(color: _settingsTableBorderColor),
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

class _SettingsTableFieldRow extends StatelessWidget {
  const _SettingsTableFieldRow({
    required this.columns,
    required this.row,
    required this.isLastRow,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onWarehouseChanged,
    super.key,
  });

  final List<_SettingsTableColumn> columns;
  final _SettingsTemplateRow row;
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
          bottom: BorderSide(color: _settingsTableBorderColor),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: 6),
            _SettingsTableCell(
              width: columns[0].width,
              child: AppReadOnlyField(
                fieldKey: Key(
                  'settingsTemplateIndexField-${row.id}',
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
            _SettingsTableCell(
              width: columns[1].width,
              child: AppTextField(
                fieldKey: Key(
                  'settingsTemplateCodeField-${row.id}',
                ),
                controller: row.codeController,
                label: 'رمز المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SettingsTableCell(
              width: columns[2].width,
              child: AppTextField(
                fieldKey: Key(
                  'settingsTemplateNameField-${row.id}',
                ),
                controller: row.nameController,
                label: 'اسم المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SettingsTableCell(
              width: columns[3].width,
              child: AppDropdownField<String>(
                fieldKey: Key(
                  'settingsTemplateWarehouseDropdown-${row.id}',
                ),
                label: 'المخزن',
                icon: Icons.warehouse_rounded,
                accentColor: AppModuleColors.sales,
                value: row.warehouse,
                options: _settingsWarehouseOptions,
                onChanged: onWarehouseChanged,
                useIntrinsicHeight: true,
                showLabel: false,
                borderRadius: AppRadii.sm,
              ),
            ),
            _SettingsTableCell(
              width: columns[4].width,
              child: AppTextField(
                fieldKey: Key(
                  'settingsTemplateQuantityField-${row.id}',
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
            _SettingsTableCell(
              width: columns[5].width,
              child: AppTextField(
                fieldKey: Key(
                  'settingsTemplateSalePriceField-${row.id}',
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
            _SettingsTableCell(
              width: columns[6].width,
              child: AppTextField(
                fieldKey: Key(
                  'settingsTemplateDiscountField-${row.id}',
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
            _SettingsTableCell(
              width: columns[7].width,
              child: AppReadOnlyField(
                fieldKey: Key(
                  'settingsTemplatePriceAfterDiscountField-${row.id}',
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
            _SettingsTableCell(
              width: columns[8].width,
              child: AppReadOnlyField(
                fieldKey: Key(
                  'settingsTemplateTotalField-${row.id}',
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
                        ? 'settingsTemplateAddButton'
                        : 'settingsTemplateDeleteButton-${row.id}',
                  ),
                  tooltipKey: Key(
                    isLastRow
                        ? 'settingsTemplateAddButtonTooltip'
                        : 'settingsTemplateDeleteButtonTooltip-${row.id}',
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

class _SettingsTableCell extends StatelessWidget {
  const _SettingsTableCell({
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

class _SettingsTableSummary extends StatelessWidget {
  const _SettingsTableSummary({required this.columns});

  final List<_SettingsTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      '',
      '',
      'المجموع',
      '',
      '0',
      '',
      '0',
      '',
      '0',
      '',
    ];

    return Container(
      key: const Key('settingsFieldTableSummary'),
      height: 46,
      color: _settingsTableSummaryColor,
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

class _SettingsTableColumn {
  const _SettingsTableColumn(
    this.label,
    this.width, {
    this.grow = 0,
  });

  final String label;
  final double width;
  final double grow;

  _SettingsTableColumn withWidth(double value) {
    return _SettingsTableColumn(label, value, grow: grow);
  }
}

List<_SettingsTableColumn> _expandSettingsColumns(
  List<_SettingsTableColumn> columns,
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
