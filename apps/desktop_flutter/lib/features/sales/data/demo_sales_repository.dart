import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/sales_invoice.dart';
import '../domain/sales_repository.dart';
import 'demo_sales_mutation_effects.dart';

typedef SalesReferenceExists = Future<bool> Function(EntityId id);
typedef SalesReferenceLabel = Future<String?> Function(EntityId id);

class DemoSalesRepository extends InMemoryDemoRepository<SalesInvoice>
    implements SalesRepository {
  factory DemoSalesRepository({
    Iterable<SalesInvoice>? initialValues,
    required SalesReferenceExists partyExists,
    required SalesReferenceExists itemExists,
    required SalesReferenceExists warehouseExists,
    required DemoSalesMutationEffects mutationEffects,
    SalesReferenceLabel? partyLabelOf,
    SalesReferenceLabel? itemLabelOf,
  }) {
    final values = List<SalesInvoice>.of(
      initialValues ?? demoSalesInvoices(),
    );
    return DemoSalesRepository._(
      initialValues: values,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
      mutationEffects: mutationEffects,
      partyLabelOf: partyLabelOf,
      itemLabelOf: itemLabelOf,
    );
  }

  DemoSalesRepository._({
    required List<SalesInvoice> initialValues,
    required SalesReferenceExists partyExists,
    required SalesReferenceExists itemExists,
    required SalesReferenceExists warehouseExists,
    required DemoSalesMutationEffects mutationEffects,
    SalesReferenceLabel? partyLabelOf,
    SalesReferenceLabel? itemLabelOf,
  })  : _partyExists = partyExists,
        _itemExists = itemExists,
        _warehouseExists = warehouseExists,
        _mutationEffects = mutationEffects,
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

  final SalesReferenceExists _partyExists;
  final SalesReferenceExists _itemExists;
  final SalesReferenceExists _warehouseExists;
  final DemoSalesMutationEffects _mutationEffects;
  final SalesReferenceLabel? _partyLabelOf;
  final SalesReferenceLabel? _itemLabelOf;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;

  @override
  Future<SalesInvoice> save(SalesInvoice value) =>
      _applyInvoice(value, mode: _SalesMutationMode.upsert);

  @override
  Future<SalesInvoice> createInvoice(SalesInvoice invoice) =>
      _applyInvoice(invoice, mode: _SalesMutationMode.create);

  @override
  Future<SalesInvoice> replaceInvoice(SalesInvoice invoice) =>
      _applyInvoice(invoice, mode: _SalesMutationMode.replace);

  Future<SalesInvoice> _applyInvoice(
    SalesInvoice invoice, {
    required _SalesMutationMode mode,
  }) {
    return _mutationEffects.applySale(
      candidate: invoice,
      preflightAndLoadPrevious: () async {
        final existing = getDemoValue(invoice.id);
        if (mode == _SalesMutationMode.create && existing != null) {
          throw StateError('معرف فاتورة البيع مستخدم مسبقاً');
        }
        if (mode == _SalesMutationMode.replace && existing == null) {
          throw StateError('فاتورة البيع غير موجودة');
        }
        await _validate(invoice);
        _ensureDocumentNumberAvailable(
          invoice,
          previousDocumentNumber: existing?.documentNumber,
        );
        return existing;
      },
      commit: (normalized) {
        final staged = createDemoSnapshot();
        staged[normalized.id] = normalized;
        commitDemoSnapshot(staged);
        _reserveDocumentNumber(normalized.documentNumber);
      },
    );
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

  void _reserveDocumentNumber(int documentNumber) {
    _issuedDocumentNumbers.add(documentNumber);
    if (documentNumber > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = documentNumber;
    }
  }

  @override
  Future<void> delete(EntityId id) => deleteInvoicePermanently(id);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) {
    return _mutationEffects.deleteSale(
      id: id,
      preflightAndLoadPrevious: () async {
        final existing = getDemoValue(id);
        if (existing == null) {
          throw StateError('فاتورة البيع غير موجودة');
        }
        return existing;
      },
      commit: () {
        final staged = createDemoSnapshot()..remove(id);
        commitDemoSnapshot(staged);
      },
    );
  }

  @override
  Future<List<SalesInvoice>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final values = await getAll();
    if (normalized.isEmpty) return values;
    final matches = <SalesInvoice>[];
    for (final invoice in values) {
      final resolvedParty = await _partyLabelOf?.call(invoice.customerId);
      final resolvedItems = <String?>[];
      for (final line in invoice.lines) {
        resolvedItems.add(await _itemLabelOf?.call(line.itemId));
      }
      final searchText = [
        invoice.documentNumber,
        invoice.date,
        invoice.currency.code,
        invoice.notes,
        invoice.customerNameSnapshot,
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

enum _SalesMutationMode { create, replace, upsert }

int _highestDocumentNumber(Iterable<SalesInvoice> invoices) {
  var highest = 0;
  for (final invoice in invoices) {
    if (invoice.documentNumber > highest) highest = invoice.documentNumber;
  }
  return highest;
}

List<SalesInvoice> demoSalesInvoices() => [
      _sales101(),
      _sales102(),
      _sales103(),
    ];

SalesInvoice _sales101() => SalesInvoice(
      id: EntityId('sales-invoice-101'),
      documentNumber: 101,
      date: BusinessDate(2026, 7, 25),
      minuteOfDay: 9 * 60 + 15,
      customerId: EntityId('party-001'),
      customerNameSnapshot: 'شركة النخيل للتجارة',
      searchDetailsSnapshot: '25/07/2026 • 3 مواد • آجل',
      defaultWarehouseId: EntityId('warehouse-003'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      settlementKind: SalesSettlementKind.credit,
      lines: [
        _salesLine(1011, 'item-003', 'warehouse-003', 5, 12000, 0,
            '3001', 'ورق طباعة', 'الرصافة', AppCurrency.iqd),
        _salesLine(1012, 'item-002', 'warehouse-003', 2, 45000, 0,
            '3002', 'حبر طابعة', 'الرصافة', AppCurrency.iqd),
        _salesLine(1013, 'item-009', 'warehouse-001', 3, 10000, 1000,
            '3003', 'دباسة', 'الرئيسي', AppCurrency.iqd),
      ],
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      received: Money.zero(AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(625000, AppCurrency.iqd),
      driverName: 'كرار مهدي',
      notes: 'تضاف إلى حساب الزبون',
    );

SalesInvoice _sales102() => SalesInvoice(
      id: EntityId('sales-invoice-102'),
      documentNumber: 102,
      date: BusinessDate(2026, 7, 26),
      minuteOfDay: 12 * 60 + 40,
      customerId: EntityId('party-002'),
      customerNameSnapshot: 'أحمد كريم',
      searchDetailsSnapshot: '26/07/2026 • مادتان • أقساط',
      defaultWarehouseId: EntityId('warehouse-004'),
      currency: AppCurrency.usd,
      exchangeRate: ExchangeRate.parse('1310'),
      settlementKind: SalesSettlementKind.installments,
      lines: [
        _salesLine(1021, 'item-007', 'warehouse-004', 1, 900, 50,
            '2001', 'طابعة حرارية', 'المنصور', AppCurrency.usd),
        _salesLine(1022, 'item-008', 'warehouse-004', 2, 200, 0,
            '2002', 'ماسح باركود', 'المنصور', AppCurrency.usd),
      ],
      invoiceDiscount: Money.zero(AppCurrency.usd),
      received: Money.fromMajor(250, AppCurrency.usd),
      balanceAfterInvoice: Money.fromMajor(1500, AppCurrency.usd),
      driverName: 'حيدر سالم',
      notes: 'تسديد القسط الأول عند التسليم',
    );

SalesInvoice _sales103() => SalesInvoice(
      id: EntityId('sales-invoice-103'),
      documentNumber: 103,
      date: BusinessDate(2026, 7, 27),
      minuteOfDay: 10 * 60 + 25,
      customerId: EntityId('party-005'),
      customerNameSnapshot: 'أسواق دجلة',
      searchDetailsSnapshot: '27/07/2026 • 3 مواد',
      defaultWarehouseId: EntityId('warehouse-001'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      settlementKind: SalesSettlementKind.cash,
      lines: [
        _salesLine(1031, 'item-010', 'warehouse-001', 4, 35000, 0,
            '1001', 'دفتر ملاحظات', 'الرئيسي', AppCurrency.iqd),
        _salesLine(1032, 'item-005', 'warehouse-001', 10, 5000, 0,
            '1002', 'قلم أزرق', 'الرئيسي', AppCurrency.iqd),
        _salesLine(1033, 'item-004', 'warehouse-002', 1, 130000, 5000,
            '1003', 'حاسبة مكتبية', 'الكرادة', AppCurrency.iqd),
      ],
      invoiceDiscount: Money.fromMajor(5000, AppCurrency.iqd),
      received: Money.fromMajor(310000, AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(120000, AppCurrency.iqd),
      driverName: 'مصطفى علي',
      notes: 'تسليم الطلب إلى فرع الكرادة',
    );

SalesInvoiceLine _salesLine(
  int sequence,
  String itemId,
  String warehouseId,
  int quantity,
  num unitPrice,
  num discountPerUnit,
  String code,
  String name,
  String warehouseName,
  AppCurrency currency,
) =>
    SalesInvoiceLine(
      id: EntityId('sales-line-$sequence'),
      itemId: EntityId(itemId),
      warehouseId: EntityId(warehouseId),
      quantity: WholeQuantity(quantity),
      unitPrice: Money.fromMajor(unitPrice, currency),
      discountPerUnit: Money.fromMajor(discountPerUnit, currency),
      itemCodeSnapshot: code,
      itemNameSnapshot: name,
      warehouseNameSnapshot: warehouseName,
    );
