import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/purchase_invoice.dart';
import '../domain/purchase_repository.dart';

typedef PurchaseReferenceExists = Future<bool> Function(EntityId id);

class DemoPurchaseRepository extends InMemoryDemoRepository<PurchaseInvoice>
    implements PurchaseRepository {
  factory DemoPurchaseRepository({
    Iterable<PurchaseInvoice>? initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
  }) {
    final values = List<PurchaseInvoice>.of(
      initialValues ?? demoPurchaseInvoices(),
    );
    return DemoPurchaseRepository._(
      initialValues: values,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
    );
  }

  DemoPurchaseRepository._({
    required List<PurchaseInvoice> initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
  })  : _partyExists = partyExists,
        _itemExists = itemExists,
        _warehouseExists = warehouseExists,
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
    return List.unmodifiable(
      values.where(
        (invoice) => [
          invoice.documentNumber,
          invoice.date,
          invoice.currency.code,
          invoice.notes,
        ].join(' ').toLowerCase().contains(normalized),
      ),
    );
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
      PurchaseInvoice(
        id: EntityId.demo('purchase', 1),
        documentNumber: 2001,
        date: BusinessDate(2026, 7, 27),
        minuteOfDay: 9 * 60 + 15,
        supplierId: EntityId.demo('party', 3),
        defaultWarehouseId: EntityId.demo('warehouse', 1),
        currency: AppCurrency.iqd,
        exchangeRate: ExchangeRate.parse('1310'),
        purchaseKind: PurchaseTransactionKind.local,
        settlementKind: PurchaseSettlementKind.cash,
        lines: [
          PurchaseInvoiceLine(
            id: EntityId.demo('purchase-line', 1),
            itemId: EntityId.demo('item', 2),
            warehouseId: EntityId.demo('warehouse', 1),
            quantity: WholeQuantity(5),
            containerQuantity: WholeQuantity(0),
            purchasePrice: Money.fromMajor(65000, AppCurrency.iqd),
            lineDiscount: Money.zero(AppCurrency.iqd),
            salePrice: Money.fromMajor(72000, AppCurrency.iqd),
          ),
        ],
        expenses: Money.zero(AppCurrency.iqd),
        invoiceDiscount: Money.zero(AppCurrency.iqd),
        paid: Money.fromMajor(325000, AppCurrency.iqd),
        notes: 'فاتورة شراء تجريبية مشتركة',
      ),
    ];
