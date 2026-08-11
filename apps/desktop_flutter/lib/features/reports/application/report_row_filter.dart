import '../domain/report_models.dart';

class ReportFilterAvailability {
  const ReportFilterAvailability({
    required this.id,
    required this.label,
    required this.options,
  });

  final String id;
  final String label;
  final List<ReportFilterOption> options;
}

/// Pure filtering and reference validation for report presentation state.
abstract final class ReportRowFilter {
  static String? missingReferenceMessage({
    required Iterable<ReportFilterAvailability> filters,
    required Map<String, String> selectedValues,
  }) {
    for (final filter in filters) {
      if (filter.options.isEmpty) {
        return 'لا توجد قيم متاحة في ${filter.label}. '
            'راجع البيانات المرجعية ثم أعد المحاولة.';
      }
      final selectedValue = selectedValues[filter.id];
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

  static List<ReportRowDefinition> apply({
    required Iterable<ReportRowDefinition> rows,
    required Iterable<String> dropdownFilterIds,
    required Map<String, String> selectedValues,
    DateTime? startDate,
    DateTime? endDate,
    String query = '',
  }) {
    final normalizedStart = startDate == null ? null : _dateOnly(startDate);
    final normalizedEnd = endDate == null ? null : _dateOnly(endDate);
    final normalizedQuery = query.trim();

    return rows.where((row) {
      if (normalizedStart != null && normalizedEnd != null) {
        final rowDate = row.date == null ? null : _dateOnly(row.date!);
        if (rowDate == null ||
            rowDate.isBefore(normalizedStart) ||
            rowDate.isAfter(normalizedEnd)) {
          return false;
        }
      }

      for (final filterId in dropdownFilterIds) {
        final selectedValue = selectedValues[filterId];
        if (selectedValue == null || selectedValue == 'all') continue;
        final rowValues = (row.filterValues[filterId] ?? '').split('|');
        if (!rowValues.contains('all') &&
            !rowValues.contains(selectedValue)) {
          return false;
        }
      }

      return row.matchesSearch(normalizedQuery);
    }).toList(growable: false);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
