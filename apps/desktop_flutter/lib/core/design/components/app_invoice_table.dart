import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_table.dart';

enum AppInvoiceTableType { purchase, sale }

class AppInvoiceItemsTable extends StatelessWidget {
  const AppInvoiceItemsTable.purchase({
    required this.rows,
    super.key,
    this.tableKey,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.purchase;

  const AppInvoiceItemsTable.sale({
    required this.rows,
    super.key,
    this.tableKey,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.sale;

  final AppInvoiceTableType type;
  final List<AppTableRow> rows;
  final Key? tableKey;
  final double height;
  final bool isLoading;

  static const purchaseColumns = <AppTableColumn>[
    AppTableColumn(label: 'ت', numeric: true, flex: 0.55),
    AppTableColumn(label: 'رمز المادة', flex: 1.25),
    AppTableColumn(label: 'اسم المادة', flex: 1.9),
    AppTableColumn(label: 'المخزن', flex: 1.3),
    AppTableColumn(label: 'الكمية', numeric: true),
    AppTableColumn(label: 'الحاوية', numeric: true),
    AppTableColumn(label: 'سعر الشراء', numeric: true, flex: 1.2),
    AppTableColumn(label: 'الخصم', numeric: true),
    AppTableColumn(label: 'السعر بعد الخصم', numeric: true, flex: 1.45),
    AppTableColumn(label: 'الإجمالي', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الكلفة', numeric: true),
    AppTableColumn(label: 'إجمالي الكلفة', numeric: true, flex: 1.3),
    AppTableColumn(label: 'سعر البيع', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الإجراء', flex: 0.8),
  ];

  static const saleColumns = <AppTableColumn>[
    AppTableColumn(label: 'ت', numeric: true, flex: 0.55),
    AppTableColumn(label: 'رمز المادة', flex: 1.25),
    AppTableColumn(label: 'اسم المادة', flex: 1.9),
    AppTableColumn(label: 'المخزن', flex: 1.3),
    AppTableColumn(label: 'الكمية', numeric: true),
    AppTableColumn(label: 'سعر البيع', numeric: true, flex: 1.2),
    AppTableColumn(label: 'الخصم', numeric: true),
    AppTableColumn(label: 'السعر بعد الخصم', numeric: true, flex: 1.45),
    AppTableColumn(label: 'الإجمالي', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الإجراء', flex: 0.8),
  ];

  @override
  Widget build(BuildContext context) {
    final isPurchase = type == AppInvoiceTableType.purchase;
    final accentColor = isPurchase
        ? AppModuleColors.purchases
        : AppModuleColors.sales;
    return AppDataTable(
      key: tableKey,
      columns: isPurchase ? purchaseColumns : saleColumns,
      rows: rows,
      height: height,
      headerHeight: 48,
      rowHeight: 48,
      minimumColumnWidth: 104,
      isLoading: isLoading,
      accentColor: accentColor,
      headerBackgroundColor: accentColor,
      headerForegroundColor: AppColors.onStrong,
      cellHorizontalPadding: AppSpacing.xs,
      showColumnDividers: true,
      showShadow: false,
      borderRadius: AppRadii.md,
      alternatingRowColor: Color.alphaBlend(
        accentColor.withAlpha(7),
        AppColors.surface,
      ),
    );
  }
}

class AppInvoiceCellField extends StatelessWidget {
  const AppInvoiceCellField({
    required this.controller,
    super.key,
    this.fieldKey,
    this.numeric = false,
    this.inputFormatters,
    this.onChanged,
    this.accentColor = AppColors.primary,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final bool numeric;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        key: fieldKey,
        controller: controller,
        cursorColor: Colors.black,
        textAlign: TextAlign.center,
        textDirection:
            numeric ? TextDirection.ltr : TextDirection.rtl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: AppTypography.tableCell.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide(
              color: accentColor,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
