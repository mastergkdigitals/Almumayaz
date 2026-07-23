import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_header_button.dart';
import 'app_loading_indicator.dart';

class AppTableColumn {
  const AppTableColumn({
    required this.label,
    this.numeric = false,
    this.flex = 1,
  }) : assert(flex > 0);

  final String label;
  final bool numeric;
  final double flex;
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
    this.headerHeight = 56,
    this.rowHeight = 56,
    this.minimumColumnWidth = 180,
    this.isLoading = false,
    this.emptyState,
  });

  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final double height;
  final double headerHeight;
  final double rowHeight;
  final double minimumColumnWidth;
  final bool isLoading;
  final Widget? emptyState;

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
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
    final columnWidths = <int, TableColumnWidth>{
      for (var index = 0; index < widget.columns.length; index++)
        index: FlexColumnWidth(widget.columns[index].flex),
    };

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
              : widget.minimumColumnWidth * widget.columns.length;
          final tableWidth = math.max(
            availableWidth,
            widget.minimumColumnWidth * widget.columns.length,
          );

          return SizedBox(
            height: widget.height,
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
                    children: [
                      _TableHeader(
                        columns: widget.columns,
                        columnWidths: columnWidths,
                        height: widget.headerHeight,
                      ),
                      Expanded(
                        child: _buildBody(columnWidths),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(Map<int, TableColumnWidth> columnWidths) {
    if (widget.isLoading) {
      return const Center(
        child: AppLoadingIndicator(size: 40, strokeWidth: 4),
      );
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: widget.emptyState ??
            const Text(
              'لا توجد بيانات',
              style: AppTypography.tableCell,
            ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _verticalScrollController,
        itemCount: widget.rows.length,
        itemExtent: widget.rowHeight,
        itemBuilder: (context, index) {
          return _TableBodyRow(
            columns: widget.columns,
            row: widget.rows[index],
            columnWidths: columnWidths,
            height: widget.rowHeight,
            showBottomBorder: index < widget.rows.length - 1,
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.columns,
    required this.columnWidths,
    required this.height,
  });

  final List<AppTableColumn> columns;
  final Map<int, TableColumnWidth> columnWidths;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.tableHeaderSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Table(
        textDirection: TextDirection.rtl,
        columnWidths: columnWidths,
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

class _TableBodyRow extends StatelessWidget {
  const _TableBodyRow({
    required this.columns,
    required this.row,
    required this.columnWidths,
    required this.height,
    required this.showBottomBorder,
  });

  final List<AppTableColumn> columns;
  final AppTableRow row;
  final Map<int, TableColumnWidth> columnWidths;
  final double height;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              )
            : null,
      ),
      child: Table(
        textDirection: TextDirection.rtl,
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              for (var index = 0; index < row.cells.length; index++)
                SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: Directionality(
                        textDirection: columns[index].numeric
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        child: DefaultTextStyle(
                          textAlign: TextAlign.center,
                          style: AppTypography.tableCell,
                          child: row.cells[index],
                        ),
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

class AppTableActionButton extends StatelessWidget {
  const AppTableActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.size = AppControlHeights.compact,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppTooltipIconButton(
      tooltipKey: tooltipKey,
      icon: icon,
      tooltip: tooltip,
      size: size,
      iconSize: AppIconSizes.md,
      onPressed: onPressed,
    );
  }
}
