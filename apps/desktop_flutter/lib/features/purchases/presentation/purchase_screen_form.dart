part of 'purchase_screen.dart';

extension _PurchaseFormState on _PurchaseScreenState {
  void _loadInvoice(_DemoPurchaseInvoice invoice) {
    _isApplyingFormState = true;
    _selectedInvoice = invoice;
    _invoiceNumberController.text = invoice.id;
    _invoiceDateTime = invoice.dateTime;
    _warehouse = invoice.warehouse;
    _purchaseType = invoice.purchaseType;
    _paymentType = invoice.paymentType;
    _currency = invoice.currency;
    _exchangeRateController.text = invoice.exchangeRate;
    _supplierNameController.text = invoice.supplierName;
    _notesController.text = invoice.notes;
    _expensesController.text = invoice.expenses;
    _invoiceDiscountController.text = invoice.invoiceDiscount;
    _discountPercentageController.text = invoice.discountPercentage;
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    _balanceBeforeInvoice =
        (AppFormatters.parseNumber(invoice.currentBalance) ?? 0) -
            (AppFormatters.parseNumber(invoice.remaining) ?? 0);
    _nonCashPaidText =
        invoice.paymentType == 'نقدي' ? '0' : invoice.paid;
    _paidController.text = _nonCashPaidText;
    _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      invoice.items,
    );
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _selectedInvoice = null;
    _invoiceNumberController.text = '$_nextInvoiceNumber';
    _invoiceDateTime = DateTime.now();
    _warehouse = _defaultWarehouse;
    _purchaseType = _defaultPurchaseType;
    _paymentType = _defaultPaymentType;
    _currency = _defaultCurrency;
    _exchangeRateController.text = _defaultExchangeRate;
    _supplierNameController.clear();
    _notesController.clear();
    _expensesController.text = '0';
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    _balanceBeforeInvoice = 0;
    _nonCashPaidText = '0';
    _paidController.text = '0';
    _activeItems = const [AppPurchaseInvoiceTableRowData()];
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  _PurchaseFormSnapshot _currentSnapshot() => (
        invoiceDateTime: _invoiceDateTime,
        warehouse: _warehouse,
        purchaseType: _purchaseType,
        paymentType: _paymentType,
        currency: _currency,
        exchangeRate: _exchangeRateController.text,
        supplierName: _supplierNameController.text,
        notes: _notesController.text,
        expenses: _expensesController.text,
        invoiceDiscount: _invoiceDiscountController.text,
        discountPercentage: _discountPercentageController.text,
        paid: _paidController.text,
        itemsSignature: _itemsSignature(_activeItems),
      );

  String _itemsSignature(
    Iterable<AppPurchaseInvoiceTableRowData> items,
  ) {
    return items
        .map(
          (item) => [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.container,
            item.purchasePrice,
            item.discount,
            item.priceAfterDiscount,
            item.total,
            item.cost,
            item.totalCost,
            item.salePrice,
          ].join('\u001f'),
        )
        .join('\u001e');
  }

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    _setPurchaseState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _currentSnapshot() != _baseline;
  }

  void _changeDate(DateTime value) {
    _setPurchaseState(() {
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
    _setPurchaseState(() {
      _warehouse = value;
      _refreshSelectionState();
    });
  }

  void _changePurchaseType(String value) {
    if (_purchaseType == value) return;
    _setPurchaseState(() {
      _purchaseType = value;
      _refreshSelectionState();
    });
  }

  void _changePaymentType(String value) {
    if (_paymentType == value) return;
    _setPurchaseState(() {
      if (_paymentType != 'نقدي' && value == 'نقدي') {
        _nonCashPaidText = _paidController.text;
      }
      _paymentType = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeCurrency(String value) {
    if (_currency == value) return;
    _setPurchaseState(() {
      final wasApplyingFormState = _isApplyingFormState;
      _isApplyingFormState = true;
      try {
        _currency = value;
        _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
          _activeItems.map((item) => item.withCurrencyPrecision(value)),
        );
        _setControllerText(
          _expensesController,
          _moneyTextAtCurrentPrecision(_expensesController.text),
        );
        _setControllerText(
          _invoiceDiscountController,
          _moneyTextAtCurrentPrecision(_invoiceDiscountController.text),
        );
        _nonCashPaidText = _moneyTextAtCurrentPrecision(_nonCashPaidText);
        _setControllerText(_paidController, _nonCashPaidText);
        _tableDataVersion++;
        _syncCalculatedFields();
        _refreshSelectionState();
      } finally {
        _isApplyingFormState = wasApplyingFormState;
      }
    });
  }

  void _changeItems(List<AppPurchaseInvoiceTableRowData> items) {
    _setPurchaseState(() {
      _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(items);
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeExpenses(String _) {
    _setPurchaseState(() {
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeInvoiceDiscount(String _) {
    _setPurchaseState(() {
      _discountInputSource = _PurchaseDiscountInputSource.amount;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeDiscountPercentage(String _) {
    _setPurchaseState(() {
      _discountInputSource = _PurchaseDiscountInputSource.percentage;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changePaid(String value) {
    if (_paymentType == 'نقدي') return;
    _setPurchaseState(() {
      _nonCashPaidText = value;
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
      num lineBaseTotal = 0;
      for (final item in _activeItems) {
        quantity += item.quantityValue;
        rowDiscount += item.effectiveDiscountValue;
        lineBaseTotal += item.totalValue;
      }

      final parsedExpenses =
          AppFormatters.parseNumber(_expensesController.text);
      final requestedExpenses = parsedExpenses ?? 0;
      final expenses = requestedExpenses < 0 ? 0 : requestedExpenses;
      if (parsedExpenses == null || expenses != requestedExpenses) {
        _setControllerText(
          _expensesController,
          AppFormatters.moneyByCurrency(expenses, _currency),
        );
      }
      final discountBase = lineBaseTotal + expenses;
      late final num invoiceDiscount;
      if (_discountInputSource ==
          _PurchaseDiscountInputSource.percentage) {
        final parsedPercentage =
            AppFormatters.parseNumber(_discountPercentageController.text);
        final requestedPercentage = parsedPercentage ?? 0;
        final percentage = requestedPercentage < 0
            ? 0
            : requestedPercentage > 100
                ? 100
                : requestedPercentage;
        if (parsedPercentage == null || percentage != requestedPercentage) {
          _setControllerText(
            _discountPercentageController,
            AppFormatters.money(percentage, decimalPlaces: 2),
          );
        }
        final formattedDiscount = AppFormatters.moneyByCurrency(
          discountBase * percentage / 100,
          _currency,
        );
        invoiceDiscount =
            AppFormatters.parseNumber(formattedDiscount) ?? 0;
        _setControllerText(
          _invoiceDiscountController,
          formattedDiscount,
        );
      } else {
        final parsedDiscount =
            AppFormatters.parseNumber(_invoiceDiscountController.text);
        final requestedDiscount = parsedDiscount ?? 0;
        invoiceDiscount = requestedDiscount < 0
            ? 0
            : requestedDiscount > discountBase
                ? discountBase
                : requestedDiscount;
        if (parsedDiscount == null || invoiceDiscount != requestedDiscount) {
          _setControllerText(
            _invoiceDiscountController,
            AppFormatters.moneyByCurrency(invoiceDiscount, _currency),
          );
        }
        final percentage =
            discountBase == 0 ? 0 : invoiceDiscount * 100 / discountBase;
        _setControllerText(
          _discountPercentageController,
          AppFormatters.money(percentage, decimalPlaces: 2),
        );
      }

      _invoiceAdjustment = expenses - invoiceDiscount;
      final rowCalculation = calculatePurchaseInvoiceRows(
        rows: _activeItems,
        currencyCode: _currency,
        invoiceAdjustment: _invoiceAdjustment,
      );
      _activeItems = rowCalculation.rows;
      _summaryQuantity = AppFormatters.quantity(quantity);
      _summaryDiscount = AppFormatters.moneyByCurrency(
        rowDiscount,
        _currency,
      );
      _summaryTotal = AppFormatters.moneyByCurrency(
        lineBaseTotal,
        _currency,
      );
      _summaryTotalCost = rowCalculation.totalCost;

      final total =
          AppFormatters.parseNumber(rowCalculation.totalCost) ?? 0;
      late final num paid;
      if (_paymentType == 'نقدي') {
        paid = total;
        _setControllerText(
          _paidController,
          AppFormatters.moneyByCurrency(paid, _currency),
        );
      } else {
        final parsedPaid = AppFormatters.parseNumber(_nonCashPaidText);
        final requestedPaid = parsedPaid ?? 0;
        paid = requestedPaid < 0
            ? 0
            : requestedPaid > total
                ? total
                : requestedPaid;
        if (parsedPaid == null || paid != requestedPaid) {
          _nonCashPaidText = AppFormatters.moneyByCurrency(
            paid,
            _currency,
          );
        }
        _setControllerText(_paidController, _nonCashPaidText);
      }

      final unpaid = _paymentType == 'نقدي' ? 0 : total - paid;
      final remaining = unpaid < 0 ? 0 : unpaid;
      final currentBalance = _balanceBeforeInvoice + remaining;
      _setControllerText(
        _totalController,
        AppFormatters.moneyByCurrency(total, _currency),
      );
      _setControllerText(
        _remainingController,
        AppFormatters.moneyByCurrency(remaining, _currency),
      );
      _setControllerText(
        _currentBalanceController,
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

  String _moneyTextAtCurrentPrecision(String value) {
    return AppFormatters.moneyByCurrency(
      AppFormatters.parseNumber(value) ?? 0,
      _currency,
    );
  }

  bool _validateForm() {
    final supplierName = _supplierNameController.text.trim();
    if (supplierName.isEmpty) {
      AppToast.showWarning(context, 'أدخل اسم المجهز أولاً');
      return false;
    }
    if (_resolveSupplierId(supplierName) == null) {
      AppToast.showWarning(context, 'اختر مجهزاً موجوداً من القائمة');
      return false;
    }

    final meaningfulItems = _activeItems.where((item) => !item.isEmpty).toList();
    if (meaningfulItems.any((item) => !item.hasRequiredValues)) {
      AppToast.showWarning(
        context,
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      );
      return false;
    }
    if (meaningfulItems.any((item) => !item.hasValidNumericValues)) {
      AppToast.showWarning(context, 'تحقق من القيم الرقمية في سطور المواد');
      return false;
    }
    if (meaningfulItems.any((item) => !item.hasValidLineDiscount)) {
      AppToast.showWarning(
        context,
        'يجب ألا يتجاوز خصم السطر إجمالي السطر',
      );
      return false;
    }
    if (meaningfulItems.isEmpty) {
      AppToast.showWarning(context, 'أضف مادة واحدة مكتملة على الأقل');
      return false;
    }
    if (meaningfulItems.any(
      (item) => _resolveItemId(
        item.code,
        item.name,
        itemId: item.itemId,
      ) == null,
    )) {
      AppToast.showWarning(context, 'اختر مادة موجودة لكل سطر');
      return false;
    }
    if (meaningfulItems.any(
      (item) => !_warehouseIdsByLabel.containsKey(item.warehouse),
    )) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً لكل سطر');
      return false;
    }
    return true;
  }

  PurchaseInvoice _domainInvoiceFromForm({required EntityId entityId}) {
    final items = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      _activeItems.where((item) => !item.isEmpty),
    );
    final currency = AppCurrency.parse(_currency);
    final supplierName = _supplierNameController.text.trim();
    final lines = <PurchaseInvoiceLine>[];
    final newLineNonce = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < items.length; index++) {
      final row = items[index];
      final lineId = row.lineId == null
          ? EntityId('${entityId.value}-line-$newLineNonce-${index + 1}')
          : EntityId(row.lineId!);
      lines.add(
        PurchaseInvoiceLine(
          id: lineId,
          itemId: _resolveItemId(
            row.code,
            row.name,
            itemId: row.itemId,
          )!,
          warehouseId: _warehouseIdsByLabel[row.warehouse]!,
          quantity: WholeQuantity(row.quantityValue),
          containerQuantity: WholeQuantity(
            AppFormatters.parseInteger(row.container) ?? 0,
          ),
          purchasePrice: Money.fromMajor(row.purchasePriceValue, currency),
          lineDiscount: Money.fromMajor(row.discountValue, currency),
          salePrice: Money.fromMajor(
            AppFormatters.parseNumber(row.salePrice) ?? 0,
            currency,
          ),
          itemCodeSnapshot: row.code.trim(),
          itemNameSnapshot: row.name.trim(),
          warehouseNameSnapshot: row.warehouse,
        ),
      );
    }
    return PurchaseInvoice(
      id: entityId,
      documentNumber: int.parse(_invoiceNumberController.text),
      date: BusinessDate.fromDateTime(_invoiceDateTime),
      minuteOfDay: _invoiceDateTime.hour * 60 + _invoiceDateTime.minute,
      supplierId: _resolveSupplierId(supplierName)!,
      supplierNameSnapshot: supplierName,
      defaultWarehouseId: _warehouseIdsByLabel[_warehouse]!,
      currency: currency,
      exchangeRate: ExchangeRate.parse(_exchangeRateController.text),
      purchaseKind: switch (_purchaseType) {
        'إستيراد' => PurchaseTransactionKind.import,
        'إرجاع' => PurchaseTransactionKind.returnPurchase,
        _ => PurchaseTransactionKind.local,
      },
      settlementKind: _paymentType == 'نقدي'
          ? PurchaseSettlementKind.cash
          : PurchaseSettlementKind.credit,
      lines: lines,
      expenses: Money.parse(_expensesController.text, currency),
      invoiceDiscount: Money.parse(_invoiceDiscountController.text, currency),
      paid: Money.parse(_paidController.text, currency),
      balanceAfterInvoice:
          Money.parse(_currentBalanceController.text, currency),
      notes: _notesController.text.trim(),
    );
  }

  EntityId? _resolveSupplierId(String name) {
    final normalized = normalizePartyName(name);
    for (final entry in _supplierIdsByName.entries) {
      if (normalizePartyName(entry.key) == normalized) return entry.value;
    }
    return null;
  }

  EntityId? _resolveItemId(
    String code,
    String name, {
    String? itemId,
  }) {
    if (itemId != null) {
      final resolvedId = EntityId(itemId);
      return _knownItemIds.contains(resolvedId) ? resolvedId : null;
    }
    final legacyId = _legacyPurchaseItemId(code, name);
    if (legacyId != null) return legacyId;
    final codeId = _itemIdsByLabel[_normalizedLookup(code)];
    final nameId = _itemIdsByLabel[_normalizedLookup(name)];
    return codeId != null && codeId == nameId ? codeId : null;
  }

  EntityId? _legacyPurchaseItemId(String code, String name) =>
      switch ('${code.trim()}|${_normalizedLookup(name)}') {
        'P1001|ورق طباعة a4' => EntityId('item-003'),
        'P1002|حبر طابعة' => EntityId('item-002'),
        'P2001|طابعة حرارية' => EntityId('item-007'),
        'P2002|ماسح باركود' => EntityId('item-008'),
        'P3001|حافظة مستندات' => EntityId('item-006'),
        _ => null,
      };

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
