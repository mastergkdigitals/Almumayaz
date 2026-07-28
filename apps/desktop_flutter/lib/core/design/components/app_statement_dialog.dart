import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_date_time_fields.dart';
import 'app_dropdown_field.dart';
import 'app_module_dialog.dart';
import 'app_text_fields.dart';

@immutable
class AppStatementOptions {
  const AppStatementOptions({
    required this.fromDate,
    required this.toDate,
    required this.currencyCode,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String currencyCode;
}

abstract final class AppStatementOptionsDialog {
  static Future<AppStatementOptions?> show(
    BuildContext context, {
    required String partyName,
    DateTime? firstTransactionDate,
    Color accentColor = AppModuleColors.parties,
  }) {
    return showDialog<AppStatementOptions>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _StatementDialogBody(
          partyName: partyName,
          firstTransactionDate: firstTransactionDate,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _StatementDialogBody extends StatefulWidget {
  const _StatementDialogBody({
    required this.partyName,
    required this.firstTransactionDate,
    required this.accentColor,
  });

  final String partyName;
  final DateTime? firstTransactionDate;
  final Color accentColor;

  @override
  State<_StatementDialogBody> createState() => _StatementDialogBodyState();
}

class _StatementDialogBodyState extends State<_StatementDialogBody> {
  late final TextEditingController _partyController;
  late DateTime _fromDate;
  late DateTime _toDate;
  String _currencyCode = 'IQD';
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _partyController = TextEditingController(text: widget.partyName);
    _fromDate = _dateOnly(widget.firstTransactionDate ?? today);
    _toDate = today;
  }

  @override
  void dispose() {
    _partyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_fromDate.isAfter(_toDate)) {
      setState(() {
        _error = 'تاريخ البداية يجب أن يسبق تاريخ النهاية';
      });
      return;
    }

    Navigator.of(context).pop(
      AppStatementOptions(
        fromDate: _fromDate,
        toDate: _toDate,
        currencyCode: _currencyCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('appStatementOptionsDialog'),
      title: 'خيارات كشف الحساب',
      subtitle: 'حدد المدة والعملة قبل فتح الكشف',
      icon: Icons.receipt_long_rounded,
      accentColor: widget.accentColor,
      width: AppDialogSizes.medium,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('appStatementActions'),
      actions: [
        AppButton(
          key: const Key('appStatementCancel'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          key: const Key('appStatementConfirm'),
          label: 'عرض الكشف',
          icon: Icons.visibility_rounded,
          width: 176,
          backgroundColor: widget.accentColor,
          onPressed: _submit,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppReadOnlyField(
            fieldKey: const Key('appStatementParty'),
            controller: _partyController,
            label: 'اسم الطرف',
            icon: Icons.groups_rounded,
            accentColor: widget.accentColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppDateField(
                  fieldKey: const Key('appStatementFromDate'),
                  label: 'من تاريخ',
                  value: _fromDate,
                  accentColor: widget.accentColor,
                  onChanged: (value) => setState(() {
                    _fromDate = value;
                    _error = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDateField(
                  fieldKey: const Key('appStatementToDate'),
                  label: 'إلى تاريخ',
                  value: _toDate,
                  accentColor: widget.accentColor,
                  onChanged: (value) => setState(() {
                    _toDate = value;
                    _error = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            fieldKey: const Key('appStatementCurrency'),
            label: 'العملة',
            icon: Icons.currency_exchange_rounded,
            accentColor: widget.accentColor,
            useIntrinsicHeight: true,
            value: _currencyCode,
            options: const [
              AppDropdownOption(value: 'IQD', label: 'دينار'),
              AppDropdownOption(value: 'USD', label: 'دولار'),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _currencyCode = value);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('appStatementDateError'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.danger),
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
