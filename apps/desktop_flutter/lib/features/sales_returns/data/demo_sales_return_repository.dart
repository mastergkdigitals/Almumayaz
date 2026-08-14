import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/domain/invoice_value_allocator.dart';
import '../../sales/domain/sales_invoice.dart';
import '../domain/sales_return.dart';
import '../domain/sales_return_repository.dart';
import 'demo_sales_return_mutation_effects.dart';

typedef SalesInvoiceLoader = Future<SalesInvoice?> Function(EntityId id);

class DemoSalesReturnRepository extends InMemoryDemoRepository<SalesReturn>
    implements SalesReturnRepository {
  factory DemoSalesReturnRepository({
    Iterable<SalesReturn>? initialValues,
    required SalesInvoiceLoader salesInvoiceLoader,
    required DemoSalesReturnMutationEffects mutationEffects,
    DateTime Function()? clock,
  }) {
    final values = List<SalesReturn>.of(initialValues ?? demoSalesReturns());
    _validateInitialValues(values);
    return DemoSalesReturnRepository._(
      initialValues: values,
      salesInvoiceLoader: salesInvoiceLoader,
      mutationEffects: mutationEffects,
      clock: clock ?? DateTime.now,
    );
  }

  DemoSalesReturnRepository._({
    required List<SalesReturn> initialValues,
    required SalesInvoiceLoader salesInvoiceLoader,
    required DemoSalesReturnMutationEffects mutationEffects,
    required DateTime Function() clock,
  })  : _salesInvoiceLoader = salesInvoiceLoader,
        _mutationEffects = mutationEffects,
        _clock = clock,
        _highestIssuedDocumentNumber = _highestNumber(initialValues),
        _issuedDocumentNumbers = {
          for (final value in initialValues) value.documentNumber,
        },
        super(initialValues: initialValues, idOf: (value) => value.id);

  final SalesInvoiceLoader _salesInvoiceLoader;
  final DemoSalesReturnMutationEffects _mutationEffects;
  final DateTime Function() _clock;
  int _highestIssuedDocumentNumber;
  final Set<int> _issuedDocumentNumbers;
  int _generatedIdNonce = 0;

  @override
  Future<List<SalesReturn>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where((value) {
        final text = [
          value.documentNumber,
          value.originalSalesInvoiceNumberSnapshot,
          value.date,
          value.customerNameSnapshot,
          value.currency.code,
          value.notes,
          value.searchDetailsSnapshot,
          for (final line in value.lines) ...[
            line.itemCodeSnapshot,
            line.itemNameSnapshot,
            line.warehouseNameSnapshot,
          ],
        ].join(' ').toLowerCase();
        return text.contains(normalized);
      }),
    );
  }

  @override
  Future<int> nextDocumentNumber() async =>
      _highestIssuedDocumentNumber + 1;

  @override
  Future<SalesReturnableSource> loadReturnableSource(
    EntityId originalSalesInvoiceId, {
    EntityId? excludingReturnId,
  }) async {
    final invoice = await _salesInvoiceLoader(originalSalesInvoiceId);
    if (invoice == null) {
      throw StateError('قائمة البيع الأصلية غير موجودة');
    }
    final sourceAmounts = _sourceLineAllocations(invoice);
    final returnedQuantities = <EntityId, int>{};
    final returnedAmounts = <EntityId, int>{};
    for (final value in createDemoSnapshot().values) {
      if (value.id == excludingReturnId ||
          value.originalSalesInvoiceId != originalSalesInvoiceId) {
        continue;
      }
      for (final line in value.lines) {
        returnedQuantities.update(
          line.sourceSalesLineId,
          (quantity) => quantity + line.quantity.value,
          ifAbsent: () => line.quantity.value,
        );
        returnedAmounts.update(
          line.sourceSalesLineId,
          (amount) => amount + line.allocatedRefund.minorUnits,
          ifAbsent: () => line.allocatedRefund.minorUnits,
        );
      }
    }

    final result = <SalesReturnableLine>[];
    for (final line in invoice.lines) {
      final returned = returnedQuantities[line.id] ?? 0;
      if (returned < 0 || returned > line.quantity.value) {
        throw StateError('كميات مرتجعات البيع المحفوظة غير متطابقة');
      }
      final allocated = sourceAmounts[line.id]!;
      final consumedAmount = returnedAmounts[line.id] ?? 0;
      if (consumedAmount < 0 || consumedAmount > allocated.minorUnits) {
        throw StateError('قيم مرتجعات البيع المحفوظة غير متطابقة');
      }
      result.add(
        SalesReturnableLine(
          source: line,
          previouslyReturned: WholeQuantity(returned),
          available: WholeQuantity(line.quantity.value - returned),
          sourceAllocatedRefund: allocated,
          availableRefund: Money.fromMinorUnits(
            allocated.minorUnits - consumedAmount,
            invoice.currency,
          ),
        ),
      );
    }
    return SalesReturnableSource(invoice: invoice, lines: result);
  }

  @override
  Future<SalesReturn> createReturn(SalesReturnSaveRequest request) {
    return _mutationEffects.applySalesReturn(
      preflightAndBuildMutation: () async {
        final documentNumber = _highestIssuedDocumentNumber + 1;
        if (_issuedDocumentNumbers.contains(documentNumber)) {
          throw StateError('رقم مرتجع البيع مستخدم مسبقاً');
        }
        final id = _nextEntityId(documentNumber);
        if (getDemoValue(id) != null) {
          throw StateError('معرف مرتجع البيع مستخدم مسبقاً');
        }
        final candidate = await _normalize(
          id: id,
          documentNumber: documentNumber,
          request: request,
        );
        return DemoSalesReturnMutation(
          previous: null,
          candidate: candidate,
        );
      },
      commit: (normalized) {
        final staged = createDemoSnapshot()..[normalized.id] = normalized;
        commitDemoSnapshot(staged);
        _reserveNumber(normalized.documentNumber);
      },
    );
  }

  @override
  Future<SalesReturn> replaceReturn(
    EntityId id,
    SalesReturnSaveRequest request,
  ) {
    return _mutationEffects.applySalesReturn(
      preflightAndBuildMutation: () async {
        final previous = getDemoValue(id);
        if (previous == null) throw StateError('مرتجع البيع غير موجود');
        if (_hasLaterIssuedReturn(previous)) {
          throw StateError(
            'لا يمكن تعديل مرتجع بيع قبل المرتجع الأحدث '
            'للقائمة نفسها',
          );
        }
        if (request.originalSalesInvoiceId !=
            previous.originalSalesInvoiceId) {
          throw StateError('لا يمكن تغيير قائمة البيع الأصلية للمرتجع');
        }
        final candidate = await _normalize(
          id: previous.id,
          documentNumber: previous.documentNumber,
          request: request,
          previous: previous,
        );
        return DemoSalesReturnMutation(
          previous: previous,
          candidate: candidate,
        );
      },
      commit: (normalized) {
        final staged = createDemoSnapshot()..[normalized.id] = normalized;
        commitDemoSnapshot(staged);
      },
    );
  }

  @override
  Future<SalesReturn> save(SalesReturn value) {
    if (getDemoValue(value.id) == null) {
      throw StateError('استخدم عملية إنشاء مرتجع البيع');
    }
    return replaceReturn(
      value.id,
      SalesReturnSaveRequest(
        originalSalesInvoiceId: value.originalSalesInvoiceId,
        date: value.date,
        minuteOfDay: value.minuteOfDay,
        lines: [
          for (final line in value.lines)
            SalesReturnLineRequest(
              sourceSalesLineId: line.sourceSalesLineId,
              quantity: line.quantity,
            ),
        ],
        refundedAtReturn: value.refundedAtReturn,
        notes: value.notes,
      ),
    );
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final existing = getDemoValue(id);
    if (existing == null) {
      return const DeleteDecision.blocked('مرتجع البيع غير موجود');
    }
    if (_hasLaterIssuedReturn(existing)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف مرتجع بيع قبل المرتجع الأحدث '
        'للقائمة نفسها',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) => deleteReturnPermanently(id);

  @override
  Future<void> deleteReturnPermanently(EntityId id) {
    return _mutationEffects.deleteSalesReturn(
      preflightAndLoadPrevious: () async {
        final previous = getDemoValue(id);
        if (previous == null) throw StateError('مرتجع البيع غير موجود');
        if (_hasLaterIssuedReturn(previous)) {
          throw StateError(
            'لا يمكن حذف مرتجع بيع قبل المرتجع الأحدث '
            'للقائمة نفسها',
          );
        }
        return previous;
      },
      commit: () {
        final staged = createDemoSnapshot()..remove(id);
        commitDemoSnapshot(staged);
      },
    );
  }

  @override
  Future<bool> hasReturnsForInvoice(EntityId originalSalesInvoiceId) async {
    return createDemoSnapshot().values.any(
      (value) => value.originalSalesInvoiceId == originalSalesInvoiceId,
    );
  }

  /// Synchronous transaction-owned view used by the shared effects
  /// coordinator when it restates an installment plan.
  List<SalesReturn> getDemoReturnsForInvoice(
    EntityId originalSalesInvoiceId, {
    EntityId? excludingReturnId,
  }) {
    return List.unmodifiable(
      createDemoSnapshot().values.where(
        (value) =>
            value.id != excludingReturnId &&
            value.originalSalesInvoiceId == originalSalesInvoiceId,
      ),
    );
  }

  bool _hasLaterIssuedReturn(SalesReturn value) {
    return createDemoSnapshot().values.any(
      (candidate) =>
          candidate.id != value.id &&
          candidate.originalSalesInvoiceId == value.originalSalesInvoiceId &&
          candidate.documentNumber > value.documentNumber,
    );
  }

  Future<SalesReturn> _normalize({
    required EntityId id,
    required int documentNumber,
    required SalesReturnSaveRequest request,
    SalesReturn? previous,
  }) async {
    final source = await loadReturnableSource(
      request.originalSalesInvoiceId,
      excludingReturnId: previous?.id,
    );
    final invoice = source.invoice;
    if (request.refundedAtReturn.currency != invoice.currency) {
      throw StateError('عملة المبلغ المسترد لا تطابق قائمة البيع الأصلية');
    }
    final sourceTimestamp = invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
      minute: invoice.minuteOfDay % Duration.minutesPerHour,
    );
    final returnTimestamp = request.date.atTime(
      hour: request.minuteOfDay ~/ Duration.minutesPerHour,
      minute: request.minuteOfDay % Duration.minutesPerHour,
    );
    if (returnTimestamp.isBefore(sourceTimestamp)) {
      throw StateError('لا يمكن أن يسبق مرتجع البيع القائمة الأصلية');
    }
    if (getDemoReturnsForInvoice(
      invoice.id,
      excludingReturnId: previous?.id,
    ).any((other) => returnTimestamp.isBefore(_returnTimestamp(other)))) {
      throw StateError(
        'لا يمكن أن يسبق مرتجع البيع مرتجعاً أقدم '
        'من القائمة نفسها',
      );
    }

    final requestedQuantities = <EntityId, int>{};
    for (final line in request.lines) {
      requestedQuantities.update(
        line.sourceSalesLineId,
        (quantity) => quantity + line.quantity.value,
        ifAbsent: () => line.quantity.value,
      );
    }
    final returnableById = {
      for (final line in source.lines) line.source.id: line,
    };
    final previousLinesBySource = {
      for (final line in previous?.lines ?? const <SalesReturnLine>[])
        line.sourceSalesLineId: line,
    };
    final lines = <SalesReturnLine>[];
    for (final entry in requestedQuantities.entries) {
      final returnable = returnableById[entry.key];
      if (returnable == null) {
        throw StateError('أحد سطور قائمة البيع الأصلية غير موجود');
      }
      final quantity = entry.value;
      if (quantity < 1 || quantity > returnable.available.value) {
        throw StateError('كمية مرتجع البيع تتجاوز الكمية المتاحة');
      }
      final allocatedRefund = returnable.allocatedRefundFor(
        WholeQuantity(quantity),
      );
      final sourceLine = returnable.source;
      lines.add(
        SalesReturnLine(
          id: previousLinesBySource[sourceLine.id]?.id ??
              EntityId('${id.value}-line-${sourceLine.id.value}'),
          sourceSalesLineId: sourceLine.id,
          itemId: sourceLine.itemId,
          warehouseId: sourceLine.warehouseId,
          quantity: WholeQuantity(quantity),
          sourceNetUnitPrice: sourceLine.netUnitPrice,
          allocatedRefund: allocatedRefund,
          itemCodeSnapshot: sourceLine.itemCodeSnapshot,
          itemNameSnapshot: sourceLine.itemNameSnapshot,
          warehouseNameSnapshot: sourceLine.warehouseNameSnapshot,
        ),
      );
    }
    lines.sort(
      (first, second) => first.sourceSalesLineId.value.compareTo(
        second.sourceSalesLineId.value,
      ),
    );

    final total = lines.fold(
      Money.zero(invoice.currency),
      (sum, line) => sum + line.allocatedRefund,
    );
    if (request.refundedAtReturn.compareTo(total) > 0) {
      throw StateError('المبلغ المسترد يتجاوز قيمة مرتجع البيع');
    }
    var otherRefunds = Money.zero(invoice.currency);
    for (final value in getDemoReturnsForInvoice(
      invoice.id,
      excludingReturnId: previous?.id,
    )) {
      otherRefunds = otherRefunds + value.refundedAtReturn;
    }
    if ((otherRefunds + request.refundedAtReturn)
        .compareTo(invoice.received) > 0) {
      throw StateError('إجمالي المبالغ المستردة يتجاوز المقبوض من القائمة');
    }

    final customerName = invoice.customerNameSnapshot;
    final details = '${request.date} • قائمة أصلية '
        '${invoice.documentNumber} • ${lines.length} مواد';
    return SalesReturn(
      id: id,
      documentNumber: documentNumber,
      date: request.date,
      minuteOfDay: request.minuteOfDay,
      originalSalesInvoiceId: invoice.id,
      originalSalesInvoiceNumberSnapshot: invoice.documentNumber,
      customerId: invoice.customerId,
      customerNameSnapshot: customerName,
      currency: invoice.currency,
      exchangeRate: invoice.exchangeRate,
      lines: lines,
      refundedAtReturn: request.refundedAtReturn,
      searchDetailsSnapshot: details,
      notes: request.notes,
    );
  }

  EntityId _nextEntityId(int documentNumber) {
    _generatedIdNonce++;
    return EntityId(
      'sales-return-$documentNumber-'
      '${_clock().microsecondsSinceEpoch}-$_generatedIdNonce',
    );
  }

  void _reserveNumber(int number) {
    _issuedDocumentNumbers.add(number);
    if (number > _highestIssuedDocumentNumber) {
      _highestIssuedDocumentNumber = number;
    }
  }
}

Map<EntityId, Money> _sourceLineAllocations(SalesInvoice invoice) {
  final allocations = allocateInvoiceTotalMinorUnits(
    totalMinorUnits: invoice.total.minorUnits,
    netLineMinorUnits: [
      for (final line in invoice.lines) line.total.minorUnits,
    ],
    grossLineMinorUnits: [
      for (final line in invoice.lines) line.total.minorUnits,
    ],
    quantities: [for (final line in invoice.lines) line.quantity.value],
  );
  return {
    for (var index = 0; index < invoice.lines.length; index++)
      invoice.lines[index].id:
          Money.fromMinorUnits(allocations[index], invoice.currency),
  };
}

void _validateInitialValues(List<SalesReturn> values) {
  if ({for (final value in values) value.id}.length != values.length) {
    throw ArgumentError('Sales-return IDs must be unique');
  }
  if ({for (final value in values) value.documentNumber}.length !=
      values.length) {
    throw ArgumentError('Sales-return document numbers must be unique');
  }
}

int _highestNumber(Iterable<SalesReturn> values) {
  var highest = 0;
  for (final value in values) {
    if (value.documentNumber > highest) highest = value.documentNumber;
  }
  return highest;
}

DateTime _returnTimestamp(SalesReturn value) => value.date.atTime(
      hour: value.minuteOfDay ~/ Duration.minutesPerHour,
      minute: value.minuteOfDay % Duration.minutesPerHour,
    );

List<SalesReturn> demoSalesReturns() => const [];
