import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../domain/report_models.dart';

export '../domain/report_models.dart';

class ReportDefinition {
  const ReportDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.palette,
    required this.variants,
  }) : assert(variants.length > 0);

  final String id;
  final String title;
  final IconData icon;
  final AppModulePalette palette;
  final List<ReportVariantDefinition> variants;
}

class ReportVariantDefinition {
  const ReportVariantDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.filters,
    required this.metrics,
    required this.columns,
    this.minimumColumnWidth = 135,
  }) : assert(columns.length > 0);

  final String id;
  final String label;
  final IconData icon;
  final List<ReportFilterDefinition> filters;
  final List<ReportMetricDefinition> metrics;
  final List<ReportColumnDefinition> columns;
  final double minimumColumnWidth;
}

class ReportFilterDefinition {
  const ReportFilterDefinition.dateRange({
    required this.id,
    required this.label,
    this.icon = Icons.date_range_rounded,
  }) : kind = ReportFilterKind.dateRange,
        options = const [];

  const ReportFilterDefinition.dropdown({
    required this.id,
    required this.label,
    required this.icon,
    required this.options,
  }) : kind = ReportFilterKind.dropdown;

  final String id;
  final String label;
  final IconData icon;
  final ReportFilterKind kind;
  final List<ReportFilterOption> options;

  ReportFilterDefinition withOptions(
    List<ReportFilterOption> runtimeOptions,
  ) {
    if (kind != ReportFilterKind.dropdown) return this;
    return ReportFilterDefinition.dropdown(
      id: id,
      label: label,
      icon: icon,
      options: List<ReportFilterOption>.unmodifiable(runtimeOptions),
    );
  }
}

class ReportColumnDefinition {
  const ReportColumnDefinition({
    required this.label,
    this.numeric = false,
    this.flex = 1,
  }) : assert(flex > 0);

  final String label;
  final bool numeric;
  final double flex;
}
