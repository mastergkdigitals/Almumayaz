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
const _purchaseDanger = Color(0xFFD94A4A);

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
  var _purchaseSeed = 3;

  @override
  void initState() {
    super.initState();
    _purchaseItems = [
      _PurchaseDemoRow(
        id: 'p1',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        quantity: '100',
        price: '2,500',
      ),
      _PurchaseDemoRow(
        id: 'p2',
        code: 'P-002',
        name: 'قلم أزرق',
        quantity: '1,000',
        price: '1,250',
      ),
    ];
  }

  @override
  void dispose() {
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
      quantity: '0',
      price: '0',
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
    final removed = _purchaseItems[index];
    setState(() => _purchaseItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _focusAfterPrice(int index) {
    if (index < _purchaseItems.length - 1) {
      _purchaseItems[index + 1].codeFocusNode.requestFocus();
      return;
    }
    _addPurchaseItem();
  }

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
                'يمكنك الكتابة داخل الخلايا وإضافة الصفوف أو حذفها.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PurchaseTableHeading(),
          const SizedBox(height: AppSpacing.sm),
          _SoftPurchaseTable(
            key: const Key('designPurchaseItemsTable'),
            rows: _purchaseItems,
            scrollController: _purchaseScrollController,
            onAddRow: _addPurchaseItem,
            onDeleteRow: _deletePurchaseItem,
            onPriceSubmitted: _focusAfterPrice,
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
              'الحقول الأساسية لإدخال مواد الفاتورة',
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
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onPriceSubmitted,
  });

  static const _minimumTableWidth = 920.0;
  static const _indexWidth = 64.0;
  static const _codeWidth = 170.0;
  static const _quantityWidth = 130.0;
  static const _priceWidth = 170.0;
  static const _actionWidth = 82.0;

  final List<_PurchaseDemoRow> rows;
  final ScrollController scrollController;
  final VoidCallback onAddRow;
  final ValueChanged<int> onDeleteRow;
  final ValueChanged<int> onPriceSubmitted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _minimumTableWidth
            ? _minimumTableWidth
            : constraints.maxWidth;
        final contentWidth = tableWidth - 28;
        final nameWidth = contentWidth -
            _indexWidth -
            _codeWidth -
            _quantityWidth -
            _priceWidth -
            _actionWidth;
        final widths = _PurchaseTableWidths(
          index: _indexWidth,
          code: _codeWidth,
          name: nameWidth,
          quantity: _quantityWidth,
          price: _priceWidth,
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
                              onDelete: () => onDeleteRow(index),
                              onPriceSubmitted: () =>
                                  onPriceSubmitted(index),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PurchaseAddButton(
                        key: const Key('designPurchaseAdd'),
                        onPressed: onAddRow,
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
            key: const Key('designPurchaseHeader-quantity'),
            label: 'الكمية',
            width: widths.quantity,
          ),
          _PurchaseHeaderCell(
            key: const Key('designPurchaseHeader-price'),
            label: 'السعر',
            width: widths.price,
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
    required this.onDelete,
    required this.onPriceSubmitted,
  });

  final int index;
  final _PurchaseDemoRow row;
  final _PurchaseTableWidths widths;
  final VoidCallback onDelete;
  final VoidCallback onPriceSubmitted;

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
            width: widths.code,
            emphasized: true,
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseNameCell-${row.id}'),
            fieldKey: Key('designPurchaseName-${row.id}'),
            controller: row.name,
            focusNode: row.nameFocusNode,
            nextFocusNode: row.quantityFocusNode,
            width: widths.name,
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchaseQuantityCell-${row.id}'),
            fieldKey: Key('designPurchaseQuantity-${row.id}'),
            controller: row.quantity,
            focusNode: row.quantityFocusNode,
            nextFocusNode: row.priceFocusNode,
            width: widths.quantity,
            numeric: true,
            wholeNumber: true,
          ),
          _PurchaseInputCell(
            cellKey: Key('designPurchasePriceCell-${row.id}'),
            fieldKey: Key('designPurchasePrice-${row.id}'),
            controller: row.price,
            focusNode: row.priceFocusNode,
            width: widths.price,
            numeric: true,
            emphasized: true,
            onSubmitted: onPriceSubmitted,
          ),
          SizedBox(
            width: widths.action,
            child: Center(
              child: _PurchaseDeleteButton(
                key: Key('designPurchaseDelete-${row.id}'),
                onPressed: onDelete,
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
    required this.width,
    this.nextFocusNode,
    this.numeric = false,
    this.wholeNumber = false,
    this.emphasized = false,
    this.onSubmitted,
  });

  final Key cellKey;
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final double width;
  final bool numeric;
  final bool wholeNumber;
  final bool emphasized;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: AnimatedBuilder(
          animation: focusNode,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
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
                  textDirection:
                      numeric ? TextDirection.ltr : TextDirection.rtl,
                  style: AppTypography.tableCell.copyWith(
                    color: emphasized
                        ? _purchaseGreenDark
                        : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: Colors.black,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    filled: false,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    final submit = onSubmitted;
                    if (submit != null) {
                      submit();
                      return;
                    }
                    nextFocusNode?.requestFocus();
                  },
                ),
              ],
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

class _PurchaseDeleteButton extends StatelessWidget {
  const _PurchaseDeleteButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'حذف السطر',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: const BorderSide(color: Color(0xFFE8C8C8)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.close_rounded,
              color: _purchaseDanger,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseAddButton extends StatelessWidget {
  const _PurchaseAddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _purchaseGreen,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 19),
              SizedBox(width: 7),
              Text(
                'إضافة مادة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseTableWidths {
  const _PurchaseTableWidths({
    required this.index,
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
    required this.action,
  });

  final double index;
  final double code;
  final double name;
  final double quantity;
  final double price;
  final double action;
}

class _PurchaseDemoRow {
  _PurchaseDemoRow({
    required this.id,
    required String code,
    required String name,
    required String quantity,
    required String price,
  })  : code = TextEditingController(text: code),
        name = TextEditingController(text: name),
        quantity = TextEditingController(text: quantity),
        price = TextEditingController(text: price);

  final String id;
  final codeFocusNode = FocusNode();
  final nameFocusNode = FocusNode();
  final quantityFocusNode = FocusNode();
  final priceFocusNode = FocusNode();
  final TextEditingController code;
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController price;

  void dispose() {
    codeFocusNode.dispose();
    nameFocusNode.dispose();
    quantityFocusNode.dispose();
    priceFocusNode.dispose();
    code.dispose();
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}
