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

class _PurchaseReturnLineDraft {
  const _PurchaseReturnLineDraft({
    required this.sourceLine,
    required this.previouslyReturnedQuantity,
    required this.previouslyReturnedDiscount,
    required this.maximumQuantity,
    required this.itemCode,
    required this.itemName,
    required this.warehouseId,
    required this.warehouseName,
    this.returnLineId,
    this.quantityText = '0',
  });

  final PurchaseInvoiceLine sourceLine;
  final int previouslyReturnedQuantity;
  final Money previouslyReturnedDiscount;
  final int maximumQuantity;
  final String itemCode;
  final String itemName;
  final EntityId? returnLineId;
  final String warehouseId;
  final String warehouseName;
  final String quantityText;

  int get quantity => AppFormatters.parseInteger(quantityText) ?? 0;

  int get effectiveQuantity => quantity < 0
      ? 0
      : quantity > maximumQuantity
          ? maximumQuantity
          : quantity;

  bool get hasValidQuantity =>
      quantity >= 0 && quantity <= maximumQuantity;

  Money get lineDiscount => PurchaseReturnPolicy.lineDiscount(
        sourceLine: sourceLine,
        totalReturnedQuantity:
            previouslyReturnedQuantity + effectiveQuantity,
        discountAlreadyReturned: previouslyReturnedDiscount,
      );

  Money get grossTotal => sourceLine.purchasePrice * effectiveQuantity;

  Money get netTotal => grossTotal - lineDiscount;

  _PurchaseReturnLineDraft copyWith({
    String? warehouseId,
    String? warehouseName,
    String? quantityText,
  }) {
    return _PurchaseReturnLineDraft(
      sourceLine: sourceLine,
      previouslyReturnedQuantity: previouslyReturnedQuantity,
      previouslyReturnedDiscount: previouslyReturnedDiscount,
      maximumQuantity: maximumQuantity,
      itemCode: itemCode,
      itemName: itemName,
      returnLineId: returnLineId,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      quantityText: quantityText ?? this.quantityText,
    );
  }
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
  String? originalPurchaseInvoiceId,
  String notes,
  String expenses,
  String invoiceDiscount,
  String discountPercentage,
  String paid,
  String itemsSignature,
});
