import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_module_dialog.dart';
import 'app_statement_dialog.dart';
import 'app_table.dart';

@immutable
class AppStatementReportEntry {
  const AppStatementReportEntry({
    required this.date,
    required this.balance,
    required this.credit,
    required this.debit,
    required this.type,
    required this.details,
    this.quantity,
  });

  final DateTime date;
  final num balance;
  final num credit;
  final num debit;
  final String type;
  final int? quantity;
  final String details;
}

abstract final class AppStatementReportDialog {
  static Future<void> show(
    BuildContext context, {
    required String partyName,
    required AppStatementOptions options,
    required List<AppStatementReportEntry> entries,
    Color accentColor = AppModuleColors.parties,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _StatementReportBody(
          partyName: partyName,
          options: options,
          entries: entries,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _StatementReportBody extends StatelessWidget {
  const _StatementReportBody({
    required this.partyName,
    required this.options,
    required this.entries,
    required this.accentColor,
  });

  final String partyName;
  final AppStatementOptions options;
  final List<AppStatementReportEntry> entries;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final period =
        'من ${AppFormatters.date(options.fromDate)} '
        'إلى ${AppFormatters.date(options.toDate)}';

    return AppModuleDialog(
      key: const Key('appStatementReportDialog'),
      title: 'كشف حساب',
      subtitle: partyName,
      subtitleStyle: const TextStyle(
        color: Color(0xFF4B5563),
        fontSize: 22 * AppDensity.scale,
        fontWeight: FontWeight.w800,
      ),
      centerHeader: true,
      showHeaderCloseButton: true,
      icon: Icons.receipt_long_rounded,
      accentColor: accentColor,
      width: AppDialogSizes.extraLarge,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('appStatementReportActions'),
      actions: [
        AppButton(
          key: const Key('appStatementPdf'),
          label: 'PDF',
          icon: Icons.picture_as_pdf_rounded,
          variant: AppButtonVariant.danger,
          width: 132 * AppDensity.scale,
          onPressed: _noop,
        ),
        AppButton(
          key: const Key('appStatementPrint'),
          label: 'طباعة',
          icon: Icons.print_rounded,
          width: 132 * AppDensity.scale,
          backgroundColor: AppColors.blue,
          onPressed: _noop,
        ),
        AppButton(
          key: const Key('appStatementExcel'),
          label: 'إكسل',
          icon: Icons.table_chart_rounded,
          variant: AppButtonVariant.success,
          width: 132 * AppDensity.scale,
          onPressed: _noop,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  period,
                  key: const Key('appStatementPeriodText'),
                  style: AppTypography.fieldText.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.currency(options.currencyCode),
                  key: const Key('appStatementCurrencyText'),
                  style: AppTypography.fieldText.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('appStatementReportTable'),
            height: 340 * AppDensity.scale,
            headerHeight: 52 * AppDensity.scale,
            rowHeight: 58 * AppDensity.scale,
            minimumColumnWidth: 132,
            accentColor: accentColor,
            emptyState: const Text(
              'لا توجد حركات ضمن الفترة والعملة المختارة',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            columns: const [
              AppTableColumn(label: 'التاريخ', flex: 1.15),
              AppTableColumn(label: 'الرصيد', numeric: true, flex: 1.25),
              AppTableColumn(label: 'دائن (له)', numeric: true, flex: 1.25),
              AppTableColumn(
                label: 'مدين (عليه)',
                numeric: true,
                flex: 1.25,
              ),
              AppTableColumn(label: 'النوع', flex: 1.2),
              AppTableColumn(label: 'الكمية', numeric: true),
              AppTableColumn(label: 'التفاصيل', flex: 2.5),
            ],
            rows: [
              for (final entry in entries)
                AppTableRow(
                  cells: [
                    Text(AppFormatters.date(entry.date)),
                    Text(_formatMoney(entry.balance, options.currencyCode)),
                    Text(_formatMoney(entry.credit, options.currencyCode)),
                    Text(_formatMoney(entry.debit, options.currencyCode)),
                    Text(entry.type),
                    Text(
                      entry.quantity == null
                          ? '—'
                          : AppFormatters.quantity(entry.quantity!),
                    ),
                    Text(entry.details),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMoney(num value, String currencyCode) {
    return currencyCode.toUpperCase() == 'USD'
        ? AppFormatters.usd(value)
        : AppFormatters.iqd(value);
  }
}

void _noop() {}
