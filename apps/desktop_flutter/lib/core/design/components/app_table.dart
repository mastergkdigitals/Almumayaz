import 'package:flutter/material.dart';

import '../app_tokens.dart';

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
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
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
                      columns: columns,
                      rows: rows,
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
