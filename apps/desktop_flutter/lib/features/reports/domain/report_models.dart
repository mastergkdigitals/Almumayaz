enum ReportFilterKind { dateRange, dropdown }

/// Spreadsheet value semantics are independent from the on-screen alignment
/// hint used by report tables. Text is deliberately the safe default because
/// item codes and phone numbers can look numeric while remaining identifiers.
enum ReportSpreadsheetCellKind {
  text,
  integer,
  decimal,
  date,
  time,
  percentage,
}

class ReportFilterOption {
  const ReportFilterOption(this.value, this.label);

  final String value;
  final String label;
}

class ReportMetricDefinition {
  const ReportMetricDefinition({
    required this.label,
    this.spreadsheetCellKind = ReportSpreadsheetCellKind.text,
    this.spreadsheetDecimalPlaces,
  });

  final String label;
  final ReportSpreadsheetCellKind spreadsheetCellKind;
  final int? spreadsheetDecimalPlaces;
}

class ReportMetricValue {
  const ReportMetricValue({
    required this.label,
    required this.value,
    this.spreadsheetCellKind = ReportSpreadsheetCellKind.text,
    this.spreadsheetDecimalPlaces,
  });

  final String label;
  final String value;
  final ReportSpreadsheetCellKind spreadsheetCellKind;
  final int? spreadsheetDecimalPlaces;
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
