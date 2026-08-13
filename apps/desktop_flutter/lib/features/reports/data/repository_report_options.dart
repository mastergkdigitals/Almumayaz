part of 'repository_report_data_service.dart';

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterOption> _saleTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('cash', 'نقدي'),
  ReportFilterOption('credit', 'آجل'),
  ReportFilterOption('installments', 'أقساط'),
];

const List<ReportFilterOption> _purchaseTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('local', 'محلي'),
  ReportFilterOption('import', 'إستيراد'),
  ReportFilterOption('return', 'إرجاع'),
];

const List<ReportFilterOption> _purchasePaymentOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('cash', 'نقدي'),
  ReportFilterOption('credit', 'آجل'),
];

const List<ReportFilterOption> _stockStateOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('available', 'متوفر'),
  ReportFilterOption('out', 'نافد'),
];

const List<ReportFilterOption> _cashboxTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('in', 'قبض'),
  ReportFilterOption('out', 'صرف'),
];

const List<ReportFilterOption> _partyTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('customer', 'زبون'),
  ReportFilterOption('supplier', 'مجهز'),
  ReportFilterOption('both', 'زبون ومجهز'),
];

const List<ReportFilterOption> _directionOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('receivable', 'لنا'),
  ReportFilterOption('payable', 'علينا'),
  ReportFilterOption('zero', 'صفر'),
];

const List<ReportFilterOption> _debtTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('debt', 'دين'),
  ReportFilterOption('installment', 'قسط'),
];

List<ReportFilterOption> _entityOptions<T>(
  Iterable<T> values, {
  required EntityId Function(T value) idOf,
  required String Function(T value) labelOf,
}) {
  final sorted = values.toList()
    ..sort((first, second) => labelOf(first).compareTo(labelOf(second)));
  return [
    const ReportFilterOption('all', 'الكل'),
    for (final value in sorted)
      ReportFilterOption(idOf(value).value, labelOf(value)),
  ];
}

List<ReportFilterOption> _itemOptions(Iterable<Item> items) =>
    _entityOptions(
      items,
      idOf: (item) => item.entityId,
      labelOf: (item) => '${item.code} - ${item.name}',
    );

bool _canBuy(Party party) =>
    party.type == PartyType.customer ||
    party.type == PartyType.customerAndSupplier;

bool _canSupply(Party party) =>
    party.type == PartyType.supplier ||
    party.type == PartyType.customerAndSupplier;

int _compareSalesNewestFirst(SalesInvoice first, SalesInvoice second) {
  final byDate = second.date.compareTo(first.date);
  if (byDate != 0) return byDate;
  final byTime = second.minuteOfDay.compareTo(first.minuteOfDay);
  return byTime != 0
      ? byTime
      : second.documentNumber.compareTo(first.documentNumber);
}

int _comparePurchasesNewestFirst(
  PurchaseInvoice first,
  PurchaseInvoice second,
) {
  final byDate = second.date.compareTo(first.date);
  if (byDate != 0) return byDate;
  final byTime = second.minuteOfDay.compareTo(first.minuteOfDay);
  return byTime != 0
      ? byTime
      : second.documentNumber.compareTo(first.documentNumber);
}

String _date(DateTime value) => AppFormatters.date(value);

String _time(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final period = value.hour < 12 ? 'ص' : 'م';
  return '${hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')} $period';
}

String _money(Money value) => AppFormatters.money(
      value.majorUnits,
      decimalPlaces: value.currency.decimalPlaces,
    );

String _availableLabel(String? live, String snapshot) {
  final liveValue = live?.trim() ?? '';
  if (liveValue.isNotEmpty) return liveValue;
  final snapshotValue = snapshot.trim();
  return snapshotValue.isEmpty ? 'سجل مفقود' : snapshotValue;
}

String _firstWarehouseSnapshot(List<SalesInvoiceLine> lines) =>
    lines.isEmpty ? '' : lines.first.warehouseNameSnapshot;

String _firstPurchaseWarehouseSnapshot(List<PurchaseInvoiceLine> lines) =>
    lines.isEmpty ? '' : lines.first.warehouseNameSnapshot;

String _saleTypeValue(SalesSettlementKind value) => switch (value) {
      SalesSettlementKind.cash => 'cash',
      SalesSettlementKind.credit => 'credit',
      SalesSettlementKind.installments => 'installments',
    };

String _saleTypeLabel(SalesSettlementKind value) => switch (value) {
      SalesSettlementKind.cash => 'نقدي',
      SalesSettlementKind.credit => 'آجل',
      SalesSettlementKind.installments => 'أقساط',
    };

String _purchaseTypeValue(PurchaseTransactionKind value) => switch (value) {
      PurchaseTransactionKind.local => 'local',
      PurchaseTransactionKind.import => 'import',
      PurchaseTransactionKind.returnPurchase => 'return',
    };

String _purchaseTypeLabel(PurchaseTransactionKind value) => switch (value) {
      PurchaseTransactionKind.local => 'محلي',
      PurchaseTransactionKind.import => 'إستيراد',
      PurchaseTransactionKind.returnPurchase => 'إرجاع',
    };

String _purchasePaymentValue(PurchaseSettlementKind value) => switch (value) {
      PurchaseSettlementKind.cash => 'cash',
      PurchaseSettlementKind.credit => 'credit',
    };

String _purchasePaymentLabel(PurchaseSettlementKind value) => switch (value) {
      PurchaseSettlementKind.cash => 'نقدي',
      PurchaseSettlementKind.credit => 'آجل',
    };

String _partyTypeValue(PartyType value) => switch (value) {
      PartyType.customer => 'customer',
      PartyType.supplier => 'supplier',
      PartyType.customerAndSupplier => 'both',
      PartyType.employee => 'employee',
    };

String _balanceDirectionValue(Money value) {
  if (value.isPositive) return 'receivable';
  if (value.isNegative) return 'payable';
  return 'zero';
}

String _balanceDirectionLabel(Money value) {
  if (value.isPositive) return 'لنا';
  if (value.isNegative) return 'علينا';
  return 'صفر';
}
