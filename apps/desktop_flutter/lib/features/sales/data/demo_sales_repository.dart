import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/sales_invoice.dart';
import '../domain/sales_repository.dart';

typedef SalesReferenceExists = Future<bool> Function(EntityId id);

class DemoSalesRepository extends InMemoryDemoRepository<SalesInvoice>
    implements SalesRepository {
  factory DemoSalesRepository({
    Iterable<SalesInvoice>? initialValues,
    required SalesReferenceExists partyExists,
    required SalesReferenceExists itemExists,
    required SalesReferenceExists warehouseExists,
  }) {
    final values = List<SalesInvoice>.of(
      initialValues ?? demoSalesInvoices(),
    );
    return DemoSalesRepository._(
      initialValues: values,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
    );
  }

  DemoSalesRepository._({
    required List<SalesInvoice> initialValues,
    required SalesReferenceExists partyExists,
    required SalesReferenceExists itemExists,
    required SalesReferenceExists warehouseExists,
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

  final SalesReferenceExists _partyExists;
  final SalesReferenceExists _itemExists;
  final SalesReferenceExists _warehouseExists;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;

  @override
  Future<SalesInvoice> save(SalesInvoice value) async {
    return await getById(value.id) == null
        ? createInvoice(value)
        : replaceInvoice(value);
  }

  @override
  Future<SalesInvoice> createInvoice(SalesInvoice invoice) async {
    if (await getById(invoice.id) != null) {
      throw StateError('معرف فاتورة البيع مستخدم مسبقاً');
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
  Future<SalesInvoice> replaceInvoice(SalesInvoice invoice) async {
    final existing = await getById(invoice.id);
    if (existing == null) {
      throw StateError('فاتورة البيع غير موجودة');
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

  Future<void> _validate(SalesInvoice value) async {
    if (!await _partyExists(value.customerId)) {
      throw StateError('الزبون المحدد غير موجود');
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
    SalesInvoice value, {
    int? previousDocumentNumber,
  }) {
    if (previousDocumentNumber != value.documentNumber &&
        _issuedDocumentNumbers.contains(value.documentNumber)) {
      throw StateError('رقم فاتورة البيع مستخدم مسبقاً');
    }
  }

  @override
  Future<void> deleteInvoicePermanently(EntityId id) => super.delete(id);

  @override
  Future<List<SalesInvoice>> search(String query) async {
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

int _highestDocumentNumber(Iterable<SalesInvoice> invoices) {
  var highest = 0;
  for (final invoice in invoices) {
    if (invoice.documentNumber > highest) highest = invoice.documentNumber;
  }
  return highest;
}

List<SalesInvoice> demoSalesInvoices() => [
      SalesInvoice(
        id: EntityId.demo('sale', 1),
        documentNumber: 1001,
        date: BusinessDate(2026, 7, 28),
        minuteOfDay: 10 * 60 + 30,
        customerId: EntityId.demo('party', 1),
        defaultWarehouseId: EntityId.demo('warehouse', 1),
        currency: AppCurrency.iqd,
        exchangeRate: ExchangeRate.parse('1310'),
        settlementKind: SalesSettlementKind.credit,
        lines: [
          SalesInvoiceLine(
            id: EntityId.demo('sale-line', 1),
            itemId: EntityId.demo('item', 1),
            warehouseId: EntityId.demo('warehouse', 1),
            quantity: WholeQuantity(2),
            unitPrice: Money.fromMajor(285000, AppCurrency.iqd),
            discountPerUnit: Money.zero(AppCurrency.iqd),
          ),
        ],
        invoiceDiscount: Money.zero(AppCurrency.iqd),
        received: Money.fromMajor(200000, AppCurrency.iqd),
        driverName: 'مصطفى علي',
        notes: 'فاتورة تجريبية مشتركة',
      ),
    ];
