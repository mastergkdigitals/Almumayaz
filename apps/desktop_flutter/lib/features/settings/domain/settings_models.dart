import '../../../core/domain/business_values.dart';

enum PurchaseKind { local, import, returnPurchase }

enum PaymentKind { cash, credit }

enum SaleKind { cash, credit, installments }

enum CashboxMovementKind { receipt, payment }

enum PrintPaperSize { a4, a5 }

class BusinessPolicySettings {
  BusinessPolicySettings({
    required this.defaultExchangeRate,
    required this.allowSaleWithInsufficientStock,
    required this.defaultCustomerDebtLimit,
    required this.defaultDebtDueDays,
    required this.overdueDebtAlertsEnabled,
  }) {
    if (defaultCustomerDebtLimit.isNegative) {
      throw ArgumentError.value(
        defaultCustomerDebtLimit,
        'defaultCustomerDebtLimit',
        'Debt limit must not be negative',
      );
    }
    if (defaultDebtDueDays < 0) {
      throw ArgumentError.value(
        defaultDebtDueDays,
        'defaultDebtDueDays',
        'Due days must not be negative',
      );
    }
  }

  final ExchangeRate defaultExchangeRate;
  final bool allowSaleWithInsufficientStock;
  final Money defaultCustomerDebtLimit;
  final int defaultDebtDueDays;
  final bool overdueDebtAlertsEnabled;
}

class PurchaseDefaults {
  const PurchaseDefaults({
    required this.warehouseId,
    required this.purchaseKind,
    required this.paymentKind,
    required this.currency,
  });

  final EntityId warehouseId;
  final PurchaseKind purchaseKind;
  final PaymentKind paymentKind;
  final AppCurrency currency;
}

class SalesDefaults {
  const SalesDefaults({
    required this.warehouseId,
    required this.saleKind,
    required this.currency,
  });

  final EntityId warehouseId;
  final SaleKind saleKind;
  final AppCurrency currency;
}

class CashboxDefaults {
  const CashboxDefaults({
    required this.movementKind,
    required this.mainAccountId,
  });

  final CashboxMovementKind movementKind;
  final EntityId mainAccountId;
}

class OperationalDefaults {
  const OperationalDefaults({
    required this.purchases,
    required this.sales,
    required this.cashbox,
  });

  final PurchaseDefaults purchases;
  final SalesDefaults sales;
  final CashboxDefaults cashbox;
}

/// Settings owned by one Windows installation rather than by the business.
class DeviceSettings {
  DeviceSettings({
    required String deviceId,
    required this.defaultPrinterName,
    required this.paperSize,
    required this.printCopies,
    required this.printPreviewEnabled,
  }) : deviceId = deviceId.trim() {
    if (this.deviceId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty');
    }
    if (printCopies < 1) {
      throw ArgumentError.value(printCopies, 'printCopies', 'Must be positive');
    }
  }

  final String deviceId;
  final String? defaultPrinterName;
  final PrintPaperSize paperSize;
  final int printCopies;
  final bool printPreviewEnabled;
}
