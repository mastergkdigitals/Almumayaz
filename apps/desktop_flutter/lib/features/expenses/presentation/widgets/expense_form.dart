import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../../../core/domain/business_values.dart';
import '../../../parties/domain/party.dart';
import '../../domain/expense.dart';

class ExpenseForm extends StatelessWidget {
  const ExpenseForm({
    required this.numberController,
    required this.descriptionController,
    required this.supplierController,
    required this.amountController,
    required this.exchangeRateController,
    required this.notesController,
    required this.dateTime,
    required this.paymentStatus,
    required this.currency,
    required this.suppliers,
    required this.enabled,
    required this.statusEditable,
    required this.onDateChanged,
    required this.onStatusChanged,
    required this.onCurrencyChanged,
    required this.onSupplierSelected,
    required this.onSupplierTextChanged,
    super.key,
  });

  final TextEditingController numberController;
  final TextEditingController descriptionController;
  final TextEditingController supplierController;
  final TextEditingController amountController;
  final TextEditingController exchangeRateController;
  final TextEditingController notesController;
  final DateTime dateTime;
  final ExpensePaymentStatus paymentStatus;
  final AppCurrency currency;
  final List<Party> suppliers;
  final bool enabled;
  final bool statusEditable;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<ExpensePaymentStatus> onStatusChanged;
  final ValueChanged<AppCurrency> onCurrencyChanged;
  final ValueChanged<Party> onSupplierSelected;
  final ValueChanged<String> onSupplierTextChanged;

  static const _accent = AppModuleColors.cashbox;

  @override
  Widget build(BuildContext context) {
    return AppSectionPanel(
      title: 'بيانات المصروف',
      icon: Icons.receipt_long_rounded,
      accentColor: _accent,
      child: Column(
        children: [
          _FieldRow(
            children: [
              AppReadOnlyField(
                fieldKey: const Key('expenseNumberField'),
                controller: numberController,
                label: 'رقم المصروف',
                icon: Icons.confirmation_number_rounded,
                accentColor: _accent,
              ),
              AppDateField(
                fieldKey: const Key('expenseDateField'),
                label: 'التاريخ',
                value: dateTime,
                accentColor: _accent,
                enabled: enabled,
                onChanged: onDateChanged,
              ),
              AppTimeField(
                fieldKey: const Key('expenseTimeField'),
                label: 'الوقت',
                value: TimeOfDay.fromDateTime(dateTime),
                accentColor: _accent,
              ),
              AppDropdownField<ExpensePaymentStatus>(
                fieldKey: const Key('expensePaymentStatusField'),
                label: 'حالة الدفع',
                icon: Icons.price_check_rounded,
                accentColor: _accent,
                value: paymentStatus,
                enabled: enabled && statusEditable,
                options: [
                  for (final status in ExpensePaymentStatus.values)
                    AppDropdownOption(value: status, label: status.label),
                ],
                onChanged: (value) {
                  if (value != null) onStatusChanged(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldRow(
            children: [
              AppTextField(
                fieldKey: const Key('expenseDescriptionField'),
                controller: descriptionController,
                label: 'بيان المصروف',
                icon: Icons.description_rounded,
                accentColor: _accent,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                enabled: enabled,
              ),
              AppAutocompleteField<Party>(
                fieldKey: const Key('expenseSupplierField'),
                controller: supplierController,
                label: paymentStatus == ExpensePaymentStatus.unpaid
                    ? 'المجهز (مطلوب)'
                    : 'المجهز (اختياري)',
                hint: 'اكتب اسم أو رقم المجهز',
                icon: Icons.local_shipping_rounded,
                accentColor: _accent,
                options: suppliers,
                displayStringForOption: (party) => party.name,
                searchTermsForOption: (party) => [
                  '${party.number}',
                  party.name,
                  party.phone,
                ],
                optionSubtitle: (party) => 'رقم ${party.number}',
                onSelected: onSupplierSelected,
                onChanged: onSupplierTextChanged,
                enabled: enabled,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldRow(
            children: [
              AppDropdownField<AppCurrency>(
                fieldKey: const Key('expenseCurrencyField'),
                label: 'العملة',
                icon: Icons.currency_exchange_rounded,
                accentColor: _accent,
                value: currency,
                enabled: enabled,
                options: [
                  for (final option in AppCurrency.values)
                    AppDropdownOption(
                      value: option,
                      label: option.arabicName,
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onCurrencyChanged(value);
                },
              ),
              AppMoneyField(
                fieldKey: const Key('expenseExchangeRateField'),
                controller: exchangeRateController,
                label: 'سعر الصرف',
                icon: Icons.currency_exchange_rounded,
                accentColor: _accent,
                decimalPlaces: ExchangeRate.decimalPlaces,
                enabled: enabled,
              ),
              AppMoneyField(
                fieldKey: const Key('expenseAmountField'),
                controller: amountController,
                label: 'المبلغ',
                icon: Icons.payments_rounded,
                accentColor: _accent,
                decimalPlaces: currency.decimalPlaces,
                enabled: enabled,
              ),
              AppTextField(
                fieldKey: const Key('expenseNotesField'),
                controller: notesController,
                label: 'الملاحظات',
                icon: Icons.notes_rounded,
                accentColor: _accent,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
