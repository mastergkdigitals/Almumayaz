import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/cashbox_voucher.dart';

class CashboxFormControllers {
  final voucherNumber = TextEditingController();
  final summaryBalanceIqd = TextEditingController();
  final summaryBalanceUsd = TextEditingController();
  final todayReceiptIqd = TextEditingController();
  final todayPaymentIqd = TextEditingController();
  final todayReceiptUsd = TextEditingController();
  final todayPaymentUsd = TextEditingController();
  final exchangeRate = TextEditingController();
  final currentBalanceIqd = TextEditingController();
  final currentBalanceUsd = TextEditingController();
  final amountIqd = TextEditingController();
  final equivalentUsd = TextEditingController();
  final previousBalanceIqd = TextEditingController();
  final remainingBalanceIqd = TextEditingController();
  final amountUsd = TextEditingController();
  final equivalentIqd = TextEditingController();
  final previousBalanceUsd = TextEditingController();
  final remainingBalanceUsd = TextEditingController();
  final notes = TextEditingController();

  void setSummary(CashboxSummary summary) {
    summaryBalanceIqd.text = AppFormatters.iqd(summary.balanceIqd);
    summaryBalanceUsd.text = AppFormatters.usd(summary.balanceUsd);
    todayReceiptIqd.text = AppFormatters.iqd(summary.todayReceiptIqd);
    todayPaymentIqd.text = AppFormatters.iqd(summary.todayPaymentIqd);
    todayReceiptUsd.text = AppFormatters.usd(summary.todayReceiptUsd);
    todayPaymentUsd.text = AppFormatters.usd(summary.todayPaymentUsd);
    currentBalanceIqd.text = AppFormatters.iqd(summary.balanceIqd);
    currentBalanceUsd.text = AppFormatters.usd(summary.balanceUsd);
  }

  void setNew({
    required int number,
    required num exchangeRateValue,
  }) {
    voucherNumber.text = number.toString();
    exchangeRate.text = AppFormatters.money(exchangeRateValue);
    amountIqd.clear();
    amountUsd.clear();
    notes.clear();
  }

  void load(CashboxVoucher voucher) {
    voucherNumber.text = voucher.number.toString();
    exchangeRate.text = AppFormatters.money(voucher.exchangeRate);
    amountIqd.text = AppFormatters.iqd(voucher.amountIqd);
    amountUsd.text = AppFormatters.usd(voucher.amountUsd);
    notes.text = voucher.notes;
  }

  void setCalculated({
    required num equivalentUsdValue,
    required num previousIqdValue,
    required num remainingIqdValue,
    required num equivalentIqdValue,
    required num previousUsdValue,
    required num remainingUsdValue,
  }) {
    equivalentUsd.text = AppFormatters.usd(equivalentUsdValue);
    previousBalanceIqd.text = AppFormatters.iqd(previousIqdValue);
    remainingBalanceIqd.text = AppFormatters.iqd(remainingIqdValue);
    equivalentIqd.text = AppFormatters.iqd(equivalentIqdValue);
    previousBalanceUsd.text = AppFormatters.usd(previousUsdValue);
    remainingBalanceUsd.text = AppFormatters.usd(remainingUsdValue);
  }

  void dispose() {
    voucherNumber.dispose();
    summaryBalanceIqd.dispose();
    summaryBalanceUsd.dispose();
    todayReceiptIqd.dispose();
    todayPaymentIqd.dispose();
    todayReceiptUsd.dispose();
    todayPaymentUsd.dispose();
    exchangeRate.dispose();
    currentBalanceIqd.dispose();
    currentBalanceUsd.dispose();
    amountIqd.dispose();
    equivalentUsd.dispose();
    previousBalanceIqd.dispose();
    remainingBalanceIqd.dispose();
    amountUsd.dispose();
    equivalentIqd.dispose();
    previousBalanceUsd.dispose();
    remainingBalanceUsd.dispose();
    notes.dispose();
  }
}

class CashboxForm extends StatelessWidget {
  const CashboxForm({
    required this.controllers,
    required this.voucherDateTime,
    required this.voucherType,
    required this.mainAccountId,
    required this.subaccountId,
    required this.mainAccounts,
    required this.subaccounts,
    required this.onDateChanged,
    required this.onVoucherTypeChanged,
    required this.onMainAccountChanged,
    required this.onSubaccountChanged,
    super.key,
  });

  final CashboxFormControllers controllers;
  final DateTime voucherDateTime;
  final CashboxVoucherType voucherType;
  final String mainAccountId;
  final String subaccountId;
  final List<CashboxMainAccount> mainAccounts;
  final List<CashboxSubaccount> subaccounts;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<CashboxVoucherType> onVoucherTypeChanged;
  final ValueChanged<String> onMainAccountChanged;
  final ValueChanged<String> onSubaccountChanged;

  @override
  Widget build(BuildContext context) {
    const accentColor = AppModuleColors.cashbox;

    return Column(
      key: const Key('cashboxForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CashboxFieldRow(
          children: [
            AppReadOnlyField(
              fieldKey: const Key('cashboxBalanceIqdField'),
              controller: controllers.summaryBalanceIqd,
              label: 'رصيد الصندوق دينار',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxBalanceUsdField'),
              controller: controllers.summaryBalanceUsd,
              label: 'رصيد الصندوق دولار',
              icon: Icons.attach_money_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxTodayReceiptIqdField'),
              controller: controllers.todayReceiptIqd,
              label: 'قبض اليوم دينار',
              icon: Icons.trending_up_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxTodayPaymentIqdField'),
              controller: controllers.todayPaymentIqd,
              label: 'صرف اليوم دينار',
              icon: Icons.trending_down_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxTodayReceiptUsdField'),
              controller: controllers.todayReceiptUsd,
              label: 'قبض اليوم دولار',
              icon: Icons.trending_up_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxTodayPaymentUsdField'),
              controller: controllers.todayPaymentUsd,
              label: 'صرف اليوم دولار',
              icon: Icons.trending_down_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CashboxFieldRow(
          children: [
            AppReadOnlyField(
              fieldKey: const Key('cashboxVoucherNumberField'),
              controller: controllers.voucherNumber,
              label: 'رقم السند',
              icon: Icons.confirmation_number_rounded,
              accentColor: accentColor,
            ),
            AppDateField(
              fieldKey: const Key('cashboxDateField'),
              label: 'التاريخ',
              value: voucherDateTime,
              accentColor: accentColor,
              onChanged: onDateChanged,
            ),
            AppTimeField(
              fieldKey: const Key('cashboxTimeField'),
              label: 'الوقت',
              value: TimeOfDay.fromDateTime(voucherDateTime),
              accentColor: accentColor,
            ),
            AppDropdownField<CashboxVoucherType>(
              fieldKey: const Key('cashboxTypeField'),
              label: 'النوع',
              icon: Icons.swap_vert_rounded,
              accentColor: accentColor,
              value: voucherType,
              options: [
                for (final type in CashboxVoucherType.values)
                  AppDropdownOption(value: type, label: type.label),
              ],
              onChanged: (value) {
                if (value != null) onVoucherTypeChanged(value);
              },
            ),
            _CashboxMoneyField(
              fieldKey: const Key('cashboxExchangeRateField'),
              controller: controllers.exchangeRate,
              label: 'سعر الصرف',
              icon: Icons.currency_exchange_rounded,
              decimalPlaces: 4,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxCurrentBalanceIqdField'),
              controller: controllers.currentBalanceIqd,
              label: 'الرصيد الحالي دينار',
              icon: Icons.account_balance_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxCurrentBalanceUsdField'),
              controller: controllers.currentBalanceUsd,
              label: 'الرصيد الحالي دولار',
              icon: Icons.account_balance_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CashboxFieldRow(
          children: [
            AppDropdownField<String>(
              fieldKey: const Key('cashboxMainAccountField'),
              label: 'الحساب الرئيسي',
              icon: Icons.account_tree_rounded,
              accentColor: accentColor,
              value: mainAccountId,
              options: [
                for (final account in mainAccounts)
                  AppDropdownOption(
                    value: account.id,
                    label: account.label,
                  ),
              ],
              onChanged: (value) {
                if (value != null) onMainAccountChanged(value);
              },
            ),
            AppDropdownField<String>(
              fieldKey: const Key('cashboxSubaccountField'),
              label: 'الحساب الفرعي',
              icon: Icons.subdirectory_arrow_left_rounded,
              accentColor: accentColor,
              enabled: subaccounts.isNotEmpty,
              value: subaccountId,
              options: [
                for (final subaccount in subaccounts)
                  AppDropdownOption(
                    value: subaccount.id,
                    label: subaccount.label,
                  ),
              ],
              onChanged: (value) {
                if (value != null) onSubaccountChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CashboxFieldRow(
          children: [
            _CashboxMoneyField(
              fieldKey: const Key('cashboxAmountIqdField'),
              controller: controllers.amountIqd,
              label: 'المبلغ دينار',
              icon: Icons.payments_rounded,
              decimalPlaces: 2,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxEquivalentUsdField'),
              controller: controllers.equivalentUsd,
              label: 'ما يعادله دولار',
              icon: Icons.currency_exchange_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxPreviousBalanceIqdField'),
              controller: controllers.previousBalanceIqd,
              label: 'الرصيد السابق دينار',
              icon: Icons.history_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxRemainingBalanceIqdField'),
              controller: controllers.remainingBalanceIqd,
              label: 'الرصيد المتبقي دينار',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CashboxFieldRow(
          children: [
            _CashboxMoneyField(
              fieldKey: const Key('cashboxAmountUsdField'),
              controller: controllers.amountUsd,
              label: 'المبلغ دولار',
              icon: Icons.attach_money_rounded,
              decimalPlaces: 2,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxEquivalentIqdField'),
              controller: controllers.equivalentIqd,
              label: 'ما يعادله دينار',
              icon: Icons.currency_exchange_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxPreviousBalanceUsdField'),
              controller: controllers.previousBalanceUsd,
              label: 'الرصيد السابق دولار',
              icon: Icons.history_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            AppReadOnlyField(
              fieldKey: const Key('cashboxRemainingBalanceUsdField'),
              controller: controllers.remainingBalanceUsd,
              label: 'الرصيد المتبقي دولار',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: accentColor,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          fieldKey: const Key('cashboxNotesField'),
          controller: controllers.notes,
          label: 'الملاحظات',
          icon: Icons.notes_rounded,
          accentColor: accentColor,
          minLines: 1,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _CashboxMoneyField extends StatelessWidget {
  const _CashboxMoneyField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.decimalPlaces,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.cashbox,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        AppMoneyInputFormatter(decimalPlaces: decimalPlaces),
      ],
    );
  }
}

class _CashboxFieldRow extends StatelessWidget {
  const _CashboxFieldRow({required this.children});

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
