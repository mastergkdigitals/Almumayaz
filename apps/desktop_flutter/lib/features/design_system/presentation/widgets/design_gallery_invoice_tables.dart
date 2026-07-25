import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

const _purchaseTableCellHeight = 44.0;

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
                'تصميم أولي خفيف لجدول المشتريات بخمسة أعمدة أساسية. '
                'الزر الأخضر يضيف سطراً جديداً، والزر الأحمر يحذف السطر.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PurchaseTableHeading(),
          const SizedBox(height: AppSpacing.sm),
          _ModernPurchaseTable(
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

class _ModernPurchaseTable extends StatelessWidget {
  const _ModernPurchaseTable({
    super.key,
    required this.rows,
    required this.scrollController,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onPriceSubmitted,
  });

  static const _minimumTableWidth = 980.0;
  static const _indexWidth = 64.0;
  static const _codeWidth = 180.0;
  static const _baseNameWidth = 330.0;
  static const _quantityWidth = 140.0;
  static const _priceWidth = 180.0;
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
        final extraWidth = tableWidth - _minimumTableWidth;
        final nameWidth = _baseNameWidth + extraWidth;
        final widths = _PurchaseTableWidths(
          index: _indexWidth,
          code: _codeWidth,
          name: nameWidth,
          quantity: _quantityWidth,
          price: _priceWidth,
          action: _actionWidth,
        );

        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: Color.lerp(
                AppColors.border,
                AppModuleColors.purchases,
                0.28,
              )!,
              width: 1.2,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg - 1),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PurchaseTableHeader(widths: widths),
                    Expanded(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: rows.length > 3,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final isLast = index == rows.length - 1;
                            return _PurchaseTableRow(
                              key: Key('designPurchaseRow-${row.id}'),
                              index: index,
                              row: row,
                              widths: widths,
                              isLast: isLast,
                              onAdd: onAddRow,
                              onDelete: () => onDeleteRow(index),
                              onPriceSubmitted: () =>
                                  onPriceSubmitted(index),
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
    return Container(
      key: const Key('designPurchaseTableHeader'),
      height: 52,
      decoration: BoxDecoration(
        color: Color.lerp(
          AppModulePalettes.purchases.light,
          Colors.white,
          0.78,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppModuleColors.purchases.withAlpha(70),
          ),
        ),
      ),
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
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.tableHeader.copyWith(
          color: AppModulePalettes.purchases.dark,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PurchaseTableRow extends StatefulWidget {
  const _PurchaseTableRow({
    super.key,
    required this.index,
    required this.row,
    required this.widths,
    required this.isLast,
    required this.onAdd,
    required this.onDelete,
    required this.onPriceSubmitted,
  });

  final int index;
  final _PurchaseDemoRow row;
  final _PurchaseTableWidths widths;
  final bool isLast;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onPriceSubmitted;

  @override
  State<_PurchaseTableRow> createState() => _PurchaseTableRowState();
}

class _PurchaseTableRowState extends State<_PurchaseTableRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final background = _hovered
        ? Color.lerp(
            AppModulePalettes.purchases.light,
            Colors.white,
            0.91,
          )
        : AppColors.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 62,
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(color: AppColors.border.withAlpha(150)),
          ),
        ),
        child: Row(
          children: [
            _PurchaseIndexCell(
              value: '${widget.index + 1}',
              width: widget.widths.index,
            ),
            _PurchaseInputCell(
              fieldKey: Key('designPurchaseCode-${row.id}'),
              controller: row.code,
              focusNode: row.codeFocusNode,
              nextFocusNode: row.nameFocusNode,
              width: widget.widths.code,
            ),
            _PurchaseInputCell(
              fieldKey: Key('designPurchaseName-${row.id}'),
              controller: row.name,
              focusNode: row.nameFocusNode,
              nextFocusNode: row.quantityFocusNode,
              width: widget.widths.name,
            ),
            _PurchaseInputCell(
              fieldKey: Key('designPurchaseQuantity-${row.id}'),
              controller: row.quantity,
              focusNode: row.quantityFocusNode,
              nextFocusNode: row.priceFocusNode,
              width: widget.widths.quantity,
              numeric: true,
              wholeNumber: true,
            ),
            _PurchaseInputCell(
              fieldKey: Key('designPurchasePrice-${row.id}'),
              controller: row.price,
              focusNode: row.priceFocusNode,
              width: widget.widths.price,
              numeric: true,
              onSubmitted: widget.onPriceSubmitted,
            ),
            SizedBox(
              width: widget.widths.action,
              child: Center(
                child: AppTableActionButton(
                  key: Key(
                    widget.isLast
                        ? 'designPurchaseAdd-${row.id}'
                        : 'designPurchaseDelete-${row.id}',
                  ),
                  icon: widget.isLast
                      ? Icons.add_rounded
                      : Icons.close_rounded,
                  tooltip: widget.isLast ? 'إضافة سطر' : 'حذف السطر',
                  variant: widget.isLast
                      ? AppButtonVariant.primary
                      : AppButtonVariant.danger,
                  backgroundColor: widget.isLast
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  size: 32,
                  iconSize: 19,
                  borderRadius: 9,
                  onPressed: widget.isLast
                      ? widget.onAdd
                      : widget.onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseIndexCell extends StatelessWidget {
  const _PurchaseIndexCell({
    required this.value,
    required this.width,
  });

  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: SizedBox(
          height: _purchaseTableCellHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.neutralSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: AppTypography.tableCell.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.width,
    this.nextFocusNode,
    this.numeric = false,
    this.wholeNumber = false,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final double width;
  final bool numeric;
  final bool wholeNumber;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: SizedBox(
          height: _purchaseTableCellHeight,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            keyboardType: numeric
                ? TextInputType.numberWithOptions(decimal: !wholeNumber)
                : TextInputType.text,
            inputFormatters:
                wholeNumber ? const [AppIntegerInputFormatter()] : null,
            textInputAction: TextInputAction.next,
            textAlign: numeric ? TextAlign.center : TextAlign.right,
            textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
            style: AppTypography.tableCell.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            cursorColor: AppModuleColors.purchases,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.lerp(
                AppModulePalettes.purchases.light,
                Colors.white,
                0.94,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                borderSide: const BorderSide(
                  color: AppModuleColors.purchases,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              isDense: true,
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
