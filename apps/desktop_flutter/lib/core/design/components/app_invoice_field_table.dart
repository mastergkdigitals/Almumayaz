import 'package:flutter/material.dart';

import '../app_tokens.dart';

typedef AppInvoiceFieldRowCellsBuilder =
    List<Widget> Function(BuildContext context, int index);

typedef AppInvoiceFieldRowKeyBuilder = Key? Function(int index);

@immutable
class AppInvoiceFieldColumn {
  const AppInvoiceFieldColumn(
    this.label,
    this.width, {
    this.grow = 0,
    this.textDirection,
    this.textAlign,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 10,
    ),
  });

  final String label;
  final double width;
  final double grow;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry padding;

  TextDirection get effectiveTextDirection =>
      textDirection ?? TextDirection.rtl;

  AppInvoiceFieldColumn withWidth(double value) {
    return AppInvoiceFieldColumn(
      label,
      value,
      grow: grow,
      textDirection: textDirection,
      textAlign: textAlign,
      padding: padding,
    );
  }
}

class AppInvoiceFieldTable extends StatefulWidget {
  const AppInvoiceFieldTable({
    required this.columns,
    required this.rowCount,
    required this.rowCellsBuilder,
    required this.summaryCells,
    required this.accentColor,
    required this.lightAccentColor,
    required this.verticalScrollController,
    super.key,
    this.surfaceKey,
    this.horizontalScrollKey,
    this.rowsKey,
    this.headerKey,
    this.summaryKey,
    this.rowKeyBuilder,
    this.headerHeight = 46,
    this.rowHeight = 80,
    this.summaryHeight = 46,
    this.edgeInset = 6,
    this.widthSafetyBuffer = 12,
    this.outerRadius = AppRadii.lg,
  })  : assert(columns.length == summaryCells.length),
        assert(rowCount >= 0);

  final List<AppInvoiceFieldColumn> columns;
  final int rowCount;
  final AppInvoiceFieldRowCellsBuilder rowCellsBuilder;
  final List<Widget> summaryCells;
  final Color accentColor;
  final Color lightAccentColor;
  final ScrollController verticalScrollController;
  final Key? surfaceKey;
  final Key? horizontalScrollKey;
  final Key? rowsKey;
  final Key? headerKey;
  final Key? summaryKey;
  final AppInvoiceFieldRowKeyBuilder? rowKeyBuilder;
  final double headerHeight;
  final double rowHeight;
  final double summaryHeight;
  final double edgeInset;
  final double widthSafetyBuffer;
  final double outerRadius;

  @override
  State<AppInvoiceFieldTable> createState() =>
      _AppInvoiceFieldTableState();
}

class _AppInvoiceFieldTableState extends State<AppInvoiceFieldTable> {
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = Color.lerp(
      widget.lightAccentColor,
      Colors.white,
      0.82,
    )!;
    final summaryColor = Color.lerp(
      headerColor,
      Colors.white,
      0.48,
    )!;
    final borderColor = Color.lerp(
      widget.accentColor,
      Colors.white,
      0.62,
    )!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseContentWidth = widget.columns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        final minimumWidth = baseContentWidth +
            (widget.edgeInset * 2) +
            widget.widthSafetyBuffer;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minimumWidth;
        final tableWidth =
            availableWidth > minimumWidth ? availableWidth : minimumWidth;
        final tableHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 308.0;
        final expandedColumns = _expandColumns(
          widget.columns,
          tableWidth - (widget.edgeInset * 2),
        );

        return Container(
          key: widget.surfaceKey,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(widget.outerRadius),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.outerRadius),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: widget.horizontalScrollKey,
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: tableHeight,
                child: Column(
                  children: [
                    _InvoiceFieldTableHeader(
                      key: widget.headerKey,
                      columns: expandedColumns,
                      color: headerColor,
                      borderColor: borderColor,
                      height: widget.headerHeight,
                      edgeInset: widget.edgeInset,
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: Scrollbar(
                          controller: widget.verticalScrollController,
                          child: ListView.builder(
                            key: widget.rowsKey,
                            controller: widget.verticalScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: widget.rowCount,
                            itemExtent: widget.rowHeight,
                            itemBuilder: (context, index) {
                              final cells =
                                  widget.rowCellsBuilder(context, index);
                              assert(
                                cells.length == expandedColumns.length,
                                'Every invoice row must contain one cell '
                                'for each column.',
                              );

                              return _InvoiceFieldTableRow(
                                key: widget.rowKeyBuilder?.call(index),
                                columns: expandedColumns,
                                cells: cells,
                                borderColor: borderColor,
                                height: widget.rowHeight,
                                edgeInset: widget.edgeInset,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _InvoiceFieldTableSummary(
                      key: widget.summaryKey,
                      columns: expandedColumns,
                      cells: widget.summaryCells,
                      color: summaryColor,
                      height: widget.summaryHeight,
                      edgeInset: widget.edgeInset,
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

class _InvoiceFieldTableHeader extends StatelessWidget {
  const _InvoiceFieldTableHeader({
    required this.columns,
    required this.color,
    required this.borderColor,
    required this.height,
    required this.edgeInset,
    super.key,
  });

  final List<AppInvoiceFieldColumn> columns;
  final Color color;
  final Color borderColor;
  final double height;
  final double edgeInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            SizedBox(width: edgeInset),
            for (final column in columns)
              SizedBox(
                width: column.width,
                child: Directionality(
                  textDirection: column.effectiveTextDirection,
                  child: Align(
                    alignment: _invoiceAlignmentForTextAlign(
                      column.textAlign ?? TextAlign.center,
                    ),
                    child: Text(
                      column.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: column.textAlign ?? TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(width: edgeInset),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFieldTableRow extends StatelessWidget {
  const _InvoiceFieldTableRow({
    required this.columns,
    required this.cells,
    required this.borderColor,
    required this.height,
    required this.edgeInset,
    super.key,
  });

  final List<AppInvoiceFieldColumn> columns;
  final List<Widget> cells;
  final Color borderColor;
  final double height;
  final double edgeInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            SizedBox(width: edgeInset),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Padding(
                  padding: columns[index].padding,
                  child: Directionality(
                    textDirection:
                        columns[index].effectiveTextDirection,
                    child: columns[index].textAlign == null
                        ? cells[index]
                        : Align(
                            alignment: _invoiceAlignmentForTextAlign(
                              columns[index].textAlign!,
                            ),
                            child: DefaultTextStyle.merge(
                              textAlign: columns[index].textAlign,
                              child: cells[index],
                            ),
                          ),
                  ),
                ),
              ),
            SizedBox(width: edgeInset),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFieldTableSummary extends StatelessWidget {
  const _InvoiceFieldTableSummary({
    required this.columns,
    required this.cells,
    required this.color,
    required this.height,
    required this.edgeInset,
    super.key,
  });

  final List<AppInvoiceFieldColumn> columns;
  final List<Widget> cells;
  final Color color;
  final double height;
  final double edgeInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            SizedBox(width: edgeInset),
            for (var index = 0; index < columns.length; index++)
              SizedBox(
                width: columns[index].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Directionality(
                    textDirection:
                        columns[index].effectiveTextDirection,
                    child: Align(
                      alignment: _invoiceAlignmentForTextAlign(
                        columns[index].textAlign ?? TextAlign.center,
                      ),
                      child: DefaultTextStyle(
                        textAlign:
                            columns[index].textAlign ?? TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        child: cells[index],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(width: edgeInset),
          ],
        ),
      ),
    );
  }
}

AlignmentGeometry _invoiceAlignmentForTextAlign(TextAlign textAlign) {
  return switch (textAlign) {
    TextAlign.left => Alignment.centerLeft,
    TextAlign.right => Alignment.centerRight,
    TextAlign.start => AlignmentDirectional.centerStart,
    TextAlign.end => AlignmentDirectional.centerEnd,
    TextAlign.center => Alignment.center,
    TextAlign.justify => Alignment.center,
  };
}

List<AppInvoiceFieldColumn> _expandColumns(
  List<AppInvoiceFieldColumn> columns,
  double targetWidth,
) {
  final baseWidth = columns.fold<double>(
    0,
    (sum, column) => sum + column.width,
  );
  final extraWidth = targetWidth - baseWidth;
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
