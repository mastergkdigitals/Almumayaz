import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportHeaderBar extends StatelessWidget {
  const ReportHeaderBar({
    required this.definition,
    required this.definitions,
    required this.selectedVariant,
    required this.accentColor,
    required this.outputBusy,
    required this.allowPrint,
    required this.allowExport,
    required this.onDefinitionChanged,
    required this.onVariantChanged,
    required this.onPrint,
    required this.onPdf,
    required this.onExcel,
    super.key,
  });

  final ReportDefinition definition;
  final List<ReportDefinition> definitions;
  final ReportVariantDefinition selectedVariant;
  final Color accentColor;
  final bool outputBusy;
  final bool allowPrint;
  final bool allowExport;
  final ValueChanged<ReportDefinition> onDefinitionChanged;
  final ValueChanged<ReportVariantDefinition> onVariantChanged;
  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    final reportId = definition.id;

    return Row(
      key: Key('reportHeaderBar_$reportId'),
      children: [
        SizedBox(
          width: 360,
          child: AppDropdownField<String>(
            fieldKey: Key('reportSelector_$reportId'),
            label: 'التقرير',
            icon: definition.icon,
            value: reportId,
            options: [
              for (final candidate in definitions)
                AppDropdownOption<String>(
                  value: candidate.id,
                  label: candidate.title,
                ),
            ],
            accentColor: accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value == null || value == reportId) return;
              onDefinitionChanged(
                definitions.firstWhere(
                  (candidate) => candidate.id == value,
                ),
              );
            },
          ),
        ),
        if (definition.variants.length > 1) ...[
          const SizedBox(width: AppSpacing.md),
          AppSelectionTabs<ReportVariantDefinition>(
            items: [
              for (final variant in definition.variants)
                (
                  value: variant,
                  label: variant.label,
                  icon: variant.icon,
                ),
            ],
            selected: selectedVariant,
            accentColor: accentColor,
            onChanged: onVariantChanged,
            keyPrefix: 'reportVariantTab_${reportId}_',
            valueId: (variant) => variant.id,
            isSelected: (variant, selected) => variant.id == selected.id,
            wrap: false,
            notifyWhenSelected: true,
            minWidth: 140,
            height: AppControlHeights.compact,
          ),
        ],
        const Spacer(),
        _ReportOutputButton(
          buttonKey: Key('reportPrintButton_$reportId'),
          semanticsLabel: 'طباعة التقرير، الاختصار Control P',
          label: 'طباعة',
          icon: Icons.print_rounded,
          backgroundColor: AppColors.blue,
          enabled: allowPrint && !outputBusy,
          onPressed: onPrint,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ReportOutputButton(
          buttonKey: Key('reportPdfButton_$reportId'),
          semanticsLabel: 'تصدير التقرير PDF، الاختصار Control Shift P',
          label: 'PDF',
          icon: Icons.picture_as_pdf_rounded,
          variant: AppButtonVariant.danger,
          enabled: allowExport && !outputBusy,
          onPressed: onPdf,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ReportOutputButton(
          buttonKey: Key('reportExcelButton_$reportId'),
          semanticsLabel: 'تصدير التقرير Excel، الاختصار Control E',
          label: 'Excel',
          icon: Icons.table_chart_rounded,
          variant: AppButtonVariant.success,
          enabled: allowExport && !outputBusy,
          onPressed: onExcel,
        ),
      ],
    );
  }
}

class _ReportOutputButton extends StatelessWidget {
  const _ReportOutputButton({
    required this.buttonKey,
    required this.semanticsLabel,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.backgroundColor,
  });

  final Key buttonKey;
  final String semanticsLabel;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: AppButton(
        key: buttonKey,
        label: label,
        icon: icon,
        variant: variant,
        backgroundColor: backgroundColor,
        minWidth: 112,
        height: AppRegularButton.defaultHeight,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
