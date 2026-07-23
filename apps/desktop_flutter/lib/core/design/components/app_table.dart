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

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.title,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPreviousPage,
    this.onNextPage,
  });

  final String? title;
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    assert(
      rows.every((row) => row.cells.length == columns.length),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(title!, style: AppTypography.sectionTitle),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                        for (final column in columns)
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
                        for (final row in rows)
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
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'الصفحة السابقة',
                  onPressed: onPreviousPage,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                Text(
                  'الصفحة $currentPage من $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  tooltip: 'الصفحة التالية',
                  onPressed: onNextPage,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
