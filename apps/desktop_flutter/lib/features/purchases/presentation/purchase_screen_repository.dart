part of 'purchase_screen.dart';

extension _PurchaseRepositoryState on _PurchaseScreenState {
  Future<void> _loadData({
    bool showLoading = true,
    EntityId? selectEntityId,
  }) async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    if (showLoading && mounted) {
      _setPurchaseState(() => _invoiceState = const AppDataState.loading());
    }
    final selectedEntityId = selectEntityId ?? _selectedInvoice?.entityId;
    final state = await coordinator.load();
    if (!mounted) return;
    _setPurchaseState(() {
      _invoiceState = state;
      final records = state.data;
      if (records == null) {
        if (state.status == AppDataStatus.empty) {
          _purchaseInvoices.clear();
          _selectedInvoice = null;
        }
        return;
      }
      _purchaseInvoices
        ..clear()
        ..addAll(records);
      final selected = coordinator.selection.select(
        selectedEntityId,
        fallbackToFirst: true,
      );
      if (selected != null) _loadInvoice(selected);
    });
  }

  Future<List<_PurchaseInvoiceViewData>> _loadRepositoryInvoices() async {
    final repositories = _store!.repositories;
    final parties = await repositories.parties.getAll();
    final items = await repositories.items.getAll();
    final warehouses = await repositories.warehouses.getAll();
    final defaults = await repositories.businessSettings.loadOperationalDefaults();
    final policies = await repositories.businessSettings.loadBusinessPolicies();
    _repositoryNextInvoiceNumber =
        await repositories.purchases.nextDocumentNumber();
    final loadedInvoices = await repositories.purchases.getAll();
    final invoices = [...loadedInvoices]
      ..sort((left, right) => left.documentNumber.compareTo(right.documentNumber));
    final invoicesById = {for (final invoice in invoices) invoice.id: invoice};

    final partiesById = {for (final party in parties) party.entityId: party};
    final itemsById = {for (final item in items) item.entityId: item};
    final warehousesById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
    };

    _supplierOptions = List.unmodifiable(
      parties.where(
        (party) =>
            party.type == PartyType.supplier ||
            party.type == PartyType.customerAndSupplier,
      ),
    );
    _knownItemIds.clear();
    for (final item in items) {
      final itemId = item.entityId;
      _knownItemIds.add(itemId);
    }
    _itemOptions = List.unmodifiable(
      items.map(
        (item) => AppInvoiceItemOption(
          id: item.id,
          code: item.code,
          name: item.name,
        ),
      ),
    );
    _warehouseNamesById.clear();
    final orderedWarehouses = [...warehouses]
      ..sort((left, right) => left.number.compareTo(right.number));
    for (final warehouse in orderedWarehouses) {
      _warehouseNamesById[warehouse.id] = warehouse.name;
    }
    _warehouseOptions = List.unmodifiable(
      orderedWarehouses.map(
        (warehouse) => AppDropdownOption(
          value: warehouse.id,
          label: warehouse.name,
        ),
      ),
    );

    final defaultWarehouse = warehousesById[defaults.purchases.warehouseId];
    if (defaultWarehouse == null) {
      throw const InvoiceMissingReferenceException(
        'المخزن الافتراضي لقوائم الشراء غير موجود.',
      );
    }
    _defaultWarehouseId = defaultWarehouse.id;
    _defaultWarehouseName = defaultWarehouse.name;
    _defaultPurchaseType = _purchaseKindLabel(defaults.purchases.purchaseKind);
    _defaultPaymentType =
        defaults.purchases.paymentKind == PaymentKind.cash ? 'نقدي' : 'آجل';
    _defaultCurrency = defaults.purchases.currency.code;
    _defaultExchangeRate = _formatExchangeRate(
      policies.defaultExchangeRate,
    );

    final result = <_PurchaseInvoiceViewData>[];
    for (final invoice in invoices) {
      final party = partiesById[invoice.supplierId];
      final warehouse = warehousesById[invoice.defaultWarehouseId];
      final originalInvoice = invoice.originalPurchaseInvoiceId == null
          ? null
          : invoicesById[invoice.originalPurchaseInvoiceId];
      if (party == null || warehouse == null) {
        throw const InvoiceMissingReferenceException(
          'إحدى قوائم الشراء مرتبطة بمجهز أو مخزن غير موجود.',
        );
      }
      if (invoice.isReturn &&
          (originalInvoice == null || originalInvoice.isReturn)) {
        throw const InvoiceMissingReferenceException(
          'أحد مرتجعات الشراء مرتبط بقائمة أصلية غير موجودة.',
        );
      }
      for (final line in invoice.lines) {
        if (itemsById[line.itemId] == null ||
            warehousesById[line.warehouseId] == null) {
          throw const InvoiceMissingReferenceException(
            'إحدى مواد قوائم الشراء مرتبطة بمادة أو مخزن غير موجود.',
          );
        }
        if (invoice.isReturn &&
            (line.originalPurchaseLineId == null ||
                !originalInvoice!.lines.any(
                  (sourceLine) =>
                      sourceLine.id == line.originalPurchaseLineId &&
                      sourceLine.itemId == line.itemId,
                ))) {
          throw const InvoiceMissingReferenceException(
            'أحد سطور مرتجعات الشراء مرتبط بسطر أصلي غير موجود.',
          );
        }
      }
      result.add(
        _purchaseViewFromDomain(
          invoice,
          party: party,
          itemsById: itemsById,
          warehousesById: warehousesById,
          originalInvoice: originalInvoice,
        ),
      );
    }
    return result;
  }

  _PurchaseInvoiceViewData _purchaseViewFromDomain(
    PurchaseInvoice invoice, {
    required Party party,
    required Map<EntityId, Item> itemsById,
    required Map<EntityId, Warehouse> warehousesById,
    PurchaseInvoice? originalInvoice,
  }) {
    final currency = invoice.currency.code;
    final rows = <AppPurchaseInvoiceTableRowData>[
      for (final line in invoice.lines)
        AppPurchaseInvoiceTableRowData(
          lineId: line.id.value,
          itemId: line.itemId.value,
          code: line.itemCodeSnapshot.isNotEmpty
              ? line.itemCodeSnapshot
              : itemsById[line.itemId]!.code,
          name: line.itemNameSnapshot.isNotEmpty
              ? line.itemNameSnapshot
              : itemsById[line.itemId]!.name,
          warehouseId: line.warehouseId.value,
          warehouse: line.warehouseNameSnapshot.isNotEmpty
              ? line.warehouseNameSnapshot
              : warehousesById[line.warehouseId]!.name,
          quantity: '${line.quantity.value}',
          container: '${line.containerQuantity.value}',
          purchasePrice: _formatMoney(line.purchasePrice),
          discount: _formatMoney(line.lineDiscount),
          salePrice: _formatMoney(line.salePrice),
        ),
    ];
    final supplierName = invoice.supplierNameSnapshot.isNotEmpty
        ? invoice.supplierNameSnapshot
        : party.name;
    final remaining = invoice.total - invoice.paid;
    final dateTime = invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ 60,
      minute: invoice.minuteOfDay % 60,
    );
    final date =
        '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
    return _PurchaseInvoiceViewData(
      source: invoice,
      documentNumber: invoice.documentNumber,
      dateTime: dateTime,
      warehouseId: invoice.defaultWarehouseId,
      warehouse: warehousesById[invoice.defaultWarehouseId]!.name,
      purchaseType: _purchaseTransactionLabel(invoice.purchaseKind),
      paymentType: invoice.settlementKind == PurchaseSettlementKind.cash
          ? 'نقدي'
          : 'آجل',
      currency: currency,
      exchangeRate: _formatExchangeRate(invoice.exchangeRate),
      supplierName: supplierName,
      notes: invoice.notes,
      expenses: _formatMoney(invoice.expenses),
      invoiceDiscount: _formatMoney(invoice.invoiceDiscount),
      discountPercentage: AppFormatters.money(
        invoice.invoiceDiscountPercentageValue,
        decimalPlaces: 2,
      ),
      paid: _formatMoney(invoice.paid),
      remaining: _formatMoney(remaining),
      currentBalance: _formatMoney(
        invoice.balanceAfterInvoice ?? remaining,
      ),
      searchDetails: invoice.searchDetailsSnapshot.isNotEmpty
          ? invoice.searchDetailsSnapshot
          : '$date • ${rows.length} مواد',
      searchTerms: List.unmodifiable([
        '${invoice.documentNumber}',
        supplierName,
        party.name,
        _purchaseTransactionLabel(invoice.purchaseKind),
        if (originalInvoice != null) '${originalInvoice.documentNumber}',
        currency,
        AppFormatters.currency(currency),
        for (var index = 0; index < rows.length; index++) ...[
          rows[index].code,
          rows[index].name,
          itemsById[invoice.lines[index].itemId]!.code,
          itemsById[invoice.lines[index].itemId]!.name,
        ],
      ]),
      items: List.unmodifiable(rows),
    );
  }

  String _normalizedLookup(String value) => value.trim().toLowerCase();

  String _formatMoney(Money value) {
    final scale = value.currency.scale;
    final hasFraction = value.minorUnits.abs() % scale != 0;
    return AppFormatters.money(
      value.majorUnits,
      decimalPlaces: hasFraction ? value.currency.decimalPlaces : 0,
    );
  }

  String _formatExchangeRate(ExchangeRate value) => AppFormatters.money(
        value.value,
        decimalPlaces: value.tenThousandths % 10000 == 0 ? 0 : 4,
      );

  String _purchaseKindLabel(PurchaseKind kind) => switch (kind) {
        PurchaseKind.local => 'محلي',
        PurchaseKind.imported => 'إستيراد',
        PurchaseKind.returnPurchase => 'إرجاع',
      };

  String _purchaseTransactionLabel(PurchaseTransactionKind kind) =>
      switch (kind) {
        PurchaseTransactionKind.local => 'محلي',
        PurchaseTransactionKind.import => 'إستيراد',
        PurchaseTransactionKind.returnPurchase => 'إرجاع',
      };
}
