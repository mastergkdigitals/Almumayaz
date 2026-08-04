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
    this.padding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 10,
    ),
  });

  final String label;
  final double width;
  final double grow;
  final EdgeInsetsGeometry padding;

  AppInvoiceFieldColumn withWidth(double value) {
    return AppInvoiceFieldColumn(
      label,
      value,
      grow: grow,
      padding: padding,
    );
  }
}

class AppInvoiceFieldTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final headerColor = Color.lerp(
      lightAccentColor,
      Colors.white,
      0.82,
    )!;
    final summaryColor = Color.lerp(
      headerColor,
      Colors.white,
      0.48,
    )!;
    final borderColor = Color.lerp(
      accentColor,
      Colors.white,
      0.62,
    )!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseContentWidth = columns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        final minimumWidth =
            baseContentWidth + (edgeInset * 2) + widthSafetyBuffer;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minimumWidth;
        final tableWidth =
            availableWidth > minimumWidth ? availableWidth : minimumWidth;
        final tableHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 308.0;
        final expandedColumns = _expandColumns(
          columns,
          tableWidth - (edgeInset * 2),
        );

        return Container(
          key: surfaceKey,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: SingleChildScrollView(
            key: horizontalScrollKey,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: tableHeight,
              child: Column(
                children: [
                  _InvoiceFieldTableHeader(
                    key: headerKey,
                    columns: expandedColumns,
                    color: headerColor,
                    borderColor: borderColor,
                    height: headerHeight,
                    edgeInset: edgeInset,
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Scrollbar(
                        controller: verticalScrollController,
                        child: ListView.builder(
                          key: rowsKey,
                          controller: verticalScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: rowCount,
                          itemExtent: rowHeight,
                          itemBuilder: (context, index) {
                            final cells = rowCellsBuilder(context, index);
                            assert(
                              cells.length == expandedColumns.length,
                              'Every invoice row must contain one cell '
                              'for each column.',
                            );

                            return _InvoiceFieldTableRow(
                              key: rowKeyBuilder?.call(index),
                              columns: expandedColumns,
                              cells: cells,
                              borderColor: borderColor,
                              height: rowHeight,
                              edgeInset: edgeInset,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _InvoiceFieldTableSummary(
                    key: summaryKey,
                    columns: expandedColumns,
                    cells: summaryCells,
                    color: summaryColor,
                    height: summaryHeight,
                    edgeInset: edgeInset,
                  ),
                ],
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
                child: Center(
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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
                  child: cells[index],
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
                  child: Center(
                    child: DefaultTextStyle(
                      textAlign: TextAlign.center,
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
            SizedBox(width: edgeInset),
          ],
        ),
      ),
    );
  }
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
