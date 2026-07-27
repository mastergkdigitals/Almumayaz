import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';

const purchaseWarehouseNames = <String>[
  'الرئيسي',
  'الرصافة',
  'الكرادة',
  'المنصور',
];

const _purchaseTextColor = Color(0xFF111827);
const _purchaseAddColor = Color(0xFF16A34A);
const _purchaseDeleteColor = Color(0xFFDC2626);
const _purchaseHeaderHeight = 46.0;
const _purchaseRowHeight = 54.0;
const _purchaseSummaryHeight = 46.0;
const _purchaseCellHeight = 38.0;
const _purchaseOuterRadius = 18.0;
const _purchaseCellRadius = 3.0;
const _purchaseEdgeInset = 6.0;
const _purchaseWidthSafetyBuffer = 8.0;

final _purchaseSelectedTint = Color.alphaBlend(
  AppModuleColors.purchases.withAlpha(22),
  AppColors.surface,
);
const _purchaseHoverTint = AppColors.controlHoverSurface;
final _purchaseHeaderColor = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.82,
)!;
final _purchaseSummaryColor = Color.lerp(
  _purchaseHeaderColor,
  Colors.white,
  0.48,
)!;
final _purchaseCellColor = Color.lerp(
  _purchaseHeaderColor,
  Colors.white,
  0.82,
)!;
final _purchasePanelBorder = Color.lerp(
  AppModulePalettes.purchases.middle,
  Colors.white,
  0.62,
)!;
final _purchaseOuterBorder = Color.lerp(
  _purchasePanelBorder,
  AppModulePalettes.purchases.middle,
  0.22,
)!;
final _purchaseCellBorder = Color.lerp(
  const Color(0xFFE5E7EB),
  _purchasePanelBorder,
  0.45,
)!;

const _purchaseColumns = <_PurchaseGridColumn>[
  _PurchaseGridColumn('ت', 54),
  _PurchaseGridColumn('رمز المادة', 126),
  _PurchaseGridColumn('اسم المادة', 190),
  _PurchaseGridColumn('المخزن', 138),
  _PurchaseGridColumn('الكمية', 104),
  _PurchaseGridColumn('الحاوية', 104),
  _PurchaseGridColumn('سعر الشراء', 126),
  _PurchaseGridColumn('الخصم', 104),
  _PurchaseGridColumn('السعر بعد الخصم', 146),
  _PurchaseGridColumn('الإجمالي', 116),
  _PurchaseGridColumn('الكلفة', 104),
  _PurchaseGridColumn('إجمالي الكلفة', 132),
  _PurchaseGridColumn('سعر البيع', 116),
  _PurchaseGridColumn('', 82),
];

class _PurchaseGridColumn {
  const _PurchaseGridColumn(this.label, this.width);

  final String label;
  final double width;
}

class PurchaseItemSeed {
  const PurchaseItemSeed({
    this.code = '',
    this.name = '',
    this.warehouse = 'الرئيسي',
    this.quantity = '0',
    this.container = '0',
    this.purchasePrice = '0',
    this.discount = '0',
    this.salePrice = '0',
  });

  final String code;
  final String name;
  final String warehouse;
  final String quantity;
  final String container;
  final String purchasePrice;
  final String discount;
  final String salePrice;

  String get fingerprint => [
        code,
        name,
        warehouse,
        quantity,
        container,
        purchasePrice,
        discount,
        salePrice,
      ].join('\u001f');
}

class PurchaseItemsController extends ChangeNotifier {
  PurchaseItemsController({
    List<PurchaseItemSeed> initialItems = const [],
    this.idPrefix = 'r',
  }) {
    _replaceRows(initialItems);
  }

  final _rows = <PurchaseItemRow>[];
  final String idPrefix;
  var _nextId = 1;

  List<PurchaseItemRow> get rows => List.unmodifiable(_rows);

  List<PurchaseItemSeed> get snapshot => [
        for (final row in _rows) row.seed,
      ];

  double get quantityTotal => _rows.fold(
        0,
        (sum, row) => sum + row.quantityValue,
      );

  double get discountTotal => _rows.fold(
        0,
        (sum, row) => sum + row.discountValue,
      );

  double get subtotal => _rows.fold(
        0,
        (sum, row) => sum + row.lineTotal,
      );

  double get totalCost => _rows.fold(
        0,
        (sum, row) => sum + row.totalCost,
      );

  bool get hasCompleteItem => _rows.any((row) {
        final hasProduct = row.code.text.trim().isNotEmpty ||
            row.name.text.trim().isNotEmpty;
        return hasProduct && row.quantityValue > 0;
      });

  PurchaseItemRow addRow() {
    final row = _newRow(const PurchaseItemSeed());
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

  void replaceItems(List<PurchaseItemSeed> items) {
    final removed = List<PurchaseItemRow>.of(_rows);
    _replaceRows(items);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in removed) {
        row.dispose();
      }
    });
  }

  void _replaceRows(List<PurchaseItemSeed> items) {
    _rows
      ..clear()
      ..addAll(
        (items.isEmpty ? const [PurchaseItemSeed()] : items).map(_newRow),
      );
  }

  PurchaseItemRow _newRow(PurchaseItemSeed seed) {
    return PurchaseItemRow(id: '$idPrefix${_nextId++}', seed: seed);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class PurchaseItemRow {
  PurchaseItemRow({
    required this.id,
    required PurchaseItemSeed seed,
  })  : code = TextEditingController(text: seed.code),
        name = TextEditingController(text: seed.name),
        warehouse = purchaseWarehouseNames.contains(seed.warehouse)
            ? seed.warehouse
            : purchaseWarehouseNames.first,
        quantity = TextEditingController(text: seed.quantity),
        container = TextEditingController(text: seed.container),
        purchasePrice = TextEditingController(text: seed.purchasePrice),
        discount = TextEditingController(text: seed.discount),
        salePrice = TextEditingController(text: seed.salePrice);

  final String id;
  final TextEditingController code;
  final TextEditingController name;
  String warehouse;
  final TextEditingController quantity;
  final TextEditingController container;
  final TextEditingController purchasePrice;
  final TextEditingController discount;
  final TextEditingController salePrice;

  PurchaseItemSeed get seed => PurchaseItemSeed(
        code: code.text,
        name: name.text,
        warehouse: warehouse,
        quantity: quantity.text,
        container: container.text,
        purchasePrice: purchasePrice.text,
        discount: discount.text,
        salePrice: salePrice.text,
      );

  double get quantityValue => _numberValue(quantity);
  double get discountValue => _numberValue(discount);

  double get lineTotal {
    return quantityValue * _numberValue(purchasePrice) - discountValue;
  }

  double get priceAfterDiscount {
    return quantityValue <= 0 ? 0 : lineTotal / quantityValue;
  }

  double get totalCost => lineTotal;

  double get unitCost {
    return quantityValue <= 0 ? 0 : totalCost / quantityValue;
  }

  double _numberValue(TextEditingController controller) {
    return AppFormatters.parseNumber(controller.text)?.toDouble() ?? 0;
  }

  void dispose() {
    code.dispose();
    name.dispose();
    quantity.dispose();
    container.dispose();
    purchasePrice.dispose();
    discount.dispose();
    salePrice.dispose();
  }
}

class PurchaseItemsTable extends StatefulWidget {
  const PurchaseItemsTable({
    required this.controller,
    super.key,
    this.keyPrefix = 'purchase',
    this.currencyCode = 'IQD',
  });

  final PurchaseItemsController controller;
  final String keyPrefix;
  final String currencyCode;

  @override
  State<PurchaseItemsTable> createState() => _PurchaseItemsTableState();
}

class _PurchaseItemsTableState extends State<PurchaseItemsTable> {
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

            return _PurchaseInvoiceGrid(
              tableKey: Key('${widget.keyPrefix}TableSurface'),
              height: tableHeight,
              keyPrefix: widget.keyPrefix,
              verticalScrollController: _verticalScrollController,
              horizontalScrollController: _horizontalScrollController,
              rows: widget.controller.rows,
              quantityTotal: widget.controller.quantityTotal,
              discountTotal: widget.controller.discountTotal,
              subtotal: widget.controller.subtotal,
              totalCost: widget.controller.totalCost,
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

class _PurchaseInvoiceGrid extends StatelessWidget {
  const _PurchaseInvoiceGrid({
    required this.tableKey,
    required this.height,
    required this.keyPrefix,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.rows,
    required this.quantityTotal,
    required this.discountTotal,
    required this.subtotal,
    required this.totalCost,
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
  final List<PurchaseItemRow> rows;
  final double quantityTotal;
  final double discountTotal;
  final double subtotal;
  final double totalCost;
  final String Function(double value) money;
  final VoidCallback onChanged;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;

  @override
  Widget build(BuildContext context) {
    final contentWidth = _purchaseColumns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );
    final safeContentWidth =
        contentWidth +
        (_purchaseEdgeInset * 2) +
        _purchaseWidthSafetyBuffer;
    final minimumHeight =
        _purchaseHeaderHeight +
        _purchaseRowHeight +
        _purchaseSummaryHeight;
    final tableHeight = height < minimumHeight ? minimumHeight : height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : safeContentWidth;
        final tableWidth = availableWidth > safeContentWidth
            ? availableWidth
            : safeContentWidth;
        final occupiedWidth =
            contentWidth + (_purchaseEdgeInset * 2);
        final trailingWidth =
            tableWidth > occupiedWidth ? tableWidth - occupiedWidth : 0.0;

        final table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PurchaseGridHeaderRow(
                keyPrefix: keyPrefix,
                columns: _purchaseColumns,
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
                      itemExtent: _purchaseRowHeight,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return _PurchaseGridBodyRow(
                          key: Key('${keyPrefix}Row-${row.id}'),
                          keyPrefix: keyPrefix,
                          columns: _purchaseColumns,
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
              _PurchaseGridSummaryRow(
                keyPrefix: keyPrefix,
                columns: _purchaseColumns,
                trailingWidth: trailingWidth,
                quantityTotal: quantityTotal,
                discountTotal: discountTotal,
                subtotal: subtotal,
                totalCost: totalCost,
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
            borderRadius: BorderRadius.circular(_purchaseOuterRadius),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_purchaseOuterRadius),
            border: Border.all(
              color: _purchaseOuterBorder,
              width: 1.4,
            ),
          ),
          child: Scrollbar(
            controller: horizontalScrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: Key('${keyPrefix}HorizontalScroll'),
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

class _PurchaseGridHeaderRow extends StatelessWidget {
  const _PurchaseGridHeaderRow({
    required this.keyPrefix,
    required this.columns,
    required this.trailingWidth,
  });

  final String keyPrefix;
  final List<_PurchaseGridColumn> columns;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('${keyPrefix}TableHeader'),
      height: _purchaseHeaderHeight,
      decoration: BoxDecoration(
        color: _purchaseHeaderColor,
        border: Border(
          bottom: BorderSide(color: _purchasePanelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _purchaseEdgeInset),
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
                        color: _purchaseTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: _purchaseEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _PurchaseGridBodyRow extends StatelessWidget {
  const _PurchaseGridBodyRow({
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
  final List<_PurchaseGridColumn> columns;
  final double trailingWidth;
  final PurchaseItemRow row;
  final int rowNumber;
  final bool isLastRow;
  final String Function(double value) money;
  final VoidCallback onChanged;
  final VoidCallback onAddRow;
  final VoidCallback onDeleteRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _purchaseRowHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: _purchasePanelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _purchaseEdgeInset),
            _PurchaseGridValueCell(
              width: columns[0].width,
              frameKey: Key('${keyPrefix}IndexCell-${row.id}'),
              valueKey: Key('${keyPrefix}Index-${row.id}'),
              value: '$rowNumber',
            ),
            _PurchaseGridEditorCell(
              width: columns[1].width,
              frameKey: Key('${keyPrefix}CodeCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Code-${row.id}'),
              controller: row.code,
              onChanged: onChanged,
            ),
            _PurchaseGridEditorCell(
              width: columns[2].width,
              frameKey: Key('${keyPrefix}NameCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Name-${row.id}'),
              controller: row.name,
              onChanged: onChanged,
            ),
            _PurchaseGridCellFrame(
              width: columns[3].width,
              frameKey: Key('${keyPrefix}WarehouseCell-${row.id}'),
              decorate: false,
              child: _PurchaseWarehouseDropdown(
                fieldKey: Key('${keyPrefix}Warehouse-${row.id}'),
                value: row.warehouse,
                onChanged: (value) {
                  row.warehouse = value;
                  onChanged();
                },
              ),
            ),
            _PurchaseGridEditorCell(
              width: columns[4].width,
              frameKey: Key('${keyPrefix}QuantityCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Quantity-${row.id}'),
              controller: row.quantity,
              numeric: true,
              wholeNumber: true,
              onChanged: onChanged,
            ),
            _PurchaseGridEditorCell(
              width: columns[5].width,
              frameKey: Key('${keyPrefix}ContainerCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Container-${row.id}'),
              controller: row.container,
              numeric: true,
              wholeNumber: true,
              onChanged: onChanged,
            ),
            _PurchaseGridEditorCell(
              width: columns[6].width,
              frameKey: Key('${keyPrefix}PurchasePriceCell-${row.id}'),
              fieldKey: Key('${keyPrefix}PurchasePrice-${row.id}'),
              controller: row.purchasePrice,
              numeric: true,
              onChanged: onChanged,
            ),
            _PurchaseGridEditorCell(
              width: columns[7].width,
              frameKey: Key('${keyPrefix}DiscountCell-${row.id}'),
              fieldKey: Key('${keyPrefix}Discount-${row.id}'),
              controller: row.discount,
              numeric: true,
              onChanged: onChanged,
            ),
            _PurchaseGridValueCell(
              width: columns[8].width,
              frameKey: Key(
                '${keyPrefix}PriceAfterDiscountCell-${row.id}',
              ),
              valueKey: Key(
                '${keyPrefix}PriceAfterDiscount-${row.id}',
              ),
              value: money(row.priceAfterDiscount),
            ),
            _PurchaseGridValueCell(
              width: columns[9].width,
              frameKey: Key('${keyPrefix}TotalCell-${row.id}'),
              valueKey: Key('${keyPrefix}Total-${row.id}'),
              value: money(row.lineTotal),
            ),
            _PurchaseGridValueCell(
              width: columns[10].width,
              frameKey: Key('${keyPrefix}CostCell-${row.id}'),
              valueKey: Key('${keyPrefix}Cost-${row.id}'),
              value: money(row.unitCost),
            ),
            _PurchaseGridValueCell(
              width: columns[11].width,
              frameKey: Key('${keyPrefix}TotalCostCell-${row.id}'),
              valueKey: Key('${keyPrefix}TotalCost-${row.id}'),
              value: money(row.totalCost),
            ),
            _PurchaseGridEditorCell(
              width: columns[12].width,
              frameKey: Key('${keyPrefix}SalePriceCell-${row.id}'),
              fieldKey: Key('${keyPrefix}SalePrice-${row.id}'),
              controller: row.salePrice,
              numeric: true,
              onChanged: onChanged,
            ),
            _PurchaseGridActionCell(
              width: columns[13].width,
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
            const SizedBox(width: _purchaseEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _PurchaseGridCellFrame extends StatelessWidget {
  const _PurchaseGridCellFrame({
    required this.width,
    required this.frameKey,
    required this.child,
    this.decorate = true,
  });

  final double width;
  final Key frameKey;
  final Widget child;
  final bool decorate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Container(
          key: frameKey,
          height: _purchaseCellHeight,
          clipBehavior: decorate ? Clip.antiAlias : Clip.none,
          decoration: decorate
              ? BoxDecoration(
                  color: _purchaseCellColor,
                  borderRadius: BorderRadius.circular(_purchaseCellRadius),
                )
              : null,
          foregroundDecoration: decorate
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(_purchaseCellRadius),
                  border: Border.all(color: _purchaseCellBorder),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

class _PurchaseGridEditorCell extends StatefulWidget {
  const _PurchaseGridEditorCell({
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
  State<_PurchaseGridEditorCell> createState() =>
      _PurchaseGridEditorCellState();
}

class _PurchaseGridEditorCellState
    extends State<_PurchaseGridEditorCell> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'purchaseInvoiceCell');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

    return _PurchaseGridCellFrame(
      width: widget.width,
      frameKey: widget.frameKey,
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
          color: _purchaseTextColor,
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

class _PurchaseGridValueCell extends StatelessWidget {
  const _PurchaseGridValueCell({
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
    return _PurchaseGridCellFrame(
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
            color: _purchaseTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PurchaseGridActionCell extends StatelessWidget {
  const _PurchaseGridActionCell({
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
                isAddAction ? _purchaseAddColor : _purchaseDeleteColor,
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

class _PurchaseGridSummaryRow extends StatelessWidget {
  const _PurchaseGridSummaryRow({
    required this.keyPrefix,
    required this.columns,
    required this.trailingWidth,
    required this.quantityTotal,
    required this.discountTotal,
    required this.subtotal,
    required this.totalCost,
    required this.money,
  });

  final String keyPrefix;
  final List<_PurchaseGridColumn> columns;
  final double trailingWidth;
  final double quantityTotal;
  final double discountTotal;
  final double subtotal;
  final double totalCost;
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
        money(subtotal),
        key: Key('${keyPrefix}Subtotal'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox.shrink(),
      Text(
        money(totalCost),
        key: Key('${keyPrefix}TotalCost'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
    ];

    return Container(
      key: Key('${keyPrefix}TableSummary'),
      height: _purchaseSummaryHeight,
      color: _purchaseSummaryColor,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: _purchaseEdgeInset),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: DefaultTextStyle(
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _purchaseTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      child: values[index],
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: _purchaseEdgeInset),
          ],
        ),
      ),
    );
  }
}

class _PurchaseWarehouseDropdown extends StatefulWidget {
  const _PurchaseWarehouseDropdown({
    required this.fieldKey,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_PurchaseWarehouseDropdown> createState() =>
      _PurchaseWarehouseDropdownState();
}

class _PurchaseWarehouseDropdownState
    extends State<_PurchaseWarehouseDropdown> {
  final _layerLink = LayerLink();
  final _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _hovered = false;

  bool get _isOpen => _overlayEntry != null;

  @override
  void didUpdateWidget(covariant _PurchaseWarehouseDropdown oldWidget) {
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
                child: _PurchaseWarehouseMenu(
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
        ? AppModuleColors.purchases
        : _hovered
            ? AppColors.controlHoverBorder
            : AppColors.border;
    final backgroundColor = _isOpen
        ? Color.alphaBlend(
            AppModuleColors.purchases.withAlpha(14),
            AppColors.surface,
          )
        : _hovered
            ? Color.alphaBlend(
                AppModuleColors.purchases.withAlpha(8),
                AppColors.surface,
              )
            : AppColors.surface;

    return SizedBox(
      key: widget.fieldKey,
      height: _purchaseCellHeight,
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
                        color: AppModuleColors.purchases,
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
                          color: _purchaseTextColor,
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

class _PurchaseWarehouseMenu extends StatelessWidget {
  const _PurchaseWarehouseMenu({
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
          key: const Key('purchaseWarehouseMenu'),
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
                      for (final warehouse in purchaseWarehouseNames)
                        _PurchaseWarehouseMenuItem(
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

class _PurchaseWarehouseMenuItem extends StatefulWidget {
  const _PurchaseWarehouseMenuItem({
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  State<_PurchaseWarehouseMenuItem> createState() =>
      _PurchaseWarehouseMenuItemState();
}

class _PurchaseWarehouseMenuItemState
    extends State<_PurchaseWarehouseMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.selected ? AppModuleColors.purchases : _purchaseTextColor;
    final background = widget.selected
        ? _purchaseSelectedTint
        : _hovered
            ? _purchaseHoverTint
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
                    color: AppModuleColors.purchases,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
