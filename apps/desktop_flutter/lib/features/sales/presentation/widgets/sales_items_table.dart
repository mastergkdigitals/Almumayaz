import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';

const salesWarehouseNames = <String>[
  'الرئيسي',
  'الرصافة',
  'الكرادة',
  'المنصور',
];

const _salesTextColor = Color(0xFF111827);
const _salesAddColor = Color(0xFF16A34A);
const _salesDeleteColor = Color(0xFFDC2626);
const _salesHeaderHeight = 46.0;
const _salesRowHeight = 54.0;
const _salesSummaryHeight = 46.0;
const _salesCellHeight = 38.0;
const _salesOuterRadius = 18.0;
const _salesCellRadius = 3.0;
const _salesEdgeInset = 6.0;
const _salesWidthSafetyBuffer = 8.0;

final _salesSelectedTint = Color.alphaBlend(
  AppModuleColors.sales.withAlpha(22),
  AppColors.surface,
);
const _salesHoverTint = AppColors.controlHoverSurface;
final _salesHeaderColor = Color.lerp(
  AppModulePalettes.sales.light,
  Colors.white,
  0.82,
)!;
final _salesSummaryColor = Color.lerp(
  _salesHeaderColor,
  Colors.white,
  0.48,
)!;
final _salesCellColor = Color.lerp(
  _salesHeaderColor,
  Colors.white,
  0.82,
)!;
final _salesPanelBorder = Color.lerp(
  AppModulePalettes.sales.middle,
  Colors.white,
  0.62,
)!;
final _salesOuterBorder = Color.lerp(
  _salesPanelBorder,
  AppModulePalettes.sales.middle,
  0.22,
)!;
final _salesCellBorder = Color.lerp(
  const Color(0xFFE5E7EB),
  _salesPanelBorder,
  0.45,
)!;

const _salesColumns = <_SalesGridColumn>[
  _SalesGridColumn('ت', 54),
  _SalesGridColumn('رمز المادة', 126, grow: 0.75),
  _SalesGridColumn('اسم المادة', 190, grow: 3),
  _SalesGridColumn('المخزن', 138, grow: 1.35),
  _SalesGridColumn('الكمية', 104, grow: 0.70),
  _SalesGridColumn('سعر البيع', 126, grow: 0.90),
  _SalesGridColumn('الخصم', 104, grow: 0.70),
  _SalesGridColumn('السعر بعد الخصم', 146, grow: 1.45),
  _SalesGridColumn('الإجمالي', 116, grow: 1.55),
  _SalesGridColumn('', 82),
];

class _SalesGridColumn {
  const _SalesGridColumn(
    this.label,
    this.width, {
    this.grow = 0,
  });

  final String label;
  final double width;
  final double grow;

  _SalesGridColumn withWidth(double value) {
    return _SalesGridColumn(label, value, grow: grow);
  }
}

class SalesItemSeed {
  const SalesItemSeed({
    this.code = '',
    this.name = '',
    this.warehouse = 'الرئيسي',
    this.quantity = '0',
    this.salePrice = '0',
    this.discount = '0',
  });

  final String code;
  final String name;
  final String warehouse;
  final String quantity;
  final String salePrice;
  final String discount;
}

class SalesItemsController extends ChangeNotifier {
  SalesItemsController({
    List<SalesItemSeed> initialItems = const [],
    this.idPrefix = 'r',
  }) {
    _rows.addAll(
      (initialItems.isEmpty ? const [SalesItemSeed()] : initialItems)
          .map(_newRow),
    );
  }

  final _rows = <SalesItemRow>[];
  final String idPrefix;
  var _nextId = 1;

  List<SalesItemRow> get rows => List.unmodifiable(_rows);

  double get quantityTotal => _rows.fold(
        0,
        (sum, row) => sum + row.quantityValue,
      );

  double get discountTotal => _rows.fold(
        0,
        (sum, row) => sum + row.discountValue,
      );

  double get total => _rows.fold(
        0,
        (sum, row) => sum + row.lineTotal,
      );

  SalesItemRow addRow() {
    final row = _newRow(const SalesItemSeed());
    _rows.add(row);
    notifyListeners();
    return row;
  }

  void removeRow(int index) {
    if (_rows.length <= 1 || index < 0 || index >= _rows.length) return;

    final removed = _rows.removeAt(index);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void rowChanged() => notifyListeners();

  SalesItemRow _newRow(SalesItemSeed seed) {
    return SalesItemRow(id: '$idPrefix${_nextId++}', seed: seed);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class SalesItemRow {
  SalesItemRow({
    required this.id,
    required SalesItemSeed seed,
  })  : code = TextEditingController(text: seed.code),
        name = TextEditingController(text: seed.name),
        warehouse = salesWarehouseNames.contains(seed.warehouse)
            ? seed.warehouse
            : salesWarehouseNames.first,
        quantity = TextEditingController(text: seed.quantity),
        salePrice = TextEditingController(text: seed.salePrice),
        discount = TextEditingController(text: seed.discount);

  final String id;
  final TextEditingController code;
  final TextEditingController name;
  String warehouse;
  final TextEditingController quantity;
  final TextEditingController salePrice;
  final TextEditingController discount;

  double get quantityValue => _numberValue(quantity);
  double get salePriceValue => _numberValue(salePrice);
  double get discountValue => _numberValue(discount);

  double get priceAfterDiscount {
    final value = salePriceValue - discountValue;
    return value < 0 ? 0 : value;
  }

  double get lineTotal => priceAfterDiscount * quantityValue;

  double _numberValue(TextEditingController controller) {
    return AppFormatters.parseNumber(controller.text)?.toDouble() ?? 0;
  }

  void dispose() {
    code.dispose();
    name.dispose();
    quantity.dispose();
    salePrice.dispose();
    discount.dispose();
  }
}

class SalesItemsTable extends StatefulWidget {
  const SalesItemsTable({
    required this.controller,
    super.key,
    this.keyPrefix = 'sales',
    this.currencyCode = 'IQD',
  });

  final SalesItemsController controller;
  final String keyPrefix;
  final String currencyCode;

  @override
  State<SalesItemsTable> createState() => _SalesItemsTableState();
}

class _SalesItemsTableState extends State<SalesItemsTable> {
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _addRow() {
    widget.controller.addRow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_verticalScrollController.hasClients) return;
      _verticalScrollController.animateTo(
        _verticalScrollController.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _money(double value) {
    return widget.currencyCode == 'USD'
        ? AppFormatters.usd(value)
        : AppFormatters.iqd(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final tableHeight =
                constraints.hasBoundedHeight ? constraints.maxHeight : 308.0;

            return _SalesInvoiceGrid(
              tableKey: Key('${widget.keyPrefix}TableSurface'),
              height: tableHeight,
              keyPrefix: widget.keyPrefix,
              verticalScrollController: _verticalScrollController,
              horizontalScrollController: _horizontalScrollController,
              rows: widget.controller.rows,
              quantityTotal: widget.controller.quantityTotal,
              discountTotal: widget.controller.discountTotal,
              total: widget.controller.total,
              money: _money,
              onChanged: widget.controller.rowChanged,
              onAddRow: _addRow,
              onDeleteRow: widget.controller.removeRow,
            );
          },
        );
      },
    );
  }
}

class _SalesInvoiceGrid extends StatelessWidget {
  const _SalesInvoiceGrid({
    required this.tableKey,
    required this.height,
    required this.keyPrefix,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.rows,
    required this.quantityTotal,
    required this.discountTotal,
    required this.total,
    required this.money,
    required this.onChanged,
    required this.onAddRow,
    required this.onDeleteRow,
  });

  final Key tableKey;
  final double height;
  final String keyPrefix;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final List<SalesItemRow> rows;
  final double quantityTotal;
  final double discountTotal;
  final double total;
  final String Function(double value) money;
  final VoidCallback onChanged;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;

  @override
  Widget build(BuildContext context) {
    final baseContentWidth = _salesColumns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );
    final safeContentWidth =
        baseContentWidth +
        (_salesEdgeInset * 2) +
        _salesWidthSafetyBuffer;
    final minimumHeight =
        _salesHeaderHeight + _salesRowHeight + _salesSummaryHeight;
    final tableHeight = height < minimumHeight ? minimumHeight : height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : safeContentWidth;
        final tableWidth =
            availableWidth > safeContentWidth
                ? availableWidth
                : safeContentWidth;
        final columns = _expandedSalesColumns(
          _salesColumns,
          tableWidth,
        );
        final occupiedWidth = columns.fold<double>(
              0,
              (sum, column) => sum + column.width,
            ) +
            (_salesEdgeInset * 2);
        final trailingWidth =
            tableWidth > occupiedWidth ? tableWidth - occupiedWidth : 0.0;

        final table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SalesGridHeaderRow(
                keyPrefix: keyPrefix,
                columns: columns,
                trailingWidth: trailingWidth,
              ),
              Expanded(
                child: ColoredBox(
                  color: AppColors.surface,
                  child: Scrollbar(
                    controller: verticalScrollController,
                    child: ListView.builder(
                      controller: verticalScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      itemExtent: _salesRowHeight,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return _SalesGridBodyRow(
                          key: Key('${keyPrefix}Row-${row.id}'),
                          keyPrefix: keyPrefix,
                          columns: columns,
                          trailingWidth: trailingWidth,
                          row: row,
                          rowNumber: index + 1,
                          isLastRow: index == rows.length - 1,
                          money: money,
                          onChanged: onChanged,
                          onAddRow: onAddRow,
                          onDeleteRow: () => onDeleteRow(index),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _SalesGridSummaryRow(
                keyPrefix: keyPrefix,
                columns: columns,
                trailingWidth: trailingWidth,
                quantityTotal: quantityTotal,
                discountTotal: discountTotal,
                total: total,
                money: money,
              ),
            ],
          ),
        );

        return Container(
          key: tableKey,
          height: tableHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_salesOuterRadius),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_salesOuterRadius),
            border: Border.all(
              color: _salesOuterBorder,
              width: 1.4,
            ),
          ),
          child: Scrollbar(
            controller: horizontalScrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: table,
            ),
          ),
        );
      },
    );
  }
}

List<_SalesGridColumn> _expandedSalesColumns(
  List<_SalesGridColumn> columns,
  double tableWidth,
) {
  final baseContentWidth = columns.fold<double>(
    0,
    (sum, column) => sum + column.width,
  );
  final targetContentWidth = tableWidth - (_salesEdgeInset * 2);
  final extraWidth = targetContentWidth - baseContentWidth;
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

class _SalesGridHeaderRow extends StatelessWidget {
  const _SalesGridHeaderRow({
    required this.keyPrefix,
    required this.columns,
    required this.trailingWidth,
  });

  final String keyPrefix;
  final List<_SalesGridColumn> columns;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('${keyPrefix}TableHeader'),
      height: _salesHeaderHeight,
      decoration: BoxDecoration(
        color: _salesHeaderColor,
        border: Border(
          bottom: BorderSide(color: _salesPanelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _salesEdgeInset),
            for (final column in columns)
              SizedBox(
                width: column.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      column.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _salesTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: _salesEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _SalesGridBodyRow extends StatelessWidget {
  const _SalesGridBodyRow({
    required this.keyPrefix,
    required this.columns,
    required this.trailingWidth,
    required this.row,
    required this.rowNumber,
    required this.isLastRow,
    required this.money,
    required this.onChanged,
    required this.onAddRow,
    required this.onDeleteRow,
    super.key,
  });

  final String keyPrefix;
  final List<_SalesGridColumn> columns;
  final double trailingWidth;
  final SalesItemRow row;
  final int rowNumber;
  final bool isLastRow;
  final String Function(double value) money;
  final VoidCallback onChanged;
  final VoidCallback onAddRow;
  final VoidCallback onDeleteRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _salesRowHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: _salesPanelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _salesEdgeInset),
            _SalesGridValueCell(
              width: columns[0].width,
              frameKey: Key('${keyPrefix}IndexCell-${row.id}'),
              valueKey: Key('${keyPrefix}Index-${row.id}'),
              value: '$rowNumber',
            ),
            _SalesGridEditorCell(
              width: columns[1].width,
              frameKey: Key('${keyPrefix}CodeCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Code-${row.id}'),
              controller: row.code,
              onChanged: onChanged,
            ),
            _SalesGridEditorCell(
              width: columns[2].width,
              frameKey: Key('${keyPrefix}NameCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Name-${row.id}'),
              controller: row.name,
              onChanged: onChanged,
            ),
            _SalesGridCellFrame(
              width: columns[3].width,
              frameKey: Key('${keyPrefix}WarehouseCell-${row.id}'),
              decorate: false,
              child: _SalesWarehouseDropdown(
                fieldKey: Key('${keyPrefix}Warehouse-${row.id}'),
                value: row.warehouse,
                onChanged: (value) {
                  row.warehouse = value;
                  onChanged();
                },
              ),
            ),
            _SalesGridEditorCell(
              width: columns[4].width,
              frameKey: Key('${keyPrefix}QuantityCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Quantity-${row.id}'),
              controller: row.quantity,
              numeric: true,
              wholeNumber: true,
              onChanged: onChanged,
            ),
            _SalesGridEditorCell(
              width: columns[5].width,
              frameKey: Key('${keyPrefix}SalePriceCell-${row.id}'),
              fieldKey: Key('${keyPrefix}SalePrice-${row.id}'),
              controller: row.salePrice,
              numeric: true,
              onChanged: onChanged,
            ),
            _SalesGridEditorCell(
              width: columns[6].width,
              frameKey: Key('${keyPrefix}DiscountCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Discount-${row.id}'),
              controller: row.discount,
              numeric: true,
              onChanged: onChanged,
            ),
            _SalesGridValueCell(
              width: columns[7].width,
              frameKey: Key(
                '${keyPrefix}PriceAfterDiscountCell-${row.id}',
              ),
              valueKey: Key(
                '${keyPrefix}PriceAfterDiscount-${row.id}',
              ),
              value: money(row.priceAfterDiscount),
            ),
            _SalesGridValueCell(
              width: columns[8].width,
              frameKey: Key('${keyPrefix}TotalCell-${row.id}'),
              valueKey: Key('${keyPrefix}Total-${row.id}'),
              value: money(row.lineTotal),
            ),
            _SalesGridActionCell(
              width: columns[9].width,
              actionKey: Key(
                isLastRow
                    ? '${keyPrefix}Add-${row.id}'
                    : '${keyPrefix}Delete-${row.id}',
              ),
              tooltipKey: Key(
                isLastRow
                    ? '${keyPrefix}AddTooltip-${row.id}'
                    : '${keyPrefix}DeleteTooltip-${row.id}',
              ),
              isAddAction: isLastRow,
              onPressed: isLastRow ? onAddRow : onDeleteRow,
            ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: _salesEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _SalesGridCellFrame extends StatelessWidget {
  const _SalesGridCellFrame({
    required this.width,
    required this.frameKey,
    required this.child,
    this.focused = false,
    this.decorate = true,
  });

  final double width;
  final Key frameKey;
  final Widget child;
  final bool focused;
  final bool decorate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Container(
          key: frameKey,
          height: _salesCellHeight,
          clipBehavior: decorate ? Clip.antiAlias : Clip.none,
          decoration: decorate
              ? BoxDecoration(
                  color: _salesCellColor,
                  borderRadius: BorderRadius.circular(_salesCellRadius),
                )
              : null,
          foregroundDecoration: decorate
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(_salesCellRadius),
                  border: Border.all(
                    color: focused
                        ? AppModuleColors.sales
                        : _salesCellBorder,
                    width: focused ? 1.5 : 1,
                  ),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

class _SalesGridEditorCell extends StatefulWidget {
  const _SalesGridEditorCell({
    required this.width,
    required this.frameKey,
    required this.fieldKey,
    required this.controller,
    required this.onChanged,
    this.numeric = false,
    this.wholeNumber = false,
  });

  final double width;
  final Key frameKey;
  final Key fieldKey;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool numeric;
  final bool wholeNumber;

  @override
  State<_SalesGridEditorCell> createState() =>
      _SalesGridEditorCellState();
}

class _SalesGridEditorCellState extends State<_SalesGridEditorCell> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'salesInvoiceCell')
      ..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inputFormatters = widget.numeric
        ? <TextInputFormatter>[
            if (widget.wholeNumber)
              const AppIntegerInputFormatter()
            else
              const AppMoneyInputFormatter(),
          ]
        : null;

    return _SalesGridCellFrame(
      width: widget.width,
      frameKey: widget.frameKey,
      focused: _focusNode.hasFocus,
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.numeric
            ? TextInputType.numberWithOptions(
                decimal: !widget.wholeNumber,
              )
            : TextInputType.text,
        inputFormatters: inputFormatters,
        maxLines: 1,
        textInputAction: TextInputAction.next,
        textAlign: widget.numeric ? TextAlign.center : TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        textDirection:
            widget.numeric ? TextDirection.ltr : TextDirection.rtl,
        cursorColor: AppColors.cursor,
        style: const TextStyle(
          color: _salesTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: kTextHeightNone,
        ),
        decoration: const InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6),
        ),
        onChanged: (_) => widget.onChanged(),
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
    );
  }
}

class _SalesGridValueCell extends StatelessWidget {
  const _SalesGridValueCell({
    required this.width,
    required this.frameKey,
    required this.valueKey,
    required this.value,
  });

  final double width;
  final Key frameKey;
  final Key valueKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SalesGridCellFrame(
      width: width,
      frameKey: frameKey,
      child: Center(
        child: Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: _salesTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SalesGridActionCell extends StatelessWidget {
  const _SalesGridActionCell({
    required this.width,
    required this.actionKey,
    required this.tooltipKey,
    required this.isAddAction,
    required this.onPressed,
  });

  final double width;
  final Key actionKey;
  final Key tooltipKey;
  final bool isAddAction;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Center(
          child: AppTableActionButton(
            key: actionKey,
            tooltipKey: tooltipKey,
            icon:
                isAddAction ? Icons.add_rounded : Icons.close_rounded,
            tooltip: isAddAction ? 'إضافة سطر' : 'حذف السطر',
            variant: isAddAction
                ? AppButtonVariant.success
                : AppButtonVariant.danger,
            backgroundColor:
                isAddAction ? _salesAddColor : _salesDeleteColor,
            foregroundColor: Colors.white,
            size: 32,
            iconSize: 19,
            borderRadius: 9,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _SalesGridSummaryRow extends StatelessWidget {
  const _SalesGridSummaryRow({
    required this.keyPrefix,
    required this.columns,
    required this.trailingWidth,
    required this.quantityTotal,
    required this.discountTotal,
    required this.total,
    required this.money,
  });

  final String keyPrefix;
  final List<_SalesGridColumn> columns;
  final double trailingWidth;
  final double quantityTotal;
  final double discountTotal;
  final double total;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    final values = <Widget>[
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const Text(
        'المجموع',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
      const SizedBox.shrink(),
      Text(
        AppFormatters.quantity(quantityTotal.round()),
        key: Key('${keyPrefix}QuantityTotal'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox.shrink(),
      Text(
        money(discountTotal),
        key: Key('${keyPrefix}DiscountTotal'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox.shrink(),
      Text(
        money(total),
        key: Key('${keyPrefix}Total'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox.shrink(),
    ];

    return Container(
      key: Key('${keyPrefix}TableSummary'),
      height: _salesSummaryHeight,
      color: _salesSummaryColor,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _salesEdgeInset),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: DefaultTextStyle(
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _salesTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      child: values[index],
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: _salesEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _SalesWarehouseDropdown extends StatefulWidget {
  const _SalesWarehouseDropdown({
    required this.fieldKey,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SalesWarehouseDropdown> createState() =>
      _SalesWarehouseDropdownState();
}

class _SalesWarehouseDropdownState extends State<_SalesWarehouseDropdown> {
  final _layerLink = LayerLink();
  final _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _hovered = false;

  bool get _isOpen => _overlayEntry != null;

  @override
  void didUpdateWidget(covariant _SalesWarehouseDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void deactivate() {
    _hideMenu(updateState: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _hideMenu(updateState: false);
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    if (!mounted || _isOpen) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final fieldRenderObject = _anchorKey.currentContext?.findRenderObject();
    final overlayRenderObject = overlay?.context.findRenderObject();

    if (overlay == null ||
        fieldRenderObject is! RenderBox ||
        overlayRenderObject is! RenderBox ||
        !fieldRenderObject.attached ||
        !overlayRenderObject.attached ||
        !fieldRenderObject.hasSize ||
        !overlayRenderObject.hasSize) {
      return;
    }

    final fieldSize = fieldRenderObject.size;
    final fieldOffset = fieldRenderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );
    final overlaySize = overlayRenderObject.size;
    final spaceBelow = overlaySize.height - fieldOffset.dy - fieldSize.height;
    final spaceAbove = fieldOffset.dy;
    final openBelow = spaceBelow >= 180 || spaceBelow >= spaceAbove;
    final availableSpace = (openBelow ? spaceBelow : spaceAbove) - 12;
    final maxMenuHeight = availableSpace.clamp(96.0, 260.0).toDouble();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor:
                  openBelow ? Alignment.bottomRight : Alignment.topRight,
              followerAnchor:
                  openBelow ? Alignment.topRight : Alignment.bottomRight,
              offset: Offset(0, openBelow ? 4 : -4),
              showWhenUnlinked: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _SalesWarehouseMenu(
                  width: fieldSize.width,
                  maxHeight: maxMenuHeight,
                  selectedValue: widget.value,
                  onSelected: _selectValue,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _hideMenu({bool updateState = true}) {
    final overlayEntry = _overlayEntry;
    if (overlayEntry == null) return;

    _overlayEntry = null;
    overlayEntry.remove();
    if (mounted && updateState) setState(() {});
  }

  void _selectValue(String value) {
    widget.onChanged(value);
    _hideMenu();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isOpen
        ? AppModuleColors.sales
        : _hovered
            ? AppColors.controlHoverBorder
            : AppColors.border;
    final backgroundColor = _isOpen
        ? Color.alphaBlend(
            AppModuleColors.sales.withAlpha(14),
            AppColors.surface,
          )
        : _hovered
            ? Color.alphaBlend(
                AppModuleColors.sales.withAlpha(8),
                AppColors.surface,
              )
            : AppColors.surface;

    return SizedBox(
      key: widget.fieldKey,
      height: _salesCellHeight,
      child: CompositedTransformTarget(
        key: _anchorKey,
        link: _layerLink,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMenu,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: borderColor,
                  width: _isOpen ? 1.6 : 1,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: AppDurations.fast,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppModuleColors.sales,
                        size: AppIconSizes.md,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _salesTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: kTextHeightNone,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppIconSizes.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesWarehouseMenu extends StatelessWidget {
  const _SalesWarehouseMenu({
    required this.width,
    required this.maxHeight,
    required this.selectedValue,
    required this.onSelected,
  });

  final double width;
  final double maxHeight;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: DecoratedBox(
          key: const Key('salesWarehouseMenu'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: const [
              BoxShadow(
                color: AppColors.menuShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md - 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final warehouse in salesWarehouseNames)
                        _SalesWarehouseMenuItem(
                          value: warehouse,
                          selected: warehouse == selectedValue,
                          onSelected: onSelected,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesWarehouseMenuItem extends StatefulWidget {
  const _SalesWarehouseMenuItem({
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  State<_SalesWarehouseMenuItem> createState() =>
      _SalesWarehouseMenuItemState();
}

class _SalesWarehouseMenuItemState
    extends State<_SalesWarehouseMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.selected ? AppModuleColors.sales : _salesTextColor;
    final background = widget.selected
        ? _salesSelectedTint
        : _hovered
            ? _salesHoverTint
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.selected) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(widget.value),
        child: Container(
          height: 42,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  widget.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ),
              if (widget.selected)
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Icon(
                    Icons.check_rounded,
                    size: AppIconSizes.sm,
                    color: AppModuleColors.sales,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
