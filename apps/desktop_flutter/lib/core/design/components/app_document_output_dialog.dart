import 'package:flutter/material.dart';

import '../../printing/document_output_service.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_feedback.dart';
import 'app_module_dialog.dart';

abstract final class AppDocumentOutputDialog {
  static Future<void> show(
    BuildContext context, {
    required DocumentOutputResult result,
    required Color accentColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _DocumentOutputBody(
          result: result,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _DocumentOutputBody extends StatelessWidget {
  const _DocumentOutputBody({
    required this.result,
    required this.accentColor,
  });

  final DocumentOutputResult result;
  final Color accentColor;

  IconData get _icon => switch (result.action) {
        DocumentOutputAction.print => Icons.print_rounded,
        DocumentOutputAction.printWithoutPrices => Icons.money_off_rounded,
        DocumentOutputAction.pdf => Icons.picture_as_pdf_rounded,
        DocumentOutputAction.excel => Icons.table_chart_rounded,
      };

  String get _message => switch (result.action) {
        DocumentOutputAction.print =>
          'هذه معاينة تجريبية داخل التطبيق وجاهزة للربط مع الطابعة.',
        DocumentOutputAction.printWithoutPrices =>
          'هذه معاينة تجريبية داخل التطبيق وجاهزة للربط مع الطابعة.',
        DocumentOutputAction.pdf =>
          'تم تجهيز نتيجة PDF تجريبية داخل التطبيق دون كتابة ملف فعلي.',
        DocumentOutputAction.excel =>
          'تم تجهيز نتيجة Excel تجريبية داخل التطبيق دون كتابة ملف فعلي.',
      };

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('appDocumentOutputDialog'),
      title: result.title,
      subtitle: result.documentTitle,
      icon: _icon,
      accentColor: accentColor,
      width: AppDialogSizes.large,
      showHeaderCloseButton: true,
      centerHeader: true,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('appDocumentOutputActions'),
      actions: [
        AppButton(
          key: const Key('appDocumentOutputClose'),
          label: 'إغلاق',
          icon: Icons.close_rounded,
          width: 144,
          backgroundColor: accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message: _message,
            foregroundColor: accentColor,
            backgroundColor: Color.alphaBlend(
              accentColor.withAlpha(16),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusBadge(
                label: 'عدد الصفوف: ${result.rowCount}',
                tone: AppStatusTone.info,
              ),
              if (result.fileName != null)
                AppStatusBadge(
                  key: const Key('appDocumentOutputFileName'),
                  label: result.fileName!,
                  tone: AppStatusTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                result.content,
                key: const Key('appDocumentOutputContent'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: AppTypography.fieldText.copyWith(
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
