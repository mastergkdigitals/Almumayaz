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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _indexController = TextEditingController(text: '1');
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _salePriceController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _priceAfterDiscountController = TextEditingController(text: '0');
  final _totalController = TextEditingController(text: '0');
  String _warehouse = 'الرئيسي';

  @override
  void dispose() {
    _indexController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _salePriceController.dispose();
    _discountController.dispose();
    _priceAfterDiscountController.dispose();
    _totalController.dispose();
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
                  indexController: _indexController,
                  codeController: _codeController,
                  nameController: _nameController,
                  warehouse: _warehouse,
                  quantityController: _quantityController,
                  salePriceController: _salePriceController,
                  discountController: _discountController,
                  priceAfterDiscountController:
                      _priceAfterDiscountController,
                  totalController: _totalController,
                  onWarehouseChanged: (value) {
                    if (value == null) return;
                    setState(() => _warehouse = value);
                  },
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
    required this.indexController,
    required this.codeController,
    required this.nameController,
    required this.warehouse,
    required this.quantityController,
    required this.salePriceController,
    required this.discountController,
    required this.priceAfterDiscountController,
    required this.totalController,
    required this.onWarehouseChanged,
  });

  final TextEditingController indexController;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final String warehouse;
  final TextEditingController quantityController;
  final TextEditingController salePriceController;
  final TextEditingController discountController;
  final TextEditingController priceAfterDiscountController;
  final TextEditingController totalController;
  final ValueChanged<String?> onWarehouseChanged;

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
                  _SettingsTableFieldRow(
                    columns: columns,
                    indexController: indexController,
                    codeController: codeController,
                    nameController: nameController,
                    warehouse: warehouse,
                    quantityController: quantityController,
                    salePriceController: salePriceController,
                    discountController: discountController,
                    priceAfterDiscountController:
                        priceAfterDiscountController,
                    totalController: totalController,
                    onWarehouseChanged: onWarehouseChanged,
                  ),
                  const Expanded(
                    child: ColoredBox(color: AppColors.surface),
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
    required this.indexController,
    required this.codeController,
    required this.nameController,
    required this.warehouse,
    required this.quantityController,
    required this.salePriceController,
    required this.discountController,
    required this.priceAfterDiscountController,
    required this.totalController,
    required this.onWarehouseChanged,
  });

  final List<_SettingsTableColumn> columns;
  final TextEditingController indexController;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final String warehouse;
  final TextEditingController quantityController;
  final TextEditingController salePriceController;
  final TextEditingController discountController;
  final TextEditingController priceAfterDiscountController;
  final TextEditingController totalController;
  final ValueChanged<String?> onWarehouseChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settingsFieldTableRow'),
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
                fieldKey: const Key('settingsTemplateIndexField'),
                controller: indexController,
                label: 'ت',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ),
            _SettingsTableCell(
              width: columns[1].width,
              child: AppTextField(
                fieldKey: const Key('settingsTemplateCodeField'),
                controller: codeController,
                label: 'رمز المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
              ),
            ),
            _SettingsTableCell(
              width: columns[2].width,
              child: AppTextField(
                fieldKey: const Key('settingsTemplateNameField'),
                controller: nameController,
                label: 'اسم المادة',
                accentColor: AppModuleColors.sales,
                textInputAction: TextInputAction.next,
              ),
            ),
            _SettingsTableCell(
              width: columns[3].width,
              child: AppDropdownField<String>(
                fieldKey:
                    const Key('settingsTemplateWarehouseDropdown'),
                label: 'المخزن',
                icon: Icons.warehouse_rounded,
                accentColor: AppModuleColors.sales,
                value: warehouse,
                options: _settingsWarehouseOptions,
                onChanged: onWarehouseChanged,
              ),
            ),
            _SettingsTableCell(
              width: columns[4].width,
              child: AppTextField(
                fieldKey: const Key('settingsTemplateQuantityField'),
                controller: quantityController,
                label: 'الكمية',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                inputFormatters: const [AppIntegerInputFormatter()],
                textInputAction: TextInputAction.next,
              ),
            ),
            _SettingsTableCell(
              width: columns[5].width,
              child: AppTextField(
                fieldKey: const Key('settingsTemplateSalePriceField'),
                controller: salePriceController,
                label: 'سعر البيع',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [AppMoneyInputFormatter()],
                textInputAction: TextInputAction.next,
              ),
            ),
            _SettingsTableCell(
              width: columns[6].width,
              child: AppTextField(
                fieldKey: const Key('settingsTemplateDiscountField'),
                controller: discountController,
                label: 'الخصم',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [AppMoneyInputFormatter()],
                textInputAction: TextInputAction.next,
              ),
            ),
            _SettingsTableCell(
              width: columns[7].width,
              child: AppReadOnlyField(
                fieldKey:
                    const Key('settingsTemplatePriceAfterDiscountField'),
                controller: priceAfterDiscountController,
                label: 'السعر بعد الخصم',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ),
            _SettingsTableCell(
              width: columns[8].width,
              child: AppReadOnlyField(
                fieldKey: const Key('settingsTemplateTotalField'),
                controller: totalController,
                label: 'الإجمالي',
                accentColor: AppModuleColors.sales,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ),
            SizedBox(
              width: columns[9].width,
              child: Center(
                child: AppTableActionButton(
                  key: const Key('settingsTemplateAddButton'),
                  tooltipKey:
                      const Key('settingsTemplateAddButtonTooltip'),
                  icon: Icons.add_rounded,
                  tooltip: 'إضافة سطر',
                  variant: AppButtonVariant.success,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  size: 40,
                  iconSize: AppIconSizes.md,
                  borderRadius: AppRadii.md,
                  onPressed: () {},
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
