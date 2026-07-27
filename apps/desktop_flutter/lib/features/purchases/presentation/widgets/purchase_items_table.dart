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

final _purchaseSelectedTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.58,
)!;
final _purchaseHoverTint = Color.lerp(
  AppModulePalettes.purchases.light,
  Colors.white,
  0.78,
)!;

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

  @override
  void dispose() {
    _verticalScrollController.dispose();
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

            return AppInvoiceItemsTable.purchase(
              tableKey: Key('${widget.keyPrefix}TableSurface'),
              height: tableHeight,
              verticalScrollController: _verticalScrollController,
              rows: [
                for (var index = 0;
                    index < widget.controller.rows.length;
                    index++)
                  _row(
                    widget.controller.rows[index],
                    index,
                    index == widget.controller.rows.length - 1,
                  ),
              ],
              summaryCells: _summaryCells(),
            );
          },
        );
      },
    );
  }

  AppTableRow _row(
    PurchaseItemRow row,
    int index,
    bool isLastRow,
  ) {
    final keyPrefix = widget.keyPrefix;

    return AppTableRow(
      rowKey: Key('${keyPrefix}Row-${row.id}'),
      cells: [
        Text(
          '${index + 1}',
          key: Key('${keyPrefix}Index-${row.id}'),
          textDirection: TextDirection.ltr,
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}Code-${row.id}'),
          controller: row.code,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}Name-${row.id}'),
          controller: row.name,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchaseWarehouseDropdown(
          fieldKey: Key('${keyPrefix}Warehouse-${row.id}'),
          value: row.warehouse,
          onChanged: (value) {
            row.warehouse = value;
            widget.controller.rowChanged();
          },
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}Quantity-${row.id}'),
          controller: row.quantity,
          numeric: true,
          wholeNumber: true,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}Container-${row.id}'),
          controller: row.container,
          numeric: true,
          wholeNumber: true,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}PurchasePrice-${row.id}'),
          controller: row.purchasePrice,
          numeric: true,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}Discount-${row.id}'),
          controller: row.discount,
          numeric: true,
          onChanged: widget.controller.rowChanged,
        ),
        _PurchaseValue(
          valueKey: Key('${keyPrefix}PriceAfterDiscount-${row.id}'),
          value: _money(row.priceAfterDiscount),
        ),
        _PurchaseValue(
          valueKey: Key('${keyPrefix}Total-${row.id}'),
          value: _money(row.lineTotal),
        ),
        _PurchaseValue(
          valueKey: Key('${keyPrefix}Cost-${row.id}'),
          value: _money(row.unitCost),
        ),
        _PurchaseValue(
          valueKey: Key('${keyPrefix}TotalCost-${row.id}'),
          value: _money(row.totalCost),
        ),
        _PurchasePlainField(
          fieldKey: Key('${keyPrefix}SalePrice-${row.id}'),
          controller: row.salePrice,
          numeric: true,
          onChanged: widget.controller.rowChanged,
        ),
        AppTableActionButton(
          key: Key(
            isLastRow
                ? '${keyPrefix}Add-${row.id}'
                : '${keyPrefix}Delete-${row.id}',
          ),
          tooltipKey: Key(
            isLastRow
                ? '${keyPrefix}AddTooltip-${row.id}'
                : '${keyPrefix}DeleteTooltip-${row.id}',
          ),
          icon: isLastRow ? Icons.add_rounded : Icons.close_rounded,
          tooltip: isLastRow ? 'إضافة سطر' : 'حذف السطر',
          variant:
              isLastRow ? AppButtonVariant.success : AppButtonVariant.danger,
          backgroundColor:
              isLastRow ? _purchaseAddColor : _purchaseDeleteColor,
          foregroundColor: Colors.white,
          size: 32,
          iconSize: 19,
          borderRadius: 9,
          onPressed:
              isLastRow ? _addRow : () => widget.controller.removeRow(index),
        ),
      ],
    );
  }

  List<Widget> _summaryCells() {
    return [
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const Text('المجموع'),
      const SizedBox.shrink(),
      Text(
        AppFormatters.quantity(widget.controller.quantityTotal.round()),
        key: Key('${widget.keyPrefix}QuantityTotal'),
      ),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      Text(
        _money(widget.controller.discountTotal),
        key: Key('${widget.keyPrefix}DiscountTotal'),
      ),
      const SizedBox.shrink(),
      Text(
        _money(widget.controller.subtotal),
        key: Key('${widget.keyPrefix}Subtotal'),
      ),
      const SizedBox.shrink(),
      Text(
        _money(widget.controller.totalCost),
        key: Key('${widget.keyPrefix}TotalCost'),
      ),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
    ];
  }
}

class _PurchasePlainField extends StatelessWidget {
  const _PurchasePlainField({
    required this.fieldKey,
    required this.controller,
    required this.onChanged,
    this.numeric = false,
    this.wholeNumber = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool numeric;
  final bool wholeNumber;

  @override
  Widget build(BuildContext context) {
    final inputFormatters = numeric
        ? <TextInputFormatter>[
            if (wholeNumber)
              const AppIntegerInputFormatter()
            else
              const AppMoneyInputFormatter(),
          ]
        : null;

    return SizedBox(
      height: AppInvoiceItemsTable.cellHeight,
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: !wholeNumber)
            : TextInputType.text,
        inputFormatters: inputFormatters,
        maxLines: 1,
        textAlign: numeric ? TextAlign.center : TextAlign.right,
        textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
        cursorColor: AppColors.cursor,
        style: const TextStyle(
          color: _purchaseTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 7,
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _PurchaseValue extends StatelessWidget {
  const _PurchaseValue({
    required this.valueKey,
    required this.value,
  });

  final Key valueKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      key: valueKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
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
    return SizedBox(
      key: widget.fieldKey,
      height: AppInvoiceItemsTable.cellHeight,
      child: CompositedTransformTarget(
        key: _anchorKey,
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Icon(
                      _isOpen
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppModuleColors.purchases,
                      size: 18,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppModuleColors.purchases),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(36),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
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
    final foreground = widget.selected
        ? AppModulePalettes.purchases.dark
        : _purchaseTextColor;
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
          height: 44,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight:
                  widget.selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
