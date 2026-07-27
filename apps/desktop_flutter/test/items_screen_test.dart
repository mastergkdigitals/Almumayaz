import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/items/presentation/items_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the temporary items list', () {
    final controller = ItemsController();
    addTearDown(controller.dispose);

    expect(controller.state.items, hasLength(6));

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
    expect(controller.selectedItem?.name, 'ملف حفظ مستندات');

    controller.next();
    expect(controller.selectedItem, isNull);
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
      expect(table.rows, hasLength(6));
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
