part of 'purchase_screen.dart';

const _purchaseWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

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

const _purchaseSupplierOptions = <String>[
  'شركة الرافدين للتجهيز',
  'شركة التجارة العالمية',
  'مجهز الكرادة',
  'مجهز الفرات',
  'شركة الموصل الحديثة',
];

class _DemoPurchaseInvoice {
  const _DemoPurchaseInvoice({
    required this.source,
    required this.id,
    required this.dateTime,
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
  final String id;
  final DateTime dateTime;
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

enum _PurchaseNavigation { first, previous, next, last }

enum _PurchaseDiscountInputSource { amount, percentage }

typedef _PurchaseFormSnapshot = ({
  DateTime invoiceDateTime,
  String warehouse,
  String purchaseType,
  String paymentType,
  String currency,
  String exchangeRate,
  String supplierName,
  String notes,
  String expenses,
  String invoiceDiscount,
  String discountPercentage,
  String paid,
  String itemsSignature,
});
