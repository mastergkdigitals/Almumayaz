import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';

const purchaseWarehouseNames = <String>[
  'الرئيسي',
  'الرصافة',
  'الكرادة',
  'المنصور',
];

const _cellHeight = 56.0;
const _cellRadius = 3.0;
const _cellFontSize = 16.0;
const _headerFontSize = 14.0;
const _purchaseGreen = AppModuleColors.purchases;
const _purchaseGreenDark = Color(0xFF064E3B);
final _purchaseGreenSoft = Color.alphaBlend(
  AppModuleColors.purchases.withAlpha(18),
  AppColors.surface,
);
final _tableSurface = Color.alphaBlend(
  AppModuleColors.purchases.withAlpha(8),
  AppColors.surface,
);
final _line = Color.alphaBlend(
  AppModuleColors.purchases.withAlpha(96),
  AppColors.border,
);
final _strongLine = Color.alphaBlend(
  AppModuleColors.purchases.withAlpha(150),
  AppColors.border,
);

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
        salePrice = TextEditingController(text: seed.salePrice) {
    focusNodes = [
      codeFocusNode,
      nameFocusNode,
      warehouseFocusNode,
      quantityFocusNode,
      containerFocusNode,
      purchasePriceFocusNode,
      discountFocusNode,
      salePriceFocusNode,
    ];
    focusListenable = Listenable.merge(focusNodes);
  }

  final String id;
  final codeFocusNode = FocusNode();
  final nameFocusNode = FocusNode();
  final warehouseFocusNode = FocusNode();
  final quantityFocusNode = FocusNode();
  final containerFocusNode = FocusNode();
  final purchasePriceFocusNode = FocusNode();
  final discountFocusNode = FocusNode();
  final salePriceFocusNode = FocusNode();
  final TextEditingController code;
  final TextEditingController name;
  String warehouse;
  final TextEditingController quantity;
  final TextEditingController container;
  final TextEditingController purchasePrice;
  final TextEditingController discount;
  final TextEditingController salePrice;
  late final List<FocusNode> focusNodes;
  late final Listenable focusListenable;

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

  bool get hasFocusedCell => focusNodes.any((node) => node.hasFocus);

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
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
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
  });

  final PurchaseItemsController controller;
  final String keyPrefix;

  @override
  State<PurchaseItemsTable> createState() => _PurchaseItemsTableState();
}

class _PurchaseItemsTableState extends State<PurchaseItemsTable> {
  final _scrollController = ScrollController();
  final _keyHoldGuard = AppKeyHoldGuard();

  @override
  void dispose() {
    _keyHoldGuard.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addRow() {
    final row = widget.controller.addRow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        );
      }
      row.codeFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : 1622.0;
            final widths = _PurchaseTableWidths.fit(
              tableWidth - (_PurchaseTable._tableInset * 2),
              index: _PurchaseTable._indexWidth,
              action: _PurchaseTable._actionWidth,
            );

            return _PurchaseTable(
              keyPrefix: widget.keyPrefix,
              rows: widget.controller.rows,
              widths: widths,
              scrollController: _scrollController,
              keyHoldGuard: _keyHoldGuard,
              onAddRow: _addRow,
              onDeleteRow: widget.controller.removeRow,
              onChanged: widget.controller.rowChanged,
            );
          },
        );
      },
    );
  }
}

class _PurchaseTable extends StatelessWidget {
  const _PurchaseTable({
    required this.keyPrefix,
    required this.rows,
    required this.widths,
    required this.scrollController,
    required this.keyHoldGuard,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onChanged,
  });

  static const _indexWidth = 54.0;
  static const _actionWidth = 54.0;
  static const _tableInset = 8.0;

  final String keyPrefix;
  final List<PurchaseItemRow> rows;
  final _PurchaseTableWidths widths;
  final ScrollController scrollController;
  final AppKeyHoldGuard keyHoldGuard;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('${keyPrefix}TableSurface'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _tableSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_tableInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PurchaseTableHeader(
              keyPrefix: keyPrefix,
              widths: widths,
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: rows.length > 2,
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _PurchaseTableRow(
                      key: Key('${keyPrefix}Row-${row.id}'),
                      keyPrefix: keyPrefix,
                      index: index,
                      row: row,
                      widths: widths,
                      keyHoldGuard: keyHoldGuard,
                      canDelete: rows.length > 1,
                      onDelete: () => onDeleteRow(index),
                      onChanged: onChanged,
                      onLastCellSubmitted: onAddRow,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTableHeader extends StatelessWidget {
  const _PurchaseTableHeader({
    required this.keyPrefix,
    required this.widths,
  });

  final String keyPrefix;
  final _PurchaseTableWidths widths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('${keyPrefix}TableHeader'),
      height: 48,
      child: Row(
        children: [
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-index'),
            label: 'ت',
            width: widths.index,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-code'),
            label: 'رمز المادة',
            width: widths.code,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-name'),
            label: 'اسم المادة',
            width: widths.name,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-warehouse'),
            label: 'المخزن',
            width: widths.warehouse,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-quantity'),
            label: 'الكمية',
            width: widths.quantity,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-container'),
            label: 'الحاوية',
            width: widths.container,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-purchasePrice'),
            label: 'سعر الشراء',
            width: widths.purchasePrice,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-discount'),
            label: 'الخصم',
            width: widths.discount,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-priceAfterDiscount'),
            label: 'السعر بعد\nالخصم',
            width: widths.priceAfterDiscount,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-total'),
            label: 'الإجمالي',
            width: widths.total,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-cost'),
            label: 'الكلفة',
            width: widths.cost,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-totalCost'),
            label: 'إجمالي\nالكلفة',
            width: widths.totalCost,
          ),
          _PurchaseHeaderCell(
            key: Key('${keyPrefix}Header-salePrice'),
            label: 'سعر البيع',
            width: widths.salePrice,
          ),
          SizedBox(width: widths.action),
        ],
      ),
    );
  }
}

class _PurchaseHeaderCell extends StatelessWidget {
  const _PurchaseHeaderCell({
    required this.label,
    required this.width,
    super.key,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cellRadius),
            border: Border.all(color: _line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.tableHeader.copyWith(
                color: _purchaseGreenDark,
                fontSize: _headerFontSize,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseTableRow extends StatelessWidget {
  const _PurchaseTableRow({
    required this.keyPrefix,
    required this.index,
    required this.row,
    required this.widths,
    required this.keyHoldGuard,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
    required this.onLastCellSubmitted,
    super.key,
  });

  final String keyPrefix;
  final int index;
  final PurchaseItemRow row;
  final _PurchaseTableWidths widths;
  final AppKeyHoldGuard keyHoldGuard;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback onLastCellSubmitted;

  Key _key(String name) => Key('$keyPrefix$name-${row.id}');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: row.focusListenable,
      builder: (context, _) {
        return SizedBox(
          height: 72,
          child: Row(
            children: [
              _PurchaseIndexCell(
                cellKey: _key('IndexCell'),
                value: '${index + 1}',
                width: widths.index,
                highlighted: row.hasFocusedCell,
              ),
              _PurchaseInputCell(
                cellKey: _key('CodeCell'),
                fieldKey: _key('Code'),
                controller: row.code,
                focusNode: row.codeFocusNode,
                nextFocusNode: row.nameFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.code,
                emphasized: true,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseInputCell(
                cellKey: _key('NameCell'),
                fieldKey: _key('Name'),
                controller: row.name,
                focusNode: row.nameFocusNode,
                nextFocusNode: row.warehouseFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.name,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseWarehouseCell(
                cellKey: _key('WarehouseCell'),
                fieldKey: _key('Warehouse'),
                value: row.warehouse,
                focusNode: row.warehouseFocusNode,
                nextFocusNode: row.quantityFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.warehouse,
                onChanged: (value) {
                  row.warehouse = value;
                  onChanged();
                },
              ),
              _PurchaseInputCell(
                cellKey: _key('QuantityCell'),
                fieldKey: _key('Quantity'),
                controller: row.quantity,
                focusNode: row.quantityFocusNode,
                nextFocusNode: row.containerFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.quantity,
                numeric: true,
                wholeNumber: true,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseInputCell(
                cellKey: _key('ContainerCell'),
                fieldKey: _key('Container'),
                controller: row.container,
                focusNode: row.containerFocusNode,
                nextFocusNode: row.purchasePriceFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.container,
                numeric: true,
                wholeNumber: true,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseInputCell(
                cellKey: _key('PurchasePriceCell'),
                fieldKey: _key('PurchasePrice'),
                controller: row.purchasePrice,
                focusNode: row.purchasePriceFocusNode,
                nextFocusNode: row.discountFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.purchasePrice,
                numeric: true,
                emphasized: true,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseInputCell(
                cellKey: _key('DiscountCell'),
                fieldKey: _key('Discount'),
                controller: row.discount,
                focusNode: row.discountFocusNode,
                nextFocusNode: row.salePriceFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.discount,
                numeric: true,
                onChanged: (_) => onChanged(),
              ),
              _PurchaseValueCell(
                cellKey: _key('PriceAfterDiscountCell'),
                valueKey: _key('PriceAfterDiscount'),
                value: AppFormatters.money(row.priceAfterDiscount),
                width: widths.priceAfterDiscount,
              ),
              _PurchaseValueCell(
                cellKey: _key('TotalCell'),
                valueKey: _key('Total'),
                value: AppFormatters.money(row.lineTotal),
                width: widths.total,
                emphasized: true,
              ),
              _PurchaseValueCell(
                cellKey: _key('CostCell'),
                valueKey: _key('Cost'),
                value: AppFormatters.money(row.unitCost),
                width: widths.cost,
              ),
              _PurchaseValueCell(
                cellKey: _key('TotalCostCell'),
                valueKey: _key('TotalCost'),
                value: AppFormatters.money(row.totalCost),
                width: widths.totalCost,
                emphasized: true,
              ),
              _PurchaseInputCell(
                cellKey: _key('SalePriceCell'),
                fieldKey: _key('SalePrice'),
                controller: row.salePrice,
                focusNode: row.salePriceFocusNode,
                keyHoldGuard: keyHoldGuard,
                width: widths.salePrice,
                numeric: true,
                emphasized: true,
                onChanged: (_) => onChanged(),
                onSubmitted: onLastCellSubmitted,
              ),
              SizedBox(
                width: widths.action,
                child: ExcludeFocus(
                  child: Center(
                    child: AppTableActionButton(
                      key: _key('Delete'),
                      tooltipKey: _key('DeleteTooltip'),
                      icon: Icons.close_rounded,
                      tooltip: 'حذف السطر',
                      variant: AppButtonVariant.danger,
                      size: 44,
                      iconSize: 19,
                      borderRadius: _cellRadius,
                      onPressed: canDelete ? onDelete : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseIndexCell extends StatelessWidget {
  const _PurchaseIndexCell({
    required this.cellKey,
    required this.value,
    required this.width,
    required this.highlighted,
  });

  final Key cellKey;
  final String value;
  final double width;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Center(
          child: Container(
            key: cellKey,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? _purchaseGreen : _purchaseGreenSoft,
              borderRadius: BorderRadius.circular(_cellRadius),
              border: Border.all(color: _line),
            ),
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: AppTypography.tableCell.copyWith(
                color: highlighted ? Colors.white : _purchaseGreenDark,
                fontSize: _cellFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseWarehouseCell extends StatelessWidget {
  const _PurchaseWarehouseCell({
    required this.cellKey,
    required this.fieldKey,
    required this.value,
    required this.focusNode,
    required this.nextFocusNode,
    required this.keyHoldGuard,
    required this.width,
    required this.onChanged,
  });

  final Key cellKey;
  final Key fieldKey;
  final String value;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final AppKeyHoldGuard keyHoldGuard;
  final double width;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    void advanceWithTab() {
      keyHoldGuard.runOnce(
        keys: {LogicalKeyboardKey.tab},
        action: () => AppFocusTraversal.next(context),
      );
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: AnimatedBuilder(
          animation: focusNode,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.tab): advanceWithTab,
            },
            child: AppInvoiceCellDropdown(
              fieldKey: fieldKey,
              value: value,
              options: purchaseWarehouseNames,
              focusNode: focusNode,
              keyHoldGuard: keyHoldGuard,
              accentColor: AppModuleColors.purchases,
              fontSize: _cellFontSize,
              onChanged: onChanged,
              onSubmitted: (_) => nextFocusNode.requestFocus(),
            ),
          ),
          builder: (context, child) {
            final focused = focusNode.hasFocus;
            return _PurchaseCellFrame(
              key: cellKey,
              borderColor: focused ? _purchaseGreen : _line,
              borderWidth: focused ? 1.5 : 1,
              child: child!,
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseInputCell extends StatelessWidget {
  const _PurchaseInputCell({
    required this.cellKey,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.keyHoldGuard,
    required this.width,
    this.nextFocusNode,
    this.numeric = false,
    this.wholeNumber = false,
    this.emphasized = false,
    this.onChanged,
    this.onSubmitted,
  });

  final Key cellKey;
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppKeyHoldGuard keyHoldGuard;
  final FocusNode? nextFocusNode;
  final double width;
  final bool numeric;
  final bool wholeNumber;
  final bool emphasized;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    void advanceWithTab() {
      keyHoldGuard.runOnce(
        keys: {LogicalKeyboardKey.tab},
        action: () => AppFocusTraversal.next(context),
      );
    }

    void submit() {
      keyHoldGuard.runOnce(
        keys: {
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
        },
        action: () {
          final callback = onSubmitted;
          if (callback != null) {
            callback();
            return;
          }
          nextFocusNode?.requestFocus();
        },
      );
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: AnimatedBuilder(
          animation: focusNode,
          child: Center(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.tab): advanceWithTab,
              },
              child: TextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                keyboardType: numeric
                    ? TextInputType.numberWithOptions(
                        decimal: !wholeNumber,
                      )
                    : TextInputType.text,
                inputFormatters: wholeNumber
                    ? const [AppIntegerInputFormatter()]
                    : null,
                textInputAction: TextInputAction.next,
                maxLines: 1,
                textAlign: numeric ? TextAlign.center : TextAlign.right,
                textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
                style: AppTypography.tableCell.copyWith(
                  color:
                      emphasized ? _purchaseGreenDark : AppColors.textPrimary,
                  fontSize: _cellFontSize,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 7,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                onChanged: onChanged,
                onSubmitted: (_) => submit(),
              ),
            ),
          ),
          builder: (context, child) {
            final focused = focusNode.hasFocus;
            return MouseRegion(
              cursor: SystemMouseCursors.text,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => focusNode.requestFocus(),
                child: _PurchaseCellFrame(
                  key: cellKey,
                  borderColor: focused
                      ? _purchaseGreen
                      : emphasized
                          ? _strongLine
                          : _line,
                  borderWidth: focused ? 1.5 : 1,
                  child: child!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseValueCell extends StatelessWidget {
  const _PurchaseValueCell({
    required this.cellKey,
    required this.valueKey,
    required this.value,
    required this.width,
    this.emphasized = false,
  });

  final Key cellKey;
  final Key valueKey;
  final String value;
  final double width;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: _PurchaseCellFrame(
          key: cellKey,
          borderColor: emphasized ? _strongLine : _line,
          child: Center(
            child: Text(
              value,
              key: valueKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: AppTypography.tableCell.copyWith(
                color:
                    emphasized ? _purchaseGreenDark : AppColors.textPrimary,
                fontSize: _cellFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseCellFrame extends StatelessWidget {
  const _PurchaseCellFrame({
    required this.child,
    super.key,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
  });

  final Widget child;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cellHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PurchaseTableWidths {
  const _PurchaseTableWidths({
    required this.index,
    required this.code,
    required this.name,
    required this.warehouse,
    required this.quantity,
    required this.container,
    required this.purchasePrice,
    required this.discount,
    required this.priceAfterDiscount,
    required this.total,
    required this.cost,
    required this.totalCost,
    required this.salePrice,
    required this.action,
  });

  factory _PurchaseTableWidths.fit(
    double totalWidth, {
    required double index,
    required double action,
  }) {
    const baseDataWidth = 1506.0;
    final availableDataWidth = totalWidth - index - action;
    final scale = availableDataWidth > 0
        ? availableDataWidth / baseDataWidth
        : 0.0;

    return _PurchaseTableWidths(
      index: index,
      code: 126 * scale,
      name: 190 * scale,
      warehouse: 138 * scale,
      quantity: 104 * scale,
      container: 104 * scale,
      purchasePrice: 126 * scale,
      discount: 104 * scale,
      priceAfterDiscount: 146 * scale,
      total: 116 * scale,
      cost: 104 * scale,
      totalCost: 132 * scale,
      salePrice: 116 * scale,
      action: action,
    );
  }

  final double index;
  final double code;
  final double name;
  final double warehouse;
  final double quantity;
  final double container;
  final double purchasePrice;
  final double discount;
  final double priceAfterDiscount;
  final double total;
  final double cost;
  final double totalCost;
  final double salePrice;
  final double action;
}
