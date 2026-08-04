import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportResultsPanel extends StatelessWidget {
  const ReportResultsPanel({
    required this.reportId,
    required this.reportTitle,
    required this.variant,
    required this.rows,
    required this.selectedRowId,
    required this.accentColor,
    required this.isLoading,
    required this.tableFocusNode,
    required this.tableScrollController,
    required this.onTableKeyEvent,
    required this.onRowTap,
    required this.onRetry,
    required this.onResetFilters,
    super.key,
    this.loadError,
    this.missingReference,
  });

  final String reportId;
  final String reportTitle;
  final ReportVariantDefinition variant;
  final List<ReportRowDefinition> rows;
  final String? selectedRowId;
  final Color accentColor;
  final bool isLoading;
  final FocusNode tableFocusNode;
  final ScrollController tableScrollController;
  final KeyEventResult Function(FocusNode, KeyEvent) onTableKeyEvent;
  final ValueChanged<ReportRowDefinition> onRowTap;
  final VoidCallback onRetry;
  final VoidCallback onResetFilters;
  final String? loadError;
  final String? missingReference;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (missingReference != null) {
          return Center(
            child: AppStatePanel(
              key: Key('reportMissingReferenceState_$reportId'),
              type: AppStateType.error,
              title: 'مرجع التصفية غير متاح',
              message: missingReference!,
              actionLabel: 'مسح التصفية',
              onAction: onResetFilters,
            ),
          );
        }
        if (loadError != null) {
          return Center(
            child: AppStatePanel(
              key: Key('reportErrorState_$reportId'),
              type: AppStateType.error,
              title: 'تعذر عرض التقرير',
              message: loadError!,
              actionLabel: 'إعادة المحاولة',
              onAction: onRetry,
            ),
          );
        }

        return Semantics(
          label: 'جدول نتائج $reportTitle. استخدم الأسهم للتنقل بين الصفوف.',
          child: Focus(
            key: Key('reportTableKeyboardScope_$reportId'),
            focusNode: tableFocusNode,
            onKeyEvent: onTableKeyEvent,
            child: AppDataTable(
              key: Key('reportTable_${reportId}_${variant.id}'),
              columns: [
                for (final column in variant.columns)
                  AppTableColumn(
                    label: column.label,
                    numeric: column.numeric,
                    flex: column.flex,
                  ),
              ],
              rows: [
                for (final row in rows)
                  AppTableRow(
                    rowKey: Key(
                      'reportRow_${reportId}_${variant.id}_${row.id}',
                    ),
                    selected: selectedRowId == row.id,
                    onTap: () => onRowTap(row),
                    cells: [
                      for (final value in row.cells)
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
              ],
              height: constraints.maxHeight,
              isLoading: isLoading,
              verticalScrollController: tableScrollController,
              headerHeight: 52,
              rowHeight: 52,
              minimumColumnWidth: variant.minimumColumnWidth,
              accentColor: accentColor,
              selectedRowColor: Color.alphaBlend(
                accentColor.withAlpha(18),
                AppColors.surface,
              ),
              showShadow: false,
              emptyState: AppStatePanel(
                key: Key('reportEmptyState_$reportId'),
                type: AppStateType.empty,
                title: 'لا توجد نتائج مطابقة',
                message: 'غيّر التصفية أو عبارة البحث ثم حاول مرة أخرى.',
              ),
            ),
          ),
        );
      },
    );
  }
}
