part of 'sales_screen.dart';

extension _SalesScreenCalculationsPart on _SalesScreenState {
  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    _setSalesState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _currentSnapshot() != _baseline;
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
    if (_warehouse == value) return;
    _setSalesState(() {
      _warehouse = value;
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
      _currency = value;
      _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
        _activeItems.map(
          (item) => item.withCalculatedValues(_currency),
        ),
      );
      _tableDataVersion++;
      _syncCalculatedFields();
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
        rowDiscount += item.discountValue;
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
        final percentage =
            AppFormatters.parseNumber(_discountPercentageController.text) ??
                0;
        invoiceDiscount = subtotal * percentage / 100;
        _setControllerText(
          _invoiceDiscountController,
          AppFormatters.moneyByCurrency(invoiceDiscount, _currency),
        );
      } else {
        invoiceDiscount =
            AppFormatters.parseNumber(_invoiceDiscountController.text) ?? 0;
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
        final requestedReceived =
            AppFormatters.parseNumber(_nonCashReceivedText) ?? 0;
        received = requestedReceived < 0
            ? 0
            : requestedReceived > total
                ? total
                : requestedReceived;
        if (received != requestedReceived) {
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

}
