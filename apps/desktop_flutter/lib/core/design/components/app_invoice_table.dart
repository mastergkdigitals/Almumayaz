import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_loading_indicator.dart';
import 'app_shortcuts.dart';
import 'app_table.dart';

enum AppInvoiceTableType { purchase, sale }

class AppInvoiceItemsTable extends StatelessWidget {
  const AppInvoiceItemsTable.purchase({
    required this.rows,
    super.key,
    this.tableKey,
    this.summaryCells,
    this.verticalScrollController,
    this.height = 308,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.purchase;

  const AppInvoiceItemsTable.sale({
    required this.rows,
    super.key,
    this.tableKey,
    this.summaryCells,
    this.verticalScrollController,
    this.height = 308,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.sale;

  final AppInvoiceTableType type;
  final List<AppTableRow> rows;
  final List<Widget>? summaryCells;
  final Key? tableKey;
  final ScrollController? verticalScrollController;
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
      verticalScrollController: verticalScrollController,
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
    required this.verticalScrollController,
    required this.height,
    required this.isLoading,
    required this.palette,
    required this.expandColumns,
    super.key,
  });

  final List<AppInvoiceTableColumn> columns;
  final List<AppTableRow> rows;
  final List<Widget>? summaryCells;
  final ScrollController? verticalScrollController;
  final double height;
  final bool isLoading;
  final AppModulePalette palette;
  final bool expandColumns;

  @override
  State<_InvoiceGrid> createState() => _InvoiceGridState();
}

class _InvoiceGridState extends State<_InvoiceGrid> {
  final _internalVerticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  ScrollController get _verticalScrollController =>
      widget.verticalScrollController ?? _internalVerticalScrollController;

  @override
  void dispose() {
    _internalVerticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _validateGridShape() {
    final invalidRowIndex = widget.rows.indexWhere(
      (row) => row.cells.length != widget.columns.length,
    );
    if (invalidRowIndex >= 0) {
      throw FlutterError(
        'Invoice row $invalidRowIndex has '
        '${widget.rows[invalidRowIndex].cells.length} cells, but '
        '${widget.columns.length} columns were provided.',
      );
    }

    final summaryCells = widget.summaryCells;
    if (summaryCells != null &&
        summaryCells.length != widget.columns.length) {
      throw FlutterError(
        'The invoice summary has ${summaryCells.length} cells, but '
        '${widget.columns.length} columns were provided.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _validateGridShape();

    final minimumHeight =
        AppInvoiceItemsTable.headerHeight +
        AppInvoiceItemsTable.rowHeight +
        (widget.summaryCells == null
            ? 0
            : AppInvoiceItemsTable.summaryHeight);
    final tableHeight = math.max<double>(
      widget.height,
      minimumHeight,
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
          height: tableHeight,
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
                height: tableHeight,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowsHeight =
            widget.rows.length * AppInvoiceItemsTable.rowHeight;

        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: rowsHeight > constraints.maxHeight,
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
      },
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
        color: row.selected ? colors.selectedRow : AppColors.surface,
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
                  selected: row.selected,
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
    required this.selected,
    required this.colors,
    required this.child,
  });

  final double width;
  final bool numeric;
  final bool selected;
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
            color: selected ? colors.selectedCell : colors.cell,
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
    required this.selectedRow,
    required this.selectedCell,
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
      selectedRow: Color.alphaBlend(
        palette.middle.withAlpha(18),
        Colors.white,
      ),
      selectedCell: Color.alphaBlend(
        palette.middle.withAlpha(28),
        Colors.white,
      ),
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
  final Color selectedRow;
  final Color selectedCell;
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
    this.focusNode,
    this.onSubmitted,
    this.keyHoldGuard,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final bool numeric;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Color accentColor;
  final TextAlign? textAlign;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final AppKeyHoldGuard? keyHoldGuard;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    void submitOnce(String value) {
      final callback = onSubmitted;
      if (callback == null) return;

      final guard = keyHoldGuard;
      if (guard == null) {
        callback(value);
        return;
      }

      guard.runOnce(
        keys: {
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
        },
        action: () => callback(value),
      );
    }

    return SizedBox(
      height: AppInvoiceItemsTable.cellHeight,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        cursorColor: AppColors.cursor,
        textAlign:
            textAlign ?? (numeric ? TextAlign.center : TextAlign.right),
        textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onEditingComplete: onSubmitted == null ? null : () {},
        onSubmitted: onSubmitted == null ? null : submitOnce,
        textInputAction: textInputAction,
        style: const TextStyle(
          color: _InvoiceGridColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppInvoiceItemsTable.cellRadius,
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppInvoiceItemsTable.cellRadius,
            ),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppInvoiceItemsTable.cellRadius,
            ),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppInvoiceItemsTable.cellRadius,
            ),
            borderSide: BorderSide.none,
          ),
          filled: !enabled || readOnly,
          fillColor: !enabled || readOnly
              ? AppColors.disabledSurface
              : Colors.transparent,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(
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
    this.focusNode,
    this.onSubmitted,
    this.keyHoldGuard,
    this.enabled = true,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Color accentColor;
  final Key? fieldKey;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final AppKeyHoldGuard? keyHoldGuard;
  final bool enabled;

  @override
  State<AppInvoiceCellDropdown> createState() =>
      _AppInvoiceCellDropdownState();
}

class _AppInvoiceCellDropdownState extends State<AppInvoiceCellDropdown> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _menuController = MenuController();
  final _internalFocusNode = FocusNode();
  AppKeyHoldGuard? _internalKeyHoldGuard;
  late List<FocusNode> _itemFocusNodes;
  var _isOpen = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;
  AppKeyHoldGuard get _keyHoldGuard =>
      widget.keyHoldGuard ??
      (_internalKeyHoldGuard ??= AppKeyHoldGuard());

  void _ignoreHorizontalNavigation() {}

  void _replaceItemFocusNodes() {
    for (final focusNode in _itemFocusNodes) {
      focusNode.dispose();
    }
    _itemFocusNodes = List.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
  }

  void _openMenu(MenuController controller) {
    controller.open();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.isOpen || _itemFocusNodes.isEmpty) return;

      final selectedIndex = widget.options.indexOf(widget.value);
      _itemFocusNodes[selectedIndex < 0 ? 0 : selectedIndex].requestFocus();
    });
  }

  void _toggleMenu(MenuController controller) {
    if (controller.isOpen) {
      controller.close();
    } else {
      _openMenu(controller);
    }
  }

  void _toggleMenuOnce(MenuController controller) {
    if (!widget.enabled) return;
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _toggleMenu(controller),
    );
  }

  void _selectOnce(String value) {
    if (!widget.enabled) return;
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _select(value),
    );
  }

  void _select(String value) {
    final submittedWithEnter = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.enter) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.numpadEnter);

    widget.onChanged(value);
    _menuController.close();

    if (!submittedWithEnter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSubmitted?.call(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _itemFocusNodes = List.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
  }

  @override
  void didUpdateWidget(covariant AppInvoiceCellDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      _replaceItemFocusNodes();
    }
  }

  @override
  void dispose() {
    for (final focusNode in _itemFocusNodes) {
      focusNode.dispose();
    }
    _internalKeyHoldGuard?.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: _menuController,
          childFocusNode: _focusNode,
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
          menuChildren: widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    () => _selectOnce(option),
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    () => _selectOnce(option),
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    _ignoreHorizontalNavigation,
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    _ignoreHorizontalNavigation,
              },
              child: MenuItemButton(
                focusNode: _itemFocusNodes[index],
                onPressed: widget.enabled ? () => _select(option) : null,
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
            );
          }).toList(growable: false),
          builder: (context, controller, child) {
            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    () => _toggleMenuOnce(controller),
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    () => _toggleMenuOnce(controller),
              },
              child: Semantics(
                button: true,
                enabled: widget.enabled,
                value: widget.value,
                child: InkWell(
                  key: widget.fieldKey,
                  focusNode: _focusNode,
                  onTap: widget.enabled
                      ? () => _toggleMenu(controller)
                      : null,
                  mouseCursor: widget.enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
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
                              color: widget.enabled
                                  ? widget.accentColor
                                  : AppColors.disabled,
                              size: 18,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.enabled
                                    ? _InvoiceGridColors.textPrimary
                                    : AppColors.disabled,
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AppInvoiceValueText extends StatelessWidget {
  const AppInvoiceValueText(
    this.value, {
    super.key,
    this.textAlign = TextAlign.center,
  });

  final String value;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        softWrap: false,
        textAlign: textAlign,
      ),
    );
  }
}
