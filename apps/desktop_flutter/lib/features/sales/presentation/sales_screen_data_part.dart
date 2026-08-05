part of 'sales_screen.dart';

extension _SalesScreenDataPart on _SalesScreenState {
  Future<void> _loadData({
    bool showLoading = true,
    EntityId? selectEntityId,
  }) async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    if (showLoading && mounted) {
      _setSalesState(() => _invoiceState = const AppDataState.loading());
    }
    final selectedEntityId = selectEntityId ?? _selectedInvoice?.source.id;
    final state = await coordinator.load();
    if (!mounted) return;
    _setSalesState(() {
      _invoiceState = state;
      final records = state.data;
      if (records == null) {
        if (state.status == AppDataStatus.empty) {
          _salesInvoices.clear();
          _selectedInvoice = null;
        }
        return;
      }
      _salesInvoices
        ..clear()
        ..addAll(records);
      _DemoSalesInvoice? selected;
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

  Future<List<_DemoSalesInvoice>> _loadRepositoryInvoices() async {
    final repositories = _store!.repositories;
    final parties = await repositories.parties.getAll();
    final items = await repositories.items.getAll();
    final warehouses = await repositories.warehouses.getAll();
    final defaults = await repositories.businessSettings.loadOperationalDefaults();
    final policies = await repositories.businessSettings.loadBusinessPolicies();
    _repositoryNextInvoiceNumber =
        await repositories.sales.nextDocumentNumber();
    final loadedInvoices = await repositories.sales.getAll();
    final invoices = [...loadedInvoices]
      ..sort((left, right) => left.documentNumber.compareTo(right.documentNumber));

    final partiesById = {for (final party in parties) EntityId(party.id): party};
    final itemsById = {for (final item in items) EntityId(item.id): item};
    final warehousesById = {
      for (final warehouse in warehouses) EntityId(warehouse.id): warehouse,
    };

    _customerIdsByName
      ..clear()
      ..addEntries(
        parties
            .where(
              (party) =>
                  party.type == PartyType.customer ||
                  party.type == PartyType.customerAndSupplier,
            )
            .map((party) => MapEntry(party.name, EntityId(party.id))),
      );
    _customerOptions = List.unmodifiable(_customerIdsByName.keys);
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

    _defaultWarehouse = _warehouseLabel(defaults.sales.warehouseId);
    _defaultSaleType = _saleKindLabel(defaults.sales.saleKind);
    _defaultCurrency = defaults.sales.currency.code;
    _defaultExchangeRate = _formatExchangeRate(
      policies.defaultExchangeRate,
    );

    final result = <_DemoSalesInvoice>[];
    for (final invoice in invoices) {
      final party = partiesById[invoice.customerId];
      final warehouse = warehousesById[invoice.defaultWarehouseId];
      if (party == null || warehouse == null) {
        throw const InvoiceMissingReferenceException(
          'إحدى قوائم البيع مرتبطة بزبون أو مخزن غير موجود.',
        );
      }
      for (final line in invoice.lines) {
        if (itemsById[line.itemId] == null ||
            warehousesById[line.warehouseId] == null) {
          throw const InvoiceMissingReferenceException(
            'إحدى مواد قوائم البيع مرتبطة بمادة أو مخزن غير موجود.',
          );
        }
      }
      result.add(
        _salesViewFromDomain(
          invoice,
          party: party,
          itemsById: itemsById,
          warehousesById: warehousesById,
        ),
      );
    }
    return result;
  }

  _DemoSalesInvoice _salesViewFromDomain(
    SalesInvoice invoice, {
    required Party party,
    required Map<EntityId, Item> itemsById,
    required Map<EntityId, Warehouse> warehousesById,
  }) {
    final currency = invoice.currency.code;
    final rows = <AppSalesInvoiceTableRowData>[
      for (final line in invoice.lines)
        AppSalesInvoiceTableRowData(
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
          salePrice: _formatMoney(line.unitPrice),
          discount: _formatMoney(line.discountPerUnit),
        ).withCalculatedValues(currency),
    ];
    final customerName = invoice.customerNameSnapshot.isNotEmpty
        ? invoice.customerNameSnapshot
        : party.name;
    final remaining = invoice.total - invoice.received;
    final dateTime = invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ 60,
      minute: invoice.minuteOfDay % 60,
    );
    final date =
        '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
    return _DemoSalesInvoice(
      source: invoice,
      id: '${invoice.documentNumber}',
      dateTime: dateTime,
      warehouse: _warehouseLabel(invoice.defaultWarehouseId),
      saleType: _salesSettlementLabel(invoice.settlementKind),
      currency: currency,
      exchangeRate: _formatExchangeRate(invoice.exchangeRate),
      customerName: customerName,
      notes: invoice.notes,
      driverName: invoice.driverName,
      invoiceDiscount: _formatMoney(invoice.invoiceDiscount),
      discountPercentage: invoice.invoiceDiscountPercentage.toPlainString(),
      received: _formatMoney(invoice.received),
      total: _formatMoney(invoice.total),
      remaining: _formatMoney(remaining),
      currentBalance: _formatMoney(
        invoice.balanceAfterInvoice ?? remaining,
      ),
      searchDetails: invoice.searchDetailsSnapshot.isNotEmpty
          ? invoice.searchDetailsSnapshot
          : '$date • ${rows.length} مواد',
      searchTerms: List.unmodifiable([
        '${invoice.documentNumber}',
        customerName,
        party.name,
        _salesSettlementLabel(invoice.settlementKind),
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
      summaryQuantity: AppFormatters.quantity(
        rows.fold<int>(0, (total, row) => total + row.quantityValue),
      ),
      summaryDiscount: AppFormatters.moneyByCurrency(
        rows.fold<num>(0, (total, row) => total + row.discountValue),
        currency,
      ),
      summaryTotal: AppFormatters.moneyByCurrency(
        rows.fold<num>(0, (total, row) => total + row.totalValue),
        currency,
      ),
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

  String _saleKindLabel(SaleKind kind) => switch (kind) {
        SaleKind.cash => 'نقدي',
        SaleKind.credit => 'آجل',
        SaleKind.installments => 'أقساط',
      };

  String _salesSettlementLabel(SalesSettlementKind kind) => switch (kind) {
        SalesSettlementKind.cash => 'نقدي',
        SalesSettlementKind.credit => 'آجل',
        SalesSettlementKind.installments => 'أقساط',
      };

  void _loadInvoice(_DemoSalesInvoice invoice) {
    _isApplyingFormState = true;
    _selectedInvoice = invoice;
    _invoiceNumberController.text = invoice.id;
    _invoiceDateTime = invoice.dateTime;
    _warehouse = invoice.warehouse;
    _saleType = invoice.saleType;
    _currency = invoice.currency;
    _exchangeRateController.text = invoice.exchangeRate;
    _customerNameController.text = invoice.customerName;
    _notesController.text = invoice.notes;
    _driverNameController.text = invoice.driverName;
    _invoiceDiscountController.text = invoice.invoiceDiscount;
    _discountPercentageController.text = invoice.discountPercentage;
    _discountInputSource = _InvoiceDiscountInputSource.amount;
    _balanceBeforeInvoice =
        (AppFormatters.parseNumber(invoice.currentBalance) ?? 0) -
            (AppFormatters.parseNumber(invoice.remaining) ?? 0);
    _nonCashReceivedText =
        invoice.saleType == 'نقدي' ? '0' : invoice.received;
    _receivedController.text = _nonCashReceivedText;
    _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
      invoice.items.map(
        (item) => item.withCalculatedValues(_currency),
      ),
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
    _saleType = _defaultSaleType;
    _currency = _defaultCurrency;
    _exchangeRateController.text = _defaultExchangeRate;
    _customerNameController.clear();
    _notesController.clear();
    _driverNameController.clear();
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _discountInputSource = _InvoiceDiscountInputSource.amount;
    _balanceBeforeInvoice = 0;
    _nonCashReceivedText = '0';
    _receivedController.text = '0';
    _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable([
      const AppSalesInvoiceTableRowData().withCalculatedValues(_currency),
    ]);
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  _SalesFormSnapshot _currentSnapshot() => (
        invoiceDateTime: _invoiceDateTime,
        warehouse: _warehouse,
        saleType: _saleType,
        currency: _currency,
        exchangeRate: _exchangeRateController.text,
        customerName: _customerNameController.text,
        notes: _notesController.text,
        driverName: _driverNameController.text,
        invoiceDiscount: _invoiceDiscountController.text,
        discountPercentage: _discountPercentageController.text,
        received: _receivedController.text,
        itemsSignature: _itemsSignature(_activeItems),
      );

  String _itemsSignature(
    Iterable<AppSalesInvoiceTableRowData> items,
  ) {
    return items
        .map(
          (item) => [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.salePrice,
            item.discount,
            item.priceAfterDiscount,
            item.total,
          ].join('\u001f'),
        )
        .join('\u001e');
  }

}
