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

const _purchaseReturnColumns = <AppInvoiceFieldColumn>[
  AppInvoiceFieldColumn('رمز المادة', 120, grow: 0.8),
  AppInvoiceFieldColumn('اسم المادة', 190, grow: 2),
  AppInvoiceFieldColumn('المشتراة', 88),
  AppInvoiceFieldColumn('مرتجع سابق', 100),
  AppInvoiceFieldColumn('المتاح', 88),
  AppInvoiceFieldColumn('مخزن الإرجاع', 145, grow: 1.1),
  AppInvoiceFieldColumn('كمية المرتجع', 115),
  AppInvoiceFieldColumn('سعر المصدر', 115),
  AppInvoiceFieldColumn('خصم السطر', 105),
  AppInvoiceFieldColumn('قيمة المرتجع', 125),
];

class _PurchaseReturnLineEditor {
  _PurchaseReturnLineEditor(this.draft)
      : quantityController = TextEditingController(text: draft.quantityText);

  _PurchaseReturnLineDraft draft;
  final TextEditingController quantityController;

  void dispose() => quantityController.dispose();
}

class _PurchaseReturnLinesTable extends StatefulWidget {
  const _PurchaseReturnLinesTable({
    required this.lines,
    required this.dataVersion,
    required this.warehouseOptions,
    required this.currencyCode,
    required this.onChanged,
    super.key,
  });

  final List<_PurchaseReturnLineDraft> lines;
  final Object? dataVersion;
  final List<AppDropdownOption<String>> warehouseOptions;
  final String currencyCode;
  final ValueChanged<List<_PurchaseReturnLineDraft>> onChanged;

  @override
  State<_PurchaseReturnLinesTable> createState() =>
      _PurchaseReturnLinesTableState();
}

class _PurchaseReturnLinesTableState
    extends State<_PurchaseReturnLinesTable> {
  final _scrollController = ScrollController();
  late List<_PurchaseReturnLineEditor> _editors;

  @override
  void initState() {
    super.initState();
    _editors = _createEditors();
  }

  @override
  void didUpdateWidget(covariant _PurchaseReturnLinesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion == widget.dataVersion) return;
    for (final editor in _editors) {
      editor.dispose();
    }
    _editors = _createEditors();
  }

  List<_PurchaseReturnLineEditor> _createEditors() => [
        for (final line in widget.lines) _PurchaseReturnLineEditor(line),
      ];

  void _notifyChanged() {
    widget.onChanged(
      List<_PurchaseReturnLineDraft>.unmodifiable(
        _editors.map((editor) => editor.draft),
      ),
    );
  }

  void _changeQuantity(_PurchaseReturnLineEditor editor, String value) {
    editor.draft = editor.draft.copyWith(quantityText: value);
    _notifyChanged();
    setState(() {});
  }

  void _changeWarehouse(
    _PurchaseReturnLineEditor editor,
    String? warehouseId,
  ) {
    if (warehouseId == null) return;
    final selected = widget.warehouseOptions.firstWhere(
      (option) => option.value == warehouseId,
    );
    editor.draft = editor.draft.copyWith(
      warehouseId: selected.value,
      warehouseName: selected.label,
    );
    _notifyChanged();
    setState(() {});
  }

  String _money(Money value) => AppFormatters.moneyByCurrency(
        value.majorUnits,
        widget.currencyCode,
      );

  @override
  void dispose() {
    _scrollController.dispose();
    for (final editor in _editors) {
      editor.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _editors
        .map((editor) => editor.draft)
        .where((draft) => draft.effectiveQuantity > 0)
        .toList(growable: false);
    final quantity = selected.fold<int>(
      0,
      (total, draft) => total + draft.effectiveQuantity,
    );
    final total = selected.fold<Money>(
      Money.zero(AppCurrency.parse(widget.currencyCode)),
      (sum, draft) => sum + draft.netTotal,
    );
    return AppInvoiceFieldTable(
      surfaceKey: const Key('purchaseReturnLinesTableSurface'),
      horizontalScrollKey:
          const Key('purchaseReturnLinesHorizontalScroll'),
      rowsKey: const Key('purchaseReturnLinesRows'),
      headerKey: const Key('purchaseReturnLinesHeader'),
      summaryKey: const Key('purchaseReturnLinesSummary'),
      columns: _purchaseReturnColumns,
      rowCount: _editors.length,
      verticalScrollController: _scrollController,
      accentColor: AppModulePalettes.purchases.middle,
      lightAccentColor: AppModulePalettes.purchases.light,
      rowKeyBuilder: (index) => Key(
        'purchaseReturnLine-${_editors[index].draft.sourceLine.id.value}',
      ),
      rowCellsBuilder: (context, index) {
        final editor = _editors[index];
        final line = editor.draft;
        final suffix = line.sourceLine.id.value;
        return [
          _returnCell(line.itemCode),
          _returnCell(line.itemName),
          _returnCell('${line.sourceLine.quantity.value}'),
          _returnCell('${line.previouslyReturnedQuantity}'),
          _returnCell('${line.maximumQuantity}'),
          AppDropdownField<String>(
            fieldKey: Key('purchaseReturnWarehouse-$suffix'),
            label: 'مخزن الإرجاع',
            icon: Icons.warehouse_rounded,
            accentColor: AppModuleColors.purchases,
            value: line.warehouseId,
            options: widget.warehouseOptions,
            onChanged: (value) => _changeWarehouse(editor, value),
            showLabel: false,
            useIntrinsicHeight: true,
            minimumHeight: AppControlHeights.invoiceField,
            borderRadius: AppRadii.sm,
          ),
          AppIntegerField(
            fieldKey: Key('purchaseReturnQuantity-$suffix'),
            controller: editor.quantityController,
            label: 'كمية المرتجع',
            icon: null,
            accentColor: AppModuleColors.purchases,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            showLabel: false,
            borderRadius: AppRadii.sm,
            onChanged: (value) => _changeQuantity(editor, value),
          ),
          _returnCell(_money(line.sourceLine.purchasePrice)),
          _returnCell(_money(line.lineDiscount)),
          _returnCell(_money(line.netTotal)),
        ];
      },
      summaryCells: [
        const SizedBox.shrink(),
        const Text('المجموع'),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        _returnCell('$quantity'),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        _returnCell(_money(total)),
      ],
    );
  }

  static Widget _returnCell(String value) => Center(
        child: Text(
          value,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      );
}
