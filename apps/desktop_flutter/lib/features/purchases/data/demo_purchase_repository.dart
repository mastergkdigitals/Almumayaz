import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/purchase_invoice.dart';
import '../domain/purchase_repository.dart';

typedef PurchaseReferenceExists = Future<bool> Function(EntityId id);
typedef PurchaseReferenceLabel = Future<String?> Function(EntityId id);

class DemoPurchaseRepository extends InMemoryDemoRepository<PurchaseInvoice>
    implements PurchaseRepository {
  factory DemoPurchaseRepository({
    Iterable<PurchaseInvoice>? initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
    PurchaseReferenceLabel? partyLabelOf,
    PurchaseReferenceLabel? itemLabelOf,
  }) {
    final values = List<PurchaseInvoice>.of(
      initialValues ?? demoPurchaseInvoices(),
    );
    return DemoPurchaseRepository._(
      initialValues: values,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
      partyLabelOf: partyLabelOf,
      itemLabelOf: itemLabelOf,
    );
  }

  DemoPurchaseRepository._({
    required List<PurchaseInvoice> initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
    PurchaseReferenceLabel? partyLabelOf,
    PurchaseReferenceLabel? itemLabelOf,
  })  : _partyExists = partyExists,
        _itemExists = itemExists,
        _warehouseExists = warehouseExists,
        _partyLabelOf = partyLabelOf,
        _itemLabelOf = itemLabelOf,
        _highestIssuedDocumentNumber = _highestDocumentNumber(initialValues),
        _issuedDocumentNumbers = {
          for (final invoice in initialValues) invoice.documentNumber,
        },
        super(
          initialValues: initialValues,
          idOf: (invoice) => invoice.id,
        );

  final PurchaseReferenceExists _partyExists;
  final PurchaseReferenceExists _itemExists;
  final PurchaseReferenceExists _warehouseExists;
  final PurchaseReferenceLabel? _partyLabelOf;
  final PurchaseReferenceLabel? _itemLabelOf;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;

  @override
  Future<PurchaseInvoice> save(PurchaseInvoice value) async {
    return await getById(value.id) == null
        ? createInvoice(value)
        : replaceInvoice(value);
  }

  @override
  Future<PurchaseInvoice> createInvoice(PurchaseInvoice invoice) async {
    if (await getById(invoice.id) != null) {
      throw StateError('معرف فاتورة الشراء مستخدم مسبقاً');
    }
    await _validate(invoice);
    _ensureDocumentNumberAvailable(invoice);
    final saved = await super.save(invoice);
    _issuedDocumentNumbers.add(invoice.documentNumber);
    if (invoice.documentNumber > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = invoice.documentNumber;
    }
    return saved;
  }

  @override
  Future<PurchaseInvoice> replaceInvoice(PurchaseInvoice invoice) async {
    final existing = await getById(invoice.id);
    if (existing == null) {
      throw StateError('فاتورة الشراء غير موجودة');
    }
    await _validate(invoice);
    _ensureDocumentNumberAvailable(
      invoice,
      previousDocumentNumber: existing.documentNumber,
    );
    final saved = await super.save(invoice);
    _issuedDocumentNumbers.add(invoice.documentNumber);
    if (invoice.documentNumber > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = invoice.documentNumber;
    }
    return saved;
  }

  Future<void> _validate(PurchaseInvoice value) async {
    if (!await _partyExists(value.supplierId)) {
      throw StateError('المجهز المحدد غير موجود');
    }
    if (!await _warehouseExists(value.defaultWarehouseId)) {
      throw StateError('المخزن المحدد غير موجود');
    }
    for (final line in value.lines) {
      if (!await _itemExists(line.itemId)) {
        throw StateError('إحدى المواد المحددة غير موجودة');
      }
      if (!await _warehouseExists(line.warehouseId)) {
        throw StateError('مخزن إحدى مواد الفاتورة غير موجود');
      }
    }
  }

  void _ensureDocumentNumberAvailable(
    PurchaseInvoice value, {
    int? previousDocumentNumber,
  }) {
    if (previousDocumentNumber != value.documentNumber &&
        _issuedDocumentNumbers.contains(value.documentNumber)) {
      throw StateError('رقم فاتورة الشراء مستخدم مسبقاً');
    }
  }

  @override
  Future<void> deleteInvoicePermanently(EntityId id) => super.delete(id);

  @override
  Future<List<PurchaseInvoice>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final values = await getAll();
    if (normalized.isEmpty) return values;
    final matches = <PurchaseInvoice>[];
    for (final invoice in values) {
      final resolvedParty = await _partyLabelOf?.call(invoice.supplierId);
      final resolvedItems = <String?>[];
      for (final line in invoice.lines) {
        resolvedItems.add(await _itemLabelOf?.call(line.itemId));
      }
      final searchText = [
        invoice.documentNumber,
        invoice.date,
        invoice.currency.code,
        invoice.notes,
        invoice.supplierNameSnapshot,
        resolvedParty,
        for (final line in invoice.lines) ...[
          line.itemCodeSnapshot,
          line.itemNameSnapshot,
        ],
        ...resolvedItems,
      ].join(' ').toLowerCase();
      if (searchText.contains(normalized)) matches.add(invoice);
    }
    return List.unmodifiable(matches);
  }

  @override
  Future<int> nextDocumentNumber() async {
    return _highestIssuedDocumentNumber + 1;
  }
}

int _highestDocumentNumber(Iterable<PurchaseInvoice> invoices) {
  var highest = 0;
  for (final invoice in invoices) {
    if (invoice.documentNumber > highest) highest = invoice.documentNumber;
  }
  return highest;
}

List<PurchaseInvoice> demoPurchaseInvoices() => [
      _purchase101(),
      _purchase102(),
      _purchase103(),
    ];

PurchaseInvoice _purchase101() => PurchaseInvoice(
      id: EntityId('purchase-invoice-101'),
      documentNumber: 101,
      date: BusinessDate(2026, 7, 25),
      minuteOfDay: 9 * 60 + 45,
      supplierId: EntityId('party-011'),
      supplierNameSnapshot: 'شركة الرافدين للتجهيز',
      searchDetailsSnapshot: '25/07/2026 • مادتان • محلي',
      defaultWarehouseId: EntityId('warehouse-003'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.local,
      settlementKind: PurchaseSettlementKind.credit,
      lines: [
        _purchaseLine(1011, 'item-003', 'warehouse-003', 10, 0, 8000, 0,
            12000, 'P1001', 'ورق طباعة A4', 'الرصافة', AppCurrency.iqd),
        _purchaseLine(1012, 'item-002', 'warehouse-003', 2, 0, 35000, 5000,
            45000, 'P1002', 'حبر طابعة', 'الرصافة', AppCurrency.iqd),
      ],
      expenses: Money.fromMajor(5000, AppCurrency.iqd),
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      paid: Money.zero(AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(450000, AppCurrency.iqd),
      notes: 'تضاف إلى حساب المجهز',
    );

PurchaseInvoice _purchase102() => PurchaseInvoice(
      id: EntityId('purchase-invoice-102'),
      documentNumber: 102,
      date: BusinessDate(2026, 7, 26),
      minuteOfDay: 13 * 60 + 20,
      supplierId: EntityId('party-012'),
      supplierNameSnapshot: 'شركة التجارة العالمية',
      searchDetailsSnapshot: '26/07/2026 • مادتان • إستيراد',
      defaultWarehouseId: EntityId('warehouse-004'),
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.import,
      settlementKind: PurchaseSettlementKind.credit,
      lines: [
        _purchaseLine(1021, 'item-007', 'warehouse-004', 2, 1, 600, 50,
            900, 'P2001', 'طابعة حرارية', 'المنصور', AppCurrency.usd),
        _purchaseLine(1022, 'item-008', 'warehouse-004', 3, 1, 100, 0,
            200, 'P2002', 'ماسح باركود', 'المنصور', AppCurrency.usd),
      ],
      expenses: Money.fromMajor(100, AppCurrency.usd),
      invoiceDiscount: Money.fromMajor(50, AppCurrency.usd),
      paid: Money.fromMajor(500, AppCurrency.usd),
      balanceAfterInvoice: Money.fromMajor(1250, AppCurrency.usd),
      notes: 'أجور الشحن مضافة إلى مصاريف القائمة',
    );

PurchaseInvoice _purchase103() => PurchaseInvoice(
      id: EntityId('purchase-invoice-103'),
      documentNumber: 103,
      date: BusinessDate(2026, 7, 27),
      minuteOfDay: 11 * 60 + 35,
      supplierId: EntityId('party-013'),
      supplierNameSnapshot: 'مجهز الكرادة',
      searchDetailsSnapshot: '27/07/2026 • مادة واحدة • نقدي',
      defaultWarehouseId: EntityId('warehouse-001'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.returnPurchase,
      settlementKind: PurchaseSettlementKind.cash,
      lines: [
        _purchaseLine(1031, 'item-006', 'warehouse-001', 5, 0, 20000, 0,
            27000, 'P3001', 'حافظة مستندات', 'الرئيسي', AppCurrency.iqd),
      ],
      expenses: Money.zero(AppCurrency.iqd),
      invoiceDiscount: Money.fromMajor(10000, AppCurrency.iqd),
      paid: Money.fromMajor(90000, AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(80000, AppCurrency.iqd),
      notes: 'إرجاع مواد واستبدالها ضمن القائمة',
    );

PurchaseInvoiceLine _purchaseLine(
  int sequence,
  String itemId,
  String warehouseId,
  int quantity,
  int container,
  num purchasePrice,
  num lineDiscount,
  num salePrice,
  String code,
  String name,
  String warehouseName,
  AppCurrency currency,
) =>
    PurchaseInvoiceLine(
      id: EntityId('purchase-line-$sequence'),
      itemId: EntityId(itemId),
      warehouseId: EntityId(warehouseId),
      quantity: WholeQuantity(quantity),
      containerQuantity: WholeQuantity(container),
      purchasePrice: Money.fromMajor(purchasePrice, currency),
      lineDiscount: Money.fromMajor(lineDiscount, currency),
      salePrice: Money.fromMajor(salePrice, currency),
      itemCodeSnapshot: code,
      itemNameSnapshot: name,
      warehouseNameSnapshot: warehouseName,
    );
