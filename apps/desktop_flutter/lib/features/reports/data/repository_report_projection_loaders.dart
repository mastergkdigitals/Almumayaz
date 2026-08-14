part of 'repository_report_data_service.dart';

extension _RepositoryReportProjectionLoaders
    on RepositoryReportDataService {
  Future<ReportDataSnapshot> _sales() async {
    final values = await Future.wait([
      _repositories.sales.getAll(),
      _repositories.parties.getAll(),
      _repositories.warehouses.getAll(),
    ]);
    final invoices = values[0] as List<SalesInvoice>;
    final parties = values[1] as List<Party>;
    final warehouses = values[2] as List<Warehouse>;
    final partyById = {for (final party in parties) party.entityId: party};
    final warehouseById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
    };
    final sorted = [...invoices]..sort(_compareSalesNewestFirst);

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < sorted.length; index++)
          _salesRow(
            sorted[index],
            index: index,
            partyById: partyById,
            warehouseById: warehouseById,
          ),
      ],
      filterOptions: {
        'warehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'customer': _entityOptions(
          parties.where(_canBuy),
          idOf: (party) => party.entityId,
          labelOf: (party) => party.name,
        ),
        'saleType': _saleTypeOptions,
        'currency': _currencyOptions,
      },
    );
  }

  Future<ReportDataSnapshot> _purchases() async {
    final values = await Future.wait([
      _repositories.purchases.getAll(),
      _repositories.parties.getAll(),
      _repositories.warehouses.getAll(),
    ]);
    final invoices = values[0] as List<PurchaseInvoice>;
    final parties = values[1] as List<Party>;
    final warehouses = values[2] as List<Warehouse>;
    final partyById = {for (final party in parties) party.entityId: party};
    final warehouseById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
    };
    final sorted = [...invoices]..sort(_comparePurchasesNewestFirst);

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < sorted.length; index++)
          _purchaseRow(
            sorted[index],
            index: index,
            partyById: partyById,
            warehouseById: warehouseById,
          ),
      ],
      filterOptions: {
        'warehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'supplier': _entityOptions(
          parties.where(_canSupply),
          idOf: (party) => party.entityId,
          labelOf: (party) => party.name,
        ),
        'purchaseType': _purchaseTypeOptions,
        'paymentType': _purchasePaymentOptions,
        'currency': _currencyOptions,
      },
    );
  }

  Future<ReportDataSnapshot> _profits() async {
    final values = await Future.wait([
      _repositories.sales.getAll(),
      _repositories.parties.getAll(),
      _repositories.items.getAll(),
      _repositories.warehouses.getAll(),
      _repositories.inventoryCosts.getSalesLineCosts(),
    ]);
    final invoices = values[0] as List<SalesInvoice>;
    final parties = values[1] as List<Party>;
    final items = values[2] as List<Item>;
    final warehouses = values[3] as List<Warehouse>;
    final lineCosts = values[4] as List<SalesLineCostRecord>;
    final partyById = {for (final party in parties) party.entityId: party};
    final itemById = {for (final item in items) item.entityId: item};
    final warehouseById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
    };
    final costByLineId = {
      for (final cost in lineCosts) cost.salesLineId: cost,
    };
    final sorted = [...invoices]..sort(_compareSalesNewestFirst);
    final rows = <ReportRowDefinition>[];
    for (final invoice in sorted) {
      for (final line in invoice.lines) {
        rows.add(
          _profitRow(
            invoice,
            line,
            index: rows.length,
            partyById: partyById,
            itemById: itemById,
            warehouseById: warehouseById,
            cost: costByLineId[line.id],
          ),
        );
      }
    }

    return ReportDataSnapshot(
      rows: rows,
      filterOptions: {
        'warehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'customer': _entityOptions(
          parties.where(_canBuy),
          idOf: (party) => party.entityId,
          labelOf: (party) => party.name,
        ),
        'product': _itemOptions(items),
        'currency': _currencyOptions,
      },
    );
  }

  Future<ReportDataSnapshot> _currentStock() async {
    final values = await Future.wait([
      _repositories.warehouses.getAll(),
      _repositories.items.getAll(),
      _repositories.items.getGroups(),
      _repositories.items.getTypes(),
    ]);
    final warehouses = values[0] as List<Warehouse>;
    final items = values[1] as List<Item>;
    final groups = values[2] as List<ItemGroup>;
    final types = values[3] as List<ItemType>;
    final itemById = {for (final item in items) item.entityId: item};
    final entries = <({Warehouse warehouse, InventoryBalance balance})>[];
    for (final warehouse in warehouses) {
      for (final balance
          in await _repositories.warehouses.getInventory(warehouse.entityId)) {
        entries.add((warehouse: warehouse, balance: balance));
      }
    }
    entries.sort((first, second) {
      final byWarehouse = first.warehouse.number.compareTo(
        second.warehouse.number,
      );
      if (byWarehouse != 0) return byWarehouse;
      final firstCode = itemById[first.balance.itemId]?.code ?? '';
      final secondCode = itemById[second.balance.itemId]?.code ?? '';
      return firstCode.compareTo(secondCode);
    });

    final rows = <ReportRowDefinition>[];
    for (final entry in entries) {
      final item = itemById[entry.balance.itemId];
      rows.add(
        ReportRowDefinition(
          id: entry.balance.id.value,
          filterValues: {
            'warehouse': entry.warehouse.entityId.value,
            'product': entry.balance.itemId.value,
            if (item != null) ...{
              'group': item.groupEntityId.value,
              'type': item.typeEntityId.value,
            },
            'stockState': entry.balance.quantity.value > 0
                ? 'available'
                : 'out',
          },
          searchTerms: [if (item != null) item.barcode],
          cells: [
            '${rows.length + 1}',
            _availableLabel(item?.code, ''),
            _availableLabel(item?.name, ''),
            _availableLabel(item?.groupName, ''),
            _availableLabel(item?.typeName, ''),
            entry.warehouse.name,
            AppFormatters.quantity(entry.balance.quantity.value),
          ],
        ),
      );
    }

    return ReportDataSnapshot(
      rows: rows,
      filterOptions: {
        'warehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'product': _itemOptions(items),
        'group': _entityOptions(
          groups,
          idOf: (group) => group.entityId,
          labelOf: (group) => group.name,
        ),
        'type': _entityOptions(
          types,
          idOf: (type) => type.entityId,
          labelOf: (type) => type.name,
        ),
        'stockState': _stockStateOptions,
      },
    );
  }

  Future<ReportDataSnapshot> _transfers() async {
    final values = await Future.wait([
      _repositories.warehouses.getTransfers(),
      _repositories.warehouses.getAll(),
      _repositories.items.getAll(),
    ]);
    final transfers = values[0] as List<InventoryTransfer>;
    final warehouses = values[1] as List<Warehouse>;
    final items = values[2] as List<Item>;
    final warehouseById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
    };
    final itemById = {for (final item in items) item.entityId: item};
    final sorted = [...transfers]..sort((first, second) {
        final byTime = second.createdAt.compareTo(first.createdAt);
        if (byTime != 0) return byTime;
        return second.documentNumber.compareTo(first.documentNumber);
      });

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < sorted.length; index++)
          _transferRow(
            sorted[index],
            index: index,
            warehouseById: warehouseById,
            itemById: itemById,
          ),
      ],
      filterOptions: {
        'sourceWarehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'destinationWarehouse': _entityOptions(
          warehouses,
          idOf: (warehouse) => warehouse.entityId,
          labelOf: (warehouse) => warehouse.name,
        ),
        'product': _itemOptions(items),
      },
    );
  }

  Future<ReportDataSnapshot> _cashbox() async {
    final values = await Future.wait([
      _repositories.cashbox.getAll(),
      _repositories.cashbox.getMainAccounts(),
      _repositories.cashbox.getOpeningBalance(),
    ]);
    final vouchers = values[0] as List<CashboxVoucher>;
    final accounts = values[1] as List<CashboxMainAccount>;
    final opening = values[2] as CashboxBalanceSnapshot;
    final sorted = [...vouchers]..sort((first, second) {
        final byTime = second.createdTimestamp.compareTo(
          first.createdTimestamp,
        );
        if (byTime != 0) return byTime;
        return second.number.compareTo(first.number);
      });
    final subaccounts = [
      for (final account in accounts) ...account.subaccounts,
    ];

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < sorted.length; index++)
          _cashboxRow(sorted[index], index: index),
      ],
      filterOptions: {
        'transactionType': _cashboxTypeOptions,
        'mainAccount': _entityOptions(
          accounts,
          idOf: (account) => account.entityId,
          labelOf: (account) => account.label,
        ),
        'subAccount': _entityOptions(
          subaccounts,
          idOf: (account) => account.entityId,
          labelOf: (account) => account.label,
        ),
        'currency': _currencyOptions,
      },
      cashboxMetadata: CashboxReportMetadata(
        openingIqd: opening.iqd,
        openingUsd: opening.usd,
      ),
    );
  }

  Future<ReportDataSnapshot> _partyBalances() async {
    final values = await Future.wait([
      _repositories.parties.getAll(),
      _repositories.operationalMasterData.getByKind(
        OperationalMasterDataKind.workplace,
      ),
      _repositories.operationalMasterData.getByKind(
        OperationalMasterDataKind.branch,
      ),
    ]);
    final parties = (values[0] as List<Party>)
        .where((party) => _canBuy(party) || _canSupply(party))
        .toList(growable: false);
    final workplaces = values[1] as List<OperationalMasterDataRecord>;
    final branches = values[2] as List<OperationalMasterDataRecord>;
    final workplaceById = {
      for (final workplace in workplaces) workplace.id: workplace,
    };
    final branchById = {for (final branch in branches) branch.id: branch};
    final references = <EntityId, PartyMasterDataReferences?>{};
    for (final party in parties) {
      references[party.entityId] =
          await _repositories.parties.getMasterDataReferences(party.entityId);
    }
    final sorted = [...parties]
      ..sort((first, second) => first.number.compareTo(second.number));

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < sorted.length; index++)
          _partyBalanceRow(
            sorted[index],
            index: index,
            references: references[sorted[index].entityId],
            workplaceById: workplaceById,
            branchById: branchById,
          ),
      ],
      filterOptions: {
        'partyType': _partyTypeOptions,
        'direction': _directionOptions,
        'currency': _currencyOptions,
        'workEntity': _entityOptions(
          workplaces,
          idOf: (record) => record.id,
          labelOf: (record) => record.name,
        ),
        'branch': _entityOptions(
          branches,
          idOf: (record) => record.id,
          labelOf: (record) => record.name,
        ),
      },
    );
  }

  Future<ReportDataSnapshot> _debts() async {
    final values = await Future.wait([
      _repositories.sales.getAll(),
      _repositories.parties.getAll(),
      _repositories.installments.getAll(),
      _repositories.businessSettings.loadBusinessPolicies(),
    ]);
    final invoices = values[0] as List<SalesInvoice>;
    final parties = values[1] as List<Party>;
    final plans = values[2] as List<InstallmentPlan>;
    final policies = values[3] as BusinessPolicySettings;
    final partyById = {for (final party in parties) party.entityId: party};
    final invoiceById = {for (final invoice in invoices) invoice.id: invoice};
    final planInvoiceIds = {for (final plan in plans) plan.salesInvoiceId};
    if (plans.any((plan) => invoiceById[plan.salesInvoiceId] == null) ||
        invoices.any(
          (invoice) =>
              invoice.settlementKind == SalesSettlementKind.installments &&
              !planInvoiceIds.contains(invoice.id),
        )) {
      throw StateError('توجد خطة أقساط أو قائمة بيع مرتبطة بسجل مفقود');
    }
    final today = BusinessDate.fromDateTime(_clock());
    final creditInvoices = invoices
        .where(
          (invoice) =>
              invoice.settlementKind == SalesSettlementKind.credit &&
              invoice.total.compareTo(invoice.received) > 0,
        )
        .toList()
      ..sort(_compareSalesNewestFirst);
    final sortedPlans = [...plans]
      ..sort((first, second) {
        final firstInvoice = invoiceById[first.salesInvoiceId];
        final secondInvoice = invoiceById[second.salesInvoiceId];
        if (firstInvoice == null || secondInvoice == null) {
          return first.id.value.compareTo(second.id.value);
        }
        return _compareSalesNewestFirst(firstInvoice, secondInvoice);
      });
    final rows = <ReportRowDefinition>[];
    for (final invoice in creditInvoices) {
      rows.add(
        _debtRow(
          invoice,
          index: rows.length,
          partyById: partyById,
          dueDate: BusinessDate.fromDateTime(
            invoice.date.value.add(
              Duration(days: policies.defaultDebtDueDays),
            ),
          ),
          today: today,
        ),
      );
    }
    for (final plan in sortedPlans) {
      final invoice = invoiceById[plan.salesInvoiceId];
      if (invoice == null) continue;
      for (final entry in plan.entries) {
        rows.add(
          _installmentDebtRow(
            invoice,
            plan,
            entry,
            index: rows.length,
            partyById: partyById,
            today: today,
          ),
        );
      }
    }

    return ReportDataSnapshot(
      rows: rows,
      filterOptions: {
        'customer': _entityOptions(
          parties.where(_canBuy),
          idOf: (party) => party.entityId,
          labelOf: (party) => party.name,
        ),
        'recordType': _debtTypeOptions,
        'currency': _currencyOptions,
      },
    );
  }
}
