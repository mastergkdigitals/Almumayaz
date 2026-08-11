part of 'purchase_screen.dart';

const _purchaseTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'محلي', label: 'محلي'),
  AppDropdownOption(value: 'إستيراد', label: 'إستيراد'),
  AppDropdownOption(value: 'إرجاع', label: 'إرجاع'),
];

const _purchasePaymentTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
];

const _purchaseCurrencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

class _PurchaseInvoiceViewData {
  const _PurchaseInvoiceViewData({
    required this.source,
    required this.documentNumber,
    required this.dateTime,
    required this.warehouseId,
    required this.warehouse,
    required this.purchaseType,
    required this.paymentType,
    required this.currency,
    required this.exchangeRate,
    required this.supplierName,
    required this.notes,
    required this.expenses,
    required this.invoiceDiscount,
    required this.discountPercentage,
    required this.paid,
    required this.remaining,
    required this.currentBalance,
    required this.searchDetails,
    required this.searchTerms,
    required this.items,
  });

  final PurchaseInvoice source;
  final int documentNumber;

  EntityId get entityId => source.id;

  final DateTime dateTime;
  final EntityId warehouseId;
  final String warehouse;
  final String purchaseType;
  final String paymentType;
  final String currency;
  final String exchangeRate;
  final String supplierName;
  final String notes;
  final String expenses;
  final String invoiceDiscount;
  final String discountPercentage;
  final String paid;
  final String remaining;
  final String currentBalance;
  final String searchDetails;
  final List<String> searchTerms;
  final List<AppPurchaseInvoiceTableRowData> items;
}

enum _PurchaseDiscountInputSource { amount, percentage }

typedef _PurchaseFormSnapshot = ({
  DateTime invoiceDateTime,
  String warehouse,
  String purchaseType,
  String paymentType,
  String currency,
  String exchangeRate,
  String supplierName,
  String? supplierId,
  String notes,
  String expenses,
  String invoiceDiscount,
  String discountPercentage,
  String paid,
  String itemsSignature,
});
