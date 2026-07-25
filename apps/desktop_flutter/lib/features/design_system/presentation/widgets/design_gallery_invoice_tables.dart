import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

const _purchaseTableCellHeight = 56.0;
const _purchaseGreen = Color(0xFF10966A);
const _purchaseGreenDark = Color(0xFF075E45);
const _purchaseGreenSoft = Color(0xFFE8F7F0);
const _purchaseTableSurface = Color(0xFFF3F7F5);
const _purchaseLine = Color(0xFFDCE9E3);
const _purchaseStrongLine = Color(0xFFB8DDCC);

class DesignGalleryInvoiceTablesSection extends StatefulWidget {
  const DesignGalleryInvoiceTablesSection({super.key});

  @override
  State<DesignGalleryInvoiceTablesSection> createState() =>
      _DesignGalleryInvoiceTablesSectionState();
}

class _DesignGalleryInvoiceTablesSectionState
    extends State<DesignGalleryInvoiceTablesSection> {
  late final List<_PurchaseDemoRow> _purchaseItems;
  final _purchaseScrollController = ScrollController();
  final _purchaseKeyHoldGuard = AppKeyHoldGuard();
  var _purchaseSeed = 3;

  @override
  void initState() {
    super.initState();
    _purchaseItems = [
      _PurchaseDemoRow(
        id: 'p1',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        warehouse: 'المخزن الرئيسي',
        quantity: '100',
        container: '10',
        purchasePrice: '2,500',
        discount: '5,000',
        salePrice: '3,000',
      ),
      _PurchaseDemoRow(
        id: 'p2',
        code: 'P-002',
        name: 'قلم أزرق',
        warehouse: 'مخزن الكرادة',
        quantity: '1,000',
        container: '20',
        purchasePrice: '1,250',
        discount: '0',
        salePrice: '1,500',
      ),
    ];
  }

  @override
  void dispose() {
    _purchaseKeyHoldGuard.dispose();
    _purchaseScrollController.dispose();
    for (final row in _purchaseItems) {
      row.dispose();
    }
    super.dispose();
  }

  void _addPurchaseItem() {
    final newRow = _PurchaseDemoRow(
      id: 'p${_purchaseSeed++}',
      code: '',
      name: '',
      warehouse: '',
      quantity: '0',
      container: '0',
      purchasePrice: '0',
      discount: '0',
      salePrice: '0',
    );

    setState(() => _purchaseItems.add(newRow));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_purchaseScrollController.hasClients) {
        _purchaseScrollController.animateTo(
          _purchaseScrollController.position.maxScrollExtent,
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        );
      }
      newRow.codeFocusNode.requestFocus();
    });
  }

  void _deletePurchaseItem(int index) {
    if (_purchaseItems.length <= 1) return;

    final removed = _purchaseItems[index];
    setState(() => _purchaseItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _refreshPurchaseTable() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جدول المشتريات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'تصميم الخلايا الناعمة المختار لجدول المشتريات. '
                'استخدم Enter أو Tab للتنقل، وEnter في آخر حقل لإضافة سطر.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PurchaseTableHeading(),
          const SizedBox(height: AppSpacing.sm),
          _SoftPurchaseTable(
            key: const Key('designPurchaseItemsTable'),
            rows: _purchaseItems,
            scrollController: _purchaseScrollController,
            keyHoldGuard: _purchaseKeyHoldGuard,
            onAddRow: _addPurchaseItem,
            onDeleteRow: _deletePurchaseItem,
            onChanged: _refreshPurchaseTable,
          ),
        ],
      ),
    );
  }
}

class _PurchaseTableHeading extends StatelessWidget {
  const _PurchaseTableHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppModulePalettes.purchases.light,
              Colors.white,
              0.72,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: AppModuleColors.purchases.withAlpha(80),
            ),
          ),
          child: const Icon(
            Icons.shopping_cart_checkout_rounded,
            color: AppModuleColors.purchases,
            size: 23,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جدول مواد المشتريات', style: AppTypography.sectionTitle),
            SizedBox(height: 2),
            Text(
              'جميع حقول مواد فاتورة المشتريات',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SoftPurchaseTable extends StatelessWidget {
  const _SoftPurchaseTable({
    super.key,
    required this.rows,
    required this.scrollController,
    required this.keyHoldGuard,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onChanged,
  });

  static const _minimumTableWidth = 1670.0;
  static const _indexWidth = 54.0;
  static const _codeWidth = 126.0;
  static const _nameWidth = 190.0;
  static const _warehouseWidth = 138.0;
  static const _quantityWidth = 104.0;
  static const _containerWidth = 104.0;
  static const _purchasePriceWidth = 126.0;
  static const _discountWidth = 104.0;
  static const _priceAfterDiscountWidth = 146.0;
  static const _totalWidth = 116.0;
  static const _costWidth = 104.0;
  static const _totalCostWidth = 132.0;
  static const _salePriceWidth = 116.0;
  static const _actionWidth = 82.0;

  final List<_PurchaseDemoRow> rows;
  final ScrollController scrollController;
  final AppKeyHoldGuard keyHoldGuard;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _minimumTableWidth
            ? _minimumTableWidth
            : constraints.maxWidth;
        final nameWidth = _nameWidth + tableWidth - _minimumTableWidth;
        final widths = _PurchaseTableWidths(
          index: _indexWidth,
          code: _codeWidth,
          name: nameWidth,
          warehouse: _warehouseWidth,
          quantity: _quantityWidth,
          container: _containerWidth,
          purchasePrice: _purchasePriceWidth,
          discount: _discountWidth,
          priceAfterDiscount: _priceAfterDiscountWidth,
          total: _totalWidth,
          cost: _costWidth,
          totalCost: _totalCostWidth,
          salePrice: _salePriceWidth,
          action: _actionWidth,
        );

        return Container(
          height: 340,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _purchaseTableSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _purchaseLine),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PurchaseTableHeader(widths: widths),
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
                              key: Key('designPurchaseRow-${row.id}'),
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
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseTableHeader extends StatelessWidget {
  const _PurchaseTableHeader({required this.widths});

  final _PurchaseTableWidths widths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('designPurchaseTableHeader'),
      height: 48,
      child: Row(
        children: [
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-index'),
            label: 'ت',
            width: widths.index,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-code'),
            label: 'رمز المادة',
            width: widths.code,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-name'),
            label: 'اسم المادة',
            width: widths.name,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-warehouse'),
            label: 'المخزن',
            width: widths.warehouse,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-quantity'),
            label: 'الكمية',
            width: widths.quantity,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-container'),
            label: 'الحاوية',
            width: widths.container,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-purchasePrice'),
            label: 'سعر الشراء',
            width: widths.purchasePrice,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-discount'),
            label: 'الخصم',
            width: widths.discount,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-priceAfterDiscount'),
            label: 'السعر بعد الخصم',
            width: widths.priceAfterDiscount,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-total'),
            label: 'الإجمالي',
            width: widths.total,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-cost'),
            label: 'الكلفة',
            width: widths.cost,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-totalCost'),
            label: 'إجمالي الكلفة',
            width: widths.totalCost,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-salePrice'),
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
    super.key,
    required this.label,
    required this.width,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purchaseLine),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.tableHeader.copyWith(
              color: _purchaseGreenDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseTableRow extends StatelessWidget {
  const _PurchaseTableRow({
    super.key,
    required this.index,
    required this.row,
    required this.widths,
    required this.keyHoldGuard,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
    required this.onLastCellSubmitted,
  });

  final int index;
  final _PurchaseDemoRow row;
  final _PurchaseTableWidths widths;
  final AppKeyHoldGuard keyHoldGuard;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback onLastCellSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          _PurchaseIndexCell(
            cellKey: Key('designPurchaseIndexCell-${row.id}'),
            value: '${index + 1}',
            width: widths.index,
            highlighted: index == 0,
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseCodeCell-${row.id}'),
            fieldKey: Key('designPurchaseCode-${row.id}'),
            controller: row.code,
            focusNode: row.codeFocusNode,
            nextFocusNode: row.nameFocusNode,
            keyHoldGuard: keyHoldGuard,
            width: widths.code,
            emphasized: true,
            onChanged: (_) => onChanged(),
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseNameCell-${row.id}'),
            fieldKey: Key('designPurchaseName-${row.id}'),
            controller: row.name,
            focusNode: row.nameFocusNode,
            nextFocusNode: row.warehouseFocusNode,
            keyHoldGuard: keyHoldGuard,
            width: widths.name,
            onChanged: (_) => onChanged(),
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseWarehouseCell-${row.id}'),
            fieldKey: Key('designPurchaseWarehouse-${row.id}'),
            controller: row.warehouse,
            focusNode: row.warehouseFocusNode,
            nextFocusNode: row.quantityFocusNode,
            keyHoldGuard: keyHoldGuard,
            width: widths.warehouse,
            onChanged: (_) => onChanged(),
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseQuantityCell-${row.id}'),
            fieldKey: Key('designPurchaseQuantity-${row.id}'),
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
            cellKey: Key('designPurchaseContainerCell-${row.id}'),
            fieldKey: Key('designPurchaseContainer-${row.id}'),
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
            cellKey: Key('designPurchasePurchasePriceCell-${row.id}'),
            fieldKey: Key('designPurchasePurchasePrice-${row.id}'),
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
            cellKey: Key('designPurchaseDiscountCell-${row.id}'),
            fieldKey: Key('designPurchaseDiscount-${row.id}'),
            controller: row.discount,
            focusNode: row.discountFocusNode,
            nextFocusNode: row.salePriceFocusNode,
            keyHoldGuard: keyHoldGuard,
            width: widths.discount,
            numeric: true,
            onChanged: (_) => onChanged(),
          ),
          _PurchaseValueCell(
            cellKey: Key('designPurchasePriceAfterDiscountCell-${row.id}'),
            valueKey: Key('designPurchasePriceAfterDiscount-${row.id}'),
            value: AppFormatters.money(row.priceAfterDiscount),
            width: widths.priceAfterDiscount,
          ),
          _PurchaseValueCell(
            cellKey: Key('designPurchaseTotalCell-${row.id}'),
            valueKey: Key('designPurchaseTotal-${row.id}'),
            value: AppFormatters.money(row.lineTotal),
            width: widths.total,
            emphasized: true,
          ),
          _PurchaseValueCell(
            cellKey: Key('designPurchaseCostCell-${row.id}'),
            valueKey: Key('designPurchaseCost-${row.id}'),
            value: AppFormatters.money(row.unitCost),
            width: widths.cost,
          ),
          _PurchaseValueCell(
            cellKey: Key('designPurchaseTotalCostCell-${row.id}'),
            valueKey: Key('designPurchaseTotalCost-${row.id}'),
            value: AppFormatters.money(row.totalCost),
            width: widths.totalCost,
            emphasized: true,
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseSalePriceCell-${row.id}'),
            fieldKey: Key('designPurchaseSalePrice-${row.id}'),
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
                  key: Key('designPurchaseDelete-${row.id}'),
                  tooltipKey: Key('designPurchaseDeleteTooltip-${row.id}'),
                  icon: Icons.close_rounded,
                  tooltip: 'حذف السطر',
                  variant: AppButtonVariant.danger,
                  size: 44,
                  iconSize: 19,
                  borderRadius: 13,
                  onPressed: canDelete ? onDelete : null,
                ),
              ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Center(
          child: Container(
            key: cellKey,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? _purchaseGreen : _purchaseGreenSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: AppTypography.tableCell.copyWith(
                color: highlighted ? Colors.white : _purchaseGreenDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
        keys: const {LogicalKeyboardKey.tab},
        action: () => AppFocusTraversal.next(context),
      );
    }

    void submit() {
      keyHoldGuard.runOnce(
        keys: const {
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  fontSize: 18,
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
                  backgroundColor: Colors.white,
                  borderColor: focused
                      ? _purchaseGreen
                      : emphasized
                          ? _purchaseStrongLine
                          : _purchaseLine,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: _PurchaseCellFrame(
          key: cellKey,
          backgroundColor: Colors.white,
          borderColor: emphasized ? _purchaseStrongLine : _purchaseLine,
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
                fontSize: 18,
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
    super.key,
    required this.backgroundColor,
    required this.child,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
  });

  final Color backgroundColor;
  final Widget child;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _purchaseTableCellHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(13),
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

class _PurchaseDemoRow {
  _PurchaseDemoRow({
    required this.id,
    required String code,
    required String name,
    required String warehouse,
    required String quantity,
    required String container,
    required String purchasePrice,
    required String discount,
    required String salePrice,
  })  : code = TextEditingController(text: code),
        name = TextEditingController(text: name),
        warehouse = TextEditingController(text: warehouse),
        quantity = TextEditingController(text: quantity),
        container = TextEditingController(text: container),
        purchasePrice = TextEditingController(text: purchasePrice),
        discount = TextEditingController(text: discount),
        salePrice = TextEditingController(text: salePrice);

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
  final TextEditingController warehouse;
  final TextEditingController quantity;
  final TextEditingController container;
  final TextEditingController purchasePrice;
  final TextEditingController discount;
  final TextEditingController salePrice;

  double get _quantityValue => _numberValue(quantity);

  double get lineTotal {
    return _quantityValue * _numberValue(purchasePrice) -
        _numberValue(discount);
  }

  double get priceAfterDiscount {
    return _quantityValue <= 0 ? 0 : lineTotal / _quantityValue;
  }

  double get totalCost => lineTotal;

  double get unitCost {
    return _quantityValue <= 0 ? 0 : totalCost / _quantityValue;
  }

  double _numberValue(TextEditingController controller) {
    return AppFormatters.parseNumber(controller.text)?.toDouble() ?? 0;
  }

  void dispose() {
    codeFocusNode.dispose();
    nameFocusNode.dispose();
    warehouseFocusNode.dispose();
    quantityFocusNode.dispose();
    containerFocusNode.dispose();
    purchasePriceFocusNode.dispose();
    discountFocusNode.dispose();
    salePriceFocusNode.dispose();
    code.dispose();
    name.dispose();
    warehouse.dispose();
    quantity.dispose();
    container.dispose();
    purchasePrice.dispose();
    discount.dispose();
    salePrice.dispose();
  }
}
