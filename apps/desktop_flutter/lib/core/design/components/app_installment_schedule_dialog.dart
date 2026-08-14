import 'package:flutter/material.dart';

import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_feedback.dart';
import 'app_module_dialog.dart';
import 'app_table.dart';
import 'app_text_fields.dart';

@immutable
class AppInstallmentScheduleEntry {
  const AppInstallmentScheduleEntry({
    required this.entryId,
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.status,
    required this.isPaid,
  });

  final String entryId;
  final int number;
  final DateTime dueDate;
  final num amount;
  final String status;
  final bool isPaid;
}

@immutable
class AppInstallmentSettlementRequest {
  const AppInstallmentSettlementRequest({
    required this.entryId,
    required this.notes,
  });

  final String entryId;
  final String notes;
}

abstract final class AppInstallmentScheduleDialog {
  static Future<AppInstallmentSettlementRequest?> show(
    BuildContext context, {
    required String invoiceNumber,
    required String customerName,
    required String currencyCode,
    required List<AppInstallmentScheduleEntry> entries,
    bool allowSettlement = false,
    Color accentColor = AppModuleColors.sales,
  }) {
    return showDialog<AppInstallmentSettlementRequest>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _InstallmentScheduleDialogBody(
          invoiceNumber: invoiceNumber,
          customerName: customerName,
          currencyCode: currencyCode,
          entries: entries,
          allowSettlement: allowSettlement,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _InstallmentScheduleDialogBody extends StatefulWidget {
  const _InstallmentScheduleDialogBody({
    required this.invoiceNumber,
    required this.customerName,
    required this.currencyCode,
    required this.entries,
    required this.allowSettlement,
    required this.accentColor,
  });

  final String invoiceNumber;
  final String customerName;
  final String currencyCode;
  final List<AppInstallmentScheduleEntry> entries;
  final bool allowSettlement;
  final Color accentColor;

  @override
  State<_InstallmentScheduleDialogBody> createState() =>
      _InstallmentScheduleDialogBodyState();
}

class _InstallmentScheduleDialogBodyState
    extends State<_InstallmentScheduleDialogBody> {
  final _notesController = TextEditingController();
  int? _selectedIndex;

  AppInstallmentScheduleEntry? get _selectedEntry {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= widget.entries.length) {
      return null;
    }
    return widget.entries[index];
  }

  bool get _canSettle => widget.allowSettlement &&
      _selectedEntry != null &&
      !_selectedEntry!.isPaid;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _notesController.clear();
    });
  }

  void _submitSettlement() {
    final entry = _selectedEntry;
    if (!_canSettle || entry == null) return;
    Navigator.of(context).pop(
      AppInstallmentSettlementRequest(
        entryId: entry.entryId,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('appInstallmentScheduleDialog'),
      title: 'جدول الأقساط',
      subtitle:
          '${widget.customerName} • قائمة بيع رقم ${widget.invoiceNumber}',
      icon: Icons.table_chart_rounded,
      accentColor: widget.accentColor,
      width: AppDialogSizes.large,
      centerHeader: true,
      showHeaderCloseButton: true,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('appInstallmentScheduleActions'),
      actions: [
        AppButton(
          key: const Key('appInstallmentScheduleSettle'),
          label: 'تسديد القسط',
          icon: Icons.payments_rounded,
          width: 160,
          backgroundColor: AppColors.success,
          onPressed: _canSettle ? _submitSettlement : null,
        ),
        AppButton(
          key: const Key('appInstallmentScheduleClose'),
          label: 'إغلاق',
          icon: Icons.close_rounded,
          width: 144,
          backgroundColor: widget.accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDataTable(
            key: const Key('appInstallmentScheduleTable'),
            height: 300,
            headerHeight: 52,
            rowHeight: 58,
            accentColor: widget.accentColor,
            minimumColumnWidth: 128,
            onKeyboardSelectionChanged: _select,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد أقساط',
              message: 'لا توجد أقساط لهذه القائمة',
            ),
            columns: const [
              AppTableColumn(label: 'رقم القسط', numeric: true),
              AppTableColumn(label: 'تاريخ الاستحقاق', flex: 1.4),
              AppTableColumn(label: 'المبلغ', numeric: true, flex: 1.3),
              AppTableColumn(label: 'الحالة', flex: 1.2),
            ],
            rows: [
              for (var index = 0; index < widget.entries.length; index++)
                AppTableRow(
                  rowKey: Key(
                    'appInstallmentScheduleRow_'
                    '${widget.entries[index].entryId}',
                  ),
                  selected: _selectedIndex == index,
                  onTap: () => _select(index),
                  cells: [
                    Text(AppFormatters.quantity(widget.entries[index].number)),
                    Text(AppFormatters.date(widget.entries[index].dueDate)),
                    Text(
                      AppFormatters.moneyByCurrency(
                        widget.entries[index].amount,
                        widget.currencyCode,
                      ),
                    ),
                    Text(widget.entries[index].status),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('appInstallmentScheduleNotes'),
            controller: _notesController,
            label: 'ملاحظات التسديد',
            icon: Icons.notes_rounded,
            accentColor: widget.accentColor,
            enabled: _canSettle,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitSettlement(),
          ),
        ],
      ),
    );
  }
}
