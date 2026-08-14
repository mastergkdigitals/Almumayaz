part of 'purchase_screen.dart';

extension on _PurchaseScreenState {
  bool _allowsPartyCreate() =>
      _store?.allowsFeatureAction('parties', PermissionAction.create) ?? false;

  bool _allowsItemCreate() =>
      _store?.allowsFeatureAction('items', PermissionAction.create) ?? false;

  Future<void> _createSupplier() async {
    final store = _store;
    if (store == null || !_allowsPartyCreate()) return;
    final values = await AppQuickCreateDialog.showParty<PartyType>(
      context: context,
      title: 'إضافة مجهز جديد',
      prompt: 'هذا المجهز غير موجود، هل تود إضافته؟',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: AppModuleColors.purchases,
      keyPrefix: 'purchaseQuickSupplier',
      initialName: _supplierNameController.text,
      initialType: PartyType.supplier,
      typeOptions: const [
        AppDropdownOption(value: PartyType.supplier, label: 'مجهز'),
      ],
    );
    if (!mounted || values == null) return;
    final repository = store.repositories.parties;
    try {
      final created = await repository.quickCreate(
        PartyQuickCreateRequest(
          name: values.name,
          type: values.type,
          phone: values.phone,
          alternatePhone: values.alternatePhone,
          city: values.city,
          address: values.address,
          notes: values.notes,
        ),
      );
      final refreshed = await repository.getAll();
      if (!mounted) return;
      _setPurchaseState(() {
        _supplierOptions = List.unmodifiable(
          refreshed.where(
            (party) =>
                party.type == PartyType.supplier ||
                party.type == PartyType.customerAndSupplier,
          ),
        );
        _supplierNameController.text = created.name;
        _selectedSupplierId = created.entityId;
      });
      store.markDataChanged();
      AppToast.showSuccess(context, 'تمت إضافة المجهز');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    }
  }

  Future<AppInvoiceItemOption?> _createItem({
    required String code,
    required String name,
  }) async {
    final store = _store;
    if (store == null || !_allowsItemCreate()) return null;
    final repository = store.repositories.items;
    try {
      final groups = await repository.getGroups();
      final types = await repository.getTypes();
      if (!mounted) return null;
      if (groups.isEmpty || types.isEmpty) {
        AppToast.showWarning(context, 'يجب تسجيل مجموعة ونوع للمادة أولاً');
        return null;
      }
      final values = await AppQuickCreateDialog.showItem(
        context: context,
        title: 'إضافة مادة جديدة',
        prompt: 'هذه المادة غير موجودة، هل تود إضافتها؟',
        accentColor: AppModuleColors.purchases,
        keyPrefix: 'purchaseQuickItem',
        initialCode: code,
        initialName: name,
        groups: [
          for (final group in groups)
            AppQuickCreateReferenceOption(
              id: group.id,
              name: group.name,
              number: group.number,
            ),
        ],
        types: [
          for (final type in types)
            AppQuickCreateReferenceOption(
              id: type.id,
              name: type.name,
              number: type.number,
              parentId: type.groupId,
            ),
        ],
      );
      if (!mounted || values == null) return null;
      final created = await repository.quickCreate(
        ItemQuickCreateRequest(
          code: values.code,
          name: values.name,
          groupId: EntityId(values.groupId),
          typeId: EntityId(values.typeId),
        ),
      );
      final refreshed = await repository.getAll();
      if (!mounted) return null;
      final option = AppInvoiceItemOption(
        id: created.id,
        code: created.code,
        name: created.name,
      );
      _setPurchaseState(() {
        _knownItemIds
          ..clear()
          ..addAll(refreshed.map((item) => item.entityId));
        _itemOptions = List.unmodifiable(
          refreshed.map(
            (item) => AppInvoiceItemOption(
              id: item.id,
              code: item.code,
              name: item.name,
            ),
          ),
        );
      });
      store.markDataChanged();
      AppToast.showSuccess(context, 'تمت إضافة المادة');
      return option;
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
      return null;
    }
  }
}

extension _PurchaseFormState on _PurchaseScreenState {
  PurchaseInvoice? _storedPurchase(EntityId? id) {
    if (id == null) return null;
    for (final invoice in _purchaseInvoices) {
      if (invoice.entityId == id) return invoice.source;
    }
    return null;
  }

  List<_PurchaseInvoiceViewData> get _returnSourceOptions {
    return _purchaseInvoices.where((invoice) {
      if (invoice.source.isReturn) return false;
      if (invoice.entityId == _selectedOriginalPurchaseInvoiceId) return true;
      final usage = _returnUsage(
        invoice.source,
        excludingReturnId: _selectedInvoice?.source.isReturn == true
            ? _selectedInvoice!.entityId
            : null,
      );
      return invoice.source.lines.any(
        (line) =>
            (usage.quantities[line.id] ?? 0) < line.quantity.value,
      );
    }).toList(growable: false);
  }

  ({
    Map<EntityId, int> quantities,
    Map<EntityId, Money> lineDiscounts,
    Money invoiceDiscount,
  }) _returnUsage(
    PurchaseInvoice source, {
    EntityId? excludingReturnId,
  }) {
    final quantities = <EntityId, int>{};
    final lineDiscounts = <EntityId, Money>{};
    var invoiceDiscount = Money.zero(source.currency);
    for (final candidate in _purchaseInvoices) {
      final returned = candidate.source;
      if (returned.id == excludingReturnId ||
          !returned.isReturn ||
          returned.originalPurchaseInvoiceId != source.id) {
        continue;
      }
      invoiceDiscount += returned.invoiceDiscount;
      for (final line in returned.lines) {
        final originalLineId = line.originalPurchaseLineId;
        if (originalLineId == null) continue;
        quantities[originalLineId] =
            (quantities[originalLineId] ?? 0) + line.quantity.value;
        lineDiscounts[originalLineId] =
            (lineDiscounts[originalLineId] ?? Money.zero(source.currency)) +
                line.lineDiscount;
      }
    }
    return (
      quantities: quantities,
      lineDiscounts: lineDiscounts,
      invoiceDiscount: invoiceDiscount,
    );
  }

  List<_PurchaseReturnLineDraft> _returnDraftsFor(
    PurchaseInvoice source, {
    PurchaseInvoice? currentReturn,
  }) {
    final usage = _returnUsage(
      source,
      excludingReturnId: currentReturn?.id,
    );
    final currentLines = <EntityId, PurchaseInvoiceLine>{};
    if (currentReturn != null) {
      for (final line in currentReturn.lines) {
        final originalLineId = line.originalPurchaseLineId;
        if (originalLineId != null) currentLines[originalLineId] = line;
      }
    }
    return [
      for (final sourceLine in source.lines)
        _PurchaseReturnLineDraft(
          sourceLine: sourceLine,
          previouslyReturnedQuantity: usage.quantities[sourceLine.id] ?? 0,
          previouslyReturnedDiscount: usage.lineDiscounts[sourceLine.id] ??
              Money.zero(source.currency),
          maximumQuantity: sourceLine.quantity.value -
              (usage.quantities[sourceLine.id] ?? 0),
          itemCode: sourceLine.itemCodeSnapshot.isNotEmpty
              ? sourceLine.itemCodeSnapshot
              : _itemOptions
                      .where(
                        (item) => item.id == sourceLine.itemId.value,
                      )
                      .firstOrNull
                      ?.code ??
                  '',
          itemName: sourceLine.itemNameSnapshot.isNotEmpty
              ? sourceLine.itemNameSnapshot
              : _itemOptions
                      .where(
                        (item) => item.id == sourceLine.itemId.value,
                      )
                      .firstOrNull
                      ?.name ??
                  '',
          returnLineId: currentLines[sourceLine.id]?.id,
          warehouseId: (currentLines[sourceLine.id]?.warehouseId ??
                  sourceLine.warehouseId)
              .value,
          warehouseName: _warehouseNamesById[
                  (currentLines[sourceLine.id]?.warehouseId ??
                          sourceLine.warehouseId)
                      .value] ??
              sourceLine.warehouseNameSnapshot,
          quantityText: '${currentLines[sourceLine.id]?.quantity.value ?? 0}',
        ),
    ];
  }

  void _selectOriginalPurchaseInvoice(_PurchaseInvoiceViewData selection) {
    final source = selection.source;
    if (source.isReturn) return;
    final supplier = _supplierOptions
        .where((party) => party.entityId == source.supplierId)
        .firstOrNull;
    _setPurchaseState(() {
      _selectedOriginalPurchaseInvoiceId = source.id;
      _originalInvoiceController.text =
          'قائمة شراء رقم ${source.documentNumber}';
      _selectedSupplierId = source.supplierId;
      _supplierNameController.text = selection.supplierName;
      _warehouseId = source.lines.first.warehouseId.value;
      _currency = source.currency.code;
      _exchangeRateController.text = _formatExchangeRate(source.exchangeRate);
      final signedBalance = source.currency == AppCurrency.iqd
          ? supplier?.iqdBalance
          : supplier?.usdBalance;
      _balanceBeforeInvoice = signedBalance?.absolute.majorUnits ?? 0;
      _paymentType = 'آجل';
      _nonCashPaidText = '0';
      _paidController.text = '0';
      _expensesController.text = '0';
      _invoiceDiscountController.text = '0';
      _discountPercentageController.text = '0';
      _returnLines = _returnDraftsFor(source);
      _activeItems = const [];
      _tableDataVersion++;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeOriginalPurchaseInvoiceText(String _) {
    if (_selectedOriginalPurchaseInvoiceId == null) return;
    _setPurchaseState(() {
      _selectedOriginalPurchaseInvoiceId = null;
      _returnLines = const [];
      _activeItems = const [];
      _tableDataVersion++;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeReturnLines(List<_PurchaseReturnLineDraft> lines) {
    _setPurchaseState(() {
      _returnLines = List.unmodifiable(lines);
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  Money _currentReturnInvoiceDiscount() {
    final source = _storedPurchase(_selectedOriginalPurchaseInvoiceId);
    if (source == null) return Money.zero(AppCurrency.parse(_currency));
    final usage = _returnUsage(
      source,
      excludingReturnId: _selectedInvoice?.source.isReturn == true
          ? _selectedInvoice!.entityId
          : null,
    );
    final quantities = Map<EntityId, int>.of(usage.quantities);
    for (final draft in _returnLines) {
      quantities[draft.sourceLine.id] =
          (quantities[draft.sourceLine.id] ?? 0) + draft.effectiveQuantity;
    }
    return PurchaseReturnPolicy.invoiceDiscount(
      source: source,
      totalReturnedQuantities: quantities,
      discountAlreadyReturned: usage.invoiceDiscount,
    );
  }

  void _syncReturnActiveItems() {
    final selectedDrafts = _returnLines
        .where((draft) => draft.effectiveQuantity > 0)
        .toList(growable: false);
    final source = _storedPurchase(_selectedOriginalPurchaseInvoiceId);
    final primaryWarehouseId = selectedDrafts.firstOrNull?.warehouseId ??
        source?.defaultWarehouseId.value;
    if (primaryWarehouseId != null &&
        _warehouseNamesById.containsKey(primaryWarehouseId)) {
      _warehouseId = primaryWarehouseId;
    }
    _activeItems = List.unmodifiable([
      for (final draft in selectedDrafts)
        AppPurchaseInvoiceTableRowData(
          lineId: draft.returnLineId?.value,
          itemId: draft.sourceLine.itemId.value,
          code: draft.itemCode,
          name: draft.itemName,
          warehouseId: draft.warehouseId,
          warehouse: draft.warehouseName,
          quantity: '${draft.effectiveQuantity}',
          container: '0',
          purchasePrice: _formatMoney(draft.sourceLine.purchasePrice),
          discount: _formatMoney(draft.lineDiscount),
          salePrice: _formatMoney(draft.sourceLine.salePrice),
        ),
    ]);
  }

  void _loadInvoice(_PurchaseInvoiceViewData invoice) {
    _isApplyingFormState = true;
    _selectedInvoice = invoice;
    _coordinator?.selection.select(invoice.entityId);
    _invoiceNumberController.text = '${invoice.documentNumber}';
    _invoiceDateTime = invoice.dateTime;
    _warehouseId = invoice.warehouseId.value;
    _purchaseType = invoice.purchaseType;
    _paymentType = invoice.paymentType;
    _currency = invoice.currency;
    _exchangeRateController.text = invoice.exchangeRate;
    _supplierNameController.text = invoice.supplierName;
    _selectedSupplierId = invoice.source.supplierId;
    _notesController.text = invoice.notes;
    _expensesController.text = invoice.expenses;
    _invoiceDiscountController.text = invoice.invoiceDiscount;
    _discountPercentageController.text = invoice.discountPercentage;
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    final currentBalance =
        AppFormatters.parseNumber(invoice.currentBalance) ?? 0;
    final remaining = AppFormatters.parseNumber(invoice.remaining) ?? 0;
    _balanceBeforeInvoice = invoice.source.isReturn
        ? currentBalance + remaining
        : currentBalance - remaining;
    _nonCashPaidText =
        invoice.paymentType == 'نقدي' ? '0' : invoice.paid;
    _paidController.text = _nonCashPaidText;
    if (invoice.source.isReturn) {
      final source = _storedPurchase(invoice.source.originalPurchaseInvoiceId);
      _selectedOriginalPurchaseInvoiceId = source?.id;
      _originalInvoiceController.text = source == null
          ? ''
          : 'قائمة شراء رقم ${source.documentNumber}';
      _returnLines = source == null
          ? const []
          : _returnDraftsFor(source, currentReturn: invoice.source);
      _syncReturnActiveItems();
    } else {
      _selectedOriginalPurchaseInvoiceId = null;
      _originalInvoiceController.clear();
      _returnLines = const [];
      _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
        invoice.items,
      );
    }
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _dirtyTracker.accept(_currentSnapshot());
    _hasUnsavedChanges = false;
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _selectedInvoice = null;
    _coordinator?.selection.clear();
    _invoiceNumberController.text = '$_nextInvoiceNumber';
    _invoiceDateTime = DateTime.now();
    _warehouseId = _defaultWarehouseId;
    _purchaseType = _defaultPurchaseType;
    _paymentType = _defaultPaymentType;
    _currency = _defaultCurrency;
    _exchangeRateController.text = _defaultExchangeRate;
    _supplierNameController.clear();
    _selectedSupplierId = null;
    _selectedOriginalPurchaseInvoiceId = null;
    _originalInvoiceController.clear();
    _notesController.clear();
    _expensesController.text = '0';
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    _balanceBeforeInvoice = 0;
    _nonCashPaidText = '0';
    _paidController.text = '0';
    _activeItems = _isPurchaseReturn
        ? const []
        : [
            AppPurchaseInvoiceTableRowData(
              warehouseId: _defaultWarehouseId,
              warehouse: _defaultWarehouseName,
            ),
          ];
    _returnLines = const [];
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _dirtyTracker.accept(_currentSnapshot());
    _hasUnsavedChanges = false;
  }

  _PurchaseFormSnapshot _currentSnapshot() => (
        invoiceDateTime: _invoiceDateTime,
        warehouse: _warehouseId,
        purchaseType: _purchaseType,
        paymentType: _paymentType,
        currency: _currency,
        exchangeRate: _exchangeRateController.text,
        supplierName: _supplierNameController.text,
        supplierId: _selectedSupplierId?.value,
        originalPurchaseInvoiceId:
            _selectedOriginalPurchaseInvoiceId?.value,
        notes: _notesController.text,
        expenses: _expensesController.text,
        invoiceDiscount: _invoiceDiscountController.text,
        discountPercentage: _discountPercentageController.text,
        paid: _paidController.text,
        itemsSignature: _isPurchaseReturn
            ? _returnItemsSignature(_returnLines)
            : _itemsSignature(_activeItems),
      );

  String _returnItemsSignature(Iterable<_PurchaseReturnLineDraft> lines) {
    return lines
        .map(
          (line) => [
            line.sourceLine.id.value,
            line.returnLineId?.value ?? '',
            line.warehouseId,
            line.quantityText,
            '${line.maximumQuantity}',
          ].join('\u001f'),
        )
        .join('\u001e');
  }

  String _itemsSignature(
    Iterable<AppPurchaseInvoiceTableRowData> items,
  ) {
    return items
        .map(
          (item) => [
            item.code,
            item.name,
            item.warehouseId ?? '',
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
    final hasUnsavedChanges = _dirtyTracker.hasChanges(_currentSnapshot());
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    _setPurchaseState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _dirtyTracker.hasChanges(_currentSnapshot());
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
    if (_warehouseId == value) return;
    _setPurchaseState(() {
      _warehouseId = value;
      _refreshSelectionState();
    });
  }

  void _changeSupplierText(String _) {
    if (_selectedSupplierId == null) return;
    _setPurchaseState(() {
      _selectedSupplierId = null;
      _refreshSelectionState();
    });
  }

  void _selectSupplier(Party party) {
    _setPurchaseState(() {
      _selectedSupplierId = party.entityId;
      _refreshSelectionState();
    });
  }

  void _changePurchaseType(String value) {
    if (_purchaseType == value) return;
    _setPurchaseState(() {
      _purchaseType = value;
      _selectedOriginalPurchaseInvoiceId = null;
      _originalInvoiceController.clear();
      _returnLines = const [];
      if (value == 'إرجاع') {
        _activeItems = const [];
        _paymentType = 'آجل';
        _nonCashPaidText = '0';
        _paidController.text = '0';
        _expensesController.text = '0';
        _invoiceDiscountController.text = '0';
        _discountPercentageController.text = '0';
      } else {
        _activeItems = [
          AppPurchaseInvoiceTableRowData(
            warehouseId: _defaultWarehouseId,
            warehouse: _defaultWarehouseName,
          ),
        ];
      }
      _tableDataVersion++;
      _syncCalculatedFields();
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
    if (_isPurchaseReturn) return;
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
      if (_isPurchaseReturn) {
        _syncReturnActiveItems();
        _setControllerText(_expensesController, '0');
        final returnDiscount = _currentReturnInvoiceDiscount();
        _setControllerText(
          _invoiceDiscountController,
          _formatMoney(returnDiscount),
        );
        _discountInputSource = _PurchaseDiscountInputSource.amount;
      }
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
        defaultWarehouse: _defaultWarehouseId,
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
      final currentBalance = _isPurchaseReturn
          ? (_balanceBeforeInvoice - remaining).abs()
          : _balanceBeforeInvoice + remaining;
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
    _selectedSupplierId ??= _uniqueSupplierIdForText(supplierName);
    if (_selectedSupplierId == null ||
        !_supplierOptions.any(
          (party) => party.entityId == _selectedSupplierId,
        )) {
      AppToast.showWarning(context, 'اختر مجهزاً موجوداً من القائمة');
      return false;
    }
    if (!_warehouseNamesById.containsKey(_warehouseId)) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً');
      return false;
    }
    if (_isPurchaseReturn) {
      final source = _storedPurchase(_selectedOriginalPurchaseInvoiceId);
      if (source == null || source.isReturn) {
        AppToast.showWarning(context, 'اختر قائمة الشراء الأصلية للمرتجع');
        return false;
      }
      final returnTimestamp = DateTime(
        _invoiceDateTime.year,
        _invoiceDateTime.month,
        _invoiceDateTime.day,
        _invoiceDateTime.hour,
        _invoiceDateTime.minute,
      );
      final sourceTimestamp = source.date.atTime(
        hour: source.minuteOfDay ~/ Duration.minutesPerHour,
        minute: source.minuteOfDay % Duration.minutesPerHour,
      );
      if (returnTimestamp.isBefore(sourceTimestamp)) {
        AppToast.showWarning(
          context,
          'لا يمكن أن يسبق المرتجع قائمة الشراء الأصلية',
        );
        return false;
      }
      if (_returnLines.any((line) => !line.hasValidQuantity)) {
        AppToast.showWarning(
          context,
          'إحدى كميات المرتجع تتجاوز الكمية المتاحة',
        );
        return false;
      }
      if (!_returnLines.any((line) => line.quantity > 0)) {
        AppToast.showWarning(context, 'أدخل كمية مرتجعة لمادة واحدة على الأقل');
        return false;
      }
      if (_returnLines.any(
        (line) =>
            line.quantity > 0 &&
            !_warehouseNamesById.containsKey(line.warehouseId),
      )) {
        AppToast.showWarning(context, 'اختر مخزناً موجوداً لكل سطر مرتجع');
        return false;
      }
    }

    final meaningfulItems = _activeItems
        .where(
          (item) =>
              !item.isEmptyForDefaultWarehouse(_defaultWarehouseId),
        )
        .toList();
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
      (item) =>
          item.warehouseId == null ||
          !_warehouseNamesById.containsKey(item.warehouseId),
    )) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً لكل سطر');
      return false;
    }
    return true;
  }

  EntityId? _uniqueSupplierIdForText(String value) {
    final normalized = normalizePartyName(value);
    if (normalized.isEmpty) return null;
    final matches = _supplierOptions.where(
      (party) => normalizePartyName(party.name) == normalized,
    );
    if (matches.length != 1) return null;
    return matches.single.entityId;
  }

  PurchaseInvoice _domainInvoiceFromForm({required EntityId entityId}) {
    if (_isPurchaseReturn) {
      return _domainReturnInvoiceFromForm(entityId: entityId);
    }
    final items = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      _activeItems.where(
        (item) =>
            !item.isEmptyForDefaultWarehouse(_defaultWarehouseId),
      ),
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
          warehouseId: EntityId(row.warehouseId!),
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
      supplierId: _selectedSupplierId!,
      supplierNameSnapshot: supplierName,
      defaultWarehouseId: EntityId(_warehouseId),
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

  PurchaseInvoice _domainReturnInvoiceFromForm({required EntityId entityId}) {
    final source = _storedPurchase(_selectedOriginalPurchaseInvoiceId)!;
    final currency = source.currency;
    final newLineNonce = DateTime.now().microsecondsSinceEpoch;
    final selectedDrafts = _returnLines
        .where((draft) => draft.quantity > 0)
        .toList(growable: false);
    final lines = <PurchaseInvoiceLine>[];
    for (var index = 0; index < selectedDrafts.length; index++) {
      final draft = selectedDrafts[index];
      lines.add(
        PurchaseInvoiceLine(
          id: draft.returnLineId ??
              EntityId('${entityId.value}-line-$newLineNonce-${index + 1}'),
          itemId: draft.sourceLine.itemId,
          warehouseId: EntityId(draft.warehouseId),
          quantity: WholeQuantity(draft.quantity),
          containerQuantity: WholeQuantity(0),
          purchasePrice: draft.sourceLine.purchasePrice,
          lineDiscount: draft.lineDiscount,
          salePrice: draft.sourceLine.salePrice,
          originalPurchaseLineId: draft.sourceLine.id,
          itemCodeSnapshot: draft.itemCode,
          itemNameSnapshot: draft.itemName,
          warehouseNameSnapshot:
              _warehouseNamesById[draft.warehouseId] ?? draft.warehouseName,
        ),
      );
    }
    return PurchaseInvoice(
      id: entityId,
      documentNumber: int.parse(_invoiceNumberController.text),
      date: BusinessDate.fromDateTime(_invoiceDateTime),
      minuteOfDay: _invoiceDateTime.hour * 60 + _invoiceDateTime.minute,
      supplierId: source.supplierId,
      supplierNameSnapshot: _supplierNameController.text.trim(),
      defaultWarehouseId: EntityId(_warehouseId),
      currency: currency,
      exchangeRate: source.exchangeRate,
      purchaseKind: PurchaseTransactionKind.returnPurchase,
      settlementKind: _paymentType == 'نقدي'
          ? PurchaseSettlementKind.cash
          : PurchaseSettlementKind.credit,
      lines: lines,
      expenses: Money.zero(currency),
      invoiceDiscount: _currentReturnInvoiceDiscount(),
      paid: Money.parse(_paidController.text, currency),
      originalPurchaseInvoiceId: source.id,
      balanceAfterInvoice:
          Money.parse(_currentBalanceController.text, currency),
      notes: _notesController.text.trim(),
    );
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
    final normalizedCode = _normalizedLookup(code);
    final normalizedName = _normalizedLookup(name);
    final matches = _itemOptions.where(
      (option) =>
          _normalizedLookup(option.code) == normalizedCode &&
          _normalizedLookup(option.name) == normalizedName,
    );
    if (matches.length != 1) return null;
    return EntityId(matches.single.id);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
