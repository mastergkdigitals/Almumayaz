import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_module_dialog.dart';
import 'app_table.dart';

@immutable
class AppInstallmentScheduleEntry {
  const AppInstallmentScheduleEntry({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  final int number;
  final DateTime dueDate;
  final num amount;
  final String status;
}

abstract final class AppInstallmentScheduleDialog {
  static Future<void> show(
    BuildContext context, {
    required String invoiceNumber,
    required String customerName,
    required String currencyCode,
    required List<AppInstallmentScheduleEntry> entries,
    Color accentColor = AppModuleColors.sales,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AppModuleDialog(
          key: const Key('appInstallmentScheduleDialog'),
          title: 'جدول الأقساط',
          subtitle: '$customerName • قائمة بيع رقم $invoiceNumber',
          icon: Icons.table_chart_rounded,
          accentColor: accentColor,
          width: AppDialogSizes.large,
          centerHeader: true,
          showHeaderCloseButton: true,
          onClose: () => Navigator.of(dialogContext).pop(),
          actionsKey: const Key('appInstallmentScheduleActions'),
          actions: [
            AppButton(
              key: const Key('appInstallmentScheduleClose'),
              label: 'إغلاق',
              icon: Icons.close_rounded,
              width: 144,
              backgroundColor: accentColor,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: AppDataTable(
            key: const Key('appInstallmentScheduleTable'),
            height: 300,
            headerHeight: 52,
            rowHeight: 58,
            accentColor: accentColor,
            minimumColumnWidth: 128,
            emptyState: const Text(
              'لا توجد أقساط متبقية لهذه القائمة',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            columns: const [
              AppTableColumn(label: 'رقم القسط', numeric: true),
              AppTableColumn(label: 'تاريخ الاستحقاق', flex: 1.4),
              AppTableColumn(label: 'المبلغ', numeric: true, flex: 1.3),
              AppTableColumn(label: 'الحالة', flex: 1.2),
            ],
            rows: [
              for (final entry in entries)
                AppTableRow(
                  cells: [
                    Text(AppFormatters.quantity(entry.number)),
                    Text(AppFormatters.date(entry.dueDate)),
                    Text(
                      AppFormatters.moneyByCurrency(
                        entry.amount,
                        currencyCode,
                      ),
                    ),
                    Text(entry.status),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
