import 'package:flutter/foundation.dart';

enum CashboxVoucherType {
  payment,
  receipt,
}

extension CashboxVoucherTypeLabel on CashboxVoucherType {
  String get label => switch (this) {
        CashboxVoucherType.payment => 'صرف',
        CashboxVoucherType.receipt => 'قبض',
      };
}

@immutable
class CashboxSubaccount {
  const CashboxSubaccount({
    required this.id,
    required this.label,
    required this.balanceIqd,
    required this.balanceUsd,
  });

  final String id;
  final String label;
  final num balanceIqd;
  final num balanceUsd;
}

@immutable
class CashboxMainAccount {
  const CashboxMainAccount({
    required this.id,
    required this.label,
    required this.subaccounts,
  });

  final String id;
  final String label;
  final List<CashboxSubaccount> subaccounts;
}

@immutable
class CashboxVoucher {
  const CashboxVoucher({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.type,
    required this.mainAccountId,
    required this.mainAccountLabel,
    required this.subaccountId,
    required this.subaccountLabel,
    required this.exchangeRate,
    required this.amountIqd,
    required this.amountUsd,
    required this.balanceBeforeIqd,
    required this.balanceAfterIqd,
    required this.balanceBeforeUsd,
    required this.balanceAfterUsd,
    required this.notes,
  });

  final String id;
  final int number;
  final DateTime createdAt;
  final CashboxVoucherType type;
  final String mainAccountId;
  final String mainAccountLabel;
  final String subaccountId;
  final String subaccountLabel;
  final num exchangeRate;
  final num amountIqd;
  final num amountUsd;
  final num balanceBeforeIqd;
  final num balanceAfterIqd;
  final num balanceBeforeUsd;
  final num balanceAfterUsd;
  final String notes;

  CashboxVoucher copyWith({
    DateTime? createdAt,
    CashboxVoucherType? type,
    String? mainAccountId,
    String? mainAccountLabel,
    String? subaccountId,
    String? subaccountLabel,
    num? exchangeRate,
    num? amountIqd,
    num? amountUsd,
    num? balanceBeforeIqd,
    num? balanceAfterIqd,
    num? balanceBeforeUsd,
    num? balanceAfterUsd,
    String? notes,
  }) {
    return CashboxVoucher(
      id: id,
      number: number,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      mainAccountId: mainAccountId ?? this.mainAccountId,
      mainAccountLabel: mainAccountLabel ?? this.mainAccountLabel,
      subaccountId: subaccountId ?? this.subaccountId,
      subaccountLabel: subaccountLabel ?? this.subaccountLabel,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      amountIqd: amountIqd ?? this.amountIqd,
      amountUsd: amountUsd ?? this.amountUsd,
      balanceBeforeIqd: balanceBeforeIqd ?? this.balanceBeforeIqd,
      balanceAfterIqd: balanceAfterIqd ?? this.balanceAfterIqd,
      balanceBeforeUsd: balanceBeforeUsd ?? this.balanceBeforeUsd,
      balanceAfterUsd: balanceAfterUsd ?? this.balanceAfterUsd,
      notes: notes ?? this.notes,
    );
  }

  String get searchText => [
        number,
        '${createdAt.year}/'
            '${createdAt.month.toString().padLeft(2, '0')}/'
            '${createdAt.day.toString().padLeft(2, '0')}',
        type.label,
        mainAccountLabel,
        subaccountLabel,
        amountIqd,
        amountUsd,
        notes,
        createdAt.year,
        createdAt.month,
        createdAt.day,
      ].join(' ').toLowerCase();
}

@immutable
class CashboxSummary {
  const CashboxSummary({
    required this.balanceIqd,
    required this.balanceUsd,
    required this.todayReceiptIqd,
    required this.todayPaymentIqd,
    required this.todayReceiptUsd,
    required this.todayPaymentUsd,
  });

  final num balanceIqd;
  final num balanceUsd;
  final num todayReceiptIqd;
  final num todayPaymentIqd;
  final num todayReceiptUsd;
  final num todayPaymentUsd;
}
