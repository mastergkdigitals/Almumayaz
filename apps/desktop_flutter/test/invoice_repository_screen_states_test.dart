import 'dart:async';

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/application/invoice_editor_coordinator.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/design/components/app_screen_shell.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/purchases/domain/purchase_repository.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales/domain/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sales shows loading then ordered repository data',
      (tester) async {
    final base = AppRepositories.demo();
    final invoices = await base.sales.getAll();
    final loading = Completer<List<SalesInvoice>>();
    final store = AppStore(
      repositories: _withSales(
        base,
        _SalesRepositoryOverride(
          delegate: base.sales,
          load: () => loading.future,
        ),
      ),
    );

    await _openFeatureWithoutSettling(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_sales',
    );
    expect(find.byKey(const Key('salesLoadingState')), findsOneWidget);

    loading.complete(invoices.reversed.toList());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('salesLoadingState')), findsNothing);
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
  });

  testWidgets('Sales exposes empty and new-editor states', (tester) async {
    final base = AppRepositories.demo();
    final store = AppStore(
      repositories: _withSales(
        base,
        _SalesRepositoryOverride(
          delegate: base.sales,
          load: () async => [],
        ),
      ),
    );

    await _openFeature(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_sales',
    );
    expect(find.byKey(const Key('salesEmptyState')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('salesEmptyState')),
        matching: find.text('قائمة بيع جديدة'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('salesEmptyState')), findsNothing);
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '104');
  });

  testWidgets('Sales distinguishes missing references from failures',
      (tester) async {
    final missingBase = AppRepositories.demo();
    final missingStore = AppStore(
      repositories: _withSales(
        missingBase,
        _SalesRepositoryOverride(
          delegate: missingBase.sales,
          load: () async => throw const InvoiceMissingReferenceException(
            'مرجع بيع مفقود',
          ),
        ),
      ),
    );

    await _openFeature(
      tester,
      store: missingStore,
      dashboardKey: 'dashboardCard_sales',
    );
    expect(
      find.byKey(const Key('salesMissingReferenceState')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final errorBase = AppRepositories.demo();
    var shouldFail = true;
    final errorStore = AppStore(
      repositories: _withSales(
        errorBase,
        _SalesRepositoryOverride(
          delegate: errorBase.sales,
          load: () async {
            if (shouldFail) throw StateError('فشل تجريبي');
            return errorBase.sales.getAll();
          },
        ),
      ),
    );
    await _openFeature(
      tester,
      store: errorStore,
      dashboardKey: 'dashboardCard_sales',
      resetSurfaceSize: false,
    );
    expect(find.byKey(const Key('salesErrorState')), findsOneWidget);

    shouldFail = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('salesErrorState')),
        matching: find.text('إعادة المحاولة'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('salesErrorState')), findsNothing);
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
  });

  testWidgets('Sales save uses the shared inaccessible busy overlay',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final base = AppRepositories.demo();
    final saving = Completer<SalesInvoice>();
    late SalesInvoice submitted;
    final store = AppStore(
      repositories: _withSales(
        base,
        _SalesRepositoryOverride(
          delegate: base.sales,
          load: base.sales.getAll,
          replace: (invoice) {
            submitted = invoice;
            return saving.future;
          },
        ),
      ),
    );

    await _openFeature(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_sales',
    );
    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'حفظ معلّق',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pump();

    expect(find.byKey(const Key('salesBusyOverlay')), findsOneWidget);
    expect(
      tester.widget<AppScreenShell>(find.byKey(const Key('salesScreen'))).onBack,
      isNull,
    );
    expect(
      find.bySemanticsLabel('جاري حفظ قائمة البيع'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('تحديث'), findsNothing);

    saving.complete(submitted);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('salesBusyOverlay')), findsNothing);
    semantics.dispose();
  });

  testWidgets('Purchase shows loading then ordered repository data',
      (tester) async {
    final base = AppRepositories.demo();
    final invoices = await base.purchases.getAll();
    final loading = Completer<List<PurchaseInvoice>>();
    final store = AppStore(
      repositories: _withPurchases(
        base,
        _PurchaseRepositoryOverride(
          delegate: base.purchases,
          load: () => loading.future,
        ),
      ),
    );

    await _openFeatureWithoutSettling(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_purchases',
    );
    expect(find.byKey(const Key('purchaseLoadingState')), findsOneWidget);

    loading.complete(invoices.reversed.toList());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseLoadingState')), findsNothing);
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
  });

  testWidgets('Purchase exposes empty and new-editor states', (tester) async {
    final base = AppRepositories.demo();
    final store = AppStore(
      repositories: _withPurchases(
        base,
        _PurchaseRepositoryOverride(
          delegate: base.purchases,
          load: () async => [],
        ),
      ),
    );

    await _openFeature(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_purchases',
    );
    expect(find.byKey(const Key('purchaseEmptyState')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('purchaseEmptyState')),
        matching: find.text('قائمة شراء جديدة'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('purchaseEmptyState')), findsNothing);
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '104');
  });

  testWidgets('Purchase distinguishes missing references from failures',
      (tester) async {
    final missingBase = AppRepositories.demo();
    final missingStore = AppStore(
      repositories: _withPurchases(
        missingBase,
        _PurchaseRepositoryOverride(
          delegate: missingBase.purchases,
          load: () async => throw const InvoiceMissingReferenceException(
            'مرجع شراء مفقود',
          ),
        ),
      ),
    );

    await _openFeature(
      tester,
      store: missingStore,
      dashboardKey: 'dashboardCard_purchases',
    );
    expect(
      find.byKey(const Key('purchaseMissingReferenceState')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final errorBase = AppRepositories.demo();
    var shouldFail = true;
    final errorStore = AppStore(
      repositories: _withPurchases(
        errorBase,
        _PurchaseRepositoryOverride(
          delegate: errorBase.purchases,
          load: () async {
            if (shouldFail) throw StateError('فشل تجريبي');
            return errorBase.purchases.getAll();
          },
        ),
      ),
    );
    await _openFeature(
      tester,
      store: errorStore,
      dashboardKey: 'dashboardCard_purchases',
      resetSurfaceSize: false,
    );
    expect(find.byKey(const Key('purchaseErrorState')), findsOneWidget);

    shouldFail = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('purchaseErrorState')),
        matching: find.text('إعادة المحاولة'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseErrorState')), findsNothing);
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
  });

  testWidgets('Purchase save uses the shared inaccessible busy overlay',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final base = AppRepositories.demo();
    final saving = Completer<PurchaseInvoice>();
    late PurchaseInvoice submitted;
    final store = AppStore(
      repositories: _withPurchases(
        base,
        _PurchaseRepositoryOverride(
          delegate: base.purchases,
          load: base.purchases.getAll,
          replace: (invoice) {
            submitted = invoice;
            return saving.future;
          },
        ),
      ),
    );

    await _openFeature(
      tester,
      store: store,
      dashboardKey: 'dashboardCard_purchases',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'حفظ معلّق',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseUpdateButton')));
    await tester.pump();

    expect(find.byKey(const Key('purchaseBusyOverlay')), findsOneWidget);
    expect(
      tester
          .widget<AppScreenShell>(find.byKey(const Key('purchaseScreen')))
          .onBack,
      isNull,
    );
    expect(
      find.bySemanticsLabel('جاري حفظ قائمة الشراء'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('تحديث'), findsNothing);

    saving.complete(submitted);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('purchaseBusyOverlay')), findsNothing);
    semantics.dispose();
  });
}

AppRepositories _withSales(
  AppRepositories base,
  SalesRepository sales,
) {
  return AppRepositories(
    parties: base.parties,
    items: base.items,
    warehouses: base.warehouses,
    inventoryCosts: base.inventoryCosts,
    cashbox: base.cashbox,
    sales: sales,
    salesReturns: base.salesReturns,
    purchases: base.purchases,
    installments: base.installments,
    expenses: base.expenses,
    businessSettings: base.businessSettings,
    deviceSettings: base.deviceSettings,
    operationalMasterData: base.operationalMasterData,
  );
}

AppRepositories _withPurchases(
  AppRepositories base,
  PurchaseRepository purchases,
) {
  return AppRepositories(
    parties: base.parties,
    items: base.items,
    warehouses: base.warehouses,
    inventoryCosts: base.inventoryCosts,
    cashbox: base.cashbox,
    sales: base.sales,
    salesReturns: base.salesReturns,
    purchases: purchases,
    installments: base.installments,
    expenses: base.expenses,
    businessSettings: base.businessSettings,
    deviceSettings: base.deviceSettings,
    operationalMasterData: base.operationalMasterData,
  );
}

Future<void> _openFeature(
  WidgetTester tester, {
  required AppStore store,
  required String dashboardKey,
  bool resetSurfaceSize = true,
}) async {
  await _bootToDashboard(
    tester,
    store: store,
    resetSurfaceSize: resetSurfaceSize,
  );
  await tester.tap(find.byKey(Key(dashboardKey)));
  await tester.pumpAndSettle();
}

Future<void> _openFeatureWithoutSettling(
  WidgetTester tester, {
  required AppStore store,
  required String dashboardKey,
}) async {
  await _bootToDashboard(tester, store: store);
  await tester.tap(find.byKey(Key(dashboardKey)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _bootToDashboard(
  WidgetTester tester, {
  required AppStore store,
  bool resetSurfaceSize = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  if (resetSurfaceSize) {
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(AlmumayazApp(store: store));
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}

String _fieldValue(WidgetTester tester, String key) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

class _SalesRepositoryOverride implements SalesRepository {
  const _SalesRepositoryOverride({
    required this.delegate,
    required this.load,
    this.replace,
  });

  final SalesRepository delegate;
  final Future<List<SalesInvoice>> Function() load;
  final Future<SalesInvoice> Function(SalesInvoice)? replace;

  @override
  Future<List<SalesInvoice>> getAll() => load();

  @override
  Future<SalesInvoice?> getById(EntityId id) => delegate.getById(id);

  @override
  Future<SalesInvoice> save(SalesInvoice value) => delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) => delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => delegate.delete(id);

  @override
  Future<List<SalesInvoice>> search(String query) => delegate.search(query);

  @override
  Future<int> nextDocumentNumber() => delegate.nextDocumentNumber();

  @override
  Future<SalesInvoice> createInvoice(SalesInvoice invoice) =>
      delegate.createInvoice(invoice);

  @override
  Future<SalesInvoice> replaceInvoice(SalesInvoice invoice) =>
      replace?.call(invoice) ?? delegate.replaceInvoice(invoice);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) =>
      delegate.deleteInvoicePermanently(id);
}

class _PurchaseRepositoryOverride implements PurchaseRepository {
  const _PurchaseRepositoryOverride({
    required this.delegate,
    required this.load,
    this.replace,
  });

  final PurchaseRepository delegate;
  final Future<List<PurchaseInvoice>> Function() load;
  final Future<PurchaseInvoice> Function(PurchaseInvoice)? replace;

  @override
  Future<List<PurchaseInvoice>> getAll() => load();

  @override
  Future<PurchaseInvoice?> getById(EntityId id) => delegate.getById(id);

  @override
  Future<PurchaseInvoice> save(PurchaseInvoice value) => delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) => delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => delegate.delete(id);

  @override
  Future<List<PurchaseInvoice>> search(String query) =>
      delegate.search(query);

  @override
  Future<int> nextDocumentNumber() => delegate.nextDocumentNumber();

  @override
  Future<PurchaseInvoice> createInvoice(PurchaseInvoice invoice) =>
      delegate.createInvoice(invoice);

  @override
  Future<PurchaseInvoice> replaceInvoice(PurchaseInvoice invoice) =>
      replace?.call(invoice) ?? delegate.replaceInvoice(invoice);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) =>
      delegate.deleteInvoicePermanently(id);
}
