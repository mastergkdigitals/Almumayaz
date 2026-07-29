import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportSectionView extends StatefulWidget {
  const ReportSectionView({
    required this.definition,
    required this.definitions,
    required this.onDefinitionChanged,
    super.key,
  });

  final ReportDefinition definition;
  final List<ReportDefinition> definitions;
  final ValueChanged<ReportDefinition> onDefinitionChanged;

  @override
  State<ReportSectionView> createState() => _ReportSectionViewState();
}

class _ReportSectionViewState extends State<ReportSectionView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

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
          Row(
            key: Key('reportHeaderBar_$reportId'),
            children: [
              SizedBox(
                width: 360,
                child: AppDropdownField<String>(
                  fieldKey: Key('reportSelector_$reportId'),
                  label: 'التقرير',
                  icon: widget.definition.icon,
                  value: reportId,
                  options: [
                    for (final definition in widget.definitions)
                      AppDropdownOption<String>(
                        value: definition.id,
                        label: definition.title,
                      ),
                  ],
                  accentColor: _accentColor,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  menuTextDirection: TextDirection.rtl,
                  onChanged: (value) {
                    if (value == null || value == reportId) return;
                    widget.onDefinitionChanged(
                      widget.definitions.firstWhere(
                        (definition) => definition.id == value,
                      ),
                    );
                  },
                ),
              ),
              if (widget.definition.variants.length > 1) ...[
                const SizedBox(width: AppSpacing.md),
                _ReportVariantTabs(
                  reportId: reportId,
                  variants: widget.definition.variants,
                  selected: _variant,
                  accentColor: _accentColor,
                  onChanged: _changeVariant,
                ),
              ],
              const Spacer(),
              AppRegularButton(
                key: Key('reportPrintButton_$reportId'),
                label: 'طباعة',
                icon: Icons.print_rounded,
                onPressed: _printReport,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            key: Key('reportFiltersPanel_$reportId'),
            builder: (context, constraints) {
              final fieldWidth =
                  (constraints.maxWidth - AppSpacing.sm * 4) / 5;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final filter in _variant.filters)
                    _buildFilter(reportId, filter, fieldWidth),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            key: Key('reportActionBar_$reportId'),
            children: [
              SizedBox(
                width: 360,
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
              const Spacer(),
            ],
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
          const SizedBox(height: AppSpacing.sm),
          _ReportSummaryBar(
            key: Key('reportSummaryPanel_$reportId'),
            reportId: reportId,
            variantId: _variant.id,
            metrics: _variant.metrics,
            matchingCount: _visibleRows.length,
            accentColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(
    String reportId,
    ReportFilterDefinition filter,
    double width,
  ) {
    final fieldKey = Key('reportFilter_${reportId}_${filter.id}');

    return switch (filter.kind) {
      ReportFilterKind.dateRange => SizedBox(
          width: width,
          child: AppDateRangeField(
            fieldKey: fieldKey,
            label: filter.label,
            value: _dateRange,
            accentColor: _accentColor,
            onChanged: (value) => setState(() => _dateRange = value),
          ),
        ),
      ReportFilterKind.dropdown => SizedBox(
          width: width,
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

class _ReportSummaryBar extends StatelessWidget {
  const _ReportSummaryBar({
    required this.reportId,
    required this.variantId,
    required this.metrics,
    required this.matchingCount,
    required this.accentColor,
    super.key,
  });

  final String reportId;
  final String variantId;
  final List<ReportMetricDefinition> metrics;
  final int matchingCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    const iqdSuffix = ' - دينار';
    const usdSuffix = ' - دولار';
    final allMetrics = <_ReportSummaryMetricData>[
      _ReportSummaryMetricData(
        key: Key('reportMetric_${reportId}_${variantId}_matches'),
        label: 'النتائج المطابقة',
        value: '$matchingCount',
      ),
      for (var index = 0; index < metrics.length; index++)
        _ReportSummaryMetricData(
          key: Key('reportMetric_${reportId}_${variantId}_$index'),
          label: metrics[index].label,
          value: metrics[index].value,
        ),
    ];
    final generalMetrics = allMetrics
        .where(
          (metric) =>
              !metric.label.endsWith(iqdSuffix) &&
              !metric.label.endsWith(usdSuffix),
        )
        .toList(growable: false);
    final iqdMetrics = allMetrics
        .where((metric) => metric.label.endsWith(iqdSuffix))
        .map((metric) => metric.withoutSuffix(iqdSuffix))
        .toList(growable: false);
    final usdMetrics = allMetrics
        .where((metric) => metric.label.endsWith(usdSuffix))
        .map((metric) => metric.withoutSuffix(usdSuffix))
        .toList(growable: false);
    final groups = <_ReportSummaryGroupData>[
      if (generalMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'عام',
          metrics: generalMetrics,
        ),
      if (iqdMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'دينار',
          metrics: iqdMetrics,
        ),
      if (usdMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'دولار',
          metrics: usdMetrics,
        ),
    ];

    return SizedBox(
      height: 88,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: Color.lerp(
              accentColor,
              AppColors.surface,
              0.58,
            )!,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < groups.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: groups[index].flex,
                child: _ReportSummaryGroup(
                  group: groups[index],
                  accentColor: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportSummaryGroup extends StatelessWidget {
  const _ReportSummaryGroup({
    required this.group,
    required this.accentColor,
  });

  final _ReportSummaryGroupData group;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withAlpha(10),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: accentColor.withAlpha(48)),
      ),
      child: Column(
        children: [
          Text(
            group.title,
            maxLines: 1,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                for (var index = 0;
                    index < group.metrics.length;
                    index++) ...[
                  if (index > 0)
                    VerticalDivider(
                      width: AppSpacing.sm,
                      thickness: 1,
                      color: accentColor.withAlpha(34),
                    ),
                  Expanded(
                    child: _ReportSummaryMetric(
                      key: group.metrics[index].key,
                      metric: group.metrics[index],
                      accentColor: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryMetric extends StatelessWidget {
  const _ReportSummaryMetric({
    required this.metric,
    required this.accentColor,
    super.key,
  });

  final _ReportSummaryMetricData metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReportSummaryGroupData {
  const _ReportSummaryGroupData({
    required this.title,
    required this.metrics,
  });

  final String title;
  final List<_ReportSummaryMetricData> metrics;

  int get flex {
    if (metrics.length < 2) return 2;
    if (metrics.length > 5) return 5;
    return metrics.length;
  }
}

class _ReportSummaryMetricData {
  const _ReportSummaryMetricData({
    required this.key,
    required this.label,
    required this.value,
  });

  final Key key;
  final String label;
  final String value;

  _ReportSummaryMetricData withoutSuffix(String suffix) {
    return _ReportSummaryMetricData(
      key: key,
      label: label.substring(0, label.length - suffix.length),
      value: value,
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
