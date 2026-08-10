import 'package:flutter/foundation.dart';

import '../../../core/domain/business_values.dart';

enum CashboxVoucherType {
  payment,
  receipt,
}

enum CashboxVoucherSourceKind {
  salesInvoice,
  purchaseInvoice,
}

/// Immutable identity of a system-generated cashbox posting.
///
/// Manual edit APIs deliberately cannot replace this metadata. Invoice
/// coordinators may rebuild the posting details while preserving [sourceId].
@immutable
class CashboxVoucherSource {
  const CashboxVoucherSource({
    required this.kind,
    required this.sourceId,
    required this.partyId,
  });

  final CashboxVoucherSourceKind kind;
  final EntityId sourceId;
  final EntityId partyId;
}

extension CashboxVoucherTypeLabel on CashboxVoucherType {
  String get label => switch (this) {
        CashboxVoucherType.payment => 'صرف',
        CashboxVoucherType.receipt => 'قبض',
      };
}

@immutable
class CashboxSubaccount {
  factory CashboxSubaccount({
    required String id,
    required String label,
    required num balanceIqd,
    required num balanceUsd,
  }) {
    return CashboxSubaccount.typed(
      entityId: EntityId(id),
      label: label,
      iqdBalance: Money.fromMajor(balanceIqd, AppCurrency.iqd),
      usdBalance: Money.fromMajor(balanceUsd, AppCurrency.usd),
    );
  }

  CashboxSubaccount.typed({
    required this.entityId,
    required this.label,
    required this.iqdBalance,
    required this.usdBalance,
  }) {
    _requireCurrency(iqdBalance, AppCurrency.iqd, 'iqdBalance');
    _requireCurrency(usdBalance, AppCurrency.usd, 'usdBalance');
  }

  final EntityId entityId;
  final String label;
  final Money iqdBalance;
  final Money usdBalance;

  String get id => entityId.value;
  num get balanceIqd => iqdBalance.majorUnits;
  num get balanceUsd => usdBalance.majorUnits;
}

@immutable
class CashboxMainAccount {
  factory CashboxMainAccount({
    required String id,
    required String label,
    required List<CashboxSubaccount> subaccounts,
  }) {
    return CashboxMainAccount.typed(
      entityId: EntityId(id),
      label: label,
      subaccounts: subaccounts,
    );
  }

  CashboxMainAccount.typed({
    required this.entityId,
    required this.label,
    required Iterable<CashboxSubaccount> subaccounts,
  }) : subaccounts = List.unmodifiable(subaccounts);

  final EntityId entityId;
  final String label;
  final List<CashboxSubaccount> subaccounts;

  String get id => entityId.value;
}

@immutable
class CashboxAccountBalance {
  factory CashboxAccountBalance({required num iqd, required num usd}) {
    return CashboxAccountBalance.typed(
      iqdMoney: Money.fromMajor(iqd, AppCurrency.iqd),
      usdMoney: Money.fromMajor(usd, AppCurrency.usd),
    );
  }

  CashboxAccountBalance.typed({
    required this.iqdMoney,
    required this.usdMoney,
  }) {
    _requireCurrency(iqdMoney, AppCurrency.iqd, 'iqdMoney');
    _requireCurrency(usdMoney, AppCurrency.usd, 'usdMoney');
  }

  final Money iqdMoney;
  final Money usdMoney;

  num get iqd => iqdMoney.majorUnits;
  num get usd => usdMoney.majorUnits;
}

@immutable
class CashboxVoucher {
  factory CashboxVoucher({
    required String id,
    required int number,
    required DateTime createdAt,
    required CashboxVoucherType type,
    required String mainAccountId,
    required String mainAccountLabel,
    required String subaccountId,
    required String subaccountLabel,
    required num exchangeRate,
    required num amountIqd,
    required num amountUsd,
    required num balanceBeforeIqd,
    required num balanceAfterIqd,
    required num balanceBeforeUsd,
    required num balanceAfterUsd,
    required String notes,
  }) {
    return CashboxVoucher.typed(
      entityId: EntityId(id),
      number: number,
      createdTimestamp: AuditTimestamp(createdAt),
      type: type,
      mainAccountEntityId: EntityId(mainAccountId),
      mainAccountLabel: mainAccountLabel,
      subaccountEntityId: EntityId(subaccountId),
      subaccountLabel: subaccountLabel,
      exchangeRateValue: ExchangeRate.parse(exchangeRate.toString()),
      iqdAmount: Money.fromMajor(amountIqd, AppCurrency.iqd),
      usdAmount: Money.fromMajor(amountUsd, AppCurrency.usd),
      iqdBalanceBefore:
          Money.fromMajor(balanceBeforeIqd, AppCurrency.iqd),
      iqdBalanceAfter: Money.fromMajor(balanceAfterIqd, AppCurrency.iqd),
      usdBalanceBefore:
          Money.fromMajor(balanceBeforeUsd, AppCurrency.usd),
      usdBalanceAfter: Money.fromMajor(balanceAfterUsd, AppCurrency.usd),
      notes: notes,
    );
  }

  CashboxVoucher.typed({
    required this.entityId,
    required this.number,
    required this.createdTimestamp,
    required this.type,
    required this.mainAccountEntityId,
    required this.mainAccountLabel,
    required this.subaccountEntityId,
    required this.subaccountLabel,
    required this.exchangeRateValue,
    required this.iqdAmount,
    required this.usdAmount,
    required this.iqdBalanceBefore,
    required this.iqdBalanceAfter,
    required this.usdBalanceBefore,
    required this.usdBalanceAfter,
    required this.notes,
    this.source,
  }) {
    _requireCurrency(iqdAmount, AppCurrency.iqd, 'iqdAmount');
    _requireCurrency(usdAmount, AppCurrency.usd, 'usdAmount');
    _requireCurrency(iqdBalanceBefore, AppCurrency.iqd, 'iqdBalanceBefore');
    _requireCurrency(iqdBalanceAfter, AppCurrency.iqd, 'iqdBalanceAfter');
    _requireCurrency(usdBalanceBefore, AppCurrency.usd, 'usdBalanceBefore');
    _requireCurrency(usdBalanceAfter, AppCurrency.usd, 'usdBalanceAfter');
  }

  final EntityId entityId;
  final int number;
  final AuditTimestamp createdTimestamp;
  final CashboxVoucherType type;
  final EntityId mainAccountEntityId;
  final String mainAccountLabel;
  final EntityId subaccountEntityId;
  final String subaccountLabel;
  final ExchangeRate exchangeRateValue;
  final Money iqdAmount;
  final Money usdAmount;
  final Money iqdBalanceBefore;
  final Money iqdBalanceAfter;
  final Money usdBalanceBefore;
  final Money usdBalanceAfter;
  final String notes;
  final CashboxVoucherSource? source;

  bool get isSystemGenerated => source != null;

  String get id => entityId.value;
  DateTime get createdAt => createdTimestamp.value.toLocal();
  String get mainAccountId => mainAccountEntityId.value;
  String get subaccountId => subaccountEntityId.value;
  num get exchangeRate => exchangeRateValue.value;
  num get amountIqd => iqdAmount.majorUnits;
  num get amountUsd => usdAmount.majorUnits;
  num get balanceBeforeIqd => iqdBalanceBefore.majorUnits;
  num get balanceAfterIqd => iqdBalanceAfter.majorUnits;
  num get balanceBeforeUsd => usdBalanceBefore.majorUnits;
  num get balanceAfterUsd => usdBalanceAfter.majorUnits;

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
    return CashboxVoucher.typed(
      entityId: entityId,
      number: number,
      createdTimestamp: createdAt == null
          ? createdTimestamp
          : AuditTimestamp(createdAt),
      type: type ?? this.type,
      mainAccountEntityId: mainAccountId == null
          ? mainAccountEntityId
          : EntityId(mainAccountId),
      mainAccountLabel: mainAccountLabel ?? this.mainAccountLabel,
      subaccountEntityId: subaccountId == null
          ? subaccountEntityId
          : EntityId(subaccountId),
      subaccountLabel: subaccountLabel ?? this.subaccountLabel,
      exchangeRateValue: exchangeRate == null
          ? exchangeRateValue
          : ExchangeRate.parse(exchangeRate.toString()),
      iqdAmount: amountIqd == null
          ? iqdAmount
          : Money.fromMajor(amountIqd, AppCurrency.iqd),
      usdAmount: amountUsd == null
          ? usdAmount
          : Money.fromMajor(amountUsd, AppCurrency.usd),
      iqdBalanceBefore: balanceBeforeIqd == null
          ? iqdBalanceBefore
          : Money.fromMajor(balanceBeforeIqd, AppCurrency.iqd),
      iqdBalanceAfter: balanceAfterIqd == null
          ? iqdBalanceAfter
          : Money.fromMajor(balanceAfterIqd, AppCurrency.iqd),
      usdBalanceBefore: balanceBeforeUsd == null
          ? usdBalanceBefore
          : Money.fromMajor(balanceBeforeUsd, AppCurrency.usd),
      usdBalanceAfter: balanceAfterUsd == null
          ? usdBalanceAfter
          : Money.fromMajor(balanceAfterUsd, AppCurrency.usd),
      notes: notes ?? this.notes,
      source: source,
    );
  }

  CashboxVoucher copyWithTyped({
    AuditTimestamp? createdTimestamp,
    CashboxVoucherType? type,
    EntityId? mainAccountEntityId,
    String? mainAccountLabel,
    EntityId? subaccountEntityId,
    String? subaccountLabel,
    ExchangeRate? exchangeRateValue,
    Money? iqdAmount,
    Money? usdAmount,
    Money? iqdBalanceBefore,
    Money? iqdBalanceAfter,
    Money? usdBalanceBefore,
    Money? usdBalanceAfter,
    String? notes,
  }) {
    return CashboxVoucher.typed(
      entityId: entityId,
      number: number,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      type: type ?? this.type,
      mainAccountEntityId:
          mainAccountEntityId ?? this.mainAccountEntityId,
      mainAccountLabel: mainAccountLabel ?? this.mainAccountLabel,
      subaccountEntityId: subaccountEntityId ?? this.subaccountEntityId,
      subaccountLabel: subaccountLabel ?? this.subaccountLabel,
      exchangeRateValue: exchangeRateValue ?? this.exchangeRateValue,
      iqdAmount: iqdAmount ?? this.iqdAmount,
      usdAmount: usdAmount ?? this.usdAmount,
      iqdBalanceBefore: iqdBalanceBefore ?? this.iqdBalanceBefore,
      iqdBalanceAfter: iqdBalanceAfter ?? this.iqdBalanceAfter,
      usdBalanceBefore: usdBalanceBefore ?? this.usdBalanceBefore,
      usdBalanceAfter: usdBalanceAfter ?? this.usdBalanceAfter,
      notes: notes ?? this.notes,
      source: source,
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
        iqdAmount.toPlainString(),
        usdAmount.toPlainString(),
        notes,
        createdAt.year,
        createdAt.month,
        createdAt.day,
      ].join(' ').toLowerCase();
}

@immutable
class CashboxSummary {
  factory CashboxSummary({
    required num balanceIqd,
    required num balanceUsd,
    required num todayReceiptIqd,
    required num todayPaymentIqd,
    required num todayReceiptUsd,
    required num todayPaymentUsd,
  }) {
    return CashboxSummary.typed(
      iqdBalance: Money.fromMajor(balanceIqd, AppCurrency.iqd),
      usdBalance: Money.fromMajor(balanceUsd, AppCurrency.usd),
      iqdTodayReceipt: Money.fromMajor(todayReceiptIqd, AppCurrency.iqd),
      iqdTodayPayment: Money.fromMajor(todayPaymentIqd, AppCurrency.iqd),
      usdTodayReceipt: Money.fromMajor(todayReceiptUsd, AppCurrency.usd),
      usdTodayPayment: Money.fromMajor(todayPaymentUsd, AppCurrency.usd),
    );
  }

  CashboxSummary.typed({
    required this.iqdBalance,
    required this.usdBalance,
    required this.iqdTodayReceipt,
    required this.iqdTodayPayment,
    required this.usdTodayReceipt,
    required this.usdTodayPayment,
  }) {
    _requireCurrency(iqdBalance, AppCurrency.iqd, 'iqdBalance');
    _requireCurrency(usdBalance, AppCurrency.usd, 'usdBalance');
    _requireCurrency(iqdTodayReceipt, AppCurrency.iqd, 'iqdTodayReceipt');
    _requireCurrency(iqdTodayPayment, AppCurrency.iqd, 'iqdTodayPayment');
    _requireCurrency(usdTodayReceipt, AppCurrency.usd, 'usdTodayReceipt');
    _requireCurrency(usdTodayPayment, AppCurrency.usd, 'usdTodayPayment');
  }

  final Money iqdBalance;
  final Money usdBalance;
  final Money iqdTodayReceipt;
  final Money iqdTodayPayment;
  final Money usdTodayReceipt;
  final Money usdTodayPayment;

  num get balanceIqd => iqdBalance.majorUnits;
  num get balanceUsd => usdBalance.majorUnits;
  num get todayReceiptIqd => iqdTodayReceipt.majorUnits;
  num get todayPaymentIqd => iqdTodayPayment.majorUnits;
  num get todayReceiptUsd => usdTodayReceipt.majorUnits;
  num get todayPaymentUsd => usdTodayPayment.majorUnits;
}

void _requireCurrency(Money value, AppCurrency currency, String name) {
  if (value.currency != currency) {
    throw ArgumentError.value(value, name, 'Must use ${currency.code}');
  }
}
