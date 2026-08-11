part of 'sales_screen.dart';

extension _SalesScreenCalculationsPart on _SalesScreenState {
  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _dirtyTracker.hasChanges(_currentSnapshot());
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    _setSalesState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _dirtyTracker.hasChanges(_currentSnapshot());
  }

  void _changeDate(DateTime value) {
    _setSalesState(() {
      _invoiceDateTime = DateTime(
        value.year,
        value.month,
        value.day,
        _invoiceDateTime.hour,
        _invoiceDateTime.minute,
      );
      _refreshSelectionState();
    });
  }

  void _changeWarehouse(String value) {
    if (_warehouseId == value) return;
    _setSalesState(() {
      _warehouseId = value;
      _refreshSelectionState();
    });
  }

  void _changeCustomerText(String _) {
    if (_selectedCustomerId == null) return;
    _setSalesState(() {
      _selectedCustomerId = null;
      _refreshSelectionState();
    });
  }

  void _selectCustomer(Party party) {
    _setSalesState(() {
      _selectedCustomerId = party.entityId;
      _refreshSelectionState();
    });
  }

  void _changeSaleType(String value) {
    if (_saleType == value) return;
    _setSalesState(() {
      if (_saleType != 'نقدي' && value == 'نقدي') {
        _nonCashReceivedText = _receivedController.text;
      }
      _saleType = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeCurrency(String value) {
    if (_currency == value) return;
    _setSalesState(() {
      final wasApplyingFormState = _isApplyingFormState;
      _isApplyingFormState = true;
      try {
        _currency = value;
        _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
          _activeItems.map(
            (item) => item.normalizeMonetaryValues(_currency),
          ),
        );
        _setControllerText(
          _invoiceDiscountController,
          _normalizedMoneyText(
            _invoiceDiscountController.text,
            _currency,
          ),
        );
        _nonCashReceivedText = _normalizedMoneyText(
          _nonCashReceivedText,
          _currency,
        );
        _tableDataVersion++;
        _syncCalculatedFields();
      } finally {
        _isApplyingFormState = wasApplyingFormState;
      }
      _refreshSelectionState();
    });
  }

  void _changeItems(List<AppSalesInvoiceTableRowData> items) {
    _setSalesState(() {
      _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
        items.map(
          (item) => item.withCalculatedValues(_currency),
        ),
      );
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeInvoiceDiscount(String _) {
    _setSalesState(() {
      _discountInputSource = _InvoiceDiscountInputSource.amount;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeDiscountPercentage(String _) {
    _setSalesState(() {
      _discountInputSource = _InvoiceDiscountInputSource.percentage;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeReceived(String value) {
    if (_saleType == 'نقدي') return;
    _setSalesState(() {
      _nonCashReceivedText = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _syncCalculatedFields() {
    final wasApplyingFormState = _isApplyingFormState;
    _isApplyingFormState = true;
    try {
      var quantity = 0;
      num rowDiscount = 0;
      num subtotal = 0;
      for (final item in _activeItems) {
        quantity += item.quantityValue;
        rowDiscount += item.totalDiscountValue;
        subtotal += item.totalValue;
      }

      _summaryQuantity = AppFormatters.quantity(quantity);
      _summaryDiscount = AppFormatters.moneyByCurrency(
        rowDiscount,
        _currency,
      );
      _summaryTotal = AppFormatters.moneyByCurrency(
        subtotal,
        _currency,
      );

      late final num invoiceDiscount;
      if (_discountInputSource ==
          _InvoiceDiscountInputSource.percentage) {
        final parsedPercentage = AppFormatters.parseNumber(
          _discountPercentageController.text,
        );
        final requestedPercentage = parsedPercentage ?? 0;
        final percentage = requestedPercentage.clamp(0, 100);
        if (parsedPercentage == null || percentage != requestedPercentage) {
          _setControllerText(
            _discountPercentageController,
            AppFormatters.money(percentage, decimalPlaces: 2),
          );
        }
        _setControllerText(
          _invoiceDiscountController,
          AppFormatters.moneyByCurrency(
            subtotal * percentage / 100,
            _currency,
          ),
        );
        invoiceDiscount =
            AppFormatters.parseNumber(_invoiceDiscountController.text) ?? 0;
      } else {
        final parsedDiscount = AppFormatters.parseNumber(
          _invoiceDiscountController.text,
        );
        final requestedDiscount = parsedDiscount ?? 0;
        invoiceDiscount = requestedDiscount.clamp(0, subtotal);
        if (parsedDiscount == null || invoiceDiscount != requestedDiscount) {
          _setControllerText(
            _invoiceDiscountController,
            AppFormatters.moneyByCurrency(invoiceDiscount, _currency),
          );
        }
        final percentage =
            subtotal == 0 ? 0 : invoiceDiscount * 100 / subtotal;
        _setControllerText(
          _discountPercentageController,
          AppFormatters.money(percentage, decimalPlaces: 2),
        );
      }

      final discountedTotal = subtotal - invoiceDiscount;
      final total = discountedTotal < 0 ? 0 : discountedTotal;
      late final num received;
      if (_saleType == 'نقدي') {
        received = total;
        _setControllerText(
          _receivedController,
          AppFormatters.moneyByCurrency(received, _currency),
        );
      } else {
        final parsedReceived = AppFormatters.parseNumber(
          _nonCashReceivedText,
        );
        final requestedReceived = parsedReceived ?? 0;
        received = requestedReceived < 0
            ? 0
            : requestedReceived > total
                ? total
                : requestedReceived;
        if (parsedReceived == null || received != requestedReceived) {
          _nonCashReceivedText = AppFormatters.moneyByCurrency(
            received,
            _currency,
          );
        }
        _setControllerText(
          _receivedController,
          _nonCashReceivedText,
        );
      }

      final unpaid = total - received;
      final remaining = unpaid < 0 ? 0 : unpaid;
      final currentBalance = _balanceBeforeInvoice + remaining;
      _setControllerText(
        _totalIqdController,
        AppFormatters.moneyByCurrency(total, _currency),
      );
      _setControllerText(
        _remainingIqdController,
        AppFormatters.moneyByCurrency(remaining, _currency),
      );
      _setControllerText(
        _currentBalanceIqdController,
        AppFormatters.moneyByCurrency(currentBalance, _currency),
      );
    } finally {
      _isApplyingFormState = wasApplyingFormState;
    }
  }

  void _setControllerText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) return;
    controller.text = value;
  }

  String _normalizedMoneyText(String value, String currencyCode) {
    final parsed = AppFormatters.parseNumber(value) ?? 0;
    return AppFormatters.moneyByCurrency(parsed, currencyCode);
  }
}
