import 'dart:async';

import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/features/expenses/data/demo_expense_mutation_effects.dart';
import 'package:erp/features/expenses/data/demo_expense_repository.dart';
import 'package:erp/features/expenses/domain/expense.dart';
import 'package:erp/features/expenses/presentation/expenses_controller.dart';
import 'package:erp/features/expenses/presentation/expenses_screen.dart';
import 'package:erp/features/parties/data/demo_party_repository.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/data/demo_operational_settings_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows shared fields, table, search and action states',
      (tester) async {
    final harness = _ExpensesHarness();
    await _pumpScreen(tester, harness);

    expect(find.byKey(const Key('expensesScreen')), findsOneWidget);
    expect(find.byKey(const Key('expenseNumberField')), findsOneWidget);
    expect(find.byKey(const Key('expenseDescriptionField')), findsOneWidget);
    expect(find.byKey(const Key('expenseSupplierField')), findsOneWidget);
    expect(find.byKey(const Key('expensePaymentStatusField')), findsOneWidget);
    expect(find.byKey(const Key('expenseCurrencyField')), findsOneWidget);
    expect(find.byKey(const Key('expenseAmountField')), findsOneWidget);
    expect(find.byKey(const Key('expenseSearchField')), findsOneWidget);
    expect(find.byKey(const Key('expensesTable')), findsOneWidget);
    expect(find.byKey(const Key('expenseRow_expense-unpaid')), findsOneWidget);
    expect(find.text('غير مدفوع'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('expenseSearchField')),
      'لا توجد نتيجة',
    );
    await tester.pump();
    expect(find.byKey(const Key('expenseRow_expense-unpaid')), findsNothing);

    await tester.tap(find.byKey(const Key('expenseSearchClearButton')));
    await tester.pump();
    expect(find.byKey(const Key('expenseRow_expense-unpaid')), findsOneWidget);
  });

  testWidgets('settles an unpaid expense explicitly and prints it',
      (tester) async {
    final harness = _ExpensesHarness();
    await _pumpScreen(tester, harness);

    await tester.tap(find.byKey(const Key('expenseRow_expense-unpaid')));
    await tester.pump();
    expect(harness.controller.selectedExpense?.isUnpaid, isTrue);

    await tester.tap(find.byKey(const Key('expenseSettleButton')));
    await tester.pump();
    expect(find.text('تسديد المصروف بالكامل'), findsWidgets);
    await tester.tap(find.text('تسديد'));
    await tester.pump();
    await tester.pump();
    expect(harness.controller.selectedExpense?.isPaid, isTrue);
    expect(harness.effects.kinds.last, DemoExpenseMutationKind.settle);

    await tester.tap(find.byKey(const Key('expensePrintButton')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('appDocumentOutputDialog')), findsOneWidget);
    expect(find.text('سند مصروف رقم 1'), findsOneWidget);
  });

  testWidgets('honors the independent expenses action permissions',
      (tester) async {
    final harness = _ExpensesHarness();
    await _pumpScreen(
      tester,
      harness,
      allowsAction: (action) => action == PermissionAction.view,
    );

    expect(
      tester.widget<AppHeaderIconButton>(
        find.byKey(const Key('expensePrintButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(find.byKey(const Key('expenseSaveButton')))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<AppTextField>(
        find.ancestor(
          of: find.byKey(const Key('expenseDescriptionField')),
          matching: find.byType(AppTextField),
        ),
      ).enabled,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('expenseRow_expense-unpaid')));
    await tester.pump();
    expect(
      tester.widget<AppHeaderIconButton>(
        find.byKey(const Key('expenseSettleButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppAutocompleteField<Party>>(
        find.ancestor(
          of: find.byKey(const Key('expenseSupplierField')),
          matching: find.byType(AppAutocompleteField<Party>),
        ),
      ).enabled,
      isFalse,
    );
  });

  testWidgets('busy save blocks duplicate expense creation', (tester) async {
    final harness = _ExpensesHarness();
    await _pumpScreen(tester, harness);
    harness.effects.delayNextMutation();
    await tester.enterText(
      find.byKey(const Key('expenseDescriptionField')),
      'مصروف اختباري',
    );
    await tester.enterText(
      find.byKey(const Key('expenseAmountField')),
      '1000',
    );

    await tester.tap(find.byKey(const Key('expenseSaveButton')));
    await tester.pump();
    await harness.effects.mutationStarted;
    await tester.pump();

    expect(find.byKey(const Key('expenseBusyOverlay')), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byKey(const Key('expenseSaveButton')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const Key('expenseSaveButton')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(harness.effects.calls, 1);

    harness.effects.releaseMutation();
    await tester.pumpAndSettle();
    expect(await harness.repository.getAll(), hasLength(2));
  });

  testWidgets('output reloads the latest saved expense', (tester) async {
    final harness = _ExpensesHarness();
    final output = _RecordingDocumentOutputService();
    await _pumpScreen(tester, harness, outputService: output);

    await tester.tap(find.byKey(const Key('expenseRow_expense-unpaid')));
    await tester.pump();
    final selected = harness.controller.selectedExpense!;
    await harness.repository.update(
      ExpenseUpdateRequest(
        id: selected.id,
        date: selected.date,
        minuteOfDay: selected.minuteOfDay,
        description: 'صيانة محدثة',
        amount: selected.amount,
        exchangeRate: selected.exchangeRate,
        supplierId: selected.supplierId,
        notes: selected.notes,
      ),
    );

    await tester.tap(find.byKey(const Key('expensePrintButton')));
    await tester.pumpAndSettle();

    expect(output.lastPreviewRequest?.subtitle, 'صيانة محدثة');
    expect(
      _fieldValue(tester, 'expenseDescriptionField'),
      'صيانة محدثة',
    );
  });

  testWidgets('output stops when the selected expense was deleted',
      (tester) async {
    final harness = _ExpensesHarness();
    final output = _RecordingDocumentOutputService();
    await _pumpScreen(tester, harness, outputService: output);

    await tester.tap(find.byKey(const Key('expenseRow_expense-unpaid')));
    await tester.pump();
    final selected = harness.controller.selectedExpense!;
    await harness.repository.deletePermanently(selected.id);

    await tester.tap(find.byKey(const Key('expensePrintButton')));
    await tester.pump();
    await tester.pump();

    expect(output.lastPreviewRequest, isNull);
    expect(
      find.byKey(const Key('expensesMissingReferenceState')),
      findsOneWidget,
    );
    await tester.pump(AppToast.duration);
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _ExpensesHarness harness, {
  bool Function(PermissionAction action)? allowsAction,
  DocumentOutputService? outputService,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() async {
    harness.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ExpensesScreen(
          controller: harness.controller,
          outputService: outputService ?? const DemoDocumentOutputService(),
          allowsAction: allowsAction ?? (_) => true,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _ExpensesHarness {
  _ExpensesHarness()
      : effects = _WidgetExpenseEffects(),
        parties = DemoPartyRepository(
          initialValues: [_supplier],
          initialMasterDataReferences: const {},
          masterData: DemoOperationalMasterDataRepository(),
        ) {
    repository = DemoExpenseRepository(
      initialValues: [_unpaidExpense],
      partyLoader: parties.getById,
      mutationEffects: effects,
    );
    controller = ExpensesController(
      repository: repository,
      parties: parties,
    );
  }

  final _WidgetExpenseEffects effects;
  final PartyRepository parties;
  late final DemoExpenseRepository repository;
  late final ExpensesController controller;

  void dispose() {
    effects.releaseMutation();
    controller.dispose();
  }
}

class _WidgetExpenseEffects implements DemoExpenseMutationEffects {
  final kinds = <DemoExpenseMutationKind>[];
  int calls = 0;
  Completer<void>? _gate;
  Completer<void>? _started;

  void delayNextMutation() {
    _gate = Completer<void>();
    _started = Completer<void>();
  }

  Future<void> get mutationStarted => _started?.future ?? Future.value();

  void releaseMutation() {
    final gate = _gate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<Expense> applyExpense({
    required DemoExpenseMutationKind kind,
    required Future<DemoExpenseMutation> Function()
        preflightAndBuildMutation,
    required void Function(Expense normalized) commit,
  }) async {
    final mutation = await preflightAndBuildMutation();
    calls++;
    _started?.complete();
    final gate = _gate;
    if (gate != null) await gate.future;
    _gate = null;
    _started = null;
    commit(mutation.candidate);
    kinds.add(kind);
    return mutation.candidate;
  }

  @override
  Future<void> deleteExpense({
    required EntityId id,
    required Future<Expense> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) async {
    await preflightAndLoadPrevious();
    commit();
  }
}

class _RecordingDocumentOutputService implements DocumentOutputService {
  final _delegate = const DemoDocumentOutputService();
  DocumentOutputRequest? lastPreviewRequest;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) {
    lastPreviewRequest = request;
    return _delegate.createPreview(request, includePrices: includePrices);
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) {
    return _delegate.export(request, format);
  }
}

String _fieldValue(WidgetTester tester, String fieldKey) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(fieldKey)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

final Party _supplier = Party(
  id: 'party-003',
  number: 3,
  createdAt: DateTime(2026, 1, 1),
  name: 'مجهز الرافدين',
  type: PartyType.supplier,
  workplace: '',
  branch: '',
  phone: '',
  alternatePhone: '',
  city: '',
  address: '',
  notes: '',
  balanceIqd: 0,
  balanceUsd: 0,
);

final Expense _unpaidExpense = Expense(
  id: EntityId('expense-unpaid'),
  documentNumber: 1,
  date: BusinessDate(2026, 8, 14),
  minuteOfDay: 9 * 60,
  description: 'صيانة أجهزة المكتب',
  amount: Money.fromMajor(150, AppCurrency.usd),
  exchangeRate: ExchangeRate.parse('1310'),
  supplierId: _supplier.entityId,
  supplierNameSnapshot: _supplier.name,
  paymentStatus: ExpensePaymentStatus.unpaid,
  notes: 'مستحق للمجهز',
);
