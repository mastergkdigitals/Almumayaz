import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/items/data/demo_item_repository.dart';
import 'package:erp/features/items/domain/item.dart';
import 'package:erp/features/items/presentation/items_controller.dart';
import 'package:erp/features/settings/data/demo_operational_settings_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the repository-backed items list', () async {
    final repositories = AppRepositories.demo();
    final controller = ItemsController(repository: repositories.items);
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.items, hasLength(10));
    expect(controller.state.items.first.entityId, EntityId('item-001'));
    expect(
      controller.state.items.first.iqdSalePrice,
      Money.fromMajor(285000, AppCurrency.iqd),
    );
    expect(
      controller.state.items.first.usdSalePrice,
      Money.fromMajor(190, AppCurrency.usd),
    );

    controller.search('ورق طباعة');
    expect(controller.visibleItems, hasLength(1));
    expect(controller.visibleItems.first.code, 'P-1003');

    controller.first();
    expect(controller.selectedItem?.name, 'ورق تصوير A4');

    controller.search('');
    controller.first();
    expect(controller.selectedItem?.name, 'طابعة ليزر');

    controller.next();
    expect(controller.selectedItem?.name, 'حبر طابعة أسود');

    controller.last();
    expect(controller.selectedItem?.name, 'دفتر ملاحظات');

    controller.next();
    expect(controller.selectedItem, isNull);
  });

  test('deletes only items without known inventory relationships', () async {
    final repositories = AppRepositories.demo();
    final controller = ItemsController(repository: repositories.items);
    addTearDown(controller.dispose);
    await controller.load();

    controller.select('item-001');
    expect((await controller.canDeleteSelected()).isAllowed, isFalse);
    expect(await controller.deleteSelected(), isNull);

    controller.select('item-006');
    expect((await controller.canDeleteSelected()).isAllowed, isFalse);

    final group = controller.state.groups.first;
    final type = controller.typesFor(group.id).first;
    await controller.add(
      Item(
        id: 'item-unreferenced-test',
        code: 'P-DELETE',
        name: 'مادة غير مرتبطة',
        barcode: '9999999999999',
        groupId: group.id,
        groupName: group.name,
        typeId: type.id,
        typeName: type.name,
        salePriceIqd: 1000,
        salePriceUsd: 1,
        notes: '',
      ),
    );
    controller.select('item-unreferenced-test');
    expect((await controller.canDeleteSelected()).isAllowed, isTrue);
    expect(
      (await controller.deleteSelected())?.id,
      'item-unreferenced-test',
    );
    expect(controller.state.items, hasLength(10));
  });

  test('persists items across controllers and reports missing references',
      () async {
    final repositories = AppRepositories.demo();
    final first = ItemsController(repository: repositories.items);
    addTearDown(first.dispose);
    await first.load();
    final group = first.state.groups.first;
    final type = first.typesFor(group.id).first;
    await first.add(
      Item(
        id: 'item-persistence-test',
        code: 'P-9000',
        name: 'مادة مستمرة',
        barcode: '9000000000000',
        groupId: group.id,
        groupName: group.name,
        typeId: type.id,
        typeName: type.name,
        salePriceIqd: 1000,
        salePriceUsd: 0.75,
        notes: '',
      ),
    );

    final reopened = ItemsController(repository: repositories.items);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(
      reopened.state.items.any((item) => item.id == 'item-persistence-test'),
      isTrue,
    );

    final masterData = DemoOperationalMasterDataRepository();
    final brokenRepository = DemoItemRepository(
      masterData: masterData,
      initialValues: [
        demoItems().first.copyWith(typeId: 'missing-item-type'),
      ],
    );
    final broken = ItemsController(repository: brokenRepository);
    addTearDown(broken.dispose);
    await broken.load();
    expect(broken.state.dataState.status, AppDataStatus.missingReference);
  });

  testWidgets(
    'opens Items from Warehouses with shared controls and read-only barcode',
    (tester) async {
      await _openItems(tester);

      expect(find.byKey(const Key('itemsScreen')), findsOneWidget);
      expect(find.byKey(const Key('itemForm')), findsOneWidget);
      expect(find.byKey(const Key('itemsActionBar')), findsOneWidget);
      expect(find.byKey(const Key('itemsTable')), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byKey(const Key('itemsScreen')),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        scaffold.backgroundColor,
        Color.alphaBlend(
          AppModuleColors.warehouses.withAlpha(12),
          AppColors.surface,
        ),
      );

      final barcodeFinder =
          find.byKey(const Key('itemBarcodeField'));
      final barcodeField =
          tester.widget<TextFormField>(barcodeFinder);
      expect(barcodeField.enabled, isFalse);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: barcodeFinder,
                matching: find.byType(EditableText),
              ),
            )
            .readOnly,
        isTrue,
      );
      expect(
        _fieldDecoration(tester, barcodeFinder).fillColor,
        AppColors.neutralSurface,
      );

      for (final fieldKey in [
        'itemCodeField',
        'itemNameField',
        'itemSalePriceIqdField',
        'itemSalePriceUsdField',
        'itemNotesField',
      ]) {
        final fieldFinder = find.byKey(Key(fieldKey));
        final field = tester.widget<TextFormField>(fieldFinder);
        final decoration = _fieldDecoration(tester, fieldFinder);
        expect(field.enabled, isTrue);
        expect(decoration.fillColor, AppColors.surface);
        expect(
          (decoration.focusedBorder as OutlineInputBorder)
              .borderSide
              .color,
          AppModuleColors.warehouses,
        );
      }

      expect(find.byKey(const Key('itemGroupField')), findsOneWidget);
      expect(find.byKey(const Key('itemTypeField')), findsOneWidget);

      final table = tester.widget<AppDataTable>(
        find.byKey(const Key('itemsTable')),
      );
      expect(table.accentColor, AppModuleColors.warehouses);
      expect(table.alternatingRowColor, isNull);
      expect(
        table.selectedRowColor,
        Color.alphaBlend(
          AppModuleColors.warehouses.withAlpha(32),
          AppColors.surface,
        ),
      );
      expect(table.rows, hasLength(10));
      expect(
        table.columns.map((column) => column.label),
        [
          'رمز المادة',
          'اسم المادة',
          'المجموعة',
          'سعر البيع دينار',
          'سعر البيع دولار',
        ],
      );

      await tester.tap(find.byKey(const Key('itemRow_item-002')));
      await tester.pump();

      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('itemNameField')),
            )
            .controller
            ?.text,
        'حبر طابعة أسود',
      );
      expect(
        tester
            .widget<TextFormField>(barcodeFinder)
            .controller
            ?.text,
        '1000000000002',
      );
    },
  );

  testWidgets('guards unsaved item data from system back', (tester) async {
    await _openItems(tester);
    await tester.enterText(
      find.byKey(const Key('itemNameField')),
      'مادة غير محفوظة',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itemsScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('itemsScreen')), findsNothing);
    expect(find.byKey(const Key('warehousesScreen')), findsOneWidget);
  });
}

Future<void> _openItems(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_warehouses')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('warehouseProductsButton')));
  await tester.pumpAndSettle();
}

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}
