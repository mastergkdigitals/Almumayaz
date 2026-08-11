import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';

class ReportActionBar extends StatelessWidget {
  const ReportActionBar({
    required this.reportId,
    required this.searchController,
    required this.searchFocusNode,
    required this.accentColor,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onShow,
    required this.onReset,
    super.key,
  });

  final String reportId;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Color accentColor;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onShow;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: Key('reportActionBar_$reportId'),
      children: [
        SizedBox(
          width: 360,
          child: AppSearchField(
            fieldKey: Key('reportSearch_$reportId'),
            clearButtonKey: Key('reportSearchClear_$reportId'),
            controller: searchController,
            focusNode: searchFocusNode,
            label: 'بحث في النتائج',
            hint: 'رقم أو اسم',
            accentColor: accentColor,
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          key: Key('reportShowButton_$reportId'),
          label: 'عرض التقرير',
          icon: Icons.assessment_rounded,
          variant: AppButtonVariant.primary,
          backgroundColor: accentColor,
          minWidth: 142,
          height: AppRegularButton.defaultHeight,
          onPressed: isLoading ? null : onShow,
        ),
        const SizedBox(width: AppSpacing.sm),
        AppRegularButton(
          key: Key('reportResetButton_$reportId'),
          label: 'مسح التصفية',
          icon: Icons.filter_alt_off_rounded,
          onPressed: onReset,
        ),
        const Spacer(),
      ],
    );
  }
}
