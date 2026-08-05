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
    final selectedEntityId = selectEntityId ?? _selectedInvoice?.source.id;
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
      _DemoPurchaseInvoice? selected;
      if (selectedEntityId != null) {
        for (final candidate in records) {
          if (candidate.source.id == selectedEntityId) {
            selected = candidate;
            break;
          }
        }
      }
      _loadInvoice(selected ?? records.first);
    });
  }

  Future<List<_DemoPurchaseInvoice>> _loadRepositoryInvoices() async {
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

    final partiesById = {for (final party in parties) EntityId(party.id): party};
    final itemsById = {for (final item in items) EntityId(item.id): item};
    final warehousesById = {
      for (final warehouse in warehouses) EntityId(warehouse.id): warehouse,
    };

    _supplierIdsByName.clear();
    for (final party in parties.where(
      (party) =>
          party.type == PartyType.supplier ||
          party.type == PartyType.customerAndSupplier,
    )) {
      _supplierIdsByName[party.name] = EntityId(party.id);
    }
    _supplierOptions = List.unmodifiable(_supplierIdsByName.keys);
    _itemIdsByLabel.clear();
    _knownItemIds.clear();
    for (final item in items) {
      final itemId = EntityId(item.id);
      _knownItemIds.add(itemId);
      _itemIdsByLabel[_normalizedLookup(item.code)] = itemId;
      _itemIdsByLabel[_normalizedLookup(item.name)] = itemId;
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
    _warehouseIdsByLabel.clear();
    final orderedWarehouses = [...warehouses]
      ..sort(
        (left, right) => _warehouseOrder(EntityId(left.id))
            .compareTo(_warehouseOrder(EntityId(right.id))),
      );
    for (final warehouse in orderedWarehouses) {
      _warehouseIdsByLabel[_warehouseLabel(EntityId(warehouse.id))] =
          EntityId(warehouse.id);
    }
    _warehouseOptions = List.unmodifiable(
      orderedWarehouses.map((warehouse) {
        final label = _warehouseLabel(EntityId(warehouse.id));
        return AppDropdownOption(value: label, label: label);
      }),
    );

    _defaultWarehouse = _warehouseLabel(defaults.purchases.warehouseId);
    _defaultPurchaseType = _purchaseKindLabel(defaults.purchases.purchaseKind);
    _defaultPaymentType =
        defaults.purchases.paymentKind == PaymentKind.cash ? 'نقدي' : 'آجل';
    _defaultCurrency = defaults.purchases.currency.code;
    _defaultExchangeRate = _formatExchangeRate(
      policies.defaultExchangeRate,
    );

    final result = <_DemoPurchaseInvoice>[];
    for (final invoice in invoices) {
      final party = partiesById[invoice.supplierId];
      final warehouse = warehousesById[invoice.defaultWarehouseId];
      if (party == null || warehouse == null) {
        throw const InvoiceMissingReferenceException(
          'إحدى قوائم الشراء مرتبطة بمجهز أو مخزن غير موجود.',
        );
      }
      for (final line in invoice.lines) {
        if (itemsById[line.itemId] == null ||
            warehousesById[line.warehouseId] == null) {
          throw const InvoiceMissingReferenceException(
            'إحدى مواد قوائم الشراء مرتبطة بمادة أو مخزن غير موجود.',
          );
        }
      }
      result.add(
        _purchaseViewFromDomain(
          invoice,
          party: party,
          itemsById: itemsById,
          warehousesById: warehousesById,
        ),
      );
    }
    return result;
  }

  _DemoPurchaseInvoice _purchaseViewFromDomain(
    PurchaseInvoice invoice, {
    required Party party,
    required Map<EntityId, Item> itemsById,
    required Map<EntityId, Warehouse> warehousesById,
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
          warehouse: line.warehouseNameSnapshot.isNotEmpty
              ? line.warehouseNameSnapshot
              : _warehouseLabel(EntityId(warehousesById[line.warehouseId]!.id)),
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
    return _DemoPurchaseInvoice(
      source: invoice,
      id: '${invoice.documentNumber}',
      dateTime: dateTime,
      warehouse: _warehouseLabel(invoice.defaultWarehouseId),
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

  String _warehouseLabel(EntityId id) => switch (id.value) {
        'warehouse-001' => 'الرئيسي',
        'warehouse-002' => 'الكرادة',
        'warehouse-003' => 'الرصافة',
        'warehouse-004' => 'المنصور',
        _ => id.value,
      };

  int _warehouseOrder(EntityId id) => switch (id.value) {
        'warehouse-001' => 0,
        'warehouse-003' => 1,
        'warehouse-002' => 2,
        'warehouse-004' => 3,
        _ => 100,
      };

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
