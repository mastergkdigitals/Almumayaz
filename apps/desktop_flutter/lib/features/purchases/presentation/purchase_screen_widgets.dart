part of 'purchase_screen.dart';

class _PurchaseInvoiceButtons extends StatelessWidget {
  const _PurchaseInvoiceButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onStatement,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintWithoutPrices;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
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
          key: const Key('purchaseSearchButton'),
          tooltipKey: const Key('purchaseSearchTooltip'),
          icon: Icons.search_rounded,
          tooltip: 'بحث',
          onPressed: onSearch,
        ),
        AppHeaderIconButton(
          key: const Key('purchasePrintButton'),
          tooltipKey: const Key('purchasePrintTooltip'),
          icon: Icons.print_rounded,
          tooltip: 'طباعة',
          onPressed: onPrint,
        ),
        AppHeaderIconButton(
          key: const Key('purchasePrintWithoutPricesButton'),
          tooltipKey: const Key('purchasePrintWithoutPricesTooltip'),
          icon: Icons.money_off_rounded,
          tooltip: 'طباعة بدون سعر',
          onPressed: onPrintWithoutPrices,
        ),
        AppHeaderIconButton(
          key: const Key('purchasePdfButton'),
          tooltipKey: const Key('purchasePdfTooltip'),
          icon: Icons.picture_as_pdf_rounded,
          tooltip: 'تصدير PDF',
          onPressed: onExportPdf,
        ),
        AppHeaderIconButton(
          key: const Key('purchaseExcelButton'),
          tooltipKey: const Key('purchaseExcelTooltip'),
          icon: Icons.table_view_rounded,
          tooltip: 'تصدير Excel',
          onPressed: onExportExcel,
        ),
        AppHeaderIconButton(
          key: const Key('purchaseStatementButton'),
          tooltipKey: const Key('purchaseStatementTooltip'),
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف الحساب',
          onPressed: onStatement,
        ),
      ],
    );
  }
}

class _PurchaseFieldRow extends StatelessWidget {
  const _PurchaseFieldRow({
    required this.children,
    this.flexes,
  }) : assert(
          flexes == null || flexes.length == children.length,
          'Provide one flex value for each child.',
        );

  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: flexes?[index] ?? 1,
              child: children[index],
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchaseMoneyField extends StatelessWidget {
  const _PurchaseMoneyField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.decimalPlaces = 4,
    this.enabled = true,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
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
      accentColor: AppModuleColors.purchases,
      focusNode: focusNode,
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
