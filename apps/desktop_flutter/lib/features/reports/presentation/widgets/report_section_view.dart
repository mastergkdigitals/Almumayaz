import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../application/report_output_service.dart';
import '../../application/report_rows_service.dart';
import '../../application/report_summary_calculator.dart';
import '../report_definition.dart';
import 'report_output_result_dialog.dart';
import 'report_summary_bar.dart';

class ReportSectionView extends StatefulWidget {
  const ReportSectionView({
    required this.definition,
    required this.definitions,
    required this.onDefinitionChanged,
    super.key,
    this.rowsService = const DemoReportRowsService(),
    this.printService = const DemoReportOutputService(),
    this.exportService = const DemoReportOutputService(),
  });

  final ReportDefinition definition;
  final List<ReportDefinition> definitions;
  final ValueChanged<ReportDefinition> onDefinitionChanged;
  final ReportRowsService rowsService;
  final ReportPrintService printService;
  final ReportExportService exportService;

  @override
  State<ReportSectionView> createState() => _ReportSectionViewState();
}

class _ReportSectionViewState extends State<ReportSectionView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _tableFocusNode = FocusNode(debugLabel: 'reportTable');
  final _tableScrollController = ScrollController();

  late ReportVariantDefinition _variant;
  late List<ReportRowDefinition> _loadedRows;
  DateTimeRange? _dateRange;
  Map<String, String> _dropdownValues = {};
  String? _selectedRowId;
  bool _isLoading = false;
  String? _loadError;
  ReportOutputAction? _activeOutput;

  Color get _accentColor => widget.definition.palette.middle;

  @override
  void initState() {
    super.initState();
    _variant = widget.definition.variants.first;
    _loadedRows = _variant.rows;
    _dropdownValues = _defaultDropdownValues(_variant);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tableFocusNode.dispose();
    _tableScrollController.dispose();
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
      _loadedRows = variant.rows;
      _dateRange = null;
      _dropdownValues = _defaultDropdownValues(variant);
      _selectedRowId = null;
      _loadError = null;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _dateRange = null;
      _dropdownValues = _defaultDropdownValues(_variant);
      _selectedRowId = null;
      _loadError = null;
    });
    AppToast.showWarning(context, 'تم مسح تصفية التقرير');
  }

  Future<void> _showReport() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _selectedRowId = null;
    });
    final requestedVariant = _variant;
    try {
      final rows = await widget.rowsService.load(
        ReportRowsRequest(
          reportId: widget.definition.id,
          variantId: requestedVariant.id,
          demoRows: requestedVariant.rows,
        ),
      );
      if (!mounted || _variant.id != requestedVariant.id) return;
      setState(() => _loadedRows = rows);
      _tableFocusNode.requestFocus();
      AppToast.showInfo(
        context,
        'تم عرض ${_visibleRows.length} نتيجة تجريبية',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل بيانات التقرير التجريبية';
      });
      AppToast.showError(context, _loadError!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runOutput(ReportOutputAction action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_activeOutput != null) return;
    final rows = _visibleRows;
    if (rows.isEmpty) {
      AppToast.showWarning(context, 'لا توجد نتائج لتجهيزها');
      return;
    }

    if (action == ReportOutputAction.printPreview) {
      AppToast.showInfo(
        context,
        'تم تجهيز معاينة طباعة ${widget.definition.title}',
      );
    }
    setState(() => _activeOutput = action);
    final request = ReportOutputRequest(
      reportTitle: widget.definition.title,
      variantLabel: _variant.label,
      columnLabels: [
        for (final column in _variant.columns) column.label,
      ],
      rowValues: [
        for (final row in rows) row.cells,
      ],
      metrics: {
        for (final metric in _calculatedMetrics)
          metric.label: metric.value,
      },
    );
    try {
      final result = switch (action) {
        ReportOutputAction.printPreview =>
          await widget.printService.createPreview(request),
        ReportOutputAction.pdf => await widget.exportService.export(
            request,
            ReportExportFormat.pdf,
          ),
        ReportOutputAction.excel => await widget.exportService.export(
            request,
            ReportExportFormat.excel,
          ),
      };
      if (!mounted) return;
      setState(() => _activeOutput = null);
      await _showOutputResult(result, action);
    } on ReportOutputException catch (error) {
      if (!mounted) return;
      setState(() => _activeOutput = null);
      AppToast.showError(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeOutput = null);
      AppToast.showError(context, 'تعذر تجهيز مخرجات التقرير');
    }
  }

  Future<void> _showOutputResult(
    ReportOutputResult result,
    ReportOutputAction action,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: ReportOutputResultDialog(
          result: result,
          action: action,
          accentColor: _accentColor,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  KeyEventResult _handleTableKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || _visibleRows.isEmpty) {
      return KeyEventResult.ignored;
    }
    final rows = _visibleRows;
    var index = rows.indexWhere((row) => row.id == _selectedRowId);
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      index = index < 0
          ? 0
          : (index + 1).clamp(0, rows.length - 1).toInt();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      index = index < 0
          ? rows.length - 1
          : (index - 1).clamp(0, rows.length - 1).toInt();
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      index = 0;
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      index = rows.length - 1;
    } else if (event.logicalKey == LogicalKeyboardKey.enter && index < 0) {
      index = 0;
    } else {
      return KeyEventResult.ignored;
    }
    setState(() => _selectedRowId = rows[index].id);
    if (_tableScrollController.hasClients) {
      _tableScrollController.animateTo(
        (index * 52.0).clamp(
          0,
          _tableScrollController.position.maxScrollExtent,
        ).toDouble(),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
    return KeyEventResult.handled;
  }

  List<ReportRowDefinition> get _visibleRows {
    final query = _searchController.text.trim();

    return _loadedRows.where((row) {
      if (_dateRange != null) {
        final date = row.date;
        final startDate = DateUtils.dateOnly(_dateRange!.start);
        final endDate = DateUtils.dateOnly(_dateRange!.end);
        final rowDate = date == null ? null : DateUtils.dateOnly(date);
        if (rowDate == null ||
            rowDate.isBefore(startDate) ||
            rowDate.isAfter(endDate)) {
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

  List<ReportMetricValue> get _calculatedMetrics {
    return ReportSummaryCalculator.calculate(
      reportId: widget.definition.id,
      variantId: _variant.id,
      rows: _visibleRows,
      fallbackMetrics: _variant.metrics,
      selectedFilters: _dropdownValues,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportId = widget.definition.id;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            () => _runOutput(ReportOutputAction.printPreview),
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): () => _runOutput(ReportOutputAction.pdf),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            () => _runOutput(ReportOutputAction.excel),
      },
      child: AppShortcutScope(
        onSearch: _focusSearch,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: AppLoadingOverlay(
            key: Key('reportOutputLoading_$reportId'),
            isLoading: _activeOutput != null,
            message: _activeOutput?.loadingMessage ?? 'جاري تجهيز التقرير',
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
                    _buildOutputButton(
                      key: Key('reportPrintButton_$reportId'),
                      semanticsLabel: 'طباعة التقرير، الاختصار Control P',
                      label: 'طباعة',
                      icon: Icons.print_rounded,
                      backgroundColor: AppColors.blue,
                      onPressed: () =>
                          _runOutput(ReportOutputAction.printPreview),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildOutputButton(
                      key: Key('reportPdfButton_$reportId'),
                      semanticsLabel:
                          'تصدير التقرير PDF، الاختصار Control Shift P',
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      variant: AppButtonVariant.danger,
                      onPressed: () => _runOutput(ReportOutputAction.pdf),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildOutputButton(
                      key: Key('reportExcelButton_$reportId'),
                      semanticsLabel:
                          'تصدير التقرير Excel، الاختصار Control E',
                      label: 'Excel',
                      icon: Icons.table_chart_rounded,
                      variant: AppButtonVariant.success,
                      onPressed: () => _runOutput(ReportOutputAction.excel),
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
                        clearButtonKey:
                            Key('reportSearchClear_$reportId'),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        label: 'بحث في النتائج',
                        hint: 'رقم أو اسم',
                        accentColor: _accentColor,
                        onChanged: (_) {
                          setState(() => _loadError = null);
                        },
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
                      onPressed: _isLoading ? null : _showReport,
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
                      if (_loadError != null) {
                        return Center(
                          child: AppStatePanel(
                            key: Key('reportErrorState_$reportId'),
                            type: AppStateType.error,
                            title: 'تعذر عرض التقرير',
                            message: _loadError!,
                            actionLabel: 'إعادة المحاولة',
                            onAction: _showReport,
                          ),
                        );
                      }
                      return Semantics(
                        label:
                            'جدول نتائج ${widget.definition.title}. استخدم الأسهم للتنقل بين الصفوف.',
                        child: Focus(
                          key: Key('reportTableKeyboardScope_$reportId'),
                          focusNode: _tableFocusNode,
                          onKeyEvent: _handleTableKeyEvent,
                          child: AppDataTable(
                            key: Key(
                              'reportTable_${reportId}_${_variant.id}',
                            ),
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
                                    _tableFocusNode.requestFocus();
                                    setState(() {
                                      _selectedRowId =
                                          _selectedRowId == row.id
                                              ? null
                                              : row.id;
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
                            isLoading: _isLoading,
                            verticalScrollController:
                                _tableScrollController,
                            headerHeight: 52,
                            rowHeight: 52,
                            minimumColumnWidth:
                                _variant.minimumColumnWidth,
                            accentColor: _accentColor,
                            selectedRowColor: Color.alphaBlend(
                              _accentColor.withAlpha(18),
                              AppColors.surface,
                            ),
                            showShadow: false,
                            emptyState: AppStatePanel(
                              key: Key('reportEmptyState_$reportId'),
                              type: AppStateType.empty,
                              title: 'لا توجد نتائج مطابقة',
                              message:
                                  'غيّر التصفية أو عبارة البحث ثم حاول مرة أخرى.',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReportSummaryBar(
                  key: Key('reportSummaryPanel_$reportId'),
                  reportId: reportId,
                  variantId: _variant.id,
                  metrics: _calculatedMetrics,
                  matchingCount: _visibleRows.length,
                  accentColor: _accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputButton({
    required Key key,
    required String semanticsLabel,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    AppButtonVariant variant = AppButtonVariant.primary,
    Color? backgroundColor,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: AppButton(
        key: key,
        label: label,
        icon: icon,
        variant: variant,
        backgroundColor: backgroundColor,
        minWidth: 112,
        height: AppRegularButton.defaultHeight,
        onPressed: _activeOutput == null ? onPressed : null,
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
            onChanged: (value) {
              setState(() {
                _dateRange = value;
                _loadError = null;
              });
            },
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
                _loadError = null;
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
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
