import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../application/report_data_snapshot_service.dart';
import '../../application/report_output_service.dart';
import '../../application/report_rows_service.dart';
import '../../application/report_summary_calculator.dart';
import '../report_definition.dart';
import 'report_filter_panel.dart';
import 'report_header_bar.dart';
import 'report_output_result_dialog.dart';
import 'report_results_panel.dart';
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
    this.initialDropdownValues = const {},
    this.refreshToken = 0,
  });

  final ReportDefinition definition;
  final List<ReportDefinition> definitions;
  final ValueChanged<ReportDefinition> onDefinitionChanged;
  final ReportRowsService rowsService;
  final ReportPrintService printService;
  final ReportExportService exportService;
  final Map<String, String> initialDropdownValues;
  final int refreshToken;

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
  Map<String, List<ReportFilterOption>> _runtimeFilterOptions = const {};
  CashboxReportMetadata? _cashboxMetadata;
  DateTimeRange? _dateRange;
  Map<String, String> _dropdownValues = {};
  String? _selectedRowId;
  bool _isLoading = false;
  String? _loadError;
  ReportOutputAction? _activeOutput;
  int _loadGeneration = 0;

  Color get _accentColor => widget.definition.palette.middle;

  @override
  void initState() {
    super.initState();
    _variant = widget.definition.variants.first;
    _loadedRows = _initialRows(_variant);
    _dropdownValues = {
      ..._defaultDropdownValues(_variant),
      ...widget.initialDropdownValues,
    };
    if (widget.rowsService is ReportDataSnapshotService) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            _refreshRows(showResultToast: false, focusTable: false),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReportSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowsService != widget.rowsService ||
        oldWidget.refreshToken != widget.refreshToken) {
      unawaited(
        _refreshRows(showResultToast: false, focusTable: false),
      );
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
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
        if (filter.kind == ReportFilterKind.dropdown &&
            filter.options.isNotEmpty)
          filter.id: filter.options.first.value,
    };
  }

  List<ReportFilterDefinition> get _effectiveFilters => [
        for (final filter in _variant.filters)
          _runtimeFilterOptions[filter.id] == null
              ? filter
              : filter.withOptions(_runtimeFilterOptions[filter.id]!),
      ];

  ReportRowsRequest _rowsRequest(ReportVariantDefinition variant) {
    return ReportRowsRequest(
      reportId: widget.definition.id,
      variantId: variant.id,
    );
  }

  List<ReportRowDefinition> _initialRows(ReportVariantDefinition variant) {
    final service = widget.rowsService;
    if (service case ReportRowsSnapshotProvider snapshotProvider) {
      return snapshotProvider.snapshot(_rowsRequest(variant));
    }
    return const [];
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
  }

  String? get _missingReferenceMessage {
    for (final filter in _effectiveFilters) {
      if (filter.kind != ReportFilterKind.dropdown) continue;
      if (filter.options.isEmpty) {
        return 'لا توجد قيم متاحة في ${filter.label}. '
            'راجع البيانات المرجعية ثم أعد المحاولة.';
      }
      final selectedValue = _dropdownValues[filter.id];
      if (selectedValue == null) continue;
      final referenceExists = filter.options.any(
        (option) => option.value == selectedValue,
      );
      if (!referenceExists) {
        return 'القيمة المحددة في ${filter.label} لم تعد متاحة. '
            'امسح التصفية ثم اختر قيمة أخرى.';
      }
    }
    return null;
  }

  void _changeVariant(ReportVariantDefinition variant) {
    if (variant.id == _variant.id) return;
    _searchController.clear();
    setState(() {
      _variant = variant;
      _loadedRows = _initialRows(variant);
      _dateRange = null;
      _dropdownValues = _defaultDropdownValues(variant);
      _selectedRowId = null;
      _loadError = null;
      _runtimeFilterOptions = const {};
      _cashboxMetadata = null;
    });
    if (widget.rowsService is ReportDataSnapshotService) {
      unawaited(
        _refreshRows(showResultToast: false, focusTable: false),
      );
    }
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
    await _refreshRows(showResultToast: true, focusTable: true);
  }

  Future<bool> _refreshRows({
    required bool showResultToast,
    required bool focusTable,
  }) async {
    final missingReference = _missingReferenceMessage;
    if (missingReference != null) {
      AppToast.showError(context, missingReference);
      return false;
    }
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _selectedRowId = null;
    });
    final requestedVariant = _variant;
    try {
      final request = _rowsRequest(requestedVariant);
      final service = widget.rowsService;
      final ReportDataSnapshot snapshot;
      if (service case ReportDataSnapshotService snapshotService) {
        snapshot = await snapshotService.loadSnapshot(request);
      } else if (service case ReportRowsSnapshotProvider snapshotProvider) {
        snapshot = ReportDataSnapshot(
          rows: snapshotProvider.snapshot(request),
        );
      } else {
        snapshot = ReportDataSnapshot(rows: await service.load(request));
      }
      if (!mounted ||
          generation != _loadGeneration ||
          _variant.id != requestedVariant.id) {
        return false;
      }
      setState(() {
        _loadedRows = snapshot.rows;
        _runtimeFilterOptions = snapshot.filterOptions;
        _cashboxMetadata = snapshot.cashboxMetadata;
      });
      if (focusTable) _tableFocusNode.requestFocus();
      if (showResultToast) {
        AppToast.showInfo(
          context,
          'تم عرض ${_visibleRows.length} نتيجة',
        );
      }
      return true;
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return false;
      setState(() {
        _loadError = 'تعذر تحميل بيانات التقرير';
      });
      AppToast.showError(context, _loadError!);
      return false;
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runOutput(ReportOutputAction action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_activeOutput != null) return;
    setState(() => _activeOutput = action);
    try {
      final refreshed = await _refreshRows(
        showResultToast: false,
        focusTable: false,
      );
      if (!mounted || !refreshed) return;
      final missingReference = _missingReferenceMessage;
      if (missingReference != null) {
        AppToast.showError(context, missingReference);
        return;
      }
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
    } finally {
      if (mounted && _activeOutput == action) {
        setState(() => _activeOutput = null);
      }
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
      cashboxOpeningIqd: _cashboxMetadata?.openingIqd.majorUnits,
      cashboxOpeningUsd: _cashboxMetadata?.openingUsd.majorUnits,
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
                ReportHeaderBar(
                  definition: widget.definition,
                  definitions: widget.definitions,
                  selectedVariant: _variant,
                  accentColor: _accentColor,
                  outputBusy: _activeOutput != null,
                  onDefinitionChanged: widget.onDefinitionChanged,
                  onVariantChanged: _changeVariant,
                  onPrint: () =>
                      _runOutput(ReportOutputAction.printPreview),
                  onPdf: () => _runOutput(ReportOutputAction.pdf),
                  onExcel: () => _runOutput(ReportOutputAction.excel),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReportFilterPanel(
                  reportId: reportId,
                  filters: _effectiveFilters,
                  dropdownValues: _dropdownValues,
                  dateRange: _dateRange,
                  accentColor: _accentColor,
                  onDateRangeChanged: (value) {
                    setState(() {
                      _dateRange = value;
                      _loadError = null;
                    });
                  },
                  onDropdownChanged: (filterId, value) {
                    final filter = _effectiveFilters.singleWhere(
                      (candidate) => candidate.id == filterId,
                    );
                    setState(() {
                      _dropdownValues[filterId] =
                          value ?? filter.options.first.value;
                      _loadError = null;
                    });
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
                  child: ReportResultsPanel(
                    reportId: reportId,
                    reportTitle: widget.definition.title,
                    variant: _variant,
                    rows: _visibleRows,
                    selectedRowId: _selectedRowId,
                    accentColor: _accentColor,
                    isLoading: _isLoading,
                    loadError: _loadError,
                    missingReference: _missingReferenceMessage,
                    tableFocusNode: _tableFocusNode,
                    tableScrollController: _tableScrollController,
                    onKeyboardSelectionChanged: (index) {
                      final rows = _visibleRows;
                      if (index < 0 || index >= rows.length) return;
                      setState(() => _selectedRowId = rows[index].id);
                    },
                    onRetry: _showReport,
                    onResetFilters: _resetFilters,
                    onRowTap: (row) {
                      _tableFocusNode.requestFocus();
                      setState(() {
                        _selectedRowId = _selectedRowId == row.id
                            ? null
                            : row.id;
                      });
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
}
