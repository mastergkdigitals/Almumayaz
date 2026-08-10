import '../../../core/app_state/app_repositories.dart';
import '../../../core/design/app_formatters.dart';
import '../../../core/domain/business_values.dart';
import '../../cashbox/domain/cashbox_repository.dart';
import '../../cashbox/domain/cashbox_voucher.dart';
import '../../items/domain/item.dart';
import '../../parties/domain/party.dart';
import '../../parties/domain/party_repository.dart';
import '../../purchases/domain/purchase_invoice.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../warehouses/domain/inventory_records.dart';
import '../../warehouses/domain/warehouse.dart';
import '../application/report_data_snapshot_service.dart';
import '../application/report_rows_service.dart';
import '../presentation/report_definition.dart';

/// Repository-backed reports projection used by the Flutter demo application.
///
/// It intentionally does not retain a snapshot. Each call observes the latest
/// shared repository state, including invoice effects and warehouse transfers.
class RepositoryReportDataService
    implements ReportDataSnapshotService, ReportRowsService {
  const RepositoryReportDataService(this._repositories);

  final AppRepositories _repositories;

  @override
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request) async {
    return (await loadSnapshot(request)).rows;
  }

  @override
  Future<ReportDataSnapshot> loadSnapshot(ReportRowsRequest request) {
    return switch ((request.reportId, request.variantId)) {
      ('salesInvoices', 'main') => _sales(),
      ('purchaseInvoices', 'main') => _purchases(),
      ('profits', 'main') => _profits(),
      ('inventory', 'currentStock') => _currentStock(),
      ('inventory', 'transfers') => _transfers(),
      ('cashbox', 'main') => _cashbox(),
      ('partyBalances', 'main') => _partyBalances(),
      ('debtsInstallments', 'main') => _debts(),
      _ => Future.value(ReportDataSnapshot(rows: const [])),
    };
  }

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
    ]);
    final invoices = values[0] as List<SalesInvoice>;
    final parties = values[1] as List<Party>;
    final items = values[2] as List<Item>;
    final warehouses = values[3] as List<Warehouse>;
    final partyById = {for (final party in parties) party.entityId: party};
    final itemById = {for (final item in items) item.entityId: item};
    final warehouseById = {
      for (final warehouse in warehouses) warehouse.entityId: warehouse,
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
      if (item == null) continue;
      rows.add(
        ReportRowDefinition(
          id: entry.balance.id.value,
          filterValues: {
            'warehouse': entry.warehouse.entityId.value,
            'product': item.entityId.value,
            'group': item.groupEntityId.value,
            'type': item.typeEntityId.value,
            'stockState': entry.balance.quantity.value > 0
                ? 'available'
                : 'out',
          },
          searchTerms: [item.barcode],
          cells: [
            '${rows.length + 1}',
            item.code,
            item.name,
            item.groupName,
            item.typeName,
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
    ]);
    final invoices = values[0] as List<SalesInvoice>;
    final parties = values[1] as List<Party>;
    final partyById = {for (final party in parties) party.entityId: party};
    final outstanding = invoices
        .where((invoice) => invoice.total.compareTo(invoice.received) > 0)
        .toList()
      ..sort(_compareSalesNewestFirst);

    return ReportDataSnapshot(
      rows: [
        for (var index = 0; index < outstanding.length; index++)
          _debtRow(
            outstanding[index],
            index: index,
            partyById: partyById,
          ),
      ],
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

ReportRowDefinition _salesRow(
  SalesInvoice invoice, {
  required int index,
  required Map<EntityId, Party> partyById,
  required Map<EntityId, Warehouse> warehouseById,
}) {
  final customer = partyById[invoice.customerId]?.name;
  final warehouse = warehouseById[invoice.defaultWarehouseId]?.name;
  final remaining = invoice.total - invoice.received;
  return ReportRowDefinition(
    id: invoice.id.value,
    date: invoice.date.value,
    filterValues: {
      'warehouse': invoice.defaultWarehouseId.value,
      'customer': invoice.customerId.value,
      'saleType': _saleTypeValue(invoice.settlementKind),
      'currency': invoice.currency.code,
    },
    searchTerms: [invoice.notes, invoice.searchDetailsSnapshot],
    cells: [
      '${index + 1}',
      '${invoice.documentNumber}',
      _date(invoice.date.value),
      _availableLabel(customer, invoice.customerNameSnapshot),
      _availableLabel(warehouse, _firstWarehouseSnapshot(invoice.lines)),
      _saleTypeLabel(invoice.settlementKind),
      invoice.currency.arabicName,
      _money(invoice.total),
      _money(invoice.received),
      _money(remaining),
      '${invoice.lines.length}',
    ],
  );
}

ReportRowDefinition _purchaseRow(
  PurchaseInvoice invoice, {
  required int index,
  required Map<EntityId, Party> partyById,
  required Map<EntityId, Warehouse> warehouseById,
}) {
  final supplier = partyById[invoice.supplierId]?.name;
  final warehouse = warehouseById[invoice.defaultWarehouseId]?.name;
  final remaining = invoice.total - invoice.paid;
  return ReportRowDefinition(
    id: invoice.id.value,
    date: invoice.date.value,
    filterValues: {
      'warehouse': invoice.defaultWarehouseId.value,
      'supplier': invoice.supplierId.value,
      'purchaseType': _purchaseTypeValue(invoice.purchaseKind),
      'paymentType': _purchasePaymentValue(invoice.settlementKind),
      'currency': invoice.currency.code,
    },
    searchTerms: [invoice.notes, invoice.searchDetailsSnapshot],
    cells: [
      '${index + 1}',
      '${invoice.documentNumber}',
      _date(invoice.date.value),
      _availableLabel(supplier, invoice.supplierNameSnapshot),
      _availableLabel(
        warehouse,
        _firstPurchaseWarehouseSnapshot(invoice.lines),
      ),
      _purchaseTypeLabel(invoice.purchaseKind),
      _purchasePaymentLabel(invoice.settlementKind),
      invoice.currency.arabicName,
      _money(invoice.total),
      _money(invoice.paid),
      _money(remaining),
      '${invoice.lines.length}',
    ],
  );
}

ReportRowDefinition _profitRow(
  SalesInvoice invoice,
  SalesInvoiceLine line, {
  required int index,
  required Map<EntityId, Party> partyById,
  required Map<EntityId, Item> itemById,
  required Map<EntityId, Warehouse> warehouseById,
}) {
  final party = partyById[invoice.customerId];
  final item = itemById[line.itemId];
  final warehouse = warehouseById[line.warehouseId];
  return ReportRowDefinition(
    id: '${invoice.id.value}:${line.id.value}',
    date: invoice.date.value,
    filterValues: {
      'warehouse': line.warehouseId.value,
      'customer': invoice.customerId.value,
      'product': line.itemId.value,
      'currency': invoice.currency.code,
    },
    searchTerms: [invoice.notes, item?.barcode ?? ''],
    cells: [
      '${index + 1}',
      '${invoice.documentNumber}',
      _date(invoice.date.value),
      _availableLabel(party?.name, invoice.customerNameSnapshot),
      _availableLabel(warehouse?.name, line.warehouseNameSnapshot),
      _availableLabel(item?.code, line.itemCodeSnapshot),
      _availableLabel(item?.name, line.itemNameSnapshot),
      '${line.quantity.value}',
      _money(line.netUnitPrice),
      _money(line.total),
      '-',
      '-',
      '-',
      'غير متوفرة',
      '-',
      invoice.currency.arabicName,
    ],
  );
}

ReportRowDefinition _transferRow(
  InventoryTransfer transfer, {
  required int index,
  required Map<EntityId, Warehouse> warehouseById,
  required Map<EntityId, Item> itemById,
}) {
  final items = [
    for (final line in transfer.lines)
      '${_availableLabel(itemById[line.itemId]?.code, line.itemId.value)} - '
          '${_availableLabel(itemById[line.itemId]?.name, 'سجل مفقود')} '
          '(${line.quantity.value})',
  ];
  return ReportRowDefinition(
    id: transfer.id.value,
    date: transfer.createdAt.value.toLocal(),
    filterValues: {
      'sourceWarehouse': transfer.fromWarehouseId.value,
      'destinationWarehouse': transfer.toWarehouseId.value,
      'product': transfer.lines.map((line) => line.itemId.value).join('|'),
    },
    searchTerms: [
      for (final line in transfer.lines) ...[
        itemById[line.itemId]?.code ?? '',
        itemById[line.itemId]?.name ?? '',
      ],
      if (transfer.reversalOfId != null) 'عكس تصحيح',
    ],
    cells: [
      '${index + 1}',
      '${transfer.documentNumber}',
      _date(transfer.createdAt.value.toLocal()),
      _availableLabel(
        warehouseById[transfer.fromWarehouseId]?.name,
        'سجل مفقود',
      ),
      _availableLabel(
        warehouseById[transfer.toWarehouseId]?.name,
        'سجل مفقود',
      ),
      items.join('، '),
    ],
  );
}

ReportRowDefinition _cashboxRow(CashboxVoucher voucher, {required int index}) {
  final currencies = <String>[
    if (!voucher.iqdAmount.isZero) AppCurrency.iqd.code,
    if (!voucher.usdAmount.isZero) AppCurrency.usd.code,
  ];
  return ReportRowDefinition(
    id: voucher.entityId.value,
    date: voucher.createdAt,
    filterValues: {
      'transactionType': voucher.type == CashboxVoucherType.receipt
          ? 'in'
          : 'out',
      'mainAccount': voucher.mainAccountEntityId.value,
      'subAccount': voucher.subaccountEntityId.value,
      'currency': currencies.isEmpty
          ? '${AppCurrency.iqd.code}|${AppCurrency.usd.code}'
          : currencies.join('|'),
    },
    cells: [
      '${index + 1}',
      '${voucher.number}',
      _date(voucher.createdAt),
      _time(voucher.createdAt),
      voucher.type.label,
      voucher.mainAccountLabel,
      voucher.subaccountLabel,
      _money(voucher.iqdAmount),
      _money(voucher.usdAmount),
      voucher.exchangeRateValue.toPlainString(),
      voucher.notes.isEmpty ? '-' : voucher.notes,
    ],
  );
}

ReportRowDefinition _partyBalanceRow(
  Party party, {
  required int index,
  required PartyMasterDataReferences? references,
  required Map<EntityId, OperationalMasterDataRecord> workplaceById,
  required Map<EntityId, OperationalMasterDataRecord> branchById,
}) {
  final currencies = <String>[
    if (!party.iqdBalance.isZero) AppCurrency.iqd.code,
    if (!party.usdBalance.isZero) AppCurrency.usd.code,
  ];
  final directions = party.iqdBalance.isZero && party.usdBalance.isZero
      ? const {'zero'}
      : <String>{
          if (!party.iqdBalance.isZero)
            _balanceDirectionValue(party.iqdBalance),
          if (!party.usdBalance.isZero)
            _balanceDirectionValue(party.usdBalance),
        };
  final workplaceEntityId = references?.workplaceId;
  final branchEntityId = references?.branchId;
  final workplaceId = workplaceEntityId?.value;
  final branchId = branchEntityId?.value;
  final workplaceName = workplaceEntityId == null
      ? null
      : workplaceById[workplaceEntityId]?.name;
  final branchName =
      branchEntityId == null ? null : branchById[branchEntityId]?.name;
  return ReportRowDefinition(
    id: party.entityId.value,
    date: party.createdAt,
    filterValues: {
      'partyType': _partyTypeValue(party.type),
      'direction': directions.join('|'),
      'currency': currencies.isEmpty
          ? '${AppCurrency.iqd.code}|${AppCurrency.usd.code}'
          : currencies.join('|'),
      if (workplaceId != null) 'workEntity': workplaceId,
      if (branchId != null) 'branch': branchId,
    },
    searchTerms: [party.alternatePhone, party.address, party.notes],
    cells: [
      '${index + 1}',
      '${party.number}',
      party.name,
      party.type.label,
      _availableLabel(workplaceName, party.workplace),
      _availableLabel(branchName, party.branch),
      party.phone,
      party.city,
      _money(party.iqdBalance.absolute),
      _balanceDirectionLabel(party.iqdBalance),
      _money(party.usdBalance.absolute),
      _balanceDirectionLabel(party.usdBalance),
    ],
  );
}

ReportRowDefinition _debtRow(
  SalesInvoice invoice, {
  required int index,
  required Map<EntityId, Party> partyById,
}) {
  final remaining = invoice.total - invoice.received;
  return ReportRowDefinition(
    id: 'debt:${invoice.id.value}',
    date: invoice.date.value,
    filterValues: {
      'customer': invoice.customerId.value,
      'recordType': 'debt',
      'currency': invoice.currency.code,
    },
    searchTerms: [invoice.notes, invoice.searchDetailsSnapshot],
    cells: [
      '${index + 1}',
      'دين',
      '${invoice.documentNumber}',
      '-',
      _availableLabel(
        partyById[invoice.customerId]?.name,
        invoice.customerNameSnapshot,
      ),
      _date(invoice.date.value),
      invoice.currency.arabicName,
      _money(invoice.total),
      _money(invoice.received),
      _money(remaining),
      'قائم',
      'رصيد قائم من قائمة مبيعات',
    ],
  );
}

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterOption> _saleTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('cash', 'نقدي'),
  ReportFilterOption('credit', 'آجل'),
  ReportFilterOption('installments', 'أقساط'),
];

const List<ReportFilterOption> _purchaseTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('local', 'محلي'),
  ReportFilterOption('import', 'إستيراد'),
  ReportFilterOption('return', 'إرجاع'),
];

const List<ReportFilterOption> _purchasePaymentOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('cash', 'نقدي'),
  ReportFilterOption('credit', 'آجل'),
];

const List<ReportFilterOption> _stockStateOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('available', 'متوفر'),
  ReportFilterOption('out', 'نافد'),
];

const List<ReportFilterOption> _cashboxTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('in', 'قبض'),
  ReportFilterOption('out', 'صرف'),
];

const List<ReportFilterOption> _partyTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('customer', 'زبون'),
  ReportFilterOption('supplier', 'مجهز'),
  ReportFilterOption('both', 'زبون ومجهز'),
];

const List<ReportFilterOption> _directionOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('receivable', 'لنا'),
  ReportFilterOption('payable', 'علينا'),
  ReportFilterOption('zero', 'صفر'),
];

const List<ReportFilterOption> _debtTypeOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('debt', 'دين'),
];

List<ReportFilterOption> _entityOptions<T>(
  Iterable<T> values, {
  required EntityId Function(T value) idOf,
  required String Function(T value) labelOf,
}) {
  final sorted = values.toList()
    ..sort((first, second) => labelOf(first).compareTo(labelOf(second)));
  return [
    const ReportFilterOption('all', 'الكل'),
    for (final value in sorted)
      ReportFilterOption(idOf(value).value, labelOf(value)),
  ];
}

List<ReportFilterOption> _itemOptions(Iterable<Item> items) =>
    _entityOptions(
      items,
      idOf: (item) => item.entityId,
      labelOf: (item) => '${item.code} - ${item.name}',
    );

bool _canBuy(Party party) =>
    party.type == PartyType.customer ||
    party.type == PartyType.customerAndSupplier;

bool _canSupply(Party party) =>
    party.type == PartyType.supplier ||
    party.type == PartyType.customerAndSupplier;

int _compareSalesNewestFirst(SalesInvoice first, SalesInvoice second) {
  final byDate = second.date.compareTo(first.date);
  if (byDate != 0) return byDate;
  final byTime = second.minuteOfDay.compareTo(first.minuteOfDay);
  return byTime != 0
      ? byTime
      : second.documentNumber.compareTo(first.documentNumber);
}

int _comparePurchasesNewestFirst(
  PurchaseInvoice first,
  PurchaseInvoice second,
) {
  final byDate = second.date.compareTo(first.date);
  if (byDate != 0) return byDate;
  final byTime = second.minuteOfDay.compareTo(first.minuteOfDay);
  return byTime != 0
      ? byTime
      : second.documentNumber.compareTo(first.documentNumber);
}

String _date(DateTime value) => AppFormatters.date(value);

String _time(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final period = value.hour < 12 ? 'ص' : 'م';
  return '${hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')} $period';
}

String _money(Money value) => AppFormatters.money(
      value.majorUnits,
      decimalPlaces: value.currency.decimalPlaces,
    );

String _availableLabel(String? live, String snapshot) {
  final liveValue = live?.trim() ?? '';
  if (liveValue.isNotEmpty) return liveValue;
  final snapshotValue = snapshot.trim();
  return snapshotValue.isEmpty ? 'سجل مفقود' : snapshotValue;
}

String _firstWarehouseSnapshot(List<SalesInvoiceLine> lines) =>
    lines.isEmpty ? '' : lines.first.warehouseNameSnapshot;

String _firstPurchaseWarehouseSnapshot(List<PurchaseInvoiceLine> lines) =>
    lines.isEmpty ? '' : lines.first.warehouseNameSnapshot;

String _saleTypeValue(SalesSettlementKind value) => switch (value) {
      SalesSettlementKind.cash => 'cash',
      SalesSettlementKind.credit => 'credit',
      SalesSettlementKind.installments => 'installments',
    };

String _saleTypeLabel(SalesSettlementKind value) => switch (value) {
      SalesSettlementKind.cash => 'نقدي',
      SalesSettlementKind.credit => 'آجل',
      SalesSettlementKind.installments => 'أقساط',
    };

String _purchaseTypeValue(PurchaseTransactionKind value) => switch (value) {
      PurchaseTransactionKind.local => 'local',
      PurchaseTransactionKind.import => 'import',
      PurchaseTransactionKind.returnPurchase => 'return',
    };

String _purchaseTypeLabel(PurchaseTransactionKind value) => switch (value) {
      PurchaseTransactionKind.local => 'محلي',
      PurchaseTransactionKind.import => 'إستيراد',
      PurchaseTransactionKind.returnPurchase => 'إرجاع',
    };

String _purchasePaymentValue(PurchaseSettlementKind value) => switch (value) {
      PurchaseSettlementKind.cash => 'cash',
      PurchaseSettlementKind.credit => 'credit',
    };

String _purchasePaymentLabel(PurchaseSettlementKind value) => switch (value) {
      PurchaseSettlementKind.cash => 'نقدي',
      PurchaseSettlementKind.credit => 'آجل',
    };

String _partyTypeValue(PartyType value) => switch (value) {
      PartyType.customer => 'customer',
      PartyType.supplier => 'supplier',
      PartyType.customerAndSupplier => 'both',
      PartyType.employee => 'employee',
    };

String _balanceDirectionValue(Money value) {
  if (value.isPositive) return 'receivable';
  if (value.isNegative) return 'payable';
  return 'zero';
}

String _balanceDirectionLabel(Money value) {
  if (value.isPositive) return 'لنا';
  if (value.isNegative) return 'علينا';
  return 'صفر';
}
