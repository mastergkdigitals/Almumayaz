import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';
import 'app_table.dart';

enum AppInvoiceTableType { purchase, sale }

class AppInvoiceItemsTable extends StatelessWidget {
  const AppInvoiceItemsTable.purchase({
    required this.rows,
    super.key,
    this.tableKey,
    this.summaryCells,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.purchase;

  const AppInvoiceItemsTable.sale({
    required this.rows,
    super.key,
    this.tableKey,
    this.summaryCells,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.sale;

  final AppInvoiceTableType type;
  final List<AppTableRow> rows;
  final List<Widget>? summaryCells;
  final Key? tableKey;
  final double height;
  final bool isLoading;

  static const headerHeight = 46.0;
  static const rowHeight = 54.0;
  static const summaryHeight = 46.0;
  static const cellHeight = 38.0;
  static const outerRadius = 18.0;
  static const cellRadius = 3.0;
  static const edgeInset = 6.0;
  static const widthSafetyBuffer = 8.0;

  static const purchaseColumns = <AppInvoiceTableColumn>[
    AppInvoiceTableColumn('ت', 54),
    AppInvoiceTableColumn('رمز المادة', 126),
    AppInvoiceTableColumn('اسم المادة', 190),
    AppInvoiceTableColumn('المخزن', 138),
    AppInvoiceTableColumn('الكمية', 104, numeric: true),
    AppInvoiceTableColumn('الحاوية', 104, numeric: true),
    AppInvoiceTableColumn('سعر الشراء', 126, numeric: true),
    AppInvoiceTableColumn('الخصم', 104, numeric: true),
    AppInvoiceTableColumn('السعر بعد الخصم', 146, numeric: true),
    AppInvoiceTableColumn('الإجمالي', 116, numeric: true),
    AppInvoiceTableColumn('الكلفة', 104, numeric: true),
    AppInvoiceTableColumn('إجمالي الكلفة', 132, numeric: true),
    AppInvoiceTableColumn('سعر البيع', 116, numeric: true),
    AppInvoiceTableColumn('', 82, action: true),
  ];

  static const saleColumns = <AppInvoiceTableColumn>[
    AppInvoiceTableColumn('ت', 54),
    AppInvoiceTableColumn('رمز المادة', 126, grow: 0.75),
    AppInvoiceTableColumn('اسم المادة', 190, grow: 3),
    AppInvoiceTableColumn('المخزن', 138, grow: 1.35),
    AppInvoiceTableColumn('الكمية', 104, numeric: true, grow: 0.70),
    AppInvoiceTableColumn('سعر البيع', 126, numeric: true, grow: 0.90),
    AppInvoiceTableColumn('الخصم', 104, numeric: true, grow: 0.70),
    AppInvoiceTableColumn(
      'السعر بعد الخصم',
      146,
      numeric: true,
      grow: 1.45,
    ),
    AppInvoiceTableColumn('الإجمالي', 116, numeric: true, grow: 1.55),
    AppInvoiceTableColumn('', 82, action: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isPurchase = type == AppInvoiceTableType.purchase;

    return _InvoiceGrid(
      key: tableKey,
      columns: isPurchase ? purchaseColumns : saleColumns,
      rows: rows,
      summaryCells: summaryCells,
      height: height,
      isLoading: isLoading,
      palette: isPurchase
          ? AppModulePalettes.purchases
          : AppModulePalettes.sales,
      expandColumns: !isPurchase,
    );
  }
}

class AppInvoiceTableColumn {
  const AppInvoiceTableColumn(
    this.label,
    this.width, {
    this.numeric = false,
    this.action = false,
    this.grow = 0,
  });

  final String label;
  final double width;
  final bool numeric;
  final bool action;
  final double grow;

  AppInvoiceTableColumn withWidth(double value) {
    return AppInvoiceTableColumn(
      label,
      value,
      numeric: numeric,
      action: action,
      grow: grow,
    );
  }
}

class _InvoiceGrid extends StatefulWidget {
  const _InvoiceGrid({
    required this.columns,
    required this.rows,
    required this.summaryCells,
    required this.height,
    required this.isLoading,
    required this.palette,
    required this.expandColumns,
    super.key,
  });

  final List<AppInvoiceTableColumn> columns;
  final List<AppTableRow> rows;
  final List<Widget>? summaryCells;
  final double height;
  final bool isLoading;
  final AppModulePalette palette;
  final bool expandColumns;

  @override
  State<_InvoiceGrid> createState() => _InvoiceGridState();
}

class _InvoiceGridState extends State<_InvoiceGrid> {
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.rows.every(
        (row) => row.cells.length == widget.columns.length,
      ),
      'Every invoice row must contain one cell for each column.',
    );
    assert(
      widget.summaryCells == null ||
          widget.summaryCells!.length == widget.columns.length,
      'The invoice summary must contain one cell for each column.',
    );

    final colors = _InvoiceGridColors(widget.palette);
    final borderRadius = BorderRadius.circular(
      AppInvoiceItemsTable.outerRadius,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseContentWidth = widget.columns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        final safeContentWidth =
            baseContentWidth +
            (AppInvoiceItemsTable.edgeInset * 2) +
            AppInvoiceItemsTable.widthSafetyBuffer;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : safeContentWidth;
        final tableWidth = math.max(availableWidth, safeContentWidth);
        final columns = widget.expandColumns
            ? _expandedColumns(widget.columns, tableWidth)
            : widget.columns;
        final occupiedWidth = columns.fold<double>(
              0,
              (sum, column) => sum + column.width,
            ) +
            (AppInvoiceItemsTable.edgeInset * 2);
        final trailingWidth = math.max<double>(
          0.0,
          tableWidth - occupiedWidth,
        );

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: colors.outerBorder,
              width: 1.4,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _horizontalScrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: widget.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InvoiceHeaderRow(
                      columns: columns,
                      trailingWidth: trailingWidth,
                      colors: colors,
                    ),
                    Expanded(
                      child: _buildBody(
                        columns: columns,
                        trailingWidth: trailingWidth,
                        colors: colors,
                      ),
                    ),
                    if (widget.summaryCells != null)
                      _InvoiceSummaryRow(
                        columns: columns,
                        cells: widget.summaryCells!,
                        trailingWidth: trailingWidth,
                        colors: colors,
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

  Widget _buildBody({
    required List<AppInvoiceTableColumn> columns,
    required double trailingWidth,
    required _InvoiceGridColors colors,
  }) {
    if (widget.isLoading) {
      return const Center(
        child: AppLoadingIndicator(size: 40, strokeWidth: 4),
      );
    }

    if (widget.rows.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مواد',
          style: TextStyle(
            color: _InvoiceGridColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _verticalScrollController,
        itemCount: widget.rows.length,
        itemExtent: AppInvoiceItemsTable.rowHeight,
        itemBuilder: (context, index) {
          return _InvoiceBodyRow(
            key: widget.rows[index].rowKey,
            columns: columns,
            row: widget.rows[index],
            trailingWidth: trailingWidth,
            colors: colors,
          );
        },
      ),
    );
  }

  List<AppInvoiceTableColumn> _expandedColumns(
    List<AppInvoiceTableColumn> columns,
    double tableWidth,
  ) {
    final baseContentWidth = columns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );
    final targetContentWidth =
        tableWidth - (AppInvoiceItemsTable.edgeInset * 2);
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
}

class _InvoiceHeaderRow extends StatelessWidget {
  const _InvoiceHeaderRow({
    required this.columns,
    required this.trailingWidth,
    required this.colors,
  });

  final List<AppInvoiceTableColumn> columns;
  final double trailingWidth;
  final _InvoiceGridColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('appInvoiceTableHeader'),
      height: AppInvoiceItemsTable.headerHeight,
      decoration: BoxDecoration(
        color: colors.header,
        border: Border(
          bottom: BorderSide(color: colors.panelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
            for (final column in columns)
              SizedBox(
                width: column.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 11,
                  ),
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _InvoiceGridColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
          ],
        ),
      ),
    );
  }
}

class _InvoiceBodyRow extends StatelessWidget {
  const _InvoiceBodyRow({
    required this.columns,
    required this.row,
    required this.trailingWidth,
    required this.colors,
    super.key,
  });

  final List<AppInvoiceTableColumn> columns;
  final AppTableRow row;
  final double trailingWidth;
  final _InvoiceGridColors colors;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      height: AppInvoiceItemsTable.rowHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: colors.panelBorder),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
            for (var index = 0; index < columns.length; index++)
              if (columns[index].action)
                _InvoiceActionCell(
                  width: columns[index].width,
                  child: row.cells[index],
                )
              else
                _InvoiceCellFrame(
                  width: columns[index].width,
                  numeric: columns[index].numeric,
                  colors: colors,
                  child: row.cells[index],
                ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
          ],
        ),
      ),
    );

    if (row.onTap == null) return body;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: row.onTap,
        child: body,
      ),
    );
  }
}

class _InvoiceCellFrame extends StatelessWidget {
  const _InvoiceCellFrame({
    required this.width,
    required this.numeric,
    required this.colors,
    required this.child,
  });

  final double width;
  final bool numeric;
  final _InvoiceGridColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('appInvoiceCellFrame'),
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cell,
            borderRadius: BorderRadius.circular(
              AppInvoiceItemsTable.cellRadius,
            ),
            border: Border.all(color: colors.cellBorder),
          ),
          child: SizedBox(
            height: AppInvoiceItemsTable.cellHeight,
            child: Center(
              child: Directionality(
                textDirection:
                    numeric ? TextDirection.ltr : TextDirection.rtl,
                child: DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _InvoiceGridColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoiceActionCell extends StatelessWidget {
  const _InvoiceActionCell({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Center(child: child),
      ),
    );
  }
}

class _InvoiceSummaryRow extends StatelessWidget {
  const _InvoiceSummaryRow({
    required this.columns,
    required this.cells,
    required this.trailingWidth,
    required this.colors,
  });

  final List<AppInvoiceTableColumn> columns;
  final List<Widget> cells;
  final double trailingWidth;
  final _InvoiceGridColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('appInvoiceTableSummary'),
      height: AppInvoiceItemsTable.summaryHeight,
      color: colors.summary,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 12,
                  ),
                  child: Center(
                    child: Directionality(
                      textDirection: columns[index].numeric
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      child: DefaultTextStyle(
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _InvoiceGridColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        child: cells[index],
                      ),
                    ),
                  ),
                ),
              ),
            if (trailingWidth > 0) SizedBox(width: trailingWidth),
            const SizedBox(width: AppInvoiceItemsTable.edgeInset),
          ],
        ),
      ),
    );
  }
}

class _InvoiceGridColors {
  const _InvoiceGridColors._({
    required this.header,
    required this.summary,
    required this.cell,
    required this.panelBorder,
    required this.outerBorder,
    required this.cellBorder,
  });

  factory _InvoiceGridColors(AppModulePalette palette) {
    final softSurface = Color.lerp(palette.light, Colors.white, 0.82)!;
    final borderTint = Color.lerp(palette.middle, Colors.white, 0.62)!;

    return _InvoiceGridColors._(
      header: softSurface,
      summary: Color.lerp(softSurface, Colors.white, 0.48)!,
      cell: Color.lerp(softSurface, Colors.white, 0.82)!,
      panelBorder: borderTint,
      outerBorder: Color.lerp(borderTint, palette.middle, 0.22)!,
      cellBorder: Color.lerp(
        const Color(0xFFE5E7EB),
        borderTint,
        0.45,
      )!,
    );
  }

  static const textPrimary = Color(0xFF111827);

  final Color header;
  final Color summary;
  final Color cell;
  final Color panelBorder;
  final Color outerBorder;
  final Color cellBorder;
}

class AppInvoiceCellField extends StatelessWidget {
  const AppInvoiceCellField({
    required this.controller,
    super.key,
    this.fieldKey,
    this.numeric = false,
    this.inputFormatters,
    this.onChanged,
    this.accentColor = AppColors.primary,
    this.textAlign,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final bool numeric;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Color accentColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppInvoiceItemsTable.cellHeight,
      child: TextField(
        key: fieldKey,
        controller: controller,
        cursorColor: AppColors.cursor,
        textAlign:
            textAlign ?? (numeric ? TextAlign.center : TextAlign.right),
        textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(
          color: _InvoiceGridColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 7,
          ),
        ),
      ),
    );
  }
}

class AppInvoiceCellDropdown extends StatefulWidget {
  const AppInvoiceCellDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.accentColor,
    super.key,
    this.fieldKey,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Color accentColor;
  final Key? fieldKey;

  @override
  State<AppInvoiceCellDropdown> createState() =>
      _AppInvoiceCellDropdownState();
}

class _AppInvoiceCellDropdownState extends State<AppInvoiceCellDropdown> {
  final _menuController = MenuController();
  var _isOpen = false;

  void _select(String value) {
    widget.onChanged(value);
    _menuController.close();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: _menuController,
          crossAxisUnconstrained: false,
          animated: false,
          onOpen: () => setState(() => _isOpen = true),
          onClose: () => setState(() => _isOpen = false),
          style: MenuStyle(
            backgroundColor:
                const WidgetStatePropertyAll<Color>(AppColors.surface),
            surfaceTintColor:
                const WidgetStatePropertyAll<Color>(Colors.transparent),
            shadowColor:
                const WidgetStatePropertyAll<Color>(AppColors.menuShadow),
            elevation: const WidgetStatePropertyAll<double>(4),
            fixedSize: WidgetStatePropertyAll<Size>(
              Size.fromWidth(constraints.maxWidth),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.all(AppSpacing.xs),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                side: BorderSide(color: widget.accentColor),
              ),
            ),
          ),
          menuChildren: [
            for (final option in widget.options)
              MenuItemButton(
                onPressed: () => _select(option),
                requestFocusOnHover: false,
                style: ButtonStyle(
                  minimumSize:
                      const WidgetStatePropertyAll<Size>(Size(0, 44)),
                  elevation: const WidgetStatePropertyAll<double>(0),
                  shadowColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                  overlayColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    option == widget.value
                        ? Color.alphaBlend(
                            widget.accentColor.withAlpha(22),
                            AppColors.surface,
                          )
                        : Colors.transparent,
                  ),
                  foregroundColor:
                      const WidgetStatePropertyAll<Color>(
                    _InvoiceGridColors.textPrimary,
                  ),
                  alignment: Alignment.center,
                ),
                child: Center(
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              key: widget.fieldKey,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              mouseCursor: SystemMouseCursors.click,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              overlayColor:
                  const WidgetStatePropertyAll<Color>(Colors.transparent),
              child: SizedBox(
                height: AppInvoiceItemsTable.cellHeight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          _isOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: widget.accentColor,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _InvoiceGridColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
