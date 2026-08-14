import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../../../core/domain/business_values.dart';
import '../../domain/sales_return_repository.dart';

class SalesReturnLineEditor {
  SalesReturnLineEditor({
    required this.returnable,
    int initialQuantity = 0,
  }) : quantityController = TextEditingController(
          text: initialQuantity == 0 ? '' : '$initialQuantity',
        );

  final SalesReturnableLine returnable;
  final TextEditingController quantityController;

  int get requestedQuantity {
    try {
      return WholeQuantity.parse(quantityController.text).value;
    } on FormatException {
      return 0;
    }
  }

  Money get previewRefund {
    final currency = returnable.availableRefund.currency;
    final available = returnable.available.value;
    final requested = requestedQuantity;
    if (available == 0 || requested == 0 || requested > available) {
      return Money.zero(currency);
    }
    return returnable.allocatedRefundFor(WholeQuantity(requested));
  }

  void dispose() => quantityController.dispose();
}

class SalesReturnLinesTable extends StatefulWidget {
  const SalesReturnLinesTable({
    required this.lines,
    required this.currencyCode,
    required this.enabled,
    required this.onQuantityChanged,
    super.key,
  });

  final List<SalesReturnLineEditor> lines;
  final String currencyCode;
  final bool enabled;
  final VoidCallback onQuantityChanged;

  @override
  State<SalesReturnLinesTable> createState() =>
      _SalesReturnLinesTableState();
}

class _SalesReturnLinesTableState extends State<SalesReturnLinesTable> {
  final _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = widget.lines.fold<int>(
      0,
      (sum, line) => sum + line.requestedQuantity,
    );
    final currency = AppCurrency.parse(widget.currencyCode);
    final totalRefund = widget.lines.fold<Money>(
      Money.zero(currency),
      (sum, line) => sum + line.previewRefund,
    );
    return AppInvoiceFieldTable(
      key: const Key('salesReturnLinesTable'),
      surfaceKey: const Key('salesReturnLinesTableSurface'),
      rowsKey: const Key('salesReturnLinesTableRows'),
      headerKey: const Key('salesReturnLinesTableHeader'),
      summaryKey: const Key('salesReturnLinesTableSummary'),
      accentColor: AppModuleColors.sales,
      lightAccentColor: AppModulePalettes.sales.gradient.last,
      verticalScrollController: _verticalScrollController,
      rowHeight: 66,
      columns: const [
        AppInvoiceFieldColumn('ت', 52),
        AppInvoiceFieldColumn('رمز المادة', 110),
        AppInvoiceFieldColumn('اسم المادة', 170, grow: 1),
        AppInvoiceFieldColumn('المخزن', 130),
        AppInvoiceFieldColumn('المباع', 86),
        AppInvoiceFieldColumn('المرتجع سابقاً', 116),
        AppInvoiceFieldColumn('المتاح', 86),
        AppInvoiceFieldColumn('كمية المرتجع', 132),
        AppInvoiceFieldColumn('صافي سعر البيع', 130),
        AppInvoiceFieldColumn('قيمة المرتجع', 132),
      ],
      rowCount: widget.lines.length,
      rowKeyBuilder: (index) => Key(
        'salesReturnLine_${widget.lines[index].returnable.source.id.value}',
      ),
      rowCellsBuilder: (context, index) {
        final editor = widget.lines[index];
        final line = editor.returnable;
        final source = line.source;
        return [
          _cell('${index + 1}', numeric: true),
          _cell(source.itemCodeSnapshot, numeric: true),
          _cell(source.itemNameSnapshot),
          _cell(source.warehouseNameSnapshot),
          _cell('${source.quantity.value}', numeric: true),
          _cell('${line.previouslyReturned.value}', numeric: true),
          _cell('${line.available.value}', numeric: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: AppIntegerField(
              fieldKey: Key(
                'salesReturnQuantity_${source.id.value}',
              ),
              controller: editor.quantityController,
              label: 'كمية المرتجع',
              showLabel: false,
              borderRadius: AppRadii.sm,
              accentColor: AppModuleColors.sales,
              enabled: widget.enabled && !line.available.isZero,
              onChanged: (_) => widget.onQuantityChanged(),
            ),
          ),
          _cell(
            AppFormatters.moneyByCurrency(
              source.netUnitPrice.majorUnits,
              widget.currencyCode,
            ),
            numeric: true,
          ),
          _cell(
            AppFormatters.moneyByCurrency(
              editor.previewRefund.majorUnits,
              widget.currencyCode,
            ),
            numeric: true,
          ),
        ];
      },
      summaryCells: [
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'المجموع',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        _cell('$totalQuantity', numeric: true, bold: true),
        const SizedBox.shrink(),
        _cell(
          AppFormatters.moneyByCurrency(
            totalRefund.majorUnits,
            widget.currencyCode,
          ),
          numeric: true,
          bold: true,
        ),
      ],
    );
  }
}

Widget _cell(
  String value, {
  bool numeric = false,
  bool bold = false,
}) {
  final text = value.trim().isEmpty ? '—' : value;
  return Align(
    alignment: numeric ? Alignment.center : Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: numeric ? TextAlign.center : TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),
  );
}
