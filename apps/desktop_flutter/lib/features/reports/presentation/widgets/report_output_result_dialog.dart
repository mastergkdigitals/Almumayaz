import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../application/report_output_service.dart';

enum ReportOutputAction { printPreview, pdf, excel }

extension ReportOutputActionPresentation on ReportOutputAction {
  String get loadingMessage => switch (this) {
        ReportOutputAction.printPreview => 'جاري تجهيز معاينة الطباعة',
        ReportOutputAction.pdf => 'جاري تجهيز PDF',
        ReportOutputAction.excel => 'جاري تجهيز Excel',
      };

  IconData get icon => switch (this) {
        ReportOutputAction.printPreview => Icons.print_rounded,
        ReportOutputAction.pdf => Icons.picture_as_pdf_rounded,
        ReportOutputAction.excel => Icons.table_chart_rounded,
      };
}

class ReportOutputResultDialog extends StatelessWidget {
  const ReportOutputResultDialog({
    required this.result,
    required this.action,
    required this.accentColor,
    required this.onClose,
    super.key,
  });

  final ReportOutputResult result;
  final ReportOutputAction action;
  final Color accentColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('reportOutputPreviewDialog'),
      title: result.title,
      subtitle: '${result.rowCount} نتيجة',
      icon: action.icon,
      accentColor: accentColor,
      width: AppDialogSizes.large,
      onClose: onClose,
      actions: [
        AppRegularButton(
          key: const Key('reportOutputPreviewClose'),
          label: 'إغلاق',
          icon: Icons.close_rounded,
          onPressed: onClose,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.fileName != null) ...[
            AppInfoBanner(
              key: const Key('reportOutputFileName'),
              message: 'الملف التجريبي: ${result.fileName}',
              foregroundColor: accentColor,
              backgroundColor: Color.alphaBlend(
                accentColor.withAlpha(12),
                AppColors.surface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Semantics(
            label: 'محتوى مخرجات التقرير',
            child: Container(
              constraints: const BoxConstraints(minHeight: 240),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SelectableText(
                  result.content,
                  key: const Key('reportOutputPreviewContent'),
                  style: AppTypography.tableCell,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
