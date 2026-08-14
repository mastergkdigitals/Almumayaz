part of 'sales_screen.dart';

class _SalesInvoiceButtons extends StatelessWidget {
  const _SalesInvoiceButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onInstallments,
    required this.onStatement,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintWithoutPrices;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onInstallments;
  final VoidCallback? onStatement;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppHeaderIconButton(
          key: const Key('salesSearchButton'),
          tooltipKey: const Key('salesSearchTooltip'),
          icon: Icons.search_rounded,
          tooltip: 'بحث',
          onPressed: onSearch,
        ),
        AppHeaderIconButton(
          key: const Key('salesReturnsButton'),
          tooltipKey: const Key('salesReturnsTooltip'),
          icon: Icons.assignment_return_rounded,
          tooltip: 'مرتجعات البيع',
          onPressed: () => unawaited(SalesReturnScreen.open(context)),
        ),
        AppHeaderIconButton(
          key: const Key('salesPrintButton'),
          tooltipKey: const Key('salesPrintTooltip'),
          icon: Icons.print_rounded,
          tooltip: 'طباعة',
          onPressed: onPrint,
        ),
        AppHeaderIconButton(
          key: const Key('salesPrintWithoutPricesButton'),
          tooltipKey: const Key('salesPrintWithoutPricesTooltip'),
          icon: Icons.money_off_rounded,
          tooltip: 'طباعة بدون سعر',
          onPressed: onPrintWithoutPrices,
        ),
        AppHeaderIconButton(
          key: const Key('salesPdfButton'),
          tooltipKey: const Key('salesPdfTooltip'),
          icon: Icons.picture_as_pdf_rounded,
          tooltip: 'تصدير PDF',
          onPressed: onExportPdf,
        ),
        AppHeaderIconButton(
          key: const Key('salesExcelButton'),
          tooltipKey: const Key('salesExcelTooltip'),
          icon: Icons.table_view_rounded,
          tooltip: 'تصدير Excel',
          onPressed: onExportExcel,
        ),
        AppHeaderIconButton(
          key: const Key('salesInstallmentsButton'),
          tooltipKey: const Key('salesInstallmentsTooltip'),
          icon: Icons.table_chart_rounded,
          tooltip: 'جدول الأقساط',
          onPressed: onInstallments,
        ),
        AppHeaderIconButton(
          key: const Key('salesStatementButton'),
          tooltipKey: const Key('salesStatementTooltip'),
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف الحساب',
          onPressed: onStatement,
        ),
      ],
    );
  }
}

class _SalesFieldRow extends StatelessWidget {
  const _SalesFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: children[index]),
          ],
        ],
      ),
    );
  }
}

class _SalesMoneyField extends StatelessWidget {
  const _SalesMoneyField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.decimalPlaces = 4,
    this.enabled = true,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int decimalPlaces;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppMoneyField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.sales,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decimalPlaces: decimalPlaces,
      enabled: enabled,
      readOnly: !enabled,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
    );
  }
}

enum _InvoiceDiscountInputSource { amount, percentage }

typedef _SalesFormSnapshot = ({
  DateTime invoiceDateTime,
  String warehouse,
  String saleType,
  String currency,
  String exchangeRate,
  String customerName,
  String? customerId,
  String notes,
  String driverName,
  String invoiceDiscount,
  String discountPercentage,
  String received,
  String itemsSignature,
});
