import 'package:flutter/material.dart';

import '../../../core/application/invoice_editor_coordinator.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../parties/domain/party_repository.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../sales/domain/sales_repository.dart';
import '../domain/sales_return.dart';
import '../domain/sales_return_repository.dart';
import 'widgets/sales_return_lines_table.dart';

class SalesReturnEditorController extends ChangeNotifier {
  SalesReturnEditorController({
    required SalesReturnRepository returns,
    required SalesRepository sales,
    required PartyRepository parties,
  })  : _returns = returns,
        _sales = sales,
        _parties = parties,
        selection = InvoiceEditorSelection<SalesReturn>(
          idOf: (value) => value.id,
        ) {
    for (final controller in _fixedEditableControllers) {
      controller.addListener(_handleFixedValueChanged);
    }
  }

  final SalesReturnRepository _returns;
  final SalesRepository _sales;
  final PartyRepository _parties;
  final InvoiceEditorSelection<SalesReturn> selection;

  final documentNumberController = TextEditingController(text: '1');
  final sourceInvoiceController = TextEditingController();
  final customerController = TextEditingController();
  final currencyController = TextEditingController();
  final exchangeRateController = TextEditingController();
  final refundController = TextEditingController(text: '0');
  final totalController = TextEditingController(text: '0');
  final creditedController = TextEditingController(text: '0');
  final balanceController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  AppDataState<List<SalesReturn>> state = const AppDataState.loading();
  List<SalesReturn> records = const [];
  List<SalesInvoice> sourceInvoices = const [];
  SalesReturnableSource? source;
  List<SalesReturnLineEditor> lines = const [];
  SalesReturn? selected;
  DateTime documentDateTime = DateTime.now();
  bool isBusy = false;
  bool hasChanges = false;
  int _nextDocumentNumber = 1;
  Money? _balanceBeforeCandidate;
  String _baseline = '';
  bool _applying = false;
  int _loadGeneration = 0;

  List<TextEditingController> get _fixedEditableControllers => [
        sourceInvoiceController,
        refundController,
        notesController,
      ];

  AppCurrency get currency => source?.invoice.currency ?? AppCurrency.iqd;

  Money get previewTotal => lines.fold(
        Money.zero(currency),
        (sum, line) => sum + line.previewRefund,
      );

  String sourceLabel(SalesInvoice invoice) {
    final name = invoice.customerNameSnapshot.trim().isEmpty
        ? 'زبون رقم ${invoice.customerId.value}'
        : invoice.customerNameSnapshot.trim();
    return 'قائمة ${invoice.documentNumber} - $name';
  }

  Future<void> initialize() => reload(showLoading: true);

  Future<void> reload({
    bool showLoading = true,
    EntityId? selectId,
  }) async {
    final generation = ++_loadGeneration;
    if (showLoading) {
      state = const AppDataState.loading();
      notifyListeners();
    }
    try {
      final values = await Future.wait<Object>([
        _returns.getAll(),
        _sales.getAll(),
        _returns.nextDocumentNumber(),
      ]);
      if (generation != _loadGeneration) return;
      final loadedReturns = [...values[0] as List<SalesReturn>]
        ..sort(
          (left, right) =>
              left.documentNumber.compareTo(right.documentNumber),
        );
      final loadedSales = [...values[1] as List<SalesInvoice>]
        ..sort(
          (left, right) =>
              right.documentNumber.compareTo(left.documentNumber),
        );
      final salesIds = {for (final invoice in loadedSales) invoice.id};
      if (loadedReturns.any(
        (value) => !salesIds.contains(value.originalSalesInvoiceId),
      )) {
        throw const InvoiceMissingReferenceException(
          'أحد مرتجعات البيع مرتبط بقائمة أصلية غير موجودة.',
        );
      }
      records = List.unmodifiable(loadedReturns);
      sourceInvoices = List.unmodifiable(loadedSales);
      _nextDocumentNumber = values[2] as int;
      selection.replaceAll(records);
      if (records.isEmpty) {
        state = const AppDataState.empty(
          message: 'لا توجد مرتجعات بيع محفوظة حتى الآن.',
        );
        _setNewForm(notify: false);
      } else {
        state = AppDataState.ready(records);
        final target = selection.select(
          selectId ?? selected?.id,
          fallbackToFirst: true,
        );
        if (target != null) await _loadRecord(target, notify: false);
      }
    } on InvoiceMissingReferenceException catch (error) {
      if (generation != _loadGeneration) return;
      state = AppDataState.missingReference(error.message);
    } catch (error) {
      if (generation != _loadGeneration) return;
      state = AppDataState.error(
        error,
        message: 'تعذر تحميل مرتجعات البيع. حاول مرة أخرى.',
      );
    }
    if (generation == _loadGeneration) notifyListeners();
  }

  void openEmptyEditor() {
    state = AppDataState.ready(records);
    _setNewForm(notify: true);
  }

  Future<void> selectSourceInvoice(SalesInvoice invoice) async {
    if (isBusy) return;
    await _withBusy(() async {
      await _loadSource(
        invoice,
        editing: selected,
        initialQuantities: const {},
        resetRefund: true,
      );
      _refreshChangeState();
    });
  }

  void handleSourceTextChanged(String value) {
    if (_applying) return;
    final invoice = source?.invoice;
    if (invoice != null && value.trim() == sourceLabel(invoice)) return;
    _disposeLines();
    source = null;
    _balanceBeforeCandidate = null;
    _applying = true;
    customerController.clear();
    currencyController.clear();
    exchangeRateController.clear();
    refundController.text = '0';
    totalController.text = '0';
    creditedController.text = '0';
    balanceController.text = '0';
    _applying = false;
    _refreshChangeState();
  }

  void changeDate(DateTime value) {
    documentDateTime = DateTime(
      value.year,
      value.month,
      value.day,
      documentDateTime.hour,
      documentDateTime.minute,
    );
    _refreshChangeState();
  }

  void changeTime(TimeOfDay value) {
    documentDateTime = DateTime(
      documentDateTime.year,
      documentDateTime.month,
      documentDateTime.day,
      value.hour,
      value.minute,
    );
    _refreshChangeState();
  }

  void handleLineChanged() {
    _syncCalculatedValues();
    _refreshChangeState();
  }

  String? validate() {
    final selectedSource = source;
    if (selectedSource == null ||
        sourceInvoiceController.text.trim() !=
            sourceLabel(selectedSource.invoice)) {
      return 'اختر قائمة البيع الأصلية من القائمة';
    }
    final chosen = lines.where((line) => line.requestedQuantity > 0).toList();
    if (chosen.isEmpty) return 'أدخل كمية مرتجع لمادة واحدة على الأقل';
    if (chosen.any(
      (line) => line.requestedQuantity > line.returnable.available.value,
    )) {
      return 'إحدى كميات المرتجع تتجاوز الكمية المتاحة';
    }
    Money refund;
    try {
      refund = Money.parse(refundController.text, currency);
    } on Object {
      return 'تحقق من المبلغ المسترد';
    }
    if (refund.isNegative || refund.compareTo(previewTotal) > 0) {
      return 'المبلغ المسترد يجب ألا يتجاوز قيمة المرتجع';
    }
    return null;
  }

  SalesReturnSaveRequest buildRequest() {
    final selectedSource = source;
    if (selectedSource == null) throw StateError('قائمة البيع الأصلية مطلوبة');
    return SalesReturnSaveRequest(
      originalSalesInvoiceId: selectedSource.invoice.id,
      date: BusinessDate.fromDateTime(documentDateTime),
      minuteOfDay: documentDateTime.hour * Duration.minutesPerHour +
          documentDateTime.minute,
      lines: [
        for (final line in lines)
          if (line.requestedQuantity > 0)
            SalesReturnLineRequest(
              sourceSalesLineId: line.returnable.source.id,
              quantity: WholeQuantity(line.requestedQuantity),
            ),
      ],
      refundedAtReturn: Money.parse(refundController.text, currency),
      notes: notesController.text,
    );
  }

  Future<SalesReturn> create() async {
    return _withBusy(() async {
      final saved = await _returns.createReturn(buildRequest());
      await reload(showLoading: false, selectId: saved.id);
      return saved;
    });
  }

  Future<SalesReturn> replace() async {
    final current = selected;
    if (current == null) throw StateError('اختر مرتجع بيع لتحديثه');
    return _withBusy(() async {
      final saved = await _returns.replaceReturn(current.id, buildRequest());
      await reload(showLoading: false, selectId: saved.id);
      return saved;
    });
  }

  Future<void> deleteSelected() async {
    final current = selected;
    if (current == null) throw StateError('اختر مرتجع بيع لحذفه');
    await _withBusy(() async {
      await _returns.deleteReturnPermanently(current.id);
      selected = null;
      await reload(showLoading: false);
      if (records.isEmpty) openEmptyEditor();
    });
  }

  Future<void> selectRecord(EntityId id) async {
    final record = selection.select(id);
    if (record == null) throw StateError('مرتجع البيع المحدد غير موجود');
    await _withBusy(() => _loadRecord(record));
  }

  Future<void> navigate(InvoiceEditorNavigation destination) async {
    final record = selection.navigate(destination);
    if (record == null) {
      _setNewForm(notify: true);
      return;
    }
    await _withBusy(() => _loadRecord(record));
  }

  Future<void> undo() async {
    final current = selected;
    if (current == null) {
      _setNewForm(notify: true);
    } else {
      await _withBusy(() => _loadRecord(current));
    }
  }

  Future<T> _withBusy<T>(Future<T> Function() operation) async {
    if (isBusy) throw StateError('هناك عملية أخرى قيد التنفيذ');
    isBusy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecord(
    SalesReturn value, {
    bool notify = true,
  }) async {
    final invoice = sourceInvoices.firstWhere(
      (candidate) => candidate.id == value.originalSalesInvoiceId,
      orElse: () => throw const InvoiceMissingReferenceException(
        'قائمة البيع الأصلية المرتبطة بالمرتجع غير موجودة.',
      ),
    );
    selected = value;
    selection.select(value.id);
    documentDateTime = value.date.atTime(
      hour: value.minuteOfDay ~/ Duration.minutesPerHour,
      minute: value.minuteOfDay % Duration.minutesPerHour,
    );
    documentNumberController.text = '${value.documentNumber}';
    notesController.text = value.notes;
    refundController.text = _plainMoney(value.refundedAtReturn);
    await _loadSource(
      invoice,
      editing: value,
      initialQuantities: {
        for (final line in value.lines)
          line.sourceSalesLineId: line.quantity.value,
      },
    );
    _acceptCurrentState();
    if (notify) notifyListeners();
  }

  Future<void> _loadSource(
    SalesInvoice invoice, {
    required SalesReturn? editing,
    required Map<EntityId, int> initialQuantities,
    bool resetRefund = false,
  }) async {
    final returnable = await _returns.loadReturnableSource(
      invoice.id,
      excludingReturnId: editing?.id,
    );
    final party = await _parties.getById(invoice.customerId);
    if (party == null) {
      throw const InvoiceMissingReferenceException(
        'الزبون المرتبط بقائمة البيع الأصلية غير موجود.',
      );
    }
    final currentBalance = invoice.currency == AppCurrency.iqd
        ? party.iqdBalance
        : party.usdBalance;
    final reversingCurrent = editing != null &&
        editing.customerId == invoice.customerId &&
        editing.currency == invoice.currency;
    _balanceBeforeCandidate = reversingCurrent
        ? currentBalance + editing.creditedToCustomer
        : currentBalance;
    _disposeLines();
    lines = [
      for (final line in returnable.lines)
        SalesReturnLineEditor(
          returnable: line,
          initialQuantity: initialQuantities[line.source.id] ?? 0,
        ),
    ];
    source = returnable;
    _applying = true;
    sourceInvoiceController.text = sourceLabel(invoice);
    customerController.text = invoice.customerNameSnapshot;
    currencyController.text = invoice.currency.arabicName;
    exchangeRateController.text = invoice.exchangeRate.toPlainString();
    if (resetRefund) refundController.text = '0';
    _applying = false;
    _syncCalculatedValues();
  }

  void _setNewForm({required bool notify}) {
    _applying = true;
    selected = null;
    selection.clear();
    documentNumberController.text = '$_nextDocumentNumber';
    documentDateTime = DateTime.now();
    sourceInvoiceController.clear();
    customerController.clear();
    currencyController.clear();
    exchangeRateController.clear();
    refundController.text = '0';
    totalController.text = '0';
    creditedController.text = '0';
    balanceController.text = '0';
    notesController.clear();
    _disposeLines();
    source = null;
    _balanceBeforeCandidate = null;
    _applying = false;
    _acceptCurrentState();
    if (notify) notifyListeners();
  }

  void _syncCalculatedValues() {
    final total = previewTotal;
    Money refund;
    try {
      refund = Money.parse(refundController.text, currency);
    } on Object {
      refund = Money.zero(currency);
    }
    final validRefund = !refund.isNegative && refund.compareTo(total) <= 0;
    final credited = validRefund ? total - refund : Money.zero(currency);
    final balance = _balanceBeforeCandidate == null
        ? null
        : _balanceBeforeCandidate! - credited;
    _applying = true;
    totalController.text = _plainMoney(total);
    creditedController.text = _plainMoney(credited);
    balanceController.text = balance == null ? '0' : _plainMoney(balance);
    _applying = false;
  }

  void _handleFixedValueChanged() {
    if (_applying) return;
    _syncCalculatedValues();
    _refreshChangeState();
  }

  void _refreshChangeState() {
    if (_applying) return;
    final changed = _snapshot() != _baseline;
    if (changed != hasChanges) hasChanges = changed;
    notifyListeners();
  }

  void _acceptCurrentState() {
    _baseline = _snapshot();
    hasChanges = false;
  }

  String _snapshot() => [
        documentDateTime.toIso8601String(),
        sourceInvoiceController.text,
        refundController.text,
        notesController.text,
        for (final line in lines)
          '${line.returnable.source.id.value}:${line.quantityController.text}',
      ].join('\u001f');

  String _plainMoney(Money value) => value.toPlainString();

  void _disposeLines() {
    for (final line in lines) {
      line.dispose();
    }
    lines = const [];
  }

  @override
  void dispose() {
    _loadGeneration++;
    for (final controller in _fixedEditableControllers) {
      controller.removeListener(_handleFixedValueChanged);
    }
    documentNumberController.dispose();
    sourceInvoiceController.dispose();
    customerController.dispose();
    currencyController.dispose();
    exchangeRateController.dispose();
    refundController.dispose();
    totalController.dispose();
    creditedController.dispose();
    balanceController.dispose();
    notesController.dispose();
    _disposeLines();
    super.dispose();
  }
}
