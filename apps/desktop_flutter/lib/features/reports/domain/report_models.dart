enum ReportFilterKind { dateRange, dropdown }

class ReportFilterOption {
  const ReportFilterOption(this.value, this.label);

  final String value;
  final String label;
}

class ReportMetricDefinition {
  const ReportMetricDefinition({
    required this.label,
  });

  final String label;
}

class ReportMetricValue {
  const ReportMetricValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
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
