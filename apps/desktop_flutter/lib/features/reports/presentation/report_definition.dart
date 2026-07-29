import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

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
    required this.rows,
    this.minimumColumnWidth = 135,
  }) : assert(columns.length > 0);

  final String id;
  final String label;
  final IconData icon;
  final List<ReportFilterDefinition> filters;
  final List<ReportMetricDefinition> metrics;
  final List<ReportColumnDefinition> columns;
  final List<ReportRowDefinition> rows;
  final double minimumColumnWidth;
}

enum ReportFilterKind { dateRange, dropdown }

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
}

class ReportFilterOption {
  const ReportFilterOption(this.value, this.label);

  final String value;
  final String label;
}

class ReportMetricDefinition {
  const ReportMetricDefinition({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
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

class ReportRowDefinition {
  const ReportRowDefinition({
    required this.id,
    required this.cells,
    this.date,
    this.filterValues = const {},
    this.searchTerms = const [],
  });

  final String id;
  final List<String> cells;
  final DateTime? date;
  final Map<String, String> filterValues;
  final List<String> searchTerms;

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final searchable = [...cells, ...searchTerms].join(' ').toLowerCase();
    return searchable.contains(query.toLowerCase());
  }
}
