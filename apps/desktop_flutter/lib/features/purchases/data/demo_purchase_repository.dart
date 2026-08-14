import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../domain/purchase_invoice.dart';
import '../domain/purchase_repository.dart';
import '../domain/purchase_return_policy.dart';
import 'demo_purchase_mutation_effects.dart';

typedef PurchaseReferenceExists = Future<bool> Function(EntityId id);
typedef PurchaseReferenceLabel = Future<String?> Function(EntityId id);

class DemoPurchaseRepository extends InMemoryDemoRepository<PurchaseInvoice>
    implements PurchaseRepository {
  factory DemoPurchaseRepository({
    Iterable<PurchaseInvoice>? initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
    required DemoPurchaseMutationEffects mutationEffects,
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
      mutationEffects: mutationEffects,
      partyLabelOf: partyLabelOf,
      itemLabelOf: itemLabelOf,
    );
  }

  DemoPurchaseRepository._({
    required List<PurchaseInvoice> initialValues,
    required PurchaseReferenceExists partyExists,
    required PurchaseReferenceExists itemExists,
    required PurchaseReferenceExists warehouseExists,
    required DemoPurchaseMutationEffects mutationEffects,
    PurchaseReferenceLabel? partyLabelOf,
    PurchaseReferenceLabel? itemLabelOf,
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

  final PurchaseReferenceExists _partyExists;
  final PurchaseReferenceExists _itemExists;
  final PurchaseReferenceExists _warehouseExists;
  final DemoPurchaseMutationEffects _mutationEffects;
  final PurchaseReferenceLabel? _partyLabelOf;
  final PurchaseReferenceLabel? _itemLabelOf;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;

  @override
  Future<PurchaseInvoice> save(PurchaseInvoice value) =>
      _applyInvoice(value, mode: _PurchaseMutationMode.upsert);

  @override
  Future<PurchaseInvoice> createInvoice(PurchaseInvoice invoice) =>
      _applyInvoice(invoice, mode: _PurchaseMutationMode.create);

  @override
  Future<PurchaseInvoice> replaceInvoice(PurchaseInvoice invoice) =>
      _applyInvoice(invoice, mode: _PurchaseMutationMode.replace);

  Future<PurchaseInvoice> _applyInvoice(
    PurchaseInvoice invoice, {
    required _PurchaseMutationMode mode,
  }) {
    return _mutationEffects.applyPurchase(
      candidate: invoice,
      preflightAndLoadPrevious: () async {
        final existing = getDemoValue(invoice.id);
        if (mode == _PurchaseMutationMode.create && existing != null) {
          throw StateError('معرف فاتورة الشراء مستخدم مسبقاً');
        }
        if (mode == _PurchaseMutationMode.replace && existing == null) {
          throw StateError('فاتورة الشراء غير موجودة');
        }
        if (existing == null &&
            invoice.isReturn &&
            invoice.documentNumber != _highestIssuedDocumentNumber + 1) {
          throw StateError('رقم مرتجع الشراء يجب أن يكون الرقم التالي الصادر');
        }
        if (existing != null && existing.isReturn != invoice.isReturn) {
          throw StateError(
            'لا يمكن تحويل قائمة شراء محفوظة إلى مرتجع '
            'أو العكس',
          );
        }
        if (existing != null &&
            existing.isReturn &&
            _hasLaterIssuedLinkedReturn(existing)) {
          throw StateError(
            'لا يمكن تعديل مرتجع شراء قبل المرتجع الأحدث '
            'للقائمة نفسها',
          );
        }
        if (existing != null &&
            existing.isReturn &&
            existing.originalPurchaseInvoiceId !=
                invoice.originalPurchaseInvoiceId) {
          throw StateError('لا يمكن تغيير قائمة الشراء الأصلية للمرتجع');
        }
        if (existing != null &&
            existing.isReturn &&
            existing.documentNumber != invoice.documentNumber) {
          throw StateError('لا يمكن تغيير رقم مرتجع شراء صادر');
        }
        await _validate(invoice, previous: existing);
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

  Future<void> _validate(
    PurchaseInvoice value, {
    required PurchaseInvoice? previous,
  }) async {
    if (value.lines.map((line) => line.id).toSet().length !=
        value.lines.length) {
      throw StateError('هوية سطر الشراء مكررة');
    }
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
    if (value.isReturn) {
      await _validateLinkedReturn(value);
    } else {
      if (value.originalPurchaseInvoiceId != null ||
          value.lines.any((line) => line.originalPurchaseLineId != null)) {
        throw StateError('قائمة الشراء العادية لا ترتبط بقائمة أصلية');
      }
    }
    if (previous != null &&
        !previous.isReturn &&
        !_hasSameReturnSourceTerms(previous, value) &&
        (await _linkedReturns(previous.id)).isNotEmpty) {
      throw StateError(
        'لا يمكن تغيير بيانات قائمة شراء مرتبطة بمرتجع؛ احذف المرتجع أولاً',
      );
    }
  }

  Future<void> _validateLinkedReturn(PurchaseInvoice value) async {
    final sourceId = value.originalPurchaseInvoiceId;
    if (sourceId == null || sourceId == value.id) {
      throw StateError('اختر قائمة الشراء الأصلية للمرتجع');
    }
    final source = getDemoValue(sourceId);
    if (source == null || source.isReturn) {
      throw StateError('قائمة الشراء الأصلية غير موجودة أو غير صالحة');
    }
    if (_purchaseTimestamp(value).isBefore(_purchaseTimestamp(source))) {
      throw StateError('لا يمكن أن يسبق المرتجع قائمة الشراء الأصلية');
    }
    if (value.supplierId != source.supplierId) {
      throw StateError('يجب أن يكون مجهز المرتجع هو مجهز القائمة الأصلية');
    }
    if (value.currency != source.currency ||
        value.exchangeRate != source.exchangeRate) {
      throw StateError('عملة وسعر صرف المرتجع يجب أن يطابقا القائمة الأصلية');
    }
    if (!value.expenses.isZero) {
      throw StateError('مصاريف قائمة الشراء لا تدخل في قيمة المرتجع');
    }
    if (value.defaultWarehouseId != value.lines.first.warehouseId) {
      throw StateError('مخزن المرتجع الافتراضي يجب أن يطابق أول سطر مرتجع');
    }

    final sourceLines = {
      for (final line in source.lines) line.id: line,
    };
    final otherReturns = await _linkedReturns(
      source.id,
      excludingId: value.id,
    );
    if (otherReturns.any(
      (other) => _purchaseTimestamp(value).isBefore(
        _purchaseTimestamp(other),
      ),
    )) {
      throw StateError(
        'لا يمكن أن يسبق المرتجع مرتجعاً أقدم من القائمة نفسها',
      );
    }
    final returnedQuantities = <EntityId, int>{};
    final returnedLineDiscounts = <EntityId, int>{};
    var returnedInvoiceDiscount = 0;
    for (final other in otherReturns) {
      returnedInvoiceDiscount += other.invoiceDiscount.minorUnits;
      for (final line in other.lines) {
        final originalLineId = line.originalPurchaseLineId;
        if (originalLineId == null || !sourceLines.containsKey(originalLineId)) {
          throw StateError('يوجد مرتجع سابق بارتباط غير صالح');
        }
        returnedQuantities[originalLineId] =
            (returnedQuantities[originalLineId] ?? 0) + line.quantity.value;
        returnedLineDiscounts[originalLineId] =
            (returnedLineDiscounts[originalLineId] ?? 0) +
                line.lineDiscount.minorUnits;
      }
    }

    final candidateSourceLines = <EntityId>{};
    for (final line in value.lines) {
      final originalLineId = line.originalPurchaseLineId;
      if (originalLineId == null || !candidateSourceLines.add(originalLineId)) {
        throw StateError('كل سطر مرتجع يجب أن يرتبط بسطر أصلي مختلف');
      }
      final sourceLine = sourceLines[originalLineId];
      if (sourceLine == null || line.itemId != sourceLine.itemId) {
        throw StateError('إحدى مواد المرتجع لا تطابق سطر القائمة الأصلية');
      }
      if (!line.containerQuantity.isZero) {
        throw StateError('كمية الحاوية لا تستخدم في سطر مرتجع الشراء');
      }
      if (line.purchasePrice != sourceLine.purchasePrice ||
          line.salePrice != sourceLine.salePrice) {
        throw StateError('أسعار المرتجع يجب أن تكون مشتقة من السطر الأصلي');
      }
      final previousQuantity = returnedQuantities[originalLineId] ?? 0;
      final combinedQuantity = previousQuantity + line.quantity.value;
      if (combinedQuantity > sourceLine.quantity.value) {
        throw StateError('كمية المرتجع تتجاوز الكمية المتبقية من السطر الأصلي');
      }
      final expectedDiscount = PurchaseReturnPolicy.lineDiscount(
        sourceLine: sourceLine,
        totalReturnedQuantity: combinedQuantity,
        discountAlreadyReturned: Money.fromMinorUnits(
          returnedLineDiscounts[originalLineId] ?? 0,
          source.currency,
        ),
      );
      if (line.lineDiscount != expectedDiscount) {
        throw StateError('خصم سطر المرتجع لا يطابق حصته من السطر الأصلي');
      }
      returnedQuantities[originalLineId] = combinedQuantity;
    }

    final expectedInvoiceDiscount = PurchaseReturnPolicy.invoiceDiscount(
      source: source,
      totalReturnedQuantities: returnedQuantities,
      discountAlreadyReturned: Money.fromMinorUnits(
        returnedInvoiceDiscount,
        source.currency,
      ),
    );
    if (value.invoiceDiscount != expectedInvoiceDiscount) {
      throw StateError(
        'خصم المرتجع لا يطابق حصته من خصم القائمة الأصلية',
      );
    }
  }

  Future<List<PurchaseInvoice>> _linkedReturns(
    EntityId sourceId, {
    EntityId? excludingId,
  }) async {
    return (await getAll())
        .where(
          (invoice) =>
              invoice.id != excludingId &&
              invoice.isReturn &&
              invoice.originalPurchaseInvoiceId == sourceId,
        )
        .toList(growable: false);
  }

  bool _hasLaterIssuedLinkedReturn(PurchaseInvoice value) {
    final sourceId = value.originalPurchaseInvoiceId;
    if (!value.isReturn || sourceId == null) return false;
    return createDemoSnapshot().values.any(
      (candidate) =>
          candidate.id != value.id &&
          candidate.isReturn &&
          candidate.originalPurchaseInvoiceId == sourceId &&
          candidate.documentNumber > value.documentNumber,
    );
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

  void _reserveDocumentNumber(int documentNumber) {
    _issuedDocumentNumbers.add(documentNumber);
    if (documentNumber > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = documentNumber;
    }
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final existing = getDemoValue(id);
    if (existing == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (!existing.isReturn && (await _linkedReturns(id)).isNotEmpty) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف قائمة شراء مرتبطة بمرتجع؛ احذف المرتجع أولاً',
      );
    }
    if (existing.isReturn && _hasLaterIssuedLinkedReturn(existing)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف مرتجع شراء قبل المرتجع الأحدث '
        'للقائمة نفسها',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) => deleteInvoicePermanently(id);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) {
    return _mutationEffects.deletePurchase(
      id: id,
      preflightAndLoadPrevious: () async {
        final existing = getDemoValue(id);
        if (existing == null) {
          throw StateError('فاتورة الشراء غير موجودة');
        }
        if (!existing.isReturn && (await _linkedReturns(id)).isNotEmpty) {
          throw StateError(
            'لا يمكن حذف قائمة شراء مرتبطة بمرتجع؛ احذف المرتجع أولاً',
          );
        }
        if (existing.isReturn && _hasLaterIssuedLinkedReturn(existing)) {
          throw StateError(
            'لا يمكن حذف مرتجع شراء قبل المرتجع الأحدث '
            'للقائمة نفسها',
          );
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
        invoice.originalPurchaseInvoiceId == null
            ? null
            : getDemoValue(invoice.originalPurchaseInvoiceId!)?.documentNumber,
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

DateTime _purchaseTimestamp(PurchaseInvoice invoice) => invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
      minute: invoice.minuteOfDay % Duration.minutesPerHour,
    );

bool _hasSameReturnSourceTerms(
  PurchaseInvoice first,
  PurchaseInvoice second,
) {
  if (first.id != second.id ||
      first.documentNumber != second.documentNumber ||
      first.date != second.date ||
      first.minuteOfDay != second.minuteOfDay ||
      first.supplierId != second.supplierId ||
      first.defaultWarehouseId != second.defaultWarehouseId ||
      first.currency != second.currency ||
      first.exchangeRate != second.exchangeRate ||
      first.purchaseKind != second.purchaseKind ||
      first.settlementKind != second.settlementKind ||
      first.expenses != second.expenses ||
      first.invoiceDiscount != second.invoiceDiscount ||
      first.paid != second.paid ||
      first.lines.length != second.lines.length) {
    return false;
  }
  final secondLines = {for (final line in second.lines) line.id: line};
  for (final firstLine in first.lines) {
    final secondLine = secondLines[firstLine.id];
    if (secondLine == null ||
        firstLine.itemId != secondLine.itemId ||
        firstLine.warehouseId != secondLine.warehouseId ||
        firstLine.quantity != secondLine.quantity ||
        firstLine.containerQuantity != secondLine.containerQuantity ||
        firstLine.purchasePrice != secondLine.purchasePrice ||
        firstLine.lineDiscount != secondLine.lineDiscount ||
        firstLine.salePrice != secondLine.salePrice) {
      return false;
    }
  }
  return true;
}

enum _PurchaseMutationMode { create, replace, upsert }

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
      searchDetailsSnapshot: '25/07/2026 • 3 مواد • محلي',
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
        _purchaseLine(1013, 'item-006', 'warehouse-001', 5, 0, 20000, 10000,
            27000, 'P3001', 'حافظة مستندات', 'الرئيسي', AppCurrency.iqd),
      ],
      expenses: Money.fromMajor(5000, AppCurrency.iqd),
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      paid: Money.zero(AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(540000, AppCurrency.iqd),
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
      supplierId: EntityId('party-011'),
      supplierNameSnapshot: 'شركة الرافدين للتجهيز',
      searchDetailsSnapshot: '27/07/2026 • مادة واحدة • مرتجع نقدي',
      defaultWarehouseId: EntityId('warehouse-001'),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.returnPurchase,
      settlementKind: PurchaseSettlementKind.cash,
      originalPurchaseInvoiceId: EntityId('purchase-invoice-101'),
      lines: [
        _purchaseLine(
          1031,
          'item-006',
          'warehouse-001',
          5,
          0,
          20000,
          10000,
          27000,
          'P3001',
          'حافظة مستندات',
          'الرئيسي',
          AppCurrency.iqd,
          originalPurchaseLineId: 'purchase-line-1013',
        ),
      ],
      expenses: Money.zero(AppCurrency.iqd),
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      paid: Money.fromMajor(90000, AppCurrency.iqd),
      balanceAfterInvoice: Money.fromMajor(540000, AppCurrency.iqd),
      notes: 'مرتجع مرتبط بقائمة الشراء رقم 101',
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
  AppCurrency currency, {
  String? originalPurchaseLineId,
}) =>
    PurchaseInvoiceLine(
      id: EntityId('purchase-line-$sequence'),
      itemId: EntityId(itemId),
      warehouseId: EntityId(warehouseId),
      quantity: WholeQuantity(quantity),
      containerQuantity: WholeQuantity(container),
      purchasePrice: Money.fromMajor(purchasePrice, currency),
      lineDiscount: Money.fromMajor(lineDiscount, currency),
      salePrice: Money.fromMajor(salePrice, currency),
      originalPurchaseLineId: originalPurchaseLineId == null
          ? null
          : EntityId(originalPurchaseLineId),
      itemCodeSnapshot: code,
      itemNameSnapshot: name,
      warehouseNameSnapshot: warehouseName,
    );
