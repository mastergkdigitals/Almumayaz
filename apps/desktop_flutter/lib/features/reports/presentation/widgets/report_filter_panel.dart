import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportFilterPanel extends StatelessWidget {
  const ReportFilterPanel({
    required this.reportId,
    required this.filters,
    required this.dropdownValues,
    required this.dateRange,
    required this.accentColor,
    required this.onDateRangeChanged,
    required this.onDropdownChanged,
    super.key,
  });

  final String reportId;
  final List<ReportFilterDefinition> filters;
  final Map<String, String> dropdownValues;
  final DateTimeRange? dateRange;
  final Color accentColor;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final void Function(String filterId, String? value) onDropdownChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: Key('reportFiltersPanel_$reportId'),
      builder: (context, constraints) {
        final fieldWidth =
            (constraints.maxWidth - AppSpacing.sm * 4) / 5;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final filter in filters)
              _ReportFilterField(
                reportId: reportId,
                filter: filter,
                width: fieldWidth,
                dateRange: dateRange,
                dropdownValue: dropdownValues[filter.id],
                accentColor: accentColor,
                onDateRangeChanged: onDateRangeChanged,
                onDropdownChanged: (value) =>
                    onDropdownChanged(filter.id, value),
              ),
          ],
        );
      },
    );
  }
}

class _ReportFilterField extends StatelessWidget {
  const _ReportFilterField({
    required this.reportId,
    required this.filter,
    required this.width,
    required this.dateRange,
    required this.dropdownValue,
    required this.accentColor,
    required this.onDateRangeChanged,
    required this.onDropdownChanged,
  });

  final String reportId;
  final ReportFilterDefinition filter;
  final double width;
  final DateTimeRange? dateRange;
  final String? dropdownValue;
  final Color accentColor;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final ValueChanged<String?> onDropdownChanged;

  @override
  Widget build(BuildContext context) {
    final fieldKey = Key('reportFilter_${reportId}_${filter.id}');

    return SizedBox(
      width: width,
      child: switch (filter.kind) {
        ReportFilterKind.dateRange => AppDateRangeField(
            fieldKey: fieldKey,
            label: filter.label,
            value: dateRange,
            accentColor: accentColor,
            onChanged: onDateRangeChanged,
          ),
        ReportFilterKind.dropdown => AppDropdownField<String>(
            fieldKey: fieldKey,
            label: filter.label,
            icon: filter.icon,
            value: dropdownValue,
            options: [
              for (final option in filter.options)
                AppDropdownOption<String>(
                  value: option.value,
                  label: option.label,
                ),
            ],
            accentColor: accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: onDropdownChanged,
          ),
      },
    );
  }
}
