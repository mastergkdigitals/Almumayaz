import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportSectionView extends StatefulWidget {
  const ReportSectionView({
    required this.definition,
    super.key,
  });

  final ReportDefinition definition;

  @override
  State<ReportSectionView> createState() => _ReportSectionViewState();
}

class _ReportSectionViewState extends State<ReportSectionView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _filtersScrollController = ScrollController();
  final _metricsScrollController = ScrollController();

  late ReportVariantDefinition _variant;
  DateTimeRange? _dateRange;
  Map<String, String> _dropdownValues = {};
  String? _selectedRowId;

  Color get _accentColor => widget.definition.palette.middle;

  @override
  void initState() {
    super.initState();
    _variant = widget.definition.variants.first;
    _dropdownValues = _defaultDropdownValues(_variant);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filtersScrollController.dispose();
    _metricsScrollController.dispose();
    super.dispose();
  }

  Map<String, String> _defaultDropdownValues(
    ReportVariantDefinition variant,
  ) {
    return {
      for (final filter in variant.filters)
        if (filter.kind == ReportFilterKind.dropdown)
          filter.id: filter.options.first.value,
    };
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
  }

  void _changeVariant(ReportVariantDefinition variant) {
    if (variant.id == _variant.id) return;
    _searchController.clear();
    setState(() {
      _variant = variant;
      _dateRange = null;
      _dropdownValues = _defaultDropdownValues(variant);
      _selectedRowId = null;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _dateRange = null;
      _dropdownValues = _defaultDropdownValues(_variant);
      _selectedRowId = null;
    });
    AppToast.showWarning(context, 'تم مسح تصفية التقرير');
  }

  void _showReport() {
    FocusManager.instance.primaryFocus?.unfocus();
    AppToast.showInfo(
      context,
      'تم عرض ${_visibleRows.length} نتيجة تجريبية',
    );
  }

  void _printReport() {
    FocusManager.instance.primaryFocus?.unfocus();
    AppToast.showInfo(
      context,
      'تم تجهيز معاينة طباعة ${widget.definition.title}',
    );
  }

  List<ReportRowDefinition> get _visibleRows {
    final query = _searchController.text.trim();

    return _variant.rows.where((row) {
      if (_dateRange != null) {
        final date = row.date;
        if (date == null ||
            date.isBefore(_dateRange!.start) ||
            date.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      for (final filter in _variant.filters) {
        if (filter.kind != ReportFilterKind.dropdown) continue;
        final selectedValue = _dropdownValues[filter.id];
        if (selectedValue == null || selectedValue == 'all') continue;
        final rowValues =
            (row.filterValues[filter.id] ?? '').split('|');
        if (!rowValues.contains('all') &&
            !rowValues.contains(selectedValue)) {
          return false;
        }
      }

      return row.matchesSearch(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final reportId = widget.definition.id;

    return AppShortcutScope(
      onSearch: _focusSearch,
      child: Column(
        key: Key('reportContent_$reportId'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportTemplatePanel(
            key: Key('reportFiltersPanel_$reportId'),
            title: 'تصفية التقرير',
            icon: Icons.filter_alt_rounded,
            accentColor: _accentColor,
            actions: widget.definition.variants.length > 1
                ? [
                    _ReportVariantTabs(
                      reportId: reportId,
                      variants: widget.definition.variants,
                      selected: _variant,
                      accentColor: _accentColor,
                      onChanged: _changeVariant,
                    ),
                  ]
                : const [],
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  Expanded(
                    child: Scrollbar(
                      controller: _filtersScrollController,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: _filtersScrollController,
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (final filter in _variant.filters) ...[
                              _buildFilter(reportId, filter),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 240,
                    child: AppSearchField(
                      fieldKey: Key('reportSearch_$reportId'),
                      clearButtonKey: Key('reportSearchClear_$reportId'),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      label: 'بحث في النتائج',
                      hint: 'رقم أو اسم',
                      accentColor: _accentColor,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _showReport(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    key: Key('reportShowButton_$reportId'),
                    label: 'عرض التقرير',
                    icon: Icons.assessment_rounded,
                    variant: AppButtonVariant.primary,
                    backgroundColor: _accentColor,
                    minWidth: 142,
                    height: AppRegularButton.defaultHeight,
                    onPressed: _showReport,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppRegularButton(
                    key: Key('reportResetButton_$reportId'),
                    label: 'مسح التصفية',
                    icon: Icons.filter_alt_off_rounded,
                    onPressed: _resetFilters,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppRegularButton(
                    key: Key('reportPrintButton_$reportId'),
                    label: 'طباعة',
                    icon: Icons.print_rounded,
                    onPressed: _printReport,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReportTemplatePanel(
            key: Key('reportSummaryPanel_$reportId'),
            title: 'الملخص العام للبيانات التجريبية',
            icon: Icons.summarize_rounded,
            accentColor: _accentColor,
            child: SizedBox(
              height: 66,
              child: Scrollbar(
                controller: _metricsScrollController,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: _metricsScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      _ReportMetricTile(
                        key: Key(
                          'reportMetric_${reportId}_${_variant.id}_matches',
                        ),
                        metric: ReportMetricDefinition(
                          label: 'النتائج المطابقة',
                          value: '${_visibleRows.length}',
                        ),
                        accentColor: _accentColor,
                      ),
                      for (var index = 0;
                          index < _variant.metrics.length;
                          index++) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _ReportMetricTile(
                          key: Key(
                            'reportMetric_${reportId}_${_variant.id}_$index',
                          ),
                          metric: _variant.metrics[index],
                          accentColor: _accentColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AppDataTable(
                  key: Key('reportTable_${reportId}_${_variant.id}'),
                  columns: [
                    for (final column in _variant.columns)
                      AppTableColumn(
                        label: column.label,
                        numeric: column.numeric,
                        flex: column.flex,
                      ),
                  ],
                  rows: [
                    for (final row in _visibleRows)
                      AppTableRow(
                        rowKey: Key(
                          'reportRow_${reportId}_${_variant.id}_${row.id}',
                        ),
                        selected: _selectedRowId == row.id,
                        onTap: () {
                          setState(() {
                            _selectedRowId =
                                _selectedRowId == row.id ? null : row.id;
                          });
                        },
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
                  headerHeight: 52,
                  rowHeight: 52,
                  minimumColumnWidth: _variant.minimumColumnWidth,
                  accentColor: _accentColor,
                  selectedRowColor: Color.alphaBlend(
                    _accentColor.withAlpha(18),
                    AppColors.surface,
                  ),
                  showShadow: false,
                  emptyState: _ReportEmptyState(
                    accentColor: _accentColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(
    String reportId,
    ReportFilterDefinition filter,
  ) {
    final fieldKey = Key('reportFilter_${reportId}_${filter.id}');

    return switch (filter.kind) {
      ReportFilterKind.dateRange => SizedBox(
          width: 310,
          child: AppDateRangeField(
            fieldKey: fieldKey,
            label: filter.label,
            value: _dateRange,
            accentColor: _accentColor,
            onChanged: (value) => setState(() => _dateRange = value),
          ),
        ),
      ReportFilterKind.dropdown => SizedBox(
          width: 220,
          child: AppDropdownField<String>(
            fieldKey: fieldKey,
            label: filter.label,
            icon: filter.icon,
            value: _dropdownValues[filter.id],
            options: [
              for (final option in filter.options)
                AppDropdownOption<String>(
                  value: option.value,
                  label: option.label,
                ),
            ],
            accentColor: _accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              setState(() {
                _dropdownValues[filter.id] =
                    value ?? filter.options.first.value;
              });
            },
          ),
        ),
    };
  }
}

class ReportTemplatePanel extends StatelessWidget {
  const ReportTemplatePanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    super.key,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadii.lg);
    final borderColor = Color.lerp(
      accentColor,
      AppColors.surface,
      0.62,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Color.alphaBlend(
                  accentColor.withAlpha(14),
                  AppColors.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          accentColor.withAlpha(24),
                          AppColors.surface,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: accentColor.withAlpha(90),
                        ),
                      ),
                      child: Icon(icon, color: accentColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportVariantTabs extends StatelessWidget {
  const _ReportVariantTabs({
    required this.reportId,
    required this.variants,
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  final String reportId;
  final List<ReportVariantDefinition> variants;
  final ReportVariantDefinition selected;
  final Color accentColor;
  final ValueChanged<ReportVariantDefinition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < variants.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            AppButton(
              key: Key(
                'reportVariantTab_${reportId}_${variants[index].id}',
              ),
              label: variants[index].label,
              icon: variants[index].icon,
              variant: variants[index].id == selected.id
                  ? AppButtonVariant.primary
                  : AppButtonVariant.navigation,
              backgroundColor:
                  variants[index].id == selected.id ? accentColor : null,
              minWidth: 154,
              height: AppControlHeights.compact,
              onPressed: () => onChanged(variants[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({
    required this.metric,
    required this.accentColor,
    super.key,
  });

  final ReportMetricDefinition metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withAlpha(10),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: Color.lerp(
            accentColor,
            AppColors.surface,
            0.68,
          )!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  const _ReportEmptyState({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: AppIconSizes.xl,
          color: accentColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'لا توجد نتائج مطابقة',
          style: AppTypography.tableCell,
        ),
      ],
    );
  }
}
