import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_tokens.dart';

class AppTableColumn {
  const AppTableColumn({required this.label, this.numeric = false});

  final String label;
  final bool numeric;
}

class AppTableRow {
  const AppTableRow({required this.cells});

  final List<Widget> cells;
}

class AppDataTable extends StatefulWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.height = 360,
  });

  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final double height;

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
  static const _headerHeight = 56.0;
  static const _rowHeight = 56.0;
  static const _minimumColumnWidth = 180.0;

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
      'Every table row must contain one cell for each column.',
    );

    final borderRadius = BorderRadius.circular(AppRadii.lg);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : _minimumColumnWidth * widget.columns.length;
          final tableWidth = math.max(
            availableWidth,
            _minimumColumnWidth * widget.columns.length,
          );

          return SizedBox(
            height: widget.height,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: widget.height,
                child: Column(
                  children: [
                    _TableHeader(
                      columns: widget.columns,
                      height: _headerHeight,
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _verticalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: _TableBody(
                            rows: widget.rows,
                            rowHeight: _rowHeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, required this.height});

  final List<AppTableColumn> columns;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF2FF),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Table(
        textDirection: TextDirection.rtl,
        defaultColumnWidth: const FlexColumnWidth(),
        children: [
          TableRow(
            children: [
              for (final column in columns)
                SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: Text(
                        column.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.tableHeader,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({required this.rows, required this.rowHeight});

  final List<AppTableRow> rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Table(
      textDirection: TextDirection.rtl,
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(
          color: AppColors.border,
          width: 0.8,
        ),
      ),
      children: [
        for (final row in rows)
          TableRow(
            children: [
              for (final cell in row.cells)
                SizedBox(
                  height: rowHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: DefaultTextStyle(
                        textAlign: TextAlign.center,
                        style: AppTypography.tableCell,
                        child: cell,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
