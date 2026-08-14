part of 'repository_report_data_service.dart';

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
  required SalesLineCostRecord? cost,
}) {
  final party = partyById[invoice.customerId];
  final item = itemById[line.itemId];
  final warehouse = warehouseById[line.warehouseId];
  final revenue = cost?.allocatedRevenue ?? line.total;
  final totalCost = cost?.totalCost;
  final profit = cost?.profit;
  final margin = profit == null || revenue.isZero
      ? null
      : profit.minorUnits * 100 / revenue.minorUnits;
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
      _money(revenue),
      totalCost == null ? '-' : _money(totalCost),
      profit == null ? '-' : _money(profit),
      margin == null ? '-' : '${margin.toStringAsFixed(2)}%',
      (cost?.availability ?? InventoryCostAvailability.unavailable)
          .arabicLabel,
      (cost?.method ?? InventoryCostMethod.unavailable).arabicLabel,
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
      '${_availableLabel(itemById[line.itemId]?.code, '')} - '
          '${_availableLabel(itemById[line.itemId]?.name, '')} '
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
        '',
      ),
      _availableLabel(
        warehouseById[transfer.toWarehouseId]?.name,
        '',
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
  final filterValues = <String, String>{
    'partyType': _partyTypeValue(party.type),
    'direction': directions.join('|'),
    'currency': currencies.isEmpty
        ? '${AppCurrency.iqd.code}|${AppCurrency.usd.code}'
        : currencies.join('|'),
  };
  if (workplaceId != null) filterValues['workEntity'] = workplaceId;
  if (branchId != null) filterValues['branch'] = branchId;
  return ReportRowDefinition(
    id: party.entityId.value,
    date: party.createdAt,
    filterValues: filterValues,
    searchTerms: [party.alternatePhone, party.address, party.notes],
    cells: [
      '${index + 1}',
      '${party.number}',
      party.name,
      party.type.label,
      workplaceEntityId == null && party.workplace.trim().isEmpty
          ? '—'
          : _availableLabel(workplaceName, party.workplace),
      branchEntityId == null && party.branch.trim().isEmpty
          ? '—'
          : _availableLabel(branchName, party.branch),
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
  required BusinessDate dueDate,
  required BusinessDate today,
}) {
  final remaining = invoice.total - invoice.received;
  final status = dueDate.compareTo(today) < 0 ? 'متأخر' : 'مستحق';
  return ReportRowDefinition(
    id: 'debt:${invoice.id.value}',
    date: dueDate.value,
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
      _date(dueDate.value),
      invoice.currency.arabicName,
      _money(invoice.total),
      _money(invoice.received),
      _money(remaining),
      status,
      'رصيد قائم من قائمة مبيعات',
    ],
  );
}

ReportRowDefinition _installmentDebtRow(
  SalesInvoice invoice,
  InstallmentPlan plan,
  InstallmentEntry entry, {
  required int index,
  required Map<EntityId, Party> partyById,
  required BusinessDate today,
}) {
  final status = entry.isPaid
      ? 'مدفوع'
      : entry.dueDate.compareTo(today) < 0
          ? 'متأخر'
          : 'مستحق';
  final paid = entry.isPaid
      ? entry.amount
      : Money.zero(plan.currency);
  final remaining = entry.isPaid
      ? Money.zero(plan.currency)
      : entry.amount;
  return ReportRowDefinition(
    id: 'installment:${entry.id.value}',
    date: entry.dueDate.value,
    filterValues: {
      'customer': plan.customerId.value,
      'recordType': 'installment',
      'currency': plan.currency.code,
    },
    searchTerms: [invoice.notes, entry.notes, invoice.searchDetailsSnapshot],
    cells: [
      '${index + 1}',
      'قسط',
      '${invoice.documentNumber}',
      '${entry.number}',
      _availableLabel(
        partyById[plan.customerId]?.name,
        invoice.customerNameSnapshot,
      ),
      _date(entry.dueDate.value),
      plan.currency.arabicName,
      _money(entry.amount),
      _money(paid),
      _money(remaining),
      status,
      entry.notes.isEmpty ? 'قسط قائمة مبيعات' : entry.notes,
    ],
  );
}
