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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: widget.height,
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTableTheme(
                      data: const DataTableThemeData(
                        headingRowColor:
                            WidgetStatePropertyAll(Color(0xFFEAF2FF)),
                        headingTextStyle: AppTypography.tableHeader,
                        dataTextStyle: AppTypography.tableCell,
                        dividerThickness: 0.8,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: [
                          for (final column in widget.columns)
                            DataColumn(
                              numeric: column.numeric,
                              headingRowAlignment: MainAxisAlignment.center,
                              label: Center(
                                child: Text(
                                  column.label,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                        rows: [
                          for (final row in widget.rows)
                            DataRow(
                              cells: [
                                for (final cell in row.cells)
                                  DataCell(
                                    Align(
                                      alignment: Alignment.center,
                                      child: cell,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                        columnSpacing: AppSpacing.xl,
                        horizontalMargin: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
